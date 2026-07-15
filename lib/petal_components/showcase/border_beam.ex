defmodule PetalComponents.Showcase.BorderBeam do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.BorderBeam, title: "Border Beam"

  example :basic_border_beam, "Basic Border Beam",
    description:
      "Wrap your content and you get the panel plus a single beam on the default gradient." do
    ~H"""
    <.border_beam id="showcase-beam-basic" class="w-full max-w-md mx-auto">
      <div class="flex items-center justify-center px-8 py-16">
        <h3 class="text-2xl font-bold">Default border beam</h3>
      </div>
    </.border_beam>
    """
  end

  example :custom_colors, "Custom Colors",
    description: "Set color_from and color_to for the gradient, and duration for the lap time." do
    ~H"""
    <.border_beam
      id="showcase-beam-cyan"
      color_from="#22d3ee"
      color_to="#0891b2"
      duration="5s"
      class="w-full max-w-md mx-auto"
    >
      <div class="flex items-center justify-center px-8 py-16">
        <h3 class="text-2xl font-bold">Cyan beam</h3>
      </div>
    </.border_beam>
    """
  end

  example :beam_with_content, "Beam with Content",
    description: "No z-index dance - drop a full call-to-action straight inside the panel." do
    ~H"""
    <.border_beam
      id="showcase-beam-content"
      color_from="#8b5cf6"
      color_to="#ec4899"
      class="w-full max-w-md mx-auto"
    >
      <div class="flex flex-col items-center px-8 py-12 text-center">
        <h3 class="text-2xl font-bold">Ready when you are</h3>
        <p class="max-w-sm mt-2 text-gray-600 dark:text-gray-300">
          Clone the repo, run the generators, ship by the weekend.
        </p>
        <.button label="Get started" class="mt-5" />
      </div>
    </.border_beam>
    """
  end

  example :pricing_cards, "Pricing Cards",
    description: "The classic use: run a beam around the plan you want people to pick." do
    ~H"""
    <.border_beam
      id="showcase-beam-pricing"
      color_from="#f59e0b"
      color_to="#ef4444"
      size="200px"
      class="w-full max-w-xs mx-auto"
    >
      <div class="px-8 py-8 text-center">
        <div class="text-sm font-semibold text-primary-600 dark:text-primary-400">Pro</div>
        <div class="mt-2 text-4xl font-bold">
          $99<span class="text-base font-normal text-gray-500">/mo</span>
        </div>
        <.button label="Choose Pro" class="w-full mt-6" />
      </div>
    </.border_beam>
    """
  end

  example :feature_highlight, "Glow and Multiple Beams",
    description:
      "glow swaps the sharp head for a soft comet - which unlocks the full beam length, since a long sharp beam clamps at the corners for safety. beams runs several at once." do
    ~H"""
    <.border_beam
      id="showcase-beam-glow"
      glow
      beams={2}
      size="400px"
      duration="9s"
      color_from="#f43f5e"
      color_to="#3b82f6"
      class="w-full max-w-sm mx-auto"
    >
      <div class="p-6">
        <div class="font-semibold leading-none text-gray-900 dark:text-gray-100">Now playing</div>
        <div class="mt-1.5 text-sm text-gray-500 dark:text-gray-400">
          Stairway to Heaven - Led Zeppelin
        </div>
        <div class="w-40 h-40 mx-auto mt-5 rounded-lg bg-gradient-to-br from-purple-500 to-pink-500">
        </div>
        <div class="mt-5">
          <.progress value={34} size="xs" />
        </div>
        <div class="flex justify-between mt-2 text-sm text-gray-500 dark:text-gray-400">
          <span>2:45</span><span>8:02</span>
        </div>
        <div class="flex justify-center gap-3 mt-4">
          <.button variant="outline" size="icon" radius="full" aria-label="Previous">
            <.icon name="hero-backward" />
          </.button>
          <.button size="icon" radius="full" aria-label="Play">
            <.icon name="hero-play" />
          </.button>
          <.button variant="outline" size="icon" radius="full" aria-label="Next">
            <.icon name="hero-forward" />
          </.button>
        </div>
      </div>
    </.border_beam>
    """
  end

  example :newsletter_beam, "Newsletter Signup",
    description: "A subtle beam turns a plain signup box into something worth stopping for." do
    ~H"""
    <.border_beam
      id="showcase-beam-newsletter"
      color_from="#a855f7"
      color_to="#6366f1"
      duration="10s"
      class="w-full max-w-md mx-auto"
    >
      <div class="px-8 py-10 text-center">
        <h3 class="text-xl font-bold">Join the list</h3>
        <p class="mt-1 text-sm text-gray-600 dark:text-gray-300">One email a week. No noise.</p>
        <div class="flex max-w-sm gap-2 mx-auto mt-5">
          <.input type="email" name="email" value="" placeholder="you@example.com" class="flex-1" />
          <.button label="Subscribe" />
        </div>
      </div>
    </.border_beam>
    """
  end
end
