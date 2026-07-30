defmodule PetalComponents.Showcase.Loading do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Loading,
    title: "Loading",
    functions: [:spinner]

  example :in_buttons_and_inline, "In buttons, and inline",
    description:
      "Buttons take loading directly - the spinner swaps in on the icon's side and the label stays. Standalone, pair the spinner with a status line for anything else that waits." do
    ~H"""
    <div class="flex flex-col items-center gap-6">
      <div class="flex flex-wrap items-center justify-center gap-3">
        <.button loading>Saving changes</.button>
        <.button color="gray" variant="outline" loading disabled>Generating</.button>
      </div>
      <div class="flex items-center gap-2.5 text-sm text-gray-500 dark:text-gray-400">
        <.spinner size="sm" /> Syncing workspace...
      </div>
    </div>
    """
  end

  example :panel, "A loading panel",
    description:
      "The empty-state pattern while content generates: spinner, one confident line, one expectation-setting line. For full layout placeholders, reach for skeleton instead." do
    ~H"""
    <div class="flex flex-col items-center justify-center w-full max-w-md gap-3 py-12 mx-auto border border-gray-200 border-dashed rounded-xl dark:border-gray-700">
      <.spinner size="md" />
      <p class="text-sm font-medium text-gray-900 dark:text-gray-100">Generating preview</p>
      <p class="text-xs text-gray-500 dark:text-gray-400">This usually takes a few seconds</p>
    </div>
    """
  end

  example :sizes_and_color, "Sizes and colour",
    description:
      "Three sizes, and size_class takes over both sizing and colour when you need more - the glyph draws with currentColor, so any text-* utility recolours it." do
    ~H"""
    <div class="flex items-end justify-center gap-10">
      <div :for={sz <- ~w(sm md lg)} class="flex flex-col items-center gap-2">
        <.spinner size={sz} />
        <span class="text-[11px] text-gray-400">{sz}</span>
      </div>
      <div class="flex flex-col items-center gap-2">
        <.spinner size_class="h-8 w-8 text-secondary-500" />
        <span class="text-[11px] text-gray-400">custom</span>
      </div>
    </div>
    """
  end
end
