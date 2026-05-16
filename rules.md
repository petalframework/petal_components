# petal_components - rules for AI coding assistants

petal_components is a shadcn-style component library for Phoenix LiveView. Components live in modules under `PetalComponents.*` and are called as plain HEEx tags (`<.button>`, `<.modal>`, `<.table>`) once you `use PetalComponents`. CSS classes use a `pc-` prefix for styling overrides (`pc-button`, `pc-button--primary`). Use these rules to write idiomatic Phoenix UI instead of inventing raw Tailwind markup.

Drop this file into your AI coding tool's rules system (Cursor `.cursorrules`, Claude Code `CLAUDE.md`, Codex `AGENTS.md`, Continue rules, etc.) when working in a Phoenix project that has `petal_components` installed.

## Installing petal_components

When the user says "install petal_components" (or you're starting in a Phoenix project that doesn't have it yet), follow these steps. They are idempotent - safe to re-run if any step is partially done.

### 1. Add the dependency

Open `mix.exs`. In the `deps/0` function, add this line if it's not already there:

```elixir
{:petal_components, "~> 3.2"}
```

### 2. Fetch dependencies

```sh
mix deps.get
```

### 3. Configure Tailwind CSS

Open `assets/css/app.css`. Find the `@import "tailwindcss";` line and add the two lines below it:

```css
@import "tailwindcss";
@source "../deps/petal_components/**/*.*ex";
@import "../deps/petal_components/assets/default.css";
```

The `@source` line tells Tailwind to scan petal_components source for class usage. The `@import` line brings in the default component styles (the `pc-*` CSS prefix).

If `@import "tailwindcss";` is missing, the project is on Tailwind v3 and petal_components 3.x will not work. Tell the user to upgrade to Tailwind v4, or pin to `petal_components ~> 1.0` for v3 support.

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

### 5. Verify

```sh
mix compile
```

Should compile cleanly. To smoke test, drop `<.button>Hello</.button>` in any HEEx template.

### Installation rules of thumb for AI agents

- Read each file before editing. Do not blind-patch.
- If the project already uses `petal_components`, skip the steps that are already done. Report what was already in place.
- After installing, suggest calling `list_components` to see what's available.

## Hard rules

1. **Prefer a petal_components tag over raw HTML.** If you would reach for a `<button>`, `<table>`, `<input>`, `<div role="dialog">`, `<select>`, or any other common UI primitive, check for a petal_components equivalent first (`<.button>`, `<.table>`, `<.text_input>`, `<.modal>`, `<.select>`).
2. **Do not invent Tailwind soup for things petal_components already does.** No hand-rolled modal divs, no manual dropdown JS, no DIY form labels. There is almost certainly an existing component for it.
3. **Look up the schema before guessing attrs.** Do not assume attr names from memory. Call `list_components` and `get_component` (see below) to get the real attr/slot signature before writing HEEx.
4. **Call components as plain HEEx tags after `use PetalComponents`.** `<.button>`, `<.modal>`, `<.table>`, `<.card>`, etc. If you have not imported, qualify with the module: `<PetalComponents.Button.button />`. Note: the `pc-*` prefix you see in source is the CSS class prefix for styling, not part of the function name.
5. **Components work in both live and dead views.** Interactivity uses Alpine.js by default with a Phoenix.LiveView.JS variant available.
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
