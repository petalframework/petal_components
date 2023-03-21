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
          <div class="pc-alert__icon-container">
            <.get_icon color={@color} />
          </div>
        <% end %>

        <div class="pc-alert">
          <div class="pc-alert__inner">
            <div>
              <%= if @heading do %>
                <div class="pc-alert__heading">
                  <%= @heading %>
                </div>
              <% end %>

              <div class="pc-alert__label">
                <%= render_slot(@inner_block) || @label %>
              </div>
            </div>

            <%= if @close_button_properties do %>
              <button
                class={build_class(["pc-alert__dismiss-button", get_dismiss_icon_classes(@color)])}
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

    base_classes = "pc-alert-base-classes"
    color_css = get_color_classes(opts.color)
    custom_classes = opts.class

    build_class([base_classes, color_css, custom_classes])
  end

  defp get_color_classes("info"),
    do: "pc-alert--info"

  defp get_color_classes("success"),
    do: "pc-alert--success"

  defp get_color_classes("warning"),
    do: "pc-alert--warning"

  defp get_color_classes("danger"),
    do: "pc-alert--danger"

  defp get_dismiss_icon_classes("info"),
    do: "pc-alert__dismiss-button--info"

  defp get_dismiss_icon_classes("success"),
    do: "pc-alert__dismiss-button--success"

  defp get_dismiss_icon_classes("warning"),
    do: "pc-alert__dismiss-button--warning"

  defp get_dismiss_icon_classes("danger"),
    do: "pc-alert__dismiss-button--danger"

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
