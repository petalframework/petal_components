<p align="center">
  <img src="https://res.cloudinary.com/wickedsites/image/upload/v1635752721/petal/logo_rh2ras.png" height="96">
</p>

<h1 align="center">Petal Components</h1>

<p align="center">
  <strong>Shadcn-style Phoenix components that AI assistants can actually use.</strong>
</p>

<p align="center">
  <a href="https://hex.pm/packages/petal_components"><img alt="Hex Version" src="https://img.shields.io/hexpm/v/petal_components.svg"></a>
  <a href="https://hexdocs.pm/petal_components"><img alt="Hex Docs" src="https://img.shields.io/hexpm/dt/petal_components.svg?style=flat"></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="MIT" src="https://img.shields.io/badge/license-MIT-green"></a>
</p>

<p align="center">
  <a href="https://petal.build/components">Live docs</a> ·
  <a href="https://mcp.petal.build">MCP server</a> ·
  <a href="./rules.md">Rules for AI tools</a> ·
  <a href="https://petal.build/petal-components/vs-shadcn">vs shadcn</a>
</p>

---

## The 30-second pitch

Petal Components gives Phoenix LiveView apps a shadcn-style set of HEEx components: buttons, forms, modals, tables, cards, and more. They are built with Tailwind v4 and work in live or dead views.

The companion piece is a hosted MCP server at `mcp.petal.build` that exposes every component's real schema to AI coding tools. Install it once and Claude Code, Cursor, Codex, and Windsurf reach for the existing components instead of inventing raw Tailwind markup from training data.

If you have used shadcn in React, you already know the shape. Same idea, composable primitives, you own the patterns, AI tools read the schema and call it correctly. We just write HEEx, not JSX.

## Install

### The two-step way (recommended)

```sh
# 1. Install the MCP server once
claude mcp add petal --transport http https://mcp.petal.build/mcp
```

Then in any Phoenix project:

```
2. Tell your AI: "install petal_components"
```

The agent calls `get_install_instructions` on the MCP, applies the changes to your `mix.exs`, runs `mix deps.get`, patches `assets/css/app.css`, and adds `use PetalComponents` to your web module. Works in umbrella apps and standard Phoenix projects. The AI handles project shape variance the install would otherwise have to special-case.

Cursor, Windsurf, Continue, Codex, and Cline have their own MCP install commands - see https://petal.build/petal-components for snippets per tool.

### The manual way

If you'd rather install yourself, in `mix.exs`:

```elixir
def deps do
  [
    {:petal_components, "~> 3.2"}
  ]
end
```

In `assets/css/app.css`:

```css
@import "tailwindcss";
@source "../deps/petal_components/**/*.*ex";
@import "../deps/petal_components/assets/default.css";
```

In your `MyAppWeb` module:

```elixir
def html do
  quote do
    use PetalComponents
    # ... your other imports
  end
end
```

Run `mix deps.get`, then `mix compile` to verify.

## For AI coding tools

If you are a Cursor, Claude Code, Codex, Continue, Windsurf, or Cline user (or you maintain one of those tools), drop [`rules.md`](./rules.md) into your rules system. It is the canonical instruction set:

- Always reach for an existing petal_components tag before hand-rolling HEEx
- The component naming map (HEEx tag form, module path, CSS class prefix)
- How to discover components via the MCP
- Common patterns (form-in-card, modal-with-form, table-with-actions)
- When in doubt: call `list_components`, then `get_component`

You can also fetch it at https://petal.build/petal-components/rules.md.

## Component catalogue

30+ components covering the patterns a real Phoenix app needs. The MCP server is always the canonical list - call `list_components` for the live inventory. Highlights:

**Layout & content**: `<.container>`, `<.card>`, `<.h1>`, `<.p>`, `<.accordion>`, `<.tabs>`, `<.stepper>`, `<.skeleton>`

**Forms**: `<.field>`, `<.text_input>`, `<.select>`, `<.checkbox>`, `<.radio_group>`, `<.switch>`, `<.textarea>`, `<.date_input>`, `<.file_input>` (full list in `lib/petal_components/form.ex`)

**Actions**: `<.button>`, `<.button_group>`, `<.dropdown>`, `<.menu>`, `<.user_dropdown_menu>`

**Feedback**: `<.alert>`, `<.modal>`, `<.slide_over>`, `<.progress>`, `<.spinner>`, `<.rating>`

**Data display**: `<.table>`, `<.pagination>`, `<.breadcrumbs>`, `<.badge>`, `<.avatar>`, `<.marquee>`, `<.icon>`, `<.link>`

A visual grid is at https://petal.build/components. A live playground is at https://petal-components-demo.fly.dev.

## Examples

### Form in a card

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

### Modal with a form

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
<.table rows={@users}>
  <:col :let={user} label="Name">{user.name}</:col>
  <:col :let={user} label="Email">{user.email}</:col>
  <:col :let={user} label="">
    <.button size="xs" variant="outline" phx-click="edit" phx-value-id={user.id}>
      Edit
    </.button>
  </:col>
</.table>
```

### Loading button

```heex
<.button loading={@saving} phx-click="save">Save</.button>
```

## Compared to shadcn

If you like the shadcn workflow in React, this is the Phoenix version of that idea:

- **Same philosophy**: composable primitives, you own the patterns, no monolithic theme system to fight.
- **Same AI-tool integration**: an MCP server so the agent reads the real schema instead of hallucinating attrs.
- **Different runtime**: HEEx, not JSX. Tailwind v4, not Tailwind 3 + CSS variables. Works in LiveView and dead views.
- **Different distribution**: a Hex package, not a CLI that copies files into your repo. Update with `mix deps.update`.

Full comparison with code samples side by side: https://petal.build/petal-components/vs-shadcn.

## petal_pro

[petal_pro](https://petal.build/petal-pro) is the production SaaS boilerplate built on petal_components - auth, multi-tenancy, Stripe billing, background jobs, the full set. It is the best reference for real-world composition of these components.

## Local development

Standalone dev server, no umbrella needed:

```sh
git clone https://github.com/petalframework/petal_components.git
cd petal_components
mix deps.get
mix tailwind.install
iex -S mix run dev.exs
```

Playground at http://localhost:4000 with every component rendered. Live reload on edits to `lib/`.

Tests:

```sh
mix test
```

## Contributing

Suggest a component on the [public roadmap](https://petal.build/components/roadmap). PRs welcome - clone the repo, run the dev server above, and submit.

There is also a [Phoenix umbrella app](https://github.com/petalframework/petal_development) with `petal_components` as a submodule alongside a boilerplate Phoenix app for integrated testing.

## Companion projects

- [petal-components-mcp](https://github.com/petalframework/petal-components-mcp) - the MCP server. Source for the schema introspector and the TypeScript MCP service.
- [petal_boilerplate](https://github.com/petalframework/petal_boilerplate) - a fresh Phoenix install with petal_components wired up.
- [Figma UI kit](https://www.figma.com/community/file/1374192831096114078/official-petal-ui-kit) - official Figma kit for designing against petal_components.
- [VSCode snippets](https://marketplace.visualstudio.com/items?itemName=petalframework.vscode-petal-components-snippets) - 65+ snippets for the components.

## License

MIT.
