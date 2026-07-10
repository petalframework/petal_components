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
      <div
        class={["pc-progress--#{@size}", "pc-progress", "pc-progress--#{@color}"]}
        role="progressbar"
        aria-valuemin="0"
        aria-valuemax={@max}
        aria-valuenow={@value}
        aria-valuetext={"#{round(@percentage)}%"}
        aria-label={@label || "Progress"}
      >
        <span
          class={["pc-progress__inner--#{@color}", "pc-progress__inner"]}
          style={"width: #{@percentage}%"}
        ></span>
      </div>
    </div>
    """
  end

  def progress(assigns) do
    assigns = assign(assigns, :percentage, calculate_percentage(assigns.value, assigns.max))

    ~H"""
    <div
      {@rest}
      class={["pc-progress--#{@size}", "pc-progress", "pc-progress--#{@color}", @class]}
      role="progressbar"
      aria-valuemin="0"
      aria-valuemax={@max}
      aria-valuenow={@value}
      aria-valuetext={"#{round(@percentage)}%"}
      aria-label={@label || "Progress"}
    >
      <span
        class={["pc-progress__inner--#{@color}", "pc-progress__inner"]}
        style={"width: #{@percentage}%"}
      >
        <%= if @size == "xl" do %>
          <span class="pc-progress__label">
            {@label}
          </span>
        <% end %>
      </span>
    </div>
    """
  end

  defp calculate_percentage(_value, 0), do: 0.0

  defp calculate_percentage(value, max) when max > 0 do
    Float.round(value / max * 100, 2)
  end
end
