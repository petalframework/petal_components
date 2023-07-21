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
      current_page: :current_page,
      sidebar_title: "blah"
    }

    html =
      rendered_to_string(~H"""
      <.menu menu_items={@main_menu_items} current_page={@current_page} title={@sidebar_title} />
      """)

    assert html =~ "<svg"
    assert html =~ "Path"
    assert html =~ "/path"
    assert html =~ "blah"
  end
end
