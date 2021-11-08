defmodule PetalComponents.DropdownTest do
  use ComponentCase
  import PetalComponents.Dropdown

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
    assert html =~ "<div x-data="
    assert html =~ "<div x-show="
    assert html =~ "<svg class="
  end
end
