defmodule PetalComponents.Showcase.UserDropdownMenu do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.UserDropdownMenu,
    title: "User menu"

  example :menu, "The app-shell user menu",
    description:
      "The avatar trigger and menu items from plain maps - path, icon and label, plus an optional method (:delete for sign-out routes). A name alone renders deterministic initials, avatar_src adds the photo, and with neither the trigger falls back to the placeholder avatar - the anonymous state. show_chevron={false} is the leaner chevron-less look the big app shells run." do
    ~H"""
    <div class="flex items-start justify-center gap-16">
      <.user_dropdown_menu
        current_user_name="Sarah Chen"
        user_menu_items={[
          %{path: "#", icon: "hero-user", label: "Profile"},
          %{path: "#", icon: "hero-cog-6-tooth", label: "Settings"},
          %{path: "#", icon: "hero-arrow-right-start-on-rectangle", label: "Sign out"}
        ]}
      />
      <.user_dropdown_menu
        current_user_name="Sarah Chen"
        show_chevron={false}
        user_menu_items={[
          %{path: "#", icon: "hero-user", label: "Profile"},
          %{path: "#", icon: "hero-arrow-right-start-on-rectangle", label: "Sign out"}
        ]}
      />
      <.user_dropdown_menu user_menu_items={[
        %{path: "#", icon: "hero-arrow-left-end-on-rectangle", label: "Sign in"}
      ]} />
    </div>
    """
  end

  example :placement, "Pointing it into the app",
    description:
      "This menu's usual home is an avatar at the bottom of a sidebar, hard against the left edge of the screen. The default placement=\"left\" hangs the panel leftward, which there means off-screen. placement=\"right\" grows it into the app instead, and because the dropdown flips upward when the window leaves no room below, a menu in that corner opens up and to the right." do
    ~H"""
    <div class="flex justify-center py-4">
      <.user_dropdown_menu
        current_user_name="Sarah Chen"
        placement="right"
        user_menu_items={[
          %{path: "#", icon: "hero-user", label: "Profile"},
          %{path: "#", icon: "hero-arrow-right-start-on-rectangle", label: "Sign out"}
        ]}
      />
    </div>
    """
  end
end
