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

  defp get_color_classes(%{color: color, variant: variant}) do
    case variant do
      "light" ->
        "pc-badge--" <> color <> "-light"

      "dark" ->
        "pc-badge--" <> color <> "-dark"

      "outline" ->
        "pc-badge--" <> color <> "-outline"
    end
  end
end
