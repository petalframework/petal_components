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

  attr(:dot_color, :string,
    default: nil,
    values: [nil, "primary", "secondary", "info", "success", "warning", "danger", "gray"],
    doc:
      "colours the dot independently of the badge. nil, the default, inherits the badge's " <>
        "colour exactly as before. Set it for the neutral chip - quiet chrome, one semantic " <>
        "dot: `<.badge color=\"gray\" variant=\"outline\" dot dot_color=\"success\">" <>
        "Production</.badge>`. The stop matches what an inherited dot of that colour shows " <>
        "on the same variant, so the override moves the hue and nothing else. The `dark` " <>
        "variant is the exception - its inherited dot is currentColor, which no ramp can " <>
        "match - so an override there takes the 400 stop, and is a visible change even when " <>
        "it names the badge's own colour. Keep it to that shape: when the badge already " <>
        "carries a semantic colour of its own, leave the dot inherited rather than putting " <>
        "two meanings in one chip - a success badge with a danger dot reads as neither."
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
      <span :if={@dot} class={dot_class(@dot_color, @variant)} aria-hidden="true"></span>{render_slot(
        @inner_block
      ) || @label}
    </span>
    """
  end

  # One string, not a class list: HEEx compiles `class={["pc-badge__dot", nil]}`
  # to `class="pc-badge__dot "`, and a dot with no override has to be byte for
  # byte the markup it was before dot_color existed.
  #
  # The variant rides in the class because the stop depends on it - see the dot
  # colour override block in assets/default.css.
  defp dot_class(nil, _variant), do: "pc-badge__dot"
  defp dot_class(color, variant), do: "pc-badge__dot pc-badge__dot--#{color}-#{variant}"
end
