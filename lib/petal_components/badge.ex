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
          "pc-badge",
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
      "sm" -> "pc-badge--sm"
      "md" -> "pc-badge--md"
      "lg" -> "pc-badge--lg"
    end
  end

  defp icon_classes(with_icon) do
    if with_icon do
      "pc-badge--with-icon"
    end
  end

  defp get_color_classes(%{color: "primary", variant: variant}) do
    case variant do
      "light" ->
        "pc-badge--primary-light"

      "dark" ->
        "pc-badge--primary-dark"

      "outline" ->
        "pc-badge--primary-outline"
    end
  end

  defp get_color_classes(%{color: "secondary", variant: variant}) do
    case variant do
      "light" ->
        "pc-badge--secondary-light"

      "dark" ->
        "pc-badge--secondary-dark"

      "outline" ->
        "pc-badge--secondary-outline"
    end
  end

  defp get_color_classes(%{color: "info", variant: variant}) do
    case variant do
      "light" ->
        "pc-badge--info-light"

      "dark" ->
        "pc-badge--info-dark"

      "outline" ->
        "pc-badge--info-outline"
    end
  end

  defp get_color_classes(%{color: "success", variant: variant}) do
    case variant do
      "light" ->
        "pc-badge--success-light"

      "dark" ->
        "pc-badge--success-dark"

      "outline" ->
        "pc-badge--success-outline"
    end
  end

  defp get_color_classes(%{color: "warning", variant: variant}) do
    case variant do
      "light" ->
        "pc-badge--warning-light"

      "dark" ->
        "pc-badge--warning-dark"

      "outline" ->
        "pc-badge--warning-outline"
    end
  end

  defp get_color_classes(%{color: "danger", variant: variant}) do
    case variant do
      "light" ->
        "pc-badge--danger-light"

      "dark" ->
        "pc-badge--danger-dark"

      "outline" ->
        "pc-badge--danger-outline"
    end
  end

  defp get_color_classes(%{color: "gray", variant: variant}) do
    case variant do
      "light" ->
        "pc-badge--gray-light"

      "dark" ->
        "pc-badge--gray-dark"

      "outline" ->
        "pc-badge--gray-outline"
    end
  end
end
