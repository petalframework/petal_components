defmodule PetalComponents.Tooltip do
  use Phoenix.Component

  @doc """
  A pure-CSS tooltip that appears on hover or keyboard focus. No JavaScript required.

  ## Examples

      <.tooltip label="Add to library">
        <.button size="sm">Hover me</.button>
      </.tooltip>

      <.tooltip placement="right" label="Settings" />

  Rich content via the `:content` slot:

      <.tooltip placement="bottom">
        <:content>
          Saved <span class="font-semibold">2 minutes ago</span>
        </:content>
        <.icon name="hero-check-circle" class="w-5 h-5" />
      </.tooltip>

  ## Disabling at runtime

  Pass `disabled` to render the trigger without any tooltip. To toggle from the
  client (e.g. only show tooltips while a sidebar is collapsed), add or remove
  the `pc-tooltip--suppressed` class on the wrapper - `JS.add_class/2`,
  `JS.remove_class/2`, or any client-side binding works.
  """

  attr :label, :string, default: nil, doc: "the tooltip text (or use the :content slot)"

  attr :placement, :string,
    default: "top",
    values: ["top", "bottom", "left", "right"],
    doc: "which side of the trigger the tooltip appears on"

  attr :disabled, :boolean, default: false, doc: "when true, no tooltip is rendered"
  attr :arrow, :boolean, default: true, doc: "show the arrow pointing at the trigger"
  attr :class, :any, default: nil, doc: "extra classes for the wrapper"
  attr :content_class, :any, default: nil, doc: "extra classes for the tooltip bubble"
  attr :rest, :global

  slot :inner_block, required: true, doc: "the trigger content"
  slot :content, doc: "rich tooltip content; overrides the label attr"

  def tooltip(assigns) do
    ~H"""
    <span class={["pc-tooltip group/pc-tooltip", @class]} {@rest}>
      {render_slot(@inner_block)}
      <span
        :if={!@disabled && (@label || @content != [])}
        role="tooltip"
        class={["pc-tooltip__content", placement_class(@placement), @content_class]}
      >
        <%= if @content != [] do %>
          {render_slot(@content)}
        <% else %>
          {@label}
        <% end %>
        <span :if={@arrow} class={"pc-tooltip__arrow pc-tooltip__arrow--" <> @placement}></span>
      </span>
    </span>
    """
  end

  defp placement_class(placement), do: "pc-tooltip__content--#{placement}"
end
