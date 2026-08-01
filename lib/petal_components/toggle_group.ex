defmodule PetalComponents.ToggleGroup do
  use Phoenix.Component

  alias PetalComponents.Helpers

  @doc """
  A segmented selection control: one rail of options where the pressed state
  is the point. Where `button_group` groups *actions* (press one, something
  happens, nothing stays lit), `toggle_group` holds a *selection* - exactly
  one option (default) or any number of them (`multiple`).

  The component is stateless and server-driven, the LiveView way: you pass
  the current `value`, it renders `aria-pressed` accordingly, and every press
  sends `on_change` with the pressed option in `phx-value-toggle`. No hook,
  no client state.

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

  Values survive the `phx-value-*` string round-trip: pressed comparison is
  string-based, so `value={2}` still highlights after the server re-assigns
  the `"2"` it received.
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

  attr :size, :string, default: "md", values: ["sm", "md", "lg"]
  attr :disabled, :boolean, default: false, doc: "disables every item"
  attr :class, :any, default: nil, doc: "extra classes for the rail"
  attr :rest, :global

  slot :item, required: true, validate_attrs: false do
    attr :value, :any, required: true, doc: "the option this item represents"
    attr :disabled, :boolean, doc: "disables this item only"
    attr :class, :any, doc: "extra classes for this item"
  end

  def toggle_group(assigns) do
    ~H"""
    <div
      id={@id || Helpers.uniq_id("toggle-group")}
      role="group"
      aria-label={@aria_label}
      class={["pc-toggle-group", "pc-toggle-group--#{@size}", @class]}
      {@rest}
    >
      <button
        :for={item <- @item}
        type="button"
        aria-pressed={to_string(pressed?(item[:value], @value, @multiple))}
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

  # phx-value-* delivers strings, so a caller who assigns the event payload
  # back into `value` still gets a pressed match against non-string options.
  defp pressed?(item_value, value, false), do: same?(item_value, value)

  defp pressed?(item_value, values, true) when is_list(values),
    do: Enum.any?(values, &same?(item_value, &1))

  defp pressed?(_item_value, _values, true), do: false

  defp same?(_item_value, nil), do: false
  defp same?(item_value, value), do: to_string(item_value) == to_string(value)

  @slot_keys [:value, :disabled, :class, :inner_block, :__slot__]

  defp item_rest(item), do: Map.drop(item, @slot_keys)
end
