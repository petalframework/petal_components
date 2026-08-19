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
      "placement names which way the panel GROWS, not which side it sits on. This menu's usual home is an avatar at the bottom of a sidebar, hard against the left edge of the screen, and the default placement=\"left\" grows the panel leftward (right edges aligned), which there means off-screen. placement=\"right\" grows it rightward into the app instead, and because the dropdown flips upward when the window leaves no room below, a menu in that corner opens up and to the right." do
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

  example :sidebar, "The sidebar block",
    description:
      "variant=\"sidebar\" trades the compact trigger for the full-width row every sidebar ends up with: avatar, name over email, and a chevron-up-down on the right that admits the panel can open either way. Reach for it when the menu has a whole sidebar width to itself and the name is worth showing at rest. Stay on the default \"icon\" variant in a top bar, where horizontal room is the scarce thing and the avatar alone says enough. current_user_email is optional - leave it out and the row is a single line. placement=\"right\" because a sidebar sits against the left edge of the screen and that grows the panel rightward, into the app; the row is as wide as its container, so give it a real one." do
    ~H"""
    <div class="flex justify-center py-4">
      <div class="w-64 p-2 border border-gray-200 rounded-xl dark:border-gray-800">
        <.user_dropdown_menu
          variant="sidebar"
          current_user_name="Sarah Chen"
          current_user_email="sarah@acme.com"
          placement="right"
          user_menu_items={[
            %{path: "#", icon: "hero-user", label: "Profile"},
            %{path: "#", icon: "hero-cog-6-tooth", label: "Settings"},
            %{path: "#", icon: "hero-arrow-right-start-on-rectangle", label: "Sign out"}
          ]}
        />
      </div>
    </div>
    """
  end

  example :account_panel, "The account panel",
    description:
      "The sidebar row is only the trigger. Hand the menu its own content instead of a user_menu_items list and it stops being a list of links: an org switcher with avatars and a check on the one you are already in, a labelled account group, keyboard hints, a theme row. Every piece in there ships with the library - dropdown_menu_label, dropdown_menu_item, dropdown_menu_separator, dropdown_menu_row for the switcher, .pc-kbd for the shortcuts. direction=\"up\" says out loud what a menu at the bottom of a sidebar already knows, so nothing gets measured and no first frame points the wrong way. menu_items_wrapper_class pins the panel to the sidebar's width so it holds still as the rows change." do
    ~H"""
    <div class="flex justify-center pt-96 pb-4">
      <div class="w-64 p-2 border border-gray-200 rounded-xl dark:border-gray-800">
        <.user_dropdown_menu
          variant="sidebar"
          current_user_name="Sarah Chen"
          current_user_email="sarah@acme.com"
          placement="right"
          direction="up"
          menu_items_wrapper_class="w-60"
        >
          <.dropdown_menu_label>Organizations</.dropdown_menu_label>
          <.dropdown_menu_item link_type="button">
            <.avatar name="Acme Inc" size="2xs" random_color /> Acme Inc
            <.icon name="hero-check" class="w-4 h-4 ml-auto" />
          </.dropdown_menu_item>
          <.dropdown_menu_item link_type="button">
            <.avatar name="Northwind" size="2xs" random_color /> Northwind
          </.dropdown_menu_item>
          <.dropdown_menu_item link_type="button">
            <.avatar name="Petal Labs" size="2xs" random_color /> Petal Labs
          </.dropdown_menu_item>
          <.dropdown_menu_item link_type="button">
            <.icon name="hero-plus" class="w-4 h-4" /> New organization
          </.dropdown_menu_item>
          <.dropdown_menu_separator />
          <.dropdown_menu_label>Account</.dropdown_menu_label>
          <.dropdown_menu_item link_type="button">
            <.icon name="hero-user" class="w-4 h-4" /> Profile
            <kbd class="pc-kbd ml-auto"><span>⇧</span><span>⌘</span>P</kbd>
          </.dropdown_menu_item>
          <.dropdown_menu_item link_type="button">
            <.icon name="hero-adjustments-horizontal" class="w-4 h-4" /> Preferences
          </.dropdown_menu_item>
          <.dropdown_menu_row>
            <.icon name="hero-paint-brush" class="w-4 h-4" /> Theme
            <.color_scheme_switch id="account-panel-scheme" variant="segmented" class="ml-auto" />
          </.dropdown_menu_row>
          <.dropdown_menu_separator />
          <.dropdown_menu_item link_type="button" class="text-danger-600 dark:text-danger-400">
            <.icon name="hero-arrow-right-start-on-rectangle" class="w-4 h-4" /> Sign out
            <kbd class="pc-kbd ml-auto"><span>⇧</span><span>⌘</span>Q</kbd>
          </.dropdown_menu_item>
        </.user_dropdown_menu>
      </div>
    </div>
    """
  end
end
