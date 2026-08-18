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

  attr(:dot, :boolean,
    default: false,
    doc:
      "renders a small filled circle before the label - the status-badge convention. " <>
        "The dot rides the badge's own colour and is decorative (aria-hidden), so the " <>
        "label has to carry the meaning on its own. Renders before an icon when both are set."
  )

  attr(:class, :any, default: nil, doc: "CSS class for parent div")
  attr(:label, :string, default: nil, doc: "label your badge")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def badge(assigns) do
    ~H"""
    <span
      {@rest}
      role={@role}
      class={[
        "pc-badge",
        "pc-badge--#{@size}",
        @with_icon && "pc-badge--with-icon",
        @dot && "pc-badge--with-dot",
        "pc-badge--#{@color}-#{@variant}",
        @class
      ]}
    >
      <span :if={@dot} class="pc-badge__dot" aria-hidden="true"></span>{render_slot(@inner_block) ||
        @label}
    </span>
    """
  end
end
