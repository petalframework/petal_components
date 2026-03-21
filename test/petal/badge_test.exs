defmodule PetalComponents.BadgeTest do
  @moduledoc """
  Tests for PetalComponents.Badge component.

  Validates badge rendering with different colors, variants, sizes,
  icons, and proper handling of edge cases.
  """

  use ComponentCase
  import PetalComponents.Badge
  import PetalComponents.Icon

  describe "badge/1 - basic rendering" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders badge with label", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge label="Test Badge" />
        """)

      assert html =~ "Test Badge"
    end

    test "renders badge with inner block content", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge>Custom Content</.badge>
        """)

      assert html =~ "Custom Content"
    end

    test "renders with custom CSS class", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge label="Badge" class="custom-class" />
        """)

      assert_has_class(html, "custom-class")
    end

    test "includes additional assigns as attributes", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge label="Badge" custom-attr="123" data-test="value" />
        """)

      assert_attribute(html, "custom-attr", "123")
      assert_attribute(html, "data-test", "value")
    end
  end

  describe "badge/1 - colors and variants" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders all color variants with light style by default" do
      colors() |> Enum.each(fn color ->
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <.badge color={@color} label={String.capitalize(@color)} />
          """)

        assert html =~ String.capitalize(color)
        assert_has_class(html, badge_class(color, "light"))
      end)
    end

    test "renders all variants for a given color" do
      variants() |> Enum.each(fn variant ->
        assigns = %{variant: variant}

        html =
          rendered_to_string(~H"""
          <.badge color="primary" variant={@variant} label="Badge" />
          """)

        assert_has_class(html, badge_class("primary", variant))
      end)
    end

    test "renders all color and variant combinations" do
      for color <- colors(), variant <- variants() do
        assigns = %{color: color, variant: variant}

        html =
          rendered_to_string(~H"""
          <.badge color={@color} variant={@variant} label="Test" />
          """)

        assert_has_class(html, badge_class(color, variant))
      end
    end
  end

  describe "badge/1 - with icons" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders badge with icon and content", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge color="gray" variant="light" with_icon size="sm">
          <.icon name="hero-clock-solid" class="w-3 h-3 pb-[0.05rem]" /> 2 hours ago
        </.badge>
        """)

      assert has_icon?(html, "hero-clock-solid")
      assert count_icons(html, "hero-clock-solid") == 1
      assert html =~ "2 hours ago"
    end

    test "renders badge with multiple icons", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge with_icon>
          <.icon name="hero-check" /> <.icon name="hero-clock" /> Status
        </.badge>
        """)

      assert has_icon?(html, "hero-check")
      assert has_icon?(html, "hero-clock")
      assert count_icons(html, "hero-check") == 1
      assert count_icons(html, "hero-clock") == 1
    end
  end

  describe "badge/1 - sizes" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders all size variants" do
      sizes() |> Enum.each(fn size ->
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <.badge size={@size} label="Badge" />
          """)

        assert html =~ "Badge"
      end)
    end
  end

  describe "badge/1 - accessibility" do
    setup do
      %{assigns: default_assigns()}
    end

    test "can include aria-label for screen readers", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge label="3" aria-label="3 unread notifications" />
        """)

      assert_attribute(html, "aria-label", "3 unread notifications")
    end

    test "badge with icon maintains semantic meaning", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge with_icon aria-label="Success status">
          <.icon name="hero-check-circle" /> Complete
        </.badge>
        """)

      assert_attribute(html, "aria-label", "Success status")
      assert html =~ "Complete"
    end
  end

  describe "badge/1 - edge cases" do
    setup do
      %{assigns: default_assigns()}
    end

    test "handles empty label gracefully", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge label="" />
        """)

      assert html != ""
    end

    test "handles nil color with default", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge color={nil} label="Badge" />
        """)

      assert html =~ "Badge"
    end

    test "handles nil variant with default", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge variant={nil} label="Badge" />
        """)

      assert html =~ "Badge"
    end

    test "badge with only icon and no text", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge with_icon aria-label="Notification">
          <.icon name="hero-bell" />
        </.badge>
        """)

      assert has_icon?(html, "hero-bell")
      assert_attribute(html, "aria-label", "Notification")
    end

    test "badge with very long text", %{assigns: assigns} do
      long_text = String.duplicate("Long Badge Text ", 10)
      assigns = %{text: long_text}

      html =
        rendered_to_string(~H"""
        <.badge label={@text} />
        """)

      assert html =~ long_text
    end
  end

  describe "badge/1 - negative cases" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders without with_icon flag when icon present", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge>
          <.icon name="hero-home" /> Home
        </.badge>
        """)

      assert has_icon?(html, "hero-home")
    end

    test "handles both label and inner_block preferring inner_block", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge label="Label Text">Inner Block Text</.badge>
        """)

      assert html =~ "Inner Block Text"
    end
  end
end
