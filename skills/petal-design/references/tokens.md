# tokens.md - styling doctrine for custom markup and theme changes

Load this file before styling any custom (non-component) markup, and for any brand / dark mode / radius request. Every value below is copied from `assets/default.css` in petal_components - do not substitute from memory.

## 1. The token layer

`default.css` opens with a Tailwind v4 `@theme default` block defining seven semantic ramps, eleven OKLCH stops each (50-950):

```
--color-primary-{50..950}     default: Tailwind blue
--color-secondary-{50..950}   default: Tailwind pink
--color-info-{50..950}        default: sky
--color-success-{50..950}     default: green
--color-warning-{50..950}     default: yellow/amber
--color-danger-{50..950}      default: red
--color-gray-{50..950}        default: Tailwind ZINC values under the gray name
```

`@theme default` marks every value as a soft fallback, so a plain `@theme` block in the consumer app wins regardless of import order. There are no flat shadcn-style tokens (`--background`, `--muted`) - ramps are the vocabulary; components hardcode step roles.

Write utilities only against these seven ramp names. `bg-primary-600`, `text-gray-500`, `border-danger-500` ride the theme; `bg-blue-600` and `text-zinc-500` do not.

### The gray dial

`gray` is the semantic neutral, not a literal palette. The library ships zinc under the gray name, which also redefines what the app's own `text-gray-*` utilities render as. Consequences:

- Never write literal palette names (`slate-*`, `zinc-*`, `stone-*`, `neutral-*`) in chrome. Use the `gray` ramp; the dial does the rest.
- An app remaps gray per stop in `@theme inline`: `--color-gray-500: var(--color-slate-500);` (repeat for all 11 stops). petal_pro and petal_marketing dial gray to slate this way.
- To restore stock Tailwind gray instead, import `tailwind-gray.css` from the package assets AFTER `default.css`. That file is a hard `@theme` (not `default`) of literal stock-gray OKLCH values - importing it IS the override, and literals are required there because once `--color-gray-*` holds zinc there is no variable left to reference.

## 2. The radius knob: `--pc-radius`

One public token controls every corner. Always read it with its fallback: `var(--pc-radius, 0.625rem)`. Never hardcode `rounded-lg` / `rounded-xl` on a Petal-adjacent surface - it breaks the one-knob theme.

Four derivations, pick by element shape:

| Case | Formula |
|---|---|
| Base control (button, input, chip) | `border-radius: var(--pc-radius, 0.625rem);` |
| Concentric inner element (chip inside a field) | `border-radius: max(calc(var(--pc-radius, 0.625rem) - 0.25rem), 0.25rem);` |
| Large card / panel (amplified, capped) | `border-radius: min(calc(var(--pc-radius, 0.625rem) * 1.2), 1.25rem);` |
| TALL-ELEMENT CLAMP - anything that can grow past one line (textarea, multi-select, alert, multi-line group) | `border-radius: min(var(--pc-radius, 0.625rem), 1rem);` |

The clamp keeps `full` meaning "pill" for one-line controls and stops it meaning "ellipse" for multi-line ones. One-line inputs deliberately stay unclamped - pill is a real style. Menu items inside a clamped panel go concentric off the clamped value: `max(calc(min(var(--pc-radius, 0.625rem), 1rem) - 0.25rem), 0px)`.

One more public hook: `--pc-button-solid-fg` (fallback `#fff`) - the text color on solid primary fills. Text on a custom solid-primary surface is `color: var(--pc-button-solid-fg, #fff)`, never hardcoded `text-white`, so a light brand primary can flip its button text dark.

### The type knobs: `--pc-font-heading` / `--pc-font-body` / `--pc-font-mono`

Like `--pc-radius`, the package only READS these - never defines them - and every fallback chain ends in `inherit` or the value the surface consumed before the tokens existed, so an app that sets nothing keeps its own stack. The chains (copied from `default.css`):

| Token | Read as | Bound to |
|---|---|---|
| `--pc-font-heading` | `var(--pc-font-heading, var(--pc-font-body, inherit))` | `pc-h1`..`pc-h5`, prose headings |
| `--pc-font-body` | `var(--pc-font-body, inherit)` | typography reading surfaces, `.prose`, chat bubble/markdown |
| `--pc-font-mono` | `var(--pc-font-mono, var(--font-mono, ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace))` | inline code, chat code, tool output, showcase props tables |

Doctrine for custom markup: a Petal-adjacent heading in custom markup reads `font-family: var(--pc-font-heading, var(--pc-font-body, inherit))`; custom mono reads the full mono chain above. Numeric UI chrome (counters, page numbers, day grids, "+N" chips) carries `lining-nums` - fonts whose default digits are old-style figures vary height by design, which reads as mis-centred in a chip; the feature is a no-op elsewhere. Component-OWNED numeric chrome ships it; slot and user content is never imposed on - callers opt their own digits in with the utility. Kbd deliberately tracks BODY (`var(--pc-font-body, var(--font-sans, ...))`) - never bind a key cap to the mono token. Chat markdown headings stay on the body face (dense scale; a display face at `text-sm` reads as a glitch). A whole-app face is NOT these tokens: that is the host's `@theme { --font-sans: ... }`, which preflight applies at `html`. Type-scale (size/leading/measure) tokens do not exist - demand-gated, same call as the field density family.

## 3. Dark mode: the gray-400 ghost material

Dark mode is class-based (`.dark` ancestor, `dark:` variant). Light chrome is opaque; dark translucent chrome is always alpha-of-gray-400 - never alpha-of-white, never opaque 800/700 fills on chrome. gray-400 is the ramp's chroma peak, so the ghost carries the dial's hue (slate ghost looks slate, zinc looks zinc); white-alpha only works when the neutral is colourless.

The alpha ladder (verified against default.css):

| Role | Light | Dark ghost |
|---|---|---|
| Resting surface (outline-button bg, table header; input fill is `bg-transparent` in light) | `bg-gray-50` / `bg-transparent` | `dark:bg-gray-400/8` |
| Hover wash AND panel hairline border | `hover:bg-gray-100` / `border-gray-200` hairline | `dark:hover:bg-gray-400/17` / `dark:border-gray-400/17` |
| Input border, active wash | `border-gray-300` / `active:bg-gray-*` | `dark:border-gray-400/25` / `dark:active:bg-gray-400/25` |

Opaque dark surfaces exist for panels only: page/card/dropdown white flips to `dark:bg-gray-900`; nested secondary chrome to `dark:bg-gray-800`; code wells rarely `dark:bg-gray-950`. The one blessed white-alpha family is the barely-there muted fill: `dark:bg-white/[0.03]` (striped rows), `/[0.04]` (muted card fill), `dark:hover:bg-white/[0.06]` (row hover). Nothing brighter.

Border grammar: structural hairline `border-gray-200` with `dark:border-gray-400/17` on panels (`dark:border-gray-800` for full-width rules like `hr`); input border `border-gray-300 dark:border-gray-400/25`.

Every light-mode color in a class string gets a `dark:` pair in the same string. Gotcha: `dark:` inside a `::-webkit-*` pseudo-element rule silently no-ops - set a CSS variable on the real host element and reference it from the pseudo-element.

## 4. Text emphasis: three tiers plus glyphs

No named tokens - exact pairs, enforced by convention:

| Tier | Classes | Use for |
|---|---|---|
| 1 Headings / strong | `text-gray-900 dark:text-white` (or `dark:text-gray-100`) | headings, card titles, input text |
| Form labels | `text-gray-900 dark:text-gray-200` | field labels (between tiers 1 and 2 in dark - see section 6) |
| 2 Body | `text-gray-700 dark:text-gray-100` (menu items: `dark:text-gray-300`) | body copy, menu items, blockquote |
| 3 Muted / support | `text-gray-500 dark:text-gray-400` | help text, descriptions, card content, lead |
| Glyphs / placeholder | `text-gray-400 dark:text-gray-500` | placeholder, chevrons, indicator icons |

Note the crossover in dark: muted brightens (500 to 400), glyphs dim (400 to 500) - dark compresses toward the ramp middle. Never invent `dark:text-gray-600` for copy; never use `text-gray-400` for body text. Interactive text brightens on hover, never dims: `text-gray-400 hover:text-gray-700 dark:hover:text-gray-200`.

## 5. Focus ring

House recipe, on the focusable element itself:

```
focus:outline-hidden focus-visible:ring-2 focus-visible:ring-primary-500/50
```

Fields add `focus-visible:border-primary-500` and animate with `transition-[color,box-shadow] duration-200 ease-out`. Use `focus-visible:`, not `focus:`, for the ring - keyboard users get it, mouse clicks do not. Variants when the real control is elsewhere:

- Wrapper containing a real input: `focus-within:border-primary-500 focus-within:ring-2 focus-within:ring-primary-500/50`
- Fake control next to a hidden peer input: `peer-focus-visible:ring-2 peer-focus-visible:ring-primary-500/50`
- Error state swaps hue, keeps shape: `border-danger-500 ring-2 ring-danger-500/20 focus-visible:border-danger-500 focus-visible:ring-danger-500/40 dark:border-danger-500/70`

No ring offsets and no full-opacity rings in new markup (the lone library exception is the button group's offset ring - do not copy it). Never `outline-none` without a visible replacement.

## 6. Spacing, density, motion

- Card rhythm: `px-6 pt-6` header, `p-6` content, `px-6 pb-6` footer, `gap-2` in footers, `gap-4` between header title block and actions.
- Form rhythm: field wrapper `mb-6`, label `block mb-2 text-sm font-medium text-gray-900 dark:text-gray-200`, error `mt-1.5 text-sm text-danger-600 dark:text-danger-400`, help text `mt-2 text-sm text-gray-500 dark:text-gray-400`.
- Density is designed, not tokenised: no global density token. Use per-component `size` attrs; `md` is the form default; do not mix `sm`/`md` mid-form.
- Elevation: `shadow-xs` resting (cards, buttons, inputs); floating panels `shadow-lg`/`shadow-xl` (dropdown, command, popover). Opt-in `*-shadow` button variants exist; do not introduce `shadow-md` middles in new markup.
- Transitions: `transition-colors` on chrome - `duration-200 ease-out` default, `duration-150` on dense hover rows (menu items, table rows); fields use `transition-[color,box-shadow]`. Reserve `transition-all` for buttons and genuinely multi-property animations.
- Tap targets grow with an invisible pseudo, never by growing the element: `::before { @apply absolute -inset-2 }` (add `relative` to the host).
- Keyframes must animate the exact property Tailwind utilities emit: `translate`, not `transform`.

## 7. Theme mode: executing a rebrand

All theming happens in ONE file in the consumer app - the app's main CSS (the file importing petal_components, typically `assets/css/app.css` or a `colors.css` it imports). Never edit `deps/petal_components/*`. Because the library block is `@theme default`, a plain app-side `@theme` wins wherever it sits.

Worked example - purple brand, slate neutral, sharper corners:

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

Rules: remap ALL 11 stops of a ramp - a partial remap leaves mismatched steps in hover/active ladders. `@theme inline` for `var()` references to Tailwind ramps; plain `@theme` works for literals. If the brand primary is light, also set `--pc-button-solid-fg` to a dark value so solid-button text stays readable. Dark mode needs no separate theming pass - the ghost material and text tiers derive from the same ramps.

## 8. Do / don't for custom markup

| DO | DON'T |
|---|---|
| `dark:bg-gray-400/8` for dark input/chrome surface, `/17` hover, `/25` border+active | `dark:bg-white/10`, `dark:bg-gray-800` on translucent chrome |
| `bg-gray-100`, `border-gray-200`, `text-gray-700` - semantic gray rides the dial | `bg-zinc-100`, `border-slate-200` - literal palettes in chrome |
| `border-radius: var(--pc-radius, 0.625rem)`; clamp with `min(..., 1rem)` if multi-line | `rounded-lg` / `rounded-xl` hardcoded on surfaces |
| `text-gray-500 dark:text-gray-400` for muted copy | `text-gray-400` body copy; inventing `dark:text-gray-600` |
| `focus:outline-hidden focus-visible:ring-2 focus-visible:ring-primary-500/50` | `focus:ring`, offset rings, `outline-none` alone |
| Solid states walk the ramp: `bg-primary-600 hover:bg-primary-700 active:bg-primary-800` | `hover:opacity-90` or `hover:brightness-*` on solids |
| Text on solid primary: `color: var(--pc-button-solid-fg, #fff)` | hardcoded `text-white` on primary solids |
| Hover wash `hover:bg-gray-100 dark:hover:bg-gray-400/17`; glyphs brighten on hover | dimming on hover; washes on non-interactive indicators |
| Panels `bg-white dark:bg-gray-900` + `border-gray-200 dark:border-gray-400/17` | `dark:bg-gray-950` panels, `border-2` hairlines |
| `shadow-xs` resting, `shadow-lg` floating | `shadow-md` everywhere |
| `transition-colors duration-200 ease-out` (fields: `transition-[color,box-shadow]`) | `transition-all` on non-button chrome, long durations |
| Grow tap targets via `::before { @apply absolute -inset-2 }` | growing the element itself (shifts layout) |
| `disabled:opacity-50 disabled:cursor-not-allowed` (+ `active:scale-100` if base scales) | gray-swapping colors for disabled states |
| Neutral surface + color as accent (icon + hairline bar) on callouts | semantic color as paint over whole surfaces |
