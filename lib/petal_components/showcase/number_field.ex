defmodule PetalComponents.Showcase.NumberField do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.NumberField, title: "Number field"

  example :basic, "The default spinner",
    description:
      "A text input carrying role=\"spinbutton\", not <input type=\"number\">, so the steppers look the same in every browser and a half-typed value survives. Arrows step, shift+arrow steps by big_step, Home and End jump to the bounds. The input is the only tab stop; the buttons sit at tabindex=\"-1\" with labels, the way the ARIA spinbutton pattern asks." do
    ~H"""
    <.number_field name="quantity" value="12" min={0} max={99} />
    """
  end

  example :split, "Split buttons",
    description:
      "Minus at the start, plus at the end, value centred - the cart-quantity anatomy. At a bound the button greys out with aria-disabled rather than disabled, so it keeps its name for a screen reader instead of vanishing. This one sits at its minimum." do
    ~H"""
    <.number_field name="cart_quantity" value="1" min={1} max={10} variant="split" />
    """
  end

  example :addons, "Addons and precision",
    description:
      "Leading and trailing addons ride the same input-group surface the rest of the library uses. precision rounds and pads on blur while the raw text stands while you type - the whole built-in formatting story. For currency or percent display, format on blur with Intl.NumberFormat; the moduledoc has the pattern." do
    ~H"""
    <div class="flex flex-col gap-4">
      <.number_field name="price" value="24.5" min={0} step={0.5} precision={2}>
        <:leading>$</:leading>
      </.number_field>
      <.number_field name="allocation" value="25" min={0} max={100} step={5} big_step={25}>
        <:trailing>%</:trailing>
      </.number_field>
    </div>
    """
  end

  example :sizes, "Sizes",
    description:
      "sm, md and lg move the input density and the button hit areas together, so the control stays square with the inputs beside it." do
    ~H"""
    <div class="flex flex-col gap-4">
      <.number_field name="size_sm" value="1" size="sm" />
      <.number_field name="size_md" value="1" size="md" />
      <.number_field name="size_lg" value="1" size="lg" />
    </div>
    """
  end

  example :plain, "Plain, and disabled",
    description:
      "variant=\"plain\" drops the buttons for keyboard, wheel and typing only - the dense-table flavour. disabled uses the native attribute on the input and both buttons, so nothing is reachable by pointer or keyboard." do
    ~H"""
    <div class="flex flex-col gap-4">
      <.number_field name="plain_qty" value="7" variant="plain" min={0} max={100} />
      <.number_field name="disabled_qty" value="7" disabled />
    </div>
    """
  end

  example :in_a_field, "In a form field",
    description:
      "type=\"number-field\" wires it into <.field>, so the label, help text and error tone come from the shared form-field machinery - the error ring is painted by the wrapper on the input-group surface, with no number-field-specific styling." do
    ~H"""
    <div class="flex flex-col gap-2">
      <.field
        type="number-field"
        name="seats"
        value="3"
        label="Seats"
        min={1}
        max={20}
        help_text="Between 1 and 20."
      />
      <.field
        type="number-field"
        name="seats_error"
        value="0"
        label="Seats"
        min={1}
        errors={["must be at least 1"]}
      />
    </div>
    """
  end
end
