defmodule PetalComponents.Showcase.Confetti do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Confetti, title: "Confetti"

  alias Phoenix.LiveView.JS

  example :celebrate, "Fire on the moments that matter",
    description:
      "Zero-dependency canvas confetti. From the client it's a pc:confetti CustomEvent - no server round-trip, as here - and from LiveView push_event(socket, \"pc-confetti\", %{}) fires the same burst on signup complete, plan upgraded, streak kept. Tune particle_count, spread, angle, velocity, colors and origin." do
    ~H"""
    <div class="flex flex-col items-center gap-4">
      <.confetti id="showcase-confetti" />
      <.button phx-click={JS.dispatch("pc:confetti", to: "#showcase-confetti")}>
        <.icon name="hero-sparkles" class="w-4 h-4 mr-1.5" /> Celebrate
      </.button>
    </div>
    """
  end
end
