defmodule PetalComponents.DropdownTest do
  use ComponentCase
  import PetalComponents.Dropdown
  import PetalComponents.Icon

  test "dropdown" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.dropdown
        class="dropdown_class"
        menu_items_wrapper_class="menu_items_wrapper_class"
        label="Dropdown"
      >
        <.dropdown_menu_item class="dropdown_menu_item_class" type="button">
          <.icon name="hero-home" class="w-5 h-5 text-gray-500" /> Button item with icon
        </.dropdown_menu_item>
      </.dropdown>
      """)

    assert html =~ "x-data"
    assert html =~ "x-show"
    assert find_icon(html, "hero-home")
    assert html =~ "menu_items_wrapper_class"
    assert html =~ "pc-dropdown__menu-items-wrapper"
    assert html =~ "pc-dropdown"
    assert html =~ "pc-dropdown__menu-item"
    assert html =~ "pc-dropdown__menu-items-wrapper-placement--left"
    assert html =~ "dropdown_menu_item_class"
    assert html =~ "pc-dropdown__trigger-button--with-label"

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
           """) =~ "pc-dropdown__menu-items-wrapper-placement--left"

    assert rendered_to_string(~H"""
           <.dropdown label="Dropdown" placement="right">
             <.dropdown_menu_item label="Option" />
           </.dropdown>
           """) =~ "pc-dropdown__menu-items-wrapper-placement--right"
  end

  test "the disabled attribute works" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.dropdown>
        <.dropdown_menu_item disabled>Option</.dropdown_menu_item>
      </.dropdown>
      """)

    assert html =~ "pc-dropdown__menu-item--disabled"
    # the attribute itself
    assert html =~ " disabled"
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

    assert find_icon(html)
  end

  test "rest works on buttons" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.dropdown custom-attrs="123">
        <.dropdown_menu_item link_type="button" phx-click="some_event">Option</.dropdown_menu_item>
      </.dropdown>
      """)

    assert html =~ ~s{custom-attrs="123"}
    assert html =~ "phx-click"
    assert html =~ "some_event"
  end
end
