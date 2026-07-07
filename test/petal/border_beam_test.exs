defmodule PetalComponents.BorderBeamTest do
  use ComponentCase
  import PetalComponents.BorderBeam

  describe "basic rendering" do
    test "renders container, beam layer and content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_beam>
          <div class="p-4">Content</div>
        </.border_beam>
        """)

      assert html =~ "pc-border-beam"
      assert html =~ "pc-border-beam__beam"
      assert html =~ "Content"
      assert html =~ ~s(aria-hidden="true")
    end

    test "applies default CSS variables" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_beam>Content</.border_beam>
        """)

      assert html =~ "--pc-beam-from: #ffaa40"
      assert html =~ "--pc-beam-to: #9c40ff"
      assert html =~ "--pc-beam-duration: 8s"
      assert html =~ "--pc-beam-size: 150px"
      # radius defaults to the theme token via the CSS fallback, so no
      # inline radius var is emitted unless border_radius is passed
      refute html =~ "--pc-beam-radius"
    end

    test "border_radius attr overrides the theme default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_beam border_radius="2rem">Content</.border_beam>
        """)

      assert html =~ "--pc-beam-radius: 2rem"
    end

    test "beams renders evenly phased beam layers" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_beam beams={2}>Content</.border_beam>
        """)

      assert length(String.split(html, "pc-border-beam__beam")) - 1 == 2
      assert html =~ "--pc-beam-phase: 0"
      assert html =~ "--pc-beam-phase: -0.5"
    end

    test "reverse flips direction and traveller rotation" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_beam reverse>Content</.border_beam>
        """)

      assert html =~ "--pc-beam-direction: reverse"
      assert html =~ "--pc-beam-rotate: reverse"
    end

    test "glow renders the symmetric gradient and modifier class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_beam glow color_from="#f43f5e" color_to="#3b82f6">Content</.border_beam>
        """)

      assert html =~ "pc-border-beam--glow"
      assert html =~ "linear-gradient(to left, transparent, #f43f5e, #3b82f6, transparent)"
    end

    test "spring with multiple beams falls back to constant speed" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_beam easing="spring" beams={2}>Content</.border_beam>
        """)

      assert html =~ "--pc-beam-ease: linear;"
      refute html =~ "linear(0"
    end

    test "spring parks near top-centre by default; initial_offset overrides" do
      assigns = %{}

      spring_html =
        rendered_to_string(~H"""
        <.border_beam easing="spring">Content</.border_beam>
        """)

      linear_html =
        rendered_to_string(~H"""
        <.border_beam>Content</.border_beam>
        """)

      custom_html =
        rendered_to_string(~H"""
        <.border_beam easing="spring" initial_offset={40}>Content</.border_beam>
        """)

      assert spring_html =~ "--pc-beam-offset: 25%"
      assert linear_html =~ "--pc-beam-offset: 0%"
      assert custom_html =~ "--pc-beam-offset: 40%"
    end

    test "spring easing resolves to a linear() curve" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_beam easing="spring">Content</.border_beam>
        """)

      assert html =~ "--pc-beam-ease: linear(0"
    end
  end

  describe "customization" do
    test "applies custom colors, duration, size and radius" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_beam
          color_from="#38bdf8"
          color_to="#818cf8"
          duration="6s"
          size="200px"
          border_radius="1rem"
        >
          Content
        </.border_beam>
        """)

      assert html =~ "--pc-beam-from: #38bdf8"
      assert html =~ "--pc-beam-to: #818cf8"
      assert html =~ "--pc-beam-duration: 6s"
      assert html =~ "--pc-beam-size: 200px"
      assert html =~ "--pc-beam-radius: 1rem"
    end

    test "applies custom classes and rest attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.border_beam class="custom-class" data-test="beam">Content</.border_beam>
        """)

      assert html =~ "custom-class"
      assert html =~ ~s(data-test="beam")
    end
  end
end
