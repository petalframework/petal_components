defmodule PetalComponents.DropdownTest do
  use ComponentCase
  import PetalComponents.Dropdown
  alias PetalComponents.Heroicons

  test "dropdown" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <.dropdown label="Dropdown">
        <.dropdown_menu_item type="button">
          <Heroicons.Outline.home class="w-5 h-5 text-gray-500" />
          Button item with icon
        </.dropdown_menu_item>
      </.dropdown>
      """
    )
    assert html =~ "x-data"
    assert html =~ "x-show"
    assert html =~ "<svg class="

    # Test js_lib option
    html = rendered_to_string(
      ~H"""
      <.dropdown label="Dropdown" js_lib="live_view_js">
        <.dropdown_menu_item label="Option" />
      </.dropdown>
      """
    )
    refute html =~ "x-data"
    assert html =~ "phx-click"

    # Test placement option
    assert rendered_to_string(
      ~H"""
      <.dropdown label="Dropdown" placement="left">
        <.dropdown_menu_item label="Option" />
      </.dropdown>
      """
    ) =~ "right-0"

    assert rendered_to_string(
      ~H"""
      <.dropdown label="Dropdown" placement="right">
        <.dropdown_menu_item label="Option" />
      </.dropdown>
      """
    ) =~ "left-0"
  end

  test "dark mode" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <.dropdown label="Dropdown">
        <.dropdown_menu_item type="button">
          <Heroicons.Outline.home class="w-5 h-5 text-gray-500" />
          Button item with icon
        </.dropdown_menu_item>
      </.dropdown>
      """
    )
    assert html =~ "x-data"
    assert html =~ "x-show"
    assert html =~ "<svg class="
    assert html =~ "dark:"
  end
end
