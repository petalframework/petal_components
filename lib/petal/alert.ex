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
        <Heroicons.Outline.render icon={get_icon(@state)} />

        <%= if assigns[:inner_block] do %>
          <%= render_slot(@inner_block) %>
        <% else %>
          <%= @label %>
        <% end %>
      </div>
    <% end %>
    """
  end

  defp alert_classes(assigns) do
    size_css =
      case assigns[:size] do
        "xs" -> "text-xs leading-4 px-2.5 py-1"
        "sm" -> "text-sm leading-4 px-2.5 py-1"
        "md" -> "text-sm leading-5 px-4 py-2"
        "lg" -> "text-base leading-6 px-4 py-2"
        "xl" -> "text-base leading-6 px-6 py-3"
      end

    state_css = get_state_classes(assigns[:state])
    custom_classes = assigns[:class] || ""

    """
      #{state_css}
      #{size_css}
      #{custom_classes}
      font-medium
      rounded-xl
      inline-flex items-center justify-start
      focus:outline-none
    """
  end

  defp get_state_classes("info"), do: "w-full text-blue-500 bg-blue-100 flex gap-2 items-center whitespace-nowrap"
  defp get_state_classes("success"), do: "w-full text-green-600 bg-green-100 flex gap-2 items-center whitespace-nowrap"
  defp get_state_classes("warning"), do: "w-full text-yellow-600 bg-yellow-100 flex gap-2 items-center whitespace-nowrap"
  defp get_state_classes("danger"), do: "w-full text-red-600 bg-red-100 flex gap-2 items-center whitespace-nowrap"

  defp get_icon("info"), do: :information_circle
  defp get_icon("success"), do: :check_circle
  defp get_icon("warning"), do: :exclamation_circle
  defp get_icon("danger"), do: :x_circle

  defp label_blank?(assigns) do
    (!assigns[:label] || assigns[:label] == "") && !assigns[:inner_block]
  end
end
