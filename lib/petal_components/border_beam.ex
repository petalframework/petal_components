defmodule PetalComponents.BorderBeam do
  @moduledoc """
  An animated beam of light that travels along the border of its container.
  Pure CSS (`offset-path` animation) — no JavaScript required.

  Great for drawing attention to a card, CTA or auth form on a landing page.
  """
  use Phoenix.Component

  attr :color_from, :string, default: "#ffaa40", doc: "start color of the beam gradient"
  attr :color_to, :string, default: "#9c40ff", doc: "end color of the beam gradient"

  attr :duration, :string,
    default: "8s",
    doc: "time the beam takes to travel the full border once"

  attr :size, :string, default: "150px", doc: "length of the beam"

  attr :border_radius, :string,
    default: "0.75rem",
    doc: "border radius of the container (the beam follows it)"

  attr :class, :any, default: nil, doc: "extra classes for the container"
  attr :rest, :global

  slot :inner_block, required: true

  @doc """
  Wraps any content in a bordered container with an animated light beam
  running along the border.

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
  """
  def border_beam(assigns) do
    assigns =
      assign(
        assigns,
        :style,
        "--pc-beam-from: #{assigns.color_from}; " <>
          "--pc-beam-to: #{assigns.color_to}; " <>
          "--pc-beam-duration: #{assigns.duration}; " <>
          "--pc-beam-size: #{assigns.size}; " <>
          "--pc-beam-radius: #{assigns.border_radius};"
      )

    ~H"""
    <div class={["pc-border-beam", @class]} style={@style} {@rest}>
      <div class="pc-border-beam__beam" aria-hidden="true"></div>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
