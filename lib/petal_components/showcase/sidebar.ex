defmodule PetalComponents.Showcase.Sidebar do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Sidebar,
    title: "Sidebar",
    functions: [:sidebar_shell, :sidebar_nav, :sidebar_group, :sidebar_item, :sidebar_trigger]

  example :app_shell, "App shell",
    description:
      "The whole anatomy: a shell, a branded header, two labelled groups, icons and a badge, and a footer. The rail toggle in the header collapses it to icons - no server round trip." do
    ~H"""
    <.sidebar_shell
      for="sb-shell"
      class="h-[30rem] min-h-0 overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800"
    >
      <:sidebar>
        <.sidebar_nav id="sb-shell" label="Main">
          <:header>
            <.icon name="hero-cube" class="w-5 h-5 shrink-0 text-primary-500" />
            <span class="pc-sidebar__brand">Acme Inc</span>
            <.sidebar_trigger for="sb-shell" class="ml-auto" />
          </:header>

          <.sidebar_group label="Workspace">
            <.sidebar_item label="Dashboard" path="#" link_type="a" icon="hero-home" active />
            <.sidebar_item label="Inbox" path="#" link_type="a" icon="hero-inbox" badge="12" />
            <.sidebar_item label="Customers" path="#" link_type="a" icon="hero-users" />
          </.sidebar_group>

          <.sidebar_group label="Account">
            <.sidebar_item label="Settings" icon="hero-cog-6-tooth" open>
              <.sidebar_item label="Profile" path="#" link_type="a" />
              <.sidebar_item label="Billing" path="#" link_type="a" />
            </.sidebar_item>
            <.sidebar_item label="Team" path="#" link_type="a" icon="hero-user-group" />
          </.sidebar_group>

          <:footer>
            <.sidebar_item
              label="Sign out"
              path="#"
              link_type="a"
              icon="hero-arrow-left-start-on-rectangle"
            />
          </:footer>
        </.sidebar_nav>
      </:sidebar>

      <header class="flex items-center flex-none gap-3 px-4 border-b border-gray-200 h-14 dark:border-gray-800">
        <.sidebar_trigger for="sb-shell" target="mobile" />
        <span class="text-sm font-semibold">Dashboard</span>
      </header>
      <div class="p-4 text-sm text-gray-500 dark:text-gray-400">
        Your page content lives here. It is marked inert while the mobile sheet is open.
      </div>
    </.sidebar_shell>
    """
  end

  example :collapsed_rail, "Collapsed rail",
    description:
      "collapsible=\"icon\" with collapsed set - the rail the app renders on first paint. Labels drop to screen-reader-only text and the title attribute carries them on hover, so nothing is lost." do
    ~H"""
    <.sidebar_shell
      for="sb-rail"
      class="h-[22rem] min-h-0 overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800"
    >
      <:sidebar>
        <.sidebar_nav id="sb-rail" label="Compact" collapsible="icon" collapsed>
          <:header>
            <.icon name="hero-cube" class="w-5 h-5 shrink-0 text-primary-500" />
            <span class="pc-sidebar__brand">Acme</span>
          </:header>

          <.sidebar_group label="Workspace">
            <.sidebar_item label="Dashboard" path="#" link_type="a" icon="hero-home" active />
            <.sidebar_item label="Inbox" path="#" link_type="a" icon="hero-inbox" badge="12" />
            <.sidebar_item label="Customers" path="#" link_type="a" icon="hero-users" />
          </.sidebar_group>

          <:footer>
            <.sidebar_trigger for="sb-rail" class="mx-auto" />
          </:footer>
        </.sidebar_nav>
      </:sidebar>

      <div class="p-4 text-sm text-gray-500 dark:text-gray-400">
        Hit the toggle at the bottom of the rail to expand it back out.
      </div>
    </.sidebar_shell>
    """
  end

  example :collapsible_groups, "Collapsible groups",
    description:
      "Groups follow the WAI-ARIA disclosure pattern: the label becomes a button carrying aria-expanded, and the run of items it controls is hidden or shown by CSS." do
    ~H"""
    <.sidebar_shell
      for="sb-groups"
      class="h-[22rem] min-h-0 overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800"
    >
      <:sidebar>
        <.sidebar_nav id="sb-groups" label="Docs" collapsible="none">
          <.sidebar_group label="Getting started" collapsible open>
            <.sidebar_item label="Installation" path="#" link_type="a" active />
            <.sidebar_item label="Theming" path="#" link_type="a" />
          </.sidebar_group>

          <.sidebar_group label="Components" collapsible open={false}>
            <.sidebar_item label="Button" path="#" link_type="a" />
            <.sidebar_item label="Modal" path="#" link_type="a" />
            <.sidebar_item label="Table" path="#" link_type="a" />
          </.sidebar_group>

          <.sidebar_group>
            <.sidebar_item label="Changelog" path="#" link_type="a" icon="hero-sparkles" />
          </.sidebar_group>
        </.sidebar_nav>
      </:sidebar>

      <div class="p-4 text-sm text-gray-500 dark:text-gray-400">
        Click a group label to collapse it. collapsible="none" pins this sidebar open at every width.
      </div>
    </.sidebar_shell>
    """
  end

  example :inspector, "Right-hand inspector",
    description:
      "side=\"right\" plus an offcanvas mode gives you an inspector panel. Two sidebars in one shell just need different ids - their state never crosses." do
    ~H"""
    <.sidebar_shell
      for="sb-inspector"
      class="h-[20rem] min-h-0 overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800"
    >
      <:sidebar>
        <.sidebar_nav id="sb-inspector" label="Inspector" side="right" collapsible="offcanvas">
          <:header>
            <span class="pc-sidebar__brand">Properties</span>
            <.sidebar_trigger for="sb-inspector" class="ml-auto" label="Hide inspector" />
          </:header>

          <.sidebar_group label="Layer">
            <.sidebar_item label="Fill" path="#" link_type="a" icon="hero-swatch" active />
            <.sidebar_item label="Stroke" path="#" link_type="a" icon="hero-pencil" />
            <.sidebar_item label="Effects" path="#" link_type="a" icon="hero-sparkles" />
          </.sidebar_group>
        </.sidebar_nav>
      </:sidebar>

      <div class="flex items-center gap-3 p-4">
        <.sidebar_trigger for="sb-inspector" label="Show inspector" />
        <span class="text-sm text-gray-500 dark:text-gray-400">Canvas</span>
      </div>
    </.sidebar_shell>
    """
  end
end
