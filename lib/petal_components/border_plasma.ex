defmodule PetalComponents.BorderPlasma do
  @moduledoc """
  A glowing border that either breathes in place or sweeps a conic gradient
  around the ring. Pure CSS (registered custom properties + a masked border
  ring) — no JavaScript required.

  The sibling of `border_beam`: where the beam sends one travelling light
  around the edge, plasma lights the whole ring at once. Good for CTAs,
  pricing cards and hero panels that need to pull the eye without moving
  anything across the screen.
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

  attr :color_from, :string,
    default: nil,
    doc: "start colour of the glow. Defaults to the theme's primary-500 token"

  attr :color_to, :string,
    default: nil,
    doc: "end colour of the glow. Defaults to the theme's secondary-500 token"

  attr :duration, :string,
    default: nil,
    doc:
      "length of one breath (pulse) or one lap (rotate). Defaults to 4s for pulse, 6s for rotate"

  attr :intensity, :string,
    default: "medium",
    values: ["subtle", "medium", "strong"],
    doc: "how bright the ring burns and how far the bloom carries past the edge"

  attr :spread, :string,
    default: nil,
    doc:
      "blur radius of the outer bloom, overriding the intensity's default. Larger values halo further out"

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

  Sweep a gradient around the ring instead of breathing it:

      <.border_plasma mode="rotate" duration="4s">
        ...
      </.border_plasma>

  Wrap a CTA, turn the glow up, and pick your own colours:

      <.border_plasma intensity="strong" color_from="#f43f5e" color_to="#3b82f6">
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
        assigns.spread && "--pc-plasma-spread: #{assigns.spread}",
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
        @class
      ]}
      style={@style}
      {@rest}
    >
      <div class="pc-border-plasma__bloom" aria-hidden="true"></div>
      <div class="pc-border-plasma__ring" aria-hidden="true"></div>
      <div class="pc-border-plasma__content">{render_slot(@inner_block)}</div>
    </div>
    """
  end
end
