defmodule PetalComponents.Showcase.ContextMenu do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.ContextMenu,
    title: "Context menu",
    functions: [
      :context_menu,
      :context_menu_item,
      :context_menu_label,
      :context_menu_separator
    ]

  example :file_card, "Right-click a file",
    description:
      "The classic: an object on the page with its own commands. Right-click the card (or long-press it on a phone) and the menu opens at the pointer, clamped so it never runs off an edge. Keyboard users tab to the card and press Shift+F10. Items carry icons, a kbd hint and the danger variant for the one that deletes something." do
    ~H"""
    <.context_menu id="showcase-context-menu-file" class="max-w-xs">
      <:trigger>
        <div class="flex items-center gap-3 p-4 bg-white border border-gray-200 rounded-xl dark:bg-gray-900 dark:border-gray-800">
          <.icon name="hero-document-chart-bar" class="w-8 h-8 text-gray-400 shrink-0" />
          <div class="min-w-0">
            <div class="text-sm font-medium truncate">Q3-forecast.xlsx</div>
            <div class="text-xs text-gray-500 dark:text-gray-400">Edited 2 days ago</div>
          </div>
        </div>
      </:trigger>

      <.context_menu_label>Q3-forecast.xlsx</.context_menu_label>
      <.context_menu_item link_type="button" kbd="↵">
        <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4" /> Open
      </.context_menu_item>
      <.context_menu_item link_type="button" kbd="F2">
        <.icon name="hero-pencil-square" class="w-4 h-4" /> Rename
      </.context_menu_item>
      <.context_menu_item link_type="button" kbd="⌘D">
        <.icon name="hero-square-2-stack" class="w-4 h-4" /> Duplicate
      </.context_menu_item>
      <.context_menu_item link_type="button" disabled>
        <.icon name="hero-lock-closed" class="w-4 h-4" /> Move to team folder
      </.context_menu_item>
      <.context_menu_separator />
      <.context_menu_item link_type="button" variant="danger" kbd="⌘⌫">
        <.icon name="hero-trash" class="w-4 h-4" /> Delete
      </.context_menu_item>
    </.context_menu>
    """
  end

  example :text_selection, "Right-click content",
    description:
      "The other half of the pattern: commands about what you are reading rather than an object you can point at. Same panel, same items, a trigger region that happens to be prose." do
    ~H"""
    <.context_menu id="showcase-context-menu-text" class="max-w-md">
      <:trigger>
        <p class="p-4 text-sm leading-relaxed text-gray-600 border border-gray-200 border-dashed rounded-xl dark:text-gray-300 dark:border-gray-700">
          Phoenix ships with LiveView, so most of what people reach for a
          single-page framework to do is already in the box. Right-click
          anywhere in this paragraph.
        </p>
      </:trigger>

      <.context_menu_item link_type="button" kbd="⌘C">
        <.icon name="hero-clipboard" class="w-4 h-4" /> Copy
      </.context_menu_item>
      <.context_menu_item link_type="button" kbd="⌘⇧H">
        <.icon name="hero-paint-brush" class="w-4 h-4" /> Highlight
      </.context_menu_item>
      <.context_menu_separator />
      <.context_menu_item link_type="a" to="#share">
        <.icon name="hero-share" class="w-4 h-4" /> Share
      </.context_menu_item>
      <.context_menu_item link_type="a" to="#search">
        <.icon name="hero-magnifying-glass" class="w-4 h-4" /> Search the web
      </.context_menu_item>
    </.context_menu>
    """
  end
end
