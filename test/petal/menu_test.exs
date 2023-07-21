defmodule PetalComponents.MenuTest do
  use ComponentCase
  import PetalComponents.Menu

  test "renders correctly" do
    assigns = %{
      main_menu_items: [
        %{
          name: :sign_in,
          label: "Path",
          path: "/path",
          icon: :key
        }
      ],
      current_page: 3,
      sidebar_title: "blah"
    }

    html =
      rendered_to_string(~H"""
      <.nav_menu menu_items={@main_menu_items} current_page={@current_page} title={@sidebar_title} />
      """)

    assert html =~ "<svg"
    assert html =~ "Path"
    assert html =~ "/path"
    assert html =~ "blah"
  end
end
