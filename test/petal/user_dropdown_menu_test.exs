defmodule PetalComponents.UserDropdownMenuTest do
  use ComponentCase
  import PetalComponents.UserDropdownMenu

  test "renders correctly" do
    assigns = %{
      user_menu_items: [%{path: "/path", icon: "hero-home", label: "blah"}],
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
    assert find_icon(html, "hero-home")
    assert html =~ "/path"
    assert html =~ "blah"
  end

  test "Icon implemented as user function" do
    assigns = %{
      user_menu_items: [
        %{
          name: :home,
          label: "Home",
          path: "/",
          icon: fn assigns ->
            ~H"""
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              class="size-6"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
            </svg>
            """
          end
        }
      ],
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

    assert html =~ "svg"
  end

  test "Icon implemented as an svg or image" do
    assigns = %{
      user_menu_items: [
        %{
          name: :home,
          label: "Home",
          path: "/",
          icon: """
          <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              class="size-6"
            >
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
          </svg>
          """
        },
        %{
          name: :dashoard,
          label: "Dashboard",
          path: "/app",
          icon: """
          <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AoSEhkYsH3MrQAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAARSURBVDjLY2AYBaMAAQgAADAAAXkT9BsAAAAASUVORK5CYII=" alt="20x20 red square" />
          """
        }
      ],
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

    assert html =~ "svg"
    assert html =~ "img"
  end
end
