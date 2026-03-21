defmodule PetalComponents.DropdownTest do
  @moduledoc """
  Tests for PetalComponents.Dropdown component.

  Validates dropdown rendering, menu items, placement options,
  JavaScript library integration, and proper handling of edge cases.
  """

  use ComponentCase
  import PetalComponents.Dropdown
  import PetalComponents.Icon

  describe "dropdown/1 - basic rendering" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders dropdown with label and menu items", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Dropdown Menu">
          <.dropdown_menu_item label="Option 1" />
          <.dropdown_menu_item label="Option 2" />
        </.dropdown>
        """)

      assert html =~ "Dropdown Menu"
      assert html =~ "Option 1"
      assert html =~ "Option 2"
      assert_has_class(html, "pc-dropdown")
      assert_has_class(html, "pc-dropdown__menu-items-wrapper")
    end

    test "renders dropdown with custom CSS classes", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown
          class="dropdown-custom"
          menu_items_wrapper_class="menu-custom"
          label="Dropdown"
        >
          <.dropdown_menu_item label="Option" />
        </.dropdown>
        """)

      assert_has_class(html, "dropdown-custom")
      assert_has_class(html, "menu-custom")
    end

    test "renders dropdown without label shows icon", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown>
          <.dropdown_menu_item label="Option" />
        </.dropdown>
        """)

      assert has_icon?(html)
    end

    test "dropdown with label has proper trigger class", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Menu">
          <.dropdown_menu_item label="Item" />
        </.dropdown>
        """)

      assert_has_class(html, "pc-dropdown__trigger-button--with-label")
    end
  end

  describe "dropdown/1 - JavaScript library options" do
    setup do
      %{assigns: default_assigns()}
    end

    test "uses Alpine.js by default with x-data and x-show", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Dropdown">
          <.dropdown_menu_item label="Option" />
        </.dropdown>
        """)

      assert_attribute(html, "x-data")
      assert html =~ "x-show"
    end

    test "uses LiveView JS when js_lib is live_view_js", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Dropdown" js_lib="live_view_js">
          <.dropdown_menu_item label="Option" />
        </.dropdown>
        """)

      refute html =~ "x-data"
      refute html =~ "x-show"
      assert_attribute(html, "phx-click")
    end
  end

  describe "dropdown/1 - placement options" do
    setup do
      %{assigns: default_assigns()}
    end

    test "defaults to left placement", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Dropdown">
          <.dropdown_menu_item label="Option" />
        </.dropdown>
        """)

      assert_has_class(html, "pc-dropdown__menu-items-wrapper-placement--left")
    end

    test "renders with left placement explicitly", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Dropdown" placement="left">
          <.dropdown_menu_item label="Option" />
        </.dropdown>
        """)

      assert_has_class(html, "pc-dropdown__menu-items-wrapper-placement--left")
    end

    test "renders with right placement", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Dropdown" placement="right">
          <.dropdown_menu_item label="Option" />
        </.dropdown>
        """)

      assert_has_class(html, "pc-dropdown__menu-items-wrapper-placement--right")
    end

    test "renders all placement options" do
      ~w(left right) |> Enum.each(fn placement ->
        assigns = %{placement: placement}

        html =
          rendered_to_string(~H"""
          <.dropdown label="Dropdown" placement={@placement}>
            <.dropdown_menu_item label="Option" />
          </.dropdown>
          """)

        assert_has_class(html, "pc-dropdown__menu-items-wrapper-placement--#{placement}")
      end)
    end
  end

  describe "dropdown/1 - custom trigger element" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders with custom trigger element", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown>
          <:trigger_element>
            <div class="custom-trigger">Custom Trigger</div>
          </:trigger_element>
          <.dropdown_menu_item label="Item 1" />
          <.dropdown_menu_item label="Item 2" />
        </.dropdown>
        """)

      assert html =~ "Custom Trigger"
      assert_has_class(html, "custom-trigger")
      assert html =~ "Item 1"
      assert html =~ "Item 2"
    end

    test "custom trigger overrides default label", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Default Label">
          <:trigger_element>
            <button>Custom Button</button>
          </:trigger_element>
          <.dropdown_menu_item label="Option" />
        </.dropdown>
        """)

      assert html =~ "Custom Button"
    end
  end

  describe "dropdown_menu_item/1 - basic rendering" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders menu item with label", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Menu">
          <.dropdown_menu_item label="Item Label" />
        </.dropdown>
        """)

      assert html =~ "Item Label"
      assert_has_class(html, "pc-dropdown__menu-item")
    end

    test "renders menu item with inner block content", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Menu">
          <.dropdown_menu_item class="custom-item">
            <.icon name="hero-home" class="w-5 h-5" /> Home Item
          </.dropdown_menu_item>
        </.dropdown>
        """)

      assert has_icon?(html, "hero-home")
      assert html =~ "Home Item"
      assert_has_class(html, "custom-item")
    end

    test "renders menu item with custom class", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Menu">
          <.dropdown_menu_item class="item-custom" label="Item" />
        </.dropdown>
        """)

      assert_has_class(html, "item-custom")
    end
  end

  describe "dropdown_menu_item/1 - disabled state" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders disabled menu item with proper class", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Menu">
          <.dropdown_menu_item disabled label="Disabled Option" />
        </.dropdown>
        """)

      assert_has_class(html, "pc-dropdown__menu-item--disabled")
      assert_attribute(html, "disabled")
    end

    test "non-disabled menu item does not have disabled class", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Menu">
          <.dropdown_menu_item label="Enabled Option" />
        </.dropdown>
        """)

      refute_has_class(html, "pc-dropdown__menu-item--disabled")
      refute_attribute(html, "disabled")
    end
  end

  describe "dropdown_menu_item/1 - link types" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders as button by default", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Menu">
          <.dropdown_menu_item label="Button Item" />
        </.dropdown>
        """)

      assert html =~ "<button"
    end

    test "renders with phx-click event for button type", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Menu">
          <.dropdown_menu_item link_type="button" phx-click="some_event" label="Option" />
        </.dropdown>
        """)

      assert_attribute(html, "phx-click", "some_event")
    end

    test "passes through rest attributes to button", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown custom-attrs="123" label="Menu">
          <.dropdown_menu_item phx-click="event" data-id="item-1">Option</.dropdown_menu_item>
        </.dropdown>
        """)

      assert_attribute(html, "custom-attrs", "123")
      assert_attribute(html, "phx-click", "event")
      assert_attribute(html, "data-id", "item-1")
    end
  end

  describe "dropdown/1 - accessibility" do
    setup do
      %{assigns: default_assigns()}
    end

    test "dropdown trigger is keyboard accessible", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Accessible Menu">
          <.dropdown_menu_item label="Item" />
        </.dropdown>
        """)

      assert html =~ "<button"
    end

    test "menu items have proper role and aria attributes", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Menu" role="menu">
          <.dropdown_menu_item label="Item" role="menuitem" />
        </.dropdown>
        """)

      assert_attribute(html, "role", "menu")
      assert_attribute(html, "role", "menuitem")
    end

    test "disabled items are marked for screen readers", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Menu">
          <.dropdown_menu_item disabled aria-disabled="true" label="Disabled" />
        </.dropdown>
        """)

      assert_attribute(html, "disabled")
      assert_attribute(html, "aria-disabled", "true")
    end
  end

  describe "dropdown/1 - edge cases" do
    setup do
      %{assigns: default_assigns()}
    end

    test "handles empty dropdown with no items", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Empty Dropdown">
        </.dropdown>
        """)

      assert html =~ "Empty Dropdown"
      assert_has_class(html, "pc-dropdown")
    end

    test "handles nil label with icon fallback", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label={nil}>
          <.dropdown_menu_item label="Item" />
        </.dropdown>
        """)

      assert has_icon?(html)
    end

    test "handles dropdown with many items", %{assigns: assigns} do
      items = for i <- 1..20, do: {"Item #{i}", "item_#{i}"}
      assigns = %{items: items}

      html =
        rendered_to_string(~H"""
        <.dropdown label="Many Items">
          <%= for {label, _value} <- @items do %>
            <.dropdown_menu_item label={label} />
          <% end %>
        </.dropdown>
        """)

      assert html =~ "Item 1"
      assert html =~ "Item 20"
    end

    test "handles default placement", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.dropdown label="Menu">
          <.dropdown_menu_item label="Item" />
        </.dropdown>
        """)

      assert_has_class(html, "pc-dropdown__menu-items-wrapper-placement--left")
    end

    test "handles very long label text", %{assigns: assigns} do
      long_label = String.duplicate("Very Long Label ", 10)
      assigns = %{label: long_label}

      html =
        rendered_to_string(~H"""
        <.dropdown label={@label}>
          <.dropdown_menu_item label="Item" />
        </.dropdown>
        """)

      assert html =~ long_label
    end
  end

  describe "dropdown/1 - negative cases" do
    setup do
      %{assigns: default_assigns()}
    end

    test "invalid js_lib raises error", %{assigns: assigns} do
      assert_raise FunctionClauseError, fn ->
        rendered_to_string(~H"""
        <.dropdown label="Menu" js_lib="invalid">
          <.dropdown_menu_item label="Item" />
        </.dropdown>
        """)
      end
    end

    test "invalid placement raises error", %{assigns: assigns} do
      assert_raise FunctionClauseError, fn ->
        rendered_to_string(~H"""
        <.dropdown label="Menu" placement="invalid">
          <.dropdown_menu_item label="Item" />
        </.dropdown>
        """)
      end
    end

    test "menu item without label raises error", %{assigns: assigns} do
      assert_raise KeyError, fn ->
        rendered_to_string(~H"""
        <.dropdown label="Menu">
          <.dropdown_menu_item />
        </.dropdown>
        """)
      end
    end
  end
end
