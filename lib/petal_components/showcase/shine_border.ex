defmodule PetalComponents.Showcase.ShineBorder do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.ShineBorder, title: "Shine border"

  example :card, "The quiet sibling of the border beam",
    description:
      "A slow, ambient shimmer sweeping the border - pure CSS, and it holds still for reduced-motion users. shine_color takes one colour or a list to blend; duration tunes the sweep, border_width the line." do
    ~H"""
    <.shine_border duration="14s" class="w-full max-w-sm">
      <div class="p-8">
        <div class="text-lg font-semibold text-gray-900 dark:text-gray-100">
          Upgrade to Pro
        </div>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          Unlimited projects and priority support.
        </p>
      </div>
    </.shine_border>
    """
  end

  example :input, "On an input",
    description:
      "Wrap a bare input and the shine becomes the field's border - the magic-search treatment. A thicker border_width makes the sweep legible at input scale." do
    ~H"""
    <.shine_border shine_color="#3b82f6" border_width="2px" class="w-full max-w-sm">
      <input
        type="text"
        value="magic search..."
        class="w-full px-4 py-2.5 text-sm bg-transparent border-0 focus:outline-hidden text-gray-900 dark:text-gray-100"
      />
    </.shine_border>
    """
  end
end
