defmodule PetalComponents.Alert do
  use Phoenix.Component
  alias PetalComponents.Heroicons

  # prop color, :string, options: ["info", "success", "warning", "danger"]
  # prop class, :css_class
  # prop label, :string
  # slot default
  def alert(assigns) do
    assigns =
      assigns
      |> assign_new(:label, fn -> nil end)
      |> assign_new(:color, fn -> "info" end)
      |> assign_new(:heading, fn -> nil end)
      |> assign_new(:with_icon, fn -> nil end)
      |> assign_new(:inner_block, fn -> nil end)
      |> assign_new(:classes, fn -> alert_classes(assigns) end)
      |> assign_new(:close_button_properties, fn -> nil end)
      |> assign_new(:extra_assigns, fn ->
        assigns_to_attributes(assigns, ~w(
          label
          color
          heading
          with_icon
          inner_block
          classes
          class
          close_button_properties
        )a)
      end)

    ~H"""
    <%= unless label_blank?(@label, @inner_block) do %>
      <div {@extra_assigns} class={@classes}>
        <%= if @with_icon do %>
          <div class="self-start flex-shrink-0 pt-1">
            <Heroicons.Solid.render icon={get_icon(@color)} />
          </div>
        <% end %>

        <div class="w-full flex-0">
          <div class="flex items-start justify-between">
            <div>
              <%= if @heading do %>
                <div class="pt-1 font-bold leading-6">
                  <%= @heading %>
                </div>
              <% end %>

              <div class="py-1 font-medium leading-6">
                <%= if @inner_block do %>
                  <%= render_slot(@inner_block) %>
                <% else %>
                  <%= @label %>
                <% end %>
              </div>
            </div>

            <%= if @close_button_properties do %>
              <button class={Enum.join(["p-2 mouse-hover flex hover:rounded ", " ", get_dismiss_icon_classes(@color), " "])} {@close_button_properties}>
                <Heroicons.Solid.x class="self-start w-4 h-4" />
              </button>
            <% end %>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  defp alert_classes(opts) do
    opts = %{
      color: opts[:color] || "info",
      class: opts[:class] || ""
    }

    base_classes = "w-full flex text-sm rounded items-center focus:outline-none px-4 py-2 gap-3"
    color_css = get_color_classes(opts.color)
    custom_classes = opts.class

    [
      base_classes,
      color_css,
      custom_classes
    ]
    |> Enum.join(" ")
  end

  defp get_color_classes("info"),
    do: "text-blue-800 bg-blue-100 dark:bg-blue-200 dark:text-blue-800"

  defp get_color_classes("success"),
    do: "text-green-800 bg-green-100 dark:bg-green-200 dark:text-green-800"

  defp get_color_classes("warning"),
    do: "text-yellow-800 bg-yellow-100 dark:bg-yellow-200 dark:text-yellow-800"

  defp get_color_classes("danger"),
    do: "text-red-800 bg-red-100 dark:bg-red-200 dark:text-red-800"

  defp get_dismiss_icon_classes("info"),
    do:
      "bg-blue-100 dark:bg-blue-200 hover:bg-blue-200 dark:hover:bg-blue-300 hover:text-blue-800 dark:hover:text-blue-900"

  defp get_dismiss_icon_classes("success"),
    do:
      "bg-green-100 dark:bg-green-200 hover:bg-green-200 dark:hover:bg-green-300 hover:text-green-800 dark:hover:text-green-900"

  defp get_dismiss_icon_classes("warning"),
    do:
      "bg-yellow-100 dark:bg-yellow-200 hover:bg-yellow-200 dark:hover:bg-yellow-300 hover:text-yellow-800 dark:hover:text-yellow-900"

  defp get_dismiss_icon_classes("danger"),
    do:
      "bg-red-100 dark:bg-red-200 hover:bg-red-200 dark:hover:bg-red-300 hover:text-red-800 dark:hover:text-red-900"

  defp get_icon("info"), do: :information_circle
  defp get_icon("success"), do: :check_circle
  defp get_icon("warning"), do: :exclamation_circle
  defp get_icon("danger"), do: :x_circle

  defp label_blank?(label, inner_block) do
    (!label || label == "") && !inner_block
  end
end
