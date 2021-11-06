defmodule PetalComponents.Alert do
  use Phoenix.Component
  alias PetalComponents.Heroicons

  def alert(assigns) do
    assigns = assigns
      |> assign_new(:state, fn -> "info" end)
      |> assign_new(:size, fn -> "xl" end)
      |> assign_new(:class, fn -> "" end)

    ~H"""
    <%= unless label_blank?(assigns) do %>
      <div class={alert_classes(assigns)}>
        <div class="flex-shrink-0">
          <Heroicons.Outline.render icon={get_icon(@state)} />
        </div>

        <div class="flex-0">
          <%= if assigns[:heading] do %>
            <div class="mt-0.5 mb-2 text-sm font-bold uppercase"><%= @heading %></div>
          <% end %>

          <%= if assigns[:inner_block] do %>
            <%= render_slot(@inner_block) %>
          <% else %>
            <%= @label %>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  defp alert_classes(assigns) do
    base_classes = "w-full flex font-medium rounded-xl justify-start focus:outline-none"

    size_css =
      case assigns[:size] do
        "xs" -> "text-xs leading-4 px-2.5 py-1 gap-2"
        "sm" -> "text-sm leading-4 px-2.5 py-1 gap-2"
        "md" -> "text-sm leading-5 px-4 py-2 gap-3"
        "lg" -> "text-base leading-6 px-4 py-2 gap-3"
        "xl" -> "text-base leading-6 px-6 py-3 gap-3"
      end

    state_css = get_state_classes(assigns[:state])
    custom_classes = assigns[:class] || ""

    [
      base_classes,
      state_css,
      size_css,
      custom_classes
    ]
    |> Enum.join(" ")
  end

  defp get_state_classes("info"), do: "text-blue-500 bg-blue-100"
  defp get_state_classes("success"), do: "text-green-600 bg-green-100"
  defp get_state_classes("warning"), do: "text-yellow-600 bg-yellow-100"
  defp get_state_classes("danger"), do: "text-red-600 bg-red-100"

  defp get_icon("info"), do: :information_circle
  defp get_icon("success"), do: :check_circle
  defp get_icon("warning"), do: :exclamation_circle
  defp get_icon("danger"), do: :x_circle

  defp label_blank?(assigns) do
    (!assigns[:label] || assigns[:label] == "") && !assigns[:inner_block]
  end
end
