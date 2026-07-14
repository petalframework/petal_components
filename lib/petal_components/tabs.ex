defmodule PetalComponents.Tabs do
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PetalComponents.Link

  attr(:underline, :boolean,
    default: false,
    doc: "underlines your tabs (legacy for variant=\"underline\")"
  )

  attr(:variant, :string,
    default: nil,
    values: [nil, "pill", "underline", "segmented"],
    doc:
      "tab style: pill (default), underline, or segmented - active tab is a raised white pill on a muted track. Overrides the legacy underline flag"
  )

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def tabs(assigns) do
    assigns =
      assign(assigns, :resolved_variant, resolve_variant(assigns.variant, assigns.underline))

    ~H"""
    <nav
      {@rest}
      class={[
        "pc-tabs",
        @resolved_variant == "underline" && "pc-tabs--underline",
        @resolved_variant == "segmented" && "pc-tabs--segmented",
        @class
      ]}
      role="tablist"
    >
      {render_slot(@inner_block)}
    </nav>
    """
  end

  defp resolve_variant(nil, true), do: "underline"
  defp resolve_variant(nil, _underline), do: "pill"
  defp resolve_variant(variant, _underline), do: variant

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:label, :string, default: nil, doc: "labels your tab")

  attr(:link_type, :string,
    default: "a",
    values: ["a", "live_patch", "live_redirect"]
  )

  attr(:to, :string, default: nil, doc: "link path")
  attr(:number, :integer, default: nil, doc: "indicates a number next to your tab")

  attr(:underline, :boolean,
    default: false,
    doc: "underlines your tab (legacy for variant=\"underline\")"
  )

  attr(:variant, :string,
    default: nil,
    values: [nil, "pill", "underline", "segmented"],
    doc: "match the parent tabs variant. Overrides the legacy underline flag"
  )

  attr(:is_active, :boolean, default: false, doc: "indicates the current tab")
  attr(:disabled, :boolean, default: false, doc: "disables your tab")

  attr :on_change, JS,
    default: %JS{},
    doc: "JS commands to run when this tab is selected"

  attr(:rest, :global, include: ~w(method download hreflang ping referrerpolicy rel target type))
  slot(:inner_block, required: false)

  def tab(assigns) do
    assigns =
      if assigns.on_change.ops != [] do
        update(assigns, :rest, fn rest -> Map.put(rest, :"phx-click", assigns.on_change) end)
      else
        assigns
      end

    assigns =
      assign(assigns, :resolved_variant, resolve_variant(assigns.variant, assigns.underline))

    ~H"""
    <Link.a
      link_type={@link_type}
      label={@label}
      to={@to}
      class={get_tab_class(@is_active, @resolved_variant) ++ [@class]}
      disabled={@disabled}
      role="tab"
      aria-selected={to_string(@is_active)}
      {@rest}
    >
      <%= if @number do %>
        {render_slot(@inner_block) || @label}

        <span class={get_tab_number_class(@is_active, @resolved_variant == "underline")}>
          {@number}
        </span>
      <% else %>
        {render_slot(@inner_block) || @label}
      <% end %>
    </Link.a>
    """
  end

  defp get_tab_class(is_active, "pill") do
    [
      "pc-tab__pill",
      if(is_active, do: "pc-tab__pill--is-active", else: "pc-tab__pill--is-not-active")
    ]
  end

  defp get_tab_class(is_active, "segmented") do
    [
      "pc-tab__segment",
      if(is_active, do: "pc-tab__segment--is-active", else: "pc-tab__segment--is-not-active")
    ]
  end

  defp get_tab_class(is_active, "underline") do
    base_classes = "pc-tab__underline"

    active_classes =
      if is_active,
        do: "pc-tab__underline--is-active",
        else: "pc-tab__underline--is-not-active"

    underline_classes =
      if is_active,
        do: "pc-tab__underline--with-underline-and-is-active",
        else: "pc-tab__underline--with-underline-and-is-not-active"

    [base_classes, active_classes, underline_classes]
  end

  # Underline
  defp get_tab_number_class(is_active, true) do
    base_classes = "pc-tab__number"

    active_classes =
      if is_active,
        do: "pc-tab__number__underline--is-active",
        else: "pc-tab__number__underline--is-not-active"

    underline_classes =
      if is_active,
        do: "pc-tab__number__underline--with-underline-and-is-active",
        else: "pc-tab__number__underline--with-underline-and-is-not-active"

    [base_classes, active_classes, underline_classes]
  end

  # Pill
  defp get_tab_number_class(is_active, false) do
    base_classes = "pc-tab__number"

    active_classes =
      if is_active,
        do: "pc-tab__number__pill--is-active",
        else: "pc-tab__number__pill--is-not-active"

    [base_classes, active_classes]
  end
end
