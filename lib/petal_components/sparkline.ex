defmodule PetalComponents.Sparkline do
  @moduledoc """
  A tiny inline trend line rendered as pure server-side SVG — zero JavaScript,
  works everywhere (stat cards, table cells, emails).

      <.sparkline data={[4, 7, 5, 9, 8, 12, 11, 14]} class="w-24 h-8 text-primary-500" />

  The line inherits `currentColor`, so you color it with a text class. Set the
  size with width/height classes; the stroke keeps its width at any size.
  """
  use Phoenix.Component

  @view_w 120
  @view_h 40

  attr :data, :list, required: true, doc: "a list of numbers (2 or more points)"

  attr :smooth, :boolean,
    default: true,
    doc: "curve through the points instead of straight segments"

  attr :fill, :boolean, default: true, doc: "shade the area under the line at low opacity"
  attr :stroke_width, :any, default: 2
  attr :class, :any, default: nil, doc: ~s|size + color, e.g. "w-24 h-8 text-success-500"|
  attr :rest, :global

  @doc """
  Renders an inline SVG sparkline.
  """
  def sparkline(assigns) do
    points = normalize(assigns.data)
    line = if assigns.smooth, do: smooth_path(points), else: linear_path(points)

    assigns =
      assigns
      |> assign(:line, line)
      |> assign(:area, area_path(line, points))
      |> assign(:view_w, @view_w)
      |> assign(:view_h, @view_h)

    ~H"""
    <svg
      viewBox={"0 0 #{@view_w} #{@view_h}"}
      preserveAspectRatio="none"
      fill="none"
      aria-hidden="true"
      class={["pc-sparkline", @class]}
      {@rest}
    >
      <path :if={@fill && @area} d={@area} fill="currentColor" opacity="0.12" stroke="none" />
      <path
        d={@line}
        stroke="currentColor"
        stroke-width={@stroke_width}
        stroke-linecap="round"
        stroke-linejoin="round"
        vector-effect="non-scaling-stroke"
      />
    </svg>
    """
  end

  # Scale the series into the viewBox with padding so round caps aren't clipped.
  defp normalize(data) do
    data = Enum.map(data, &(&1 * 1.0))
    {min, max} = Enum.min_max(data)
    span = if max == min, do: 1.0, else: max - min
    n = length(data)
    pad = 3.0
    step = if n > 1, do: (@view_w - pad * 2) / (n - 1), else: 0.0

    data
    |> Enum.with_index()
    |> Enum.map(fn {v, i} ->
      {pad + i * step, pad + (1 - (v - min) / span) * (@view_h - pad * 2)}
    end)
  end

  defp linear_path([{x, y} | rest]) do
    Enum.reduce(rest, "M#{fmt(x)} #{fmt(y)}", fn {px, py}, acc ->
      acc <> " L#{fmt(px)} #{fmt(py)}"
    end)
  end

  # Catmull-Rom through the points, converted to cubic beziers.
  defp smooth_path([first | _] = points) do
    extended = [first | points] ++ [List.last(points)]

    extended
    |> Enum.chunk_every(4, 1, :discard)
    |> Enum.reduce("M#{fmt(elem(first, 0))} #{fmt(elem(first, 1))}", fn
      [{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}], acc ->
        c1x = x1 + (x2 - x0) / 6
        c1y = y1 + (y2 - y0) / 6
        c2x = x2 - (x3 - x1) / 6
        c2y = y2 - (y3 - y1) / 6
        acc <> " C#{fmt(c1x)} #{fmt(c1y)}, #{fmt(c2x)} #{fmt(c2y)}, #{fmt(x2)} #{fmt(y2)}"
    end)
  end

  defp area_path(nil, _points), do: nil

  defp area_path(line, points) do
    {last_x, _} = List.last(points)
    {first_x, _} = List.first(points)
    line <> " L#{fmt(last_x)} #{@view_h} L#{fmt(first_x)} #{@view_h} Z"
  end

  defp fmt(f), do: :erlang.float_to_binary(f * 1.0, decimals: 2)
end
