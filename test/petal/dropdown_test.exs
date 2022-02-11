defmodule PetalComponents.DropdownTest do
  use ComponentCase
  import PetalComponents.Dropdown
  alias PetalComponents.Heroicons

  test "dropdown" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.dropdown label="Dropdown">
        <.dropdown_menu_item type="button">
          <Heroicons.Outline.home class="w-5 h-5 text-gray-500" />
          Button item with icon
        </.dropdown_menu_item>
      </.dropdown>
      """)

    assert html =~ "x-data"
    assert html =~ "x-show"
    assert html =~ "<svg class="
    assert html =~ "dark:"

    # Test js_lib option
    html =
      rendered_to_string(~H"""
      <.dropdown label="Dropdown" js_lib="live_view_js">
        <.dropdown_menu_item label="Option" />
      </.dropdown>
      """)

    refute html =~ "x-data"
    assert html =~ "phx-click"

    # Test placement option
    assert rendered_to_string(~H"""
           <.dropdown label="Dropdown" placement="left">
             <.dropdown_menu_item label="Option" />
           </.dropdown>
           """) =~ "right-0"

    assert rendered_to_string(~H"""
           <.dropdown label="Dropdown" placement="right">
             <.dropdown_menu_item label="Option" />
           </.dropdown>
           """) =~ "left-0"
  end

  test "it works with a custom trigger" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.dropdown>
        <:trigger_element>
          <div>Custom trigger</div>
        </:trigger_element>

        <.dropdown_menu_item label="Item 1" />
        <.dropdown_menu_item label="Item 2" />
      </.dropdown>
      """)

    assert html =~ "<div>Custom trigger</div>"
  end

  test "it works without a label" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.dropdown>
        <.dropdown_menu_item>Option</.dropdown_menu_item>
      </.dropdown>
      """)

    assert html =~ "<svg"
  end

  test "extra_assigns works on buttons" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.dropdown>
        <.dropdown_menu_item link_type="button" phx-click="some_event">Option</.dropdown_menu_item>
      </.dropdown>
      """)

    assert html =~ "phx-click"
    assert html =~ "some_event"
  end
end
