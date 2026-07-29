defmodule PetalComponents.Showcase.Popover do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Popover, title: "Popover"

  example :basic, "Click to open",
    description:
      "A click-to-open panel with light dismiss - click away or press Escape and it's gone. The :trigger slot renders inside a real button (style it with trigger_class); the body is yours. Unlike a tooltip, the content can be interacted with." do
    ~H"""
    <.popover id="showcase-popover" trigger_class="pc-button pc-button--gray-outline pc-button--md">
      <:trigger>Open popover</:trigger>
      <div class="max-w-56">
        <div class="text-sm font-semibold">Dimensions</div>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          Set the width and height for the layer.
        </p>
      </div>
    </.popover>
    """
  end

  example :top_layer, "Escaping clipped containers",
    description:
      "top_layer paints the panel on the browser's native top layer (the popover API), so an overflow: hidden ancestor - table cells, scroll areas, cards - can't cut it off." do
    ~H"""
    <div class="relative h-24 w-full max-w-md p-4 overflow-hidden border border-dashed rounded-lg border-gray-300 dark:border-gray-700">
      <div class="mb-2 text-xs text-gray-400">overflow: hidden container</div>
      <.popover
        id="showcase-popover-clipped"
        placement="bottom"
        top_layer
        trigger_class="pc-button pc-button--gray-outline pc-button--sm"
      >
        <:trigger>Open from inside</:trigger>
        <div class="max-w-64 text-sm">
          This panel paints on the browser top layer - the clipped
          container can't cut it off.
        </div>
      </.popover>
    </div>
    """
  end
end
