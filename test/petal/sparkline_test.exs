defmodule PetalComponents.SparklineTest do
  use ComponentCase
  import PetalComponents.Sparkline

  describe "basic rendering" do
    test "renders an inline svg with a line and an area fill" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sparkline data={[1, 5, 3, 8]} class="w-24 h-8 text-primary-500" />
        """)

      assert html =~ "pc-sparkline"
      assert html =~ "<svg"
      assert html =~ ~s(viewBox="0 0 120 40")
      assert html =~ ~s(stroke="currentColor")
      assert html =~ "text-primary-500"

      # smooth by default -> cubic beziers; area fill present
      assert html =~ " C"
      assert html =~ ~s(opacity="0.12")
    end

    test "fill=false drops the area, smooth=false draws straight segments" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sparkline data={[1, 5, 3, 8]} fill={false} smooth={false} />
        """)

      refute html =~ ~s(opacity="0.12")
      assert html =~ " L"
      refute html =~ " C"
    end

    test "handles a flat series without dividing by zero" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sparkline data={[5, 5, 5]} />
        """)

      assert html =~ "<svg"
    end
  end
end
