defmodule PetalComponents.Empty do
  @moduledoc """
  The empty state: what a list, table, inbox or search renders when it has
  nothing to show.

  Every app reinvents this anatomy by hand - a piece of media, a title, a
  short description, one or two actions. `<.empty>` standardises it so the
  empty states across a product read as one system:

      <.empty
        title="No results found"
        description="No projects match your filters. Try a broader search."
      >
        <:actions>
          <.button size="sm" variant="outline" color="gray">Clear filters</.button>
        </:actions>
      </.empty>

  Every part is optional - a title on its own renders fine. Without an
  `:icon` slot a default treatment renders: a muted circle with a dashed
  ring around a heroicon glyph, marked `aria-hidden` because it is
  decorative.

  ## Variants

    * `default` - centred with generous vertical padding, no border. The
      page-level empty state.
    * `compact` - tighter padding and type, sized to sit inside a table
      frame or a list.
    * `card` - the floating-panel surface (border + radius), for an empty
      state that has to hold its own on a busy page.
    * `dashed` - a dashed border on the gray ramp, the drop-target look.
      Visual only; it ships no drag-and-drop behaviour.

  `size` (`sm`/`md`/`lg`) scales the media, the type and the spacing of
  every variant.

  ## A first-run state with actions

      <.empty
        variant="dashed"
        title="No projects yet"
        description="Projects hold your environments, deploys and team access."
      >
        <:icon><.icon name="hero-folder-plus" class="w-6 h-6 text-gray-400" /></:icon>
        <:actions>
          <.button size="sm">Create your first project</.button>
          <.button size="sm" variant="outline" color="gray">Import from Git</.button>
        </:actions>
        <.a to="/docs/projects" class="text-sm">Learn more about projects</.a>
      </.empty>

  ## Inside a data table

  `<.data_table>` takes an `:empty` slot, so the empty state of a table is
  the same component as the empty state of a page:

      <.data_table id="orders" rows={@rows} state={@state} path={~p"/orders"}>
        <:col :let={row} field={:name}>{row.name}</:col>
        <:empty>
          <.empty
            variant="compact"
            size="sm"
            title="No orders yet"
            description="Orders show up here the moment your first customer checks out."
          />
        </:empty>
      </.data_table>

  ## Accessibility

  The root is a plain `<div>` - no landmark, no live region. An empty state
  is static content; announcing that a result set changed is the job of the
  thing that changed it. The media is `aria-hidden="true"`, and the title,
  description and actions sit in DOM order so a screen reader gets a
  coherent read.
  """
  use Phoenix.Component

  import PetalComponents.Icon

  attr(:title, :string, default: nil, doc: "the headline, e.g. \"No results found\"")

  attr(:description, :string,
    default: nil,
    doc: "one or two sentences of supporting text under the title"
  )

  attr(:variant, :string,
    default: "default",
    values: ["default", "compact", "card", "dashed"],
    doc:
      "default: centred with generous vertical padding; compact: tighter, for table/list empties; card: wrapped in the floating-panel surface; dashed: dashed border, drop-target look"
  )

  attr(:size, :string,
    default: "md",
    values: ["sm", "md", "lg"],
    doc: "scales the media, the type and the spacing"
  )

  attr(:class, :any, default: nil, doc: "CSS class for the outer container")
  attr(:rest, :global)

  slot(:icon,
    doc:
      "custom icon or illustration; without it a default treatment renders - a muted circle with a dashed ring around a heroicon glyph"
  )

  slot(:actions,
    doc: "primary and secondary actions (buttons or links) rendered under the description"
  )

  slot(:inner_block,
    doc: "an optional trailing line, e.g. a \"Learn more\" link rendered under the actions"
  )

  @doc """
  The empty state: media, title, description, actions, trailing line - every
  part optional, centred in a column.
  """
  def empty(assigns) do
    ~H"""
    <div
      class={["pc-empty", "pc-empty--#{@variant}", "pc-empty--#{@size}", @class]}
      {@rest}
    >
      <div
        class={["pc-empty__media", @icon == [] && "pc-empty__media--default"]}
        aria-hidden="true"
      >
        <%= if @icon == [] do %>
          <.icon name="hero-inbox" class="pc-empty__icon" />
        <% else %>
          {render_slot(@icon)}
        <% end %>
      </div>

      <p :if={@title} class="pc-empty__title">{@title}</p>
      <p :if={@description} class="pc-empty__description">{@description}</p>

      <div :if={@actions != []} class="pc-empty__actions">
        {render_slot(@actions)}
      </div>

      <div :if={@inner_block != []} class="pc-empty__footer">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
