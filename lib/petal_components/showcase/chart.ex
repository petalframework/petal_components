defmodule PetalComponents.Showcase.Chart do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Chart,
    title: "Chart",
    functions: [:chart]

  example :area_line, "Area line",
    description:
      "A smooth line with the soft gradient fade. The spec is a plain Elixir map; colours derive from your theme tokens at mount." do
    ~H"""
    <.chart
      id="showcase-chart-line"
      height="16rem"
      option={
        %{
          grid: %{left: 8, right: 16, top: 16, bottom: 8, containLabel: true},
          xAxis: %{type: "category", boundaryGap: false, data: ~w(Mon Tue Wed Thu Fri Sat Sun)},
          yAxis: %{type: "value"},
          tooltip: %{trigger: "axis"},
          series: [
            %{
              type: "line",
              name: "Visitors",
              smooth: true,
              areaStyle: %{color: "petal:fade"},
              data: [820, 932, 901, 1290, 1330, 1520, 1710]
            }
          ]
        }
      }
    />
    """
  end

  example :grouped_bar, "Grouped bars",
    description:
      "Two series side by side. Series colours come from the --pc-chart-* palette, falling back to your semantic ramps." do
    ~H"""
    <.chart
      id="showcase-chart-bar"
      height="16rem"
      option={
        %{
          grid: %{left: 8, right: 8, top: 32, bottom: 8, containLabel: true},
          legend: %{top: 0},
          tooltip: %{trigger: "axis"},
          xAxis: %{type: "category", data: ~w(Q1 Q2 Q3 Q4)},
          yAxis: %{type: "value"},
          series: [
            %{name: "Pro", type: "bar", barGap: 0, data: [320, 402, 391, 534]},
            %{name: "Teams", type: "bar", data: [120, 182, 231, 290]}
          ]
        }
      }
    />
    """
  end

  example :donut, "Donut with a centre total",
    description: "A pie with an inner radius and a title placed in the hole." do
    ~H"""
    <.chart
      id="showcase-chart-donut"
      height="16rem"
      option={
        %{
          tooltip: %{trigger: "item"},
          legend: %{bottom: 0},
          title: %{
            text: "960",
            subtext: "customers",
            left: "center",
            top: "33%",
            itemGap: 2,
            textStyle: %{fontSize: 24, fontWeight: 650},
            subtextStyle: %{fontSize: 12}
          },
          series: [
            %{
              name: "Plan",
              type: "pie",
              radius: ["48%", "72%"],
              center: ["50%", "44%"],
              itemStyle: %{borderRadius: 5, borderWidth: 2},
              label: %{show: false},
              data: [
                %{value: 580, name: "Individual"},
                %{value: 260, name: "Team"},
                %{value: 120, name: "Legacy"}
              ]
            }
          ]
        }
      }
    />
    """
  end

  example :live_currency, "Money axes and tooltips",
    description:
      "Named formatters stand in for the JavaScript callbacks ECharts normally wants: petal:currency-compact for the axis, petal:currency for the tooltip." do
    ~H"""
    <.chart
      id="showcase-chart-currency"
      height="16rem"
      option={
        %{
          grid: %{left: 8, right: 16, top: 16, bottom: 8, containLabel: true},
          xAxis: %{type: "category", boundaryGap: false, data: ~w(Jan Feb Mar Apr May Jun)},
          yAxis: %{type: "value", axisLabel: %{formatter: "petal:currency-compact:USD"}},
          tooltip: %{trigger: "axis", valueFormatter: "petal:currency:USD"},
          series: [
            %{
              type: "line",
              name: "MRR",
              smooth: true,
              areaStyle: %{color: "petal:fade"},
              data: [9200, 9840, 10100, 11200, 11900, 12480]
            }
          ]
        }
      }
    />
    """
  end
end
