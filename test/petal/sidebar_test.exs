defmodule PetalComponents.SidebarTest do
  use ComponentCase

  import PetalComponents.Sidebar

  defp query(html, selector) do
    html |> LazyHTML.from_fragment() |> LazyHTML.query(selector)
  end

  defp attr_of(html, selector, attribute) do
    html |> query(selector) |> LazyHTML.attribute(attribute) |> List.first()
  end

  describe "sidebar_shell/1" do
    test "wraps the sidebar slot beside an inert-able main region" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_shell for="sb">
          <:sidebar><span>the rail</span></:sidebar>
          <p>page content</p>
        </.sidebar_shell>
        """)

      assert html =~ "pc-sidebar-shell"
      assert html =~ "the rail"
      assert html =~ "page content"
      # The trigger targets this id to toggle inert while the sheet is open.
      assert attr_of(html, ".pc-sidebar-shell__main", "id") == "sb-main"
    end

    test "class is appended, not replaced, so consumer utilities win" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_shell for="sb" class="h-96" data-testid="shell">
          <:sidebar>rail</:sidebar>
          main
        </.sidebar_shell>
        """)

      classes = attr_of(html, "div.pc-sidebar-shell", "class")
      assert classes =~ "pc-sidebar-shell"
      assert classes =~ "h-96"
      assert html =~ ~s(data-testid="shell")
    end
  end

  describe "sidebar/1" do
    test "renders a nav landmark with an accessible name" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar id="sb" label="Primary">
          <span>items</span>
        </.sidebar>
        """)

      assert attr_of(html, "nav.pc-sidebar__nav", "aria-label") == "Primary"
    end

    test "label defaults to Sidebar" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar id="sb">items</.sidebar>
        """)

      assert attr_of(html, "nav.pc-sidebar__nav", "aria-label") == "Sidebar"
    end

    test "state rides on data attributes with sane defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar id="sb">items</.sidebar>
        """)

      assert attr_of(html, "#sb", "data-side") == "left"
      assert attr_of(html, "#sb", "data-collapsible") == "icon"
      assert attr_of(html, "#sb", "data-collapsed") == "false"
      assert attr_of(html, "#sb", "data-mobile-open") == "false"
    end

    test "collapsed is rendered server-side, so the first paint is already the rail" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar id="sb" collapsed>items</.sidebar>
        """)

      assert attr_of(html, "#sb", "data-collapsed") == "true"
    end

    for mode <- ~w(icon offcanvas none) do
      test "collapsible=#{mode} is emitted as a data attribute" do
        assigns = %{mode: unquote(mode)}

        html =
          rendered_to_string(~H"""
          <.sidebar id="sb" collapsible={@mode}>items</.sidebar>
          """)

        assert attr_of(html, "#sb", "data-collapsible") == unquote(mode)
      end
    end

    for side <- ~w(left right) do
      test "side=#{side} is emitted as a data attribute" do
        assigns = %{side: unquote(side)}

        html =
          rendered_to_string(~H"""
          <.sidebar id="sb" side={@side}>items</.sidebar>
          """)

        assert attr_of(html, "#sb", "data-side") == unquote(side)
      end
    end

    test "header and footer slots render only when given" do
      assigns = %{}

      bare =
        rendered_to_string(~H"""
        <.sidebar id="sb">body</.sidebar>
        """)

      refute bare =~ "pc-sidebar__header"
      refute bare =~ "pc-sidebar__footer"
      assert bare =~ "body"

      full =
        rendered_to_string(~H"""
        <.sidebar id="sb">
          <:header>brand</:header>
          body
          <:footer>user menu</:footer>
        </.sidebar>
        """)

      assert full =~ "pc-sidebar__header"
      assert full =~ "brand"
      assert full =~ "pc-sidebar__footer"
      assert full =~ "user menu"
    end

    test "the mobile sheet is fenced, escapable and dismissable by scrim" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar id="sb">items</.sidebar>
        """)

      # focus containment: LiveView's focus_wrap around the panel
      assert attr_of(html, ".pc-sidebar__panel", "phx-hook") == "Phoenix.FocusWrap"
      assert attr_of(html, ".pc-sidebar__panel", "id") == "sb-panel"

      # Escape closes, but only while the sheet is actually open - the exec
      # selector is gated on data-mobile-open so Escape on desktop is a no-op.
      assert attr_of(html, "#sb", "phx-key") == "escape"
      keydown = attr_of(html, "#sb", "phx-window-keydown")
      assert keydown =~ "exec"
      assert keydown =~ "data-close"
      assert keydown =~ ~s(sb[data-mobile-open=)

      # scrim click closes
      assert query(html, ".pc-sidebar__scrim") |> Enum.count() == 1
      assert attr_of(html, ".pc-sidebar__scrim", "aria-hidden") == "true"
      assert attr_of(html, ".pc-sidebar__scrim", "phx-click") =~ "data-close"
    end

    test "the close command clears inert, unlocks scroll and restores focus to the trigger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar id="sb">items</.sidebar>
        """)

      close = attr_of(html, "#sb", "data-close")

      assert close =~ ~s(data-mobile-open)
      assert close =~ "remove_attr"
      assert close =~ "inert"
      assert close =~ "sb-main"
      assert close =~ "overflow-hidden"
      assert close =~ "focus"
      assert close =~ "sb-trigger"
    end

    test "on_close JS is composed ahead of the component's own commands" do
      assigns = %{js: Phoenix.LiveView.JS.push("sidebar_closed")}

      html =
        rendered_to_string(~H"""
        <.sidebar id="sb" on_close={@js}>items</.sidebar>
        """)

      assert attr_of(html, "#sb", "data-close") =~ "sidebar_closed"
    end

    test "two sidebars in one page do not cross-wire" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <div>
          <.sidebar id="left-sb">a</.sidebar>
          <.sidebar id="right-sb" side="right">b</.sidebar>
        </div>
        """)

      assert attr_of(html, "#left-sb", "data-close") =~ "left-sb-main"
      refute attr_of(html, "#left-sb", "data-close") =~ "right-sb"
      assert attr_of(html, "#right-sb", "data-close") =~ "right-sb-main"
      refute attr_of(html, "#right-sb", "data-close") =~ "left-sb-main"
    end

    test "class and global attrs pass through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar id="sb" class="w-72" data-testid="sb">items</.sidebar>
        """)

      assert attr_of(html, "#sb", "class") =~ "pc-sidebar"
      assert attr_of(html, "#sb", "class") =~ "w-72"
      assert attr_of(html, "#sb", "data-testid") == "sb"
    end
  end

  describe "sidebar_group/1" do
    test "renders a plain label when not collapsible" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_group label="Workspace">items</.sidebar_group>
        """)

      assert html =~ "Workspace"
      assert query(html, "button.pc-sidebar-group__toggle") |> Enum.empty?()
      assert query(html, "div.pc-sidebar-group__label") |> Enum.count() == 1
    end

    test "an unlabelled group renders no heading at all" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_group>items</.sidebar_group>
        """)

      refute html =~ "pc-sidebar-group__label"
      assert html =~ "items"
    end

    test "collapsible groups follow the disclosure pattern" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_group id="grp" label="Account" collapsible>items</.sidebar_group>
        """)

      assert attr_of(html, "button.pc-sidebar-group__toggle", "aria-expanded") == "true"
      assert attr_of(html, "button.pc-sidebar-group__toggle", "aria-controls") == "grp-items"
      assert attr_of(html, "#grp-items", "data-open") == "true"
    end

    test "open={false} renders a closed disclosure" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_group id="grp" label="Account" collapsible open={false}>items</.sidebar_group>
        """)

      assert attr_of(html, "button.pc-sidebar-group__toggle", "aria-expanded") == "false"
      assert attr_of(html, "#grp-items", "data-open") == "false"
    end

    test "the toggle flips aria-expanded and the panel together" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_group id="grp" label="Account" collapsible>items</.sidebar_group>
        """)

      click = attr_of(html, "button.pc-sidebar-group__toggle", "phx-click")
      assert click =~ "aria-expanded"
      assert click =~ "grp-items"
      # CSS-first: a JS attribute flip, no hook.
      refute click =~ "phx-hook"
    end

    test "on_toggle JS is composed in" do
      assigns = %{js: Phoenix.LiveView.JS.push("group_toggled")}

      html =
        rendered_to_string(~H"""
        <.sidebar_group id="grp" label="Account" collapsible on_toggle={@js}>items</.sidebar_group>
        """)

      assert attr_of(html, "button.pc-sidebar-group__toggle", "phx-click") =~ "group_toggled"
    end

    test "id falls back to a slug of the label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_group label="Account" collapsible>items</.sidebar_group>
        """)

      assert attr_of(html, "button.pc-sidebar-group__toggle", "aria-controls") =~
               "pc-sidebar-group-account"
    end

    test "class and global attrs pass through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_group label="A" class="mt-6" data-testid="grp">items</.sidebar_group>
        """)

      assert attr_of(html, ".pc-sidebar-group", "class") =~ "mt-6"
      assert attr_of(html, ".pc-sidebar-group", "data-testid") == "grp"
    end
  end

  describe "sidebar_item/1" do
    test "renders a link with its label kept for screen readers" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_item label="Dashboard" path="/dash" />
        """)

      assert attr_of(html, "a.pc-sidebar-item", "href") == "/dash"
      assert html =~ "Dashboard"
      # the collapsed rail hides the label visually, so title carries it on hover
      assert attr_of(html, "a.pc-sidebar-item", "title") == "Dashboard"
    end

    test "the active item is marked with aria-current=page" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_item label="Dashboard" path="/dash" active />
        """)

      assert attr_of(html, "a.pc-sidebar-item", "aria-current") == "page"
      assert attr_of(html, "a.pc-sidebar-item", "class") =~ "pc-sidebar-item--active"
    end

    test "an inactive item emits no aria-current" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_item label="Dashboard" path="/dash" />
        """)

      assert attr_of(html, "a.pc-sidebar-item", "aria-current") == nil
      refute html =~ "pc-sidebar-item--active"
    end

    test "renders a heroicon by name" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_item label="Home" path="/" icon="hero-home" />
        """)

      assert has_icon?(html)
      assert html =~ "pc-sidebar-item__icon"
    end

    test "renders a function component icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_item label="Home" path="/" icon={&custom_icon/1} />
        """)

      assert html =~ "custom-icon-svg"
      assert html =~ "pc-sidebar-item__icon"
    end

    test "renders a raw svg string icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_item label="Home" path="/" icon="<svg id='raw-icon'></svg>" />
        """)

      assert html =~ "raw-icon"
    end

    test "no icon renders no icon element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_item label="Home" path="/" />
        """)

      refute html =~ "pc-sidebar-item__icon"
    end

    test "a badge renders trailing text" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_item label="Inbox" path="/inbox" badge="12" />
        """)

      assert query(html, ".pc-sidebar-item__badge") |> LazyHTML.text() == "12"
    end

    test "no badge renders no badge element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_item label="Inbox" path="/inbox" />
        """)

      refute html =~ "pc-sidebar-item__badge"
    end

    test "link_type=live_redirect (the default) navigates" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_item label="Home" path="/" />
        """)

      assert attr_of(html, "a.pc-sidebar-item", "data-phx-link") == "redirect"
    end

    test "link_type=live_patch patches" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_item label="Home" path="/" link_type="live_patch" />
        """)

      assert attr_of(html, "a.pc-sidebar-item", "data-phx-link") == "patch"
    end

    test "link_type=a renders a plain anchor" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_item label="Home" path="/" link_type="a" />
        """)

      assert attr_of(html, "a.pc-sidebar-item", "href") == "/"
      assert attr_of(html, "a.pc-sidebar-item", "data-phx-link") == nil
    end

    test "link_type=button renders a button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_item label="Sign out" link_type="button" phx-click="sign_out" />
        """)

      assert query(html, "button.pc-sidebar-item") |> Enum.count() == 1
      assert html =~ ~s(phx-click="sign_out")
    end

    test "nested sub-items turn the item into a disclosure" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_item id="settings" label="Settings" icon="hero-cog-6-tooth">
          <.sidebar_item label="Profile" path="/profile" />
          <.sidebar_item label="Billing" path="/billing" />
        </.sidebar_item>
        """)

      assert attr_of(html, "button.pc-sidebar-item", "aria-expanded") == "false"
      assert attr_of(html, "button.pc-sidebar-item", "aria-controls") == "settings-sub"
      assert attr_of(html, "#settings-sub", "data-open") == "false"
      assert attr_of(html, "#settings-sub", "class") =~ "pc-sidebar-item__sub"

      # the children are ordinary items
      assert query(html, "#settings-sub a.pc-sidebar-item") |> Enum.count() == 2
      assert html =~ "Profile"
      assert html =~ "Billing"
    end

    test "an open sub-menu renders expanded" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_item id="settings" label="Settings" open>
          <.sidebar_item label="Profile" path="/profile" active />
        </.sidebar_item>
        """)

      assert attr_of(html, "button.pc-sidebar-item", "aria-expanded") == "true"
      assert attr_of(html, "#settings-sub", "data-open") == "true"
      # a nested item still carries aria-current
      assert attr_of(html, "#settings-sub a.pc-sidebar-item", "aria-current") == "page"
    end

    test "a parent item can be active and badged too" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_item id="settings" label="Settings" active badge="3">
          <.sidebar_item label="Profile" path="/profile" />
        </.sidebar_item>
        """)

      assert attr_of(html, "button.pc-sidebar-item", "class") =~ "pc-sidebar-item--active"
      assert query(html, ".pc-sidebar-item__badge") |> LazyHTML.text() == "3"
    end

    test "the sub-menu toggle is a JS attribute flip, not a hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_item id="settings" label="Settings">
          <.sidebar_item label="Profile" path="/profile" />
        </.sidebar_item>
        """)

      click = attr_of(html, "button.pc-sidebar-item", "phx-click")
      assert click =~ "aria-expanded"
      assert click =~ "settings-sub"
      refute html =~ "phx-hook"
    end

    test "on_toggle JS is composed into the sub-menu toggle" do
      assigns = %{js: Phoenix.LiveView.JS.push("submenu_toggled")}

      html =
        rendered_to_string(~H"""
        <.sidebar_item id="settings" label="Settings" on_toggle={@js}>
          <.sidebar_item label="Profile" path="/profile" />
        </.sidebar_item>
        """)

      assert attr_of(html, "button.pc-sidebar-item", "phx-click") =~ "submenu_toggled"
    end

    test "class and global attrs pass through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_item label="Home" path="/" class="font-bold" data-testid="item" />
        """)

      assert attr_of(html, "a.pc-sidebar-item", "class") =~ "font-bold"
      assert attr_of(html, "a.pc-sidebar-item", "data-testid") == "item"
    end
  end

  describe "sidebar_trigger/1" do
    test "targets the sidebar it names" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_trigger for="sb" />
        """)

      assert attr_of(html, "button.pc-sidebar-trigger", "aria-controls") == "sb"
      assert attr_of(html, "button.pc-sidebar-trigger", "aria-label") == "Toggle sidebar"
    end

    test "only the mobile trigger claims the derived focus-restore id" do
      assigns = %{}

      # A shell commonly carries both a burger and a rail toggle for the same
      # sidebar. Only one element may hold the id focus returns to.
      html =
        rendered_to_string(~H"""
        <div>
          <.sidebar_trigger for="sb" target="mobile" />
          <.sidebar_trigger for="sb" />
        </div>
        """)

      assert query(html, "#sb-trigger") |> Enum.count() == 1

      assert attr_of(html, ".pc-sidebar-trigger--mobile", "id") == "sb-trigger"
      assert attr_of(html, ".pc-sidebar-trigger--collapse", "id") == nil
    end

    test "the collapse target flips data-collapsed on its sidebar only" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_trigger for="sb" />
        """)

      click = attr_of(html, "button.pc-sidebar-trigger", "phx-click")
      assert click =~ "data-collapsed"
      assert click =~ "#sb"
      assert attr_of(html, "button.pc-sidebar-trigger", "class") =~ "pc-sidebar-trigger--collapse"
    end

    test "the mobile target opens the sheet, marks the shell inert and moves focus in" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_trigger for="sb" target="mobile" />
        """)

      click = attr_of(html, "button.pc-sidebar-trigger", "phx-click")
      assert click =~ "data-mobile-open"
      assert click =~ "inert"
      assert click =~ "sb-main"
      assert click =~ "overflow-hidden"
      assert click =~ "focus"
      assert attr_of(html, "button.pc-sidebar-trigger", "class") =~ "pc-sidebar-trigger--mobile"
      # it is a disclosure for the sheet, so it reports state
      assert attr_of(html, "button.pc-sidebar-trigger", "aria-expanded") == "false"
    end

    test "the collapse trigger is not a sheet disclosure" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_trigger for="sb" />
        """)

      assert attr_of(html, "button.pc-sidebar-trigger", "aria-expanded") == nil
    end

    test "triggers for different sidebars do not cross-wire" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <div>
          <.sidebar_trigger for="left-sb" target="mobile" />
          <.sidebar_trigger for="right-sb" target="mobile" />
        </div>
        """)

      left = attr_of(html, "#left-sb-trigger", "phx-click")
      right = attr_of(html, "#right-sb-trigger", "phx-click")

      assert left =~ "left-sb"
      refute left =~ "right-sb"
      assert right =~ "right-sb"
      refute right =~ "left-sb"
    end

    test "an explicit id wins over the derived one" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_trigger for="sb" id="my-trigger" />
        """)

      assert attr_of(html, "button.pc-sidebar-trigger", "id") == "my-trigger"
    end

    test "a custom label names the button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_trigger for="sb" label="Hide navigation" />
        """)

      assert attr_of(html, "button.pc-sidebar-trigger", "aria-label") == "Hide navigation"
    end

    test "renders a default icon, or the inner block when given" do
      assigns = %{}

      default =
        rendered_to_string(~H"""
        <.sidebar_trigger for="sb" />
        """)

      assert has_icon?(default)

      custom =
        rendered_to_string(~H"""
        <.sidebar_trigger for="sb">Menu</.sidebar_trigger>
        """)

      assert custom =~ "Menu"
      refute has_icon?(custom)
    end

    test "on_click JS is composed ahead of the component's own commands" do
      assigns = %{js: Phoenix.LiveView.JS.push("toggle_sidebar")}

      html =
        rendered_to_string(~H"""
        <.sidebar_trigger for="sb" on_click={@js} />
        """)

      assert attr_of(html, "button.pc-sidebar-trigger", "phx-click") =~ "toggle_sidebar"
    end

    test "class and global attrs pass through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_trigger for="sb" class="ml-auto" data-testid="trig" />
        """)

      assert attr_of(html, "button.pc-sidebar-trigger", "class") =~ "ml-auto"
      assert attr_of(html, "button.pc-sidebar-trigger", "data-testid") == "trig"
    end
  end

  describe "JS command helpers" do
    test "toggle_sidebar/1 flips only the collapsed attribute" do
      js = toggle_sidebar("sb") |> Jason.encode!()

      assert js =~ "toggle_attr"
      assert js =~ "data-collapsed"
      assert js =~ "#sb"
      refute js =~ "data-mobile-open"
    end

    test "show_sidebar/1 opens the sheet and fences the shell" do
      js = show_sidebar("sb") |> Jason.encode!()

      assert js =~ ~s(data-mobile-open)
      assert js =~ "inert"
      assert js =~ "#sb-main"
      assert js =~ "overflow-hidden"
      assert js =~ "focus_first"
    end

    test "hide_sidebar/1 unwinds all of it and restores focus" do
      js = hide_sidebar("sb") |> Jason.encode!()

      assert js =~ "remove_attr"
      assert js =~ "inert"
      assert js =~ "#sb-trigger"
      assert js =~ "remove_class"
    end
  end

  describe "composition" do
    test "a full app shell renders one nav, one main and the whole item tree" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_shell for="app">
          <:sidebar>
            <.sidebar id="app" label="Main">
              <:header>Acme</:header>
              <.sidebar_group label="Workspace">
                <.sidebar_item label="Dashboard" path="/" icon="hero-home" active />
                <.sidebar_item label="Inbox" path="/inbox" icon="hero-inbox" badge="12" />
              </.sidebar_group>
              <.sidebar_group id="acct" label="Account" collapsible>
                <.sidebar_item id="set" label="Settings" open>
                  <.sidebar_item label="Profile" path="/profile" />
                </.sidebar_item>
              </.sidebar_group>
              <:footer>
                <.sidebar_item label="Sign out" path="/out" />
              </:footer>
            </.sidebar>
          </:sidebar>
          <.sidebar_trigger for="app" target="mobile" />
          <main>page</main>
        </.sidebar_shell>
        """)

      assert query(html, "nav[aria-label='Main']") |> Enum.count() == 1
      assert query(html, "#app-main") |> Enum.count() == 1
      assert query(html, "[aria-current='page']") |> Enum.count() == 1
      assert query(html, "#acct-items") |> Enum.count() == 1
      assert attr_of(html, "#set-sub", "data-open") == "true"
      assert attr_of(html, "#app-trigger", "aria-controls") == "app"
      assert html =~ "Acme"
      assert html =~ "Sign out"
    end
  end

  describe "the collapsed rail" do
    # The markup is byte for byte the same collapsed or not - the rail is a
    # data attribute and a stylesheet - so default.css is the only place any
    # of this can be pinned.

    @app_root Path.expand("../..", __DIR__)
    @rail ~s(.pc-sidebar[data-collapsible="icon"][data-collapsed="true"])

    setup do
      %{css: File.read!(Path.join(@app_root, "assets/default.css"))}
    end

    test "the header is a centred grid column, not a flex row", %{css: css} do
      body = rule_of(css, "#{@rail} .pc-sidebar__header")

      # Grid rather than a flex column on purpose: the single track is only as
      # wide as the widest child, which leaves an `ml-auto` a caller put on the
      # trigger for the expanded row no free space to shove it into. Resetting
      # that margin from here is not an option - @layer utilities outranks
      # @layer components, so the utility wins whatever this rule says. Swap
      # this back to flex-col and the trigger goes flush right while the logo
      # above it stays centred.
      assert body =~ "grid"
      refute body =~ "flex-col"
      assert body =~ "justify-center", "the track has to be centred on the rail"
      assert body =~ "justify-items-center", "and each row centred inside the track"
    end

    test "the header sheds its one-row height without shrinking below it", %{css: css} do
      body = rule_of(css, "#{@rail} .pc-sidebar__header")

      # h-14 is the height of ONE row; a logo stacked over a trigger needs more.
      assert body =~ "h-auto"
      assert body =~ "py-3"
      # A header holding nothing but a logo should still be exactly as tall as
      # it was expanded, or collapsing the rail jogs the whole nav upward.
      assert body =~ "min-h-14"
    end

    test "the footer centres what the caller cannot", %{css: css} do
      # A plain block gives an inline-level child - a bare trigger, which is
      # what the collapsed-rail example puts down there - nothing for mx-auto
      # to work on, so it sits left of every icon above it.
      body = rule_of(css, "#{@rail} .pc-sidebar__footer")

      assert body =~ "flex"
      assert body =~ "flex-col"
      assert body =~ "items-center"
    end

    test "a sidebar-variant user menu hides its identity the way items hide labels",
         %{css: css} do
      # sr-only, not hidden: the avatar beside it goes aria-hidden whenever
      # there is a name to read, so this text is what names the trigger button.
      assert rule_of(css, "#{@rail} .pc-user-menu__identity") =~ "sr-only"
      assert rule_of(css, "#{@rail} .pc-user-menu__row .pc-dropdown__chevron") =~ "hidden"
    end

    test "the user menu row centres its avatar like any other rail item", %{css: css} do
      assert rule_of(css, "#{@rail} .pc-user-menu__row") =~ "justify-center"
    end

    test "the rail stops clipping, so a panel can open out of it", %{css: css} do
      # 240px of account panel inside a 64px overflow-hidden box is one sliver
      # of panel. The clip holds labels in while the width animates, and by the
      # time the rail is narrow they are already sr-only.
      assert rule_of(css, "#{@rail} .pc-sidebar__panel") =~ "overflow-visible"
    end

    # The body of whichever rule lists `selector` among its selectors, so a
    # selector that shares a rule with its siblings still resolves.
    defp rule_of(css, selector) do
      case Regex.run(~r/#{Regex.escape(selector)}\s*(?:,[^{}]*)?\{([^}]*)\}/s, css) do
        [_, body] -> body
        nil -> flunk("selector not found in default.css: #{selector}")
      end
    end
  end

  defp custom_icon(assigns) do
    ~H"""
    <svg id="custom-icon-svg" class={@class}></svg>
    """
  end
end
