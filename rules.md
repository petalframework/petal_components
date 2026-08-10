# petal_components - rules for AI coding assistants

petal_components is a shadcn-style component library for Phoenix LiveView. Components live in modules under `PetalComponents.*` and are called as plain HEEx tags (`<.button>`, `<.modal>`, `<.table>`) once you `use PetalComponents`. CSS classes use a `pc-` prefix for styling overrides (`pc-button`, `pc-button--primary`). Use these rules to write idiomatic Phoenix UI instead of inventing raw Tailwind markup.

Drop this file into your AI coding tool's rules system (Cursor `.cursorrules`, Claude Code `CLAUDE.md`, Codex `AGENTS.md`, Continue rules, etc.) when working in a Phoenix project that has `petal_components` installed.

## Installing petal_components

When the user says "install petal_components" (or you're starting in a Phoenix project that doesn't have it yet), follow these steps. They are idempotent - safe to re-run if any step is partially done.

### 1. Add the dependency

Open `mix.exs`. In the `deps/0` function, add this line if it's not already there:

```elixir
{:petal_components, "~> 4.0"}
```

If the user wants the chat components (`PetalComponents.Chat` — `<Chat.conversation>`, `<Chat.markdown>`, `<Chat.rich_text>`, …), also add the optional `{:mdex, "~> 0.12"}`. The rest of the library needs no extra deps. Note the `Chat` family is not pulled in by `use PetalComponents` — `alias PetalComponents.Chat` and call it namespaced.

### 2. Fetch dependencies

```sh
mix deps.get
```

### 3. Configure Tailwind CSS

Open `assets/css/app.css`. Find the `@import "tailwindcss";` line and add the two lines below it:

```css
@import "tailwindcss";
@source "../deps/petal_components/**/*.*ex";
@source not "../deps/petal_components/lib/petal_components/showcase";
@import "../deps/petal_components/assets/default.css";
```

The `@source` line tells Tailwind to scan petal_components source for class usage. The `@source not` line skips the `showcase/` example modules - those power petal.build's own docs, not your app, so scanning them would only add unused utility classes to your CSS. (`@source not` needs Tailwind v4.1+. On v4.0 it's harmless to drop the line; you just get a little extra CSS.) The `@import` line brings in the default component styles (the `pc-*` CSS prefix).

If `@import "tailwindcss";` is missing, the project is on Tailwind v3 and petal_components 4.x will not work. Tell the user to upgrade to Tailwind v4, or pin to `petal_components ~> 1.0` for Tailwind v3 support.

### 4. Import the components in your web module

Find `lib/<your_app>_web.ex`. In umbrella apps it lives at `apps/<your_app>_web/lib/<your_app>_web.ex`. The file defines macros like `def html`, `def controller`, `def live_view`.

Inside `def html`, locate the `quote do` block and add `use PetalComponents`:

```elixir
def html do
  quote do
    use Phoenix.Component
    use PetalComponents
    # ... existing imports
  end
end
```

`use PetalComponents` imports every component so you can call them as `<.button>`, `<.modal>`, etc. without explicit aliases. If a `use PetalComponents` line is already present, skip this step.

### 5. Register the JS hooks

petal_components v4 ships a bundled JS hook set - toasts, the command palette and its trigger, the colour-scheme switch, carousel, charts, local time, sliders, OTP input, the chat family, popover, the navigation menu's hover mode, the effects, and the enhanced inputs (everything else is CSS + LiveView.JS only). You never register hooks individually - spread the whole set once. Open `assets/js/app.js`, import the hooks, and merge them into your `LiveSocket`:

```js
import PetalComponents from "../../deps/petal_components/assets/js/petal_components"

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { ...PetalComponents }, // merge with existing hooks: { ...MyHooks, ...PetalComponents }
})
```

If the project has no `assets/js/app.js` (an API-only or minimal app), skip this — the hooks are only needed for those interactive components.

### 5b. Charts (only if the app uses `<.chart>`)

The `<.chart>` component drives Apache ECharts but does not bundle it — the engine is bring-your-own, exactly like Alpine. Add it ONLY when the app actually renders a `<.chart>`; skip otherwise. Either a script tag in the root layout:

```html
<script src="https://cdn.jsdelivr.net/npm/echarts@5/dist/echarts.min.js"></script>
```

or `npm i echarts` plus `import * as echarts from "echarts"; window.echarts = echarts;` in `app.js`. The `PetalChart` hook picks it up from `window.echarts` and warns in the console if it's missing (the chart area renders empty). `<.sparkline>` is pure server-rendered SVG and needs nothing.

### 6. Verify

```sh
mix compile
```

Should compile cleanly. To smoke test, drop `<.button>Hello</.button>` in any HEEx template.

### 7. Brand colours (optional)

Components work out of the box: petal_components ships default colour ramps (blue `primary`, pink `secondary`, semantic hues, zinc `gray`). They are soft defaults (`@theme default`), so a plain `@theme` block in the project's `app.css` wins no matter where it sits relative to the import:

```css
@theme inline {
  --color-primary-50: var(--color-violet-50);
  --color-primary-100: var(--color-violet-100);
  /* ...one line per stop, 50-950, for any ramp you want to change... */
  --color-primary-950: var(--color-violet-950);
}
```

The roles: `primary` is the base action colour and tints every variant of every component (solid fills, outline borders, ghost text); `secondary` is a second brand accent with the same rule; `info`/`success`/`warning`/`danger` carry meaning and should stay recognisable; `gray` is the neutral chrome. Map a role to any Tailwind hue by referencing that hue's variables, or use literal values.

One deliberate choice to know about: the `gray` role ships Tailwind's **zinc** values under the gray name, so one coherent neutral runs through every component. Because `--color-gray-*` is a shared namespace, this also sets what the app's own `text-gray-*` / `bg-gray-*` utilities render as. To use a different neutral, remap it like any other role (`--color-gray-50: var(--color-slate-50);` and so on per stop - slate, stone, neutral and zinc all remain available as variables). The one palette a `var()` cannot reach is Tailwind's original gray itself (its values only ever lived under the name petal_components now occupies), so restoring it is a one-line import after the default styles:

```css
@import "../deps/petal_components/assets/default.css";
@import "../deps/petal_components/assets/tailwind-gray.css";
```

### Installation rules of thumb for AI agents

- Read each file before editing. Do not blind-patch.
- If the project already uses `petal_components`, skip the steps that are already done. Report what was already in place.
- After installing, suggest calling `list_components` to see what's available.

## Hard rules

1. **Prefer a petal_components tag over raw HTML.** If you would reach for a `<button>`, `<table>`, `<input>`, `<div role="dialog">`, `<select>`, or any other common UI primitive, check for a petal_components equivalent first (`<.button>`, `<.table>`, `<.text_input>`, `<.modal>`, `<.select>`).
2. **Do not invent Tailwind soup for things petal_components already does.** No hand-rolled modal divs, no manual dropdown JS, no DIY form labels. There is almost certainly an existing component for it.
3. **Look up the schema before guessing attrs.** Do not assume attr names from memory. Call `list_components` and `get_component` (see below) to get the real attr/slot signature before writing HEEx.
4. **Call components as plain HEEx tags after `use PetalComponents`.** `<.button>`, `<.modal>`, `<.table>`, `<.card>`, etc. If you have not imported, qualify with the module: `<PetalComponents.Button.button />`. Note: the `pc-*` prefix you see in source is the CSS class prefix for styling, not part of the function name.
5. **Components work in both live and dead views.** Interactivity is Phoenix.LiveView.JS only (no Alpine.js as of v4). Many components (toasts, command palette, colour scheme, carousel, charts, chat, enhanced inputs and more) use bundled JS hooks — register the whole set once in your LiveSocket: `import PetalComponents from "../../deps/petal_components/assets/js/petal_components"` then `hooks: { ...PetalComponents }`.
6. **Form inputs come in two layers, pick deliberately.** Use `<.field type="..." />` when you want label + input + error + help text bundled (the common case in form contexts). Use the standalone primitives (`<.text_input>`, `<.select>`, `<.checkbox>`, etc.) when composing your own field layout.

## Discovering components

### Recommended: the MCP server

Install once:

```sh
claude mcp add petal --transport http https://mcp.petal.build/mcp
```

Then call:

- `list_components` returns every component with a one-line summary
- `get_component <name>` returns the full schema (attrs, slots, defaults, allowed values) plus a usage example

Equivalent installs exist for Cursor, Windsurf, Continue, Codex, and Cline. See https://petal.build/petal-components for setup snippets.

### Fallback: static reference

If the MCP is unavailable, the source of truth is https://hexdocs.pm/petal_components. Each `lib/petal_components/*.ex` module documents its component with `attr` and `slot` declarations you can read directly.

## Naming conventions

- **HEEx tags**: plain component name with a leading dot, e.g. `<.button>`, `<.modal>`, `<.breadcrumbs>`. No `pc_` prefix on the function name.
- **Modules**: `PetalComponents.Button`, `PetalComponents.Modal`, `PetalComponents.Breadcrumbs`. Importing via `use PetalComponents` is the common path.
- **Form primitives**: `<.text_input>`, `<.email_input>`, `<.select>`, `<.checkbox>`, `<.switch>`, `<.textarea>`, etc. (all defined in `PetalComponents.Form`).
- **Field wrapper**: `<.field type="text" | "email" | "select" | "checkbox" | "switch" | "radio-group" | ...>`
- **CSS classes**: use the `pc-` prefix for styling overrides (e.g. `pc-button`, `pc-button--primary`, `pc-modal`). This is the only place `pc-` appears.

## Common patterns

### Form in card

```heex
<.card>
  <.card_content>
    <.form for={@form} phx-submit="save">
      <.field field={@form[:name]} label="Name" />
      <.field field={@form[:email]} type="email" label="Email" />
      <.button type="submit">Save</.button>
    </.form>
  </.card_content>
</.card>
```

### Modal with form

```heex
<.modal title="Edit user" max_width="md">
  <.form for={@form} phx-submit="save">
    <.field field={@form[:name]} label="Name" />
    <.button type="submit">Save</.button>
  </.form>
</.modal>
```

### Table with row actions

```heex
<.table>
  <:col :let={user} label="Name">{user.name}</:col>
  <:col :let={user} label="Email">{user.email}</:col>
  <:col :let={user} label="">
    <.button size="xs" variant="outline" phx-click="edit" phx-value-id={user.id}>
      Edit
    </.button>
  </:col>
</.table>
```

### Data table (sortable, paged, filtered - the full surface)

For anything beyond a static table, reach for `<.data_table>` instead of hand-wiring `<.table>` + pagination + inputs. One `DataTable.State` struct drives the whole surface; `Engine.List` runs it over an in-memory list (or run the state against your own query layer).

```heex
<.data_table
  id="orders"
  rows={@rows}
  state={@table}
  on_change="table"
  searchable
  selectable
  selected={@selected}
  row_id={&row_key/1}
  column_toggle
  hidden_columns={@hidden}
  page_size_options={[10, 25, 50]}
>
  <:col :let={o} field={:customer} sortable filterable="text">{o.customer}</:col>
  <:col :let={o} field={:status} filterable="select" options={["paid", "pending", "refunded"]}>
    <.badge size="sm" variant="soft" label={o.status} />
  </:col>
  <:col :let={o} field={:amount} sortable align="right" filterable="number">${o.amount}</:col>
  <:bulk_action :let={ids}>
    <.button size="sm" variant="soft" color="danger" phx-click="archive" phx-value-ids={Enum.join(ids, ",")}>
      Archive {length(ids)}
    </.button>
  </:bulk_action>
</.data_table>
```

The event-mode backend: UI-state ops (selection, column visibility) get their own clauses, and everything else is query state through `State.handle_op/3` (sort/page/search/page_size/filter/clear_filters). Do NOT skip the UI clauses when using `selectable`/`column_toggle` - `handle_op` ignores those ops by design:

Events post STRING values, so keep the `selected` and `hidden` assigns as string lists (`["1", "7"]`, `["amount"]`) - mixing in integers or atoms makes the membership checks below silently miss:

```elixir
def handle_event("table", %{"op" => "select", "id" => id}, socket) do
  {:noreply, update(socket, :selected, fn sel ->
    if id in sel, do: List.delete(sel, id), else: sel ++ [id]
  end)}
end

def handle_event("table", %{"op" => "select_all"}, socket) do
  page_ids = Enum.map(socket.assigns.rows, &row_key/1)
  sel = socket.assigns.selected

  {:noreply,
   assign(socket, :selected,
     if(Enum.all?(page_ids, &(&1 in sel)), do: sel -- page_ids, else: Enum.uniq(sel ++ page_ids))
   )}
end

def handle_event("table", %{"op" => "clear_selection"}, socket),
  do: {:noreply, assign(socket, :selected, [])}

def handle_event("table", %{"op" => "toggle_column", "field" => f}, socket) do
  {:noreply, update(socket, :hidden, fn h ->
    if f in h, do: List.delete(h, f), else: h ++ [f]
  end)}
end

# move_column (reorderable): apply the field/dir delta to YOUR current
# order via the provided helper - race-free under rapid clicks
def handle_event("table", %{"op" => "move_column", "field" => f, "dir" => dir}, socket) do
  fields = [:customer, :status, :amount]
  {:noreply, update(socket, :column_order, &PetalComponents.DataTable.move_column(&1, fields, f, dir))}
end

# ONE identity function, used as both the component's row_id and
# select_all's page sweep - they must never disagree
defp row_key(row), do: to_string(row.id)

def handle_event("table", params, socket) do
  state = State.handle_op(socket.assigns.table, params, fields: [:customer, :status, :amount])
  {rows, state} = Engine.List.run(all_orders(), state)
  {:noreply, assign(socket, rows: rows, table: state)}
end
```

Selection and column visibility are UI state (the clauses above; move them to a separate `on_ui` event if you prefer) - keep them in assigns, never in URLs. For URL-driven tables pass `path` instead of `on_change`: every interaction becomes a patch URL and `State.from_params/2` in `handle_params` is the whole backend. `row_id` must uniquely identify records across all pages.

### Alert / inline feedback

```heex
<.alert color="success" heading="Saved">
  Your changes have been saved.
</.alert>
```

### Loading state on a button

```heex
<.button loading={@saving} phx-click="save">Save</.button>
```

## When in doubt

Stop guessing. Call `list_components` to see the full catalogue, then `get_component <name>` for the exact schema before writing HEEx. The MCP exists so you never have to invent component APIs from training data.

## Companion libraries

- **petal_pro** is the production Phoenix SaaS boilerplate built on petal_components. Use it as a reference for real-world composition (auth pages, dashboards, billing UI, tables with filters, etc.).
- **petal-components-mcp** is this rules file's companion - the MCP server that exposes schemas. Source: https://github.com/petalframework/petal-components-mcp.
