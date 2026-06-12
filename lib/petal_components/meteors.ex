defmodule PetalComponents.Meteors do
  @moduledoc """
  A shower of meteors streaking across the parent container. Pure CSS —
  positions, delays and durations are generated server-side, so the effect
  costs zero JavaScript.

  Place it inside any `relative` container (a hero section, a card) and it
  fills the space behind your content.
  """
  use Phoenix.Component

  attr :count, :integer, default: 20, doc: "number of meteors"

  attr :seed, :integer,
    default: 0,
    doc:
      "vary this when rendering several meteor fields on one page so each gets a different scatter pattern"

  attr :class, :any, default: nil, doc: "extra classes for the container"
  attr :rest, :global

  @doc """
  Renders a meteor shower that fills its nearest `relative` ancestor.

      <div class="relative overflow-hidden rounded-xl bg-gray-950 p-12">
        <.meteors count={30} />
        <.h2 class="relative text-white">Ship faster with Petal</.h2>
      </div>

  Meteor positions are deterministic for a given `seed`, so LiveView
  re-renders never make the meteors jump.
  """
  def meteors(assigns) do
    assigns = assign(assigns, :meteor_styles, build_styles(assigns.count, assigns.seed))

    ~H"""
    <div class={["pc-meteors", @class]} aria-hidden="true" {@rest}>
      <span :for={style <- @meteor_styles} class="pc-meteor" style={style}></span>
    </div>
    """
  end

  # Deterministic pseudo-random placement: stable across re-renders (no
  # meteor-jumping when LiveView patches the page) and across test runs.
  defp build_styles(count, seed) when count > 0 do
    for i <- 1..count do
      top = rand({seed, i, :top}, 60) - 20
      left = rand({seed, i, :left}, 100)
      delay = rand({seed, i, :delay}, 500) / 100
      duration = rand({seed, i, :duration}, 400) / 100 + 4

      "top: #{top}%; left: #{left}%; animation-delay: #{delay}s; animation-duration: #{duration}s;"
    end
  end

  defp build_styles(_count, _seed), do: []

  defp rand(term, max), do: rem(:erlang.phash2(term), max)
end
