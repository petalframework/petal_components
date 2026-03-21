defmodule PetalComponents.ButtonTest do
  @moduledoc """
  Tests for PetalComponents.Button component.

  Validates button rendering, variants, colors, accessibility,
  and proper handling of edge cases and invalid inputs.
  """

  use ComponentCase
  import PetalComponents.Button
  import PetalComponents.Icon

  describe "button/1 - basic rendering" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders basic button element with label", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button label="Press me" phx-click="click_event" />
        """)

      assert html =~ "<button"
      assert html =~ "Press me"
      assert_attribute(html, "phx-click", "click_event")
    end

    test "renders button with inner_block instead of label", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button phx-click="click_event">Press me</.button>
        """)

      assert html =~ "<button"
      assert html =~ "Press me"
      assert_attribute(html, "phx-click", "click_event")
    end

    test "renders with custom CSS class", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button class="custom-class">Press me</.button>
        """)

      assert_has_class(html, "custom-class")
    end

    test "includes additional assigns as attributes", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button custom-attr="123" type="button">Press me</.button>
        """)

      assert_attribute(html, "custom-attr", "123")
      assert_attribute(html, "type", "button")
    end
  end

  describe "button/1 - link types" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders as anchor tag with link_type='a'", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button link_type="a" label="Press me" to="/" phx-click="click_event" />
        """)

      assert html =~ "<a"
      assert html =~ "Press me"
      assert_attribute(html, "href")
      assert_attribute(html, "phx-click", "click_event")
    end

    test "renders as live_patch link with proper data attribute", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button link_type="live_patch" label="Press me" to="/" phx-click="click_event" />
        """)

      assert html =~ "<a"
      assert_attribute(html, "href")
      assert_attribute(html, "phx-click", "click_event")
      assert_attribute(html, "data-phx-link", "patch")
    end

    test "renders as live_redirect link with proper data attribute", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button link_type="live_redirect" label="Press me" to="/" phx-click="click_event" />
        """)

      assert html =~ "<a"
      assert_attribute(html, "href")
      assert_attribute(html, "phx-click", "click_event")
      assert_attribute(html, "data-phx-link", "redirect")
    end
  end

  describe "button/1 - colors and variants" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders all color variants correctly" do
      colors() |> Enum.each(fn color ->
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <.button color={@color}>Button</.button>
          """)

        assert_has_class(html, button_class(color))
      end)
    end

    test "renders shadow variant with proper class", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button color="primary" variant="shadow">Press me</.button>
        """)

      assert_has_class(html, button_class("primary", "shadow"))
    end

    test "renders outline variant with proper class", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button color="primary" variant="outline">Press me</.button>
        """)

      assert_has_class(html, button_class("primary", "outline"))
    end
  end

  describe "button/1 - states and modifiers" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders loading state with spinner icon", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button loading>Press me</.button>
        """)

      assert html =~ "<button"
      assert html =~ "Press me"
      assert html =~ "<svg"
    end

    test "renders disabled button without phx attributes", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button disabled label="Home" phx-click="click-me" />
        """)

      assert_attribute(html, "disabled")
      refute html =~ "phx-"
    end

    test "disabled link renders as button without href or phx attributes", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button disabled link_type="live_redirect" label="Home" to="/" phx-click="click-me" />
        """)

      assert_attribute(html, "disabled")
      refute html =~ "href"
      refute html =~ "phx-"
    end

    test "renders with icon attribute", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button icon="hero-home" label="Home" />
        """)

      assert has_icon?(html, "hero-home")
    end
  end

  describe "button/1 - accessibility" do
    setup do
      %{assigns: default_assigns()}
    end

    test "disabled button has disabled attribute for screen readers", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button disabled>Button</.button>
        """)

      assert_attribute(html, "disabled")
    end

    test "link button maintains phx-click for interaction", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button link_type="live_patch" to="/" phx-click="track_click">Track</.button>
        """)

      assert_attribute(html, "phx-click", "track_click")
    end
  end

  describe "button/1 - rest attributes" do
    setup do
      %{assigns: default_assigns()}
    end

    test "passes through valid HTML button attributes", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button
          label="Home"
          method="post"
          value="submit_value"
          name="submit_button"
          form="my_form"
        />
        """)

      assert_attribute(html, "method", "post")
      assert_attribute(html, "value", "submit_value")
      assert_attribute(html, "name", "submit_button")
      assert_attribute(html, "form", "my_form")
    end

    test "passes through valid HTML anchor attributes for link types", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button
          link_type="a"
          to="/"
          label="Link"
          download="file.pdf"
          target="_blank"
          rel="noopener"
        />
        """)

      assert_attribute(html, "download", "file.pdf")
      assert_attribute(html, "target", "_blank")
      assert_attribute(html, "rel", "noopener")
    end
  end

  describe "button/1 - edge cases" do
    setup do
      %{assigns: default_assigns()}
    end

    test "handles empty label gracefully", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button label="" />
        """)

      assert html =~ "<button"
    end

    test "handles nil color gracefully", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button color={nil}>Button</.button>
        """)

      assert html =~ "<button"
    end

    test "loading without size specified renders correctly", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.button loading>Press me</.button>
        """)

      assert html =~ "<svg"
      assert html =~ "Press me"
    end
  end

  describe "icon_button/1 - basic rendering" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders icon button with proper classes", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.icon_button to="/" link_type="button" size="xs" color="primary">
          <.icon name="hero-clock-solid" />
        </.icon_button>
        """)

      assert has_icon?(html, "hero-clock-solid")
      assert_has_class(html, icon_button_bg_class("primary"))
      refute html =~ "tooltip"
    end

    test "renders with tooltip when provided", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.icon_button tooltip="Hello world!" color="primary">
          <.icon name="hero-clock-solid" />
        </.icon_button>
        """)

      assert has_icon?(html, "hero-clock-solid")
      assert_has_class(html, icon_button_bg_class("primary"))
      assert_attribute(html, "role", "tooltip")
      assert html =~ "Hello world!"
    end

    test "renders all color variants correctly" do
      colors() |> Enum.each(fn color ->
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <.icon_button color={@color}>
            <.icon name="hero-clock" />
          </.icon_button>
          """)

        assert has_icon?(html, "hero-clock")
        assert_has_class(html, icon_button_bg_class(color))
      end)
    end
  end

  describe "icon_button/1 - accessibility" do
    setup do
      %{assigns: default_assigns()}
    end

    test "tooltip has proper ARIA role", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.icon_button tooltip="Settings">
          <.icon name="hero-cog" />
        </.icon_button>
        """)

      assert_attribute(html, "role", "tooltip")
    end

    test "icon button without tooltip still accessible", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.icon_button aria-label="Settings">
          <.icon name="hero-cog" />
        </.icon_button>
        """)

      assert_attribute(html, "aria-label", "Settings")
    end
  end

  describe "icon_button/1 - edge cases" do
    setup do
      %{assigns: default_assigns()}
    end

    test "handles missing icon gracefully", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.icon_button color="primary">
        </.icon_button>
        """)

      assert_has_class(html, icon_button_bg_class("primary"))
    end

    test "handles nil color with default", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.icon_button color={nil}>
          <.icon name="hero-home" />
        </.icon_button>
        """)

      assert has_icon?(html, "hero-home")
    end
  end
end
