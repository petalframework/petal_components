defmodule PetalComponents.TabsTest do
  use ComponentCase
  import PetalComponents.Tabs
  alias PetalComponents.Heroicons

  test "Test tabs active" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <.tabs class="flex-col sm:flex-row space-x">
        <.tab is_active to="/">Home</.tab>
        <.tab link_type="a" to="/" label="Press me" phx-click="click_event" />
      </.tabs>
      """
    )

    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href="
    assert html =~ "phx-click"
    assert html =~ "text-primary-"
  end

  test "Test tabs underline" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <.tabs class="flex-col sm:flex-row space-x">
        <.tab underline is_active to="/">Home</.tab>
        <.tab underline link_type="a" to="/" label="Press me" phx-click="click_event" />
      </.tabs>
      """
    )

    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href="
    assert html =~ "phx-click"
    assert html =~ "border-b-2"
  end

  test "Test tabs a" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <.tabs class="flex-col sm:flex-row space-x">
        <.tab is_active to="/">Home</.tab>
        <.tab link_type="a" to="/" label="Press me" phx-click="click_event" />
      </.tabs>
      """
    )

    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href="
    assert html =~ "phx-click"
  end

  test "patch" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <.tabs class="flex-col sm:flex-row space-x">
        <.tab is_active to="/">Home</.tab>
        <.tab link_type="live_patch" to="/" label="Press me" phx-click="click_event" />
      </.tabs>
      """
    )
    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href="
    assert html =~ "phx-click"
  end

  test "redirect" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <.tabs class="flex-col sm:flex-row space-x">
        <.tab is_active to="/">Home</.tab>
        <.tab link_type="live_redirect" to="/" label="Press me" phx-click="click_event" />
      </.tabs>
      """
    )
    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href="
    assert html =~ "phx-click"
  end

  test "tabs with number" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <.tabs>
        <.tab number={1} is_active to="/">Home</.tab>
        <.tab number={63} link_type="a" to="/" label="Press me" phx-click="click_event" />
      </.tabs>
      """
    )
    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href="
    assert html =~ "phx-click"
    assert html =~ "<span"
  end

  test "tabs with icon" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <.tabs underline>
        <.tab underline is_active to="/">
          <Heroicons.Outline.home class="w-5 h-5 mr-2" />
            Home
        </.tab>
        <.tab underline link_type="a" to="/" phx-click="click_event" >
          <Heroicons.Outline.office_building class="w-5 h-5 mr-2"  />
            Company
        </.tab>
      </.tabs>
      """
    )
    assert html =~ "<a"
    assert html =~ "href="
    assert html =~ "phx-click"
    assert html =~ "<svg"
  end

  test "dark mode" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <.tabs underline>
        <.tab underline is_active to="/">
          <Heroicons.Outline.home class="w-5 h-5 mr-2" />
            Home
        </.tab>
        <.tab underline link_type="a" to="/" phx-click="click_event" >
          <Heroicons.Outline.office_building class="w-5 h-5 mr-2"  />
            Company
        </.tab>
      </.tabs>
      """
    )
    assert html =~ "<a"
    assert html =~ "href="
    assert html =~ "phx-click"
    assert html =~ "<svg"
    assert html =~ "dark:"
  end
end
