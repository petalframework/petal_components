defmodule PetalComponents.Progress do
  use Phoenix.Component

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

  defp calculate_percentage(_value, 0), do: 0.0

  defp calculate_percentage(value, max) when max > 0 do
    Float.round(value / max * 100, 2)
  end
end
