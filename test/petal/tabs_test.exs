defmodule PetalComponents.TabsTest do
  use ComponentCase
  import PetalComponents.Tabs
  import PetalComponents.Icon

  test "Test tabs active" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tabs class="flex-col sm:flex-row space-x">
        <.tab is_active to="/">Home</.tab>
        <.tab link_type="a" to="/" label="Press me" phx-click="click_event" />
      </.tabs>
      """)

    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href="
    assert html =~ "phx-click"
    assert html =~ "pc-tab__pill--is-active"
  end

  test "Test tabs underline" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tabs class="flex-col sm:flex-row space-x">
        <.tab underline is_active to="/">Home</.tab>
        <.tab underline link_type="a" to="/" label="Press me" phx-click="click_event" />
      </.tabs>
      """)

    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href="
    assert html =~ "phx-click"
    assert html =~ "pc-tab__underline"
  end

  test "Test tabs a" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tabs class="flex-col sm:flex-row space-x">
        <.tab is_active to="/">Home</.tab>
        <.tab link_type="a" to="/" label="Press me" phx-click="click_event" />
      </.tabs>
      """)

    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href="
    assert html =~ "phx-click"
  end

  test "Test tabs custom css class" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tabs class="flex-col sm:flex-row space-x">
        <.tab class="hello" is_active to="/">Home</.tab>
      </.tabs>
      """)

    assert html =~ " hello"
  end

  test "patch" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tabs class="flex-col sm:flex-row space-x">
        <.tab is_active to="/">Home</.tab>
        <.tab link_type="live_patch" to="/" label="Press me" phx-click="click_event" />
      </.tabs>
      """)

    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href="
    assert html =~ "phx-click"
  end

  test "redirect" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tabs class="flex-col sm:flex-row space-x">
        <.tab is_active to="/">Home</.tab>
        <.tab link_type="live_redirect" to="/" label="Press me" phx-click="click_event" />
      </.tabs>
      """)

    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href="
    assert html =~ "phx-click"
  end

  test "tabs with number" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tabs>
        <.tab number={1} is_active to="/">Home</.tab>
        <.tab number={63} link_type="a" to="/" label="Press me" phx-click="click_event" />
      </.tabs>
      """)

    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href="
    assert html =~ "phx-click"
    assert html =~ "<span"
  end

  test "tabs with icon" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tabs underline>
        <.tab underline is_active to="/">
          <.icon name="hero-home" class="w-5 h-5 mr-2" /> Home
        </.tab>
        <.tab underline link_type="a" to="/" phx-click="click_event">
          <.icon name="hero-building-office" class="w-5 h-5 mr-2" /> Company
        </.tab>
      </.tabs>
      """)

    assert html =~ "<a"
    assert html =~ "href="
    assert html =~ "phx-click"
    assert find_icon(html, "hero-home")
    assert find_icon(html, "hero-building-office")
  end

  test "dark mode" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tabs underline>
        <.tab underline is_active to="/">
          <.icon name="hero-home" class="w-5 h-5 mr-2" /> Home
        </.tab>
        <.tab underline link_type="a" to="/" phx-click="click_event">
          <.icon name="hero-building-office" class="w-5 h-5 mr-2" /> Company
        </.tab>
      </.tabs>
      """)

    assert html =~ "<a"
    assert html =~ "href="
    assert html =~ "phx-click"
    assert find_icon(html, "hero-home")
    assert find_icon(html, "hero-building-office")
    assert html =~ "pc-tab__underline--is-active"
  end

  test "should include additional assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tabs custom-attrs="1" underline>
        <.tab custom-attrs="2" underline is_active to="/">
          <.icon name="hero-home" class="w-5 h-5 mr-2" /> Home
        </.tab>
        <.tab custom-attrs="3" underline link_type="a" to="/" phx-click="click_event">
          <.icon name="hero-building-office" class="w-5 h-5 mr-2" /> Company
        </.tab>
      </.tabs>
      """)

    for i <- 1..3 do
      assert html =~ ~s{custom-attrs="#{i}"}
    end
  end

  test "disabled tab" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tabs custom-attrs="1" underline>
        <.tab disabled to="/">Home</.tab>
      </.tabs>
      """)

    assert html =~ "disabled"
  end
end
