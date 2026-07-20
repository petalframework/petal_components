defmodule PetalComponents.Showcase.Sparkline do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Sparkline,
    title: "Sparkline",
    functions: [:sparkline]

  example :stat_cards, "Trends in stat cards",
    description:
      "Pure server-rendered SVG - zero JavaScript. The line inherits currentColor, so a text class sets the colour." do
    ~H"""
    <div class="grid w-full gap-4 sm:grid-cols-3">
      <div class="flex items-center justify-between px-5 py-4 border border-gray-200 rounded-xl dark:border-gray-800">
        <div>
          <div class="text-xs text-gray-400 dark:text-gray-500">MRR</div>
          <div class="mt-1 text-xl font-semibold">$12,480</div>
        </div>
        <.sparkline data={[8, 9, 9, 11, 10, 12, 13, 14]} class="h-10 w-24 text-primary-500" />
      </div>
      <div class="flex items-center justify-between px-5 py-4 border border-gray-200 rounded-xl dark:border-gray-800">
        <div>
          <div class="text-xs text-gray-400 dark:text-gray-500">Signups</div>
          <div class="mt-1 text-xl font-semibold">1,204</div>
        </div>
        <.sparkline data={[30, 34, 31, 38, 36, 41, 40, 44]} class="h-10 w-24 text-success-500" />
      </div>
      <div class="flex items-center justify-between px-5 py-4 border border-gray-200 rounded-xl dark:border-gray-800">
        <div>
          <div class="text-xs text-gray-400 dark:text-gray-500">Churn</div>
          <div class="mt-1 text-xl font-semibold">1.9%</div>
        </div>
        <.sparkline data={[9, 8, 9, 7, 8, 6, 7, 5]} class="h-10 w-24 text-danger-500" />
      </div>
    </div>
    """
  end

  example :variants, "Line styles",
    description: "Smooth or linear, with or without the area fill." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-8">
      <.sparkline data={[4, 7, 5, 9, 8, 12, 11, 14]} class="h-10 w-32 text-primary-500" />
      <.sparkline
        data={[4, 7, 5, 9, 8, 12, 11, 14]}
        smooth={false}
        class="h-10 w-32 text-info-500"
      />
      <.sparkline
        data={[4, 7, 5, 9, 8, 12, 11, 14]}
        fill={false}
        class="h-10 w-32 text-secondary-500"
      />
    </div>
    """
  end
end
