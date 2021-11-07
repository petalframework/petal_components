defmodule PetalComponents.Badge do
  use Phoenix.Component

  # prop label, :string
  # prop size, :string, options: ["xs", "sm", "md", "lg", "xl"]
  # prop color, :string, options: ["primary", "secondary", "white", "black", "green", "red", "blue", "gray", "gray-light", "pink", "purple", "orange", "yellow"]
  def badge(assigns) do
    assigns = assign_new(assigns, :classes, fn ->
      badge_classes(assigns)
    end)

    ~H"""
    <badge class={@classes}>
      <%= @label %>
    </badge>
    """
  end

  def badge_classes(opts \\ %{}) do
    opts = %{
      size: opts[:size] || "sm",
      color: opts[:color] || "primary"
    }

    size_css =
      case opts[:size] do
        "xs" -> "text-xs leading-4 px-2.5 py-1"
        "sm" -> "text-sm leading-4 px-2.5 py-1"
        "md" -> "text-sm leading-5 px-4 py-2"
        "lg" -> "text-base leading-6 px-4 py-2"
        "xl" -> "text-base leading-6 px-6 py-3"
      end

    color_css = get_color_classes(opts)

    """
      #{color_css}
      #{size_css}
      font-medium
      rounded-lg
      inline-flex items-center justify-center
      focus:outline-none
    """
  end

  def get_color_classes(%{color: "primary"}) do
    "text-primary-800 bg-primary-100"
  end

  def get_color_classes(%{color: "secondary"}) do
    "text-secondary-800 bg-secondary-100"
  end

  def get_color_classes(%{color: "white"}) do
    "text-white-800 bg-white-100"
  end

  def get_color_classes(%{color: "black"}) do
    "text-white bg-black"
  end

  def get_color_classes(%{color: "green"}) do
    "text-green-800 bg-green-100"
  end

  def get_color_classes(%{color: "red"}) do
    "text-red-800 bg-red-100"
  end

  def get_color_classes(%{color: "blue"}) do
    "text-blue-800 bg-blue-100"
  end

  def get_color_classes(%{color: "gray"}) do
    "text-gray-800 bg-gray-100"
  end

  def get_color_classes(%{color: "gray-light"}) do
    "text-gray-500 bg-gray-100"
  end

  def get_color_classes(%{color: "pink"}) do
    "text-pink-800 bg-pink-100"
  end

  def get_color_classes(%{color: "purple"}) do
    "text-purple-800 bg-purple-100"
  end

  def get_color_classes(%{color: "orange"}) do
    "text-yellow-600 bg-yellow-100"
  end

  def get_color_classes(%{color: "yellow"}) do
    "text-yellow-800 bg-yellow-100"
  end
end
