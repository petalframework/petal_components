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
        <nav class="h-full p-3 overflow-auto text-sm bg-gray-50 dark:bg-gray-800/40">
          <div class="px-2 mb-1.5 text-[11px] font-semibold tracking-wide text-gray-400 uppercase">
            Getting started
          </div>
          <ul class="mb-4 space-y-0.5 text-gray-600 dark:text-gray-300">
            <li class="px-2 py-1 rounded-md">Installation</li>
            <li class="px-2 py-1 font-medium text-gray-900 rounded-md bg-gray-200/70 dark:bg-gray-400/17 dark:text-white">
              Theming
            </li>
            <li class="px-2 py-1 rounded-md">Dark mode</li>
            <li class="px-2 py-1 rounded-md">Upgrading</li>
          </ul>
          <div class="px-2 mb-1.5 text-[11px] font-semibold tracking-wide text-gray-400 uppercase">
            Components
          </div>
          <ul class="space-y-0.5 text-gray-600 dark:text-gray-300">
            <li class="px-2 py-1 rounded-md">Button</li>
            <li class="flex items-center justify-between gap-2 px-2 py-1 rounded-md">
              Resizable
              <span class="text-[10px] font-semibold uppercase text-success-600 dark:text-success-400">
                new
              </span>
            </li>
          </ul>
        </nav>
      </.resizable_panel>
      <.resizable_handle
        controls="sx-rsz-docs-nav"
        with_handle
        value_now={25}
        value_min={15}
        label="Resize navigation"
      />
      <.resizable_panel default_size={75} min_size={30}>
        <article class="h-full p-5 overflow-auto">
          <div class="text-[11px] font-semibold tracking-wide uppercase text-primary-600 dark:text-primary-400">
            Fundamentals
          </div>
          <h3 class="mt-1 text-base font-semibold text-gray-900 dark:text-white">Theming</h3>
          <p class="mt-2 text-sm leading-6 text-gray-600 dark:text-gray-300">
            Every component reads its colours off the theme rail, so setting the primary
            ramp once retints the whole library. There is no per-component colour prop to
            keep in sync and nothing to re-declare per page.
          </p>
          <div class="flex gap-2 mt-4">
            <span class="w-6 h-6 rounded-md bg-primary-200"></span>
            <span class="w-6 h-6 rounded-md bg-primary-400"></span>
            <span class="w-6 h-6 rounded-md bg-primary-600"></span>
            <span class="w-6 h-6 rounded-md bg-primary-800"></span>
          </div>
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
            <div class="h-full p-2 overflow-auto text-xs bg-gray-50 dark:bg-gray-800/40">
              <div class="flex items-center justify-between px-1 mb-2 text-[10px] font-semibold tracking-wide text-gray-400 uppercase">
                Explorer <span class="font-normal normal-case">3</span>
              </div>
              <ul class="space-y-0.5 text-gray-600 dark:text-gray-300">
                <li class="px-1 py-0.5 text-gray-500 dark:text-gray-400">lib/</li>
                <li class="px-1 py-0.5 pl-3 text-gray-500 dark:text-gray-400">petal_components/</li>
                <li class="flex items-center gap-1.5 rounded px-1 py-0.5 pl-6 font-medium text-gray-900 bg-gray-200/70 dark:bg-gray-400/17 dark:text-white">
                  resizable.ex <span class="ml-auto h-1.5 w-1.5 rounded-full bg-warning-500"></span>
                </li>
                <li class="px-1 py-0.5 pl-6">showcase.ex</li>
                <li class="px-1 py-0.5 text-gray-500 dark:text-gray-400">assets/</li>
                <li class="px-1 py-0.5 pl-3">default.css</li>
                <li class="px-1 py-0.5 text-gray-500 dark:text-gray-400">test/</li>
              </ul>
            </div>
          </.resizable_panel>
          <.resizable_handle
            controls="sx-rsz-ide-files"
            value_now={22}
            value_min={12}
            label="Resize file tree"
          />
          <.resizable_panel id="sx-rsz-ide-editor" default_size={48} min_size={25}>
            <div class="flex flex-col h-full">
              <div class="flex items-center gap-1 px-2 pt-2 text-xs shrink-0">
                <span class="px-2 py-1 font-medium text-gray-900 bg-gray-100 rounded-t-md dark:bg-gray-400/17 dark:text-white">
                  resizable.ex
                </span>
                <span class="px-2 py-1 text-gray-400">default.css</span>
              </div>
              <%!-- Hand-rolled tokens, not a real highlighter: this is demo
              content, and a flex gutter per line keeps it immune to however the
              HEEx formatter decides to wrap the spans. --%>
              <div class="flex-1 p-3 overflow-auto font-mono text-xs leading-5 text-gray-700 dark:text-gray-200">
                <div class="flex">
                  <span class="w-4 mr-3 text-right text-gray-300 select-none shrink-0 dark:text-gray-600">
                    1
                  </span>
                  <span>
                    <span class="text-danger-500 dark:text-danger-400">defmodule</span>
                    <span class="text-info-600 dark:text-info-400">Workspace</span>
                    <span class="text-danger-500 dark:text-danger-400">do</span>
                  </span>
                </div>
                <div class="flex">
                  <span class="w-4 mr-3 text-right text-gray-300 select-none shrink-0 dark:text-gray-600">
                    2
                  </span>
                  <span class="pl-3">
                    <span class="text-danger-500 dark:text-danger-400">use</span>
                    <span class="text-info-600 dark:text-info-400">MyAppWeb</span>
                    <span class="text-warning-600 dark:text-warning-400">:live_view</span>
                  </span>
                </div>
                <div class="flex">
                  <span class="w-4 mr-3 text-right text-gray-300 select-none shrink-0 dark:text-gray-600">
                    3
                  </span>
                  <span>&nbsp;</span>
                </div>
                <div class="flex">
                  <span class="w-4 mr-3 text-right text-gray-300 select-none shrink-0 dark:text-gray-600">
                    4
                  </span>
                  <span class="pl-3 text-gray-400 dark:text-gray-500">
                    # every group owns its own hook
                  </span>
                </div>
                <div class="flex">
                  <span class="w-4 mr-3 text-right text-gray-300 select-none shrink-0 dark:text-gray-600">
                    5
                  </span>
                  <span class="pl-3">
                    <span class="text-danger-500 dark:text-danger-400">def</span>
                    <span class="text-info-600 dark:text-info-400">render</span><span class="text-gray-500 dark:text-gray-400">(assigns)</span>
                    <span class="text-danger-500 dark:text-danger-400">do</span>
                  </span>
                </div>
                <div class="flex">
                  <span class="w-4 mr-3 text-right text-gray-300 select-none shrink-0 dark:text-gray-600">
                    6
                  </span>
                  <span class="pl-6 text-success-600 dark:text-success-400">
                    ~H"&lt;.resizable_group /&gt;"
                  </span>
                </div>
                <div class="flex">
                  <span class="w-4 mr-3 text-right text-gray-300 select-none shrink-0 dark:text-gray-600">
                    7
                  </span>
                  <span class="pl-3 text-danger-500 dark:text-danger-400">end</span>
                </div>
                <div class="flex">
                  <span class="w-4 mr-3 text-right text-gray-300 select-none shrink-0 dark:text-gray-600">
                    8
                  </span>
                  <span class="text-danger-500 dark:text-danger-400">end</span>
                </div>
              </div>
            </div>
          </.resizable_panel>
          <.resizable_handle
            controls="sx-rsz-ide-editor"
            with_handle
            value_now={48}
            value_min={25}
            label="Resize editor"
          />
          <.resizable_panel default_size={30} min_size={15}>
            <div class="h-full p-3 overflow-auto text-xs bg-gray-50 dark:bg-gray-800/40">
              <div class="mb-2 text-[10px] font-semibold tracking-wide text-gray-400 uppercase">
                Preview
              </div>
              <div class="p-3 bg-white border border-gray-200 rounded-lg shadow-xs dark:bg-gray-900 dark:border-gray-400/17">
                <div class="text-sm font-semibold text-gray-900 dark:text-white">New project</div>
                <p class="mt-1 leading-4 text-gray-500 dark:text-gray-400">
                  Name it and pick a region.
                </p>
                <div class="h-6 px-2 mt-2 text-[11px] leading-6 text-gray-400 border border-gray-300 rounded-md bg-gray-50 dark:bg-gray-400/8 dark:border-gray-400/25">
                  my-app
                </div>
                <%!-- text-(--pc-button-solid-fg), not text-white: on the
                monochrome primary ramp the solid goes white in dark mode and a
                white label would vanish into it. --%>
                <div class="mt-2 inline-flex h-6 items-center rounded-md px-2.5 text-[11px] font-medium bg-primary-600 text-(--pc-button-solid-fg)">
                  Create
                </div>
              </div>
            </div>
          </.resizable_panel>
        </.resizable_group>
      </.resizable_panel>
      <.resizable_handle
        orientation="vertical"
        with_handle
        value_now={70}
        value_min={30}
        label="Resize terminal"
      />
      <.resizable_panel id="sx-rsz-ide-term" default_size={30} min_size={10}>
        <div class="h-full p-3 overflow-auto font-mono text-xs leading-5 bg-gray-50 dark:bg-gray-800/40">
          <div>
            <span class="text-success-600 dark:text-success-400">$</span>
            <span class="text-gray-700 dark:text-gray-200">mix test</span>
          </div>
          <div class="text-gray-400 dark:text-gray-500">Compiling 1 file (.ex)</div>
          <div class="text-success-600 dark:text-success-400">
            ................................
          </div>
          <div>
            <span class="text-gray-700 dark:text-gray-200">916 tests,</span>
            <span class="text-success-600 dark:text-success-400">0 failures</span>
          </div>
          <div>
            <span class="text-success-600 dark:text-success-400">$</span>
            <span class="inline-block h-3.5 w-1.5 -mb-0.5 bg-gray-400 dark:bg-gray-500"></span>
          </div>
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
        <div class="h-full p-4 overflow-auto font-mono text-xs leading-5 text-gray-700 dark:text-gray-200">
          <div>
            <span class="text-gray-400 dark:text-gray-500">&lt;</span><span class="text-danger-500 dark:text-danger-400">.resizable_group</span>
            <span class="text-warning-600 dark:text-warning-400">orientation</span><span class="text-gray-400 dark:text-gray-500">=</span><span class="text-success-600 dark:text-success-400">"vertical"</span>
            <span class="text-warning-600 dark:text-warning-400">on_resize</span><span class="text-gray-400 dark:text-gray-500">=</span><span class="text-success-600 dark:text-success-400">"split"</span><span class="text-gray-400 dark:text-gray-500">&gt;</span>
          </div>
          <div class="pl-3">
            <span class="text-gray-400 dark:text-gray-500">&lt;</span><span class="text-danger-500 dark:text-danger-400">.resizable_panel</span>
            <span class="text-warning-600 dark:text-warning-400">id</span><span class="text-gray-400 dark:text-gray-500">=</span><span class="text-success-600 dark:text-success-400">"code"</span>
            <span class="text-warning-600 dark:text-warning-400">default_size</span><span class="text-gray-400 dark:text-gray-500">=</span><span class="text-info-600 dark:text-info-400">&lbrace;65&rbrace;</span>
            <span class="text-gray-400 dark:text-gray-500">/&gt;</span>
          </div>
          <div class="pl-3">
            <span class="text-gray-400 dark:text-gray-500">&lt;</span><span class="text-danger-500 dark:text-danger-400">.resizable_handle</span>
            <span class="text-warning-600 dark:text-warning-400">orientation</span><span class="text-gray-400 dark:text-gray-500">=</span><span class="text-success-600 dark:text-success-400">"vertical"</span>
            <span class="text-gray-400 dark:text-gray-500">/&gt;</span>
          </div>
          <div class="pl-3">
            <span class="text-gray-400 dark:text-gray-500">&lt;</span><span class="text-danger-500 dark:text-danger-400">.resizable_panel</span>
            <span class="text-warning-600 dark:text-warning-400">default_size</span><span class="text-gray-400 dark:text-gray-500">=</span><span class="text-info-600 dark:text-info-400">&lbrace;35&rbrace;</span>
            <span class="text-gray-400 dark:text-gray-500">/&gt;</span>
          </div>
          <div>
            <span class="text-gray-400 dark:text-gray-500">&lt;/</span><span class="text-danger-500 dark:text-danger-400">.resizable_group</span><span class="text-gray-400 dark:text-gray-500">&gt;</span>
          </div>
          <div>&nbsp;</div>
          <div>
            <span class="text-danger-500 dark:text-danger-400">def</span>
            <span class="text-info-600 dark:text-info-400">handle_event</span><span class="text-gray-500 dark:text-gray-400">(</span><span class="text-success-600 dark:text-success-400">"split"</span><span class="text-gray-500 dark:text-gray-400">, params, socket)</span><span class="text-gray-400 dark:text-gray-500">,</span>
            <span class="text-danger-500 dark:text-danger-400">do:</span>
          </div>
          <div class="pl-3">
            <span class="text-info-600 dark:text-info-400">assign</span><span class="text-gray-500 dark:text-gray-400">(socket,</span>
            <span class="text-warning-600 dark:text-warning-400">:sizes</span><span class="text-gray-500 dark:text-gray-400">, params[</span><span class="text-success-600 dark:text-success-400">"sizes"</span><span class="text-gray-500 dark:text-gray-400">])</span>
          </div>
        </div>
      </.resizable_panel>
      <.resizable_handle
        orientation="vertical"
        controls="sx-rsz-vertical-code"
        with_handle
        label="Resize console"
      />
      <.resizable_panel default_size={35} min_size={15}>
        <div class="h-full p-4 overflow-auto font-mono text-xs leading-5 bg-gray-50 dark:bg-gray-800/40">
          <div class="mb-1 font-sans text-[10px] tracking-wide text-gray-400 uppercase">console</div>
          <div class="text-gray-500 dark:text-gray-400">Compiling 1 file (.ex)</div>
          <div>
            <span class="text-info-600 dark:text-info-400">[info]</span>
            <span class="text-gray-700 dark:text-gray-200">split &rarr;</span>
            <span class="text-success-600 dark:text-success-400">65% / 35%</span>
          </div>
        </div>
      </.resizable_panel>
    </.resizable_group>
    """
  end
end
