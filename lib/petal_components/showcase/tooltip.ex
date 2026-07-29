defmodule PetalComponents.Showcase.Tooltip do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Tooltip, title: "Tooltip"

  example :basic, "On hover or focus",
    description:
      "A label on hover or keyboard focus. Pure CSS - no JS, no dependencies - and the bubble inverts against the page in both colour schemes. placement puts it top, bottom, left or right; arrow adds the pointer." do
    ~H"""
    <.tooltip label="Copied to clipboard">
      <.button color="gray" variant="outline">Hover me</.button>
    </.tooltip>
    """
  end

  example :icon_buttons, "Icon buttons",
    description:
      "The classic use: a glyph gets its name on hover while aria-label carries it for screen readers - the tooltip is a sighted-user convenience, not the accessible name." do
    ~H"""
    <div class="flex items-center justify-center gap-3">
      <.tooltip label="Bold">
        <.button color="gray" variant="ghost" size="icon" aria-label="Bold">
          <.icon name="hero-bold" />
        </.button>
      </.tooltip>
      <.tooltip label="Italic">
        <.button color="gray" variant="ghost" size="icon" aria-label="Italic">
          <.icon name="hero-italic" />
        </.button>
      </.tooltip>
      <.tooltip label="Link">
        <.button color="gray" variant="ghost" size="icon" aria-label="Link">
          <.icon name="hero-link" />
        </.button>
      </.tooltip>
    </div>
    """
  end

  example :rich_content, "Rich content",
    description:
      "The :content slot takes markup when one line isn't enough - keep it glanceable; a tooltip is still a label, not a panel. For interactive content reach for popover instead." do
    ~H"""
    <.tooltip placement="bottom">
      <:content>
        <span class="font-semibold">Deploys locked</span><br />ask in #releases to unlock
      </:content>
      <.badge color="warning" label="Locked" />
    </.tooltip>
    """
  end
end
