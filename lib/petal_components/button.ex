defmodule PetalComponents.Button do
  use Phoenix.Component
  alias PetalComponents.Loading
  import PetalComponents.Link

  # <.button link_type="button|a|live_patch|live_redirect" />
  # prop class, :string
  # prop label, :string
  # prop size, :string
  # prop variant, :string
  # prop loading, :boolean, default: false
  # prop disabled, :boolean, default: false
  # slot default
  def button(assigns) do
    assigns = assign_defaults(assigns)

    ~H"""
    <%= if @link_type == "button" do %>
      <button class={@classes} disabled={@disabled} {@extra_assigns}>
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
      <.link to={@to} link_type={@link_type} class={@classes} disabled={@disabled} {@extra_assigns}>
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
    |> assign_new(:size, fn -> "md" end)
    |> assign_new(:disabled, fn -> false end)
    |> assign_new(:extra_assigns, fn -> get_extra_assigns(assigns) end)
    |> assign_new(:classes, fn -> button_classes(assigns) end)
    |> assign_new(:class, fn -> "" end)
  end

  defp button_classes(opts) do
    opts = %{
      size: opts[:size] || "md",
      variant: opts[:variant] || "solid",
      color: opts[:color] || "primary",
      loading: opts[:loading] || false,
      disabled: opts[:disabled] || false,
      icon: opts[:icon] || false,
      user_added_classes: opts[:class] || ""
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
      #{opts.user_added_classes}
      #{color_css}
      #{size_css}
      #{loading_css}
      #{disabled_css}
      #{icon_css}
      font-medium
      rounded-md
      inline-flex items-center justify-center
      border
      focus:outline-none
      transition duration-150 ease-in-out
    """
    |> PetalComponents.Helpers.convert_string_to_one_line()
  end

  defp get_extra_assigns(assigns) do
    assigns_to_attributes(assigns, [
      :loading,
      :disabled,
      :link_type,
      :size,
      :variant,
      :color,
      :icon,
      :class
    ])
  end

  defp get_color_classes(%{color: "primary", variant: variant}) do
    case variant do
      "outline" ->
        "border-primary-400 dark:border-primary-400 dark:hover:border-primary-300 dark:hover:text-primary-300 dark:hover:bg-transparent dark:text-primary-400 hover:border-primary-600 text-primary-600 hover:text-primary-700 active:bg-primary-200 hover:bg-primary-50 focus:border-primary-700 focus:shadow-outline-primary"

      "shadow" ->
        "shadow-xl border-transparent text-white bg-primary-600 active:bg-primary-700 hover:bg-primary-700 focus:bg-primary-700 active:bg-primary-800 focus:shadow-outline-primary shadow-primary-500/30 dark:hover:shadow-primary-600/30 dark:focus:shadow-primary-600/30 dark:active:shadow-primary-700/30"

      _ ->
        "border-transparent text-white bg-primary-600 active:bg-primary-700 hover:bg-primary-700 focus:bg-primary-700 active:bg-primary-800 focus:shadow-outline-primary"
    end
  end

  defp get_color_classes(%{color: "secondary", variant: variant}) do
    case variant do
      "outline" ->
        "border-secondary-400 dark:border-secondary-400 dark:hover:border-secondary-300 dark:hover:text-secondary-300 dark:hover:bg-transparent dark:text-secondary-400 hover:border-secondary-600 text-secondary-600 hover:text-secondary-700 active:bg-secondary-200 hover:bg-secondary-50 focus:border-secondary-700 focus:shadow-outline-secondary"

      "shadow" ->
        "shadow-xl border-transparent text-white bg-secondary-600 active:bg-secondary-700 hover:bg-secondary-700 focus:bg-secondary-700 active:bg-secondary-800 focus:shadow-outline-secondary shadow-secondary-500/30 dark:hover:shadow-secondary-600/30 dark:focus:shadow-secondary-600/30 dark:active:shadow-secondary-700/30"

      _ ->
        "border-transparent text-white bg-secondary-600 active:bg-secondary-700 hover:bg-secondary-700 focus:bg-secondary-700 active:bg-secondary-800 focus:shadow-outline-secondary"
    end
  end

  defp get_color_classes(%{color: "white", variant: variant}) do
    case variant do
      "outline" ->
        "border-gray-400 dark:border-gray-300 dark:hover:border-gray-200 dark:hover:text-gray-200 dark:hover:bg-transparent dark:text-gray-300 hover:border-gray-600 text-gray-600 hover:text-gray-700 active:bg-gray-100 hover:bg-gray-50 focus:bg-gray-50 focus:border-gray-500 active:border-gray-600"

      "shadow" ->
        "shadow-xl text-gray-700 bg-white border-gray-300 hover:text-gray-900 hover:text-gray-900 hover:border-gray-400 hover:bg-gray-50 focus:outline-none focus:border-gray-400 focus:bg-gray-100 focus:text-gray-900 active:border-gray-400 active:bg-gray-200 dark:bg-white dark:hover:bg-gray-200 dark:hover:border-transparent dark:border-transparent active:text-black shadow-gray-500/30 dark:shadow-gray-200/30 dark:hover:shadow-gray-300/30 dark:focus:shadow-gray-300/30 dark:active:shadow-gray-400/30"

      _ ->
        "text-gray-700 bg-white border-transparent border-gray-300 hover:text-gray-900 hover:text-gray-900 hover:border-gray-400 hover:bg-gray-50 focus:outline-none focus:border-gray-400 focus:bg-gray-100 focus:text-gray-900 active:border-gray-400 active:bg-gray-200 active:text-black dark:bg-white dark:hover:bg-gray-200 dark:hover:border-transparent dark:border-transparent"
    end
  end

  defp get_color_classes(%{color: "pure_white", variant: variant}) do
    case variant do
      _ ->
        "text-gray-700 bg-white border-transparent border-white hover:text-gray-900 hover:text-gray-900 hover:border-transparent hover:bg-gray-50 focus:outline-none focus:border-transparent focus:bg-gray-100 focus:text-gray-900 active:border-transparent active:bg-gray-200 active:text-black dark:bg-white dark:hover:bg-gray-200 dark:hover:border-transparent dark:border-transparent"
    end
  end

  defp get_color_classes(%{color: "success", variant: variant}) do
    case variant do
      "outline" ->
        "border-green-400 dark:border-green-400 dark:hover:border-green-300 dark:hover:text-green-300 dark:hover:bg-transparent dark:text-green-400 hover:border-green-600 text-green-600 hover:text-green-700 active:border-green-600 focus:text-green-600 active:text-green-700 active:bg-green-100 hover:bg-green-50 focus:border-green-700"

      "shadow" ->
        "shadow-xl border-transparent text-white bg-green-600 active:bg-green-700 hover:bg-green-700 focus:bg-green-700 active:bg-green-800 focus:shadow-outline-green shadow-green-500/30 dark:hover:shadow-green-600/30 dark:focus:shadow-green-600/30 dark:active:shadow-green-700/30"

      _ ->
        "border-transparent text-white bg-green-600 active:bg-green-700 hover:bg-green-700 active:bg-green-700 focus:bg-green-700"
    end
  end

  defp get_color_classes(%{color: "danger", variant: variant}) do
    case variant do
      "outline" ->
        "border-red-400 dark:border-red-400 dark:hover:border-red-300 dark:hover:text-red-300 dark:hover:bg-transparent dark:text-red-400 hover:border-red-600 text-red-600 hover:text-red-700 active:bg-red-200 active:border-red-700 hover:bg-red-50 focus:border-red-700"

      "shadow" ->
        "shadow-xl border-transparent text-white bg-red-600 active:bg-red-700 hover:bg-red-700 focus:bg-red-700 active:bg-red-800 focus:shadow-outline-red shadow-red-500/30 dark:hover:shadow-red-600/30 dark:focus:shadow-red-600/30 dark:active:shadow-red-700/30"

      _ ->
        "border-transparent text-white bg-red-600 active:bg-red-700 hover:bg-red-700 active:bg-green-700 focus:bg-red-700"
    end
  end

  defp get_spinner_classes("xs"), do: "h-3 w-3"
  defp get_spinner_classes("sm"), do: "h-4 w-4"
  defp get_spinner_classes("md"), do: "h-5 w-5"
  defp get_spinner_classes("lg"), do: "h-5 w-5"
  defp get_spinner_classes("xl"), do: "h-6 w-6"
end
