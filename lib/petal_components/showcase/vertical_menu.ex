defmodule PetalComponents.Showcase.VerticalMenu do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Menu,
    title: "Vertical menu",
    functions: [:vertical_menu, :vertical_menu_item, :menu_group]

  example :flagship, "The list in its shell",
    description:
      "The menu is the list. The sidebar is the shell it hangs in. Here they are composed: sidebar_shell and sidebar_nav for the chrome, a workspace switcher in the header slot, a user menu in the footer slot, and vertical_menu doing the one job it exists for in between. Nothing here is a new component - a menu item carrying its own menu_items becomes a collapsible sub-menu (Playground is open because a child is the current_page), and everything around the list is sidebar: the nav landmark, the slots, the collapse the topbar toggle drives, and the sheet the burger opens below 768px." do
    ~H"""
    <.sidebar_shell
      for="showcase-menu-sidebar"
      class="h-[34rem] min-h-0 w-full overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800"
    >
      <:sidebar>
        <.sidebar_nav id="showcase-menu-sidebar" label="Platform" collapsible="offcanvas">
          <:header>
            <.dropdown
              class="w-full"
              trigger_class="w-full"
              align="start"
              menu_items_wrapper_class="w-60"
            >
              <:trigger_element>
                <div class="flex items-center w-full gap-2 px-2 py-1.5 rounded-lg transition-colors hover:bg-gray-100 dark:hover:bg-white/5">
                  <div class="flex items-center justify-center w-8 h-8 text-sm font-semibold rounded-lg shrink-0 bg-primary-600 text-(--pc-button-solid-fg)">
                    N
                  </div>
                  <div class="flex-1 min-w-0 text-left">
                    <div class="text-sm font-semibold text-gray-900 truncate dark:text-gray-100">
                      Northwind
                    </div>
                    <div class="text-xs text-gray-500 truncate dark:text-gray-400">Enterprise</div>
                  </div>
                  <.icon name="hero-chevron-up-down" class="w-4 h-4 text-gray-400 shrink-0" />
                </div>
              </:trigger_element>
              <.dropdown_menu_label>Workspaces</.dropdown_menu_label>
              <.dropdown_menu_item link_type="button">
                <div class="flex items-center justify-center w-6 h-6 text-xs font-semibold rounded shrink-0 bg-primary-600 text-(--pc-button-solid-fg)">
                  N
                </div>
                Northwind
              </.dropdown_menu_item>
              <.dropdown_menu_item link_type="button">
                <div class="flex items-center justify-center w-6 h-6 text-xs font-semibold text-gray-600 bg-gray-200 rounded shrink-0 dark:bg-white/10 dark:text-gray-300">
                  V
                </div>
                Vertex Labs
              </.dropdown_menu_item>
              <.dropdown_menu_separator />
              <.dropdown_menu_item link_type="button">
                <.icon name="hero-plus" class="w-5 h-5 text-gray-500" /> Add workspace
              </.dropdown_menu_item>
            </.dropdown>
          </:header>

          <.vertical_menu current_page={:history} menu_items={shell_menu_items()} />

          <:footer>
            <.user_dropdown_menu
              variant="sidebar"
              current_user_name="Alex Rivera"
              current_user_email="alex@example.com"
              side="top"
              align="start"
              menu_items_wrapper_class="w-60"
            >
              <.dropdown_menu_label>alex@example.com</.dropdown_menu_label>
              <.dropdown_menu_item link_type="button">
                <.icon name="hero-user-circle" class="w-4 h-4" /> Account
              </.dropdown_menu_item>
              <.dropdown_menu_item link_type="button">
                <.icon name="hero-credit-card" class="w-4 h-4" /> Billing
              </.dropdown_menu_item>
              <.dropdown_menu_separator />
              <.dropdown_menu_item link_type="button" class="text-danger-600 dark:text-danger-400">
                <.icon name="hero-arrow-right-start-on-rectangle" class="w-4 h-4" /> Log out
              </.dropdown_menu_item>
            </.user_dropdown_menu>
          </:footer>
        </.sidebar_nav>
      </:sidebar>

      <div class="flex items-center h-12 gap-2 px-4 text-sm text-gray-500 border-b shrink-0 border-gray-200 dark:border-white/10 dark:text-gray-400">
        <.sidebar_trigger for="showcase-menu-sidebar" target="mobile" />
        <.sidebar_trigger for="showcase-menu-sidebar" label="Hide navigation" />
        <span class="w-px h-4 bg-gray-200 dark:bg-white/10"></span>
        <span>Platform</span>
        <.icon name="hero-chevron-right" class="w-3.5 h-3.5" />
        <span class="font-medium text-gray-900 dark:text-gray-100">History</span>
      </div>
      <div class="grid flex-1 grid-cols-3 gap-4 p-4 auto-rows-min">
        <div class="rounded-xl bg-gray-100 dark:bg-white/[0.03] aspect-video"></div>
        <div class="rounded-xl bg-gray-100 dark:bg-white/[0.03] aspect-video"></div>
        <div class="rounded-xl bg-gray-100 dark:bg-white/[0.03] aspect-video"></div>
        <div class="col-span-3 rounded-xl bg-gray-100 dark:bg-white/[0.03] h-40"></div>
      </div>
    </.sidebar_shell>
    """
  end

  example :standalone, "The list on its own",
    description:
      "vertical_menu without any shell - grouped items from plain maps, icons, an active state driven by current_page, and a nested group that renders as a collapsible sub-menu. This is the whole API: give it maps, tell it where the reader is." do
    ~H"""
    <div class="w-full max-w-xs">
      <.vertical_menu current_page={:history} menu_items={shell_menu_items()} />
    </div>
    """
  end

  # Examples render with `assigns = %{}`, so the nav data lives here.
  defp shell_menu_items do
    [
      %{
        title: "Platform",
        menu_items: [
          %{name: :dashboard, label: "Dashboard", path: "#", icon: "hero-home"},
          %{
            name: :playground,
            label: "Playground",
            icon: "hero-command-line",
            menu_items: [
              %{name: :history, label: "History", path: "#"},
              %{name: :starred, label: "Starred", path: "#"},
              %{name: :ai_settings, label: "Settings", path: "#"}
            ]
          },
          %{name: :models, label: "Models", path: "#", icon: "hero-cube"},
          %{name: :docs, label: "Documentation", path: "#", icon: "hero-book-open"}
        ]
      },
      %{
        title: "Projects",
        menu_items: [
          %{name: :design, label: "Design Engineering", path: "#", icon: "hero-swatch"},
          %{
            name: :sales,
            label: "Sales & Marketing",
            path: "#",
            icon: "hero-presentation-chart-line"
          },
          %{name: :travel, label: "Travel", path: "#", icon: "hero-map"}
        ]
      }
    ]
  end
end
