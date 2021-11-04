defmodule PetalComponents.Button do
  use Phoenix.Component

  def button(assigns) do
    assigns = get_extra_attributes(assigns)

    ~H"""
    <button class={button_classes(assigns)} disabled={assigns[:disabled]} {@extra_attributes}>
      <%= if assigns[:loading] do %>
        <svg
          class="w-5 h-5 animate-spin"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
          <path
            class="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          />
        </svg>
      <% end %>

      <%= if assigns[:inner_block] do %>
        <%= render_slot(@inner_block) %>
      <% else %>
        <%= @label %>
      <% end %>
    </button>
    """
  end

  def a(assigns) do
    assigns = get_extra_attributes(assigns)

    ~H"""
    <a href={@href} class={button_classes(assigns)} onclick={if assigns[:disabled] || assigns[:loading], do: "return false;", else: nil} {@extra_attributes}>
      <%= if assigns[:loading] do %>
        <svg
          class="w-5 h-5 animate-spin"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
          <path
            class="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          />
        </svg>
      <% end %>

      <%= if assigns[:inner_block] do %>
        <%= render_slot(@inner_block) %>
      <% else %>
        <%= @label %>
      <% end %>
    </a>
    """
  end

  def patch(assigns) do
    assigns = get_extra_attributes(assigns)

    ~H"""
    <%= live_patch [
      to: @href,
      class: button_classes(assigns),
      onclick: (if assigns[:disabled] || assigns[:loading], do: "return false;", else: nil)
    ] ++ Map.to_list(assigns.extra_attributes) do %>
      <%= if assigns[:loading] do %>
        <svg
          class="w-5 h-5 animate-spin"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
          <path
            class="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          />
        </svg>
      <% end %>

      <%= if assigns[:inner_block] do %>
        <%= render_slot(@inner_block) %>
      <% else %>
        <%= @label %>
      <% end %>
    <% end %>
    """
  end

  def redirect(assigns) do
    assigns = get_extra_attributes(assigns)

    ~H"""
    <%= live_redirect [
      to: @href,
      class: button_classes(assigns),
      onclick: (if assigns[:disabled] || assigns[:loading], do: "return false;", else: nil)
     ] ++ Map.to_list(assigns.extra_attributes) do %>
      <%= if assigns[:loading] do %>
        <svg
          class="w-5 h-5 animate-spin"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
          <path
            class="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          />
        </svg>
      <% end %>

      <%= if assigns[:inner_block] do %>
        <%= render_slot(@inner_block) %>
      <% else %>
        <%= @label %>
      <% end %>
    <% end %>
    """
  end

  def button_classes(opts \\ %{}) do
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

  def get_extra_attributes(assigns) do
    assign_new(assigns, :extra_attributes, fn ->
      Map.drop(assigns, [
        :loading,
        :disabled,
        :inner_block,
        :size,
        :variant,
        :color,
        :icon,
        :__changed__
      ])
    end)
  end

  def get_color_classes(%{color: "primary", variant: variant}) do
    case variant do
      "outline" ->
        "border-primary-400 hover:border-primary-600 text-primary-600 hover:text-primary-700 active:bg-primary-200 hover:bg-primary-50 focus:border-primary-700 focus:shadow-outline-primary"

      _ ->
        "border-transparent text-white bg-primary-600 active:bg-primary-700 hover:bg-primary-700 focus:bg-primary-700 active:bg-primary-800 focus:shadow-outline-primary"
    end
  end

  def get_color_classes(%{color: "secondary", variant: variant}) do
    case variant do
      "outline" ->
        "border-secondary-400 hover:border-secondary-600 text-secondary-600 hover:text-secondary-700 active:bg-secondary-200 hover:bg-secondary-50 focus:border-secondary-700 focus:shadow-outline-secondary"

      _ ->
        "border-transparent text-white bg-secondary-600 active:bg-secondary-700 hover:bg-secondary-700 focus:bg-secondary-700 active:bg-secondary-800 focus:shadow-outline-secondary"
    end
  end

  def get_color_classes(%{color: "white", variant: variant}) do
    case variant do
      "outline" ->
        "border-gray-400 hover:border-gray-500 text-gray-600 hover:text-gray-700 active:bg-gray-100 hover:bg-gray-50 focus:bg-gray-50 focus:border-gray-500 active:border-gray-600"

      _ ->
        "text-gray-700 border-gray-300 hover:text-gray-900 hover:text-gray-900 hover:border-gray-400 hover:bg-gray-50 focus:outline-none focus:border-gray-400 focus:bg-gray-100 focus:text-gray-900 active:border-gray-400 active:bg-gray-200 active:text-black"
    end
  end

  def get_color_classes(%{color: "success", variant: variant}) do
    case variant do
      "outline" ->
        "border-green-400 hover:border-green-500 text-green-500 hover:text-green-600 active:border-green-600 focus:text-green-600 active:text-green-700 active:bg-green-100 hover:bg-green-50 focus:border-green-500"

      _ ->
        "border-transparent text-white bg-green-500 active:bg-green-700 hover:bg-green-600 active:bg-green-700 focus:bg-green-600"
    end
  end

  def get_color_classes(%{color: "danger", variant: variant}) do
    case variant do
      "outline" ->
        "border-red-400 hover:border-red-600 text-red-600 hover:text-red-700 active:bg-red-200 active:border-red-700 hover:bg-red-50 focus:border-red-600"

      _ ->
        "border-transparent text-white bg-red-500 active:bg-red-700 hover:bg-red-600 active:bg-green-700 focus:bg-red-600"
    end
  end
end
