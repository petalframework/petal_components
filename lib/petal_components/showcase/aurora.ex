defmodule PetalComponents.Showcase.Aurora do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Aurora, title: "Aurora"

  example :basic_aurora, "Basic Aurora",
    description:
      "A soft, drifting glow behind your content. The wrapper sizes to fit - no colors means the default palette." do
    ~H"""
    <.aurora id="showcase-aurora-basic" class="w-full max-w-xl mx-auto rounded-2xl">
      <div class="flex flex-col items-center px-8 py-20 text-center">
        <h2 class="text-3xl font-bold tracking-tight text-gray-900 dark:text-gray-100">
          Ship your Phoenix app this weekend
        </h2>
        <p class="max-w-md mt-3 text-gray-600 dark:text-gray-300">
          Auth, billing, orgs and a component library that looks like you hired a designer.
        </p>
        <.button label="Get started" class="mt-6" />
      </div>
    </.aurora>
    """
  end

  example :custom_colors, "Custom Colors",
    description:
      "Pass any palette as colors (three to six CSS colors) and the gradient is built for you." do
    ~H"""
    <div class="grid w-full max-w-2xl gap-4 mx-auto sm:grid-cols-3">
      <.aurora
        id="showcase-aurora-sunset"
        colors={["#f97316", "#f43f5e", "#fbbf24", "#fb7185"]}
        class="border border-gray-200 rounded-xl dark:border-gray-800"
      >
        <div class="flex items-end px-4 h-32">
          <span class="pb-3 font-mono text-xs text-gray-500 dark:text-gray-400">sunset</span>
        </div>
      </.aurora>
      <.aurora
        id="showcase-aurora-emerald"
        colors={["#10b981", "#5eead4", "#a7f3d0", "#34d399"]}
        class="border border-gray-200 rounded-xl dark:border-gray-800"
      >
        <div class="flex items-end px-4 h-32">
          <span class="pb-3 font-mono text-xs text-gray-500 dark:text-gray-400">emerald</span>
        </div>
      </.aurora>
      <.aurora
        id="showcase-aurora-violet"
        colors={["#8b5cf6", "#f0abfc", "#c4b5fd", "#a78bfa"]}
        class="border border-gray-200 rounded-xl dark:border-gray-800"
      >
        <div class="flex items-end px-4 h-32">
          <span class="pb-3 font-mono text-xs text-gray-500 dark:text-gray-400">violet</span>
        </div>
      </.aurora>
    </div>
    """
  end

  example :aurora_with_content, "Aurora with Content",
    description: "Slow the drift with speed and drop a full call-to-action straight inside." do
    ~H"""
    <.aurora
      id="showcase-aurora-content"
      colors={["#22d3ee", "#06b6d4", "#0891b2", "#0e7490"]}
      speed="80s"
      class="w-full max-w-xl mx-auto rounded-2xl"
    >
      <div class="flex flex-col items-center px-8 py-16 text-center">
        <h2 class="mb-4 text-2xl font-bold text-gray-900 dark:text-white">Start selling today</h2>
        <p class="max-w-md mb-6 text-gray-600 dark:text-gray-300">
          Everything wired up out of the box, so you spend the weekend on the part that's yours.
        </p>
        <.button label="Get started" color="primary" />
      </div>
    </.aurora>
    """
  end

  example :aurora_card, "Aurora Card",
    description:
      "Set it behind cards for feature highlights. A lower opacity keeps the copy readable." do
    ~H"""
    <.aurora
      id="showcase-aurora-card"
      colors={["#6366f1", "#4f46e5", "#4338ca", "#3730a3"]}
      opacity="0.35"
      class="w-full max-w-md mx-auto rounded-xl"
    >
      <.card class="relative z-10 bg-transparent border-0 shadow-none dark:bg-transparent">
        <.card_content category="Feature" heading="Fast development">
          <p class="text-gray-700 dark:text-white/80">
            Build interfaces in record time with a component library and design system that agree.
          </p>
        </.card_content>
      </.card>
    </.aurora>
    """
  end

  example :testimonial_aurora, "Testimonial with Aurora",
    description:
      "Push the mask out with mask_position and mask_coverage to flood more of the container - a testimonial that pulls the eye without shouting." do
    ~H"""
    <.aurora
      id="showcase-aurora-testimonial"
      colors={["#c084fc", "#a855f7", "#9333ea", "#7e22ce"]}
      opacity="0.35"
      mask_position="center top"
      mask_coverage="0%, 100%"
      class="w-full max-w-2xl mx-auto rounded-xl"
    >
      <div class="flex flex-col items-center px-8 py-16 text-center">
        <p class="max-w-2xl mb-8 text-xl text-gray-900 dark:text-white">
          "The aurora took our landing page from fine to the thing people mention on calls. Two attributes and it was done."
        </p>
        <div class="font-bold text-gray-900 dark:text-white">Jordan Lee</div>
        <div class="text-purple-700 dark:text-purple-300">Founder, Northwind</div>
      </div>
    </.aurora>
    """
  end
end
