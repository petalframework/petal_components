defmodule PetalComponents.Progress do
  use Phoenix.Component

  attr(:size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"])

  attr(:color, :string,
    default: "primary",
    values: ["primary", "secondary", "info", "success", "warning", "danger", "gray"]
  )

  attr(:label, :string, default: nil, doc: "labels your progress bar [xl only]")
  attr(:value, :integer, default: nil, doc: "adds a value to your progress bar")
  attr(:max, :integer, default: 100, doc: "sets a max value for your progress bar")
  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:rest, :global)

  def progress(assigns) do
    ~H"""
    <div
      {@rest}
      class={["pc-progress--#{@size}", "pc-progress", "pc-progress--#{@color}", @class]}
      role="progressbar"
      aria-valuemin="0"
      aria-valuemax={@max}
      aria-valuenow={@value}
      aria-label={@label || "Progress"}
    >
      <span
        class={["pc-progress__inner--#{@color}", "pc-progress__inner"]}
        style={"width: #{Float.round(@value/@max*100, 2)}%"}
      >
        <%= if @size == "xl" do %>
          <span class="pc-progress__label">
            <%= @label %>
          </span>
        <% end %>
      </span>
    </div>
    """
  end
end
