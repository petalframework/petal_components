defmodule PetalComponents.ChartTest do
  use ComponentCase
  import PetalComponents.Chart

  describe "basic rendering" do
    test "renders the hook mount point with the option as JSON" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.chart
          id="revenue"
          option={%{series: [%{type: "line", data: [1, 2, 3]}]}}
        />
        """)

      assert html =~ "pc-chart"
      assert html =~ ~s(phx-hook="PetalChart")
      assert html =~ ~s(id="revenue")
      assert html =~ ~s(data-renderer="canvas")

      # option travels as JSON on the hook element
      assert html =~ "data-option="
      assert html =~ "&quot;type&quot;:&quot;line&quot;"
      assert html =~ "[1,2,3]"
    end

    test "the echarts mount node is protected from LiveView patching" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.chart id="c1" option={%{}} height="10rem" />
        """)

      assert html =~ ~s(id="c1-canvas")
      assert html =~ ~s(phx-update="ignore")
      assert html =~ "height: 10rem"
    end

    test "loading state travels as a data attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.chart id="c3" option={%{}} loading={true} />
        """)

      assert html =~ ~s(data-loading="true")

      html =
        rendered_to_string(~H"""
        <.chart id="c4" option={%{}} />
        """)

      assert html =~ ~s(data-loading="false")
    end

    test "renderer, group and custom classes pass through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.chart id="c2" option={%{}} renderer="svg" group="dash" class="mt-4" />
        """)

      assert html =~ ~s(data-renderer="svg")
      assert html =~ ~s(data-group="dash")
      assert html =~ "mt-4"
    end
  end
end
