defmodule PetalComponents.BorderBeam do
  @moduledoc """
  An animated beam of light that travels along the border of its container.
  Pure CSS (`offset-path` animation) — no JavaScript required.

  Great for drawing attention to a card, CTA or auth form on a landing page.
  """
  use Phoenix.Component

  # A critically-damped spring position curve for the CSS linear() timing
  # function: fast rise, long settle, strictly monotonic. Overshoot is
  # deliberately zero - on a closed path even a few percent of overshoot is
  # a huge visible backwards excursion at the lap seam.
  @spring_easing "linear(0.0, 0.0617, 0.1918, 0.3384, 0.4765, 0.5958, 0.6937, 0.7713, 0.8313, 0.877, 0.9112, 0.9365, 0.9552, 0.9687, 0.9785, 0.9856, 0.9907, 0.9943, 0.9969, 0.9987, 1)"

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
      "beam motion: linear for constant speed, ease-in-out for a glide, spring for a springy lap with a settle at the seam. Spring applies to a single beam; with beams > 1 motion stays linear so the chase remains even"

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
        "--pc-beam-ease: #{resolve_easing(assigns.easing, assigns.beams)}",
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

  # Spring is a per-lap surge-and-settle; staggered beams sharing it lurch
  # and park alternately, so multi-beam runs keep constant speed instead.
  defp resolve_easing("spring", beams) when beams > 1, do: "linear"
  defp resolve_easing("spring", _beams), do: @spring_easing
  defp resolve_easing(easing, _beams), do: easing

  defp beam_phases(count) when count <= 1, do: ["0"]

  defp beam_phases(count) do
    Enum.map(0..(count - 1), fn index ->
      Float.round(-index / count, 4) |> to_string()
    end)
  end
end
