defmodule PetalComponents.ToggleGroup do
  use Phoenix.Component

  alias PetalComponents.Helpers

  @doc """
  A segmented selection control: one rail of options where the pressed state
  is the point. Where `button_group` groups *actions* (press one, something
  happens, nothing stays lit), `toggle_group` holds a *selection* - exactly
  one option (default) or any number of them (`multiple`).

  The component is stateless and server-driven, the LiveView way: you pass
  the current `value`, every press sends `on_change` with the pressed option
  in `phx-value-toggle`, and you assign the value back. No hook, no client
  state.

  Single select renders **native radio inputs** (the same mechanics as the
  colour-scheme switch's segmented variant): real radiogroup semantics, one
  tab stop, and arrow keys move the selection - the full WAI-ARIA radio
  pattern with zero JavaScript. Multiple select renders `aria-pressed`
  toggle buttons, the toolbar pattern.

  ## Single select - a density rail

      <.toggle_group aria_label="Density" value={@density} on_change="set_density">
        <:item value="compact">Compact</:item>
        <:item value="cozy">Cozy</:item>
        <:item value="comfortable">Comfortable</:item>
      </.toggle_group>

      def handle_event("set_density", %{"toggle" => density}, socket) do
        {:noreply, assign(socket, density: density)}
      end

  ## Multiple select - formatting toggles

  With `multiple`, `value` is a list and the server owns the toggle logic:

      <.toggle_group multiple aria_label="Formatting" value={@formats} on_change="toggle_format">
        <:item value="bold" aria-label="Bold"><.icon name="hero-bold" /></:item>
        <:item value="italic" aria-label="Italic"><.icon name="hero-italic" /></:item>
      </.toggle_group>

      def handle_event("toggle_format", %{"toggle" => format}, socket) do
        formats = socket.assigns.formats

        formats =
          if format in formats, do: List.delete(formats, format), else: [format | formats]

        {:noreply, assign(socket, formats: formats)}
      end

  ## Variants

  `variant="solid"` (default) is the wash rail with a neutral chip - the
  segmented-control look the scheme switch uses. `variant="outline"` is the
  bordered toolbar rail with floating chips, at home next to a
  `button_group`. `variant="accent"` keeps the wash rail but paints the
  selection in the brand accent, for a committed setting rather than a view
  preference.

  Values survive the `phx-value-*` string round-trip: pressed comparison is
  string-based, so `value={2}` still highlights after the server re-assigns
  the `"2"` it received.

  The single-select radios detach themselves from any surrounding form
  (their `form` attribute points at nothing), so dropping a toggle group
  inside a `<.form>` never posts a stray `"<id>-toggle"` param.
  """

  attr :id, :string, default: nil
  attr :aria_label, :string, required: true, doc: "the ARIA label for the group"

  attr :value, :any,
    default: nil,
    doc: "the selected value - a single term, or a list when `multiple`"

  attr :on_change, :any,
    default: nil,
    doc:
      "event name (or JS command) sent on press; the pressed option arrives in phx-value-toggle. Omit it and put phx-click on individual items instead"

  attr :multiple, :boolean,
    default: false,
    doc: "treat value as a list; any number of options can be pressed"

  attr :variant, :string,
    default: "solid",
    values: ["solid", "outline", "accent"],
    doc:
      "solid is the wash rail with a neutral chip; outline is the bordered toolbar rail; accent paints the selection in the brand colour"

  attr :size, :string, default: "md", values: ["sm", "md", "lg"]
  attr :disabled, :boolean, default: false, doc: "disables every item"
  attr :class, :any, default: nil, doc: "extra classes for the rail"
  attr :rest, :global

  slot :item, required: true, validate_attrs: false do
    attr :value, :any, required: true, doc: "the option this item represents"
    attr :disabled, :boolean, doc: "disables this item only"
    attr :class, :any, doc: "extra classes for this item"

    attr :"aria-label", :string,
      doc: "accessible name for icon-only items - reaches the radio/button itself"
  end

  def toggle_group(%{multiple: true} = assigns) do
    assigns = assign_id(assigns)

    ~H"""
    <div
      id={@id}
      role="group"
      aria-label={@aria_label}
      class={rail_class(assigns)}
      {@rest}
    >
      <button
        :for={item <- @item}
        type="button"
        aria-pressed={to_string(pressed?(item[:value], @value, true))}
        disabled={@disabled || item[:disabled]}
        phx-click={@on_change}
        phx-value-toggle={item[:value]}
        class={["pc-toggle-group__item", item[:class]]}
        {item_rest(item)}
      >
        {render_slot(item)}
      </button>
    </div>
    """
  end

  def toggle_group(assigns) do
    assigns = assign_id(assigns)

    ~H"""
    <div
      id={@id}
      role="radiogroup"
      aria-label={@aria_label}
      class={rail_class(assigns)}
      {@rest}
    >
      <label
        :for={item <- @item}
        class={["pc-toggle-group__item", item[:class]]}
      >
        <input
          type="radio"
          name={"#{@id}-toggle"}
          value={item[:value]}
          form={"#{@id}-no-form"}
          checked={pressed?(item[:value], @value, false)}
          disabled={@disabled || item[:disabled]}
          class="pc-toggle-group__input"
          phx-click={@on_change}
          phx-value-toggle={item[:value]}
          {item_rest(item)}
        />
        <span class="pc-toggle-group__content">{render_slot(item)}</span>
      </label>
    </div>
    """
  end

  # Assigned once because the generated id feeds three attributes (the rail id,
  # the radios' shared name, the form detach target) that must agree.
  defp assign_id(assigns),
    do: assign(assigns, :id, assigns.id || Helpers.uniq_id("toggle-group"))

  defp rail_class(assigns) do
    [
      "pc-toggle-group",
      "pc-toggle-group--#{assigns.size}",
      assigns.variant != "solid" && "pc-toggle-group--#{assigns.variant}",
      assigns.class
    ]
  end

  # phx-value-* delivers strings, so a caller who assigns the event payload
  # back into `value` still gets a pressed match against non-string options.
  defp pressed?(item_value, values, true) when is_list(values),
    do: Enum.any?(values, &same?(item_value, &1))

  defp pressed?(_item_value, _values, true), do: false
  defp pressed?(item_value, value, false), do: same?(item_value, value)

  defp same?(_item_value, nil), do: false
  defp same?(item_value, value), do: to_string(item_value) == to_string(value)

  @slot_keys [:value, :disabled, :class, :inner_block, :__slot__]

  defp item_rest(item), do: Map.drop(item, @slot_keys)
end
