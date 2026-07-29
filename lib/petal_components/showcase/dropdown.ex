defmodule PetalComponents.Showcase.Dropdown do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Dropdown,
    title: "Dropdown",
    functions: [:dropdown, :dropdown_menu_item, :dropdown_menu_label, :dropdown_menu_separator]

  example :account_menu, "Account menu",
    description:
      "Menus on the floating-panel surface. label renders the built-in trigger - deliberately neutral gray whatever your palette, only its focus ring rides primary. dropdown_menu_label and dropdown_menu_separator organise groups; items take arbitrary content - icons, .pc-kbd hints, a custom class for the destructive one - and render as a, live_patch, live_redirect or button via link_type." do
    ~H"""
    <.dropdown label="you@example.com">
      <.dropdown_menu_label>My account</.dropdown_menu_label>
      <.dropdown_menu_item link_type="button">
        <.icon name="hero-user" class="w-4 h-4" /> Profile
        <kbd class="pc-kbd ml-auto"><span>⇧</span><span>⌘</span>P</kbd>
      </.dropdown_menu_item>
      <.dropdown_menu_item link_type="button">
        <.icon name="hero-credit-card" class="w-4 h-4" /> Billing
      </.dropdown_menu_item>
      <.dropdown_menu_item link_type="button">
        <.icon name="hero-cog-6-tooth" class="w-4 h-4" /> Settings
        <kbd class="pc-kbd ml-auto"><span>⌘</span>,</kbd>
      </.dropdown_menu_item>
      <.dropdown_menu_separator />
      <.dropdown_menu_label>Team</.dropdown_menu_label>
      <.dropdown_menu_item link_type="button">
        <.icon name="hero-user-plus" class="w-4 h-4" /> Invite members
      </.dropdown_menu_item>
      <.dropdown_menu_item link_type="button" disabled>
        <.icon name="hero-plus" class="w-4 h-4" /> New team (Pro)
      </.dropdown_menu_item>
      <.dropdown_menu_separator />
      <.dropdown_menu_item link_type="button" class="text-danger-600 dark:text-danger-400">
        <.icon name="hero-arrow-right-start-on-rectangle" class="w-4 h-4" /> Sign out
        <kbd class="pc-kbd ml-auto"><span>⇧</span><span>⌘</span>Q</kbd>
      </.dropdown_menu_item>
    </.dropdown>
    """
  end

  example :row_actions, "Row actions and a custom trigger",
    description:
      "No label renders the ghost ellipsis - the table-row actions trigger. For a branded trigger, :trigger_element is your own button (style it with trigger_class); this one goes solid and follows your colour dials. placement drops the panel left or right of the trigger." do
    ~H"""
    <div class="flex items-start justify-center gap-16">
      <.dropdown>
        <.dropdown_menu_item link_type="button">
          <.icon name="hero-pencil-square" class="w-4 h-4" /> Edit
          <kbd class="pc-kbd ml-auto"><span>⌘</span>E</kbd>
        </.dropdown_menu_item>
        <.dropdown_menu_item link_type="button">
          <.icon name="hero-document-duplicate" class="w-4 h-4" /> Duplicate
          <kbd class="pc-kbd ml-auto"><span>⌘</span>D</kbd>
        </.dropdown_menu_item>
        <.dropdown_menu_item link_type="button">
          <.icon name="hero-archive-box" class="w-4 h-4" /> Archive
        </.dropdown_menu_item>
        <.dropdown_menu_separator />
        <.dropdown_menu_item link_type="button" class="text-danger-600 dark:text-danger-400">
          <.icon name="hero-trash" class="w-4 h-4" /> Delete
          <kbd class="pc-kbd ml-auto"><span>⌘</span>⌫</kbd>
        </.dropdown_menu_item>
      </.dropdown>
      <.dropdown placement="right" trigger_class="pc-button pc-button--primary pc-button--md">
        <:trigger_element>
          Move to project <.icon name="hero-chevron-down" class="w-4 h-4 ml-1" />
        </:trigger_element>
        <.dropdown_menu_label>Recent</.dropdown_menu_label>
        <.dropdown_menu_item link_type="button">petal_components</.dropdown_menu_item>
        <.dropdown_menu_item link_type="button">petal_pro</.dropdown_menu_item>
        <.dropdown_menu_item link_type="button">marketing site</.dropdown_menu_item>
      </.dropdown>
    </div>
    """
  end
end
