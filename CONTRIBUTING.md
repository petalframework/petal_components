# Contributing to Petal Components

Everything lives in this one repo: the component library, its styles, the JS hooks, the tests, and the playground you develop against. There is no separate playground repo and no umbrella app to set up.

## Repo anatomy

| Path | What it is |
|---|---|
| `lib/petal_components/*.ex` | The components. One module per component, `use Phoenix.Component`, HEEx only. |
| `lib/petal_components.ex` | The `use PetalComponents` entry point. Every exported function name is claimed here, so check it before naming anything new. |
| `assets/default.css` | All component styling as semantic `pc-*` classes, compiled by the consumer's Tailwind v4 build. New components add a section here. |
| `assets/js/` | Optional Phoenix hooks (`petal_components.js` is the index). The published library has **zero npm dependencies**; `package.json` exists only for dev tooling. |
| `dev.exs` | **The playground.** A single-file [phoenix_playground](https://github.com/phoenix-playground/phoenix_playground) app that renders every component with interactive controls. This same script serves [playground.petal.build](https://playground.petal.build). |
| `test/petal/` | ExUnit component tests (`ComponentCase`, LazyHTML DOM assertions). |
| `test/js/` | Vitest tests for the JS hooks. |

## Setup

Versions are pinned in `.tool-versions` (Erlang 26.2.1, Elixir 1.17.2; asdf/mise pick these up automatically).

```sh
git clone https://github.com/petalframework/petal_components.git
cd petal_components
mix deps.get
mix tailwind.install
npm install
```

## Run the playground

```sh
iex -S mix run dev.exs
```

Open http://localhost:4000 (set `PORT` to change it). Edits to `lib/` live-reload. After editing `assets/default.css` or changing deps, restart the server; the CSS is compiled at boot and dependency BEAMs are not hot-swapped.

The playground is the development surface: every component has a page with dials (variant, size, state toggles) and one or more realistic example scenarios. When you build a component, its playground page is part of the deliverable, not an afterthought.

## Run the tests

```sh
mix test    # Elixir component tests
npm test    # JS hook tests (vitest)
```

Both suites must be green before opening a PR.

## Building a component

Pick an issue from the [milestones](https://github.com/petalframework/petal_components/milestones). Each component issue is a full build brief: API sketch, variants, playground page spec, accessibility requirements, and a test checklist. The briefs are written to be workable by a contributor pairing with an AI coding assistant; paste the issue in and it has everything it needs.

A component PR contains five things:

1. **The module**: `lib/petal_components/<name>.ex`. Every attr gets a `doc:` string; the moduledoc carries usage examples. Match the attr naming and slot patterns of neighbouring components.
2. **The styles**: a `pc-<name>` section in `assets/default.css`. Consume the `--pc-radius` token, ride the gray ramp for neutrals, style dark mode via `dark:`, use `focus-visible` (never persistent `:focus` fills), and respect `prefers-reduced-motion`.
3. **The tests**: `test/petal/<name>_test.exs`. Every attr, variant, and slot gets a rendering assertion; ARIA attributes are asserted explicitly. If you added a hook, unit-test its logic in `test/js/`.
4. **The showcase module**: `lib/petal_components/showcase/<name>.ex` (`use PetalComponents.Showcase, component: ..., title: ...`), holding the canonical examples as `example/3` blocks, plus its entry in `lib/petal_components/showcase/registry.ex`. The macro captures each example's exact source for the playground's View Code panel and compiles it as the live preview, and petal.build renders the same registry, so the code shown can never drift from what runs. A test asserts every showcase module is registered, so a missing registry entry fails the suite.
5. **The playground page**: a nav entry and page in `dev.exs` with dials for the attrs that matter and 1 to 3 realistic scenarios (a real product moment, not lorem ipsum), rendering the showcase examples plus any interactive dial sections. Check it in light and dark, keyboard-only, and with reduced motion.

House rules that will come up in review:

- **No new dependencies.** No npm packages in the published library, no required hex deps beyond Phoenix/LiveView. If a component genuinely needs one (as an optional dep), raise it on the issue first.
- **CSS-first.** Reach for CSS and `Phoenix.LiveView.JS` before writing a hook. A hook is justified only when those genuinely cannot do the job (existing precedents: `PetalInputOTP`, `PetalPopover`, the command palette filter).
- **Accessibility is part of done.** Follow the WAI-ARIA pattern named in the issue, including the keyboard map.
- **Naming**: components are plain HEEx tags (`<.alert_dialog>`); the `pc-` prefix belongs to CSS classes only. Avoid names that collide with `Phoenix.Component` or common core_components (the library must never export `flash/1`).

## The process

1. Build on a feature branch, verify in the playground, get both suites green.
2. Open a PR against `main` with light and dark screenshots of the playground page. The automated review runs on every PR and must pass.
3. [@nhobes](https://github.com/nhobes) is the gatekeeper: final design and quality checks happen on the PR, and he merges when happy. Please don't self-merge.
4. Releases (Hex publish, changelog, docs, MCP schema sync) are handled by maintainers after merge.

Suggestions outside the current milestones are welcome too: open an issue with the shape of the API you'd want, or propose it on the [public roadmap](https://petal.build/components/roadmap).
