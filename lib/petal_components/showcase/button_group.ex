defmodule PetalComponents.Showcase.ButtonGroup do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.ButtonGroup,
    title: "Button group",
    functions: [:button_group, :button_group_separator, :button_group_text]

  example :fused, "Fused buttons",
    description:
      "Drop real components in and the group fuses them: outer corners keep the radius token, inner borders collapse to a single line. The buttons carry the size - the group just joins. Set an aria_label; the group announces as one control." do
    ~H"""
    <.button_group aria_label="Change view">
      <.button color="gray" variant="outline" label="Day" />
      <.button color="gray" variant="outline" label="Week" />
      <.button color="gray" variant="outline" label="Month" />
    </.button_group>
    """
  end

  example :split_button, "Split button with a menu",
    description:
      "The GitHub-merge pattern: a primary action fused to a dropdown of alternatives. Outline buttons carry their own dividers; the dropdown trigger borrows button classes via trigger_class so it fuses like a sibling." do
    ~H"""
    <.button_group aria_label="Merge options">
      <.button color="gray" variant="outline" label="Merge pull request" />
      <.dropdown
        placement="left"
        menu_items_wrapper_class="w-72"
        trigger_class="pc-button pc-button--gray-outline pc-button--icon rounded-l-none border-l-0"
      >
        <:trigger_element>
          <.icon name="hero-chevron-down" class="w-4 h-4" />
        </:trigger_element>
        <.dropdown_menu_item link_type="button">
          <.icon name="hero-arrow-down-on-square" class="w-4 h-4 mt-0.5 text-gray-500 shrink-0" />
          <div class="flex flex-col">
            <span class="font-medium text-gray-900 dark:text-gray-100">Create a merge commit</span>
            <span class="text-xs text-gray-500 dark:text-gray-400">
              All commits added to the base via a merge commit
            </span>
          </div>
        </.dropdown_menu_item>
        <.dropdown_menu_item link_type="button">
          <.icon name="hero-arrows-pointing-in" class="w-4 h-4 mt-0.5 text-gray-500 shrink-0" />
          <div class="flex flex-col">
            <span class="font-medium text-gray-900 dark:text-gray-100">Squash and merge</span>
            <span class="text-xs text-gray-500 dark:text-gray-400">
              Commits combined into one before merging
            </span>
          </div>
        </.dropdown_menu_item>
      </.dropdown>
    </.button_group>
    """
  end

  example :solid_separator, "Solid buttons need the separator",
    description:
      "Solid buttons have transparent borders, so put a button_group_separator between them - between primary solids it tints from the solid label colour; elsewhere it matches the border colour." do
    ~H"""
    <.button_group aria_label="Save options">
      <.button label="Save changes" />
      <.button_group_separator />
      <.button size="icon" aria-label="More save options">
        <.icon name="hero-chevron-down" class="w-4 h-4" />
      </.button>
    </.button_group>
    """
  end

  example :toolbar, "Toolbar",
    description:
      "Nested groups stop fusing and gap into clusters - history, formatting and share stay distinct while the buttons inside each cluster fuse." do
    ~H"""
    <.button_group aria_label="Editor toolbar">
      <.button_group aria_label="History">
        <.button color="gray" variant="outline" size="icon" aria-label="Undo">
          <.icon name="hero-arrow-uturn-left" class="w-4 h-4" />
        </.button>
        <.button color="gray" variant="outline" size="icon" aria-label="Redo">
          <.icon name="hero-arrow-uturn-right" class="w-4 h-4" />
        </.button>
      </.button_group>
      <.button_group aria_label="Formatting">
        <.button color="gray" variant="outline" size="icon" aria-label="Bold">
          <.icon name="hero-bold" class="w-4 h-4" />
        </.button>
        <.button color="gray" variant="outline" size="icon" aria-label="Italic">
          <.icon name="hero-italic" class="w-4 h-4" />
        </.button>
      </.button_group>
      <.button_group aria_label="Share">
        <.button color="gray" variant="outline" size="sm" label="Share" />
      </.button_group>
    </.button_group>
    """
  end

  example :mixed_rail, "Mixed rail",
    description:
      "Text segments, inputs and buttons share one surface: button_group_text for the static prefix, any petal input in the middle, a button to act. The URL bar and the search rail from one component." do
    ~H"""
    <div class="flex w-full max-w-sm flex-col items-center gap-5">
      <.button_group aria_label="Site address" class="w-full">
        <.button_group_text>https://</.button_group_text>
        <.input type="text" name="bg_domain" value="" placeholder="example.com" />
        <.button color="gray" variant="outline" label="Visit" />
      </.button_group>
      <.button_group aria_label="Search the docs" class="w-full">
        <.input type="search" name="bg_q" value="" placeholder="Search the docs..." />
        <.button color="gray" variant="outline" size="icon" aria-label="Search">
          <.icon name="hero-magnifying-glass" class="w-4 h-4" />
        </.button>
      </.button_group>
    </div>
    """
  end

  example :vertical, "Vertical",
    description:
      "orientation=\"vertical\" fuses top to bottom - zoom rails, vote stacks, map controls." do
    ~H"""
    <.button_group aria_label="Zoom" orientation="vertical">
      <.button color="gray" variant="outline" size="icon" aria-label="Zoom in">
        <.icon name="hero-plus" class="w-4 h-4" />
      </.button>
      <.button color="gray" variant="outline" size="icon" aria-label="Zoom out">
        <.icon name="hero-minus" class="w-4 h-4" />
      </.button>
    </.button_group>
    """
  end
end
