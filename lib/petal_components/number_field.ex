defmodule PetalComponents.NumberField do
  @moduledoc """
  A numeric spinbutton: one real input on the input-group surface, with
  decrement and increment buttons, clamping, and a full keyboard map.

  Reach for it wherever a quantity, a price or a percentage is typed. It
  replaces `<input type="number">`, whose spinners are unstyleable and
  inconsistent across browsers, and whose value sanitising fights any kind of
  display formatting.

  ## Why not `type="number"`

  The control renders `<input type="text" inputmode="decimal">` carrying
  `role="spinbutton"`, the WAI-ARIA pattern for exactly this widget. That buys:

    * spinners we draw ourselves, identical in every browser
    * `precision` formatting on blur, which `type="number"` silently discards
    * a value that stays readable while editing, since the browser never
      "sanitises" a half-typed number to the empty string
    * the numeric keypad on mobile, via `inputmode`

  What it costs: native constraint validation. `min` and `max` are enforced by
  the hook and mirrored to `aria-valuemin` / `aria-valuemax`, not by the
  browser, so **validate the bound on the server too** - the same as you would
  for any user-supplied number.

  ## Examples

      <.number_field name="quantity" value="1" min={1} max={99} />

      <.number_field field={@form[:quantity]} min={1} max={99} />

      <.number_field field={@form[:price]} variant="split" precision={2} step={0.5}>
        <:leading>$</:leading>
      </.number_field>

      <.number_field field={@form[:share]} min={0} max={100} step={5} big_step={25}>
        <:trailing>%</:trailing>
      </.number_field>

  Inside `<.field>` it gets a label, help text and error styling for free:

      <.field type="number-field" field={@form[:quantity]} label="Quantity" min={1} />

  ## Variants

    * `stacked` (default) - chevron up/down stacked at the inline end
    * `split` - minus at the inline start, plus at the inline end, value centred
    * `plain` - no buttons; typing, arrows and wheel only

  ## Keyboard and pointer

  | Input | Effect |
  | --- | --- |
  | `ArrowUp` / `ArrowDown` | step by `step` |
  | `Shift` + arrow | step by `big_step` (defaults to `step * 10`) |
  | `PageUp` / `PageDown` | step by `big_step` |
  | `Home` / `End` | jump to `min` / `max` when set |
  | Wheel | steps while the input is focused, and only then |
  | Press and hold a button | one step, then repeat, accelerating |

  Typed text is never clamped mid-keystroke - it is clamped and formatted on
  blur, so `1` on the way to `15` does not snap to the maximum under your
  fingers.

  ## Accessibility

  The input is the single tab stop: the buttons are `tabindex="-1"` with
  `aria-label`s, the way the APG spinbutton pattern prescribes. `aria-valuenow`
  tracks the value on every change, and a button at its bound gets
  `aria-disabled` rather than `disabled`, so it stays discoverable to a screen
  reader. A `disabled` control uses the native attribute throughout.

  Inside `<.field>` the label wires up automatically. Standalone, the input
  has NO accessible name - the APG pattern requires one, so pass
  `aria-label` (it rides through the global attrs) or reference a visible
  label with `aria-labelledby`.

  ## Formatting beyond `precision`

  `precision` rounds and pads to a fixed number of decimals on blur. That is the
  whole built-in formatting story - no locale engine, no masking dependency.

  For currency or percent display, format the visible text on blur and keep the
  raw number in the posted value, using the platform's own `Intl.NumberFormat`:

      // in your app's JS, alongside the petal hooks
      export const PriceField = {
        mounted() {
          const input = this.el.querySelector("[data-pc-number-input]");
          const fmt = new Intl.NumberFormat("en-US", {
            style: "currency",
            currency: "USD"
          });

          input.addEventListener("focus", () => {
            input.value = input.dataset.raw ?? input.value;
          });

          input.addEventListener("blur", () => {
            const n = parseFloat(input.value);
            if (Number.isNaN(n)) return;
            input.dataset.raw = String(n);
            input.value = fmt.format(n);
          });
        }
      };

  Post the raw number in a hidden input if the formatted text would confuse
  your changeset.

  ## Setup

  Needs the `PetalNumberField` hook from the petal_components JS bundle:

      import PetalComponents from "../../deps/petal_components/assets/js/petal_components.js"

      let liveSocket = new LiveSocket("/live", Socket, {
        hooks: { ...PetalComponents }
      })

  Without the hook it degrades to a plain text input that still posts its value.
  """
  use Phoenix.Component

  @doc """
  Renders a numeric spinbutton. Full documentation, including the keyboard map
  and the `Intl.NumberFormat` pattern, lives on `PetalComponents.NumberField`.
  """
  attr :id, :any, default: nil, doc: "input id; generated from the field or name if not passed"

  attr :name, :any, doc: "input name; generated from the field if not passed"

  attr :value, :any, doc: "current value; generated from the field if not passed"

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct, e.g. @form[:quantity]; sets id, name and value like other inputs"

  attr :min, :any,
    default: nil,
    doc: "lower bound; values are clamped and mirrored to aria-valuemin"

  attr :max, :any, default: nil, doc: "upper bound; clamped and mirrored to aria-valuemax"

  attr :step, :any, default: 1, doc: "increment for the buttons, arrow keys and wheel"

  attr :big_step, :any,
    default: nil,
    doc: "increment for shift+arrow and page up/down; defaults to step * 10"

  attr :precision, :integer,
    default: nil,
    doc:
      "decimal places shown on blur; the raw text stands while editing. nil means no formatting"

  attr :variant, :string,
    default: "stacked",
    values: ~w(stacked split plain),
    doc:
      "stacked: both buttons at the inline end; split: minus at the start, plus at the end; plain: no buttons"

  attr :size, :string, default: "md", values: ~w(sm md lg), doc: "input height and text size"

  attr :disabled, :boolean, default: false, doc: "disables the input and both buttons natively"

  attr :decrement_label, :string,
    default: "Decrease value",
    doc: "accessible name for the decrement button"

  attr :increment_label, :string,
    default: "Increase value",
    doc: "accessible name for the increment button"

  attr :class, :any, default: nil, doc: "extra classes for the field surface"

  attr :rest, :global,
    include: ~w(autocomplete form placeholder readonly required inputmode aria-describedby),
    doc: "all other attributes land on the input"

  slot :leading, doc: "addon before the input, e.g. a currency symbol"
  slot :trailing, doc: "addon after the input, e.g. a unit"

  def number_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(:field, nil)
    |> assign(:id, assigns.id || field.id)
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> number_field()
  end

  def number_field(assigns) do
    assigns =
      assigns
      |> assign_new(:name, fn -> nil end)
      |> assign_new(:value, fn -> nil end)

    number = to_number(assigns.value)
    min = to_number(assigns.min)
    max = to_number(assigns.max)

    # ARIA and the bound checks must describe what the user SEES: with
    # precision, value="5.5" renders "6", so aria-valuenow and at-bound
    # dimming are computed from the rounded number, never the raw parse
    # (otherwise first paint announces 5.5 against a visible 6 until the
    # hook's mount-time sync papers over it).
    rounded = round_to_precision(number, assigns.precision)
    display = display_value(number, assigns.value, assigns.precision)

    assigns =
      assigns
      |> assign(:id, resolve_id(assigns.id, assigns.name))
      |> assign(:display, display)
      |> assign(
        :value_now,
        if(rounded && is_integer(assigns.precision), do: display, else: rounded)
      )
      |> assign(:at_min, at_bound?(rounded, min, :min))
      |> assign(:at_max, at_bound?(rounded, max, :max))
      |> assign(:big_step, assigns.big_step || big_step_default(assigns.step))
      |> assign(:show_buttons, assigns.variant != "plain")

    ~H"""
    <PetalComponents.InputGroup.input_group
      id={@id <> "-field"}
      phx-hook="PetalNumberField"
      class={[
        "pc-number-field",
        "pc-number-field--#{@variant}",
        "pc-number-field--#{@size}",
        @class
      ]}
      data-min={@min}
      data-max={@max}
      data-step={@step}
      data-big-step={@big_step}
      data-precision={@precision}
    >
      <:leading :if={@leading != [] or (@show_buttons and @variant == "split")}>
        <.spin_button
          :if={@show_buttons and @variant == "split"}
          direction="dec"
          icon="minus"
          label={@decrement_label}
          disabled={@disabled}
          at_bound={@at_min}
        />
        {render_slot(@leading)}
      </:leading>
      <input
        type="text"
        inputmode="decimal"
        autocomplete="off"
        id={@id}
        name={@name}
        value={@display}
        class="pc-number-field__input"
        role="spinbutton"
        aria-valuenow={@value_now}
        aria-valuemin={@min}
        aria-valuemax={@max}
        disabled={@disabled}
        data-pc-number-input
        {@rest}
      />
      <:trailing :if={@trailing != [] or @show_buttons}>
        {render_slot(@trailing)}
        <div :if={@show_buttons and @variant == "stacked"} class="pc-number-field__stack">
          <.spin_button
            direction="inc"
            icon="chevron-up"
            label={@increment_label}
            disabled={@disabled}
            at_bound={@at_max}
          />
          <.spin_button
            direction="dec"
            icon="chevron-down"
            label={@decrement_label}
            disabled={@disabled}
            at_bound={@at_min}
          />
        </div>
        <.spin_button
          :if={@show_buttons and @variant == "split"}
          direction="inc"
          icon="plus"
          label={@increment_label}
          disabled={@disabled}
          at_bound={@at_max}
        />
      </:trailing>
    </PetalComponents.InputGroup.input_group>
    """
  end

  attr :direction, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :disabled, :boolean, required: true
  attr :at_bound, :boolean, required: true

  defp spin_button(assigns) do
    ~H"""
    <button
      type="button"
      tabindex="-1"
      class={["pc-number-field__button", "pc-number-field__button--#{@direction}"]}
      aria-label={@label}
      aria-disabled={@at_bound && "true"}
      disabled={@disabled}
      data-pc-number-step={@direction}
    >
      <PetalComponents.Icon.icon name={"hero-#{@icon}-micro"} class="pc-number-field__icon" />
    </button>
    """
  end

  @doc """
  The input id this component would render for a given `id` and `name`.

  `<.field type="number-field">` calls it so the label's `for=` names the same
  control the hook addresses. One identity, no way for the two to drift.
  """
  # No identity at all is a programming error, not something to paper over
  # with a constant id that would collide on the second instance.
  @spec resolve_id(String.t() | nil, String.t() | nil) :: String.t()
  def resolve_id(id, _name) when is_binary(id) and id != "", do: id

  def resolve_id(_id, name) when is_binary(name) and name != "",
    do: "number_field_" <> String.replace(name, ~r/[^A-Za-z0-9_]/, "_")

  def resolve_id(_id, _name) do
    raise ArgumentError,
          "number_field requires a field, an id or a name to derive its id from " <>
            "(the hook and the label both need to address the input)"
  end

  # Bounds only bite once we know the value is a number. A blank or
  # part-typed field disables nothing.
  defp at_bound?(nil, _bound, _side), do: false
  defp at_bound?(_value, nil, _side), do: false
  defp at_bound?(value, bound, :min), do: value <= bound
  defp at_bound?(value, bound, :max), do: value >= bound

  defp big_step_default(step) do
    case to_number(step) do
      nil -> 10
      n -> trim_float(n * 10)
    end
  end

  # `precision` is a display concern: it fires on blur in the hook, and the
  # server renders the same shape so the first paint matches. Anything we
  # cannot read as a number rides through untouched - a half-typed value
  # belongs to the user, not to us.
  defp display_value(nil, raw, _precision), do: normalize(raw)
  defp display_value(_number, raw, nil), do: normalize(raw)

  defp display_value(number, _raw, precision) when is_integer(precision) and precision >= 0 do
    :erlang.float_to_binary(number / 1, decimals: precision)
  end

  defp display_value(_number, raw, _precision), do: normalize(raw)

  # The numeric twin of display_value/3: what the rendered string means as a
  # number, for aria-valuenow and the at-bound checks.
  defp round_to_precision(nil, _precision), do: nil

  defp round_to_precision(number, precision) when is_integer(precision) and precision >= 0 do
    Float.round(number / 1, precision)
  end

  defp round_to_precision(number, _precision), do: number

  defp normalize(nil), do: nil
  defp normalize(value) when is_binary(value), do: value
  defp normalize(value), do: to_string(value)

  defp to_number(nil), do: nil
  defp to_number(value) when is_integer(value), do: value
  defp to_number(value) when is_float(value), do: trim_float(value)

  defp to_number(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} ->
        int

      _ ->
        case Float.parse(value) do
          {float, ""} -> trim_float(float)
          _ -> nil
        end
    end
  end

  # Decimal is not a dependency here, so a Decimal (or any other struct that
  # prints as a number) goes through its String.Chars form.
  defp to_number(%_{} = value) do
    if String.Chars.impl_for(value), do: value |> to_string() |> to_number()
  end

  defp to_number(_), do: nil

  # 5.0 renders as "5" in aria-valuenow and in a step default; a trailing .0
  # is noise a screen reader would read aloud.
  defp trim_float(float) do
    truncated = trunc(float)
    if float == truncated, do: truncated, else: float
  end
end
