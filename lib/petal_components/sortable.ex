defmodule PetalComponents.Sortable do
  @moduledoc """
  A drag-to-reorder list or grid.

  The user drags an item (or lifts it with the keyboard), the DOM reorders
  optimistically with animated gaps, and on drop the component pushes ONE
  event carrying `%{"id" => ..., "from" => ..., "to" => ...}`. Your
  `handle_event/3` persists the new order and re-renders. LiveView stays the
  source of truth: the optimistic DOM already matches, so the patch is a
  visual no-op. Rejecting a move snaps the items back, which is the correct
  failure behaviour rather than a bug - but a stream has to be told to do it,
  see "Rejecting a move" below.

  Needs the `PetalSortable` hook from the petal_components JS bundle.

  ## Examples

  A plain list. `on_reorder` is an event name, not a `JS` struct, because the
  move has to reach the server to be persisted:

      <.sortable id="stages" on_reorder="reorder_stages">
        <:item :for={stage <- @stages} id={stage.id}>
          {stage.name}
        </:item>
      </.sortable>

  Handle mode, where only the grip starts a drag so the rest of the row stays
  clickable (links, checkboxes, inline edit):

      <.sortable id="todos" on_reorder="reorder_todos" handle>
        <:item :for={todo <- @todos} id={todo.id} label={todo.title} disabled={todo.locked}>
          <input type="checkbox" checked={todo.done} phx-click="toggle" phx-value-id={todo.id} />
          <span>{todo.title}</span>
        </:item>
      </.sortable>

  A grid, where the arrow keys move in two dimensions:

      <.sortable id="gallery" on_reorder="reorder_photos" orientation="grid">
        <:item :for={photo <- @photos} id={photo.id} label={photo.alt}>
          <img src={photo.url} alt={photo.alt} />
        </:item>
      </.sortable>

  ## Stream-backed lists

  Streams are the usual way to render a reorderable list. Pass
  `phx-update="stream"` through to the root (it lands on the element that
  directly contains the items) and give each item BOTH ids: `dom_id` is the
  stream's DOM id, `id` is your record's real id, which is what arrives in the
  event. Reconciliation is by `data-sortable-id`, never by index.

      <.sortable id="todos" on_reorder="reorder" phx-update="stream">
        <:item :for={{dom_id, todo} <- @streams.todos} id={todo.id} dom_id={dom_id}>
          {todo.title}
        </:item>
      </.sortable>

  And the handler that makes the server the source of truth. Reinserting every
  item at its new position is what keeps a later full re-render in agreement
  with the DOM the hook already produced:

      def handle_event("reorder", %{"id" => id, "from" => from, "to" => to}, socket) do
        todos =
          socket.assigns.todos
          |> List.delete_at(from)
          |> List.insert_at(to, Enum.at(socket.assigns.todos, from))

        {:ok, _} = Todos.persist_order(todos)

        socket =
          Enum.reduce(Enum.with_index(todos), socket, fn {todo, index}, acc ->
            stream_insert(acc, :todos, todo, at: index)
          end)

        {:noreply, assign(socket, :todos, todos)}
      end

  The `id` in the payload is the item's `data-sortable-id`, so a handler that
  prefers identity over index can ignore `from` entirely and place by id.
  Prefer that: treat the payload as "move `id` to index `to`" and use `from`
  only as a sanity check. Under concurrency (someone else reordered between
  the render and the drop) `from` can be stale, but the id never is.

  ## Rejecting a move

  Read this before shipping a sortable that can say no.

  For a list rendered from assigns, rejection needs no work: the next render
  is the server's order, so the items snap back on their own.

  Streams do not behave that way. Stream updates are ops, not a diff, so a
  handler that rejects a move and sends no stream ops leaves the DOM in the
  client's order forever, silently disagreeing with the server. Rejection has
  to be explicit:

      def handle_event("reorder", %{"id" => id, "to" => to}, socket) do
        case Todos.move(id, to) do
          {:ok, todos} ->
            {:noreply, restream(socket, todos)}

          {:error, :locked} ->
            # say no out loud: without this the client keeps its own order
            {:noreply,
             socket
             |> stream(:todos, Todos.list(), reset: true)
             |> put_flash(:error, "That list is locked.")}
        end
      end

  ## Dead views and JS interop

  Alongside the pushed event, a drop dispatches a bubbling `petal:sortable`
  `CustomEvent` with the same `detail` (`{id, from, to}`), mirroring
  `petal:otp-complete` on `input_otp`. Outside LiveView, listen for that.

  ## Keyboard

  Tab reaches each item (or its handle in handle mode), then:

    * `Space` lifts the focused item
    * arrow keys move it one position (up/down in a list; all four in a grid)
    * `Space` drops it, and only then does `on_reorder` fire
    * `Escape` cancels and restores the original position

  Every transition is announced through a visually hidden `aria-live="polite"`
  region, and focus stays on the moved item after a drop.

  ## Touch

  A long press of roughly 250ms lifts an item. A tap or a scroll gesture does
  not, so the page still scrolls normally with a sortable on screen.

  ## One caveat worth knowing

  There is no cloned drag overlay: the real element is moved through the list
  as you drag it, which keeps the accessible order equal to the DOM order at
  every instant and keeps form state, media and measured widths intact. The
  cost is that a server patch arriving mid-drag replaces the nodes being
  animated, so the hook abandons that drag rather than animating a detached
  tree. In an app pushing frequent unrelated updates into the same container
  (presence, live counters) a drag can be cut short. A keyboard lift survives
  a patch: it re-resolves itself by `data-sortable-id`.

  ## Planned follow-ups

  v1 is deliberately one container. These are the known gaps, each additive
  rather than breaking, and the event shape is designed so a kanban board can
  be composed on top:

    * cross-container drag (kanban) via a `group` attr and a container id in
      the payload
    * multi-select drag
    * auto-scrolling a scroll container while dragging near its edge
    * nested sortables
  """
  use Phoenix.Component

  attr :id, :string, required: true, doc: "DOM id; the hook mounts here"

  attr :on_reorder, :string,
    required: true,
    doc: "event name pushed on drop with %{id, from, to} (string-key params)"

  attr :handle, :boolean,
    default: false,
    doc: "when true only the grip handle initiates drag; when false the whole item does"

  attr :disabled, :boolean, default: false, doc: "disables all drag and keyboard reorder"

  attr :orientation, :string,
    default: "vertical",
    values: ["vertical", "grid"],
    doc: "vertical = single-column list; grid = wrapping grid, arrow keys move in 2D"

  attr :target, :any,
    default: nil,
    doc: "optional phx-target for the reorder event (a live component's @myself)"

  attr :class, :any, default: nil, doc: "extra classes for the list container"
  attr :rest, :global, doc: ~s|passed to the list container, e.g. phx-update="stream"|

  slot :item, required: true, doc: "one per sortable entry" do
    attr :id, :string, doc: "stable item identity, rendered as data-sortable-id (required)"

    attr :dom_id, :string,
      doc: "the element's id; defaults to :id. Pass the stream dom_id for stream-backed lists"

    attr :disabled, :boolean,
      doc:
        "this item cannot be grabbed or lifted. It can still be displaced when its neighbours move"

    attr :label, :string, doc: "accessible name used in announcements and the handle label"
    attr :class, :any, doc: "extra classes for this item"
  end

  def sortable(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "pc-sortable",
        @orientation == "grid" && "pc-sortable--grid",
        @disabled && "pc-sortable--disabled",
        @class
      ]}
      role="list"
      phx-hook="PetalSortable"
      phx-target={@target}
      data-on-reorder={@on_reorder}
      data-orientation={@orientation}
      data-handle={@handle && "true"}
      data-disabled={@disabled && "true"}
      {@rest}
    >
      <div
        :for={item <- @item}
        id={item[:dom_id] || item.id}
        class={[
          "pc-sortable__item",
          item_disabled?(@disabled, item) && "pc-sortable__item--disabled",
          item[:class]
        ]}
        role="listitem"
        data-sortable-id={item.id}
        data-sortable-label={item[:label]}
        data-disabled={item_disabled?(@disabled, item) && "true"}
        aria-roledescription="sortable"
        aria-describedby={"#{@id}-instructions"}
        tabindex={item_tabindex(@disabled, @handle, item)}
      >
        <button
          :if={@handle}
          type="button"
          class="pc-sortable__handle"
          tabindex={item_disabled?(@disabled, item) && "-1"}
          aria-label={"Reorder #{item[:label] || item.id}"}
          aria-describedby={"#{@id}-instructions"}
          aria-disabled={item_disabled?(@disabled, item) && "true"}
          data-sortable-handle
        >
          <svg
            class="pc-sortable__grip"
            viewBox="0 0 20 20"
            fill="currentColor"
            aria-hidden="true"
            focusable="false"
          >
            <circle cx="7" cy="4" r="1.5" />
            <circle cx="13" cy="4" r="1.5" />
            <circle cx="7" cy="10" r="1.5" />
            <circle cx="13" cy="10" r="1.5" />
            <circle cx="7" cy="16" r="1.5" />
            <circle cx="13" cy="16" r="1.5" />
          </svg>
        </button>
        {render_slot(item)}
      </div>
    </div>
    <p id={"#{@id}-instructions"} class="pc-sortable__sr">
      Press Space to lift this item, the arrow keys to move it, Space again to drop it, or Escape to cancel.
    </p>
    <%!-- phx-update="ignore" is load-bearing: the hook writes the announcement
    here, and the server renders this element empty. Without it the very patch
    the drop caused would wipe the announcement back out. --%>
    <div
      id={"#{@id}-live"}
      class="pc-sortable__sr"
      phx-update="ignore"
      role="status"
      aria-live="polite"
      aria-atomic="true"
    >
    </div>
    """
  end

  defp item_disabled?(true, _item), do: true
  defp item_disabled?(_disabled, item), do: item[:disabled] == true

  # In handle mode the grip is the tab stop, not the row, so the row itself
  # never takes focus. Disabled either way means out of the tab order.
  defp item_tabindex(container_disabled, handle, item) do
    cond do
      item_disabled?(container_disabled, item) -> nil
      handle -> nil
      true -> "0"
    end
  end
end
