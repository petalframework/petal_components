defmodule PetalComponents.Progress do
  @moduledoc """
  Determinate progress in two shapes, sharing one API.

    * `progress/1` - the linear bar. Page-top loading strips, upload rows,
      quota meters.
    * `progress_ring/1` - the circular version. Reads at sizes a bar can't
      (a 16px ring in a table cell still shows its proportion), and the
      middle is free real estate for a percentage readout.

  Both take the same `value`/`max`, the same `size` scale (xs to xl) and the
  same `color` vocabulary, so a bar and a ring on the same page agree.

  ## What this is not

  Both shapes are determinate: you know the percentage and you're showing it.
  For "something is happening, no idea how long" reach for
  `PetalComponents.Loading.spinner/1` instead. A ring that spins forever is a
  spinner wearing a progress costume, and this library already has a spinner.

  Semi-circle gauges (the speedometer look) are deliberately absent. They're a
  dashboard-chart shape rather than a progress shape, and nobody has asked.
  """
  use Phoenix.Component

  # Ring geometry: {diameter, stroke width}, both in px and both in the SVG's
  # own user units, so the viewBox is 1:1 with the rendered box. Stroke grows
  # with diameter but not linearly - a 16px ring needs a proportionally
  # fatter stroke than a 96px one to read at all.
  @ring_geometry %{
    "xs" => {16, 2.5},
    "sm" => {24, 3},
    "md" => {40, 4},
    "lg" => {64, 6},
    "xl" => {96, 8}
  }

  attr(:size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"])

  attr(:color, :string,
    default: "primary",
    values: ["primary", "secondary", "info", "success", "warning", "danger", "gray"]
  )

  attr(:label, :string, default: nil, doc: "labels your progress bar")

  attr(:label_position, :string,
    default: "inside",
    values: ["inside", "top"],
    doc:
      "inside renders the label in the bar itself (xl only); top renders a label row with the percentage above the bar, at any size"
  )

  attr(:value, :integer, default: nil, doc: "adds a value to your progress bar")
  attr(:max, :integer, default: 100, doc: "sets a max value for your progress bar")

  attr(:status, :string,
    default: nil,
    doc:
      ~s(a status line under the bar - "Downloading assets..." - announced politely to screen readers as it changes)
  )

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:rest, :global)

  def progress(%{label_position: "top"} = assigns) do
    assigns = assign(assigns, :percentage, calculate_percentage(assigns.value, assigns.max))

    ~H"""
    <div {@rest} class={["pc-progress-wrapper", @class]}>
      <div class="pc-progress__header">
        <span class="pc-progress__title">{@label}</span>
        <span :if={@value} class="pc-progress__value">{round(@percentage)}%</span>
      </div>
      <.bar
        size={@size}
        color={@color}
        percentage={@percentage}
        value={@value}
        max={@max}
        aria_label={@label || "Progress"}
      />
      <div :if={@status} class="pc-progress__status" aria-live="polite">{@status}</div>
    </div>
    """
  end

  # A status line needs somewhere to live, so it implies the wrapper even
  # without a top label row.
  def progress(%{status: status} = assigns) when is_binary(status) do
    assigns = assign(assigns, :percentage, calculate_percentage(assigns.value, assigns.max))

    ~H"""
    <div {@rest} class={["pc-progress-wrapper", @class]}>
      <.bar
        size={@size}
        color={@color}
        percentage={@percentage}
        value={@value}
        max={@max}
        aria_label={@label || "Progress"}
        inside_label={@size == "xl" && @label}
      />
      <div class="pc-progress__status" aria-live="polite">{@status}</div>
    </div>
    """
  end

  def progress(assigns) do
    assigns = assign(assigns, :percentage, calculate_percentage(assigns.value, assigns.max))

    ~H"""
    <.bar
      {@rest}
      class={@class}
      size={@size}
      color={@color}
      percentage={@percentage}
      value={@value}
      max={@max}
      aria_label={@label || "Progress"}
      inside_label={@size == "xl" && @label}
    />
    """
  end

  attr(:size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"])

  attr(:color, :string,
    default: "primary",
    values: ["primary", "secondary", "info", "success", "warning", "danger", "gray"]
  )

  attr(:value, :integer, default: nil, doc: "how far along you are")
  attr(:max, :integer, default: 100, doc: "sets a max value for your progress ring")

  attr(:label, :string,
    default: nil,
    doc: "the accessible name, same as on the bar - not drawn, screen readers only"
  )

  attr(:show_value, :boolean,
    default: false,
    doc: "draws the rounded percentage in the middle. md and up have room for it; xs and sm don't"
  )

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:rest, :global)

  slot(:inner_block,
    doc: "custom middle content (\"12/30\", an icon) - takes over from show_value"
  )

  @doc """
  Circular determinate progress: a track ring with the value drawn as an arc
  over it, starting at 12 o'clock and going clockwise.

      <.progress_ring value={72} />
      <.progress_ring value={72} size="lg" color="success" show_value />
      <.progress_ring value={12} max={30} size="lg"><span>12/30</span></.progress_ring>

  The arc is `stroke="currentColor"` and the track is the same colour washed
  back, so a text class recolours the whole thing the way it does on
  `PetalComponents.Sparkline.sparkline/1`:

      <.progress_ring value={72} class="text-emerald-500" />

  `size` sets the diameter (16px at xs up to 96px at xl); a `w-*`/`h-*` class
  overrides it and the stroke scales with the box.
  """
  def progress_ring(assigns) do
    {diameter, stroke_width} = Map.fetch!(@ring_geometry, assigns.size)
    center = diameter / 2
    radius = (diameter - stroke_width) / 2
    circumference = 2 * :math.pi() * radius
    percentage = calculate_percentage(assigns.value, assigns.max)

    # Past 100% the dash offset would go negative and the pattern wraps back
    # on itself, so the arc geometry clamps even though the ARIA values report
    # what you actually passed.
    drawn = percentage |> max(0.0) |> min(100.0)

    assigns =
      assigns
      |> assign(:percentage, percentage)
      |> assign(:diameter, diameter)
      |> assign(:stroke_width, stroke_width)
      |> assign(:center, center)
      |> assign(:radius, radius)
      |> assign(:circumference, Float.round(circumference, 2))
      |> assign(:dash_offset, Float.round(circumference * (1 - drawn / 100), 2))

    ~H"""
    <div
      {@rest}
      class={[
        "pc-progress-ring",
        "pc-progress-ring--#{@size}",
        "pc-progress-ring--#{@color}",
        @class
      ]}
      role="progressbar"
      aria-valuemin="0"
      aria-valuemax={@max}
      aria-valuenow={@value}
      aria-valuetext={"#{round(@percentage)}%"}
      aria-label={@label || "Progress"}
    >
      <svg
        class="pc-progress-ring__svg"
        viewBox={"0 0 #{@diameter} #{@diameter}"}
        fill="none"
        aria-hidden="true"
      >
        <circle
          class="pc-progress-ring__track"
          cx={@center}
          cy={@center}
          r={@radius}
          stroke="currentColor"
          stroke-width={@stroke_width}
        />
        <%!-- rotate(-90) puts the dash origin at 12 o'clock instead of 3, so
              the arc grows the way people read a clock. --%>
        <circle
          class="pc-progress-ring__arc"
          cx={@center}
          cy={@center}
          r={@radius}
          stroke="currentColor"
          stroke-width={@stroke_width}
          stroke-linecap="round"
          stroke-dasharray={@circumference}
          stroke-dashoffset={@dash_offset}
          transform={"rotate(-90 #{@center} #{@center})"}
        />
      </svg>
      <%!-- aria-hidden: role="progressbar" already announces aria-valuetext,
            so an announced readout would just say the number twice. --%>
      <div
        :if={@show_value || @inner_block != []}
        class={["pc-progress-ring__label", "pc-progress-ring__label--#{@size}"]}
        aria-hidden="true"
      >
        <span :if={@inner_block == []}>{round(@percentage)}%</span>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr(:size, :string, required: true)
  attr(:color, :string, required: true)
  attr(:percentage, :float, required: true)
  attr(:value, :any, required: true)
  attr(:max, :integer, required: true)
  attr(:aria_label, :string, required: true)
  attr(:inside_label, :any, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  defp bar(assigns) do
    ~H"""
    <div
      {@rest}
      class={["pc-progress--#{@size}", "pc-progress", "pc-progress--#{@color}", @class]}
      role="progressbar"
      aria-valuemin="0"
      aria-valuemax={@max}
      aria-valuenow={@value}
      aria-valuetext={"#{round(@percentage)}%"}
      aria-label={@aria_label}
    >
      <%!-- Two-layer label wipe (xl): base reads on the empty track; the fill
            copy, clipped to the filled width and painted on top, reads on the
            fill. Same text, same spot, so it stays legible at any percentage
            instead of white-on-light until the fill catches up. --%>
      <span
        :if={@inside_label}
        class="pc-progress__label pc-progress__label--track"
        aria-hidden="true"
      >
        {@inside_label}
      </span>
      <span
        class={["pc-progress__inner--#{@color}", "pc-progress__inner"]}
        style={"width: #{@percentage}%"}
      ></span>
      <span
        :if={@inside_label}
        class="pc-progress__label pc-progress__label--fill"
        style={"clip-path: inset(0 #{Float.round(100.0 - @percentage, 2)}% 0 0)"}
        aria-hidden="true"
      >
        {@inside_label}
      </span>
    </div>
    """
  end

  # No value yet is an indeterminate bar, not an arithmetic error: nothing
  # drawn, and aria-valuenow stays absent so AT reads it as indeterminate.
  defp calculate_percentage(nil, _max), do: 0.0
  defp calculate_percentage(_value, 0), do: 0.0

  defp calculate_percentage(value, max) when max > 0 do
    Float.round(value / max * 100, 2)
  end
end
