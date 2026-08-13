defmodule PetalComponents.Tree do
  @moduledoc """
  A hierarchical tree view: the file-explorer staple.

  `tree/1` takes a nested list of maps and renders arbitrary depth with
  expand/collapse, single selection, optional connecting indent guides, and the
  WAI-ARIA [TreeView](https://www.w3.org/WAI/ARIA/apg/patterns/treeview/)
  keyboard map. Nodes need nothing but an `:id` and a `:label`; `:children`
  makes a node a branch.

      <.tree
        id="files"
        label="Project files"
        show_guides
        default_expanded={["lib"]}
        items={[
          %{id: "lib", label: "lib", children: [%{id: "app.ex", label: "app.ex"}]},
          %{id: "mix.exs", label: "mix.exs"}
        ]}
      />

  ## Node maps

  | key | meaning |
  | --- | --- |
  | `:id` | required, unique within the tree; stringified for the DOM |
  | `:label` | required, the visible text |
  | `:children` | a list of node maps; a non-empty list makes the node a branch |
  | `:icon` | a heroicon name overriding the default folder/document icon |
  | `:disabled` | renders the node non-selectable (still focusable, per the APG) |
  | `:lazy` | marks a branch whose children arrive later; shows the `:loading` row while `:children` is empty |

  Any other key rides along untouched and is handed to the `:item` slot, so
  custom rows can read whatever they need off the node.

  ## The two expansion models

  Pick one. Both render identical markup and identical ARIA, so a tree can move
  from one to the other without a visual change.

  **Client-side (the default).** Leave `:expanded` unset and seed the open
  branches with `:default_expanded`. The chevron toggles `data-expanded` and
  `aria-expanded` with `Phoenix.LiveView.JS`, and CSS animates the height. No
  round-trip, no assigns to keep, nothing to handle. The catch: the open/closed
  state lives only in the DOM, so a LiveView patch that re-renders the tree
  resets it to `:default_expanded`. Right for static trees (docs navigation, a
  settings outline, anything that renders once).

  **Server-controlled.** Pass `:expanded` (a list or `MapSet` of branch ids) and
  an `:on_expand` event name. The chevron pushes that event with the node id in
  `phx-value-id` and your `handle_event/3` decides what opens. Required for
  `:lazy` branches, whose children only exist after the server has been asked
  for them, and for any tree that has to survive `phx-update` patches.

      def handle_event("toggle", %{"id" => id}, socket) do
        {:noreply, update(socket, :expanded, &toggle(&1, id))}
      end

  ## Selection

  Selection is single-select and always server-owned: pass the chosen id as
  `:selected` and give `:select_event` a name to hear about clicks (the node id
  arrives as `phx-value-id`). The component also flips `aria-selected` and the
  selected class client-side on click, so the highlight lands immediately rather
  than a round-trip later. `:on_select` composes your own JS commands onto that.

  Selection only exists when you wire it: with none of `:selected`,
  `:select_event` or `:on_select` set, the tree is purely navigational -
  nodes carry no `aria-selected` at all (per the APG, a tree that does not
  support selection must not announce it) and label clicks do nothing.

  ## Keyboard

  The `PetalTree` hook implements the APG map over a roving tabindex: the tree
  is a single tab stop and exactly one node carries `tabindex="0"`.

  | key | does |
  | --- | --- |
  | `Down` / `Up` | move through visible nodes |
  | `Right` | expand a collapsed branch, or move to its first child |
  | `Left` | collapse an expanded branch, or move to the parent |
  | `Home` / `End` | first / last visible node |
  | `Enter` / `Space` | select the focused node |
  | `*` | expand every sibling branch of the focused node |

  Expansion and selection are JS commands and server events, not hook internals,
  so a tree still expands and selects with the pointer if the hook never runs.
  """
  use Phoenix.Component

  import PetalComponents.Icon
  import PetalComponents.Helpers, only: [compose_js: 2]
  import PetalComponents.Loading, only: [spinner: 1]

  alias Phoenix.LiveView.JS

  attr :id, :string,
    required: true,
    doc: "unique id; the PetalTree hook mounts here for roving focus"

  attr :items, :list,
    default: [],
    doc:
      "nested node maps, e.g. `%{id: \"lib\", label: \"lib\", children: [...]}`. `:id` and `:label` are required; `:children` makes a node a branch, `:icon` overrides the default icon, `:disabled` makes it non-selectable and `:lazy` marks a branch whose children load async. Extra keys pass through to the `:item` slot"

  attr :label, :string,
    default: nil,
    doc:
      "accessible name for the tree, rendered as aria-label. Skip it if you label the tree with aria-labelledby via rest"

  attr :selected, :string,
    default: nil,
    doc: "id of the currently selected node (single selection)"

  attr :select_event, :string,
    default: nil,
    doc: "event name pushed when a node is chosen; the node id rides in phx-value-id"

  attr :on_select, JS,
    default: %JS{},
    doc: "extra JS commands composed onto the built-in selection behaviour when a node is chosen"

  attr :expanded, :any,
    default: nil,
    doc:
      "ids of the currently expanded branches (list or MapSet), or `:all`. Setting this switches the tree to the server-controlled expansion model; leave it nil for the client-side default"

  attr :on_expand, :string,
    default: nil,
    doc:
      "event name pushed by the chevron in the server-controlled model, with the node id in phx-value-id. Ignored when :expanded is nil"

  attr :default_expanded, :any,
    default: [],
    doc:
      "ids of branches expanded at first render, or `:all` to expand everything. Client-side model only"

  attr :target, :any,
    default: nil,
    doc: "phx-target for the select and expand events, for trees inside a LiveComponent"

  attr :show_guides, :boolean,
    default: false,
    doc: "render connecting indent guide lines down each expanded branch"

  attr :class, :any, default: nil, doc: "extra classes for the tree container"
  attr :rest, :global

  slot :item,
    doc:
      "custom node rendering; receives the node map via :let. The chevron, indent and ARIA wiring stay owned by the component - the slot replaces the icon and label row content only"

  slot :empty, doc: "rendered when :items is empty"

  slot :loading,
    doc:
      "rendered inside a :lazy branch while its children are pending (default: a small spinner row)"

  @doc """
  Renders a tree.

  ## Examples

      <.tree id="files" label="Files" items={@files} />

      <.tree
        id="explorer"
        label="Explorer"
        show_guides
        default_expanded={:all}
        selected={@current}
        select_event="pick_file"
        items={@files}
      />

      <.tree id="org" items={@people}>
        <:item :let={person}>
          <span class="font-medium">{person.label}</span>
          <span class="text-xs text-gray-500">{person.title}</span>
        </:item>
        <:empty>Nobody reports into this team yet.</:empty>
      </.tree>
  """
  def tree(assigns) do
    expanded = expanded_set(assigns.expanded, assigns.default_expanded, assigns.items)

    ctx = %{
      id: assigns.id,
      expanded: expanded,
      server: not is_nil(assigns.expanded),
      # Node ids stringify everywhere else (DOM ids, phx-value-id, the
      # expanded sets), so the selected comparison must too - an app passing
      # selected={post.id} with integer PKs would otherwise never see its
      # highlight.
      selected: assigns.selected && to_string(assigns.selected),
      # A purely navigational tree must not announce "not selected" on every
      # node (APG: omit aria-selected when selection is unsupported) - so the
      # selection contract only switches on when the app wires any of the
      # three selection surfaces.
      selectable?:
        assigns.selected != nil or assigns.select_event != nil or assigns.on_select != %JS{},
      select_event: assigns.select_event,
      on_select: assigns.on_select,
      on_expand: assigns.on_expand,
      target: assigns.target,
      show_guides: assigns.show_guides,
      focus_id:
        focus_id(assigns.items, expanded, assigns.selected && to_string(assigns.selected)),
      item: assigns.item,
      loading: assigns.loading
    }

    assigns = assign(assigns, :ctx, ctx)

    ~H"""
    <ul
      id={@id}
      role="tree"
      aria-label={@label}
      phx-hook="PetalTree"
      data-pc-tree
      class={["pc-tree", @show_guides && "pc-tree--guides", @class]}
      {@rest}
    >
      <li :if={@items == []} role="none" class="pc-tree__empty">
        {if @empty == [], do: "Nothing here yet.", else: render_slot(@empty)}
      </li>
      <.tree_node
        :for={{node, i} <- Enum.with_index(@items, 1)}
        node={node}
        ctx={@ctx}
        level={1}
        posinset={i}
        setsize={length(@items)}
      />
    </ul>
    """
  end

  # The recursive half. A node renders its own row and, when it is an expanded
  # branch, a role="group" list that calls straight back into this function -
  # depth is whatever the data has, not a fixed number of levels.
  defp tree_node(assigns) do
    node = assigns.node
    children = List.wrap(Map.get(node, :children))
    lazy? = Map.get(node, :lazy) == true
    branch? = children != [] or lazy?
    node_id = to_string(node.id)
    expanded? = branch? and MapSet.member?(assigns.ctx.expanded, node_id)

    assigns =
      assigns
      |> assign(:children, children)
      |> assign(:branch, branch?)
      |> assign(:node_id, node_id)
      |> assign(:expanded, expanded?)
      |> assign(:disabled, Map.get(node, :disabled) == true)
      |> assign(:selected, assigns.ctx.selected == node_id)
      |> assign(:pending, lazy? and children == [])
      |> assign(:icon, node_icon(node, branch?, expanded?))
      |> assign(:guide_count, assigns.level - 1)

    ~H"""
    <li
      id={node_dom_id(@ctx.id, @node_id)}
      role="treeitem"
      aria-level={@level}
      aria-posinset={@posinset}
      aria-setsize={@setsize}
      aria-labelledby={label_dom_id(@ctx.id, @node_id)}
      aria-expanded={@branch && to_string(@expanded)}
      aria-selected={@ctx.selectable? && to_string(@selected)}
      aria-disabled={@disabled && "true"}
      tabindex={if @ctx.focus_id == @node_id, do: "0", else: "-1"}
      data-pc-tree-node
      data-node-id={@node_id}
      data-branch={@branch && "true"}
      data-expanded={@branch && to_string(@expanded)}
      class={[
        "pc-tree__item",
        @selected && "pc-tree__item--selected",
        @disabled && "pc-tree__item--disabled"
      ]}
    >
      <div class="pc-tree__row" style={"--pc-tree-depth: #{@level - 1};"}>
        <span :if={@ctx.show_guides && @guide_count > 0} class="pc-tree__guides" aria-hidden="true">
          <span :for={_ <- 1..@guide_count//1} class="pc-tree__guide"></span>
        </span>

        <span
          :if={@branch}
          class="pc-tree__chevron"
          aria-hidden="true"
          data-pc-tree-chevron
          phx-click={chevron_click(@ctx, @node_id)}
          phx-value-id={@node_id}
          phx-target={@ctx.server && @ctx.target}
        >
          <.icon name="hero-chevron-right-mini" class="pc-tree__chevron-icon" />
        </span>
        <span :if={!@branch} class="pc-tree__chevron pc-tree__chevron--leaf" aria-hidden="true"></span>

        <span
          id={label_dom_id(@ctx.id, @node_id)}
          class="pc-tree__content"
          data-pc-tree-select
          phx-click={!@disabled && select_click(@ctx, @node_id)}
          phx-value-id={@node_id}
          phx-target={!@disabled && @ctx.select_event && @ctx.target}
        >
          <%= if @ctx.item == [] do %>
            <.icon :if={@icon} name={@icon} class="pc-tree__icon" aria-hidden="true" />
            <span class="pc-tree__label">{@node.label}</span>
          <% else %>
            {render_slot(@ctx.item, @node)}
          <% end %>
        </span>
      </div>

      <div :if={@branch} class="pc-tree__group-wrap">
        <ul role="group" class="pc-tree__group">
          <li
            :if={@pending}
            role="none"
            class="pc-tree__loading"
            style={"--pc-tree-depth: #{@level};"}
          >
            <%= if @ctx.loading == [] do %>
              <.spinner size="sm" class="pc-tree__spinner" /> Loading...
            <% else %>
              {render_slot(@ctx.loading)}
            <% end %>
          </li>
          <.tree_node
            :for={{child, i} <- Enum.with_index(@children, 1)}
            node={child}
            ctx={@ctx}
            level={@level + 1}
            posinset={i}
            setsize={length(@children)}
          />
        </ul>
      </div>
    </li>
    """
  end

  # In the server-controlled model the chevron is a plain event push, so the
  # LiveView owns what is open. Otherwise it flips the two attributes the CSS
  # and the hook both read, entirely client-side.
  defp chevron_click(%{server: true} = ctx, _node_id), do: ctx.on_expand

  defp chevron_click(ctx, node_id) do
    selector = "#" <> node_dom_id(ctx.id, node_id)

    %JS{}
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: selector)
    |> JS.toggle_attribute({"data-expanded", "true", "false"}, to: selector)
  end

  # User JS first, then the built-in highlight move, then the push (so the
  # server hears about a selection the user's own commands did not cancel).
  # No selection wiring, no selection behaviour: the label click does
  # nothing rather than flipping a client-side highlight the app never
  # asked for and cannot read.
  defp select_click(%{selectable?: false}, _node_id), do: nil

  defp select_click(ctx, node_id) do
    ctx.on_select
    |> compose_js(selection_js(ctx, node_id))
    |> push_select(ctx)
  end

  defp selection_js(ctx, node_id) do
    self_selector = "#" <> node_dom_id(ctx.id, node_id)
    tree_selector = "##{ctx.id} [role='treeitem'][aria-selected='true']"

    %JS{}
    |> JS.set_attribute({"aria-selected", "false"}, to: tree_selector)
    |> JS.remove_class("pc-tree__item--selected", to: "##{ctx.id} .pc-tree__item--selected")
    |> JS.set_attribute({"aria-selected", "true"}, to: self_selector)
    |> JS.add_class("pc-tree__item--selected", to: self_selector)
  end

  defp push_select(js, %{select_event: nil}), do: js
  defp push_select(js, ctx), do: JS.push(js, ctx.select_event, target: ctx.target)

  defp node_icon(node, branch?, expanded?) do
    case Map.get(node, :icon) do
      nil when branch? and expanded? -> "hero-folder-open"
      nil when branch? -> "hero-folder"
      nil -> "hero-document"
      icon -> icon
    end
  end

  defp node_dom_id(tree_id, node_id), do: "#{tree_id}-node-#{node_id}"
  defp label_dom_id(tree_id, node_id), do: "#{tree_id}-label-#{node_id}"

  # :expanded (server-controlled) wins over :default_expanded (client-side seed).
  defp expanded_set(nil, default, items), do: to_id_set(default, items)
  defp expanded_set(expanded, _default, items), do: to_id_set(expanded, items)

  defp to_id_set(:all, items), do: MapSet.new(branch_ids(items))
  defp to_id_set(ids, _items) when is_list(ids), do: MapSet.new(ids, &to_string/1)
  defp to_id_set(%MapSet{} = ids, _items), do: MapSet.new(ids, &to_string/1)
  defp to_id_set(_other, _items), do: MapSet.new()

  defp branch_ids(items) do
    Enum.flat_map(items, fn node ->
      children = List.wrap(Map.get(node, :children))

      if children == [] and Map.get(node, :lazy) != true,
        do: [],
        else: [to_string(node.id) | branch_ids(children)]
    end)
  end

  # Exactly one node carries tabindex="0" at render: the selected node when it
  # is reachable without expanding anything, otherwise the first visible node.
  defp focus_id(items, expanded, selected) do
    visible = visible_ids(items, expanded)

    if selected && selected in visible, do: selected, else: List.first(visible)
  end

  defp visible_ids(items, expanded) do
    Enum.flat_map(items, fn node ->
      id = to_string(node.id)
      children = List.wrap(Map.get(node, :children))

      if MapSet.member?(expanded, id),
        do: [id | visible_ids(children, expanded)],
        else: [id]
    end)
  end
end
