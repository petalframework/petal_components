defmodule PetalComponents.Showcase.Resizable do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Resizable,
    title: "Resizable",
    functions: [:resizable_group, :resizable_panel, :resizable_handle]

  example :docs, "Docs layout with a collapsible sidebar",
    description:
      "The everyday split: a navigation rail you can drag narrower, and content that takes the rest. The sidebar is collapsible, so dragging it below half its min_size snaps it shut and fires petal:resizable-collapse; dragging back out reopens it at min_size. Double-click the separator to put both panes back on their default_size. Tab to the separator and the arrow keys do the same job - Home collapses, End grows it to max." do
    ~H"""
    <.resizable_group
      id="sx-rsz-docs"
      class="h-64 border border-gray-200 rounded-xl dark:border-gray-400/20"
    >
      <.resizable_panel id="sx-rsz-docs-nav" default_size={25} min_size={15} collapsible>
        <nav class="h-full p-4 text-sm bg-gray-50 dark:bg-gray-800/40">
          <div class="mb-2 text-[11px] font-semibold tracking-wide text-gray-400 uppercase">
            Getting started
          </div>
          <ul class="space-y-1.5 text-gray-600 dark:text-gray-300">
            <li>Installation</li>
            <li class="font-medium text-gray-900 dark:text-white">Theming</li>
            <li>Dark mode</li>
            <li>Upgrading</li>
          </ul>
        </nav>
      </.resizable_panel>
      <.resizable_handle controls="sx-rsz-docs-nav" with_handle label="Resize navigation" />
      <.resizable_panel default_size={75} min_size={30}>
        <article class="h-full p-5 overflow-auto">
          <h3 class="text-base font-semibold text-gray-900 dark:text-white">Theming</h3>
          <p class="mt-2 text-sm text-gray-600 dark:text-gray-300">
            Every component reads its colours off the theme rail, so setting the
            primary ramp once retints the whole library. Drag the divider to see
            how the two panes trade space.
          </p>
        </article>
      </.resizable_panel>
    </.resizable_group>
    """
  end

  example :ide, "Nested groups: an IDE workspace",
    description:
      "The nesting case. A vertical group holds a horizontal group on top (files, editor, preview) and a terminal below. Each group mounts its own hook and only ever touches its own direct children, so the inner separators and the outer one never fight over a panel." do
    ~H"""
    <.resizable_group
      id="sx-rsz-ide"
      orientation="vertical"
      class="h-80 border border-gray-200 rounded-xl dark:border-gray-400/20"
    >
      <.resizable_panel default_size={70} min_size={30}>
        <.resizable_group id="sx-rsz-ide-top" class="h-full">
          <.resizable_panel id="sx-rsz-ide-files" default_size={22} min_size={12}>
            <div class="h-full p-3 text-xs bg-gray-50 dark:bg-gray-800/40">
              <div class="mb-2 font-semibold text-gray-400">EXPLORER</div>
              <ul class="space-y-1 text-gray-600 dark:text-gray-300">
                <li>lib/</li>
                <li class="pl-3 font-medium text-gray-900 dark:text-white">resizable.ex</li>
                <li>assets/</li>
                <li>test/</li>
              </ul>
            </div>
          </.resizable_panel>
          <.resizable_handle controls="sx-rsz-ide-files" label="Resize file tree" />
          <.resizable_panel id="sx-rsz-ide-editor" default_size={48} min_size={25}>
            <div class="h-full p-3 overflow-auto font-mono text-xs leading-5 text-gray-700 whitespace-pre dark:text-gray-200">
              <div>&lt;.resizable_group id="ide" orientation="vertical"&gt;</div>
              <div>&lt;.resizable_panel default_size={70}&gt;</div>
              <div>&lt;.editor /&gt;</div>
              <div>&lt;/.resizable_panel&gt;</div>
              <div>&lt;.resizable_handle orientation="vertical" with_handle /&gt;</div>
              <div>&lt;.resizable_panel default_size={30} min_size={10}&gt;</div>
              <div>&lt;.terminal /&gt;</div>
              <div>&lt;/.resizable_panel&gt;</div>
              <div>&lt;/.resizable_group&gt;</div>
            </div>
          </.resizable_panel>
          <.resizable_handle controls="sx-rsz-ide-editor" with_handle label="Resize editor" />
          <.resizable_panel default_size={30} min_size={15}>
            <div class="h-full p-3 text-xs bg-gray-50 dark:bg-gray-800/40">
              <div class="mb-2 font-semibold text-gray-400">PREVIEW</div>
              <div class="border border-gray-200 rounded-lg h-16 dark:border-gray-400/20"></div>
            </div>
          </.resizable_panel>
        </.resizable_group>
      </.resizable_panel>
      <.resizable_handle orientation="vertical" with_handle label="Resize terminal" />
      <.resizable_panel id="sx-rsz-ide-term" default_size={30} min_size={10}>
        <div class="h-full p-3 overflow-auto font-mono text-xs leading-5 text-gray-500 dark:text-gray-400">
          <div>$ mix test</div>
          <div>916 tests, 0 failures</div>
        </div>
      </.resizable_panel>
    </.resizable_group>
    """
  end

  example :vertical, "Vertical split",
    description:
      "Stacked panes with a horizontal separator. aria-orientation inverts: the group is vertical, so the separator is horizontal and Up/Down resize it while Left/Right are a no-op. Wire on_resize to a handle_event and the released percentages arrive on the server, ready to persist - the library itself stores nothing." do
    ~H"""
    <.resizable_group
      id="sx-rsz-vertical"
      orientation="vertical"
      class="h-72 border border-gray-200 rounded-xl dark:border-gray-400/20"
    >
      <.resizable_panel id="sx-rsz-vertical-code" default_size={65} min_size={25}>
        <div class="h-full p-4 overflow-auto font-mono text-xs leading-5 text-gray-700 whitespace-pre dark:text-gray-200">
          <div>&lt;.resizable_group orientation="vertical" on_resize="split"&gt;</div>
          <div>&lt;.resizable_panel id="code" default_size={65} min_size={25} /&gt;</div>
          <div>&lt;.resizable_handle orientation="vertical" controls="code" /&gt;</div>
          <div>&lt;.resizable_panel default_size={35} min_size={15} /&gt;</div>
          <div>&lt;/.resizable_group&gt;</div>
        </div>
      </.resizable_panel>
      <.resizable_handle
        orientation="vertical"
        controls="sx-rsz-vertical-code"
        with_handle
        label="Resize console"
      />
      <.resizable_panel default_size={35} min_size={15}>
        <div class="h-full p-4 font-mono text-xs bg-gray-50 dark:bg-gray-800/40">
          <div class="text-gray-400">console</div>
          <div class="mt-1 text-gray-600 dark:text-gray-300">Compiling 1 file (.ex)</div>
        </div>
      </.resizable_panel>
    </.resizable_group>
    """
  end
end
