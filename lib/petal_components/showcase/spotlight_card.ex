defmodule PetalComponents.Showcase.SpotlightCard do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.SpotlightCard, title: "Spotlight card"

  example :pair, "A glow that follows the cursor",
    description:
      "The tiny PetalSpotlight hook tracks pointer position only - the paint is pure CSS. Subtle by default; spotlight_color and spotlight_size turn it into a brand moment. Reads best on dark panels." do
    ~H"""
    <div class="grid w-full gap-6 md:grid-cols-2">
      <.spotlight_card id="showcase-spot-default" class="p-8">
        <h3 class="text-lg font-semibold">Default glow</h3>
        <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
          Subtle by default - the light source tracks the pointer.
        </p>
      </.spotlight_card>
      <.spotlight_card
        id="showcase-spot-tuned"
        spotlight_color="rgba(124, 58, 237, 0.25)"
        spotlight_size="500px"
        class="p-8"
      >
        <h3 class="text-lg font-semibold">Tuned glow</h3>
        <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
          spotlight_color and spotlight_size make it a brand moment.
        </p>
      </.spotlight_card>
    </div>
    """
  end
end
