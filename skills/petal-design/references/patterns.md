# patterns.md - composition grammar

How petal_components compose into pages. API layer lives in rules.md (Hex package root) - read it for install and hard rules. This file is the wiring grammar. Look up every attr with the MCP ladder before writing it - never from memory.

## One State, many surfaces

`PetalComponents.DataTable.State` is the data table's entire backend contract in one struct: `order_by`, `filters`, `search`, `page`, `page_size`, `total`. `total: nil` means cursor/unknown mode; pagination auto-picks numbered mode when total is known. It is Flop-shaped on purpose and Flop-free on purpose - anything that can produce this struct can drive `<.data_table>`, and anything that can consume it can execute the query.

When a page needs both a filter bar and a table, create ONE `%State{}` assign and pass it to both `<.filters>` and `<.data_table>` with the same `on_change` event (or the same `path`). Never maintain separate filter assigns. The payoff is bidirectional composition with no glue: filter from the bar and the table updates, filter from a column header and a chip appears.

```heex
<.filters id="products-filters" state={@table} on_change="table">
  <:field field={:category} type="select" options={["tools", "toys"]} />
  <:field field={:in_stock} label="In stock" type="boolean" />
</.filters>

<.data_table id="products" rows={@rows} state={@table} on_change="table">
  <:col :let={p} field={:name} sortable>{p.name}</:col>
  <:col :let={p} field={:category} filterable="select" options={["tools", "toys"]}>
    {p.category}
  </:col>
</.data_table>
```

The `:field` slot is the registry: `field` (atom, required), `label` (defaults to the humanized field), `options` (strings or `{label, value}` tuples, same shape as data_table's `:col` options), and `type` - one of `"text"`, `"select"`, `"multi"`, `"date_range"`, `"boolean"`, `"number_range"` (defaults to `"text"`). Each type picks the value editor and an operator subset of `State.ops/0`.

Run the state with an engine: `Engine.List.run(rows, state)` returns `{rows, state}` with `total` filled in - zero setup, no database. Never write ad-hoc `Enum.filter`/`Enum.sort` around a data_table. Swap in a real query layer later; the State and templates do not change.

## Two wiring modes - inferred, never both, never neither

Both `<.filters>` and `<.data_table>` infer their mode from which attr you pass. Passing neither `path` nor `on_change` raises `ArgumentError` at render.

**Link mode (`path`)** - default for top-level index pages. Every change is a `patch` URL built from `State.to_params/1`; the URL is the state store. handle_params plus `State.from_params/2` is the whole backend:

```elixir
def handle_params(params, _uri, socket) do
  state = State.from_params(params, fields: [:name, :category, :price])
  {rows, state} = Engine.List.run(all_products(), state)
  {:noreply, assign(socket, rows: rows, table: state)}
end
```

Payoffs: shareable sorts/filters, working back button, curl-able URLs. `to_params/1` omits defaults so URLs stay clean; `total` never round-trips - it is a result, not a request. Pass the same `:page_size` default to both `from_params` and `to_params` so they stay symmetric.

**Event mode (`on_change`)** - use inside LiveComponents (it takes `target` for `@myself`) or embedded widgets. Everything posts op-shaped payloads; `State.handle_op/3` plus an engine re-run is the whole handler:

```elixir
def handle_event("table", params, socket) do
  state = State.handle_op(socket.assigns.table, params, fields: [:name, :email])
  {rows, state} = Engine.List.run(all_rows(), state)
  {:noreply, assign(socket, rows: rows, table: state)}
end
```

Pick one mode per State and use it on every surface sharing that State.

## The op grammar

One event name carries the whole table vocabulary as `%{"op" => ...}` payloads: `sort`, `page`, `search`, `page_size`, `filter`, `clear_filters`. Never invent per-action events (`"sort_by_name"`, `"filter_status"`). A LiveView already wired for an event-mode data_table gains a filter bar without a single new handler clause - the bar speaks the same grammar.

Normalization you get for free: a `values` list is always `:in`; a missing `filter_op` is the clear button's payload (removal); `between` pairs `value`/`value2` into `[min, max]` and a half-empty range reads as removal; valueless ops (`is_empty`, `is_not_empty`) store `value: true`. State mutations (`put_filter/4`, `toggle_sort/2`, `put_search/2`, `put_page_size/2`) all reset `page: 1` - a reordered page 7 is meaningless. `toggle_sort` cycles asc, desc, removed.

Operators describe user intent, not SQL: `:between` is INCLUSIVE of both bounds; `:eq` folds case (byte-exact equality would arrive as a new operator, never a change to this one); `:is_empty` matches nil/`""`/`[]` but not `" "`. Do not contradict these when writing engines or docs.

## fields: is a security boundary

`fields:` is REQUIRED on every `State.from_params/2` and `State.handle_op/3` call. It is a whitelist: an op naming a field outside it is silently dropped, unknown ops are dropped, page/page_size are clamped (`:max_page_size`, default 100), and no atoms are ever created from user input. List exactly the fields that are sortable/filterable - nothing more. Never widen it to all schema fields for convenience; never bypass it by building filters from raw params. Silent dropping is the contract: hostile or stale params degrade to a smaller query, never a crash or an atom leak.

## Query state vs UI state - two channels

Sort/filter/search/page are query state: they live in State and round-trip URLs in link mode. Selection, column visibility and column order are UI state: they ride the `on_ui` event (defaulting to `on_change`) with `select` / `select_all` / `clear_selection` / `toggle_column` / `move_column` ops and never touch URLs or State.

**`handle_op` ignores UI ops by design.** When you use `selectable` or `column_toggle`, write the UI clauses yourself or the checkboxes are dead with no error:

- `"select"` - toggle the id in a list; a MapSet plus three clauses is the whole backend
- `"select_all"` - page sweep: `Enum.all?` then subtract or uniq-append
- `"clear_selection"` - empty the list
- `"toggle_column"` - toggle the field in `hidden_columns`
- `"move_column"` - delegate the `field`/`dir` delta to `PetalComponents.DataTable.move_column/4` against YOUR current order - race-free under rapid clicks

Events post STRING values - keep `selected` and `hidden` assigns as string lists (`["1", "7"]`, `["amount"]`); integers or atoms make membership checks silently miss. Use ONE identity function as both the component's `row_id` and select_all's page sweep - they must never disagree, and it must uniquely identify records across ALL pages.

Loading and empty are designed in: `loading` swaps the page for skeleton rows; the built-in empty state is filters-aware and offers clear-filters in the right mode. Use them before writing custom markup; override only via the `:empty` slot (`<.empty>` drops in).

## Forms - the field layer first

Two layers, pick deliberately. `<.field>` bundles label + input + error + help text and is the common case inside `<.form> (Phoenix core, not a petal component)`; standalone primitives (`<.text_input>`, `<.select>`, `<.checkbox>`) are for composing your own field layout. The binding idiom is `field={@form[:name]}`:

```heex
<.form for={@form} phx-submit="save">
  <.field field={@form[:name]} label="Name" />
  <.field field={@form[:email]} type="email" label="Email" />
  <.button type="submit">Save</.button>
</.form>
```

Type routes the control: `<.field type="text" | "email" | "select" | "checkbox" | "switch" | "radio-group" | "combobox" | ...>`. Wrap forms in `<.card><.card_content>` on standalone pages; put them directly inside `<.modal title="..." max_width="md">` for edit-in-place.

Reach for `<.combo_box>` whenever a `<.select>` has more options than someone wants to scroll. The real control is a hidden `<select>` a hook keeps in sync, so changesets, `phx-change` and form recovery behave exactly like a plain select. Always pass `label` (or go through `<.field>`) - without it the placeholder is all a screen reader has. Remote search: `remote_options_event_name` (plus `remote_options_target={@myself}` from a LiveComponent); the handler replies `{:reply, %{results: results}, socket}` with `%{text:, value:}` maps.

## Chat family - namespaced, composed

Not imported by `use PetalComponents` - `alias PetalComponents.Chat` and call namespaced (`<Chat.conversation>`). Needs optional `{:mdex, "~> 0.12"}` for markdown.

The composition: `conversation` is the scroll surface; `chat_message` per turn; `markdown` / `streaming_text` / `rich_text` render content; `prompt_input` is the composer. Around a message compose the satellites: `chat_sources` and `citation` for grounding, `message_attachments` for files, `tool_call` and `reasoning` for agent traces, `questionnaire` for structured asks, `suggestions` for follow-ups, `message_actions` with `action_button` / `copy_button` for per-message controls, `chat_error` and `marker` for stream states. Look up each schema before wiring - the family is the fastest-moving surface in the library.

## Overlays - pick by contract, never hand-roll

Never hand-roll `fixed inset-0` overlay divs, manual dropdown JS, or focus traps - every overlay contract ships:

- `<.modal>` - light-dismissible general dialog; header/footer fixed, only content scrolls; `:footer` slot for the action band
- `<.alert_dialog>` - native `<dialog>`, `role="alertdialog"`: one question, two answers, backdrop clicks do NOT dismiss. Use it when the user must choose; use modal when escaping cheaply is right
- `<.command_dialog>` - the command palette in a native `<dialog>`, opened with the Cmd/Ctrl key binding or `open_command/1`
- `<.slide_over>` - `origin` is one of `"left" | "right" | "top" | "bottom"`. `origin="bottom"` is a first-class mobile drawer, not a full-width panel: grab-handle pill (default true only for bottom), drag-down-to-dismiss (pointer-only; Escape and the close button always work), `snap_points={[0.4, 0.9]}` with `initial_snap`, and `scale_background`
- `<.dropdown>` / `<.context_menu>` for menus, `<.popover>` / `<.hover_card>` / `<.tooltip>` for anchored surfaces, `<.toast_group>` plus `send_toast/3` for notifications

Dropdown placement: use `side` (`"bottom" | "top" | "left" | "right"`) and `align` (`"start" | "end"`). The older `placement` / `direction` attrs still work but are superseded - new wins when both appear. Naming a side skips the measuring hook; side-out panels deliberately never flip.

## Naming gotchas

- No `pc_` prefix on function names, ever. `pc-` (hyphen) is the CSS class prefix only (`pc-button`, `pc-modal`) - it never appears in HEEx tags
- The sidebar family is `sidebar_shell` / `sidebar_nav` / `sidebar_group` / `sidebar_item` / `sidebar_trigger` - there is no `<.sidebar>`
- `<.combo_box>` (underscore) is the searchable select; `<.select>` is the plain primitive
- Through `<.field type="combobox">` the anatomy attr is `combo_variant`, NOT `variant` (`:variant` already belongs to radio-card there). On bare `<.combo_box>` it IS `variant`. `combo_variant="trigger"` is the picker shape the data table's filter editor uses
- Dropdown `placement` / `direction` are superseded by `side` / `align` (above)
- `user_dropdown_menu`'s `user_menu_items` is now optional - a custom panel goes in the inner block; `dropdown_menu_row` is the `role="none"` control row for things that are not commands
- Icons are `<.icon name="hero-*">` and the class name must be a source literal - runtime-built `"hero-#{icon}-micro"` strings get purged by the Tailwind scan

## Agents get this wrong - do the opposite

1. Look up the schema before writing any attr - MCP `get_component`, bundled schemas.json, or `deps/petal_components` source, in that order. Never from memory
2. Write the UI-state clauses (`select`, `select_all`, `clear_selection`, `toggle_column`, `move_column`) whenever you pass `selectable` or `column_toggle` - `handle_op` ignores them silently
3. Keep event-posted ids and column names as strings in assigns - never integers or atoms
4. Always pass `fields:` to `from_params/2` and `handle_op/3`, scoped to exactly the sortable/filterable set
5. Alias `PetalComponents.Chat` explicitly - `use PetalComponents` does not import it
6. Spread the whole hook set once (`hooks: { ...PetalComponents }`) - never cherry-pick individual hooks
7. Bring your own ECharts for `<.chart>` (`window.echarts`) - it renders empty without it; `<.sparkline>` is server SVG and needs nothing
8. Confirm Tailwind v4 (`@import "tailwindcss";` in app.css) - petal_components 4.x does not work on v3
9. Prefer `<.data_table>` over hand-wiring `<.table>` + pagination + inputs for anything beyond a static list
10. Use the built-in loading skeletons and filters-aware empty state before writing custom ones
