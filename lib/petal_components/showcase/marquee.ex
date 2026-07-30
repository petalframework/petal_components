defmodule PetalComponents.Showcase.Marquee do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Marquee, title: "Marquee"

  example :logos, "An infinite scroller",
    description:
      "Logos, testimonials, anything - pure CSS animation with edge fade, pausing under the pointer with pause_on_hover. repeat controls how many copies keep the loop seamless; duration and gap tune the feel; reverse and vertical change direction. Holds still under prefers-reduced-motion." do
    ~H"""
    <.marquee pause_on_hover duration="24s">
      <div
        :for={name <- ~w(Phoenix LiveView Tailwind Elixir Postgres Oban Ecto)}
        class="flex items-center gap-2 px-5 py-3 mx-2 border border-gray-200 rounded-xl dark:border-gray-700"
      >
        <.icon name="hero-bolt" class="w-4 h-4 text-gray-400" />
        <span class="text-sm font-medium">{name}</span>
      </div>
    </.marquee>
    """
  end
end
