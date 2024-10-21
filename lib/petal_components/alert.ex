defmodule PetalComponents.Alert do
  use Phoenix.Component
  alias PetalComponents.Helpers
  import PetalComponents.Icon

  attr(:color, :string,
    default: "info",
    values: ["info", "success", "warning", "danger"]
  )

  attr(:variant, :string,
    default: "light",
    values: ["light", "soft", "dark", "outline"],
    doc: "The variant of the alert"
  )

  attr(:with_icon, :boolean, default: false, doc: "adds some icon base classes")
  attr(:class, :any, default: nil, doc: "CSS class for parent div")
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
      |> assign(:heading_id, Helpers.uniq_id(assigns.heading || "alert-heading"))
      |> assign(:label_id, Helpers.uniq_id(assigns.label || "alert-label"))

    ~H"""
    <%= unless label_blank?(@label, @inner_block) do %>
      <div
        {@rest}
        class={@classes}
        role="dialog"
        aria-labelledby={(@heading && @heading_id) || @label_id}
        aria-describedby={@label_id}
      >
        <%= if @with_icon do %>
          <div class="pc-alert__icon-container">
            <.get_icon color={@color} />
          </div>
        <% end %>

        <div class="pc-alert">
          <div class="pc-alert__inner">
            <div>
              <%= if @heading do %>
                <h2 id={@heading_id} class="pc-alert__heading">
                  <%= @heading %>
                </h2>
              <% end %>

              <div id={@label_id} class="pc-alert__label">
                <%= render_slot(@inner_block) || @label %>
              </div>
            </div>

            <%= if @close_button_properties do %>
              <button
                class={["pc-alert__dismiss-button", get_dismiss_icon_classes(@color, @variant)]}
                {@close_button_properties}
              >
                <.icon name="hero-x-mark-solid" class="self-start w-4 h-4" />
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
      variant: opts[:variant] || "light",
      class: opts[:class] || ""
    }

    base_classes = "pc-alert-base-classes"
    color_css = get_color_classes(opts.color, opts.variant)
    custom_classes = opts.class

    [base_classes, color_css, custom_classes]
  end

  defp get_color_classes(color, variant) do
    "pc-alert--#{color}-#{variant}"
  end

  defp get_dismiss_icon_classes(color, variant) do
    "pc-alert__dismiss-button--#{color}-#{variant}"
  end

  defp get_icon(%{color: "info"} = assigns) do
    ~H"""
    <.icon name="hero-information-circle" />
    """
  end

  defp get_icon(%{color: "success"} = assigns) do
    ~H"""
    <.icon name="hero-check-circle" />
    """
  end

  defp get_icon(%{color: "warning"} = assigns) do
    ~H"""
    <.icon name="hero-exclamation-circle" />
    """
  end

  defp get_icon(%{color: "danger"} = assigns) do
    ~H"""
    <.icon name="hero-x-circle" />
    """
  end

  defp label_blank?(label, inner_block) do
    (!label || label == "") && inner_block == []
  end
end
