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
      colors()
      |> Enum.each(fn color ->
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
      variants()
      |> Enum.each(fn variant ->
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

  describe "badge/1 - status dot" do
    # The badge's own variants, not TestConstants.variants/0 (which carries
    # the button's "shadow" too).
    @badge_variants ~w(light dark soft outline)

    setup do
      %{assigns: default_assigns()}
    end

    test "no dot by default", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge label="Active" />
        """)

      refute_has_class(html, "pc-badge__dot")
      refute_has_class(html, "pc-badge--with-dot")
    end

    test "dot={false} renders byte for byte what it always did", %{assigns: assigns} do
      # The whole promise of a new opt-in attr: nobody's existing badge moves
      # by a single character. Pinned as an exact string, not a class list, so
      # a stray space or an always-emitted empty span fails here.
      html =
        rendered_to_string(~H"""
        <.badge label="Active" />
        """)

      assert html ==
               ~s(<span role="note" class="pc-badge pc-badge--md pc-badge--primary-light">\n  Active\n</span>)
    end

    test "renders a decorative dot before the label", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge dot label="Active" />
        """)

      assert html =~ ~s(<span class="pc-badge__dot" aria-hidden="true"></span>Active)
      assert_has_class(html, "pc-badge--with-dot")
    end

    test "the dot is empty and hidden from assistive tech", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge dot label="Active" />
        """)

      dot = html |> parse_html() |> LazyHTML.query("span.pc-badge__dot")

      assert Enum.count(dot) == 1
      assert LazyHTML.attribute(dot, "aria-hidden") == ["true"]
      assert dot |> LazyHTML.text() |> String.trim() == ""
    end

    test "the dot carries no colour of its own - the badge's variant class does" do
      # Markup stays identical across the matrix; assets/default.css maps
      # .pc-badge--<color>-<variant> .pc-badge__dot to the right ramp stop
      # (see the badge dot guards in css_assets_test.exs).
      for color <- colors(), variant <- @badge_variants do
        assigns = %{color: color, variant: variant}

        html =
          rendered_to_string(~H"""
          <.badge dot color={@color} variant={@variant} label="Active" />
          """)

        assert_has_class(html, badge_class(color, variant))
        assert_has_class(html, "pc-badge--with-dot")
        assert html =~ ~s(<span class="pc-badge__dot" aria-hidden="true"></span>)
      end
    end

    test "every size keeps the dot" do
      for size <- sizes() do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <.badge dot size={@size} label="Active" />
          """)

        assert_has_class(html, "pc-badge--#{size}")
        assert_has_class(html, "pc-badge__dot")
      end
    end

    test "dot leads an inner block too", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge dot>Deploying</.badge>
        """)

      assert html =~ ~s(<span class="pc-badge__dot" aria-hidden="true"></span>)
      assert html =~ "Deploying"
    end

    test "dot and with_icon compose, dot first", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge dot with_icon color="success" variant="soft">
          <.icon name="hero-check" /> Passing
        </.badge>
        """)

      assert_has_class(html, "pc-badge--with-icon")
      assert_has_class(html, "pc-badge--with-dot")
      assert has_icon?(html, "hero-check")

      {dot_at, _} = :binary.match(html, "pc-badge__dot")
      {icon_at, _} = :binary.match(html, "hero-check")
      assert dot_at < icon_at
    end

    test "dot survives a custom class and pass-through attrs", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge dot role="status" class="custom-class" data-test="value" label="Active" />
        """)

      assert_has_class(html, "pc-badge--with-dot")
      assert_has_class(html, "custom-class")
      assert_attribute(html, "role", "status")
      assert_attribute(html, "data-test", "value")
    end
  end

  describe "badge/1 - dot colour override" do
    setup do
      %{assigns: default_assigns()}
    end

    test "dot_color is nil by default - a dotted badge doesn't move a byte", %{assigns: assigns} do
      # The pin for the whole attr. Everything an existing dotted badge
      # renders is here as an exact string: had the dot's class stayed a
      # class list, the unset override would have left `class="pc-badge__dot "`
      # and every consumer snapshot with it.
      html =
        rendered_to_string(~H"""
        <.badge dot label="Active" />
        """)

      assert html ==
               ~s(<span role="note" class="pc-badge pc-badge--md pc-badge--with-dot pc-badge--primary-light">\n  <span class="pc-badge__dot" aria-hidden="true"></span>Active\n</span>)
    end

    test "the neutral chip: gray chrome, semantic dot", %{assigns: assigns} do
      # The shape the attr exists for - the badge stays quiet, the dot
      # carries the state.
      html =
        rendered_to_string(~H"""
        <.badge color="gray" variant="outline" dot dot_color="success">Production</.badge>
        """)

      assert_has_class(html, badge_class("gray", "outline"))

      assert html =~
               ~s(<span class="pc-badge__dot pc-badge__dot--success-outline" aria-hidden="true"></span>Production)
    end

    test "the badge keeps its own colour when the dot diverges", %{assigns: assigns} do
      # dot_color must not leak into the chip's chrome - if it did, the
      # neutral chip stops being neutral.
      html =
        rendered_to_string(~H"""
        <.badge color="gray" variant="outline" dot dot_color="danger" label="Preview" />
        """)

      assert_has_class(html, badge_class("gray", "outline"))
      refute html =~ "pc-badge--danger"
    end

    test "the override carries the variant, because the stop depends on it" do
      # assets/default.css gives each colour a different stop per variant
      # (600 on light, 600/400 on soft and outline, 400 on dark), so the
      # variant has to be in the class for the override to land on the same
      # stop an inherited dot of that colour would.
      for variant <- @badge_variants do
        assigns = %{variant: variant}

        html =
          rendered_to_string(~H"""
          <.badge dot color="gray" variant={@variant} dot_color="success" label="Active" />
          """)

        assert_has_class(html, "pc-badge__dot")
        assert_has_class(html, "pc-badge__dot--success-#{variant}")
        assert_has_class(html, badge_class("gray", variant))
      end
    end

    test "every colour overrides on every variant" do
      for color <- colors(), variant <- @badge_variants do
        assigns = %{color: color, variant: variant}

        html =
          rendered_to_string(~H"""
          <.badge dot color="primary" variant={@variant} dot_color={@color} label="Active" />
          """)

        assert_has_class(html, "pc-badge__dot--#{color}-#{variant}")
      end
    end

    test "dot_color on its own renders nothing - there is no dot to colour", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge dot_color="success" label="Active" />
        """)

      refute_has_class(html, "pc-badge__dot")

      assert html ==
               ~s(<span role="note" class="pc-badge pc-badge--md pc-badge--primary-light">\n  Active\n</span>)
    end

    test "an overridden dot is still decorative and still empty", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge color="gray" variant="outline" dot dot_color="warning" label="Degraded" />
        """)

      dot = html |> parse_html() |> LazyHTML.query("span.pc-badge__dot")

      assert Enum.count(dot) == 1
      assert LazyHTML.attribute(dot, "aria-hidden") == ["true"]
      assert dot |> LazyHTML.text() |> String.trim() == ""
    end

    test "the override composes with size, icon and pass-through attrs", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.badge
          dot
          dot_color="success"
          with_icon
          size="lg"
          color="gray"
          variant="outline"
          role="status"
          class="custom-class"
        >
          <.icon name="hero-check" /> Passing
        </.badge>
        """)

      assert_has_class(html, "pc-badge__dot--success-outline")
      assert_has_class(html, "pc-badge--with-dot")
      assert_has_class(html, "pc-badge--with-icon")
      assert_has_class(html, "pc-badge--lg")
      assert_has_class(html, "custom-class")
      assert_attribute(html, "role", "status")

      {dot_at, _} = :binary.match(html, "pc-badge__dot")
      {icon_at, _} = :binary.match(html, "hero-check")
      assert dot_at < icon_at
    end
  end

  describe "badge/1 - sizes" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders all size variants" do
      sizes()
      |> Enum.each(fn size ->
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

  test "the dot is layout-neutral: it never changes a badge's whitespace policy" do
    assigns = %{}

    # the markup carries no whitespace utility of its own, with or without
    # a dot - the policy is the stylesheet's to state, in one place
    html =
      rendered_to_string(~H"""
      <.badge dot label="A status label long enough to wrap" />
      """)

    refute html =~ "whitespace-nowrap"
    refute html =~ "whitespace-normal"

    css = File.read!(Path.expand("../../assets/default.css", __DIR__))

    # that one place is the base rule: a badge is a label and never wraps,
    # so every badge gets the same answer whatever modifiers it carries
    [base] = Regex.run(~r/\.pc-badge\s*\{[^}]*\}/, css)
    assert base =~ "whitespace-nowrap"

    # and no modifier restates or contradicts it - not the dot, and not
    # the icon, which used to carry a nowrap of its own
    for modifier <- ~w(with-dot with-icon) do
      [rule] = Regex.run(~r/\.pc-badge--#{modifier}\s*\{[^}]*\}/, css)
      refute rule =~ "whitespace", "--#{modifier} must leave whitespace to the base rule"
    end
  end
end
