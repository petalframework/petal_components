defmodule PetalComponents.UserDropdownMenuTest do
  use ComponentCase
  import PetalComponents.Dropdown
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
    assert has_icon?(html, "hero-home")
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

  test "the chevron wears the family class and show_chevron drops it" do
    assigns = %{items: [%{path: "/", icon: "hero-user", label: "Profile"}]}

    html =
      rendered_to_string(~H"""
      <.user_dropdown_menu current_user_name="Sarah Chen" user_menu_items={@items} />
      """)

    assert html =~ "pc-dropdown__chevron"
    refute html =~ "dark:text-gray-100"

    html =
      rendered_to_string(~H"""
      <.user_dropdown_menu current_user_name="Sarah Chen" show_chevron={false} user_menu_items={@items} />
      """)

    refute html =~ "hero-chevron-down-mini"
  end

  test "placement passes through to the dropdown, defaulting left" do
    assigns = %{items: [%{path: "/", icon: "hero-user", label: "Profile"}]}

    html =
      rendered_to_string(~H"""
      <.user_dropdown_menu current_user_name="Sarah Chen" user_menu_items={@items} />
      """)

    assert html =~ "pc-dropdown__menu-items-wrapper-placement--left"

    # the sidebar-bottom avatar: against the left viewport edge the panel must
    # grow rightward into the viewport, not leftward off it
    html =
      rendered_to_string(~H"""
      <.user_dropdown_menu current_user_name="Sarah Chen" placement="right" user_menu_items={@items} />
      """)

    assert html =~ "pc-dropdown__menu-items-wrapper-placement--right"
    refute html =~ "pc-dropdown__menu-items-wrapper-placement--left"
  end

  # The trigger variant="icon" rendered before `variant` existed, captured off
  # main. Everything the new attr can reach lives inside this one element: the
  # button's own class (which now comes from the dropdown's trigger_class) and
  # the trigger_element it wraps. The dropdown's generated id is the only
  # per-render value in there, so it is the only thing normalised away.
  #
  # If this fails after a deliberate change to the icon trigger, re-capture it
  # rather than loosening the comparison - the point is that nobody moves a
  # character of the default variant by accident.
  @icon_trigger_golden ~S"""
  <button type="button" class="pc-dropdown__trigger-button--with-label-and-trigger-element" phx-click="[[&quot;toggle&quot;,{&quot;display&quot;:&quot;block&quot;,&quot;ins&quot;:[[&quot;transition&quot;,&quot;transform&quot;,&quot;ease-out&quot;,&quot;duration-100&quot;],[&quot;transform&quot;,&quot;opacity-0&quot;,&quot;scale-95&quot;],[&quot;transform&quot;,&quot;opacity-100&quot;,&quot;scale-100&quot;]],&quot;to&quot;:&quot;#dropdown_ID&quot;,&quot;outs&quot;:[[&quot;transition&quot;,&quot;ease-in&quot;,&quot;duration-75&quot;],[&quot;transform&quot;,&quot;opacity-100&quot;,&quot;scale-100&quot;],[&quot;transform&quot;,&quot;opacity-0&quot;,&quot;scale-95&quot;]]}]]" aria-haspopup="true" data-pc-dropdown-trigger>
        <span class="sr-only">Open options</span>

        

        
          
      <div class="inline-flex items-center justify-center w-full gap-1 align-middle focus:outline-hidden">
        
          
    
      <div style="background-color: hsl(189, 100%, 35%); color: white;" role="img" aria-label="user avatar" class="pc-avatar--with-placeholder-initials pc-avatar--sm">
        SC
      </div>
    

        

        <span class="hero-chevron-down-mini pc-dropdown__chevron"></span>
      </div>
    
        

        
      </button>
  """

  defp trigger_button(html) do
    [_, rest] = String.split(html, "<button", parts: 2)
    [button, _] = String.split(rest, "</button>", parts: 2)

    String.replace(
      "<button" <> button <> "</button>",
      ~r/dropdown_[0-9a-f-]{36}/,
      "dropdown_ID"
    )
  end

  describe "variant" do
    test ~s|the default "icon" trigger is byte for byte what it was before variant existed| do
      assigns = %{
        items: [
          %{path: "/profile", icon: "hero-user", label: "Profile"},
          %{path: "/settings", icon: "hero-cog-6-tooth", label: "Settings"}
        ]
      }

      html =
        rendered_to_string(~H"""
        <.user_dropdown_menu current_user_name="Sarah Chen" user_menu_items={@items} />
        """)

      assert trigger_button(html) == String.trim_trailing(@icon_trigger_golden)

      # nothing leaked onto the dropdown container either - the sidebar row
      # widens it, the icon variant must leave it exactly as it found it
      assert html =~ ~s|class="pc-dropdown">|
      refute html =~ "pc-user-menu"

      # and saying the default out loud renders the same trigger
      explicit =
        rendered_to_string(~H"""
        <.user_dropdown_menu variant="icon" current_user_name="Sarah Chen" user_menu_items={@items} />
        """)

      assert trigger_button(explicit) == trigger_button(html)
    end
  end

  describe ~s|variant="sidebar"| do
    setup do
      %{items: [%{path: "/profile", icon: "hero-user", label: "Profile"}]}
    end

    test "renders the full-width row: name over email, up-down chevron on the right", %{
      items: items
    } do
      assigns = %{items: items}

      html =
        rendered_to_string(~H"""
        <.user_dropdown_menu
          variant="sidebar"
          current_user_name="Sarah Chen"
          current_user_email="sarah@acme.com"
          user_menu_items={@items}
        />
        """)

      # the row IS the dropdown's trigger button, and the container has to stop
      # being inline-block before anything inside it can be full width
      assert html =~ "pc-user-menu--sidebar"
      assert html =~ "pc-user-menu__row"

      assert html =~ ~s|<span class="pc-user-menu__name">Sarah Chen</span>|
      assert html =~ ~s|<span class="pc-user-menu__email">sarah@acme.com</span>|

      # up-down rather than down: from the bottom of a sidebar the panel opens
      # either way, and the glyph should not claim otherwise
      assert has_icon?(html, "hero-chevron-up-down")
      refute html =~ "hero-chevron-down-mini"

      # the trigger content renders inside the dropdown's own <button>, so it
      # must not carry an interactive element of its own
      button = trigger_button(html)
      assert count_substring(button, "<button") == 1
      refute button =~ "<a "
    end

    test "the accessible name carries the user's name, not the avatar's stock label", %{
      items: items
    } do
      assigns = %{items: items}

      html =
        rendered_to_string(~H"""
        <.user_dropdown_menu
          variant="sidebar"
          current_user_name="Sarah Chen"
          current_user_email="sarah@acme.com"
          user_menu_items={@items}
        />
        """)

      # the button's name composes from the sr-only text plus its visible
      # content. The avatar's aria-label is a stock "user avatar" that would
      # sit in front of the real name, so with a name present it steps out.
      assert html =~ ~s|<span class="sr-only">Open options</span>|
      assert trigger_button(html) =~ ~s|aria-hidden="true"|

      # with nobody signed in the avatar is the only label there is, so it stays
      anonymous =
        rendered_to_string(~H"""
        <.user_dropdown_menu variant="sidebar" user_menu_items={@items} />
        """)

      refute trigger_button(anonymous) =~ ~s|aria-hidden="true"|
      assert trigger_button(anonymous) =~ ~s|aria-label="user avatar"|
      refute anonymous =~ "pc-user-menu__name"
    end

    test "the email line renders only when there is an email", %{items: items} do
      assigns = %{items: items}

      html =
        rendered_to_string(~H"""
        <.user_dropdown_menu
          variant="sidebar"
          current_user_name="Sarah Chen"
          user_menu_items={@items}
        />
        """)

      assert html =~ "pc-user-menu__name"
      refute html =~ "pc-user-menu__email"
    end

    test "show_chevron={false} drops the up-down chevron", %{items: items} do
      assigns = %{items: items}

      html =
        rendered_to_string(~H"""
        <.user_dropdown_menu
          variant="sidebar"
          current_user_name="Sarah Chen"
          show_chevron={false}
          user_menu_items={@items}
        />
        """)

      refute html =~ "hero-chevron-up-down"
      assert html =~ "pc-user-menu__row"
    end

    test "placement still passes through - the sidebar-bottom row opens rightward", %{
      items: items
    } do
      assigns = %{items: items}

      html =
        rendered_to_string(~H"""
        <.user_dropdown_menu
          variant="sidebar"
          current_user_name="Sarah Chen"
          current_user_email="sarah@acme.com"
          placement="right"
          user_menu_items={@items}
        />
        """)

      assert html =~ "pc-dropdown__menu-items-wrapper-placement--right"
      refute html =~ "pc-dropdown__menu-items-wrapper-placement--left"

      # and the flip hook is still on the panel, so the same row at the bottom
      # of a real sidebar opens up as well as right
      assert html =~ ~s|phx-hook="PetalDropdown"|
    end
  end

  describe "a panel of your own" do
    test "the inner block renders in place of the generated items" do
      assigns = %{items: [%{path: "/profile", icon: "hero-user", label: "Profile"}]}

      html =
        rendered_to_string(~H"""
        <.user_dropdown_menu current_user_name="Sarah Chen" user_menu_items={@items}>
          <.dropdown_menu_label>Organizations</.dropdown_menu_label>
          <.dropdown_menu_item link_type="button">Acme Inc</.dropdown_menu_item>
        </.user_dropdown_menu>
        """)

      assert html =~ "Organizations"
      assert html =~ "Acme Inc"
      # The two are alternatives, not layers: a panel passed in wholesale
      # replaces the list rather than stacking on top of it.
      refute html =~ "/profile"
    end

    test "the trigger is untouched by it - the sidebar row still renders" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.user_dropdown_menu
          variant="sidebar"
          current_user_name="Sarah Chen"
          current_user_email="sarah@acme.com"
          direction="up"
        >
          <.dropdown_menu_item link_type="button">Acme Inc</.dropdown_menu_item>
        </.user_dropdown_menu>
        """)

      assert html =~ "pc-user-menu__row"
      assert html =~ "Sarah Chen"
      assert html =~ "sarah@acme.com"
      assert has_icon?(html, "hero-chevron-up-down")
      assert html =~ "data-flip"
    end

    test "no items and no inner block renders nothing at all" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.user_dropdown_menu current_user_name="Sarah Chen" />
        """)

      refute html =~ "pc-dropdown"
    end
  end
end
