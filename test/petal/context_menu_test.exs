defmodule PetalComponents.ContextMenuTest do
  use ComponentCase

  import PetalComponents.ContextMenu
  import PetalComponents.Icon

  describe "context_menu/1" do
    test "renders the trigger region, the hook wiring and the menu panel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.context_menu id="cm-basic">
          <:trigger>A file card</:trigger>
          <.context_menu_item link_type="button" label="Open" />
        </.context_menu>
        """)

      assert html =~ "A file card"
      assert html =~ "Open"
      assert html =~ "pc-context-menu"
      assert html =~ "pc-context-menu__trigger"
      assert html =~ "pc-context-menu__panel"
      assert html =~ ~s(id="cm-basic")
      assert html =~ ~s(id="cm-basic-trigger")
      assert html =~ ~s(id="cm-basic-menu")
      assert html =~ ~s(phx-hook="PetalContextMenu")
      assert html =~ ~s(data-pc-context-menu-panel="cm-basic-menu")
    end

    test "generates an id when none is given" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.context_menu>
          <:trigger>Region</:trigger>
          <.context_menu_item link_type="button" label="Open" />
        </.context_menu>
        """)

      assert html =~ "id=\"context_menu_"
      assert html =~ "-trigger\""
      assert html =~ "-menu\""
      assert html =~ ~s(phx-hook="PetalContextMenu")
    end

    test "the panel carries the WAI-ARIA menu roles and is not visible at rest" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.context_menu id="cm-aria">
          <:trigger>Region</:trigger>
          <.context_menu_item link_type="button" label="Open" />
        </.context_menu>
        """)

      panel =
        html
        |> parse_html()
        |> LazyHTML.query("#cm-aria-menu")

      assert LazyHTML.attribute(panel, "role") == ["menu"]
      assert LazyHTML.attribute(panel, "aria-orientation") == ["vertical"]
      # popover keeps it out of the flow until the hook shows it
      assert LazyHTML.attribute(panel, "popover") == ["manual"]
      # focusable programmatically so a pointer-opened menu has somewhere to land
      assert LazyHTML.attribute(panel, "tabindex") == ["-1"]
    end

    test "the trigger region is a focus stop wired to the panel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.context_menu id="cm-trigger">
          <:trigger>Region</:trigger>
          <.context_menu_item link_type="button" label="Open" />
        </.context_menu>
        """)

      trigger =
        html
        |> parse_html()
        |> LazyHTML.query("#cm-trigger-trigger")

      assert LazyHTML.attribute(trigger, "tabindex") == ["0"]
      assert LazyHTML.attribute(trigger, "aria-haspopup") == ["menu"]
      assert LazyHTML.attribute(trigger, "aria-expanded") == ["false"]
      assert LazyHTML.attribute(trigger, "aria-controls") == ["cm-trigger-menu"]
    end

    test "disabled drops the hook so the browser's own menu comes through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.context_menu id="cm-off" disabled>
          <:trigger>Region</:trigger>
          <.context_menu_item link_type="button" label="Open" />
        </.context_menu>
        """)

      refute html =~ "PetalContextMenu"
      refute html =~ "phx-hook"
      # the markup is otherwise unchanged, so toggling disabled is not a re-layout
      assert html =~ ~s(id="cm-off-menu")
      assert html =~ ~s(role="menu")
    end

    test "class, menu_class and rest pass through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.context_menu
          id="cm-pass"
          class="my-region"
          menu_class="my-panel"
          data-testid="cm"
          aria-label="File actions"
        >
          <:trigger>Region</:trigger>
          <.context_menu_item link_type="button" label="Open" />
        </.context_menu>
        """)

      doc = parse_html(html)

      assert doc |> LazyHTML.query("#cm-pass-trigger") |> LazyHTML.attribute("class") == [
               "pc-context-menu__trigger my-region"
             ]

      assert doc |> LazyHTML.query("#cm-pass-menu") |> LazyHTML.attribute("class") == [
               "pc-context-menu__panel my-panel"
             ]

      assert html =~ ~s(data-testid="cm")
      assert html =~ ~s(aria-label="File actions")
    end
  end

  describe "context_menu_item/1" do
    test "renders a menuitem off the tab order by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.context_menu_item link_type="button" label="Rename" />
        """)

      item = html |> parse_html() |> LazyHTML.query("[data-pc-context-menu-item]")

      assert LazyHTML.attribute(item, "role") == ["menuitem"]
      # roving tabindex: the hook moves real focus, the items stay off Tab
      assert LazyHTML.attribute(item, "tabindex") == ["-1"]
      assert html =~ "pc-context-menu__item"
      assert html =~ "Rename"
      assert html =~ "<button"
    end

    test "the inner block wins over label, and takes an icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.context_menu_item link_type="button" label="Ignored">
          <.icon name="hero-trash" class="w-4 h-4" /> Delete
        </.context_menu_item>
        """)

      assert html =~ "Delete"
      refute html =~ "Ignored"
      assert has_icon?(html)
    end

    test "each link_type renders the right element" do
      assigns = %{}

      button =
        rendered_to_string(~H"""
        <.context_menu_item link_type="button" label="Open" />
        """)

      anchor =
        rendered_to_string(~H"""
        <.context_menu_item link_type="a" to="/files" label="Open" />
        """)

      patch =
        rendered_to_string(~H"""
        <.context_menu_item link_type="live_patch" to="/files" label="Open" />
        """)

      redirect =
        rendered_to_string(~H"""
        <.context_menu_item link_type="live_redirect" to="/files" label="Open" />
        """)

      assert button =~ "<button"
      assert anchor =~ ~s(href="/files")
      refute anchor =~ "data-phx-link"
      assert patch =~ ~s(data-phx-link="patch")
      assert redirect =~ ~s(data-phx-link="redirect")
    end

    test "disabled marks the item up for both the hook and assistive tech" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.context_menu_item link_type="a" to="/files" disabled label="Move" />
        """)

      item = html |> parse_html() |> LazyHTML.query("[data-pc-context-menu-item]")

      assert LazyHTML.attribute(item, "aria-disabled") == ["true"]
      assert html =~ "pc-context-menu__item--disabled"
      # an <a> can't be disabled, so Link.a turns it into a real disabled button
      assert html =~ "<button"
      assert html =~ " disabled"
      refute html =~ ~s(href="/files")
    end

    test "variant=danger emits the destructive treatment" do
      assigns = %{}

      danger =
        rendered_to_string(~H"""
        <.context_menu_item link_type="button" variant="danger" label="Delete" />
        """)

      default =
        rendered_to_string(~H"""
        <.context_menu_item link_type="button" label="Delete" />
        """)

      assert danger =~ "pc-context-menu__item--danger"
      refute default =~ "pc-context-menu__item--danger"
    end

    test "kbd renders a right-aligned hint that screen readers skip" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.context_menu_item link_type="button" label="Delete" kbd="⌘⌫" />
        """)

      hint = html |> parse_html() |> LazyHTML.query("kbd")

      assert LazyHTML.attribute(hint, "class") == ["pc-context-menu__kbd"]
      assert LazyHTML.attribute(hint, "aria-hidden") == ["true"]
      assert html =~ "⌘⌫"
    end

    test "no kbd renders no hint element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.context_menu_item link_type="button" label="Delete" />
        """)

      refute html =~ "pc-context-menu__kbd"
    end

    test "class and rest pass through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.context_menu_item
          link_type="button"
          label="Delete"
          class="my-item"
          phx-click="delete"
          data-testid="delete"
        />
        """)

      assert html =~ "my-item"
      assert html =~ ~s(phx-click="delete")
      assert html =~ ~s(data-testid="delete")
    end
  end

  describe "context_menu_label/1" do
    test "renders a non-interactive heading" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.context_menu_label class="my-label" data-testid="label">Selection</.context_menu_label>
        """)

      label = html |> parse_html() |> LazyHTML.query(".pc-context-menu__label")

      assert LazyHTML.attribute(label, "role") == ["none"]
      assert html =~ "Selection"
      assert html =~ "my-label"
      assert html =~ ~s(data-testid="label")
      refute html =~ "menuitem"
    end
  end

  describe "context_menu_separator/1" do
    test "renders a separator" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.context_menu_separator class="my-sep" data-testid="sep" />
        """)

      sep = html |> parse_html() |> LazyHTML.query(".pc-context-menu__separator")

      assert LazyHTML.attribute(sep, "role") == ["separator"]
      assert html =~ "my-sep"
      assert html =~ ~s(data-testid="sep")
    end
  end

  describe "composition" do
    test "a full menu renders labels, items and separators inside the panel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.context_menu id="cm-full">
          <:trigger>Card</:trigger>
          <.context_menu_label>Q3-forecast.xlsx</.context_menu_label>
          <.context_menu_item link_type="button" label="Open" />
          <.context_menu_item link_type="button" label="Rename" kbd="F2" />
          <.context_menu_item link_type="button" disabled label="Move" />
          <.context_menu_separator />
          <.context_menu_item link_type="button" variant="danger" label="Delete" kbd="⌘⌫" />
        </.context_menu>
        """)

      doc = parse_html(html)

      assert doc |> LazyHTML.query("#cm-full-menu [role=menuitem]") |> Enum.count() == 4
      assert doc |> LazyHTML.query("#cm-full-menu [role=separator]") |> Enum.count() == 1
      assert doc |> LazyHTML.query("#cm-full-menu .pc-context-menu__label") |> Enum.count() == 1
      assert doc |> LazyHTML.query("#cm-full-menu kbd") |> Enum.count() == 2
    end
  end
end
