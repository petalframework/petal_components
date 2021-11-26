defmodule PetalComponents.Button do
  use Phoenix.Component
  alias PetalComponents.Loading
  import PetalComponents.Link

  # <.button link_type="button|a|live_patch|live_redirect" />
  # prop label, :string
  # prop size, :string
  # prop loading, :boolean, default: false
  # prop disabled, :boolean, default: false
  # slot default
  def button(assigns) do
    assigns = assign_defaults(assigns)

    ~H"""
    <%= if @link_type == "button" do %>
      <button class={@classes} disabled={@disabled} {@button_opts}>
        <%= if @loading do %>
          <Loading.spinner show={true} size_class={get_spinner_classes(@size)} />
        <% end %>

        <%= if @inner_block do %>
          <%= render_slot(@inner_block) %>
        <% else %>
          <%= @label %>
        <% end %>
      </button>

    <% else %>
      <.link to={@to} link_type={@link_type} class={@classes} disabled={@disabled} {@button_opts}>
        <%= if @loading do %>
          <Loading.spinner show={true} size_class={get_spinner_classes(@size)} />
        <% end %>

        <%= if @inner_block do %>
          <%= render_slot(@inner_block) %>
        <% else %>
          <%= @label %>
        <% end %>
      </.link>
    <% end %>
    """
  end

  defp assign_defaults(assigns) do
    assigns
    |> assign_new(:link_type, fn -> "button" end)
    |> assign_new(:inner_block, fn -> nil end)
    |> assign_new(:loading, fn -> false end)
    |> assign_new(:disabled, fn -> false end)
    |> assign_new(:button_opts, fn -> get_button_opts(assigns) end)
    |> assign_new(:classes, fn -> button_classes(assigns) end)
  end

  defp button_classes(opts) do
    opts = %{
      size: opts[:size] || "md",
      variant: opts[:variant] || "solid",
      color: opts[:color] || "primary",
      loading: opts[:loading] || false,
      disabled: opts[:disabled] || false,
      icon: opts[:icon] || false
    }

    color_css = get_color_classes(opts)

    size_css =
      case opts[:size] do
        "xs" -> "text-xs leading-4 px-2.5 py-1.5"
        "sm" -> "text-sm leading-4 px-3 py-2"
        "md" -> "text-sm leading-5 px-4 py-2"
        "lg" -> "text-base leading-6 px-4 py-2"
        "xl" -> "text-base leading-6 px-6 py-3"
      end

    loading_css =
      if opts[:loading] do
        "flex gap-2 items-center whitespace-nowrap disabled cursor-not-allowed"
      else
        ""
      end

    disabled_css =
      if opts[:disabled] do
        "disabled cursor-not-allowed opacity-50"
      else
        ""
      end

    icon_css =
      if opts[:icon] do
        "flex gap-2 items-center whitespace-nowrap"
      else
        ""
      end

    """
      #{color_css}
      #{size_css}
      #{loading_css}
      #{disabled_css}
      #{icon_css}
      font-medium
      shadow-sm
      rounded-md
      inline-flex items-center justify-center
      border
      focus:outline-none
      transition duration-150 ease-in-out
    """
  end

  defp get_button_opts(assigns) do
    Map.drop(assigns, [
      :loading,
      :disabled,
      :link_type,
      :inner_block,
      :size,
      :variant,
      :color,
      :icon,
      :__changed__
    ])
  end

  defp get_color_classes(%{color: "primary", variant: variant}) do
    case variant do
      "outline" ->
        "border-primary-400 hover:border-primary-600 text-primary-600 hover:text-primary-700 active:bg-primary-200 hover:bg-primary-50 focus:border-primary-700 focus:shadow-outline-primary"

      _ ->
        "border-transparent text-white bg-primary-600 active:bg-primary-700 hover:bg-primary-700 focus:bg-primary-700 active:bg-primary-800 focus:shadow-outline-primary"
    end
  end

  defp get_color_classes(%{color: "secondary", variant: variant}) do
    case variant do
      "outline" ->
        "border-secondary-400 hover:border-secondary-600 text-secondary-600 hover:text-secondary-700 active:bg-secondary-200 hover:bg-secondary-50 focus:border-secondary-700 focus:shadow-outline-secondary"

      _ ->
        "border-transparent text-white bg-secondary-600 active:bg-secondary-700 hover:bg-secondary-700 focus:bg-secondary-700 active:bg-secondary-800 focus:shadow-outline-secondary"
    end
  end

  defp get_color_classes(%{color: "white", variant: variant}) do
    case variant do
      "outline" ->
        "border-gray-400 hover:border-gray-500 text-gray-600 hover:text-gray-700 active:bg-gray-100 hover:bg-gray-50 focus:bg-gray-50 focus:border-gray-500 active:border-gray-600"

      _ ->
        "text-gray-700 border-gray-300 hover:text-gray-900 hover:text-gray-900 hover:border-gray-400 hover:bg-gray-50 focus:outline-none focus:border-gray-400 focus:bg-gray-100 focus:text-gray-900 active:border-gray-400 active:bg-gray-200 active:text-black"
    end
  end

  defp get_color_classes(%{color: "success", variant: variant}) do
    case variant do
      "outline" ->
        "border-green-400 hover:border-green-500 text-green-500 hover:text-green-600 active:border-green-600 focus:text-green-600 active:text-green-700 active:bg-green-100 hover:bg-green-50 focus:border-green-500"

      _ ->
        "border-transparent text-white bg-green-500 active:bg-green-700 hover:bg-green-600 active:bg-green-700 focus:bg-green-600"
    end
  end

  defp get_color_classes(%{color: "danger", variant: variant}) do
    case variant do
      "outline" ->
        "border-red-400 hover:border-red-600 text-red-600 hover:text-red-700 active:bg-red-200 active:border-red-700 hover:bg-red-50 focus:border-red-600"

      _ ->
        "border-transparent text-white bg-red-500 active:bg-red-700 hover:bg-red-600 active:bg-green-700 focus:bg-red-600"
    end
  end

  defp get_spinner_classes("xs"), do: "h-3 w-3"
  defp get_spinner_classes("sm"), do: "h-4 w-4"
  defp get_spinner_classes("md"), do: "h-5 w-5"
  defp get_spinner_classes("lg"), do: "h-5 w-5"
  defp get_spinner_classes("xl"), do: "h-6 w-6"
end
