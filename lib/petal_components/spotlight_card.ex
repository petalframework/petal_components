defmodule PetalComponents.SpotlightCard do
  @moduledoc """
  A card with a radial glow that follows the cursor — a subtle "premium"
  hover effect for feature grids and pricing cards.

  Requires the `PetalSpotlight` hook from the JS bundle (a few lines that
  track the cursor into CSS variables; the glow itself is pure CSS).
  """
  use Phoenix.Component

  attr :id, :string, required: true

  attr :spotlight_color, :string,
    default: "rgb(120 119 198 / 0.18)",
    doc: "color of the glow (any CSS color, ideally with alpha)"

  attr :spotlight_size, :string, default: "350px", doc: "radius of the glow"
  attr :class, :any, default: nil, doc: "extra classes for the card"
  attr :rest, :global

  slot :inner_block, required: true

  @doc """
  Renders a card whose glow tracks the cursor.

      <div class="grid grid-cols-3 gap-4">
        <.spotlight_card :for={feature <- @features} id={feature.id}>
          <div class="p-6">
            <.h4>{feature.title}</.h4>
            <.p>{feature.description}</.p>
          </div>
        </.spotlight_card>
      </div>
  """
  def spotlight_card(assigns) do
    assigns =
      assign(
        assigns,
        :style,
        "--pc-spotlight-color: #{assigns.spotlight_color}; --pc-spotlight-size: #{assigns.spotlight_size};"
      )

    ~H"""
    <div
      id={@id}
      class={["pc-spotlight-card", @class]}
      style={@style}
      phx-hook="PetalSpotlight"
      {@rest}
    >
      <div class="pc-spotlight-card__glow" aria-hidden="true"></div>
      <div class="pc-spotlight-card__content">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
