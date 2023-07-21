defmodule PetalComponents.UserDropdownMenuTest do
  use ComponentCase
  import PetalComponents.UserDropdownMenu

  test "renders correctly" do
    assigns = %{
      user_menu_items: [%{path: "/path", icon: :home, label: "blah"}],
      avatar_src: "blah.img",
      current_user_name: nil
    }

    html =
      rendered_to_string(~H"""
      <.user_dropdown_menu
        user_menu_items={@user_menu_items}
        avatar_src={@avatar_src}
        current_user_name={@current_user_name}
      />
      """)

    assert html =~ "<img"
    assert html =~ "<svg"
    assert html =~ "/path"
    assert html =~ "blah"
  end
end
