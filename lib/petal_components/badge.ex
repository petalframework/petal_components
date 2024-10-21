defmodule PetalComponents.Badge do
  use Phoenix.Component

  attr(:size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"])
  attr(:variant, :string, default: "light", values: ["light", "dark", "soft", "outline"])

  attr(:color, :string,
    default: "primary",
    values: ["primary", "secondary", "info", "success", "warning", "danger", "gray"]
  )

  attr(:role, :string, default: "note", values: ["note", "status"])
  attr(:with_icon, :boolean, default: false, doc: "adds some icon base classes")
  attr(:class, :any, default: nil, doc: "CSS class for parent div")
  attr(:label, :string, default: nil, doc: "label your badge")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def badge(assigns) do
    ~H"""
    <badge
      {@rest}
      role={@role}
      class={[
        "pc-badge",
        "pc-badge--#{@size}",
        @with_icon && "pc-badge--with-icon",
        "pc-badge--#{@color}-#{@variant}",
        @class
      ]}
    >
      <%= render_slot(@inner_block) || @label %>
    </badge>
    """
  end
end
