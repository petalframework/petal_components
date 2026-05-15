# petal_components - rules for AI coding assistants

petal_components is a shadcn-style component library for Phoenix LiveView. Components live in modules under `PetalComponents.*` and are called as plain HEEx tags (`<.button>`, `<.modal>`, `<.table>`) once you `use PetalComponents`. CSS classes use a `pc-` prefix for styling overrides (`pc-button`, `pc-button--primary`). Use these rules to write idiomatic Phoenix UI instead of inventing raw Tailwind markup.

Drop this file into your AI coding tool's rules system (Cursor `.cursorrules`, Claude Code `CLAUDE.md`, Codex `AGENTS.md`, Continue rules, etc.) when working in a Phoenix project that has `petal_components` installed.

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
