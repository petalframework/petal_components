defmodule Petal.Button do
  use Phoenix.Component

  # <Button.render type="a" />
  # <Button.render type="a" />
  # <Button.render type="button" />
  def render(%{type: "button"} = assigns) do
    button(assigns)
  end

  def render(%{type: "live_patch"} = assigns) do
    patch(assigns)
  end

  def render(%{type: "live_redirect"} = assigns) do
    redirect(assigns)
  end

  def render(%{type: "a"} = assigns) do
    a(assigns)
  end

  def button(assigns) do
    ~H"""
    <button class={button_classes(assigns)}>
      <%= @label %>
    </button>
    """
  end

  def a(assigns) do
    ~H"""
    <a href={@href} class={button_classes(assigns)}>
      <%= @label %>
    </a>
    """
  end

  def patch(assigns) do
    ~H"""
    <%= live_patch @label, to: @href, class: button_classes(assigns) %>
    """
  end

  def redirect(assigns) do
    ~H"""
    <%= live_redirect @label, to: @href, class: button_classes(assigns) %>
    """
  end

  def button_classes(opts \\ %{}) do
    opts = %{
      size: opts[:size] || "md",
      variant: opts[:variant] || "solid",
      color: opts[:color] || "primary"
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

    """
      #{color_css}
      #{size_css} font-medium
      disabled:opacity-50
      shadow-sm
      rounded-md
      inline-flex items-center justify-center
      border
      focus:outline-none
      transition duration-150 ease-in-out
    """
  end

  def get_color_classes(%{color: "primary", variant: variant}) do
    case variant do
      "outline" ->
        "border-primary-400 hover:border-primary-600 text-primary-600 hover:text-primary-700 active:bg-primary-200 hover:bg-primary-50 focus:border-primary-700 focus:shadow-outline-primary"

      _ ->
        "border-transparent text-white bg-primary-600 active:bg-primary-700 hover:bg-primary-500 focus:border-primary-700 focus:shadow-outline-primary"
    end
  end

  def get_color_classes(%{color: "secondary", variant: variant}) do
    case variant do
      "outline" ->
        "border-secondary-400 hover:border-secondary-600 text-secondary-600 hover:text-secondary-700 active:bg-secondary-200 hover:bg-secondary-50 focus:border-secondary-700 focus:shadow-outline-secondary"

      _ ->
        "border-transparent text-white bg-secondary-600 active:bg-secondary-700 hover:bg-secondary-500 focus:border-secondary-700 focus:shadow-outline-secondary"
    end
  end

  def get_color_classes(%{color: "white", variant: variant}) do
    case variant do
      "outline" ->
        "border-gray-300 hover:border-gray-500 text-gray-600 hover:text-gray-700 active:bg-gray-100 hover:bg-gray-50 focus:border-gray-600 focus:shadow-outline-gray"

      _ ->
        "border-gray-300 hover:text-gray-500 focus:outline-none focus:border-gray-300 focus:shadow-outline-gray active:bg-gray-50 active:text-gray-800"
    end
  end

  def get_color_classes(%{color: "green", variant: variant}) do
    case variant do
      "outline" ->
        "border-green-400 hover:border-green-600 text-green-600 hover:text-green-700 active:bg-green-200 hover:bg-green-50 focus:border-green-700 focus:shadow-outline-green"

      _ ->
        "border-transparent text-white bg-green-600 active:bg-green-700 hover:bg-green-500 focus:border-green-700 focus:shadow-outline-green"
    end
  end

  def get_color_classes(%{color: "gray", variant: variant}) do
    case variant do
      "outline" ->
        "border-gray-400 hover:border-gray-600 text-gray-600 hover:text-gray-700 active:bg-gray-200 hover:bg-gray-50 focus:border-gray-700 focus:shadow-outline-gray"

      _ ->
        "border-transparent text-white bg-gray-600 active:bg-gray-700 hover:bg-gray-500 focus:border-gray-700 focus:shadow-outline-gray"
    end
  end

  def get_color_classes(%{color: "gray-light", variant: variant}) do
    case variant do
      "outline" ->
        "border-gray-200 hover:border-gray-300 text-gray-400 hover:text-gray-500 active:bg-gray-100 hover:bg-gray-50 focus:border-gray-500 focus:shadow-outline-gray"

      _ ->
        "border-transparent text-gray-800 bg-gray-300 active:bg-gray-400 hover:bg-gray-400 focus:border-gray-400 focus:shadow-outline-gray"
    end
  end

  def get_color_classes(%{color: "blue", variant: variant}) do
    case variant do
      "outline" ->
        "border-blue-400 hover:border-blue-600 text-blue-600 hover:text-blue-700 active:bg-blue-200 hover:bg-blue-50 focus:border-blue-700 focus:shadow-outline-blue"

      _ ->
        "border-transparent text-white bg-blue-600 active:bg-blue-700 hover:bg-blue-500 focus:border-blue-700 focus:shadow-outline-blue"
    end
  end

  def get_color_classes(%{color: "pink", variant: variant}) do
    case variant do
      "outline" ->
        "border-pink-400 hover:border-pink-600 text-pink-600 hover:text-pink-700 active:bg-pink-200 hover:bg-pink-50 focus:border-pink-700 focus:shadow-outline-pink"

      _ ->
        "border-transparent text-white bg-pink-600 active:bg-pink-700 hover:bg-pink-500 focus:border-pink-700 focus:shadow-outline-pink"
    end
  end

  def get_color_classes(%{color: "purple", variant: variant}) do
    case variant do
      "outline" ->
        "border-purple-400 hover:border-purple-600 text-purple-600 hover:text-purple-700 active:bg-purple-200 hover:bg-purple-50 focus:border-purple-700 focus:shadow-outline-purple"

      _ ->
        "border-transparent text-white bg-purple-600 active:bg-purple-700 hover:bg-purple-500 focus:border-purple-700 focus:shadow-outline-purple"
    end
  end

  def get_color_classes(%{color: "orange", variant: variant}) do
    case variant do
      "outline" ->
        "border-yellow-400 hover:border-yellow-600 text-yellow-600 hover:text-orange-700 active:bg-yellow-200 hover:bg-yellow-50 focus:border-yellow-700 focus:shadow-outline-yellow"

      _ ->
        "border-transparent text-white bg-yellow-600 active:bg-yellow-700 hover:bg-yellow-500 focus:border-yellow-700 focus:shadow-outline-yellow"
    end
  end

  def get_color_classes(%{color: "red", variant: variant}) do
    case variant do
      "outline" ->
        "border-red-400 hover:border-red-600 text-red-600 hover:text-red-700 active:bg-red-200 hover:bg-red-50 focus:border-red-700 focus:shadow-outline-red"

      _ ->
        "border-transparent text-white bg-red-600 active:bg-red-700 hover:bg-red-500 focus:border-red-700 focus:shadow-outline-red"
    end
  end

  def get_color_classes(%{color: "yellow", variant: variant}) do
    case variant do
      "outline" ->
        "border-yellow-300 hover:border-yellow-400 text-yellow-400 hover:text-yellow-500 active:bg-yellow-100 hover:bg-yellow-50 focus:border-yellow-400 focus:shadow-outline-yellow"

      _ ->
        "border-transparent text-gray-900 bg-yellow-300 active:bg-yellow-200 hover:bg-yellow-200 focus:border-yellow-200 focus:shadow-outline-yellow"
    end
  end

  def get_color_classes(%{color: "deep-red", variant: variant}) do
    case variant do
      "outline" ->
        "border-red-700 hover:border-red-800 text-red-800 hover:text-red-900 active:bg-red-400 hover:bg-red-300 focus:border-red-900 focus:shadow-outline-red"

      _ ->
        "border-transparent text-white bg-red-800 active:bg-red-900 hover:bg-red-700 focus:border-red-900 focus:shadow-outline-red"
    end
  end
end
