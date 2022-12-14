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
      <div class={"#{get_parent_classes(@size)} flex overflow-hidden #{get_parent_color_classes(@color)}"}>
        <span
          class={"#{get_color_classes(@color)} text-xs flex flex-col text-center text-white justify-center whitespace-nowrap font-normal leading-6 px-4 py-2"}
          style={"width: #{round(@value/@max*100)}%"}
        >
          <%= if @size == "xl" do %>
            <%= @label %>
          <% end %>
        </span>
      </div>
    </div>
    """
  end

  defp get_color_classes("primary"), do: "bg-primary-500"
  defp get_color_classes("secondary"), do: "bg-secondary-500"
  defp get_color_classes("info"), do: "bg-blue-500"
  defp get_color_classes("success"), do: "bg-green-500"
  defp get_color_classes("warning"), do: "bg-yellow-500"
  defp get_color_classes("danger"), do: "bg-red-500"
  defp get_color_classes("gray"), do: "bg-gray-500"

  defp get_parent_classes("xs"), do: "h-1 rounded-sm"
  defp get_parent_classes("sm"), do: "h-2 rounded-md"
  defp get_parent_classes("md"), do: "h-3 rounded-md"
  defp get_parent_classes("lg"), do: "h-4 rounded-lg"
  defp get_parent_classes("xl"), do: "h-5 rounded-xl"

  defp get_parent_color_classes("primary"), do: "bg-primary-100"
  defp get_parent_color_classes("secondary"), do: "bg-secondary-100"
  defp get_parent_color_classes("info"), do: "bg-blue-100"
  defp get_parent_color_classes("success"), do: "bg-green-100"
  defp get_parent_color_classes("warning"), do: "bg-yellow-100"
  defp get_parent_color_classes("danger"), do: "bg-red-100"
  defp get_parent_color_classes("gray"), do: "bg-gray-100"
end
