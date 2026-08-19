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
      "align says which edges line up, which for a panel below the trigger decides which way it grows. This menu's usual home is an avatar at the bottom of a sidebar, hard against the left edge of the screen, and the default aligns the right edges (align=\"end\"), growing the panel leftward, which there means off-screen. align=\"start\" aligns the left edges and grows it rightward into the app instead, and because the dropdown flips upward when the window leaves no room below, a menu in that corner opens up and to the right. placement=\"left\" and placement=\"right\" are the older spelling of the same two values and still work." do
    ~H"""
    <div class="flex justify-center py-4">
      <.user_dropdown_menu
        current_user_name="Sarah Chen"
        align="start"
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
      "variant=\"sidebar\" trades the compact trigger for the full-width row every sidebar ends up with: avatar, name over email, and a chevron-up-down on the right that admits the panel can open either way. Reach for it when the menu has a whole sidebar width to itself and the name is worth showing at rest. Stay on the default \"icon\" variant in a top bar, where horizontal room is the scarce thing and the avatar alone says enough. current_user_email is optional - leave it out and the row is a single line. align=\"start\" because a sidebar sits against the left edge of the screen and that grows the panel rightward, into the app; the row is as wide as its container, so give it a real one." do
    ~H"""
    <div class="flex justify-center py-4">
      <div class="w-64 p-2 border border-gray-200 rounded-xl dark:border-gray-800">
        <.user_dropdown_menu
          variant="sidebar"
          current_user_name="Sarah Chen"
          current_user_email="sarah@acme.com"
          align="start"
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
      "The sidebar row is only the trigger. Hand the menu its own content instead of a user_menu_items list and it stops being a list of links: an org switcher with avatars and a check on the one you are already in, a labelled account group, keyboard hints, a theme row. Every piece in there ships with the library - dropdown_menu_label, dropdown_menu_item, dropdown_menu_separator, dropdown_menu_row for the switcher, .pc-kbd for the shortcuts. side=\"top\" says out loud what a menu at the bottom of a sidebar already knows, so nothing gets measured and no first frame points the wrong way, and align=\"start\" lines the panel's left edge up with the row so it grows into the app. menu_items_wrapper_class pins the panel to the sidebar's width so it holds still as the rows change." do
    ~H"""
    <div class="flex justify-center pt-96 pb-4">
      <div class="w-64 p-2 border border-gray-200 rounded-xl dark:border-gray-800">
        <.user_dropdown_menu
          variant="sidebar"
          current_user_name="Sarah Chen"
          current_user_email="sarah@acme.com"
          side="top"
          align="start"
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

  example :beside, "Out beside the sidebar",
    description:
      "The same panel, pushed sideways: side=\"right\" opens it past the sidebar rather than up over the nav it came from, and align=\"end\" lines its bottom edge up with the row that opened it. Beside wins when the sidebar is the busy half - a full nav tree that a panel opening upward would bury - or when the sidebar is an icon rail too narrow to host a panel at all. Stay on side=\"top\" when there is empty sidebar above the row and the content area is what you would rather not cover. Nothing is measured either way: an explicit side is a decision, so a panel that would run off a short viewport is yours to move." do
    ~H"""
    <div class="flex justify-center py-4">
      <div class="flex w-[460px] max-w-full border border-gray-200 h-72 rounded-xl dark:border-gray-800">
        <div class="flex flex-col flex-none p-2 border-r w-52 border-gray-200 dark:border-gray-800">
          <div class="px-2 py-1 text-sm font-semibold">Acme Inc</div>
          <div class="mt-2 space-y-0.5">
            <div class="flex items-center gap-2 px-2 py-1.5 text-sm text-gray-500 dark:text-gray-400">
              <.icon name="hero-home" class="w-4 h-4 text-gray-400 dark:text-gray-500" /> Dashboard
            </div>
            <div class="flex items-center gap-2 px-2 py-1.5 text-sm text-gray-500 dark:text-gray-400">
              <.icon name="hero-users" class="w-4 h-4 text-gray-400 dark:text-gray-500" /> Customers
            </div>
            <div class="flex items-center gap-2 px-2 py-1.5 text-sm text-gray-500 dark:text-gray-400">
              <.icon name="hero-banknotes" class="w-4 h-4 text-gray-400 dark:text-gray-500" /> Billing
            </div>
          </div>
          <div class="mt-auto">
            <.user_dropdown_menu
              variant="sidebar"
              current_user_name="Sarah Chen"
              current_user_email="sarah@acme.com"
              side="right"
              align="end"
              menu_items_wrapper_class="w-56"
            >
              <.dropdown_menu_label>Organizations</.dropdown_menu_label>
              <.dropdown_menu_item link_type="button">
                <.avatar name="Acme Inc" size="2xs" random_color /> Acme Inc
                <.icon name="hero-check" class="w-4 h-4 ml-auto" />
              </.dropdown_menu_item>
              <.dropdown_menu_item link_type="button">
                <.avatar name="Northwind" size="2xs" random_color /> Northwind
              </.dropdown_menu_item>
              <.dropdown_menu_separator />
              <.dropdown_menu_item link_type="button">
                <.icon name="hero-user" class="w-4 h-4" /> Profile
              </.dropdown_menu_item>
              <.dropdown_menu_item link_type="button" class="text-danger-600 dark:text-danger-400">
                <.icon name="hero-arrow-right-start-on-rectangle" class="w-4 h-4" /> Sign out
              </.dropdown_menu_item>
            </.user_dropdown_menu>
          </div>
        </div>
        <%!-- No overflow-hidden on the shell: a panel that opens sideways is
        the one thing a clipping container would silently eat. --%>
        <div class="flex-1 p-4 space-y-3">
          <div class="w-32 h-3 rounded bg-gray-100 dark:bg-gray-900"></div>
          <div class="w-full h-20 rounded-lg bg-gray-50 dark:bg-gray-900/50"></div>
          <div class="w-full h-20 rounded-lg bg-gray-50 dark:bg-gray-900/50"></div>
        </div>
      </div>
    </div>
    """
  end
end
