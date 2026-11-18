defmodule PetalComponents.Check.Rules.WhiteAlphaGhost do
  @moduledoc false
  # Guide section 11 row 10 and section 4. Dark translucent chrome is gray-400
  # alpha, which carries the gray dial's hue; white alpha glows and ignores
  # the dial. The one blessed white-alpha family is the barely-there muted
  # fill, 6% or less, so fills at /1 to /6 and [0.01] to [0.06] pass.
  # Borders flag at any alpha.

  @behaviour PetalComponents.Check.Rule

  alias PetalComponents.Check.Classes
  alias PetalComponents.Check.Rule
  alias PetalComponents.Check.Unit

  import Rule, only: [cls: 1]

  @impl true
  def rule do
    %Rule{
      id: "white-alpha-ghost",
      severity: :error,
      section: "11.10",
      row_keyword: "white-alpha",
      scope: :class_unit,
      why:
        "dark translucent chrome is gray-400 alpha, which follows the gray dial; white alpha glows and ignores it",
      examples: [
        {:bad, ~s(<div class="#{cls(["dark:bg", "white/10"])}">)},
        {:good, ~s(<div class="#{cls(["dark:bg", "gray", "400/8"])}">)}
      ],
      exemptions: [
        "the blessed muted fill: #{cls(["dark:bg", "white"])}/[0.03] to /[0.06], or /1 to /6",
        "white alpha with no dark: variant (an overlay on imagery or a brand panel)",
        "text, ring and divide colours, and opaque white",
        "a bracket value that is not a plain number or percentage"
      ]
    }
  end

  defp utility_re,
    do: ~r/^(bg|border(?:-(?:x|y|t|r|b|l|s|e))?)-white\/(\d+|\[\s*[0-9.]+%?\s*\])$/

  @impl true
  def check(%Unit{} = unit, _ctx) do
    for tok <- unit.tokens,
        %{} = parsed <- [Classes.parse(tok.text)],
        "dark" in parsed.variants,
        [_, prop, alpha] <- [Regex.run(utility_re(), parsed.utility)],
        flag?(prop, alpha) do
      finding(unit, tok, parsed, prop)
    end
  end

  defp flag?("bg", alpha), do: alpha_value(alpha) > 0.06
  defp flag?(_border, _alpha), do: true

  defp alpha_value(alpha) do
    case Regex.run(~r/^\[\s*([0-9.]+)(%?)\s*\]$/, alpha) do
      [_, n, "%"] -> number(n) / 100
      [_, n, ""] -> number(n)
      nil -> String.to_integer(alpha) / 100
    end
  end

  defp number(n) do
    case Float.parse(if String.starts_with?(n, "."), do: "0" <> n, else: n) do
      {f, ""} -> f
      # Not a number Tailwind would read; skip beats a false alarm.
      _ -> 0.0
    end
  end

  defp finding(unit, tok, parsed, prop) do
    {line, column} = Unit.position(unit, tok)
    gray = cls(["gray", "400"])

    {utility, extra} =
      cond do
        prop != "bg" -> {"#{prop}-#{gray}/17", " (use /25 on an input border)"}
        "active" in parsed.variants -> {"bg-#{gray}/25", ""}
        "hover" in parsed.variants -> {"bg-#{gray}/17", ""}
        true -> {"bg-#{gray}/8", ""}
      end

    replacement = Classes.rebuild(parsed, utility)

    Rule.finding(rule(),
      line: line,
      column: column,
      subject: tok.text,
      message: "#{tok.text} is a white-alpha ghost; dark chrome uses gray-400 alpha",
      replacement: replacement,
      fix: "replace #{tok.text} with #{replacement}",
      note: if(extra != "", do: "on an input border use /25 instead of /17"),
      tag_line: unit.tag && unit.tag.line
    )
  end
end
