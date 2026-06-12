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
      assert html =~ "--pc-beam-radius: 0.75rem"
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
