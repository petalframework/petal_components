# The Petal design system

> Same doctrine, two copies: this is the human version. The copy agents load is `skills/petal-design/` (SKILL.md plus `references/`). Change one, change the other.

petal_components ships a design system, not just a pile of components. The system is small enough to hold in your head: seven semantic colour ramps, one radius knob, three type knobs, a dark-mode material, a text emphasis scale, and a handful of composition rules. The components are built from it, and anything you hand-write next to them should be too. Done right, your custom markup is indistinguishable from a shipped component.

This guide is for the developer or designer writing HEEx and CSS in a Phoenix app that uses the library. It covers the token layer, light and dark rules, variants, spacing and type, the composition patterns that keep pages consistent, and a review checklist you can apply by hand to a diff. Every value here is copied from `assets/default.css`. If the two ever disagree, the CSS is right and this page needs a fix.

## 1. The token layer

`default.css` opens with a Tailwind v4 `@theme default` block that defines seven semantic ramps, eleven OKLCH stops each (50 to 950):

```
--color-primary-{50..950}     default: Tailwind blue
--color-secondary-{50..950}   default: Tailwind pink
--color-info-{50..950}        default: sky
--color-success-{50..950}     default: green
--color-warning-{50..950}     default: yellow/amber
--color-danger-{50..950}      default: red
--color-gray-{50..950}        default: Tailwind ZINC values under the gray name
```

`@theme default` marks every value as a soft fallback, so a plain `@theme` block in your app wins regardless of import order. There are no flat shadcn-style tokens (`--background`, `--muted`). Ramps are the vocabulary, and components hardcode which step plays which role.

Write utilities only against these seven ramp names. `bg-primary-600`, `text-gray-500` and `border-danger-500` ride the theme. `bg-blue-600` and `text-zinc-500` do not: they look right until someone rebrands, and then they are the only things on the page that did not move.

### The gray dial

`gray` is the semantic neutral, not a literal palette. The library ships zinc under the gray name, which also redefines what your own `text-gray-*` utilities render as. Three consequences:

- Never write literal palette names (`slate-*`, `zinc-*`, `stone-*`, `neutral-*`) in chrome. Use the `gray` ramp; the dial does the rest.
- An app remaps gray per stop in `@theme inline`: `--color-gray-500: var(--color-slate-500);` and so on for all eleven stops. petal_pro and petal_marketing dial gray to slate this way.
- To get stock Tailwind gray back instead, import `tailwind-gray.css` from the package assets after `default.css`. That file is a hard `@theme` (not `default`) of literal stock-gray OKLCH values. Importing it is the override, and the literals are required there: once `--color-gray-*` holds zinc there is no variable left to reference.

## 2. Radius: the `--pc-radius` knob

One public token controls every corner. Read it with its fallback: `var(--pc-radius, 0.625rem)`. Never hardcode `rounded-lg` or `rounded-xl` on a Petal-adjacent surface; it opts that surface out of the one-knob theme.

There are four derivations. Pick by the shape of the element:

| Case | Formula |
|---|---|
| Base control (button, input, chip) | `border-radius: var(--pc-radius, 0.625rem);` |
| Concentric inner element (chip inside a field) | `border-radius: max(calc(var(--pc-radius, 0.625rem) - 0.25rem), 0.25rem);` |
| Large card or panel (amplified, capped) | `border-radius: min(calc(var(--pc-radius, 0.625rem) * 1.2), 1.25rem);` |
| Tall-element clamp: anything that can grow past one line (textarea, multi-select, alert, multi-line group) | `border-radius: min(var(--pc-radius, 0.625rem), 1rem);` |

The clamp keeps `full` meaning "pill" for one-line controls and stops it meaning "ellipse" for multi-line ones. One-line inputs deliberately stay unclamped, because pill is a real style. Menu items inside a clamped panel go concentric off the clamped value: `max(calc(min(var(--pc-radius, 0.625rem), 1rem) - 0.25rem), 0px)`.

One more public hook lives next to the radius: `--pc-button-solid-fg` (fallback `#fff`) is the text colour on solid primary fills. Text on a custom solid-primary surface reads `color: var(--pc-button-solid-fg, #fff)`, never a hardcoded `text-white`, so a light brand primary can flip its button text dark.

## 3. Type: `--pc-font-heading`, `--pc-font-body`, `--pc-font-mono`

Like `--pc-radius`, the package only reads these and never defines them. Every fallback chain ends in `inherit` or in the value the surface used before the tokens existed, so an app that sets nothing keeps its own stack. The chains, copied from `default.css`:

| Token | Read as | Bound to |
|---|---|---|
| `--pc-font-heading` | `var(--pc-font-heading, var(--pc-font-body, inherit))` | `pc-h1` to `pc-h5`, prose headings |
| `--pc-font-body` | `var(--pc-font-body, inherit)` | typography reading surfaces, `.prose`, chat bubble and markdown |
| `--pc-font-mono` | `var(--pc-font-mono, var(--font-mono, ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace))` | inline code, chat code, tool output, showcase props tables |

For custom markup: a Petal-adjacent heading reads `font-family: var(--pc-font-heading, var(--pc-font-body, inherit))`; custom mono reads the full mono chain above.

A few finer points:

- Numeric UI chrome (counters, page numbers, day grids, "+N" chips) carries `lining-nums`. Fonts whose default digits are old-style figures vary height by design, which reads as mis-centred in a chip; the feature is a no-op elsewhere. Component-owned numeric chrome ships it; slot and user content is never imposed on, so callers opt their own digits in with the utility.
- Kbd deliberately tracks body (`var(--pc-font-body, var(--font-sans, ...))`). Never bind a key cap to the mono token.
- Chat markdown headings stay on the body face. The chat scale is dense, and a display face at `text-sm` reads as a glitch.
- A whole-app face is not these tokens. That is the host's `@theme { --font-sans: ... }`, which preflight applies at `html`.
- Type-scale tokens (size, leading, measure) do not exist. They are demand-gated, the same call as a field density family.

## 4. Dark mode: the gray-400 ghost material

Dark mode is class-based (a `.dark` ancestor, the `dark:` variant). Light chrome is opaque. Dark translucent chrome is always alpha-of-gray-400: never alpha-of-white, never opaque 800 or 700 fills on chrome. gray-400 is the ramp's chroma peak, so the ghost carries the dial's hue (a slate ghost looks slate, a zinc ghost looks zinc). White alpha only works when the neutral is colourless, which it usually is not.

The alpha ladder, verified against `default.css`:

| Role | Light | Dark ghost |
|---|---|---|
| Resting surface (outline-button bg, table header; input fill is `bg-transparent` in light) | `bg-gray-50` / `bg-transparent` | `dark:bg-gray-400/8` |
| Hover wash and panel hairline border | `hover:bg-gray-100` / `border-gray-200` hairline | `dark:hover:bg-gray-400/17` / `dark:border-gray-400/17` |
| Input border, active wash | `border-gray-300` / `active:bg-gray-*` | `dark:border-gray-400/25` / `dark:active:bg-gray-400/25` |

Opaque dark surfaces exist for panels only: page, card and dropdown white flips to `dark:bg-gray-900`; nested secondary chrome to `dark:bg-gray-800`; code wells, rarely, to `dark:bg-gray-950`. The one blessed white-alpha family is the barely-there muted fill: `dark:bg-white/[0.03]` (striped rows), `/[0.04]` (muted card fill), `dark:hover:bg-white/[0.06]` (row hover). Nothing brighter.

Border grammar: structural hairline `border-gray-200` with `dark:border-gray-400/17` on panels (`dark:border-gray-800` for full-width rules like `hr`); input border `border-gray-300 dark:border-gray-400/25`.

Every light-mode colour in a class string gets a `dark:` pair in the same string. No unpaired colours. One gotcha: `dark:` inside a `::-webkit-*` pseudo-element rule silently no-ops. Set a CSS variable on the real host element and reference it from the pseudo-element instead.

## 5. Text emphasis: three tiers plus glyphs

There are no named text tokens, only exact pairs enforced by convention:

| Tier | Classes | Use for |
|---|---|---|
| 1 Headings / strong | `text-gray-900 dark:text-white` (or `dark:text-gray-100`) | headings, card titles, input text |
| Form labels | `text-gray-900 dark:text-gray-200` | field labels (between tiers 1 and 2 in dark; see section 8) |
| 2 Body | `text-gray-700 dark:text-gray-100` (menu items: `dark:text-gray-300`) | body copy, menu items, blockquote |
| 3 Muted / support | `text-gray-500 dark:text-gray-400` | help text, descriptions, card content, lead |
| Glyphs / placeholder | `text-gray-400 dark:text-gray-500` | placeholder, chevrons, indicator icons |

Note the crossover in dark: muted brightens (500 to 400) while glyphs dim (400 to 500). Dark compresses toward the middle of the ramp. Never invent `dark:text-gray-600` for copy, and never use `text-gray-400` for body text. Interactive text brightens on hover and never dims: `text-gray-400 hover:text-gray-700 dark:hover:text-gray-200`.

## 6. Focus ring

The house recipe, on the focusable element itself:

```
focus:outline-hidden focus-visible:ring-2 focus-visible:ring-primary-500/50
```

Fields add `focus-visible:border-primary-500` and animate with `transition-[color,box-shadow] duration-200 ease-out`. Use `focus-visible:`, not `focus:`, for the ring: keyboard users get it, mouse clicks do not. When the real control is somewhere else:

- Wrapper containing a real input: `focus-within:border-primary-500 focus-within:ring-2 focus-within:ring-primary-500/50`
- Fake control next to a hidden peer input: `peer-focus-visible:ring-2 peer-focus-visible:ring-primary-500/50`
- Error state swaps the hue and keeps the shape: `border-danger-500 ring-2 ring-danger-500/20 focus-visible:border-danger-500 focus-visible:ring-danger-500/40 dark:border-danger-500/70`

No ring offsets and no full-opacity rings in new markup. The lone library exception is the button group's offset ring; do not copy it. Never `outline-none` without a visible replacement.

## 7. Fills, variants and colour as accent

Solid fills walk the ramp: `bg-primary-600 hover:bg-primary-700 active:bg-primary-800`, with text on them set to `var(--pc-button-solid-fg, #fff)`. Never `hover:opacity-90` or `hover:brightness-*` on a solid; the ramp step is the hover state.

The fill vocabulary on buttons, badges and alerts shares names, and the names mean the same thing everywhere:

- **solid**: the ramp walk above. The primary action.
- **soft**: a tint in light (`bg-primary-100 text-primary-800`) that adapts to dark mode as a translucent wash (`dark:bg-primary-500/15 dark:text-primary-300`). Reach for this when you want a tinted surface that holds up in both modes.
- **light**: the same light tint, but it stays light in both modes (`dark:bg-primary-200 dark:text-primary-800`). Use it when the surface really should read as a light chip against dark chrome.
- **outline**: transparent fill, a hairline in the hue (`border-primary-600/30`), and the ghost material in dark (`dark:bg-gray-400/8 dark:border-primary-500/40`).
- **ghost**: no fill and no border until hover, then the same tint soft uses (`hover:bg-primary-100`, `dark:hover:bg-primary-500/15`).

On buttons, `inverted` and `shadow` are legacy and slated for removal in a future major; prefer `outline`, and compose effects like `border_beam` or `shine_border` for flourish. On alerts, `callout` is the toast-cohesive form: a neutral panel surface, a coloured left accent bar and a solid kind icon.

That last variant is the general rule. Colour is an accent, never paint: keep the surface neutral and let the semantic hue arrive as an icon and a hairline, not as a tinted background flood. Hover washes are `hover:bg-gray-100` in light and `dark:hover:bg-gray-400/17` in dark. Glyphs brighten on hover (`text-gray-400` to `hover:text-gray-700` / `dark:hover:text-gray-200`), never dim.

Disabled is `disabled:opacity-50 disabled:cursor-not-allowed` (plus `active:scale-100` if the base scales). Do not gray-swap colours for disabled states.

## 8. Spacing, density, elevation, motion

- Card rhythm: `px-6 pt-6` header, `p-6` content, `px-6 pb-6` footer, `gap-2` in footers, `gap-4` between the header title block and its actions.
- Form rhythm: field wrapper `mb-6`, label `block mb-2 text-sm font-medium text-gray-900 dark:text-gray-200`, error `mt-1.5 text-sm text-danger-600 dark:text-danger-400`, help text `mt-2 text-sm text-gray-500 dark:text-gray-400`.
- Density is designed, not tokenised. There is no global density token. Use per-component `size` attrs; `md` is the form default; do not mix `sm` and `md` mid-form.
- Elevation: `shadow-xs` resting (cards, buttons, inputs); floating panels `shadow-lg` or `shadow-xl` (dropdown, command, popover). Opt-in `*-shadow` button variants exist; do not introduce `shadow-md` middles in new markup.
- Transitions: `transition-colors` on chrome, `duration-200 ease-out` by default, `duration-150` on dense hover rows (menu items, table rows); fields use `transition-[color,box-shadow]`. Reserve `transition-all` for buttons and genuinely multi-property animations.
- Tap targets grow with an invisible pseudo-element, never by growing the element itself (which shifts layout): `::before { @apply absolute -inset-2 }`, with `relative` on the host.
- Custom `@keyframes` must animate the exact property Tailwind utilities emit: `translate`, not `transform`. A keyframe on the wrong property silently loses to the utility.
- Heroicon class names must be source-literal. `name="hero-check-micro"` works; `name={"hero-#{icon}-micro"}` gets purged by the Tailwind source scan.

## 9. Theming: executing a rebrand

All theming happens in one file in your app: the main CSS file that imports petal_components, typically `assets/css/app.css` or a `colors.css` it imports. Never edit `deps/petal_components/*`. Because the library block is `@theme default`, a plain app-side `@theme` wins wherever it sits.

A worked example: purple brand, slate neutral, sharper corners.

```css
/* app.css - after the petal_components import */
@theme inline {
  /* brand primary: point at a Tailwind ramp per stop... */
  --color-primary-50: var(--color-violet-50);
  --color-primary-100: var(--color-violet-100);
  /* ...continue through every stop 200-900... */
  --color-primary-950: var(--color-violet-950);
  /* ...or drop literal OKLCH/hex per stop for a custom ramp
     (literals are fine here - this is the one place they belong) */

  /* gray dial: remap the neutral to slate, all 11 stops */
  --color-gray-50: var(--color-slate-50);
  /* ...100 through 900... */
  --color-gray-950: var(--color-slate-950);
}

:root {
  --pc-radius: 0.375rem; /* one knob, whole library follows; 0 = square, 9999px = pill */
}
```

The rules:

- Remap all eleven stops of a ramp. A partial remap leaves mismatched steps in the hover and active ladders.
- Use `@theme inline` for `var()` references to Tailwind ramps; plain `@theme` works for literals.
- If the brand primary is light, also set `--pc-button-solid-fg` to a dark value so solid-button text stays readable.
- Dark mode needs no separate theming pass. The ghost material and the text tiers derive from the same ramps.
- Fonts are the three type knobs from section 3. Set `--pc-font-body` alone and headings follow, since `--pc-font-heading` falls back through it.

## 10. Composition patterns

The token rules above make a surface look right. These patterns make a page behave right.

### Reach for the component first

Before typing `<button>`, `<table>`, `<input>`, `<select>` or `<div role="dialog">`, check whether a component already covers it. `<.button>`, `<.table>` and `<.field>` carry focus rings, dark pairs, accessibility and the `pc-*` styling API for free. The full inventory is on the MCP server (`list_components`) and in the module docs.

Two naming rules trip people up. There is no `pc_` prefix on function names, ever: it is `<.button>`, not `<.pc_button>`. `pc-` with a hyphen is the CSS class prefix only (`pc-button`, `pc-button--primary`), used for styling overrides. And Tailwind v4 is a hard gate: `app.css` must contain `@import "tailwindcss";`. If it has `@tailwind base` instead, the project is on v3 and petal_components 4.x will not work; none of the token contract above is loaded.

### Data tables: one State, many surfaces

`PetalComponents.DataTable.State` is the data table's entire backend contract in one struct: `order_by`, `filters`, `search`, `page`, `page_size`, `total`. `total: nil` means cursor or unknown mode; pagination auto-picks numbered mode when the total is known. It is Flop-shaped on purpose and Flop-free on purpose. Anything that can produce this struct can drive `<.data_table>`, and anything that can consume it can execute the query.

When a page needs both a filter bar and a table, create one `%State{}` assign and pass it to both `<.filters>` and `<.data_table>` with the same `on_change` event (or the same `path`). Never maintain separate filter assigns. The payoff is composition with no glue: filter from the bar and the table updates, filter from a column header and a chip appears.

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

The `:field` slot is the registry: `field` (atom, required), `label` (defaults to the humanised field), `options` (strings or `{label, value}` tuples, the same shape as data_table's `:col` options), and `type`, one of `"text"`, `"select"`, `"multi"`, `"date_range"`, `"boolean"`, `"number_range"` (default `"text"`). Each type picks the value editor and an operator subset of `State.ops/0`.

Run the state with an engine: `Engine.List.run(rows, state)` returns `{rows, state}` with `total` filled in. Zero setup, no database. Never write ad-hoc `Enum.filter` and `Enum.sort` around a data_table. Swap in a real query layer later; the State and the templates do not change.

### Two wiring modes: inferred, never both, never neither

Both `<.filters>` and `<.data_table>` infer their mode from which attr you pass. Passing neither `path` nor `on_change` raises `ArgumentError` at render.

**Link mode (`path`)** is the default for top-level index pages. Every change is a `patch` URL built from `State.to_params/1`; the URL is the state store. `handle_params` plus `State.from_params/2` is the whole backend:

```elixir
def handle_params(params, _uri, socket) do
  state = State.from_params(params, fields: [:name, :category, :price])
  {rows, state} = Engine.List.run(all_products(), state)
  {:noreply, assign(socket, rows: rows, table: state)}
end
```

You get shareable sorts and filters, a working back button, and curl-able URLs. `to_params/1` omits defaults so URLs stay clean; `total` never round-trips, because it is a result, not a request. Pass the same `:page_size` default to both `from_params` and `to_params` so they stay symmetric.

**Event mode (`on_change`)** is for LiveComponents (it takes `target` for `@myself`) and embedded widgets. Everything posts op-shaped payloads; `State.handle_op/3` plus an engine re-run is the whole handler:

```elixir
def handle_event("table", params, socket) do
  state = State.handle_op(socket.assigns.table, params, fields: [:name, :email])
  {rows, state} = Engine.List.run(all_rows(), state)
  {:noreply, assign(socket, rows: rows, table: state)}
end
```

Pick one mode per State and use it on every surface sharing that State.

### The op grammar

One event name carries the whole table vocabulary as `%{"op" => ...}` payloads: `sort`, `page`, `search`, `page_size`, `filter`, `clear_filters`. Never invent per-action events (`"sort_by_name"`, `"filter_status"`). A LiveView already wired for an event-mode data_table gains a filter bar without a single new handler clause, because the bar speaks the same grammar.

Normalisation you get for free: a `values` list is always `:in`; a missing `filter_op` is the clear button's payload (removal); `between` pairs `value` and `value2` into `[min, max]`, and a half-empty range reads as removal; valueless ops (`is_empty`, `is_not_empty`) store `value: true`. State mutations (`put_filter/4`, `toggle_sort/2`, `put_search/2`, `put_page_size/2`) all reset `page: 1`, because a reordered page 7 is meaningless. `toggle_sort` cycles asc, desc, removed.

Operators describe user intent, not SQL: `:between` is inclusive of both bounds; `:eq` folds case (byte-exact equality would arrive as a new operator, never a change to this one); `:is_empty` matches nil, `""` and `[]` but not `" "`. Do not contradict these when writing engines or docs.

### `fields:` is a security boundary

`fields:` is required on every `State.from_params/2` and `State.handle_op/3` call. It is a whitelist: an op naming a field outside it is silently dropped, unknown ops are dropped, page and page_size are clamped (`:max_page_size`, default 100), and no atoms are ever created from user input. List exactly the fields that are sortable or filterable, nothing more. Never widen it to all schema fields for convenience, and never bypass it by building filters from raw params. Silent dropping is the contract: hostile or stale params degrade to a smaller query, never a crash or an atom leak.

### Query state vs UI state

Sort, filter, search and page are query state: they live in State and round-trip URLs in link mode. Selection, column visibility and column order are UI state: they ride the `on_ui` event (defaulting to `on_change`) with `select`, `select_all`, `clear_selection`, `toggle_column` and `move_column` ops, and never touch URLs or State.

`handle_op` ignores UI ops by design. When you use `selectable` or `column_toggle`, write the UI clauses yourself or the checkboxes are dead with no error:

- `"select"`: toggle the id in a list; a MapSet plus three clauses is the whole backend
- `"select_all"`: page sweep, `Enum.all?` then subtract or uniq-append
- `"clear_selection"`: empty the list
- `"toggle_column"`: toggle the field in `hidden_columns`
- `"move_column"`: delegate the `field`/`dir` delta to `PetalComponents.DataTable.move_column/4` against your current order, which is race-free under rapid clicks

Events post string values, so keep `selected` and `hidden` assigns as string lists (`["1", "7"]`, `["amount"]`); integers or atoms make membership checks silently miss. Use one identity function as both the component's `row_id` and select_all's page sweep. They must never disagree, and it must uniquely identify records across all pages.

Loading and empty states are designed in: `loading` swaps the page for skeleton rows, and the built-in empty state is filters-aware and offers clear-filters in the right mode. Use them before writing custom markup; override only via the `:empty` slot (`<.empty>` drops in).

### Forms: the field layer first

Two layers, pick deliberately. `<.field>` bundles label, input, error and help text and is the common case inside `<.form>` (Phoenix core, not a petal component). The standalone primitives (`<.text_input>`, `<.select>`, `<.checkbox>`) are for composing your own field layout. The binding idiom is `field={@form[:name]}`:

```heex
<.form for={@form} phx-submit="save">
  <.field field={@form[:name]} label="Name" />
  <.field field={@form[:email]} type="email" label="Email" />
  <.button type="submit">Save</.button>
</.form>
```

Type routes the control: `<.field type="text" | "email" | "select" | "checkbox" | "switch" | "radio-group" | "combobox" | ...>`. Wrap forms in `<.card><.card_content>` on standalone pages; put them directly inside `<.modal title="..." max_width="md">` for edit-in-place.

Reach for `<.combo_box>` whenever a `<.select>` has more options than someone wants to scroll. The real control is a hidden `<select>` a hook keeps in sync, so changesets, `phx-change` and form recovery behave exactly like a plain select. Always pass `label` (or go through `<.field>`); without it the placeholder is all a screen reader has. For remote search use `remote_options_event_name` (plus `remote_options_target={@myself}` from a LiveComponent); the handler replies `{:reply, %{results: results}, socket}` with `%{text:, value:}` maps.

### The Chat family

Not imported by `use PetalComponents`. `alias PetalComponents.Chat` and call namespaced (`<Chat.conversation>`). Markdown needs the optional `{:mdex, "~> 0.12"}` dependency.

The composition: `conversation` is the scroll surface; `chat_message` per turn; `markdown`, `streaming_text` and `rich_text` render content; `prompt_input` is the composer. Around a message compose the satellites: `chat_sources` and `citation` for grounding, `message_attachments` for files, `tool_call` and `reasoning` for agent traces, `questionnaire` for structured asks, `suggestions` for follow-ups, `message_actions` with `action_button` and `copy_button` for per-message controls, `chat_error` and `marker` for stream states. The full walkthrough is in the [streaming chat guide](streaming_chat.md).

### Overlays: pick by contract, never hand-roll

Never hand-roll `fixed inset-0` overlay divs, manual dropdown JS or focus traps. Every overlay contract ships:

- `<.modal>`: light-dismissible general dialog; header and footer fixed, only content scrolls; `:footer` slot for the action band
- `<.alert_dialog>`: native `<dialog>` with `role="alertdialog"`: one question, two answers, backdrop clicks do not dismiss. Use it when the user must choose; use modal when escaping cheaply is right
- `<.command_dialog>`: the command palette in a native `<dialog>`, opened with the Cmd/Ctrl key binding or `open_command/1`
- `<.slide_over>`: `origin` is one of `"left" | "right" | "top" | "bottom"`. `origin="bottom"` is a real mobile drawer, not a full-width panel: grab-handle pill (default true only for bottom), drag-down-to-dismiss (pointer-only; Escape and the close button always work), `snap_points={[0.4, 0.9]}` with `initial_snap`, and `scale_background`
- `<.dropdown>` and `<.context_menu>` for menus; `<.popover>`, `<.hover_card>` and `<.tooltip>` for anchored surfaces; `<.toast_group>` plus `send_toast/3` for notifications

Dropdown placement uses `side` (`"bottom" | "top" | "left" | "right"`) and `align` (`"start" | "end"`). The older `placement` and `direction` attrs still work but are superseded; the new attrs win when both appear. Naming a side skips the measuring hook, and side-out panels deliberately never flip.

### Naming gotchas

- No `pc_` prefix on function names, ever. `pc-` (hyphen) is the CSS class prefix only and never appears in HEEx tags.
- The sidebar family is `sidebar_shell`, `sidebar_nav`, `sidebar_group`, `sidebar_item`, `sidebar_trigger`. There is no `<.sidebar>`.
- `<.combo_box>` (underscore) is the searchable select; `<.select>` is the plain primitive.
- Through `<.field type="combobox">` the anatomy attr is `combo_variant`, not `variant` (`:variant` already belongs to radio-card there). On bare `<.combo_box>` it is `variant`. `combo_variant="trigger"` is the picker shape the data table's filter editor uses.
- `user_dropdown_menu`'s `user_menu_items` is optional; a custom panel goes in the inner block. `dropdown_menu_row` is the `role="none"` control row for things that are not commands.
- Spread the whole hook set once (`hooks: { ...PetalComponents }`); never cherry-pick individual hooks.
- Bring your own ECharts for `<.chart>` (`window.echarts`); it renders empty without it. `<.sparkline>` is server SVG and needs nothing.

## 11. Reviewing a diff by hand

This is the checklist for auditing UI, your own or someone else's. Produce findings, not scores.

### Write the judgment first

Read the diff, the surrounding template and the page it renders. Before searching for anything, write three to five sentences covering: hierarchy (one focal point, with weight and size steps that read in order), spacing rhythm (tight groups, generous separation, more space above a heading than below it), token fidelity (does the surface speak the gray dial plus primary accent, or literal palettes and one-off values), and dark-mode parity (would this screen hold up with dark active).

Write it down before the mechanical checks. Detector output anchors judgment, and an anchored reviewer stops seeing what the searches cannot catch.

### The checks

Run each over the changed `.heex` and `.ex` files plus any touched CSS under `assets/`. Each row gives the thing to search for, why it matters and the fix.

1. **Literal neutral palettes in chrome.** Search for `slate-`, `zinc-`, `neutral-`, `stone-` followed by a number. Gray is the neutral dial; other neutral families fork the palette and break the `@theme` gray remap. Fix: use `gray-*`; if the brand wants a warmer or cooler neutral, remap the gray ramp in `@theme`, never per element. Ignore prose that happens to name a palette.
2. **Bang overrides targeting `pc-*`.** Search app CSS for `!important` and class strings for trailing-bang utilities (`w-4!`). `pc-*` classes are the component's styling API; bangs fight the contract and break on the next release. Fix: a plain rule on the documented `pc-*` class, or the component's own attrs. The library's own doubled-selector plus `!important` icon-sizing contract inside `default.css` is intentional; only flag app CSS.
3. **Hand-rolled overlays.** Search for `fixed` together with `inset-0`. A DIY scrim ships none of the focus handling, escape, scroll lock or dark material that `<.modal>`, `<.slide_over>` and `<.dropdown>` do. Fix: swap to the matching component. Toast or portal containers and full-bleed hero media are not dialogs.
4. **`pc_` function prefix.** Search for `<.pc_`. These functions do not exist. Fix: `<.button>`, `<.modal>`, and so on. Every hit is real.
5. **Deprecated dropdown spellings.** Search for `placement=` and `direction=` on `<.dropdown>` calls. Fix: `placement="left"` to `align="end"`; `placement="right"` to `align="start"`; `direction="up"` to `side="top"`; `direction="down"` to `side="bottom"`; `direction="auto"` drops the attr. It still works, so this is polish.
6. **Keyframes animating `transform`.** Search CSS for `transform:` with `translate`, `scale` or `rotate` inside `@keyframes`. Tailwind v4 utilities emit standalone `translate`, `scale` and `rotate` properties, so the keyframe silently fights the utility and the animation dies. Fix: animate the property the utility emits.
7. **Raw HTML where a component exists.** Search for `<button`, `<table`, `<input`, `<select`, `<textarea` in app templates. Fix: swap to the component. Hidden and CSRF inputs and third-party embeds are fine.
8. **Missing `dark:` pair.** Search for `bg-`, `text-` or `border-` with `white`, `black` or `gray-N` on lines with no `dark:`. Treat hits as candidates and finish with the dark-pair pass below; BEM class names that embed colour tokens are names, not utilities.
9. **`variant` on a combobox field.** Search for `type="combobox"` alongside `variant=`. The field attr is `combo_variant` (`"input"` | `"trigger"`). Direct `<.combo_box>` calls take `variant` legitimately.
10. **White-alpha ghost in dark variants.** Search for `dark:bg-white/N` and `dark:border-white/N`. The dark ghost material is gray-400 alpha: `dark:bg-gray-400/8` surface, `/17` hover and hairline border, `dark:border-gray-400/25` input border. White alpha glows and shifts hue. Deliberate white overlays on imagery or brand panels are the exception.
11. **`~E` sigil.** Search for `~E"`. HEEx only (`~H`); `~E` has no HTML-aware engine. Hard rule.
12. **Tailwind v3 tells.** Search `assets/` for `@tailwind base`, `@tailwind components` or `@tailwind utilities`. v3 directives mean none of the token contract is loaded. Fix: `@import "tailwindcss";` plus `@theme` tokens per section 9.
13. **Unknown attrs on component calls.** List every `<.name>` the diff touches and check each attr written against the real schema: the MCP server's `get_component`, or the `attr`/`slot` declarations in `deps/petal_components/lib/petal_components/*.ex`. An attr absent from the schema, or a value outside its enum (`color="prmary"`), is a major finding. Components that declare a `rest` attr legitimately accept `phx-*`, `data-*`, `aria-*`, `id` and other globals. Compile-time checks only catch literal values in compiled code; the review catches dynamic assigns and code nobody compiled yet.

Standing rules: skip beats false positive, so if you are unsure a hit is real, drop it. A clean sweep is a floor, not proof; the judgment paragraph outranks an empty table. Searches do not strip comments, so confirm a hit is not inside `<%!-- --%>`, `#` or `/* */` before reporting. Exclude petal_components' own source from rows 2, 3, 7 and 10; raw tags, `pc-*` rules and internal white-alpha chrome there are the implementation.

### Dark-pair coverage

Finish row 8's candidates by hand. For every class string in the diff that sets a light-mode colour (`bg-`, `text-`, `border-`, `divide-`, `ring-`), require the dark sibling for the same property in the same class string:

- text, the three tiers: `text-gray-900` pairs with `dark:text-white`; `text-gray-700` with `dark:text-gray-100`; `text-gray-500` with `dark:text-gray-400`
- surfaces: `bg-white` pairs with `dark:bg-gray-900` (panels and cards), or the ghost material `dark:bg-gray-400/8`
- borders: `border-gray-200` and `border-gray-300` pair with `dark:border-gray-400/17` hairline, `dark:border-gray-400/25` on inputs

A `dark:` token for a different property does not count: `bg-white dark:text-white` still has an unpaired background. Components handle their own dark styling; this check is for the hand-written markup around them. Default minor; promote to major when the unpaired surface is a whole page or panel.

### Severity and the report

Judgment paragraph first, then findings grouped by severity, then counts.

- **P0 Blocking**: broken render or unusable surface: invalid HEEx, `~E`, dark mode unreadable, an overlay that traps focus
- **P1 Major**, fix before merge: unknown or off-enum attrs, hand-rolled component clones, missing dark pair on a whole surface
- **P2 Minor**, visible drift with a workaround: literal palettes, one-off values, missing dark pair on a detail
- **P3 Polish**: legacy spellings, style nits

Tie-break: would a user contact support about it? Then it is at least P1.

One line per finding: severity, file and line, drift class in brackets, the defect, the fix.

`P2 lib/my_app_web/live/settings_live.html.heex:42 [one-off value] bg-[#f8f7f4] hand-rolled surface - use bg-white dark:bg-gray-900 or a @theme token`

Every finding names a drift class:

- **missing-token**: a value the token system already provides, written literally
- **one-off value**: an arbitrary value (`bg-[#...]`, `w-[13px]`) no token covers
- **conceptual mismatch**: right value, wrong idea: raw `<table>` for `<.table>`, white-alpha ghost, transform keyframes
- **local defect**: plain bug: off-enum attr, unpaired dark mode, `~E`

No numeric score, only findings and counts. Close with the per-severity count, and when one pattern repeats three or more times add one "systemic" line naming it.

## 12. Do and don't for custom markup

| Do | Don't |
|---|---|
| `dark:bg-gray-400/8` for dark input and chrome surfaces, `/17` hover, `/25` border and active | `dark:bg-white/10`, `dark:bg-gray-800` on translucent chrome |
| `bg-gray-100`, `border-gray-200`, `text-gray-700`: semantic gray rides the dial | `bg-zinc-100`, `border-slate-200`: literal palettes in chrome |
| `border-radius: var(--pc-radius, 0.625rem)`; clamp with `min(..., 1rem)` if multi-line | `rounded-lg` / `rounded-xl` hardcoded on surfaces |
| `text-gray-500 dark:text-gray-400` for muted copy | `text-gray-400` body copy; inventing `dark:text-gray-600` |
| `focus:outline-hidden focus-visible:ring-2 focus-visible:ring-primary-500/50` | `focus:ring`, offset rings, `outline-none` alone |
| Solid states walk the ramp: `bg-primary-600 hover:bg-primary-700 active:bg-primary-800` | `hover:opacity-90` or `hover:brightness-*` on solids |
| Text on solid primary: `color: var(--pc-button-solid-fg, #fff)` | hardcoded `text-white` on primary solids |
| Hover wash `hover:bg-gray-100 dark:hover:bg-gray-400/17`; glyphs brighten on hover | dimming on hover; washes on non-interactive indicators |
| Panels `bg-white dark:bg-gray-900` plus `border-gray-200 dark:border-gray-400/17` | `dark:bg-gray-950` panels, `border-2` hairlines |
| `shadow-xs` resting, `shadow-lg` floating | `shadow-md` everywhere |
| `transition-colors duration-200 ease-out` (fields: `transition-[color,box-shadow]`) | `transition-all` on non-button chrome, long durations |
| Grow tap targets via `::before { @apply absolute -inset-2 }` | growing the element itself (shifts layout) |
| `disabled:opacity-50 disabled:cursor-not-allowed` (plus `active:scale-100` if the base scales) | gray-swapping colours for disabled states |
| Neutral surface plus colour as accent (icon and hairline bar) on callouts | semantic colour as paint over whole surfaces |
