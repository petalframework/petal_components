defmodule PetalComponents.Badge do
  use Phoenix.Component

  # prop label, :string
  # prop size, :string, options: ["xs", "sm", "md", "lg", "xl"]
  # prop variant, :string
  # prop color, :string, options: ["primary", "secondary", "info", "success", "warning", "danger", "gray"]
  # prop class, :css_class
  def badge(assigns) do
    assigns = assigns
      |> assign_new(:size, fn -> "sm" end)
      |> assign_new(:variant, fn -> "light" end)
      |> assign_new(:color, fn -> "primary" end)
      |> assign_new(:class, fn -> "" end)

    ~H"""
    <badge class={Enum.join([
      "font-medium rounded-lg inline-flex items-center justify-center focus:outline-none border",
      size_classes(@size),
      get_color_classes(%{color: @color, variant: @variant}),
      @class
    ], " ")}>
      <%= @label %>
    </badge>
    """
  end

  defp size_classes(size) do
    case size do
      "xs" -> "text-xs leading-4 px-2.5 py-1"
      "sm" -> "text-sm leading-4 px-2.5 py-1"
      "md" -> "text-sm leading-5 px-4 py-2"
      "lg" -> "text-base leading-6 px-4 py-2"
      "xl" -> "text-base leading-6 px-6 py-3"
    end
  end

  defp get_color_classes(%{color: "primary", variant: variant}) do
    case variant do
      "light" ->
        "text-primary-600 bg-primary-100 border-primary-100"

      "dark" ->
        "text-white bg-primary-600 border-primary-600"

      "outline" ->
        "text-primary-600 border-primary-600 dark:text-primary-400 dark:border-primary-400"
    end
  end

  defp get_color_classes(%{color: "secondary", variant: variant}) do
    case variant do
      "light" ->
        "text-secondary-600 bg-secondary-100 border-secondary-100"

      "dark" ->
        "text-white bg-secondary-600 border-secondary-600"

      "outline" ->
        "text-secondary-600 border border-secondary-600  dark:text-secondary-400 dark:border-secondary-400"
    end
  end

  defp get_color_classes(%{color: "info", variant: variant}) do
    case variant do
      "light" ->
        "text-blue-600 bg-blue-100 border-blue-100"

      "dark" ->
        "text-white bg-blue-600 border-blue-600"

      "outline" ->
        "text-blue-600 border border-blue-600 dark:text-blue-400 dark:border-blue-400"
    end
  end

  defp get_color_classes(%{color: "success", variant: variant}) do
    case variant do
      "light" ->
        "text-green-600 bg-green-100 border-green-100"

      "dark" ->
        "text-white bg-green-600 border-green-600"

      "outline" ->
        "text-green-600 border border-green-600 dark:text-green-400 dark:border-green-400"
    end
  end

  defp get_color_classes(%{color: "warning", variant: variant}) do
    case variant do
      "light" ->
        "text-yellow-600 bg-yellow-100 border-yellow-100"

      "dark" ->
        "text-white bg-yellow-600 border-yellow-600"

      "outline" ->
        "text-yellow-600 border border-yellow-600 dark:text-yellow-400 dark:border-yellow-400"
    end
  end

  defp get_color_classes(%{color: "danger", variant: variant}) do
    case variant do
      "light" ->
        "text-red-600 bg-red-100 border-red-100"

      "dark" ->
        "text-white bg-red-600 border-red-600"

      "outline" ->
        "text-red-600 border border-red-600 dark:text-red-400 dark:border-red-400"
    end
  end

  defp get_color_classes(%{color: "gray", variant: variant}) do
    case variant do
      "light" ->
        "text-gray-600 bg-gray-100 border-gray-100 dark:text-gray-400 dark:border-transparent"

      "dark" ->
        "text-white bg-gray-600 border-gray-600"

      "outline" ->
        "text-gray-600 border border-gray-600 dark:text-gray-400 dark:border-gray-400"
    end
  end
end
