# Review mode - the playbook

You are reviewing Phoenix/LiveView UI built with petal_components. Run the
steps below in order. Produce findings, not scores. Never fix anything unless
asked.

Staleness check first: compare the petal_components version in SKILL.md
frontmatter to the `petal_components` entry in the project's mix.lock. If they
differ, print one line - "petal-design snapshot vX.Y.Z is behind mix.lock
vA.B.C - re-copy from deps/petal_components/skills/petal-design" - then
continue. Never block on staleness.

The order:
1. Read the UI and its intent, write the design judgment - before any grep.
2. Run the grep table over the changed `.heex`/`.ex` files plus touched CSS.
3. Schema spot-check every `<.component>` call touched; dark-pair coverage.
4. Report P0-P3 findings with file:line and a drift class. Fixes only on request.

## 1. Design judgment - written before any grep

Read the diff, the surrounding template, and the page it renders. Write 3-5
sentences covering: hierarchy (one focal point, weight and size steps that read
in order), spacing rhythm (tight groups, generous separation, more space above
a heading than below it), token fidelity (does the surface speak the gray dial
plus primary accent, or literal palettes and one-off values), and dark-mode
parity (would this screen hold up with dark active).

Write it down before running a single grep: detector output anchors judgment,
and an anchored reviewer stops seeing what the greps cannot catch.

## 2. The grep table

Collect targets with `git diff --name-only` (or the files named in the
request); keep `.heex` and `.ex`, plus any touched CSS under `assets/`. Run
every row with `grep -nE` so findings carry line numbers.

**1. Literal neutral palettes in chrome**
- pattern: `grep -nE '(slate|zinc|neutral|stone)-[0-9]+'`
- catches: `text-slate-500`, `bg-zinc-900`, `dark:border-stone-700` in UI chrome
- why: gray is THE neutral dial; other neutral families fork the palette and break the `@theme` gray remap contract
- fix: use `gray-*`; if the brand wants a warmer/cooler neutral, remap the gray ramp in `@theme` (tokens.md), never per-element
- false positive: prose or docs content naming palettes; comments

**2. Bang overrides targeting pc-***
- pattern: `grep -n '!important' assets/*.css` and `grep -nE 'class="[^"]*[]a-z0-9]![ "]'` for trailing-bang utilities
- catches: `.pc-*` override rules forced with `!important`; `w-4!`-style utilities out-muscling component styles
- why: pc-* classes are the component's styling API; bangs fight the contract (bang audit, PR #526) and break the next release
- fix: override with a plain rule on the documented `pc-*` class, or use the component's own attrs
- false positive: the library's own doubled-selector + `!important` icon-sizing contract inside `default.css` is intentional - only flag app CSS; in `.ex`, `!` is also Elixir negation and bang functions

**3. Hand-rolled overlays**
- pattern: `grep -nE 'fixed[^"]*inset-0|inset-0[^"]*fixed'`
- catches: DIY modal/drawer scrims, ad-hoc `z-50` panels
- why: `<.modal>`, `<.slide_over>`, `<.dropdown>` ship focus handling, escape, scroll-lock, and the dark ghost material; a bare scrim ships none
- fix: swap to the matching component; resolve its schema first (Step 3)
- false positive: toast/portal containers and full-bleed hero media that are not dialogs

**4. pc_ function prefix**
- pattern: `grep -nE '<\.pc_[a-z_]+'`
- catches: `<.pc_button>`, `<.pc_modal>` - functions that do not exist
- why: there is NO `pc_` function prefix; `pc-` (hyphen) is the CSS class prefix only - the classic AI conflation
- fix: `<.button>`, `<.modal>`, etc.
- false positive: none known - every hit is real

**5. Deprecated dropdown spellings**
- pattern: `grep -nE '(placement|direction)='`
- catches: legacy `<.dropdown>` attrs
- why: `side` + `align` are the vocabulary; `placement`/`direction` are the older spelling kept working
- fix: `placement="left"` -> `align="end"`; `placement="right"` -> `align="start"`; `direction="up"` -> `side="top"`; `direction="down"` -> `side="bottom"`; `direction="auto"` -> drop the attr
- false positive: `direction=` on non-dropdown markup - confirm the enclosing call is `<.dropdown>`; P3, it still works

**6. Keyframes animating transform**
- pattern: `grep -nE 'transform:[^;]*(translate|scale|rotate)' assets/*.css`
- catches: `@keyframes` bodies writing `transform:` while Tailwind v4 utilities emit standalone `translate`/`scale`/`rotate` properties
- why: the keyframe silently fights the utility and the animation dies (PR #650)
- fix: animate the exact property the utility emits - `translate:`, `scale:`, `rotate:`
- false positive: `transform` in non-keyframe rules with no competing utility - confirm the hit is inside `@keyframes`

**7. Raw HTML where a component exists**
- pattern: `grep -nE '<(button|table|input|select|textarea)\b'`
- catches: raw elements in app templates
- why: `<.button>`, `<.table>`, `<.field>` carry focus rings, dark pairs, a11y, and the pc-* API for free
- fix: swap to the component; resolve its schema first (Step 3)
- false positive: hidden/CSRF inputs, third-party embeds, and petal_components' own source where the raw tag IS the implementation

**8. Missing dark: pair (candidate pass)**
- pattern: `grep -nE '(bg|text|border)-(white|black|gray-[0-9]+)' | grep -v 'dark:'`
- catches: class strings styling light mode with no dark sibling on the line
- why: pc components are dark-aware; hand-written wrappers around them usually are not
- fix: add the pair per Step 4's tier table
- false positive: heavy - `grep -v` drops lines with ANY `dark:`, even for a different property; BEM class names that embed color tokens (`pc-skeleton--text__block--bg-gray-300`) are names, not utilities; treat hits as candidates and finish with Step 4 by hand

**9. variant on a combobox field**
- pattern: `grep -nE 'type="combobox"[^>]*variant=|variant=[^>]*type="combobox"'`
- catches: `<.field type="combobox" variant="...">`
- why: field's attr is `combo_variant` (`"input"` | `"trigger"`); a bare `variant=` is not the field API
- fix: `combo_variant="trigger"`
- false positive: direct `<.combo_box>` calls take `variant` legitimately; multi-line attrs defeat the regex - when a file greps for `combobox` at all, read the call

**10. White-alpha ghost in dark variants**
- pattern: `grep -nE 'dark:(bg|border)-white/[0-9]+'`
- catches: `dark:bg-white/10`-style surfaces
- why: the dark ghost material is gray-400 alpha - `dark:bg-gray-400/8` surface, `/17` hover + hairline border, `dark:border-gray-400/25` input border; white alpha glows and shifts hue
- fix: swap to the gray-400 alpha ladder
- false positive: deliberate white overlays on imagery or brand panels; the library's own source uses `dark:*-white/10` internally (slide_over grab-handle chrome, showcase demos) - the library-source exclusion below covers it

**11. ~E sigil**
- pattern: `grep -nE '~E"'`
- catches: the banned EEx sigil
- why: HEEx only (`~H`) - `~E` has no HTML-aware engine
- fix: rewrite as `~H`
- false positive: none - hard rule

**12. Tailwind v3 tells**
- pattern: `grep -rnE '@tailwind (base|components|utilities)' assets/`
- catches: v3 directives in project CSS
- why: the whole token contract (`@theme` ramps, gray dial remap, `tailwind-gray.css` restore) is Tailwind v4; v3 directives mean none of it is loaded
- fix: `@import "tailwindcss";` plus `@theme` tokens per tokens.md
- false positive: docs or comments quoting v3 syntax

**13. Unknown attrs on component calls**
- pattern: `grep -ohE '<\.[a-z_0-9]+' | sort -u` to list every component touched, then run Step 3 per component
- catches: attrs that do not exist, enum values that do not exist
- why: 4.15.x shipped 5 releases in 4 days - memory lies, the schema does not
- fix: per Step 3
- false positive: globals on components with a `rest` attr - see Step 3

Standing rules:
- Skip beats false positive. Unsure whether a hit is real - drop it, say nothing.
- A clean grep is a floor, not proof. The judgment in Step 1 outranks an empty table.
- Never block on a finding - report it. Review mode has no gate, no exit code, no veto.
- grep does not strip comments: confirm a hit is not inside `<%!-- --%>`, `#`, or `/* */` before reporting.
- Exclude petal_components' own source (`deps/petal_components/`, `apps/petal_components/lib/`) from rows 2, 3, 7, and 10 - raw tags, pc-* rules, and internal white-alpha chrome there are the implementation.

## 3. Schema spot-check

For each distinct `<.name>` call touched by the diff (row 13's list), verify
every attr written against the real schema. Resolve via the ladder in SKILL.md:
MCP `get_component <name>` if connected, else the bundled snapshot, else
`deps/petal_components/**/*.ex` attr/slot declarations.

The snapshot lives at `data/schemas.json` next to SKILL.md. Shape:
`{"version", "components": [{"module", "name", "slots", "kind", "attrs":
[{"name", "type", "values", "default", "required"}]}], "generated_at"}` - the
component `name` is the HEEx tag without the dot. Pull one component, never
load the whole file:

```sh
python3 -c "import json; c = next(c for c in json.load(open('data/schemas.json'))['components'] if c['name'] == 'button'); [print(a['name'], a['type'], a['values'] or '') for a in c['attrs']]"
```

Flag as P1: an attr absent from the schema, or a value outside a non-null
`values` enum (`color="prmary"`). Before flagging, check the schema for a
`rest` attr - components that declare one legitimately accept `phx-*`,
`data-*`, `aria-*`, `id`, and other globals; no `rest` attr means unknown
attrs are real findings. Compile-time checks only catch literal values in
compiled code - the review catches dynamic assigns and code nobody compiled yet.

## 4. Dark-pair coverage

Finish row 8's candidates by hand. For every class string in the diff that sets
a light-mode color (`bg-`, `text-`, `border-`, `divide-`, `ring-`), require the
dark sibling for the SAME property in the SAME class string:

- text, 3-tier emphasis: `text-gray-900` -> `dark:text-white`; `text-gray-700` -> `dark:text-gray-100`; `text-gray-500` -> `dark:text-gray-400`
- surfaces: `bg-white` -> `dark:bg-gray-900` (panels/cards), or the ghost material `dark:bg-gray-400/8`
- borders: `border-gray-200`/`border-gray-300` -> `dark:border-gray-400/17` hairline, `dark:border-gray-400/25` on inputs

A `dark:` token for a different property does not count - `bg-white
dark:text-white` still has an unpaired background. pc components handle their
own dark styling; this check is for the hand-written markup around them.
Default P2; promote to P1 when the unpaired surface is a whole page or panel.

## 5. The report

Judgment paragraph first, then findings grouped by severity, then counts.

- P0 Blocking - broken render or unusable surface: invalid HEEx, `~E`, dark mode unreadable, overlay traps focus
- P1 Major - fix before merge: unknown/off-enum attrs, hand-rolled component clones, missing dark pair on a whole surface
- P2 Minor - visible drift with a workaround: literal palettes, one-off values, missing dark pair on a detail
- P3 Polish - legacy spellings, style nits

Tie-break: would a user contact support about it - then it is at least P1.

One line per finding - severity, file:line, drift class in brackets, the
defect, the fix:

`P2 lib/my_app_web/live/settings_live.html.heex:42 [one-off value] bg-[#f8f7f4] hand-rolled surface - use bg-white dark:bg-gray-900 or a @theme token`

Drift classes, every finding names one:
- missing-token - a value the token system already provides, written literally
- one-off value - an arbitrary value (`bg-[#...]`, `w-[13px]`) no token covers
- conceptual mismatch - right value, wrong idea: raw `<table>` for `<.table>`, white-alpha ghost, transform keyframes
- local defect - plain bug: off-enum attr, unpaired dark mode, `~E`

No numeric score - findings and counts only. Close with the per-severity count,
and when one pattern repeats 3+ times add one "systemic" line naming it.

Fixes only on request: propose the fix inside each finding, never edit files,
never auto-run anything. If asked to fix, take P0/P1 first, then re-run Step 2
over the files you touched.
