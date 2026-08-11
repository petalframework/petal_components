defmodule PetalComponents.BorderPlasmaTest do
  use ComponentCase
  import PetalComponents.BorderPlasma

  describe "basic rendering" do
    test "renders container, glow layers and content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_plasma>
          <div class="p-4">Content</div>
        </.border_plasma>
        """)

      assert html =~ "pc-border-plasma"
      assert html =~ "pc-border-plasma__stroke"
      assert html =~ "pc-border-plasma__core"
      assert html =~ "pc-border-plasma__bloom"
      assert html =~ "pc-border-plasma__sheen"
      refute html =~ "pc-border-plasma--clip"
      assert html =~ "pc-border-plasma--rainbow"
      assert html =~ "pc-border-plasma__content"
      assert html =~ "Content"
      assert html =~ ~s(aria-hidden="true")
    end

    test "all four decorative layers are hidden from assistive tech" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_plasma>Content</.border_plasma>
        """)

      # bloom + core + stroke + sheen: light is decoration, every layer of it
      assert count_substring(html, ~s(aria-hidden="true")) == 4

      clipped =
        rendered_to_string(~H"""
        <.border_plasma clip>Content</.border_plasma>
        """)

      assert clipped =~ "pc-border-plasma--clip"
    end

    test "defaults to pulse mode at medium intensity" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_plasma>Content</.border_plasma>
        """)

      assert html =~ "pc-border-plasma--pulse"
      assert html =~ "pc-border-plasma--medium"
      refute html =~ "pc-border-plasma--rotate"
    end

    test "applies default CSS variables" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_plasma>Content</.border_plasma>
        """)

      assert html =~ "--pc-plasma-duration: 4s"
      assert html =~ "--pc-plasma-border-width: 1px"
    end

    test "colours are left to the theme tokens unless passed" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_plasma>Content</.border_plasma>
        """)

      # the CSS falls back to --color-primary-500 / --color-secondary-500, so
      # emitting nothing here is what lets a consumer's theme win
      refute html =~ "--pc-plasma-from"
      refute html =~ "--pc-plasma-to"
      refute html =~ "--pc-plasma-spread"
      refute html =~ "--pc-plasma-radius"
    end

    test "border_radius attr overrides the theme default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_plasma border_radius="2rem">Content</.border_plasma>
        """)

      assert html =~ "--pc-plasma-radius: 2rem"
    end
  end

  describe "modes" do
    test "rotate swaps the modifier class and takes a slower default duration" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_plasma mode="rotate">Content</.border_plasma>
        """)

      assert html =~ "pc-border-plasma--rotate"
      refute html =~ "pc-border-plasma--pulse"
      assert html =~ "--pc-plasma-duration: 6s"
    end

    test "an explicit duration wins over the per-mode default" do
      assigns = %{}

      pulse =
        rendered_to_string(~H"""
        <.border_plasma duration="9s">Content</.border_plasma>
        """)

      rotate =
        rendered_to_string(~H"""
        <.border_plasma mode="rotate" duration="9s">Content</.border_plasma>
        """)

      assert pulse =~ "--pc-plasma-duration: 9s"
      assert rotate =~ "--pc-plasma-duration: 9s"
    end
  end

  describe "intensity" do
    test "each intensity renders its own modifier class" do
      for intensity <- ~w(subtle medium strong) do
        assigns = %{intensity: intensity}

        html =
          rendered_to_string(~H"""
          <.border_plasma intensity={@intensity}>Content</.border_plasma>
          """)

        assert html =~ "pc-border-plasma--#{intensity}"
      end
    end

    test "palette picks the jewel colour source" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_plasma palette="brand">Content</.border_plasma>
        """)

      assert html =~ "pc-border-plasma--brand"
      refute html =~ "pc-border-plasma--rainbow"

      mono =
        rendered_to_string(~H"""
        <.border_plasma palette="mono">Content</.border_plasma>
        """)

      assert mono =~ "pc-border-plasma--mono"
    end
  end

  describe "customization" do
    test "applies custom colors, duration, width and radius" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_plasma
          color_from="#38bdf8"
          color_to="#818cf8"
          duration="6s"
          border_width="3px"
          border_radius="1rem"
        >
          Content
        </.border_plasma>
        """)

      assert html =~ "--pc-plasma-from: #38bdf8"
      assert html =~ "--pc-plasma-to: #818cf8"
      assert html =~ "--pc-plasma-duration: 6s"
      assert html =~ "--pc-plasma-border-width: 3px"
      assert html =~ "--pc-plasma-radius: 1rem"
    end

    test "one colour can be overridden while the other stays on the theme" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_plasma color_from="#38bdf8">Content</.border_plasma>
        """)

      assert html =~ "--pc-plasma-from: #38bdf8"
      refute html =~ "--pc-plasma-to:"
    end

    test "applies custom classes and rest attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_plasma class="custom-class" data-test="plasma">Content</.border_plasma>
        """)

      assert html =~ "custom-class"
      assert html =~ ~s(data-test="plasma")
    end
  end
end
