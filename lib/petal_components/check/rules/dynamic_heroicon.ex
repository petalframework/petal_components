defmodule PetalComponents.Check.Rules.DynamicHeroicon do
  @moduledoc false
  # Guide section 8, last bullet. Tailwind finds heroicon classes by scanning
  # source text, so a name built at runtime (interpolation or <>) is never
  # seen and the icon can render blank. Covers petal's <.icon> and an app's
  # own CoreComponents icon: both have this failure.
  #
  # Only names that are visibly built from a "hero-" piece are flagged. A
  # passthrough (name={@icon}) or a function call may hold full literals
  # elsewhere, so it is left alone.

  @behaviour PetalComponents.Check.Rule

  alias PetalComponents.Check.Components
  alias PetalComponents.Check.Heex.Attr
  alias PetalComponents.Check.Heex.Tag
  alias PetalComponents.Check.Rule

  defp hero, do: "hero" <> "-"

  @impl true
  def rule do
    %Rule{
      id: "dynamic-heroicon",
      severity: :error,
      section: "8",
      row_keyword: "heroicon",
      scope: :component,
      why:
        "Tailwind only builds the heroicon classes it finds written out in full, so a name built at runtime can render blank",
      examples: [
        {:bad, ~s(<.icon name={"#{hero()}\#{@kind}"} />)},
        {:good,
         ~s(<.icon name={if @open, do: "#{hero()}chevron-up", else: "#{hero()}chevron-down"} />)}
      ],
      exemptions: [
        "name={@icon} or name={icon_for(@x)}: a passthrough or a function may return full literal names",
        "a name chosen between full literals (if, case)",
        ~s(an id or other attr built from "#{hero()}", which is not an icon),
        "an app whose CSS lists the icons with @source inline(\"#{hero()}...\")"
      ]
    }
  end

  @impl true
  def check(%Tag{kind: kind} = tag, ctx) when kind in [:local_component, :remote_component] do
    with false <- ctx.hero_inline?,
         "icon" <- Components.function_name(tag),
         %Attr{value: {:expr, code}} = attr <- Enum.find(tag.attrs, &(&1.name == "name")),
         true <- String.contains?(code, hero()),
         {:ok, ast} <- Code.string_to_quoted(code, emit_warnings: false),
         true <- built?(ast) do
      [finding(tag, attr, code)]
    else
      _ -> []
    end
  end

  def check(_tag, _ctx), do: []

  defp built?(ast) do
    {_, hit} =
      Macro.prewalk(ast, false, fn
        node, true ->
          {node, true}

        {:<<>>, _, parts} = node, false when is_list(parts) ->
          {node, Enum.any?(parts, &hero_bin?/1) and Enum.any?(parts, &(not is_binary(&1)))}

        {:<>, _, [l, r]} = node, false ->
          {node, hero_bin?(l) or hero_bin?(r)}

        node, acc ->
          {node, acc}
      end)

    hit
  end

  defp hero_bin?(b), do: is_binary(b) and String.contains?(b, hero())

  defp finding(tag, attr, code) do
    shown = code |> String.replace(~r/\s+/, " ") |> String.trim()

    Rule.finding(rule(),
      line: attr.line,
      column: attr.column,
      subject: attr.source,
      message:
        "icon name {#{shown}} is built at runtime and can render blank: " <>
          "Tailwind only builds #{hero()}* classes it finds written out in full",
      replacement: nil,
      fix:
        "write each full name as a literal, for example " <>
          ~s(name={if @open, do: "#{hero()}chevron-up", else: "#{hero()}chevron-down"}, ) <>
          "or return literal names from a function",
      tag_line: tag.line
    )
  end
end
