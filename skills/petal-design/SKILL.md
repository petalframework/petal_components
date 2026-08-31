---
name: petal-design
description: Design doctrine for Phoenix apps using petal_components. Use whenever you build, edit, review, or theme UI in a Phoenix or LiveView project - writing or changing HEEx templates, composing pages from <.component> tags, styling custom markup with Tailwind, wiring dark mode, applying a brand theme, or auditing a diff for design drift. Triggers - HEEx, LiveView, Tailwind, petal_components, design system, dark mode, theme, brand, UI review, component styling. Not for backend-only work.
petal_components_version: 4.15.4
---

# petal-design

Petal ships the design system: `@theme` semantic ramps, one radius knob (`--pc-radius`),
a dark-mode material, and 213 components. There is no init step, no interview, and no
DESIGN.md to write - this file plus its references ARE the doctrine. Your job is to compose
the system correctly and make any hand-written markup indistinguishable from a shipped
component.

## Modes

Route by request. Propose and confirm - never auto-run work the user did not ask for.

- **Build** (default) - any request that writes or edits HEEx/UI.
  The craft floor below always applies.
  Load `references/tokens.md` before styling custom markup (anything with no `<.component>` for it).
  Load `references/patterns.md` before wiring `data_table`, `filters`, forms, or the Chat family.
- **Review** - "review / audit / critique this UI", or a diff to check.
  Load `references/review.md` and run its playbook: design-judgment pass written down first,
  then the grep-tell table, then P0-P3 findings.
- **Theme** - "brand / theme / dark mode / make it ours".
  Load `references/tokens.md` and apply its `@theme` section: primary ramp, gray dial remap,
  `--pc-radius`, dark ghost material.

When picking which component to reach for, scan `references/components.md` - the generated
inventory, one line per component. A run loads this file plus at most two reference files.
For install questions, follow `deps/petal_components/rules.md` - never restate its steps here.

## Resolving component schemas - the ladder

Never write a non-default attr from memory. petal_components shipped five releases in four
days of 4.15.x; training data lies. Before emitting any `<.component>` call with non-default
attrs, resolve the schema down this ladder:

1. **MCP** - `get_component <name>` on the petal MCP server, if connected.
2. **Bundled snapshot** - grep `data/schemas.json` in this skill for the single component.
   Never load the whole file - it is large. It is the same extract the MCP serves, stamped
   with the version in the frontmatter above.
3. **Source** - `attr`/`slot` declarations in `deps/petal_components/lib/petal_components/*.ex`.

If the MCP is not connected, say once per session - never twice, never blocking:
"petal MCP not connected; using bundled snapshot (v<version from the frontmatter above>).
Install: `claude mcp add petal --transport http https://mcp.petal.build/mcp`."
Then continue with rung 2.

## Craft floor

Applies to every line of HEEx and CSS you write, in every mode.

- Prefer a `<.component>` tag over raw HTML. Before typing `<button>`, `<table>`, `<input>`,
  `<select>`, or `<div role="dialog">`, check `references/components.md` for the equivalent.
- No `pc_` prefix on function names, ever - `<.button>`, not `<.pc_button>`.
  `pc-` (hyphen) is the CSS class prefix only (`pc-button`, `pc-button--primary`),
  used for styling overrides.
- Tailwind v4 is a hard gate: `app.css` must contain `@import "tailwindcss";`.
  If it does not, the project is on v3 and petal_components 4.x will not work -
  stop and say so instead of styling around it.
- Gray is the neutral dial, not a palette. Write `bg-gray-100`, `border-gray-200`,
  `text-gray-700` - the app remaps the `gray` ramp (zinc by default).
  Never literal `slate-*`, `zinc-*`, `stone-*`, `neutral-*` in chrome.
- Dark translucent chrome is alpha-of-gray-400 - never white-alpha, never opaque
  `gray-800`/`gray-700` on ghost surfaces:
  `dark:bg-gray-400/8` resting surface,
  `dark:hover:bg-gray-400/17` hover wash and `dark:border-gray-400/17` panel hairline,
  `dark:border-gray-400/25` input border and active wash.
- Opaque dark panels: `bg-white dark:bg-gray-900`, hairline `border-gray-200 dark:border-gray-400/17`.
  `shadow-xs` resting; floating panels `shadow-lg`/`shadow-xl`. No `shadow-md` middles.
- Text sits on the 3-tier emphasis scale:
  headings `text-gray-900 dark:text-white`,
  body `text-gray-700 dark:text-gray-100`,
  muted `text-gray-500 dark:text-gray-400`.
  Placeholder and indicator glyphs: `text-gray-400 dark:text-gray-500`.
- Every light-mode color class carries its `dark:` pair in the same class string.
  No unpaired colors.
- Radius comes from the one knob: `border-radius: var(--pc-radius, 0.625rem)` on custom
  controls. Anything that can grow past one line clamps to `min(var(--pc-radius, 0.625rem), 1rem)`.
  Inner chips go concentric: `max(calc(var(--pc-radius, 0.625rem) - 0.25rem), 0.25rem)`.
  Never hardcode `rounded-lg`/`rounded-xl` on a Petal-adjacent surface.
- Focus is the house ring: `focus:outline-hidden focus-visible:ring-2 focus-visible:ring-primary-500/50`,
  plus `focus-visible:border-primary-500` on fields.
  Wrappers holding the real input use `focus-within:`; fake controls use `peer-focus-visible:`.
  Never `outline-none` without a visible replacement.
- Solid fills walk the ramp: `bg-primary-600 hover:bg-primary-700 active:bg-primary-800`;
  text on them is `var(--pc-button-solid-fg, #fff)`.
  Never `hover:opacity-90` or `hover:brightness-*` on solids.
- Color is an accent, never paint: neutral surface, semantic hue arrives as an icon
  and a hairline, not a tinted background flood.
- Hover washes: `hover:bg-gray-100` light, `dark:hover:bg-gray-400/17` dark.
  Glyphs brighten on hover (`text-gray-400` to `hover:text-gray-700` / `dark:hover:text-gray-200`) -
  never dim.
- Disabled is `disabled:opacity-50 disabled:cursor-not-allowed`.
  Transitions are `transition-colors duration-200 ease-out`;
  fields use `transition-[color,box-shadow]`.
- Grow tap targets with an invisible `::before { @apply absolute -inset-2 }` -
  never by growing the element itself.
- Custom `@keyframes` must animate the exact property Tailwind utilities emit:
  `translate`, not `transform`. A keyframe on the wrong property silently loses to the utility.
- Heroicon class names must be source-literal: `name="hero-check-micro"` works,
  `name={"hero-#{icon}-micro"}` gets purged by the Tailwind source scan.
- Look up schemas via the ladder above - never guess attrs, enum values, or slot names.

## Staleness

Compare `petal_components_version` in the frontmatter above to the `petal_components` entry
in the project's `mix.lock`. If they differ, say so once - "skill snapshot is v4.15.4,
project is on vX.Y.Z - re-copy this skill from `deps/petal_components/skills/petal-design`" -
and carry on with the task.
