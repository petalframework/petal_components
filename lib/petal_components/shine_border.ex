defmodule PetalComponents.ShineBorder do
  @moduledoc """
  A subtle animated shimmer that sweeps around the border of its container.
  Pure CSS — no JavaScript, and it respects `prefers-reduced-motion`.

  The quieter sibling of `border_beam`: where the beam is a discrete
  travelling light, the shine is an ambient shimmer on the border ring. Good
  for cards, inputs and CTAs that want a hint of life without demanding
  attention.
  """
  use Phoenix.Component

  attr :shine_color, :any,
    default: "#a1a1aa",
    doc: "the shimmer colour. A single CSS colour, or a list of colours to blend across the sweep"

  attr :duration, :string, default: "14s", doc: "time for one full shimmer sweep"
  attr :border_width, :string, default: "1px", doc: "width of the shimmering border"

  attr :border_radius, :string,
    default: nil,
    doc:
      "border radius of the container. When unset, follows the theme radius (--pc-radius, scaled for panels)"

  attr :class, :any, default: nil, doc: "extra classes for the container"
  attr :rest, :global

  slot :inner_block, required: true

  @doc """
  Wraps content in a panel whose border carries a slow, ambient shimmer.

      <.shine_border>
        <div class="p-8">
          <.h3>Upgrade to Pro</.h3>
          ...
        </div>
      </.shine_border>

  Blend several colours across the sweep:

      <.shine_border shine_color={["#f43f5e", "#8b5cf6", "#3b82f6"]}>
        ...
      </.shine_border>
  """
  def shine_border(assigns) do
    colors =
      case assigns.shine_color do
        list when is_list(list) -> Enum.join(list, ", ")
        color -> color
      end

    style =
      [
        "--pc-shine-colors: #{colors}",
        "--pc-shine-duration: #{assigns.duration}",
        "--pc-shine-border-width: #{assigns.border_width}",
        assigns.border_radius && "--pc-shine-radius: #{assigns.border_radius}"
      ]
      |> Enum.filter(& &1)
      |> Enum.join("; ")

    assigns = assign(assigns, :style, style)

    ~H"""
    <div class={["pc-shine-border", @class]} style={@style} {@rest}>
      <div class="pc-shine-border__shine" aria-hidden="true"></div>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
