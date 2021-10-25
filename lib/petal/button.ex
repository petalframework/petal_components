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
    color = opts[:color] || "primary"
    size = opts[:size] || "md"
    style = opts[:style] || "outline"

    color_css =
      case color do
        "primary" ->
          "border-transparent text-white bg-primary-600 active:bg-primary-700 hover:bg-primary-500 focus:border-primary-700 focus:shadow-outline-blue"

        "secondary" ->
          "border-transparent text-white bg-secondary-600 active:bg-secondary-700 hover:bg-secondary-500 focus:border-secondary-700 focus:shadow-outline-blue"

        "white" ->
          "border-gray-300 hover:text-gray-500 focus:outline-none focus:border-blue-300 focus:shadow-outline-blue active:bg-gray-50 active:text-gray-800"

        "green" ->
          "border-transparent text-white bg-green-600 active:bg-green-700 hover:bg-green-500 focus:border-green-700 focus:shadow-outline-green"

        "gray" ->
          "border-transparent text-white bg-gray-600 active:bg-gray-700 hover:bg-gray-500 focus:border-gray-700 focus:shadow-outline-gray"

        "gray-light" ->
          "border-transparent text-gray-800 bg-gray-300 active:bg-gray-400 hover:bg-gray-400 focus:border-gray-400 focus:shadow-outline-gray"

        "blue" ->
          "border-transparent text-white bg-blue-600 active:bg-blue-700 hover:bg-blue-500 focus:border-blue-700 focus:shadow-outline-blue"

        "pink" ->
          "border-transparent text-white bg-pink-600 active:bg-pink-700 hover:bg-pink-500 focus:border-pink-700 focus:shadow-outline-pink"

        "purple" ->
          "border-transparent text-white bg-purple-600 active:bg-purple-700 hover:bg-purple-500 focus:border-purple-700 focus:shadow-outline-purple"

        "orange" ->
          "border-transparent text-white bg-orange-600 active:bg-orange-700 hover:bg-orange-500 focus:border-orange-700 focus:shadow-outline-orange"

        "red" ->
          "border-transparent text-white bg-red-600 active:bg-red-700 hover:bg-red-500 focus:border-red-700 focus:shadow-outline-red"

        "yellow-light" ->
          "border-transparent text-gray-900 bg-yellow-300 active:bg-yellow-200 hover:bg-yellow-200 focus:border-yellow-200 focus:shadow-outline-yellow"

        "deep-red" ->
          "border-transparent text-white bg-red-800 active:bg-red-900 hover:bg-red-700 focus:border-red-900 focus:shadow-outline-red"
      end

    size_css =
      case size do
        "xs" -> "text-xs leading-4 px-2.5 py-1.5"
        "sm" -> "text-sm leading-4 px-3 py-2"
        "md" -> "text-sm leading-5 px-4 py-2"
        "lg" -> "text-base leading-6 px-4 py-2"
        "xl" -> "text-base leading-6 px-6 py-3"
      end

    style_css =
      case style do
        "outline" ->
          "border text-white active:bg-primary-700 hover:bg-primary-200 focus:border-primary-700 focus:shadow-outline-blue"
      end

    """
      #{color_css}
      #{size_css} font-medium
      #{style_css}
      disabled:opacity-50
      shadow-sm
      rounded-md
      inline-flex items-center justify-center
      border
      focus:outline-none
      transition duration-150 ease-in-out
    """
  end
end
