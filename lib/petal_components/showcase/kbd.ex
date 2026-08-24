defmodule PetalComponents.Showcase.Kbd do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Kbd,
    title: "Kbd"

  example :basic, "A single key",
    description:
      "One <kbd> element with the key cap treatment. Use it inline in a sentence when you are telling someone which key to press." do
    ~H"""
    <p class="text-sm text-gray-500 dark:text-gray-400">
      Press
      <.kbd>/</.kbd>
      to jump to search, or
      <.kbd>Esc</.kbd>
      to close anything that is open.
    </p>
    """
  end

  example :sequence, "Key sequences",
    description:
      "keys renders one chip per key with the separator glyph between them. Known names fold to their symbol (cmd becomes the command glyph), anything else renders exactly as you typed it. The separator is hidden from screen readers, which already read the keys." do
    ~H"""
    <div class="flex flex-wrap items-center gap-6">
      <.kbd keys={["cmd", "K"]} />
      <.kbd keys={["ctrl", "shift", "P"]} />
      <.kbd keys={["G"]} separator="then" />
      <.kbd keys={["G", "I"]} separator="then" />
    </div>
    """
  end

  example :sizes, "Sizes",
    description:
      "md is the default and matches the chips already used by the command palette trigger and input group addons. sm is the dense one for table rows, sidebars and menu items." do
    ~H"""
    <div class="flex items-center gap-6">
      <.kbd keys={["cmd", "S"]} size="md" />
      <.kbd keys={["cmd", "S"]} size="sm" />
    </div>
    """
  end

  example :cheat_sheet, "A shortcuts cheat sheet",
    description:
      "The row-and-chip layout every app ends up building. Small chips keep the rows tight, and the whole table reads fine with only the keys announced." do
    ~H"""
    <div class="max-w-md divide-y divide-gray-200 rounded-xl border border-gray-200 dark:divide-gray-800 dark:border-gray-800">
      <div class="flex items-center justify-between gap-4 px-4 py-2.5">
        <span class="text-sm text-gray-700 dark:text-gray-300">Open command palette</span>
        <.kbd keys={["cmd", "K"]} size="sm" />
      </div>
      <div class="flex items-center justify-between gap-4 px-4 py-2.5">
        <span class="text-sm text-gray-700 dark:text-gray-300">New issue</span>
        <.kbd keys={["C"]} size="sm" />
      </div>
      <div class="flex items-center justify-between gap-4 px-4 py-2.5">
        <span class="text-sm text-gray-700 dark:text-gray-300">Assign to me</span>
        <.kbd keys={["A", "I"]} separator="then" size="sm" />
      </div>
      <div class="flex items-center justify-between gap-4 px-4 py-2.5">
        <span class="text-sm text-gray-700 dark:text-gray-300">Save and close</span>
        <.kbd keys={["cmd", "enter"]} size="sm" />
      </div>
    </div>
    """
  end

  example :menu_item, "Trailing shortcut on a menu item",
    description:
      "The shortcut sits at the end of the row on ml-auto. This is the pattern the dropdown examples already use by hand; the component gives you the symbol map for free." do
    ~H"""
    <div class="max-w-xs rounded-xl border border-gray-200 p-1.5 dark:border-gray-800">
      <button
        type="button"
        class="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-sm text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
      >
        <.icon name="hero-pencil-square" class="h-4 w-4 text-gray-400" /> Rename
        <.kbd keys={["cmd", "E"]} size="sm" class="ml-auto" />
      </button>
      <button
        type="button"
        class="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-sm text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
      >
        <.icon name="hero-document-duplicate" class="h-4 w-4 text-gray-400" /> Duplicate
        <.kbd keys={["cmd", "D"]} size="sm" class="ml-auto" />
      </button>
      <button
        type="button"
        class="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-sm text-danger-600 hover:bg-danger-50 dark:text-danger-400 dark:hover:bg-danger-500/10"
      >
        <.icon name="hero-trash" class="h-4 w-4" /> Delete
        <.kbd keys={["cmd", "backspace"]} size="sm" class="ml-auto" />
      </button>
    </div>
    """
  end
end
