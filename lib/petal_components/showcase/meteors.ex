defmodule PetalComponents.Showcase.Meteors do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Meteors, title: "Meteors"

  example :basic, "A meteor shower in any container",
    description:
      "Positions are generated server-side - zero JavaScript, and with a seed the same sky renders every time, so LiveView re-renders never make it jump. Meteors sit behind your content; count, angle, color and reverse tune the weather." do
    ~H"""
    <div class="relative w-full overflow-hidden bg-gray-950 rounded-xl h-56">
      <.meteors count={20} seed={42} />
      <div class="relative flex flex-col items-center justify-center h-full text-center">
        <div class="text-lg font-semibold text-white">Ship something tonight</div>
        <div class="mt-1 text-sm text-gray-400">Meteors sit behind your content.</div>
      </div>
    </div>
    """
  end
end
