defmodule PetalComponents.Tabs do
  use Phoenix.Component

  alias PetalComponents.Link

  import PetalComponents.Helpers

  attr(:underline, :boolean, default: false, doc: "underlines your tabs")
  attr(:class, :string, default: "", doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def tabs(assigns) do
    ~H"""
    <div
      {@rest}
      class={
        build_class(
          [
            "pc-tabs",
            if(@underline, do: "pc-tabs--underline", else: ""),
            @class
          ],
          " "
        )
      }
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:label, :string, default: nil, doc: "labels your tab")

  attr(:link_type, :string,
    default: "a",
    values: ["a", "live_patch", "live_redirect"]
  )

  attr(:to, :string, default: nil, doc: "link path")
  attr(:number, :integer, default: nil, doc: "indicates a number next to your tab")
  attr(:underline, :boolean, default: false, doc: "underlines your your tab")
  attr(:is_active, :boolean, default: false, doc: "indicates the current tab")
  attr(:rest, :global, include: ~w(method download hreflang ping referrerpolicy rel target type))
  slot(:inner_block, required: false)

  def tab(assigns) do
    ~H"""
    <Link.a
      link_type={@link_type}
      label={@label}
      to={@to}
      class={"#{get_tab_class(@is_active, @underline)} #{@class}"}
      {@rest}
    >
      <%= if @number do %>
        <%= render_slot(@inner_block) || @label %>

        <span class={get_tab_number_class(@is_active, @underline)}>
          <%= @number %>
        </span>
      <% else %>
        <%= render_slot(@inner_block) || @label %>
      <% end %>
    </Link.a>
    """
  end

  # Pill CSS
  defp get_tab_class(is_active, false) do
    base_classes = "pc-tab__pill"

    active_classes =
      if is_active,
        do: "pc-tab__pill--is-active",
        else: "pc-tab__pill--is-not-active"

    build_class([base_classes, active_classes])
  end

  # Underline CSS
  defp get_tab_class(is_active, underline) do
    base_classes = "pc-tab__underline"

    active_classes =
      if is_active,
        do: "pc-tab__underline--is-active",
        else: "pc-tab__underline--is-not-active"

    underline_classes =
      if is_active && underline,
        do: "pc-tab__underline--with-underline-and-is-active",
        else: "pc-tab__underline--with-underline-and-is-not-active"

    build_class([base_classes, active_classes, underline_classes])
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

    build_class([base_classes, active_classes, underline_classes])
  end

  # Pill
  defp get_tab_number_class(is_active, false) do
    base_classes = "pc-tab__number"

    active_classes =
      if is_active,
        do: "pc-tab__number__pill--is-active",
        else: "pc-tab__number__pill--is-not-active"

    build_class([base_classes, active_classes])
  end
end
