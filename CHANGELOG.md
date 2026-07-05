# Changelog
### Unreleased

#### Fixed

- **`email_input`, `number_input`, `password_input`, `search_input`, `telephone_input` and `url_input` forward global attributes again** (`value`, `placeholder`, `phx-*` bindings, etc.). A 3.0.2 refactor left these six without their own `attr :rest, :global` declarations, and since `attr` only applies to the function directly below it, only `text_input` kept forwarding. Fixes [#488](https://github.com/petalframework/petal_components/issues/488).

### 4.2.0 - 2026-06-29

A typography pass. The heading and body scale got a proper going-over, and the type set is now complete enough to lay out a full article from components alone. Everything here is additive or a restyle, with no breaking API changes (see Upgrading for the visual shifts).

#### Added

- **Seven typography components: `lead`, `blockquote`, `inline_code`, `text_large`, `text_muted`, `text_small` and `hr`.** Rounds out the type set so a full page composes without dropping to raw HTML. `lead` is the larger intro paragraph, `blockquote` a bordered quote, `inline_code` for snippets inside a sentence, `text_large` / `text_muted` / `text_small` for emphasis and secondary copy, and `hr` a spaced divider.

#### Changed

- **Refined the type scale.** Headings now carry tight tracking, balanced multi-line wrapping (`text-wrap: balance`) and a `scroll-margin` so anchor links don't tuck under a sticky header. Weights are normalised to `semibold` (only `h1` stays heavier), and the sizes were re-stepped for a cleaner ramp: `h2`/`h3`/`h4` are a touch larger and lighter than before, and `h5` is smaller and now clearly distinct from `h4`. Body copy gained a more comfortable line height and roomier paragraph spacing. And text contrast is now systematic: every element sits on one of three emphasis tiers (strong / default / muted) that hold consistently across light *and* dark, so headings, body, inline code and table data all read at the right level in both modes, with no element drifting brighter or dimmer than its peers.
- **`ul` / `ol` lists look considered out of the box.** Markers sit outside the text with consistent indentation (ordered and unordered line up), and there's built-in vertical spacing between items, so a list reads well without adding spacing utilities yourself.
- **Typography self-composes now.** Headings carry an automatic top margin (`first:mt-0` zeroes the first one), `lead` and `blockquote` have proper surrounding space, and lists match the paragraph rhythm, so a full article has correct vertical spacing from components alone with no manual `mt-*`. Body copy also uses `text-wrap: pretty` (fewer orphans and widows), and `<.table>` cells use tabular figures so columns of numbers line up.

#### Fixed

- A table user-cell sub-label (the secondary line under a name, e.g. an email) was missing its dark-mode colour, so on dark backgrounds it rendered too faint and dropped below the WCAG contrast floor. It now uses a readable muted tone in dark mode.

#### Upgrading

No code changes are required. Everything is additive or a CSS restyle, so nothing in your templates breaks. But after `mix deps.update petal_components`, existing `h1`-`h5`, `<.p>` and lists will *look* different (that's the point of the pass). If you've tuned layouts around the old metrics, here's what moved and how to pin the old look:

- **Headings are re-sized and lighter.** `h2`-`h4` are slightly larger (most noticeably on small screens) and use `font-semibold` instead of `bold` / `extrabold`; `h5` is now `text-base`. To keep a previous look on a specific heading, pass `class` (it's appended last, so it wins), e.g. `<.h2 class="text-2xl font-extrabold">`.
- **Headings now carry a top margin** (`h2` 3rem, `h3` / `h4` 2rem, `h5` 1.5rem) so sections self-space, with `first:mt-0` zeroing it for the first element in a container. For a heading used as a tight label in UI, drop it with `<.h2 no_margin>`. Internally the per-heading margin class is now per level (e.g. `pc-h2--margin`), which only matters if you overrode `pc-heading--margin` directly.
- **Paragraph rhythm is roomier.** Body line height went from `leading-5` to `leading-7`, and the gap after a paragraph from `mb-2` to `mb-6`. If that's too airy in a dense layout, drop the margin per element with `<.p no_margin>`, or set it globally by redefining the class after your import: `.pc-p--margin { @apply mb-4; }`.
- **Lists indent and space their items.** They moved from inside to outside markers, with `ml-6` and spacing between items. Override per list by passing `class`.
- **Headings gained `scroll-margin`.** Anchor links now land below a sticky header cleanly. If you already set your own `scroll-margin-top`, the more specific rule still wins.

### 4.1.2 - 2026-06-17

#### Fixed

- **`navigation_menu` flyout panels now open on small screens.** 4.1.1 positioned panels with `position: fixed` below the `sm` breakpoint, which on real phones placed the panel at the wrong spot (often off-screen), so tapping a trigger looked like it did nothing. It worked in landscape only because that width uses the desktop layout. Panels now use `position: absolute` at every breakpoint, the same positioning that already worked on desktop: anchored under the trigger, width-clamped to the viewport, and scrollable if taller than the screen. Use `align="end"` for triggers near the right edge.

### 4.1.1 - 2026-06-17

#### Added

- **`navigation_menu` flyout panels stay on screen.** Each `:item` now takes an `align` attr (`"start"`, the default, or `"end"`). Panels anchor to the trigger's start edge and open rightward by default, so a left-most trigger no longer opens back under a sidebar; set `align="end"` on a trigger near the right edge so its panel opens leftward instead. Panel widths are clamped to the viewport, and on small screens every panel becomes a full-width sheet pinned to the viewport gutters.

#### Fixed

- **`navigation_menu` flyout panels no longer overflow the viewport.** Panels were centred on their trigger at `width: 100vw` before being clamped, so a trigger near a screen edge (or any trigger on mobile) pushed the panel off-screen where it was clipped. They now edge-anchor and clamp to the viewport (see the `align` attr above).
- **`<.a>` now forwards `target`, `rel` and the other anchor attributes.** The `:rest` global on `<.a>` only allowed `method` and `download`, so writing `<.a target="_blank">` raised a compile warning and the attribute was silently dropped at runtime (the link opened in the same tab instead of a new one). The include list now matches `<.button>`, `<.dropdown_menu_item>` and `<.tabs>`: `method download hreflang ping referrerpolicy rel target type`. Because `<.dropdown_menu_item>` renders through `<.a>`, this also restores attribute forwarding for dropdown menu items.
- **`navigation_menu_link` and `navigation_menu_footer_link` use the same canonical anchor include list.** They already forwarded `target`/`rel`, but now also pass `hreflang`, `ping`, `referrerpolicy` and `type` for consistency with the other link-rendering components.

### 4.1.0 - 2026-06-12

Seven new components. One closes the biggest functional gap (a real navigation menu), the other six open a lane no Phoenix component library covers: landing-page "special effects" in the MagicUI style, built for server rendering — most are pure CSS, the rest ship as hooks in the JS bundle.

#### Added

- **`navigation_menu` flyout / mega menu.** `<.navigation_menu>` renders a horizontal nav where each `:item` is either a plain link or a disclosure trigger opening a rich flyout panel — compose panels from `<.navigation_menu_link>` rows (icon + title + description), an optional `<.navigation_menu_footer>` CTA strip, or any markup. Follows the W3C disclosure navigation pattern (`aria-expanded`/`aria-controls`, Escape and click-away close, `aria-current` on the active item), 100% LiveView.JS — no Alpine, no hooks. Set `full_width` on an item for a mega menu spanning your header. Panel widths: `sm`–`xl`.
- **`border_beam` animated border.** A beam of light travels along the container border. Pure CSS (`offset-path`). Attrs: `color_from`, `color_to`, `duration`, `size`, `border_radius`.
- **`meteors` background effect.** A meteor shower for hero sections and dark cards. Pure CSS — positions, delays and durations are generated server-side and are deterministic per `seed`, so LiveView re-renders never make meteors jump. Attrs: `count`, `seed`.
- **`gradient_text`, `shimmer_text`, `word_rotate`, `typing_effect` text animations.** Gradient sweep and shimmer are pure CSS; word rotate and the typewriter ship as `PetalWordRotate` / `PetalTypingEffect` hooks. All four render their full text server-side, so they degrade gracefully without JavaScript and stay visible to search engines.
- **`number_ticker` animated counter.** Counts up when scrolled into view (IntersectionObserver) and re-animates the delta whenever the LiveView assign changes — built for stats sections and live dashboards. Locale-aware formatting via `Intl.NumberFormat`. Attrs: `value`, `start_value`, `duration`, `decimal_places`, `prefix`, `suffix`, `locale`. Requires the `PetalNumberTicker` hook.
- **`confetti` celebration bursts.** Zero-dependency canvas confetti. Fire from the server with `push_event(socket, "pc-confetti", %{})` (optionally targeting an `id`) or from the client with `JS.dispatch("pc:confetti", to: "#id")` — no round trip. Options: `particle_count`, `spread`, `angle`, `velocity`, `colors`, `origin`. Requires the `PetalConfetti` hook.
- **`spotlight_card` hover glow.** A radial glow follows the cursor across the card. Attrs: `spotlight_color`, `spotlight_size`. Requires the (tiny) `PetalSpotlight` hook.
- All animated components respect `prefers-reduced-motion`: decorative animation is disabled or hidden, informative content stays static and readable.
- Playground: new **Effects** tab and a navigation menu showcase in `dev.exs`, which now loads the bundled hooks as an ES module (so hook-based components work out of the box when contributing).

#### Fixed

- The `dev.exs` playground no longer crashes with `CompileError` ("module is currently being defined") when two requests arrive concurrently (e.g. `curl -I` alongside a browser tab) — code reloads are now serialized behind a global lock.

### 4.0.12 - 2026-06-11

#### Added

- **`range-dual` dual-handle range slider.** A new `type="range-dual"` for both `<.input>` and `<.field>` renders two stacked `<input type="range">` thumbs sharing a coloured track. Requires the `PetalDualRangeSlider` hook (included in the JS bundle). Attrs: `min_field`, `max_field`, `range_min`, `range_max`, `range_min_label`, `range_max_label`, `value_prefix`, `value_suffix`. Works without Alpine.js — pure LiveView hook.

### 4.0.11 - 2026-06-10

#### Fixed

- **Chat markdown no longer crashes with MDEx 0.13.0.** MDEx 0.13.0 changed from returning `:lumis_not_enabled` to raising `ArgumentError` when Lumis is not configured. The `render_markdown/1` fallback now rescues `ArgumentError` in addition to matching on `:lumis_not_enabled`, and retries without syntax highlighting in either case.

### 4.0.10 - 2026-06-10

#### Fixed

- **Streaming chat typing dots now align left in all layout contexts.** Root cause: when `<Chat.conversation>` is placed in a flex container that sizes itself to content (e.g. `justify-content: center` wrappers), the chat collapses to ~48px wide. The bubble's `max-width: 80%` then resolves to ~38px, which is narrower than the typing indicator (16px dots + 32px padding). The dots overflowed into the right padding area, appearing at the right side of the bubble. Fixed by adding `min-width: min-content` to `pc-chat__bubble` so the bubble can never be narrower than its own content.

### 4.0.9 - 2026-06-09

#### Fixed

- **Streaming chat typing dots now align left inside the bubble.** `pc-chat__stream` now resets `text-align: left`, preventing any inherited right-alignment from pushing the `inline-flex` typing indicator to the right edge of the bubble. The 4.0.8 approach (changing `pc-chat__typing` to `display: flex`) caused the dot spans to stretch, so the typing indicator is back to `inline-flex` with the fix applied at the stream level instead.

### 4.0.8 - 2026-06-09

#### Fixed

- **Streaming chat typing dots now align left inside the bubble.** `pc-chat__typing` changed from `inline-flex` to `flex` to prevent inherited `text-align` from pushing dots right. (Superseded by 4.0.9 which reverts this and fixes at the stream level instead.)

### 4.0.7 - 2026-06-09

#### Fixed

- **Chat markdown Lumis fallback no longer raises `NimbleOptions.ValidationError`.** The 4.0.6 fallback used `formatter: :html_class`, which is not a valid Lumis formatter option (only `:html_inline` exists). The fallback now removes `syntax_highlight` entirely so MDEx renders code blocks without colours rather than crashing.

### 4.0.6 - 2026-06-09

#### Fixed

- **Chat markdown no longer crashes when Lumis NIF is unavailable.** `MDEx.to_html/2` returns `:lumis_not_enabled` when the Lumis NIF (required for `formatter: :html_inline` syntax highlighting) is not loaded. The case in `render_markdown/1` didn't handle this atom, causing a `CaseClauseError`. It now falls back to class-based syntax highlighting (`formatter: :html_class`), and if that also fails, falls back to escaped plain text.

### 4.0.5 - 2026-06-09

#### Fixed

- **Streaming chat typing dots now appear on the left of the bubble.** `pc-chat__stream` was `display: inline`, which could cause its inline formatting context to flow to the right side of the bubble in certain parent layouts (e.g. the docs page). Changed to `display: block` so the typing indicator always anchors to the left edge of the bubble, regardless of inherited text-alignment or flex context.

### 4.0.4 - 2026-06-08 14:03:58

#### Fixed

- **Accordion now works after LiveView live navigation.** The accordion's toggle behaviour lived in a per-instance inline `<script>`. LiveView does not execute inline scripts injected via live navigation, so an accordion reached through a `navigate` link was dead (clicks did nothing), and stale listeners from earlier full page loads could throw `Cannot read properties of null`. The behaviour now lives in the shipped JS bundle (`assets/js/petal_components.js`), registered once and surviving navigation. **You must import that bundle** (the same `import PetalComponents ...` step already needed for the input and Chat components) for the accordion to be interactive. Added a regression test asserting the component emits no inline `<script>`.

### 4.0.3 - 2026-06-08 13:12:01

#### Fixed

- **Ghost accordion now shows exactly one icon per item.** Completes the 4.0.2 fix. The conditional `hidden` class for the +/- icons was passed via an attribute spread that conflicted with the icons' explicit `class` and was silently dropped, so the server never hid the inactive icon - 4.0.1 masked this by hiding both behind `data-js-loading`, and 4.0.2 (which removed that gate) showed both. The `hidden` class is now part of the icon's own class list (the same pattern the chevron variant already used), so each item renders the correct single icon server-side, with or without JS. Added a regression test.

### 4.0.2 - 2026-06-08 12:58:42

#### Fixed

- **Ghost accordion +/- icons no longer disappear on LiveView pages.** The ghost variant hid both icons behind a `data-js-loading` attribute removed once on `DOMContentLoaded`. On a LiveView page the connected render re-applied the attribute after that one-shot removal, so the +/- icons stayed hidden. The server already renders the correct icon (plus when closed, minus when open), so the hide-until-JS gate was both redundant and the cause of the bug. Removed it; icons now render correctly with or without JS.

### 4.0.1 - 2026-06-08 12:07:39

#### Fixed

- **MDEx is now genuinely optional again.** v4.0.0 referenced `MDEx.Document.default_sanitize_options/0` in a module attribute, which is evaluated at compile time — so `petal_components` failed to compile unless the consumer also added `:mdex`, defeating the optional dependency. The markdown options are now built at call time, behind the existing runtime guard, so apps that don't use the Chat markdown components compile without `:mdex`.

### 4.0.0 - 2026-06-08 11:58:49

Petal Components v4 drops Alpine.js, adds an AI chat component family, and makes markdown rendering an optional dependency. See the [Upgrade Guide](UPGRADE_GUIDE.md) for migration steps.

#### Breaking

- **Dropped Alpine.js — all components are Phoenix.LiveView.JS only.** Components no longer emit `x-*` attributes, and apps no longer need Alpine.js for Petal Components. Register the bundled JS hooks in your LiveSocket instead (see the upgrade guide).
- **Removed the `js_lib` attribute** from `dropdown/1`, `accordion/1`, and the vertical menu components. Passing it now raises.
- **`input/1` and `field/1`** `viewable` (password), `copyable`, and `clearable` variants now rely on bundled JS hooks (`PetalPasswordToggle`, `PetalCopyInput`, `PetalClearableInput`) instead of Alpine. Register the hooks or these controls won't be interactive.
- **`PetalComponents.default_js_lib/0` is deprecated** and always returns `"live_view_js"`.

#### Added

- **Chat component family** (`PetalComponents.Chat`) for building streaming AI chat UIs — the LiveView-native answer to React's AI Elements / assistant-ui: `conversation`, `chat_message`, `streaming_text`, `prompt_input`, `markdown`, `tool_call`, `rich_text`, `reasoning`, `message_actions`, `copy_button`, `suggestions`, `chat_error`. The `Chat` family is **not** brought in by `use PetalComponents` (its generic names like `markdown/1` would clash with your own helpers) — `alias PetalComponents.Chat` and call it namespaced (`<Chat.conversation>`).
- **Bundled JS hooks** shipped at `assets/js/petal_components.js` (Petal Components now ships JS for the first time): `PetalChatStream`, `PetalChatComposer`, `PetalCopy`, `PetalCodeCopy`, `PetalChatScroll`, `PetalPasswordToggle`, `PetalCopyInput`, `PetalClearableInput`.
- **`MDEx` as an optional dependency** for `markdown/1` / `to_html/1` (sanitized, syntax-highlighted markdown, with live-streaming support via `streaming_text format="markdown"`). Add `{:mdex, "~> 0.12"}` to your deps to use it.

#### Fixed

- Accordion now finds its container by `container_id` from the toggle event, so a custom `container_id` works (previously only the auto-generated id worked).

### 3.2.2 - 2026-05-15 23:11:12

- Fix submenu keyboard focus: when a menu toggle is activated with Space or Enter, focus now moves to the first link inside the expanded submenu instead of staying on the toggle button. Matches the WAI-ARIA disclosure menu pattern. Affects both the Alpine.js and Phoenix.LiveView.JS variants.
- Fixed Firefox's native time picker icon overlapping AM/PM text in `field type="time"` (#377). Time inputs now get extra right padding under Firefox to make room for the native picker indicator.
- Fixed white button variants (`white`, `white-shadow`, `pure-white`) having no visible focus state in dark mode (#315). The focus state now shifts the background to gray-200, matching the dark hover state.

### 3.2.1 - 2026-05-15 21:30:12

- Fixed disabled `checkbox`, `switch`, and `checkbox-group` fields still submitting a value via their hidden companion input (#483). Native HTML form behavior excludes disabled fields from submission; the hidden input is now omitted when `disabled` is set.

### 3.2.0 - 2026-04-04 23:07:17

- Added composable JS hook attrs to components (modal, slide over, dropdown, accordion, menu, alert, tabs) so users can compose additional JS commands onto component lifecycle events (#239)
- Added `compose_js/2` helper for combining user and component JS structs
- Added `on_open` to modal and slide over
- Added `on_close` to slide over and dropdown
- Added `on_toggle` to accordion and menu
- Added `on_dismiss` to alert (with built-in hide behavior)
- Added `on_change` to tabs

### 3.1.0 - 2026-04-04 07:22:03

- Added smooth transitions and easing to interactive components (buttons, tabs, accordion, dropdown, table rows, pagination, menu items, checkboxes, file inputs, alert dismiss)
- Added focus-visible ring to buttons for keyboard accessibility
- Added active press scale feedback on buttons
- Fixed dropdown not working with Alpine.js 3.13.6+ (#379) — removed conflicting `@click.outside` on button, added initial `display: none` style for proper `x-show` initialization
- Fixed accordion state being wiped on LiveView DOM patches (#381, #323) — added `phx-update="ignore"` to LV.JS accordion container, rewrote Alpine accordion to use direct `active` state instead of nested getter/setter pattern that broke with Alpine 3.13+
- Added `multiple` attribute to accordion for expanding multiple sections simultaneously (#38) — works with both Alpine.js and LiveView.JS
- Fixed pagination prev/next arrows not wrapped in `<li>` elements (#391) — invalid HTML per spec
- Fixed multiple select field errors not showing when no option is selected (#439) — added hidden input to ensure `used_input?` returns true
- Added `copy_icon` and `copied_icon` attributes to copyable field (#474) — allows custom icon names instead of hardcoded clipboard icons

### 3.0.2 - 2026-03-21 21:46:00

- fix(container): scope mobile padding to small screens only — `pc-container--mobile-padded` was overriding responsive `sm:px-6`/`lg:px-8` rules due to Tailwind v4 cascade ordering

### 3.0.1 - 2025-03-27 01:06:01

- Bumps deps

### 3.0.0 - 2025-03-16 07:38:08

* Release for Tailwind 4

Tailwind 4 introduces breaking changes - the `2.9.x` releases have been deprecated in favour of `v3.0.0`

### 2.9.2 - 2025-03-14 06:46:59

* Correct light button active colour by @mitkins in https://github.com/petalframework/petal_components/pull/418

### 2.9.1 - 2025-03-14 06:16:15

* Tailwind instructions for upgrade guide and README by @mitkins in https://github.com/petalframework/petal_components/pull/416
* Address CSS anomolies after Tailwind 4 upgrade by @mitkins in https://github.com/petalframework/petal_components/pull/417

### 2.9.0 - 2025-03-11 03:36:55

* Prepare Petal Components for Tailwind 4 by @mitkins in https://github.com/petalframework/petal_components/pull/415
* Bump phoenix from 1.7.19 to 1.7.20 by @dependabot in https://github.com/petalframework/petal_components/pull/407
* Bump phoenix_live_view from 1.0.4 to 1.0.5 by @dependabot in https://github.com/petalframework/petal_components/pull/413
* Bump a11y_audit from 0.2.2 to 0.2.3 by @dependabot in https://github.com/petalframework/petal_components/pull/412
* Bump ex_doc from 0.37.1 to 0.37.3 by @dependabot in https://github.com/petalframework/petal_components/pull/414
* Hide the calendar icon in inputs in Firefox. by @r38y in https://github.com/petalframework/petal_components/pull/394
* Fix hidden `checkbox-group` input name by @IdoLeshkowitz in https://github.com/petalframework/petal_components/pull/405

### 2.8.4 - 2025-02-22 22:04:15

- User Dropdown Menu - `avatar_src` and `current_user_name` are optional by @mitkins in https://github.com/petalframework/petal_components/pull/406

### 2.8.3 - 2025-02-21 22:12:41

- Allow for multiple instances of the `slide_over` component by @mitkins in https://github.com/petalframework/petal_components/pull/404
- Bump ex_doc from 0.37.0 to 0.37.1 by @dependabot in https://github.com/petalframework/petal_components/pull/403

### 2.8.2 - 2025-02-17 05:41:23

- Workaround for Slide Over and Modal with LiveView 1.0.4
- Bump to Phoenix LiveView 1.0.4

### 2.8.1 - 2024-12-17 01:12:12

- Bumped LiveView to 1.0.1
- Bumped Phoenix to 1.7.18

### 2.8.0 - 2024-12-11 00:28:11

- Update for forms V1 and V2 to support LiveView 1.0 - https://github.com/petalframework/petal_components/pull/382 (thanks @joepstender for your contribution

### 2.7.4 - 2024-12-04 20:57:07

- Bumped LiveView to 1.0
- Bumped other deps

### 2.7.3 - 2024-11-29 02:37:33

- fix icon backgrounds on disabled input (finally fixed, whoops)

### 2.7.2 - 2024-11-29 02:26:37

- fix icon backgrounds on disabled input

### 2.7.1 - 2024-11-27 21:34:32

- Add trigger_class prop to target dropdown_with_label base classes
- Change default dropdown_with_label base classes for dark mode

### 2.7.0 - 2024-11-27 07:50:55

- Add ghost and light color variants to buttons
- Adds radius opts to buttons and icon_buttons
- Adds no_margin prop to field_wrapper
- Fixes custom datetime and time icons bg color on error state

### 2.6.1 - 2024-11-18 02:16:57

- Squashes button_group warnings
- Fix the date inputs icon overlap in safari

### 2.6.0 - 2024-11-12 02:47:23

- Added Marquee component
- Added review_card
- add no_margin to p tags
- add tests and a11y checks pass

### 2.5.2 - 2024-11-01 02:58:45

- style icon better for cross browser support

### 2.5.1 - 2024-10-31 05:48:51

- update stepper with better responsiveness across vertical and horizontal orientations
- update input to accept clearable, copyable and viewable

### 2.5.0 - 2024-10-30 02:04:14

- New Stepper component
- New Radio Card field
- Adds viewable icon to password field and upgrades date and time icons to heroicons for cleaner look and to facilitate dark mode better
- Adds copyable and clearable functionality to respective fields

### 2.4.3 - 2024-10-24 00:45:20

- bump default switch size to md
- fix rendering .alert with HTML fails #361

### 2.4.2 - 2024-10-24 00:08:31

- missing w-full and adds test for pc-accordion--ghost

### 2.4.1 - 2024-10-24 00:00:03

- fix, variant classes not passing through correctly

### 2.4.0 - 2024-10-23 04:13:40

- Allow for different switch sizes and fix some error state colors

### 2.3.0 - 2024-10-21 23:37:49

- Provide more variants for alert and badge (soft) to allow better support for dark mode
- Bump a11y_audit from 0.2.0 to 0.2.1

### 2.2.1 - 2024-10-18 01:12:17

- Fixes slide over opening animation

### 2.2.0 - 2024-10-07 09:55:16

- Update accordion so that you can set a particular item to be open at render

### 2.1.2 - 2024-10-07 01:52:01

- update button_group to support custom bg and border style props

### 2.1.1 - 2024-10-07 01:08:01

- move button_group classes into default css file
- update button_group classes

### 2.1.0 - 2024-10-02 03:12:09

- Adds new ghost table variant for extremely clean look

### 2.0.6 - 2024-09-26 04:23:16

- Items center correctly for the Icon Button by @mitkins in https://github.com/petalframework/petal_components/pull/352

### 2.0.5 - 2024-09-25 23:42:23

- implement button_group/1 component by @tylerbarker in https://github.com/petalframework/petal_components/pull/351

### 2.0.4 - 2024-09-23 04:31:51

- Add skeleton css classes to default css to allow for configurability

### 2.0.3 - 2024-09-20 23:45:16

- Fixed margin and dark mode for Avatar placeholder

### 2.0.2 - 2024-09-20 04:06:05

- Fixed: heroicon pattern matching is based on deps folder - rather than dependencies listed for petal_components 
- Improved error messages for incorrect heroicon names

### 2.0.1 - 2024-09-20 01:48:10

- Ensure css transitions don't cause flaky tests
- Remove text placeholder from image skeleton to match video skeleton

### 2.0.0 - 2024-09-17 06:59:11

- a11y improvements by @tylerbarker in https://github.com/petalframework/petal_components/pull/331
- Make Petal Components Accessible by @tylerbarker in https://github.com/petalframework/petal_components/pull/326
- Aligns .icon with latest heroicon method by @mitkins in https://github.com/petalframework/petal_components/pull/340
- Generate list of heroicons if the dependency exists by @mitkins in https://github.com/petalframework/petal_components/pull/345
- Skeleton placeholder to be shown when loading content by @GraphiteSprite in https://github.com/petalframework/petal_components/pull/319
- Hide dropdown when pressing escape by @RobinBoers in https://github.com/petalframework/petal_components/pull/334
- Remove `for` attribute in `radio-group` label by @tegon in https://github.com/petalframework/petal_components/pull/333
- Remove for attribute in checkbox-group label by @mitkins in https://github.com/petalframework/petal_components/pull/336
- Use `spans` instead of `labels` if there is no `for` attribute by @mitkins in https://github.com/petalframework/petal_components/pull/344
- Cleanup type of class attrs by @nallwhy in https://github.com/petalframework/petal_components/pull/329
- Add default_js_lib config by @nallwhy in https://github.com/petalframework/petal_components/pull/335

### 1.9.3 - 2024-05-27 04:03:39

- Rounds the width of the progress component to 2 decimal places

### 1.9.2 - 2024-02-13 02:51:59

- Adds optional empty states for tables.
- named slot :empty_state
- always rendered at the top of the table into a cell that spans the whole width (the width is derived from the number of :col slots supplied)
- the row that holds the cell has hidden only:table-row Tailwind classes so it's only visible if it's the only row
- the slot takes row_class that is then forwarded to the cell
- renders multiple cells if more than one :empty_state slot is given

### 1.9.1 - 2024-02-01 19:24:57

- Fix modal class
- Removes scale classes on sm size and up for slideover

### 1.9.0 - 2024-01-27 23:11:33

- <.vertical_menu> - add support for liveview JS (thanks to @mrdotb)
- <.table> - now supports dynamic data and col slots

### 1.8.0 - 2024-01-15 04:38:46

- Updated deps
- Use new PhoenixHTMLHelpers lib
- Fix bug where the close_modal event gets sent twice to the LiveView if you push_patch from the close_modal handle_event in the LiveView - thanks @axelclark


### 1.7.1 - 2023-11-06 23:11:51

- Fix form_field switch class bug [#275]
- Vertical menu items no longer require an icon

### 1.7.0 - 2023-10-14 00:57:34

- Added close_on_click_away to `<.slide_over>` (thx @samuelpordeus)
- Added close_on_escape to `<.slide_over>` (thx @samuelpordeus)
- Added fade in transition to `<.slide_over>`
- Cleaned up classes in codebase (deprecated build_class)

### 1.6.2 - 2023-10-03 18:39:33

- Default loading spinner to shrink-0 to enforce its size

### 1.6.1 - 2023-10-02 19:24:14

- Add pagination attribute allowing always shown prev and next buttons
- Pagination support encoded path
- icon-support-to-breadcrumb-link

### 1.6.0 - 2023-09-23 07:55:44

- Fix: <.button disabled> where link_type not "button" now shows proper cursor and isn't clickable
- Fix: <.a> now uses <.link> underneath to avoid warnings with live_view 0.20.0
- Update: live_view bumped to 0.20.0

### 1.5.5 - 2023-09-18 02:15:19

- adds an attribute to `hide_close_button` in the modal header

### 1.5.4 - 2023-09-13 04:05:32

- Changed close icon svg to Heroicons

### 1.5.3 - 2023-09-11 03:53:22

- Allow configurability of menu icons active/inactive state + test

### 1.5.2 - 2023-09-09 01:04:37

- Added BEM classnames for menu components

### 1.5.1 - 2023-09-06 04:55:54

- Add `disabled` attribute to Tab component

### 1.5.0 - 2023-09-05 04:05:44

- New high-contrast `dark` button color
- Breaking change: please update Tailwind in config.exs to `3.3.3` then run `mix tailwind.install`

### 1.4.9 - 2023-09-04 03:03:18

- Add target attribute for sending pagination events to LiveComponents

### 1.4.8 - 2023-08-24 02:56:03

- Add `close_on_click_away` attr on modal [Issue 253)[https://github.com/petalframework/petal_components/pull/253]
- Add `close_on_escape` on modal

### 1.4.7 - 2023-08-24 02:18:04

- Added type=button to close modal button

### 1.4.6 - 2023-08-20 22:12:28

- Added support for disabled attribute on dropdown menu items

### 1.4.5 - 2023-08-13 22:23:12

- Added type=button to close slide over button

### 1.4.4 - 2023-08-08 02:02:15

- Fix: Icon button setting info to primary + test

### 1.4.3 - 2023-08-04 02:12:44

- input can now be passed a class attribute

### 1.4.2 - 2023-08-04 01:45:24

- Add option to send events in pagination component

### 1.4.1 - 2023-07-28 10:32:02

- Added support for styling last accordion item
- Added checked_value and unchecked_value to switch global rest

### 1.4.0 - 2023-07-26 03:14:50

- Updated accordion class name from "pc-accordion-item--last" to "pc-accordion-item--all-except-last"

### 1.3.0 - 2023-07-21 08:00:47

- New: <.vertical_menu> component
- New: <.user_dropdown_menu> component

### 1.2.14 - 2023-07-16 02:42:07

- Fix: Modal phx-remove call to hide_modal
- New: form fields now show a red asterisk for required fields

### 1.2.13 - 2023-06-30 03:32:59

- Updated: button can accept a "form" attribute

### 1.2.12 - 2023-06-26 23:24:23

- Improvement: file input looks better in dark mode

### 1.2.11 - 2023-06-07 00:18:05

- Fix: allow checkbox/radio labels to support links. eg. `<.field type="checkbox" field={@form[:checkbox]} label={raw(~s|Please accept these <a href="#" class="text-blue-500">Terms and Conditions</a> before continuing|)} />`

### 1.2.10 - 2023-06-05 02:06:55

- Bumped phoenix_live_view dep to 0.19

### 1.2.9 - 2023-06-01 02:35:12

- Updated: add empty_message attr to `<.field>` (`<.field type="checkbox-group|radio_group" empty_message="No options">`)
- Fixed: `<.field type="switch">` not providing a `false` value when unchecked

### 1.2.8 - 2023-05-27 05:03:40

- Add light button variant for dark mode friendliness

### 1.2.7 - 2023-05-27 03:34:33

- Fixed radio-group value not being checked for integers

### 1.2.6 - 2023-05-26 01:45:26

- Fix radio-group checked options for <.field>
- Fix select selected options

### 1.2.5 - 2023-05-20 00:34:56

- Fix: <.field type="textarea" rows="1"> - rows for textarea are now overridable

### 1.2.4 - 2023-05-17 04:38:50

- Fixed button with icon (reverted tooltip)

### 1.2.3 - 2023-05-17 03:52:29

- Updated: Move custom css classes to last so they can potentially override default ones (button, loading)
- Added: `tooltip` option to `<.button>`

### 1.2.2 - 2023-05-17 02:26:44

- Updated: checkbox_group now supports `disabled_options` attr

### 1.2.1 - 2023-05-16 02:56:56

- Fixed transitions on modal
- Updated `<.field>` to take a `label_class` attr

### 1.2.0 - 2023-05-11 10:15:53

- Breaking change: `<.field type="checkbox_group">` is now `<.field type="checkbox-group">` (to match `datetime-local`)
- Breaking change: `<.field type="radio_group">` is now `<.field type="radio-group">` (to match `datetime-local`)
- Fixed: radio group state
- Fixed: textarea height
- Fixed: CSS now conforms to tailwind config colors (eg. changing `danger` in tailwind config will now change the color of the `danger` button/alert/etc.)
- Fixed error CSS on textarea/select/switch

### 1.1.6 - 2023-05-09 10:20:42

- Fix <.field> checkbox_group not keeping state
- Changed <.field> textarea to be the same size as v1 form_field version

### 1.1.5 - 2023-05-08 23:07:33

- Fixed `class` attr not working in `<.field>` for types "select", "checkbox_group", "radio_group" and "textarea"
- Fixed <.card_footer> `class` attr not working

### 1.1.4 - 2023-05-06 04:46:08

- For consistency, the group_layout attr on <.field> should be a string like the type

### 1.1.3 - 2023-05-05 23:31:07

- Ensure help_text div isn't in DOM when no help text is provided

### 1.1.2 - 2023-05-05 23:18:10

- Added help_text to <.field>

### 1.1.1 - 2023-05-05 21:34:23

- Renamed .error to .field_error
- Renamed .label to .field_label

### 1.1.0 - 2023-05-05 04:45:56

- New: <.field> component to replace <.form_field>. <.field> takes the new `%Phoenix.HTML.FormField{}` struct, which better optimizes forms for live views
- New: <.input> component - these represent inputs but styled with Petal Components. It differs from <.field> in that you don't get a label or error messages.
- New: <.label> component - just a label styled with Petal Components. These are used inside a <.field>.
- New: <.error> component - an error message for form fields. These are used inside a <.field>.
- Updated: <.tab> can now take a class attr

### 1.0.8 - 2023-05-03 04:47:14

- Fix checkbox group issue introduced in 1.0.7

### 1.0.7 - 2023-04-27 08:16:41

- Fixed checkbox group giving an empty string instead of a list when submitted
- Added transitions to the icon button tooltip

### 1.0.6 - 2023-04-22 00:52:23

- New: Add `separator_class` option to `<.breadcrumb>`
- New: Add `tooltip` option to `<.icon_button>`

### 1.0.5 - 2023-04-03 09:33:31

- New: <.rating> component
- Fixed: error was showing prematurely on forms

### 1.0.4 - 2023-02-28 03:57:29

- Updated: Slideover now accepts a close target for when it is in a live_component
- Fixed: Disabled buttons and links should not do anything when clicked

### 1.0.3 - 2023-02-26 03:47:33

- Fixed: `hidden_input` not working correctly in `form_field`. Thanks @BobbieBarker!
- Fixed: `disabled` attribute wasn't working on non-button buttons (eg. a live_redirect)
- Fixed: Added alpine JS x-cloak hidden in CSS to avoid flash of unstyled content

### 1.0.2 - 2023-02-23 10:33:11

- Fixed: fixed an issue where phx-feedback-for was not being properly included inside of the form_field component (thanks @BobbieBarker)
- Update: Make paragraph text easier to read

### 1.0.1 - 2023-02-20 05:37:11

- Fixed issue "The `invalid-feedback` class does not exist" [#141]

### 1.0.0 - 2023-02-16 20:22:49

- Extracted classnames for each component into a CSS file using BEM naming convention. This allows for more flexibility in styling and theming.

### 0.19.10 - 2023-01-14 09:24:34

- Fixed: support button attrs: 'value', 'name'
- Fixed: support form element attr: 'accept'
- Fixed: support link attr: 'download'

### 0.19.9 - 2023-01-12 22:41:06

- Fix: <.th> can now accept colspan and rowspan

### 0.19.8 - 2023-01-12 00:37:24

- New: Button now can take an icon name as an attribute. eg `<.button icon={:home} label="Home" />`

### 0.19.7 - 2023-01-11 21:20:15

- Fixed disabled buttons

### 0.19.6 - 2023-01-01 22:18:07

- New: `<.hidden_input>` form element
- Added "list" attr warning for inputs
- Added "for" attr warning for label

### 0.19.5 - 2022-12-30 06:00:52

- Changed: form_help_text colours

### 0.19.4 - 2022-12-29 00:10:21

- New <.icon> functional component that renders a dynamic Heroicon (v2)
- Added label_class attr to all form inputs so you can change the look of labels
- Fixed "checked" attr for checkbox_group use with form_field

### 0.19.3 - 2022-12-22 02:42:17

- Added: help text for form fields
- Enhancement: <.td> can now accept colspan and rowspan attributes
- Enhancement: Added some optional textarea attributes: cols, rows and wrap
- Fixed: checkbox_group "checked" attr wasn't getting passed through
- Fixed: checkbox label wasn't working when no label attr was passed

### 0.19.2 - 2022-12-18 20:22:40

- Enhancement: Dropdowns are more customisable with classes
- Chore: Cleaned up form field attrs
- Fix: Changed the heading attr :no_margin to be a :boolean

### 0.19.1 - 2022-12-14 00:56:52

- Fixed form_field class attribute - it wasn't getting appended to the input classes properly

### 0.19.0 - 2022-12-13 05:11:47

- Added declarative assigns for all components
- Fix default green button having the wrong background

### 0.18.5 - 2022-10-06 02:04:15

- Fix compilation error on form.ex

### 0.18.4 - 2022-10-06 01:43:08

- Fixed compilation errors in accordion

### 0.18.3 - 2022-09-28 03:54:34

- Fix accordion icon not animating when opening

### 0.18.2 - 2022-09-28 00:38:14

- Add disabled classes for checkbox

### 0.18.1 - 2022-09-27 03:29:44

- HeroiconsV1 do not have default classes anymore
- Fix issue where `.icon_button` svg icons were not the correct size

### 0.18.0 - 2022-09-25 01:11:49

- Sorry, the last release was meant to be minor, not patch

### 0.17.8 - 2022-09-25 01:10:23

- Updated to work with Live View 0.18 - see UPGRADE_GUIDE.md
- Disabled fields fixed in dark mode - thanks @moogle19
- Pagination component can receive a function as a parameter that will define the path of the page - thanks @Wigny

Breaking changes

- `<.link>` was renamed to `<.a>`.
- Renamed `Heroicons` to `HeroiconsV1`

### 0.17.7 - 2022-08-10 00:34:26

- Fix 'modal' IDs used at SlideOver component
- Make accordion items dynamic
- Add coveralls + dependabot
- Remove credo from ci
- Add codecov token
- Add mix audit alias
- Add codecov badge
- Use string.replace to allow "-"
- Make borders for radio and checkbox consistent with other inputs
- Fixed pagination control if users set sibling_count to less than 1 or boundary_count less than 1
- Moved Pagination.get_items to PaginationInternal.get_pagination_items so we can get at it in the unit tests

### 0.17.6 - 2022-07-20 03:59:09

- Fixed issue where closing modal/slideover caused two events to be fired

### 0.17.5 - 2022-07-15 05:01:55

- Move card bg colors to the parent div

### 0.17.4 - 2022-07-15 04:09:17

- modified accordion aesthetic
- differentiated white inverted button type

### 0.17.2 - 2022-07-07 06:19:05

- Added an inverted button type that fills the outlined button on hover
- Added ring/border to card and table to add more distinction on white backgrounds
- Added a bg color and shadow to accordion

### 0.17.1 - 2022-07-06 01:05:09

- Modals - only send close_modal event to target if provided

### 0.17.0 - 2022-07-02 03:29:33

- New components: <.prose>, <.ul>, <.ol>
- Modals fade in (extra CSS required)
- Improve readability of card content in dark mode
- Extra assigns on <.p> are forwarded to the p tag
- Fix extra_assigns in headings
- Fix dropdown button not closing when clicked

### 0.16.0 - 2022-05-03 00:56:17

- Generate prettier classes with build_class
- Accordion
- Now use inline-block for icon buttons

### 0.15.0 - 2022-04-19 00:06:22

- Switch - new form component

### 0.14.0 - 2022-04-08 00:49:03

- Slide Over

### 0.13.7 - 2022-03-28 00:02:41

- Added info, warning and gray variants to buttons
- Added gray variant to progress
- Fixed progress test
- Form does not leak the class assign as it's already set from classes
- Made tabs text in dark mode lighter and changed assigns_to_attributes to be consistent with other components

### 0.13.6 - 2022-03-27 23:59:54

- Added info, warning and gray variants to buttons
- Added gray variant to progress
- Fixed progress test
- Form does not leak the class assign as it's already set from classes
- Made tabs text in dark mode lighter and changed assigns_to_attributes to be consistent with other components

### 0.13.5 - 2022-03-09 04:53:41

- Excluded label and sub_label in the user_inner_td
- Fixed pagination to work when less than 5 pages
- Fixed corners of red bg on file input error
- Removed prop references to size_class, rename size_class / css_class to :string
- Updated the heroicons generator to use "extra_assigns" instead of "extra_attributes"

### 0.13.4 - 2022-03-07 03:11:28

- Fixed table to accept extra attributes and updated table tests

### 0.13.3 - 2022-03-06 23:47:24

- added user_inner_td and fixed formatting where thead and tbody are required

### 0.13.2 - 2022-02-28 02:23:54

- added row layout to radio group

### 0.13.1 - 2022-02-25 20:17:55

- Fixed button type not working

### 0.13.0 - 2022-02-25 03:50:18

- Table

### 0.12.0 - 2022-02-22 21:25:39

- Icon buttons
- Made a link type button and refactored dropdown
- Removed negative margin on spinner
- Removed unnecessary underline statement in tabs

### 0.11.4 - 2022-02-21 00:52:06

- Removed excess class "border-transparent" from white button

### 0.11.3 - 2022-02-17 23:24:49

- Fixed bug with placeholder avatars

### 0.11.2 - 2022-02-16 05:40:24

- Fix issue where untouched inputs were highlighted red

### 0.11.1 - 2022-02-16 04:15:40

- Added object-cover to card_media

### 0.11.0 - 2022-02-15 22:00:59

- Heroicons.Solid icons size defaults to "w-5 h-5" as recommended in their docs
- Form inputs no longer show errors before they have been touched by the user. To get this to work, I had to remove the error classes off the inputs themselves, so they no longer turn red on error by default. However, you can turn this back on by adding these rules to your app.css file (we will update the install docs with this):

```
label.has-error:not(.phx-no-feedback) {
  @apply !text-red-900 dark:!text-red-200;
}

textarea.has-error:not(.phx-no-feedback), input.has-error:not(.phx-no-feedback), select.has-error:not(.phx-no-feedback) {
  @apply !border-red-500 focus:!border-red-500 !text-red-900 !placeholder-red-700 !bg-red-50 dark:!text-red-100 dark:!placeholder-red-300 dark:!bg-red-900;
}

input[type=file_input].has-error:not(.phx-no-feedback) {
  @apply !border-red-500 !rounded-md focus:!border-red-500 !text-red-900 !placeholder-red-700 !bg-red-50 file:!border-none dark:!border-none dark:!bg-[#160B0B] dark:text-red-400;
}

input[type=checkbox].has-error:not(.phx-no-feedback) {
  @apply !border-red-500 !text-red-900 dark:!text-red-200;
}

input[type=radio].has-error:not(.phx-no-feedback) {
  @apply !border-red-500;
}
```

### 0.10.8 - 2022-02-15 01:11:32

- Fixed <.a> emitting white spaces

### 0.10.7 - 2022-02-14 03:44:45

- Fixed white button background

### 0.10.6 - 2022-02-14 03:31:50

- Removed pure_white button shadow variant and fixed white bg for shadow

### 0.10.5 - 2022-02-11 22:30:21

- Fixed Heroicons sometimes failing

### 0.10.4 - 2022-02-10 19:49:47

- Fixed card_media not working properly on Safari

### 0.10.3 - 2022-02-03 01:18:38

- Added <.card_footer> for content you would like fixed to the bottom of a card
- Added `category_color_class` to <.card_content> so that you can customize category colors

### 0.10.2 - 2022-01-29 01:51:55

- <.h1>, <.h2> etc now turn into those underlying html elements (h1, h2 etc)
- <.card_media> utilises Tailwinds aspect-ratio classes
- Fix <.card> `class` assigns appearing twice

### 0.10.1 - 2022-01-26 04:02:41

- Buttons can now take custom classes

### 0.10.0 - 2022-01-26 01:18:58

- [BREAKING CHANGE] Rename alert property "state" to "color"
- Add checkbox_group form field type
- Fix z-index issue with dropdown
- Update Alert colors
- Add icons to badges

### 0.9.3 - 2022-01-19 19:28:35

- Fixed z-index issue with dropdowns

### 0.9.2 - 2022-01-19 05:33:26

- Fixed `<.dropdown_menu_item>` where extra_attributes weren't being passed to underlying button
- Fixed z-index issue on dropdowns

### 0.9.1 - 2022-01-19 02:55:17

- New form component `<.date_select ...>`
- New form component `<.date_input ...>`
- Add dark mode to components
- Fix dropdown failing when no label provided
- Fix dropdown button not having type=button
- Allow dropdown to have custom trigger buttons

### 0.9.0 - 2022-01-07 04:43:03

- New component: Card
- Button colored shadow option
- Improve styling on disabled inputs
- Allow custom attributes to be forwarded to underlying svg element on Heroicons

### 0.8.0 - 2021-12-15 20:17:41

- New component: Tabs
- Fix button that was failing when in a loading state and no size given
- Avatar now uses the `object-cover` class for non-square images
- New badge variations
- Badge can now accept a class prop

### 0.7.0 - 2021-12-07 03:54:41

- Breadcrumbs no longer need a parent flex container

### 0.6.1 - 2021-12-07 00:51:25

- Default the modal max_width to md

### 0.6.0 - 2021-12-07 00:14:21

- New component: `<.modal>`
- Fixed container not defaulting to full width when inside a flex
- Add docs for `<.p>` and heading params

### 0.5.1 - 2021-11-26 00:54:25

- `<.a>`, `<.button>` and `<.dropdown_menu_item>` all now take `method` as a parameter. eg. `<.a method={:delete} to="/logout" label="Logout" />`

### 0.5.0 - 2021-11-22 02:00:02

- Added `<.pagination>`
- Added `<.progress>`
- Improved `<.a>` to work as a live_patch or live_rediect

### 0.4.0 - 2021-11-18 02:18:16

- Added new form components ("email_input", "number_input", "password_input", "search_input", "telephone_input", "url_input", "time_input", "time_select", "datetime_local_input", "datetime_select", "color_input", "file_input", "range_input")
- `<.spinner>` defaults to visible

### 0.3.2 - 2021-11-15 02:50:45

- Add new component Avatar
- `<.form_field>` now shows errors from changesets

### 0.3.1 - 2021-11-09 07:36:13

- Added breadcrumbs components
- Removed unnecessary badge colors

### 0.3.0 - 2021-11-07 20:11:56

- import instead of alias the functions
- removed references to assigns in the HEEX templates to allow proper change tracking
- form functions like text_input now only create an input without the label
- added a `form_field` function that will include the label
- fixed the spinner on different button sizes
- removed alert sizing - stick with on size for now

### 0.2.2 - 2021-11-06 01:34:48

- Fixed Alert.alert not allowing wrapping
- Added heading parameter to Alert.alert

### 0.2.1 - 2021-11-04 22:45:38

- Updated dropdown to include live_patch and live_redirect

### 0.2.0 - 2021-11-04 06:43:01

- Added new component Alert
  - Added new component Loading
  - Added some tests
