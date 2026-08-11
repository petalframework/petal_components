defmodule PetalComponents.BorderPlasma do
  @moduledoc """
  A border made of jewels of light: many small pools of colour parked
  around the rim, breathing out of phase and washing inward over the
  panel's edge - clipped at the border, so the silhouette stays crisp and
  the light lives on the glass. Pure CSS (registered custom properties and
  a plus-lighter inner layer) — no JavaScript required.

  The sibling of `border_beam`: the beam sends one travelling light around
  the edge; plasma keeps a field of light alive on it. `mode="pulse"`
  (default) breathes the jewels in place; `mode="rotate"` sweeps a neutral
  arc of light around the rim that illuminates them as it passes. Good for
  CTAs, pricing cards and hero panels that need to pull the eye without
  moving anything across the screen.
  """
  use Phoenix.Component

  # Pulse is a slow breath; rotate is a lap. Sharing one number would make
  # one of them wrong, so the default follows the mode.
  @default_durations %{"pulse" => "4s", "rotate" => "6s"}

  attr :mode, :string,
    default: "pulse",
    values: ["pulse", "rotate"],
    doc:
      "pulse breathes the whole ring in place; rotate sweeps a conic gradient arc around the border"

  attr :palette, :string,
    default: "rainbow",
    values: ["rainbow", "brand", "mono"],
    doc:
      "where the jewels get their colours: an eight-hue rainbow (the reference look), the theme's primary/secondary (brand), or grayscale (mono)"

  attr :color_from, :string,
    default: nil,
    doc: "palette=\"brand\" only: overrides the primary anchor colour"

  attr :color_to, :string,
    default: nil,
    doc: "palette=\"brand\" only: overrides the secondary anchor colour"

  attr :duration, :string,
    default: nil,
    doc:
      "length of one breath (pulse) or one lap (rotate). Defaults to 4s for pulse, 6s for rotate"

  attr :intensity, :string,
    default: "medium",
    values: ["subtle", "medium", "strong"],
    doc: "how bright the rim jewels burn and how much light washes inward over the panel"

  attr :border_width, :string,
    default: "2px",
    doc: "thickness of the glowing ring. 1px reads as a hairline, 3px+ as a band"

  attr :border_radius, :string,
    default: nil,
    doc:
      "border radius of the container. When unset, follows the theme radius (--pc-radius, scaled for panels)"

  attr :class, :any, default: nil, doc: "extra classes for the container"
  attr :rest, :global

  slot :inner_block, required: true

  @doc """
  Wraps any content in a bordered panel with a glowing border. The panel
  carries the surface (background, border, radius) — put plain content
  inside, not another card.

      <.border_plasma>
        <div class="p-8">
          <.h3>Upgrade to Pro</.h3>
          ...
        </div>
      </.border_plasma>

  Sweep a light around the rim instead of breathing it:

      <.border_plasma mode="rotate" duration="4s">
        ...
      </.border_plasma>

  Stay on brand instead of the rainbow, or turn the glow up on a CTA:

      <.border_plasma palette="brand">...</.border_plasma>

      <.border_plasma intensity="strong" palette="brand" color_from="#f43f5e" color_to="#3b82f6">
        <div class="px-6 py-2.5 font-medium">Buy now</div>
      </.border_plasma>
  """
  def border_plasma(assigns) do
    style =
      [
        "--pc-plasma-duration: #{assigns.duration || @default_durations[assigns.mode]}",
        "--pc-plasma-border-width: #{assigns.border_width}",
        assigns.color_from && "--pc-plasma-from: #{assigns.color_from}",
        assigns.color_to && "--pc-plasma-to: #{assigns.color_to}",
        assigns.border_radius && "--pc-plasma-radius: #{assigns.border_radius}"
      ]
      |> Enum.filter(& &1)
      |> Enum.join("; ")

    assigns = assign(assigns, :style, style)

    ~H"""
    <div
      class={[
        "pc-border-plasma",
        "pc-border-plasma--#{@mode}",
        "pc-border-plasma--#{@intensity}",
        "pc-border-plasma--#{@palette}",
        @class
      ]}
      style={@style}
      {@rest}
    >
      <div class="pc-border-plasma__jewels" aria-hidden="true"></div>
      <div class="pc-border-plasma__sheen" aria-hidden="true"></div>
      <div class="pc-border-plasma__content">{render_slot(@inner_block)}</div>
      <%!-- Painted after the content so the spill sits over the panel's edge
      without z-index games; plus-lighter only ever ADDS light, so nothing
      underneath is obscured. --%>
      <div class="pc-border-plasma__inner" aria-hidden="true"></div>
    </div>
    """
  end
end
