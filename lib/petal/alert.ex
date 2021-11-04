defmodule PetalComponents.Alert do
  use Phoenix.Component
  alias PetalComponents.Heroicons

  def alert(assigns) do
    ~H"""
    <div class={alert_classes(assigns)}>
      <Heroicons.Outline.render icon={get_icon(@state)} />

      <%= if assigns[:inner_block] do %>
        <%= render_slot(@inner_block) %>
      <% else %>
        <%= @label %>
      <% end %>
    </div>
    """
  end

  def alert_classes(opts \\ %{}) do
    opts = %{
      size: opts[:size] || "xl",
      state: opts[:state] || "info",
      class: opts[:class] || ""
    }

    size_css =
      case opts[:size] do
        "xs" -> "text-xs leading-4 px-2.5 py-1"
        "sm" -> "text-sm leading-4 px-2.5 py-1"
        "md" -> "text-sm leading-5 px-4 py-2"
        "lg" -> "text-base leading-6 px-4 py-2"
        "xl" -> "text-base leading-6 px-6 py-3"
      end

    state_css = get_state_classes(opts)

    custom_classes = opts[:class] || ""

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

  def get_state_classes(%{state: "info"}) do
    "w-full text-blue-500 bg-blue-100 flex gap-2 items-center whitespace-nowrap"
  end

  def get_state_classes(%{state: "success"}) do
    "w-full text-green-600 bg-green-100 flex gap-2 items-center whitespace-nowrap"
  end

  def get_state_classes(%{state: "warning"}) do
    "w-full text-yellow-600 bg-yellow-100 flex gap-2 items-center whitespace-nowrap"
  end

  def get_state_classes(%{state: "danger"}) do
    "w-full text-red-600 bg-red-100 flex gap-2 items-center whitespace-nowrap"
  end

  def get_icon("info") do
    :information_circle
  end

  def get_icon("success") do
    :check_circle
  end

  def get_icon("warning") do
    :exclamation_circle
  end

  def get_icon("danger") do
    :x_circle
  end
end
