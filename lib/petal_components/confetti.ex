defmodule PetalComponents.Confetti do
  @moduledoc """
  A confetti cannon for celebration moments — completed onboarding, first
  payment, level up. Rendered as an invisible mount point; bursts are drawn on
  a temporary full-screen canvas with zero dependencies.

  Requires the `PetalConfetti` hook from the JS bundle.

  ## Firing confetti

  From the server (e.g. after a successful form submit):

      {:noreply, push_event(socket, "pc-confetti", %{})}

  Target a specific mount when a page has several:

      {:noreply, push_event(socket, "pc-confetti", %{id: "my-confetti", particle_count: 150})}

  From the client, without a round trip:

      <.button phx-click={Phoenix.LiveView.JS.dispatch("pc:confetti", to: "#my-confetti")} label="Celebrate" />

  Both paths accept options: `particle_count`, `spread`, `angle`, `velocity`,
  `colors`, and `origin` (`%{x: 0..1, y: 0..1}` in viewport coordinates).

  Respects `prefers-reduced-motion` — bursts are skipped for users who opt
  out of animation.
  """
  use Phoenix.Component

  attr :id, :string, required: true

  attr :particle_count, :integer,
    default: 100,
    doc: "default number of particles per burst"

  attr :spread, :integer, default: 70, doc: "default spread of a burst, in degrees"

  attr :colors, :list,
    default: [],
    doc: ~s|default particle colors as hex strings, e.g. ["#26ccff", "#a25afd"]|

  attr :rest, :global

  @doc """
  Mounts an (invisible) confetti cannon on the page.

      <.confetti id="confetti" />
  """
  def confetti(assigns) do
    ~H"""
    <span
      id={@id}
      class="pc-confetti"
      phx-hook="PetalConfetti"
      data-particle-count={@particle_count}
      data-spread={@spread}
      data-colors={if @colors != [], do: Phoenix.json_library().encode!(@colors)}
      {@rest}
    >
    </span>
    """
  end
end
