defmodule PetalComponents.BorderPlasma do
  @moduledoc """
  A border of whispery, warping light: long thin washes of colour ride a
  hairline rim, whole corners swell and dissipate on their own clocks, and
  by default a soft halo spills past the border onto the page. Set
  `clip` and every layer stays inside the panel's crisp silhouette
  instead. Pure CSS (registered custom properties driving one shared
  gradient field through three differently-masked layers) — no JavaScript
  required.

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
  @default_durations %{"pulse" => "2.3s", "rotate" => "6s"}

  attr :mode, :string,
    default: "pulse",
    values: ["pulse", "rotate"],
    doc:
      "pulse breathes the whole ring in place; rotate sweeps a conic gradient arc around the border"

  attr :palette, :string,
    default: "rainbow",
    values: ["rainbow", "brand", "mono", "ocean", "sunset"],
    doc:
      "where the light gets its colours: an eight-hue rainbow (the reference look), the theme's primary/secondary (brand), grayscale (mono), blues (ocean), or ambers (sunset)"

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

  attr :clip, :boolean,
    default: false,
    doc:
      "false (default) lets the glow halo spill past the border onto the page; true keeps every layer inside the panel's silhouette"

  attr :border_width, :string,
    default: "1px",
    doc:
      "thickness of the glowing rim line. The reference look is a 1px hairline; 2px+ reads as a band"

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
        @clip && "pc-border-plasma--clip",
        @class
      ]}
      style={@style}
      {@rest}
    >
      <%!-- Halo layers sit at z-index -1: painted over the page but under the
      panel's content. In clip mode the same two become the inner wash and
      the blurred ring. The stroke and sheen paint after the content - the
      hairline rides the rim, never over the middle. --%>
      <div class="pc-border-plasma__bloom" aria-hidden="true"></div>
      <div class="pc-border-plasma__core" aria-hidden="true"></div>
      <div class="pc-border-plasma__content">{render_slot(@inner_block)}</div>
      <div class="pc-border-plasma__stroke" aria-hidden="true"></div>
      <div class="pc-border-plasma__sheen" aria-hidden="true"></div>
    </div>
    """
  end
end
