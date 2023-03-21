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
  attr(:class, :string, default: "", doc: "CSS class")
  attr(:rest, :global)

  def progress(assigns) do
    ~H"""
    <div {@rest} class={@class}>
      <div class={"#{get_parent_classes(@size)} pc-progress #{get_parent_color_classes(@color)}"}>
        <span
          class={"#{get_color_classes(@color)} pc-progress__inner"}
          style={"width: #{round(@value/@max*100)}%"}
        >
          <%= if @size == "xl" do %>
            <span class="pc-progress__label">
              <%= @label %>
            </span>
          <% end %>
        </span>
      </div>
    </div>
    """
  end

  defp get_color_classes("primary"), do: "pc-progress__inner--primary"
  defp get_color_classes("secondary"), do: "pc-progress__inner--secondary"
  defp get_color_classes("info"), do: "pc-progress__inner--info"
  defp get_color_classes("success"), do: "pc-progress__inner--success"
  defp get_color_classes("warning"), do: "pc-progress__inner--warning"
  defp get_color_classes("danger"), do: "pc-progress__inner--danger"
  defp get_color_classes("gray"), do: "pc-progress__inner--gray"

  defp get_parent_classes("xs"), do: "pc-progress--xs"
  defp get_parent_classes("sm"), do: "pc-progress--sm"
  defp get_parent_classes("md"), do: "pc-progress--md"
  defp get_parent_classes("lg"), do: "pc-progress--lg"
  defp get_parent_classes("xl"), do: "pc-progress--xl"

  defp get_parent_color_classes("primary"), do: "pc-progress--primary"
  defp get_parent_color_classes("secondary"), do: "pc-progress--secondary"
  defp get_parent_color_classes("info"), do: "pc-progress--info"
  defp get_parent_color_classes("success"), do: "pc-progress--success"
  defp get_parent_color_classes("warning"), do: "pc-progress--warning"
  defp get_parent_color_classes("danger"), do: "pc-progress--danger"
  defp get_parent_color_classes("gray"), do: "pc-progress--gray"
end
