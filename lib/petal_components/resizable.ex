defmodule PetalComponents.Resizable do
  use Phoenix.Component

  @moduledoc """
  Split-pane layout groups with draggable, keyboard-operable dividers.

  This is the layout primitive behind docs sites with an adjustable sidebar,
  IDE-style workspaces and editor/preview splits. Three components compose it:

    * `resizable_group/1` - the flex container that owns the `PetalResizable` hook
    * `resizable_panel/1` - a sized pane
    * `resizable_handle/1` - the separator between two panes

  Panels are sized as **percentages of the group** and rendered as
  `flex: <pct> 1 0px`, so a window resize keeps the split proportional. The
  hook reads only its DIRECT children, which is what makes nested groups work:
  each group owns its own hook instance and never touches an inner group's
  panels.

  The library stores nothing. On drag release and on keyboard commit the group
  dispatches a bubbling `petal:resizable-resize` DOM event carrying
  `detail.sizes` (percentages in panel order) and, when `on_resize` is set,
  pushes the same payload to your LiveView. Persist it wherever you like -
  session, URL params, localStorage.

  ## Keyboard

  With a handle focused (it is in the tab order):

    * `ArrowLeft` / `ArrowRight` - resize a vertical separator by 2 points
    * `ArrowUp` / `ArrowDown` - resize a horizontal separator by 2 points
    * hold `Shift` for a 10-point step
    * `Home` - shrink the preceding panel to its `min_size` (collapse it if collapsible)
    * `End` - grow the preceding panel to its `max_size`
    * `Enter` - toggle collapse on a collapsible preceding panel

  Arrows perpendicular to the separator are a no-op, per the WAI-ARIA window
  splitter pattern.

  ## Examples

  A docs layout: a collapsible sidebar and a content pane.

      <.resizable_group id="docs" class="h-80">
        <.resizable_panel id="docs-nav" default_size={25} min_size={15} collapsible>
          Navigation
        </.resizable_panel>
        <.resizable_handle controls="docs-nav" with_handle />
        <.resizable_panel default_size={75}>
          Content
        </.resizable_panel>
      </.resizable_group>

  A vertical split that reports its sizes back to the LiveView.

      <.resizable_group id="editor" orientation="vertical" on_resize="split_changed" class="h-96">
        <.resizable_panel id="editor-code" default_size={70} min_size={30}>Code</.resizable_panel>
        <.resizable_handle orientation="vertical" controls="editor-code" />
        <.resizable_panel default_size={30} min_size={10}>Output</.resizable_panel>
      </.resizable_group>

  Nested groups - a horizontal split inside a vertical one. Each group gets its
  own id and its own hook.

      <.resizable_group id="ide" orientation="vertical" class="h-96">
        <.resizable_panel default_size={75}>
          <.resizable_group id="ide-top" class="h-full">
            <.resizable_panel id="ide-files" default_size={20} min_size={10}>Files</.resizable_panel>
            <.resizable_handle controls="ide-files" />
            <.resizable_panel default_size={50}>Editor</.resizable_panel>
            <.resizable_handle />
            <.resizable_panel default_size={30}>Preview</.resizable_panel>
          </.resizable_group>
        </.resizable_panel>
        <.resizable_handle orientation="vertical" />
        <.resizable_panel default_size={25} min_size={10}>Terminal</.resizable_panel>
      </.resizable_group>
  """

  @doc """
  The container. Renders a flex row (or column) and mounts the `PetalResizable`
  hook, which owns dragging, keyboard resizing, clamping and the resize events.

  Put `resizable_panel/1` and `resizable_handle/1` children in it, alternating,
  with a handle between every adjacent pair of panels. Give the group a height
  (`class="h-80"`, `class="h-full"`, ...) - a flex container has none of its own.
  """
  attr :id, :string,
    default: nil,
    doc: "auto-generated when omitted; set it so the resize events can be told apart"

  attr :orientation, :string,
    default: "horizontal",
    values: ["horizontal", "vertical"],
    doc: "horizontal = panels side by side (vertical dividers); vertical = panels stacked"

  attr :on_resize, :string,
    default: nil,
    doc:
      "optional LiveView event name pushed on drag release and keyboard commit with %{\"sizes\" => [..]} percentages"

  attr :class, :any, default: nil, doc: "extra classes on the group; this is where height goes"
  attr :rest, :global

  slot :inner_block,
    required: true,
    doc: "resizable_panel and resizable_handle children, in order"

  def resizable_group(assigns) do
    assigns = assign(assigns, :id, assigns.id || "pc-resizable-#{Ecto.UUID.generate()}")

    ~H"""
    <div
      id={@id}
      class={[
        "pc-resizable",
        @orientation == "vertical" && "pc-resizable--vertical",
        @class
      ]}
      phx-hook="PetalResizable"
      data-orientation={@orientation}
      data-on-resize={@on_resize}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  One pane of a group.

  `default_size` is a percentage of the group. Panels without one grow to share
  whatever is left (`flex: 1 1 0px`); when a group mixes sized and unsized
  panels the hook normalises the shares on mount so the sized ones land on their
  exact percentage.

  Give the panel an `id` if a handle needs to point `aria-controls` at it, or if
  you want to read the panel out of a `petal:resizable-collapse` event.
  """
  attr :id, :string, default: nil, doc: "needed for aria-controls and collapse events"

  attr :default_size, :integer,
    default: nil,
    doc: "initial size as a percentage of the group; unsized panels share the remainder equally"

  attr :min_size, :integer,
    default: 10,
    doc: "smallest percentage the panel can be dragged or keyed down to"

  attr :max_size, :integer, default: 100, doc: "largest percentage the panel can grow to"

  attr :collapsible, :boolean,
    default: false,
    doc:
      "when true, dragging below roughly half the min_size snaps the panel to collapsed_size and fires petal:resizable-collapse"

  attr :collapsed_size, :integer, default: 0, doc: "the size the panel snaps to when collapsed"
  attr :class, :any, default: nil, doc: "extra classes on the panel"
  attr :rest, :global

  slot :inner_block, required: true

  def resizable_panel(assigns) do
    ~H"""
    <div
      id={@id}
      class={["pc-resizable__panel", @class]}
      style={panel_style(@default_size)}
      data-pc-resizable-panel
      data-min={@min_size}
      data-max={@max_size}
      data-default={@default_size}
      data-collapsible={@collapsible && "true"}
      data-collapsed-size={@collapsed_size}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The separator between two panels.

  It is the accessible control: `role="separator"`, in the tab order, and
  carrying the live `aria-valuenow` for the panel before it. Note the
  inversion - a handle in a `horizontal` group (panels side by side) is a
  VERTICAL separator, so pass the group's `orientation` and the component flips
  it for you.

  The painted line is a hairline; the hit area around it is deliberately much
  larger. `with_handle` adds the visible grip.

  Server-rendered `aria-valuenow`/`valuemin`/`valuemax` are a starting point -
  the hook restamps all three (plus `aria-orientation` and, when the preceding
  panel has an id, `aria-controls`) from the live layout on mount and on every
  resize.
  """
  attr :orientation, :string,
    default: "horizontal",
    values: ["horizontal", "vertical"],
    doc: "the ORIENTATION OF THE GROUP; the separator's own aria-orientation is the inverse"

  attr :with_handle, :boolean, default: false, doc: "renders the visible grip-dot affordance"

  attr :controls, :string,
    default: nil,
    doc:
      "id of the preceding panel, for aria-controls; the hook fills it in when the panel has one"

  attr :value_now, :integer,
    default: 50,
    doc: "initial aria-valuenow (the preceding panel's size); the hook keeps it current"

  attr :value_min, :integer, default: 0, doc: "initial aria-valuemin for the preceding panel"
  attr :value_max, :integer, default: 100, doc: "initial aria-valuemax for the preceding panel"

  attr :label, :string,
    default: "Resize panels",
    doc: "accessible name for the separator; override per split when a page has several"

  attr :class, :any, default: nil, doc: "extra classes on the separator"
  attr :rest, :global

  def resizable_handle(assigns) do
    ~H"""
    <div
      class={[
        "pc-resizable__handle",
        @with_handle && "pc-resizable__handle--with-handle",
        @class
      ]}
      data-pc-resizable-handle
      role="separator"
      tabindex="0"
      aria-orientation={if @orientation == "horizontal", do: "vertical", else: "horizontal"}
      aria-valuenow={@value_now}
      aria-valuemin={@value_min}
      aria-valuemax={@value_max}
      aria-controls={@controls}
      aria-label={@label}
      {@rest}
    >
      <span :if={@with_handle} class="pc-resizable__grip" aria-hidden="true"></span>
    </div>
    """
  end

  defp panel_style(nil), do: "flex: 1 1 0px"
  defp panel_style(size), do: "flex: #{size} 1 0px"
end
