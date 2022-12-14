defmodule PetalComponents.Badge do
  use Phoenix.Component
  import PetalComponents.Helpers

  attr(:size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"])
  attr(:variant, :string, default: "light", values: ["light", "dark", "outline"])

  attr(:color, :string,
    default: "primary",
    values: ["primary", "secondary", "info", "success", "warning", "danger", "gray"]
  )

  attr(:with_icon, :boolean, default: false, doc: "adds some icon base classes")
  attr(:class, :string, default: "", doc: "CSS class for parent div")
  attr(:label, :string, default: nil, doc: "label your badge")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def badge(assigns) do
    ~H"""
    <badge
      {@rest}
      class={
        build_class([
          "rounded inline-flex items-center justify-center focus:outline-none border",
          size_classes(@size),
          icon_classes(@with_icon),
          get_color_classes(%{color: @color, variant: @variant}),
          @class
        ])
      }
    >
      <%= render_slot(@inner_block) || @label %>
    </badge>
    """
  end

  defp size_classes(size) do
    case size do
      "sm" -> "text-[0.625rem] font-semibold px-1.5"
      "md" -> "text-xs font-semibold px-2.5 py-0.5"
      "lg" -> "text-sm font-semibold px-2.5 py-0.5"
    end
  end

  defp icon_classes(with_icon) do
    if with_icon do
      "flex gap-1 items-center whitespace-nowrap"
    end
  end

  defp get_color_classes(%{color: "primary", variant: variant}) do
    case variant do
      "light" ->
        "text-primary-800 bg-primary-100 border-primary-100 dark:bg-primary-200 dark:border-primary-200"

      "dark" ->
        "text-white bg-primary-600 border-primary-600"

      "outline" ->
        "text-primary-600 border-primary-600 dark:text-primary-400 dark:border-primary-400"
    end
  end

  defp get_color_classes(%{color: "secondary", variant: variant}) do
    case variant do
      "light" ->
        "text-secondary-800 bg-secondary-100 border-secondary-100 dark:bg-secondary-200 dark:border-secondary-200"

      "dark" ->
        "text-white bg-secondary-600 border-secondary-600"

      "outline" ->
        "text-secondary-600 border border-secondary-600  dark:text-secondary-400 dark:border-secondary-400"
    end
  end

  defp get_color_classes(%{color: "info", variant: variant}) do
    case variant do
      "light" ->
        "text-blue-800 bg-blue-100 border-blue-100 dark:bg-blue-200 dark:border-blue-200"

      "dark" ->
        "text-white bg-blue-600 border-blue-600"

      "outline" ->
        "text-blue-600 border border-blue-600 dark:text-blue-400 dark:border-blue-400"
    end
  end

  defp get_color_classes(%{color: "success", variant: variant}) do
    case variant do
      "light" ->
        "text-green-800 bg-green-100 border-green-100 dark:bg-green-200 dark:border-green-200"

      "dark" ->
        "text-white bg-green-600 border-green-600"

      "outline" ->
        "text-green-600 border border-green-600 dark:text-green-400 dark:border-green-400"
    end
  end

  defp get_color_classes(%{color: "warning", variant: variant}) do
    case variant do
      "light" ->
        "text-yellow-800 bg-yellow-100 border-yellow-100 dark:bg-yellow-200 dark:border-yellow-200"

      "dark" ->
        "text-white bg-yellow-600 border-yellow-600"

      "outline" ->
        "text-yellow-600 border border-yellow-600 dark:text-yellow-400 dark:border-yellow-400"
    end
  end

  defp get_color_classes(%{color: "danger", variant: variant}) do
    case variant do
      "light" ->
        "text-red-800 bg-red-100 border-red-100 dark:bg-red-200 dark:border-red-200"

      "dark" ->
        "text-white bg-red-600 border-red-600"

      "outline" ->
        "text-red-600 border border-red-600 dark:text-red-400 dark:border-red-400"
    end
  end

  defp get_color_classes(%{color: "gray", variant: variant}) do
    case variant do
      "light" ->
        "text-gray-800 bg-gray-100 border-gray-100 dark:bg-gray-200 dark:border-gray-200"

      "dark" ->
        "text-white bg-gray-600 border-gray-600 dark:bg-gray-700 dark:border-gray-700"

      "outline" ->
        "text-gray-600 border border-gray-600 dark:text-gray-400 dark:border-gray-400"
    end
  end
end
