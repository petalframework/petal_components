defmodule PetalComponents.Showcase.Tabs do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Tabs,
    title: "Tabs",
    functions: [:tabs, :tab]

  example :styles, "Three styles",
    description:
      "segmented is the modern default for in-page switching - the active tab is a raised pill on a muted track, nested-radius; underline suits page-level navigation; pill is the roomy classic. Tabs are links or buttons via link_type - wire them to live_patch, JS commands or events; number renders the count badge." do
    ~H"""
    <div class="flex flex-col items-center gap-8">
      <.tabs variant="segmented">
        <.tab variant="segmented" is_active link_type="button">Overview</.tab>
        <.tab variant="segmented" link_type="button">Analytics</.tab>
        <.tab variant="segmented" link_type="button" number={4}>Reports</.tab>
      </.tabs>
      <.tabs variant="underline">
        <.tab variant="underline" is_active link_type="button">Overview</.tab>
        <.tab variant="underline" link_type="button">Analytics</.tab>
        <.tab variant="underline" link_type="button" number={4}>Reports</.tab>
      </.tabs>
      <.tabs variant="pill">
        <.tab variant="pill" is_active link_type="button">Overview</.tab>
        <.tab variant="pill" link_type="button">Analytics</.tab>
        <.tab variant="pill" link_type="button" number={4}>Reports</.tab>
      </.tabs>
    </div>
    """
  end

  example :with_icons, "With icons",
    description:
      "Anything goes in the tab body - icons beside labels here. The legacy underline flag still works; variant wins when both are set." do
    ~H"""
    <.tabs variant="segmented">
      <.tab variant="segmented" is_active link_type="button">
        <.icon name="hero-chart-bar" class="w-4 h-4 mr-1.5" /> Dashboard
      </.tab>
      <.tab variant="segmented" link_type="button">
        <.icon name="hero-users" class="w-4 h-4 mr-1.5" /> Team
      </.tab>
      <.tab variant="segmented" link_type="button">
        <.icon name="hero-cog-6-tooth" class="w-4 h-4 mr-1.5" /> Settings
      </.tab>
    </.tabs>
    """
  end
end
