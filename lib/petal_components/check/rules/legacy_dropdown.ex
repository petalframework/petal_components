defmodule PetalComponents.Check.Rules.LegacyDropdown do
  @moduledoc false
  # Guide section 11 row 5. placement and direction on <.dropdown> still
  # work, but side and align supersede them and win when both appear
  # (dropdown.ex). A warning: nothing is broken.

  @behaviour PetalComponents.Check.Rule

  alias PetalComponents.Check.Components
  alias PetalComponents.Check.Heex.Attr
  alias PetalComponents.Check.Heex.Tag
  alias PetalComponents.Check.Rule

  @map %{
    {"placement", "left"} => {"align", "end"},
    {"placement", "right"} => {"align", "start"},
    {"direction", "up"} => {"side", "top"},
    {"direction", "down"} => {"side", "bottom"}
  }

  @impl true
  def rule do
    %Rule{
      id: "legacy-dropdown",
      severity: :warning,
      section: "11.5",
      row_keyword: "dropdown",
      scope: :component,
      why:
        "placement and direction still work but are superseded by side and align, which win when both appear",
      examples: [
        {:bad, ~s(<.dropdown label="Org" placement="left">)},
        {:good, ~s(<.dropdown label="Org" align="end">)}
      ],
      exemptions: [
        ~s(placement={@placement}: a passthrough, the value is not known here),
        "placement on other components (popover, tooltip)",
        "an app's own dropdown component"
      ]
    }
  end

  @impl true
  def check(%Tag{kind: kind} = tag, ctx) when kind in [:local_component, :remote_component] do
    if Components.function_name(tag) == "dropdown" and ctx.petal?.(tag) do
      for %Attr{name: name, value: {:string, v}} = attr <- tag.attrs,
          name in ["placement", "direction"],
          do: finding(tag, attr, v)
    else
      []
    end
  end

  def check(_tag, _ctx), do: []

  defp finding(tag, %Attr{name: name} = attr, v) do
    other = if name == "placement", do: "align", else: "side"

    {replacement, fix} =
      cond do
        Enum.any?(tag.attrs, &(&1.name == other)) ->
          {"", "remove #{attr.source} (#{other} is already set and wins)"}

        new = @map[{name, v}] ->
          {k, nv} = new
          r = ~s(#{k}="#{nv}")
          {r, "replace #{attr.source} with #{r}"}

        {name, v} == {"direction", "auto"} ->
          {"", "remove #{attr.source} (auto is the default)"}

        true ->
          {nil, "use side and align instead"}
      end

    Rule.finding(rule(),
      line: attr.line,
      column: attr.column,
      subject: attr.source,
      message: "#{attr.source} is the legacy dropdown spelling",
      replacement: replacement,
      fix: fix,
      tag_line: tag.line
    )
  end
end
