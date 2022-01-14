defmodule PetalComponents.Alert do
  use Phoenix.Component
  alias PetalComponents.Heroicons

  # prop state, :string, options: ["info", "success", "warning", "danger"]
  # prop class, :css_class
  # prop label, :string
  # slot default
  def alert(assigns) do
    assigns = assigns
      |> assign_new(:label, fn -> nil end)
      |> assign_new(:state, fn -> "info" end)
      |> assign_new(:heading, fn -> nil end)
      |> assign_new(:inner_block, fn -> nil end)
      |> assign_new(:classes, fn -> alert_classes(assigns) end)

    ~H"""
    <%= unless label_blank?(@label, @inner_block) do %>
      <div class={@classes}>
        <div class="flex-shrink-0">
          <Heroicons.Outline.render icon={get_icon(@state)} />
        </div>

        <div class="flex-0">
          <%= if @heading do %>
            <div class="mb-2 font-bold"><%= @heading %></div>
          <% end %>

          <%= if @inner_block do %>
            <%= render_slot(@inner_block) %>
          <% else %>
            <%= @label %>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  defp alert_classes(opts) do
    opts = %{
      state: opts[:state] || "info",
      class: opts[:class] || "",
    }

    base_classes = "w-full flex text-sm rounded-xl justify-start focus:outline-none font-medium leading-6 px-4 py-2 gap-3"
    state_css = get_state_classes(opts.state)
    custom_classes = opts.class

    [
      base_classes,
      state_css,
      custom_classes
    ]
    |> Enum.join(" ")
  end

  defp get_state_classes("info"), do: "text-blue-600 bg-blue-100 dark:bg-[#071418] dark:text-blue-200"
  defp get_state_classes("success"), do: "text-green-600 bg-green-100 dark:bg-[#0C130D] dark:text-green-200"
  defp get_state_classes("warning"), do: "text-yellow-600 bg-yellow-100 dark:bg-[#191207] dark:text-yellow-200"
  defp get_state_classes("danger"), do: "text-red-600 bg-red-100 dark:bg-[#160B0B] dark:text-red-200"

  defp get_icon("info"), do: :information_circle
  defp get_icon("success"), do: :check_circle
  defp get_icon("warning"), do: :exclamation_circle
  defp get_icon("danger"), do: :x_circle

  defp label_blank?(label, inner_block) do
    (!label || label == "") && !inner_block
  end
end
