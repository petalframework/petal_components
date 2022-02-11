defmodule PetalComponents.Progress do
  use Phoenix.Component

  # prop size, :string, options: ["xs", "sm", "md", "lg", "xl"]
  # prop color, :string, options: ["primary", "secondary", "info", "success", "warning", "danger"]
  # prop class, :string
  # prop value, :integer
  # prop max, :integer
  # prop label, :string [xl]
  def progress(assigns) do
    assigns =
      assigns
      |> assign_new(:label, fn -> "" end)
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:size, fn -> "md" end)
      |> assign_new(:value, fn -> nil end)
      |> assign_new(:color, fn -> "primary" end)
      |> assign_new(:max, fn -> 100 end)

    ~H"""
    <div class={@class}>
      <div class={"#{get_parent_classes(@size)} flex overflow-hidden #{get_parent_color_classes(@color)}"}>
        <span class={"#{get_color_classes(@color)} text-xs flex flex-col text-center text-white justify-center whitespace-nowrap font-normal leading-6 px-4 py-2"} style={"width: #{round(@value/@max*100)}%"}>
          <%= if @size == "xl" do %>
            <%= @label %>
          <% end %>
        </span>
      </div>
    </div>
    """
  end

  defp get_color_classes("primary"), do: "bg-blue-500"
  defp get_color_classes("secondary"), do: "bg-pink-500"
  defp get_color_classes("info"), do: "bg-blue-500"
  defp get_color_classes("success"), do: "bg-green-500"
  defp get_color_classes("warning"), do: "bg-yellow-500"
  defp get_color_classes("danger"), do: "bg-red-500"

  defp get_parent_classes("xs"), do: "h-1 rounded-sm"
  defp get_parent_classes("sm"), do: "h-2 rounded-md"
  defp get_parent_classes("md"), do: "h-3 rounded-md"
  defp get_parent_classes("lg"), do: "h-4 rounded-lg"
  defp get_parent_classes("xl"), do: "h-5 rounded-xl"

  defp get_parent_color_classes("primary"), do: "bg-blue-100"
  defp get_parent_color_classes("secondary"), do: "bg-pink-100"
  defp get_parent_color_classes("info"), do: "bg-blue-100"
  defp get_parent_color_classes("success"), do: "bg-green-100"
  defp get_parent_color_classes("warning"), do: "bg-yellow-100"
  defp get_parent_color_classes("danger"), do: "bg-red-100"
end
