defmodule PetalComponents.BorderBeam do
  @moduledoc """
  An animated beam of light that travels along the border of its container.
  Pure CSS (`offset-path` animation) — no JavaScript required.

  Great for drawing attention to a card, CTA or auth form on a landing page.
  """
  use Phoenix.Component

  # A damped-spring position curve for the CSS linear() timing function:
  # accelerates in, overshoots the lap seam by ~9%, settles back. Gives the
  # springy per-lap motion of MagicUI's framer-motion spring, without JS.
  @spring_easing "linear(0, 0.007, 0.029, 0.065, 0.116, 0.182, 0.263, 0.359, 0.469, 0.593, 0.731, 0.882, 1.046 63.6%, 1.088, 1.098, 1.092, 1.078, 1.061, 1.045, 1.031, 1.02, 1.011, 1.005, 1.001, 1)"

  attr :color_from, :string, default: "#ffaa40", doc: "start color of the beam gradient"
  attr :color_to, :string, default: "#9c40ff", doc: "end color of the beam gradient"

  attr :duration, :string,
    default: "8s",
    doc: "time the beam takes to travel the full border once"

  attr :delay, :string, default: "0s", doc: "phase offset for the beam (applied as a head start)"

  attr :size, :string,
    default: "150px",
    doc: "length of the beam. Also sets how widely the beam swings through corners"

  attr :border_radius, :string,
    default: nil,
    doc:
      "border radius of the container. When unset, follows the theme radius (--pc-radius, scaled for panels)"

  attr :border_width, :string, default: "1px", doc: "width of the border the beam runs along"

  attr :beams, :integer,
    default: 1,
    doc: "number of beams, evenly phased around the border"

  attr :reverse, :boolean, default: false, doc: "run the beam anticlockwise"

  attr :easing, :string,
    default: "linear",
    values: ["linear", "ease-in-out", "spring"],
    doc:
      "beam motion: linear for constant speed, ease-in-out for a glide, spring for a springy lap with a settle at the seam"

  attr :class, :any, default: nil, doc: "extra classes for the container"
  attr :rest, :global

  slot :inner_block, required: true

  @doc """
  Wraps any content in a bordered panel with an animated light beam running
  along the border. The panel carries the surface (background, border,
  radius) — put plain content inside, not another card.

      <.border_beam>
        <div class="p-8">
          <.h3>Sign in</.h3>
          ...
        </div>
      </.border_beam>

  Customise the look:

      <.border_beam color_from="#38bdf8" color_to="#818cf8" duration="6s" size="200px">
        ...
      </.border_beam>

  Two beams chasing each other, springing around the corners:

      <.border_beam beams={2} easing="spring" duration="6s">
        ...
      </.border_beam>
  """
  def border_beam(assigns) do
    style =
      [
        "--pc-beam-from: #{assigns.color_from}",
        "--pc-beam-to: #{assigns.color_to}",
        "--pc-beam-duration: #{assigns.duration}",
        "--pc-beam-delay: #{assigns.delay}",
        "--pc-beam-size: #{assigns.size}",
        "--pc-beam-border-width: #{assigns.border_width}",
        "--pc-beam-ease: #{resolve_easing(assigns.easing)}",
        assigns.reverse && "--pc-beam-direction: reverse",
        assigns.reverse && "--pc-beam-rotate: reverse",
        assigns.border_radius && "--pc-beam-radius: #{assigns.border_radius}"
      ]
      |> Enum.filter(& &1)
      |> Enum.join("; ")

    assigns =
      assigns
      |> assign(:style, style)
      |> assign(:phases, beam_phases(assigns.beams))

    ~H"""
    <div class={["pc-border-beam", @class]} style={@style} {@rest}>
      <div
        :for={phase <- @phases}
        class="pc-border-beam__beam"
        style={"--pc-beam-phase: #{phase}"}
        aria-hidden="true"
      >
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp resolve_easing("spring"), do: @spring_easing
  defp resolve_easing(easing), do: easing

  defp beam_phases(count) when count <= 1, do: ["0"]

  defp beam_phases(count) do
    Enum.map(0..(count - 1), fn index ->
      Float.round(-index / count, 4) |> to_string()
    end)
  end
end
