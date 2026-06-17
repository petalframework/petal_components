defmodule PetalComponents.NavigationMenuTest do
  use ComponentCase
  import PetalComponents.NavigationMenu

  describe "navigation_menu/1 - flyout items" do
    test "renders a disclosure trigger wired to its panel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.navigation_menu id="nav">
          <:item label="Products">
            <.navigation_menu_link to="/analytics" title="Analytics" />
          </:item>
        </.navigation_menu>
        """)

      assert html =~ "pc-nav-menu"
      assert html =~ "pc-nav-menu__trigger"
      assert html =~ "Products"
      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(aria-controls="nav-panel-0")
      assert html =~ ~s(id="nav-panel-0")
      assert html =~ "pc-nav-menu__chevron"
      # panel starts hidden and is toggled with LiveView.JS
      assert html =~ "display: none"
      assert html =~ "phx-click"
      assert html =~ "data-pc-nav-panel"
    end

    test "closes on Escape and click-away" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.navigation_menu id="nav">
          <:item label="Products">
            <div>Panel</div>
          </:item>
        </.navigation_menu>
        """)

      assert html =~ "phx-click-away"
      assert html =~ "phx-window-keydown"
      assert html =~ ~s(phx-key="Escape")
    end

    test "panel width defaults to md and accepts variants" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.navigation_menu id="nav">
          <:item label="Default">
            <div>A</div>
          </:item>
          <:item label="Large" width="lg">
            <div>B</div>
          </:item>
        </.navigation_menu>
        """)

      assert html =~ "pc-nav-menu__panel--md"
      assert html =~ "pc-nav-menu__panel--lg"
    end

    test "align=end anchors the panel to the trigger's end edge" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.navigation_menu id="nav">
          <:item label="Start">
            <div>A</div>
          </:item>
          <:item label="End" align="end">
            <div>B</div>
          </:item>
        </.navigation_menu>
        """)

      assert html =~ "pc-nav-menu__panel--end"
      # only the end item gets the modifier
      assert count_substring(html, "pc-nav-menu__panel--end") == 1
    end

    test "full_width renders a mega panel and drops the item's relative positioning" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.navigation_menu id="nav">
          <:item label="Mega" full_width>
            <div>Wide</div>
          </:item>
        </.navigation_menu>
        """)

      assert html =~ "pc-nav-menu__panel--full"
      refute html =~ ~s(class="pc-nav-menu__item relative")
    end

    test "panels get unique sequential ids" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.navigation_menu id="main">
          <:item label="One">
            <div>1</div>
          </:item>
          <:item label="Two">
            <div>2</div>
          </:item>
        </.navigation_menu>
        """)

      assert html =~ ~s(id="main-panel-0")
      assert html =~ ~s(id="main-panel-1")
    end
  end

  describe "navigation_menu/1 - plain link items" do
    test "renders an anchor instead of a trigger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.navigation_menu id="nav">
          <:item label="Pricing" to="/pricing" />
        </.navigation_menu>
        """)

      assert html =~ "pc-nav-menu__link-item"
      assert html =~ ~s(href="/pricing")
      assert html =~ "Pricing"
      # no trigger button or panel is rendered (the class still appears inside
      # the nav's serialized JS commands, so match the element attribute)
      refute html =~ ~s(class="pc-nav-menu__trigger")
      refute html =~ "<button"
      refute html =~ ~s( data-pc-nav-panel)
    end

    test "marks the current item with aria-current" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.navigation_menu id="nav">
          <:item label="Docs" to="/docs" current />
        </.navigation_menu>
        """)

      assert html =~ ~s(aria-current="page")
    end

    test "supports live navigation link types" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.navigation_menu id="nav">
          <:item label="Dashboard" to="/dashboard" link_type="live_redirect" />
        </.navigation_menu>
        """)

      assert html =~ ~s(data-phx-link="redirect")
    end
  end

  describe "navigation_menu_link/1" do
    test "renders icon, title and description" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.navigation_menu_link
          to="/analytics"
          icon="hero-chart-bar"
          title="Analytics"
          description="Understand your traffic"
        />
        """)

      assert html =~ "pc-nav-menu__link"
      assert html =~ "pc-nav-menu__link-icon"
      assert html =~ "Analytics"
      assert html =~ "Understand your traffic"
      assert html =~ ~s(href="/analytics")
      assert has_icon?(html)
    end

    test "omits the icon box and description when not given" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.navigation_menu_link to="/x" title="Bare" />
        """)

      refute html =~ "pc-nav-menu__link-icon"
      refute html =~ "pc-nav-menu__link-description"
      assert html =~ "Bare"
    end

    test "forwards anchor attributes (target, rel, referrerpolicy)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.navigation_menu_link
          to="/x"
          title="External"
          target="_blank"
          rel="noopener"
          referrerpolicy="no-referrer"
        />
        """)

      assert html =~ ~s(target="_blank")
      assert html =~ ~s(rel="noopener")
      assert html =~ ~s(referrerpolicy="no-referrer")
    end
  end

  describe "navigation_menu_footer/1" do
    test "renders the footer strip with footer links" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.navigation_menu_footer>
          <.navigation_menu_footer_link to="/demo" icon="hero-play-circle" label="Watch demo" />
          <.navigation_menu_footer_link to="/contact" label="Contact sales" />
        </.navigation_menu_footer>
        """)

      assert html =~ "pc-nav-menu__footer"
      assert html =~ "pc-nav-menu__footer-link"
      assert html =~ "Watch demo"
      assert html =~ "Contact sales"
      assert html =~ ~s(href="/demo")
      assert has_icon?(html)
    end
  end
end
