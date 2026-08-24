defmodule PetalComponents.Showcase.Scrollspy do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Scrollspy, title: "Scrollspy"

  example :basic, "On this page",
    description:
      "The docs rail: pass the sections as items and the hook highlights the one you are reading. Scroll the article on the right and watch the bar move." do
    ~H"""
    <div class="flex gap-8">
      <.scrollspy
        id="showcase-scrollspy"
        heading="On this page"
        class="flex-none w-40"
        items={[
          %{label: "Install", target: "ss-install"},
          %{label: "Usage", target: "ss-usage"},
          %{label: "Theming", target: "ss-theming"},
          %{label: "Upgrading", target: "ss-upgrading"}
        ]}
      />
      <div class="flex-1 h-64 pr-2 overflow-y-auto">
        <section id="ss-install" class="pb-24">
          <h2 class="text-base font-semibold">Install</h2>
          <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            Add the dependency, run mix deps.get, then point your CSS at the
            package so the component classes get built.
          </p>
        </section>
        <section id="ss-usage" class="pb-24">
          <h2 class="text-base font-semibold">Usage</h2>
          <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            Give every section an id and hand the same ids to the rail as
            targets. That is the whole contract.
          </p>
        </section>
        <section id="ss-theming" class="pb-24">
          <h2 class="text-base font-semibold">Theming</h2>
          <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            The active link and the bar both ride the primary ramp, so the rail
            picks up your brand without being told.
          </p>
        </section>
        <section id="ss-upgrading" class="pb-4">
          <h2 class="text-base font-semibold">Upgrading</h2>
          <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            A short closing section still highlights at the bottom of the
            scroll, because the last entry snaps active there.
          </p>
        </section>
      </div>
    </div>
    """
  end

  example :nested, "Nested sections",
    description:
      "One level of nesting for h2/h3 structure. Children indent and set their own active state; the rail stays scannable because it stops there." do
    ~H"""
    <div class="flex gap-8">
      <.scrollspy
        id="showcase-scrollspy-nested"
        class="flex-none w-44"
        items={[
          %{label: "Getting started", target: "ssn-start"},
          %{
            label: "Components",
            target: "ssn-components",
            children: [
              %{label: "Buttons", target: "ssn-buttons"},
              %{label: "Modals", target: "ssn-modals"}
            ]
          },
          %{label: "Deploying", target: "ssn-deploy"}
        ]}
      />
      <div class="flex-1 h-64 pr-2 overflow-y-auto">
        <section id="ssn-start" class="pb-24">
          <h2 class="text-base font-semibold">Getting started</h2>
          <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            Everything you need for the first five minutes.
          </p>
        </section>
        <section id="ssn-components" class="pb-16">
          <h2 class="text-base font-semibold">Components</h2>
          <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            The set, grouped the way you would reach for them.
          </p>
        </section>
        <section id="ssn-buttons" class="pb-16">
          <h3 class="text-sm font-semibold">Buttons</h3>
          <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            Sizes, variants, and the loading state.
          </p>
        </section>
        <section id="ssn-modals" class="pb-24">
          <h3 class="text-sm font-semibold">Modals</h3>
          <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            Focus trapping and dismissal come wired.
          </p>
        </section>
        <section id="ssn-deploy" class="pb-4">
          <h2 class="text-base font-semibold">Deploying</h2>
          <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            Ship it.
          </p>
        </section>
      </div>
    </div>
    """
  end

  example :bare, "Your own markup",
    description:
      "The hook is not tied to the renderer. Put phx-hook=\"PetalScrollspy\" on any container whose links carry data-scrollspy-target and it drives them, adding pc-scrollspy-link--active and aria-current=\"location\" to the one being read." do
    ~H"""
    <div class="flex gap-8">
      <nav
        id="showcase-scrollspy-bare"
        phx-hook="PetalScrollspy"
        data-offset="1rem"
        aria-label="On this page"
        class="flex-none w-40 space-y-1 text-sm"
      >
        <a
          href="#ssb-one"
          data-scrollspy-target="ssb-one"
          class="block text-gray-500 dark:text-gray-400 [&.pc-scrollspy-link--active]:font-semibold [&.pc-scrollspy-link--active]:text-primary-600 dark:[&.pc-scrollspy-link--active]:text-primary-400"
        >
          First
        </a>
        <a
          href="#ssb-two"
          data-scrollspy-target="ssb-two"
          class="block text-gray-500 dark:text-gray-400 [&.pc-scrollspy-link--active]:font-semibold [&.pc-scrollspy-link--active]:text-primary-600 dark:[&.pc-scrollspy-link--active]:text-primary-400"
        >
          Second
        </a>
        <a
          href="#ssb-three"
          data-scrollspy-target="ssb-three"
          class="block text-gray-500 dark:text-gray-400 [&.pc-scrollspy-link--active]:font-semibold [&.pc-scrollspy-link--active]:text-primary-600 dark:[&.pc-scrollspy-link--active]:text-primary-400"
        >
          Third
        </a>
      </nav>
      <div class="flex-1 h-56 pr-2 overflow-y-auto">
        <section id="ssb-one" class="pb-24">
          <h2 class="text-base font-semibold">First</h2>
          <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            No pc-scrollspy classes anywhere in this example.
          </p>
        </section>
        <section id="ssb-two" class="pb-24">
          <h2 class="text-base font-semibold">Second</h2>
          <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            The links style themselves off the active class.
          </p>
        </section>
        <section id="ssb-three" class="pb-4">
          <h2 class="text-base font-semibold">Third</h2>
          <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            Same hook, your markup.
          </p>
        </section>
      </div>
    </div>
    """
  end
end
