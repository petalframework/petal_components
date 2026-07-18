defmodule PetalComponents.Chart do
  @moduledoc """
  Declarative charts powered by Apache ECharts, themed by your design tokens.

  The chart is described by a plain Elixir map — the ECharts
  [option object](https://echarts.apache.org/en/option.html) — so the whole
  spec lives server-side and travels the LiveView wire as data. Updating the
  assign that feeds `option` patches the chart in place with an animated
  transition; no JavaScript is written per chart.

      <.chart
        id="revenue"
        option={%{
          xAxis: %{type: "category", data: ~w(Jan Feb Mar Apr)},
          yAxis: %{type: "value"},
          series: [%{type: "line", smooth: true, data: [820, 932, 901, 1290]}]
        }}
      />

  ## Bring your own ECharts

  Like Alpine, the library does not bundle the engine. Add ECharts to your app
  (either is fine):

      <script src="https://cdn.jsdelivr.net/npm/echarts@5/dist/echarts.min.js"></script>

  or `npm i echarts` and `import * as echarts from "echarts"; window.echarts = echarts;`
  in your `app.js`. The `PetalChart` hook (in the bundled JS) picks it up from
  `window.echarts` and warns if it is missing.

  ## Theming

  Colors are resolved from your CSS tokens at mount, so charts follow the same
  dial as every other component — light and dark:

    * **Series palette** — `--pc-chart-1` … `--pc-chart-8` if you define them,
      otherwise a default palette derived from your semantic ramps
      (primary, info, success, warning, danger, secondary).
    * **Axes, labels, gridlines, tooltips** — derived from the `gray` ramp,
      using the same ghost-material alphas as the rest of the library in dark
      mode.

  Anything you set explicitly in `option` wins over the derived theme.

  The theme re-derives automatically when dark mode flips or theme attributes
  change anywhere above the chart (`class`, `data-theme`, `data-primary`,
  `data-gray`, ...). If your app rethemes some other way, dispatch
  `window.dispatchEvent(new Event("petal:retheme"))` after changing tokens.

  ## Live updates

  Change the assign and the chart animates — this is the primary API:

      def handle_info({:tick, points}, socket) do
        {:noreply, assign(socket, option: put_in(socket.assigns.option, [:series, Access.at(0), :data], points))}
      end

  For high-frequency streams where re-serializing the full option is wasteful,
  push a partial option instead; it is merged via `setOption`:

      push_event(socket, "chart:update:revenue", %{option: %{series: [%{data: points}]}})
  """
  use Phoenix.Component

  attr :id, :string, required: true

  attr :option, :map,
    required: true,
    doc: "the ECharts option object as an Elixir map (atom or string keys)"

  attr :height, :string,
    default: "20rem",
    doc: "any CSS height; the chart fills its container's width"

  attr :renderer, :string,
    default: "canvas",
    values: ~w(canvas svg),
    doc: "svg renders crisp at any zoom and is print-friendly; canvas suits large data"

  attr :group, :string,
    default: nil,
    doc: "charts sharing a group name get connected tooltips/zoom (echarts.connect)"

  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  Renders an ECharts chart bound to the `PetalChart` hook.
  """
  def chart(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="PetalChart"
      class={["pc-chart", @class]}
      data-option={Jason.encode!(@option)}
      data-renderer={@renderer}
      data-group={@group}
      {@rest}
    >
      <div
        id={"#{@id}-canvas"}
        phx-update="ignore"
        class="pc-chart__canvas"
        style={"height: #{@height}"}
      >
      </div>
    </div>
    """
  end
end
