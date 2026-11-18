defmodule PetalComponents.Check.Rules.ComboboxVariant do
  @moduledoc false
  # Guide section 11 row 9. Through <.field type="combobox"> the anatomy attr
  # is combo_variant; `variant` belongs to radio-card there and is ignored
  # (field.ex: the combobox clause never reads :variant).

  @behaviour PetalComponents.Check.Rule

  alias PetalComponents.Check.Components
  alias PetalComponents.Check.Heex.Attr
  alias PetalComponents.Check.Heex.Tag
  alias PetalComponents.Check.Rule

  @impl true
  def rule do
    %Rule{
      id: "combobox-variant",
      severity: :error,
      section: "11.9",
      row_keyword: "combobox",
      scope: :component,
      why: ~s(through <.field type="combobox"> the anatomy attr is combo_variant; variant is ignored there),
      examples: [
        {:bad, ~s(<.field type="combobox" variant="trigger" field={@form[:owner]} options={@owners} />)},
        {:good, ~s(<.field type="combobox" combo_variant="trigger" field={@form[:owner]} options={@owners} />)}
      ],
      exemptions: [
        ~s(<.combo_box variant="trigger">: the combo_box component takes variant itself),
        ~s(<.field type={@type} variant="x">: the type is not a literal, so it cannot be known),
        "an app's own field component (one the module defines, or imports instead of petal's)"
      ]
    }
  end

  @impl true
  def check(%Tag{kind: kind} = tag, ctx) when kind in [:local_component, :remote_component] do
    with "field" <- Components.function_name(tag),
         true <- ctx.petal?.(tag),
         %Attr{value: {:string, "combobox"}} <- attr(tag, "type"),
         %Attr{} = variant <- attr(tag, "variant") do
      [finding(tag, variant)]
    else
      _ -> []
    end
  end

  def check(_tag, _ctx), do: []

  defp attr(%Tag{attrs: attrs}, name), do: Enum.find(attrs, &(&1.name == name))

  defp finding(tag, %Attr{} = v) do
    {replacement, fix} =
      case v.value do
        {:string, value} when value in ["input", "trigger"] ->
          r = "combo_" <> v.source
          {r, "replace #{v.source} with #{r}"}

        {:string, _} ->
          {nil,
           ~s(remove #{v.source}; if you meant the combobox anatomy, set combo_variant="input" or combo_variant="trigger")}

        {:expr, _} ->
          {nil, ~s(rename it to combo_#{v.source} if the value is "input" or "trigger", else remove it)}

        nil ->
          {"", "remove variant"}
      end

    Rule.finding(rule(),
      line: v.line,
      column: v.column,
      subject: v.source,
      message: ~s(variant does nothing on <.field type="combobox">: the combobox anatomy attr is combo_variant),
      replacement: replacement,
      fix: fix,
      tag_line: tag.line
    )
  end
end
