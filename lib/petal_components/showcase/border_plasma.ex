defmodule PetalComponents.Showcase.BorderPlasma do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.BorderPlasma, title: "Border plasma"

  example :card, "A breathing glow",
    description:
      "The default. The whole ring lights at once and breathes, so nothing travels across the screen - it pulls the eye without dragging it. Colours come off the theme's primary and secondary tokens unless you pass your own." do
    ~H"""
    <.border_plasma class="w-full max-w-sm">
      <div class="p-8">
        <div class="text-lg font-semibold text-gray-900 dark:text-gray-100">
          Upgrade to Pro
        </div>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          Unlimited projects and priority support.
        </p>
      </div>
    </.border_plasma>
    """
  end

  example :rotate, "A rotating sweep",
    description:
      "mode=\"rotate\" spins a conic gradient arc around the ring instead of breathing it. Busier than pulse, so it earns its place on one hero panel rather than every card on the page." do
    ~H"""
    <.border_plasma mode="rotate" duration="5s" class="w-full max-w-sm">
      <div class="p-8">
        <div class="text-lg font-semibold text-gray-900 dark:text-gray-100">
          Now in beta
        </div>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          Ship your next Phoenix app in a weekend.
        </p>
      </div>
    </.border_plasma>
    """
  end

  example :cta, "On a CTA",
    description:
      "Wrap a button-sized block and the plasma becomes the button's edge. Turn intensity up to strong and set your own colours when the glow needs to carry across a dark hero." do
    ~H"""
    <.border_plasma intensity="strong" color_from="#f43f5e" color_to="#3b82f6" class="inline-block">
      <div class="px-6 py-2.5 text-sm font-medium text-gray-900 dark:text-gray-100">
        Buy now
      </div>
    </.border_plasma>
    """
  end

  example :subtle, "Turned down",
    description:
      "intensity=\"subtle\" with a hairline border_width is the ambient setting - close to shine_border in weight, but lit all the way round. Good for a card that should feel alive without shouting." do
    ~H"""
    <.border_plasma intensity="subtle" border_width="1px" duration="6s" class="w-full max-w-sm">
      <div class="p-8">
        <div class="text-lg font-semibold text-gray-900 dark:text-gray-100">
          Weekly digest
        </div>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          One email, every Friday. No noise.
        </p>
      </div>
    </.border_plasma>
    """
  end
end
