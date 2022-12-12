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
    <div {@rest} class={build_class([
        "flex gap-x-8 gap-y-2",
        (if @underline, do: "border-b border-gray-200 dark:border-gray-600", else: ""),
        @class
      ], " ")}>
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
    <Link.a link_type={@link_type} label={@label} to={@to} class={get_tab_class(@is_active, @underline) <> @class} {@rest}>
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
    base_classes = "whitespace-nowrap px-3 py-2 flex font-medium items-center text-sm rounded-md"

    active_classes =
      if is_active,
        do: "bg-primary-100 dark:bg-gray-800 text-primary-600 dark:text-primary-500",
        else:
          "text-gray-500 hover:text-gray-600 dark:hover:text-gray-300 dark:text-gray-400 dark:hover:bg-gray-800 hover:bg-gray-100"

    build_class([base_classes, active_classes])
  end

  # Underline CSS
  defp get_tab_class(is_active, underline) do
    base_classes = "whitespace-nowrap flex items-center py-3 px-3 border-b-2 font-medium text-sm"

    active_classes =
      if is_active,
        do: "border-primary-500 text-primary-600 dark:text-primary-500 dark:border-primary-500",
        else:
          "border-transparent text-gray-500 dark:hover:text-gray-300 dark:text-gray-400 hover:border-gray-300 hover:text-gray-600"

    underline_classes =
      if is_active && underline,
        do: "",
        else: "hover:border-gray-300"

    build_class([base_classes, active_classes, underline_classes])
  end

  # Underline
  defp get_tab_number_class(is_active, true) do
    base_classes = "whitespace-nowrap ml-2 py-0.5 px-2 rounded-full text-xs font-normal"

    active_classes =
      if is_active,
        do: "bg-primary-100 text-primary-600",
        else: "bg-gray-100 text-gray-500"

    underline_classes =
      if is_active,
        do: "bg-primary-100 dark:bg-primary-600 text-primary-600 dark:text-white",
        else: "bg-gray-100 dark:bg-gray-600 dark:text-white text-gray-500"

    build_class([base_classes, active_classes, underline_classes])
  end

  # Pill
  defp get_tab_number_class(is_active, false) do
    base_classes = "whitespace-nowrap ml-2 py-0.5 px-2 rounded-full text-xs font-normal"

    active_classes =
      if is_active,
        do: "bg-primary-600 text-white",
        else: "bg-gray-500 dark:bg-gray-600 text-white"

    build_class([base_classes, active_classes])
  end
end
