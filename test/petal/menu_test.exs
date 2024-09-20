defmodule PetalComponents.MenuTest do
  use ComponentCase
  import PetalComponents.Menu

  describe "vertical_menu/1" do
    test "renders correctly" do
      assigns = %{
        main_menu_items: [
          %{
            name: :sign_in,
            label: "Path",
            path: "/path",
            icon: "hero-key"
          }
        ],
        current_page: :current_page,
        sidebar_title: "blah"
      }

      html =
        rendered_to_string(~H"""
        <.vertical_menu menu_items={@main_menu_items} current_page={@current_page} title={@sidebar_title} />
        """)

      assert find_icon(html, "hero-key")
      assert html =~ "Path"
      assert html =~ "/path"
      assert html =~ "blah"
    end

    test "renders with no menu items" do
      assigns = %{
        current_page: :current_page,
        sidebar_title: "blah"
      }

      html =
        rendered_to_string(~H"""
        <.vertical_menu menu_items={[]} current_page={@current_page} title={@sidebar_title} />
        """)

      assert html =~ ""
    end

    test "renders without icons" do
      assigns = %{
        main_menu_items: [
          %{
            name: :sign_in,
            label: "Path",
            path: "/path"
          }
        ],
        current_page: :current_page,
        sidebar_title: "blah"
      }

      html =
        rendered_to_string(~H"""
        <.vertical_menu menu_items={@main_menu_items} current_page={@current_page} title={@sidebar_title} />
        """)

      assert html =~ "Path"
      assert html =~ "/path"
      assert html =~ "blah"
    end

    test "grouped menu renders correctly" do
      assigns = %{
        main_menu_items: [
          %{
            title: "Menu group 1",
            menu_items: [
              %{
                name: :home,
                label: "Home",
                path: "#",
                icon: "hero-home"
              }
            ]
          },
          %{
            title: "Menu group 2",
            menu_items: [
              %{
                name: :school,
                label: "School",
                path: "#",
                icon: "hero-academic-cap"
              }
            ]
          }
        ],
        current_page: :current_page,
        sidebar_title: "blah"
      }

      html =
        rendered_to_string(~H"""
        <.vertical_menu menu_items={@main_menu_items} current_page={@current_page} title={@sidebar_title} />
        """)

      assert find_icon(html, "hero-home")
      assert html =~ "Home"
      assert html =~ "School"
    end

    test "active menu item renders css correctly" do
      assigns = %{
        menu_items: [
          %{
            title: "Menu group 1",
            menu_items: [
              %{
                name: :home,
                label: "Home",
                path: "/",
                icon: "hero-home"
              }
            ]
          },
          %{
            title: "Menu group 2",
            menu_items: [
              %{
                name: :school,
                label: "School",
                path: "#",
                icon: "hero-academic-cap"
              }
            ]
          }
        ],
        current_page: :home,
        title: "blah"
      }

      html =
        rendered_to_string(~H"""
        <.vertical_menu menu_items={@menu_items} current_page={@current_page} title={@title} />
        """)

      assert html =~ "pc-vertical-menu-item__icon--active"
    end

    test "nested menu items renders icon" do
      assigns = %{
        main_menu_items: [
          %{
            name: :home,
            label: "Home",
            icon: "hero-home",
            menu_items: [
              %{
                name: :sign_in,
                label: "Sign in",
                path: "/sign-in",
                icon: "hero-key"
              },
              %{
                name: :sign_up,
                label: "Sign up",
                path: "/sign-up",
                icon: "hero-key"
              }
            ]
          }
        ],
        current_page: :current_page,
        sidebar_title: "blah"
      }

      html =
        rendered_to_string(~H"""
        <.vertical_menu menu_items={@main_menu_items} current_page={@current_page} title={@sidebar_title} />
        """)

      assert html =~ "Home"
      assert find_icon(html, "hero-home")
      assert find_icon(html, "hero-chevron-right")

      assert html =~ "Sign in"
      assert html =~ "/sign-in"
      assert find_icon(html, "hero-key")
    end

    test "Icon implemented as user function" do
      assigns = %{
        main_menu_items: [
          %{
            name: :sign_in,
            label: "Sign in",
            path: "/sign-in",
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
        current_page: :current_page,
        sidebar_title: "blah"
      }

      html =
        rendered_to_string(~H"""
        <.vertical_menu menu_items={@main_menu_items} current_page={@current_page} title={@sidebar_title} />
        """)

      assert html =~ "svg"
    end

    test "Icon implemented as an svg or image" do
      assigns = %{
        main_menu_items: [
          %{
            name: :sign_in,
            label: "Sign in",
            path: "/sign-in",
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
            name: :sign_out,
            label: "Sign out",
            path: "/sign-out",
            icon: """
            <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AoSEhkYsH3MrQAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAAARSURBVDjLY2AYBaMAAQgAADAAAXkT9BsAAAAASUVORK5CYII=" alt="20x20 red square" />
            """
          }
        ],
        current_page: :current_page,
        sidebar_title: "blah"
      }

      html =
        rendered_to_string(~H"""
        <.vertical_menu menu_items={@main_menu_items} current_page={@current_page} title={@sidebar_title} />
        """)

      assert html =~ "svg"
      assert html =~ "img"
    end
  end
end
