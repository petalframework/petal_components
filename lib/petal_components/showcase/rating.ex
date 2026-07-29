defmodule PetalComponents.Showcase.Rating do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Rating, title: "Rating"

  example :interactive, "Interactive",
    description:
      "interactive renders a fieldset of real radios: the value posts under name like any form field, arrow keys move between options, the hover preview is pure CSS, and focus-visible rings the focused icon. Zero JavaScript. precision=\"half\" doubles the hit areas so 3.5 is clickable." do
    ~H"""
    <form>
      <.rating interactive name="score" rating={3} precision="half" include_label />
    </form>
    """
  end

  example :sentiment, "The sentiment scale",
    description:
      "icon=\"face\" swaps stars for five expressions, each its own colour - the CSAT scale. Faces are ordinal, so they always step whole; fractional display values round to the nearest expression with the label carrying the precision." do
    ~H"""
    <.rating interactive name="csat" rating={0} icon="face" size="lg" label="How was your experience?" />
    """
  end

  example :display, "Display only",
    description:
      "Without interactive it's a read-only display: fractional values render partial fills, include_label prints the number beside the icons." do
    ~H"""
    <div class="flex flex-col items-center gap-4">
      <.rating rating={3.5} include_label />
      <.rating rating={3.5} icon="heart" include_label />
      <.rating rating={4.2} icon="face" include_label />
    </div>
    """
  end

  example :custom_glyph, "Bring your own glyph",
    description:
      "The :glyph slot swaps in any SVG, and --pc-rating-active-color recolours the active state per instance - one slot and one token for a fully custom scale." do
    ~H"""
    <.rating
      interactive
      name="heat"
      rating={3}
      label="Spice level"
      style="--pc-rating-active-color: var(--color-orange-500)"
    >
      <:glyph>
        <svg viewBox="0 0 24 24" fill="currentColor" class="pc-rating__icon">
          <path
            fill-rule="evenodd"
            d="M12.963 2.286a.75.75 0 00-1.071-.136 9.742 9.742 0 00-3.539 6.176 7.547 7.547 0 01-1.705-1.715.75.75 0 00-1.152-.082A9 9 0 1015.68 4.534a7.46 7.46 0 01-2.717-2.248zM15.75 14.25a3.75 3.75 0 11-7.313-1.172c.628.465 1.35.81 2.133 1a5.99 5.99 0 011.925-3.545 3.75 3.75 0 013.255 3.717z"
            clip-rule="evenodd"
          />
        </svg>
      </:glyph>
    </.rating>
    """
  end
end
