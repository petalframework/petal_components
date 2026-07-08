defmodule PetalComponents.MeteorsTest do
  use ComponentCase
  import PetalComponents.Meteors

  describe "basic rendering" do
    test "renders the default number of meteors" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.meteors />
        """)

      assert html =~ "pc-meteors"
      assert count_substring(html, "pc-meteor\"") == 20
      assert html =~ ~s(aria-hidden="true")
    end

    test "renders a custom count" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.meteors count={5} />
        """)

      assert count_substring(html, "pc-meteor\"") == 5
    end

    test "renders nothing for count 0" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.meteors count={0} />
        """)

      assert count_substring(html, "pc-meteor\"") == 0
    end

    test "each meteor gets position, delay and duration styles" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.meteors count={1} />
        """)

      assert html =~ "top:"
      assert html =~ "left:"
      assert html =~ "animation-delay:"
      assert html =~ "animation-duration:"
    end
  end

  describe "determinism" do
    test "same seed renders identical positions across renders" do
      assigns = %{}

      render = fn ->
        rendered_to_string(~H"""
        <.meteors count={10} seed={1} />
        """)
      end

      assert render.() == render.()
    end

    test "different seeds render different positions" do
      assigns = %{}

      html_a =
        rendered_to_string(~H"""
        <.meteors count={10} seed={1} />
        """)

      html_b =
        rendered_to_string(~H"""
        <.meteors count={10} seed={2} />
        """)

      refute html_a == html_b
    end
  end

  describe "customization" do
    test "applies custom classes and rest attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.meteors class="custom-class" data-test="meteors" />
        """)

      assert html =~ "custom-class"
      assert html =~ ~s(data-test="meteors")
    end
  end
  test "angle and color attrs set the field custom properties" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.meteors count={5} angle="235deg" color="#38bdf8" />
      """)

    assert html =~ "--pc-meteor-angle: 235deg"
    assert html =~ "--pc-meteor-color: #38bdf8"
  end

  test "angle and color default to the shipped look" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.meteors count={3} />
      """)

    assert html =~ "--pc-meteor-angle: 215deg"
    assert html =~ "--pc-meteor-color: #64748b"
  end
end
