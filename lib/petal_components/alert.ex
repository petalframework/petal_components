defmodule PetalComponents.Alert do
  use Phoenix.Component
  import PetalComponents.Helpers

  attr(:color, :string,
    default: "info",
    values: ["info", "success", "warning", "danger"]
  )

  attr(:with_icon, :boolean, default: false, doc: "adds some icon base classes")
  attr(:class, :string, default: "", doc: "CSS class for parent div")
  attr(:heading, :string, default: nil, doc: "label your heading")
  attr(:label, :string, default: nil, doc: "label your alert")
  attr(:rest, :global)

  attr(:close_button_properties, :list,
    default: nil,
    doc: "a list of properties passed to the close button"
  )

  slot(:inner_block)

  def alert(assigns) do
    assigns =
      assigns
      |> assign(:classes, alert_classes(assigns))

    ~H"""
    <%= unless label_blank?(@label, @inner_block) do %>
      <div {@rest} class={@classes}>
        <%= if @with_icon do %>
          <div class="self-start flex-shrink-0 pt-0.5 w-6 h-6">
            <.get_icon color={@color} />
          </div>
        <% end %>

        <div class="w-full flex-0">
          <div class="flex items-start justify-between">
            <div>
              <%= if @heading do %>
                <div class="pt-1 font-bold">
                  <%= @heading %>
                </div>
              <% end %>

              <div class="py-1 font-medium">
                <%= render_slot(@inner_block) || @label %>
              </div>
            </div>

            <%= if @close_button_properties do %>
              <button
                class={
                  build_class(["p-2 mouse-hover flex hover:rounded", get_dismiss_icon_classes(@color)])
                }
                {@close_button_properties}
              >
                <Heroicons.x_mark solid class="self-start w-4 h-4" />
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

    build_class([base_classes, color_css, custom_classes])
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

  defp get_icon(%{color: "info"} = assigns) do
    ~H"""
    <Heroicons.information_circle />
    """
  end

  defp get_icon(%{color: "success"} = assigns) do
    ~H"""
    <Heroicons.check_circle />
    """
  end

  defp get_icon(%{color: "warning"} = assigns) do
    ~H"""
    <Heroicons.exclamation_circle />
    """
  end

  defp get_icon(%{color: "danger"} = assigns) do
    ~H"""
    <Heroicons.x_circle />
    """
  end

  defp label_blank?(label, inner_block) do
    (!label || label == "") && inner_block == []
  end
end
