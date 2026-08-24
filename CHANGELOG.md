# Changelog
### Unreleased

#### Added

- **New `number_field` component: a real spinbutton for quantities,
  prices and percentages, in place of a bare
  `<input type="number">`.** The native number input has spinners you
  can't style, that differ in every browser, and a value the browser
  sanitises out from under you the moment you try to format it. This one
  is a text input carrying `role="spinbutton"` on the existing
  `input_group` surface, so it inherits the border, radius, focus ring
  and error tone the rest of the form family already uses, and the
  steppers are ours to draw. Three variants: `stacked` chevrons at the
  inline end, `split` minus and plus with the value centred - the cart
  quantity look - and `plain` for keyboard only. `min`, `max` and `step`
  clamp and mirror to `aria-valuemin` / `aria-valuemax` /
  `aria-valuenow`; `big_step` (defaulting to ten steps) rides
  shift+arrow and page up/down; Home and End jump to the bounds.
  `precision` rounds and pads on blur while the raw text stands while
  you type, so `7.5` becomes `7.50` only once you're done - and the
  moduledoc documents the `Intl.NumberFormat` pattern for currency and
  percent display, because no formatting dependency ships with this. The
  `PetalNumberField` hook owns the stepping, the clamping, wheel while
  focused, and hold-to-repeat that accelerates and stops on
  `pointerleave` as well as `pointerup`. The input is the single tab
  stop, the buttons are labelled at `tabindex="-1"`, and a button at its
  bound takes `aria-disabled` rather than `disabled` so it keeps its
  name for a screen reader. `<.field type="number-field">` wires it into
  the label/help/error machinery, and `<.field type="number">` is
  untouched.

- **`stepper` gains `size="xs"`, `variant="bars"`, and circles that
  don't need names.** Three gaps against the reference set, closed
  together. `xs` is a 24px disc with 11px numerals, sized for a rail
  that sits above a form rather than one that headlines the page, and it
  carries its own labels-bottom connector offsets like the other sizes.
  Steps whose maps leave out `name` and `description` now render no
  label block at all rather than an empty one, so a nameless stepper is
  circles and connectors with nothing padding them out - the plain
  numbered rail everyone else ships as a separate "basic" component is
  just this one with less in its maps, and each step's `aria-label`
  falls back to its count. `variant="bars"` trades the discs for a row
  of 4px segments and drops the connectors, because the gaps between
  segments are already the rail: completed and current fill solid,
  ahead of you stays the same gray hairline the connector uses, the
  numerals go `sr-only`, and titles (when the steps have names) sit
  under their own segment, left-aligned, muted for the ones you haven't
  reached. Bars is horizontal only and outranks `label_placement`.
  Everything else is byte for byte identical between the two paints -
  same jump targets, same `role="list"`, same `aria-current`, same
  completed labels - so it really is one component with two faces. The
  "Step 3 of 4" line people pair with the bars is composition, not an
  attr, and the showcase demonstrates the shape.

- **`modal` takes a `:footer`.** Every dialog with a Save button was
  building the same row by hand at the bottom of the content - a
  `flex justify-end gap-2 mt-6` div, give or take the margin - and it sat
  on the body's own surface, so a modal and a slide over open on the same
  page looked like two different components. The slot puts the row where
  it belongs. It renders below the content in a band: border on top, muted
  wash behind, edge to edge, the exact treatment the table's tfoot wears
  and the one the alert dialog will ship with. Buttons stack on a narrow
  screen with the primary action on top under the thumb, and unstack to a
  right-aligned row from `sm` up. Want something on the far left instead -
  a docs link, a step counter - put one full-width child in the slot and
  lay it out yourself; the band, the border and the padding stay the
  component's job.

  Pinning it meant changing how the box scrolls, which is the part worth
  reading twice. The box used to be one scrolling block, so a long body
  carried the header off the top and would have carried the footer off the
  bottom. It is now a column, the same shape the slide over has always
  had: header and footer are fixed bands and the content between them is
  the only part that scrolls. That is a visible change for a modal with
  more content than fits, footer or no footer - the title now stays put
  where it used to scroll away - and it is the behaviour the component
  should have had. Everything else is untouched: omit the slot and the
  modal renders exactly what it always did, buttons in the content and
  all.

- **`badge` takes a status dot.** Every app that shows state ends up
  writing the same span by hand - a 6px filled circle in front of the
  label - because that is how a status reads at a glance in a table of
  forty rows. `dot` renders it. The dot takes the badge's own colour at
  the strength that ramp reads as "the" colour, so a success badge gets a
  green dot and a danger badge a red one with nothing else to pass: the
  600 stop on `light`, `soft` and `outline`, rising to 400 in the dark
  where soft and outline go translucent, and `currentColor` on `dark`,
  where a saturated fill leaves no stop of its own ramp visible (that also
  means it picks up the `--pc-button-solid-fg` token rather than a
  hardcoded white). It scales with `size`, from 4px at `xs` to 8px at
  `xl`, and sits `shrink-0` so it stays a circle next to a long label. The
  dot is `aria-hidden` on purpose - the colour only repeats what the label
  already says, so a screen reader gets "Failed", not "Failed" and a
  circle. It composes with `with_icon` (dot, then icon, then text), and
  `dot` defaults to false, where the badge renders byte for byte what it
  always did.
- **The dropdown places its panel with `side` and `align`.** Two attrs
  that were three answers to two questions. `side` is which side of the
  trigger the panel opens on: `"bottom"`, `"top"`, or `"left"` / `"right"`
  for a panel that opens BESIDE the trigger, over whatever sits next to it
  rather than over the thing it belongs to - the sidebar account panel
  that pushes out into the content area instead of burying the nav it grew
  from. `align` is which edges line up on the other axis, `"start"` or
  `"end"`, and it reads horizontally for a panel above or below (start
  grows it rightward, end grows it leftward) and vertically for one beside
  (start aligns the tops, end aligns the bottoms - the sidebar-bottom
  one). Leave `side` out and nothing changes: the panel opens downward and
  the hook measures on every open. Name a side and there is nothing left
  to measure, so the hook never attaches - including for `"left"` and
  `"right"`, which are not on the flip's axis at all. That last one is a
  deliberate limit rather than an oversight: a side-out panel that would
  run off a short viewport stays where you put it, because you put it
  there. `placement` and `direction` are the older spelling of the same
  two questions, they keep working unchanged, and they map straight on -
  `placement="left"` is `align="end"`, `placement="right"` is
  `align="start"`, `direction="up"` is `side="top"`, `direction="down"` is
  `side="bottom"`, `direction="auto"` is naming no side at all. Pass both
  spellings and the new one wins. `user_dropdown_menu` passes `side` and
  `align` through like the rest.
- **The badge's dot can carry a different colour to the badge.** A dot in
  the badge's own colour is right when the state is the message. It is the
  wrong shape for the other convention, the one reui uses: a quiet chip
  where the label is what varies and the same three or four states repeat
  behind it, so the colour belongs on the circle and nowhere else.
  `dot_color` puts it there. `<.badge color="gray" variant="outline" dot
  dot_color="success">Production</.badge>` is neutral chrome with a green
  dot, and it is the same green a success outline badge's own dot shows,
  because the override takes the stop that variant already maps the colour
  to rather than inventing one. It defaults to nil, which inherits exactly
  as before, so nothing you have written moves. The one variant it cannot
  match is `dark`, where the inherited dot is `currentColor` and no ramp
  can match that: an override there takes the 400 stop, which means naming
  the badge's own colour on `dark` is a visible change rather than a
  no-op, and same-hue on `dark` is the one combination with little to show.

- **The dropdown takes an explicit open direction.** The panel learned to
  flip upward when the viewport left no room below it, which is the right
  behaviour when nobody knows in advance. At the bottom of a sidebar
  somebody does: it opens up, every time, and measuring to rediscover that
  on each open buys a MutationObserver, two sets of scroll and resize
  listeners and a frame's worth of risk that the panel paints downward
  first. `direction` says it outright. `"auto"` is the default and is
  exactly what shipped before - the hook attaches and measures. `"up"`
  renders the panel already flipped and never attaches the hook at all.
  `"down"` pins it downward and skips the hook too. `user_dropdown_menu`
  passes `direction` through, alongside the new `menu_items_wrapper_class`,
  so a sidebar account menu can be `direction="up"` with the panel pinned
  to the sidebar's width.
- **`user_dropdown_menu` accepts its own panel.** The component built the
  menu from a `user_menu_items` list of maps, which is right up until the
  menu wants an org switcher, a group label or a theme row - none of which
  fit in a `%{path:, icon:, label:}`. Pass content in the inner block
  instead and it replaces the generated list; the trigger, including
  `variant="sidebar"`, is untouched. `user_menu_items` is now optional.
- **`dropdown_menu_row` parks a control in the panel.** A theme switcher or
  a plan badge is not a command, so it should not be a menu item pretending
  to be one. The row carries menu-item padding and type with no hover wash,
  and marks itself `role="none"` so it opts out of the surrounding
  `role="menu"` and whatever you put inside keeps its own semantics. The
  new "The account panel" example on the user menu shows the whole thing:
  orgs with avatars, keyboard hints, a colour-scheme switch inline.- **`user_dropdown_menu` has a sidebar presentation.** The component only
  ever rendered the compact navbar trigger - avatar plus chevron - so
  anyone building the app-shell sidebar it is named after had to hand-roll
  the rest of the row beside it: a name span, an email span, the truncation,
  the hover wash. `variant="sidebar"` renders that row itself. Avatar, name
  over email in muted text, `hero-chevron-up-down` on the right (up-down
  because from the bottom of a sidebar the panel really can go either way),
  the house hover wash and the `--pc-radius` corner. Both text lines
  truncate. The new `current_user_email` is optional, and without it the row
  is a single line. It all still rides the same `<button>` the dropdown
  already owned, so `placement` and the upward flip work exactly as before:
  `variant="sidebar"` with `placement="right"` at the bottom of a left-hand
  sidebar opens up and to the right. `variant` defaults to `"icon"`, which
  renders byte for byte what it always did.
- **`progress_ring` draws determinate progress as a circle.** Every other
  library in this space ships one and we didn't, so a quota meter in a
  table cell had to be a bar squeezed into a column where five stacked
  bars read as a barcode. It lives in `PetalComponents.Progress` next to
  the bar and takes the same `value`, `max`, `size` (xs to xl, 16px up to
  96px) and `color` attrs, so the two shapes agree wherever a page uses
  both. Server-rendered SVG, no JavaScript: a track circle plus an arc
  drawn with `stroke-dasharray`, starting at 12 o'clock with round caps,
  and the value change animates unless the reader asked for less motion.
  The arc is `currentColor`, so a `text-*` class recolours it the way it
  does a sparkline. `show_value` puts the percentage in the middle at lg
  and xl, the two sizes with a hole big enough to read a number in; below
  that it draws nothing and the readout goes beside the ring, which the
  showcase demonstrates. Pass a slot and the middle takes a count or an
  icon instead, at any size. Same ARIA contract as the bar, down to
  `aria-valuetext`.
- **`user_dropdown_menu` takes a `placement`.** It always rendered its
  dropdown at the default `"left"` placement (panel hangs leftward, right
  edges aligned), which is exactly wrong for the component's most common
  home: an avatar at the bottom-left of a sidebar, where the menu must grow
  rightward into the viewport. `placement` now passes straight through to
  the dropdown, and together with the viewport flip that means a
  sidebar-bottom user menu opens up and to the right instead of off-screen.

#### Changed

- **The slide over's footer joins the band.** Visible change: the footer
  used to be a bare `gray-100` hairline with nothing behind it, which was
  the treatment before the house settled on what a component-owned footer
  looks like. It now wears the same pair the table's tfoot and the new
  modal footer wear - `border-gray-200` with a `bg-gray-50` wash in light,
  the `gray-400` alphas in dark - so the strip reads as the same part in
  whichever component it turns up in, and a re-themed gray dial carries
  all three together. Nothing moved: the padding, the alignment and the
  slot are what they were. The band is simply darker and no longer
  transparent, which is most noticeable on a sheet whose body scrolls
  under it, where the wash is what tells you the row is pinned rather than
  the last thing in the list. If you were leaning on the old flat look,
  the band is one rule - override `.pc-slideover__footer` in your own
  stylesheet.

- **The stepper learns the timeline's visual language - except where a
  wizard has to disagree.** The active step is now ringed with the
  timeline's currentColor halo instead of a thick outline, unreached
  steps go hollow (gray ring, no fill, muted glyph), the connector takes
  the house hairline pair, and the component reserves its own halo
  headroom so a scrolling wrapper can't clip it. Completed steps stay
  SOLID primary discs - a restyle pass tried the timeline's quiet chip
  wash there and the eye-test caught why it can't transfer: in a
  timeline "complete" is the resting record, in a stepper it is the
  payload, and done-vs-not-done has to separate at a glance. Two latent
  bugs fixed on the way: `.pc-stepper__title` was declared twice with
  the second quietly winning, and the labels-bottom line's dark colour
  sat on a `::before` where `dark:` variants silently never match.

- **A horizontal stepper stays horizontal - behaviour change.** Below
  `md` it used to flip itself into a vertical stack. Orientation is now
  a contract: `horizontal` holds at every width and the rail compresses
  instead - descriptions hide below `md`, and below `sm` every title but
  the active step's hides too, so the circles carry the count, the
  active label carries the context, and each step's `aria-label` keeps
  its name for assistive tech. This is how the leading systems treat a
  mobile wizard (a compact band above the form, never a component that
  reshapes the page at a breakpoint the consumer didn't choose - and
  never one that surprises an agent that asked for a horizontal wizard).
  If you relied on the flip, render `orientation="vertical"` under a
  breakpoint yourself - that keeps the choice in your hands.

- **`badge` never wraps.** Behaviour change: a plain badge used to wrap a
  long label onto a second line, while a `with_icon` badge did not, so the
  same string in the same column laid out two different ways depending on
  whether an icon happened to be there. A badge is a label - two lines of
  10px semibold inside a pill reads as a rendering bug - so
  `whitespace-nowrap` moved onto the base `.pc-badge` rule and came off
  `--with-icon`, where it would only have said the same thing twice. Every
  badge answers the question identically. A label too long for its column now
  overflows instead of wrapping, which is the container's problem to fix
  the way it fixes it for anything else: a `min-w-0` track, a `truncate`,
  or a shorter label. If you were relying on the old wrapping, put
  `class="whitespace-normal"` on the badge.

#### Fixed

- **A LiveView patch no longer closes an open command palette.** The
  server never renders `open` on the dialog - `showModal()` sets it
  client-side - so any patch that re-rendered the dialog's subtree (a
  reconnect's join morph after a deploy or a network blip, live assigns
  feeding the items) merged the attribute away: the palette vanished
  with no `close` event, and the body scroll lock it owns leaked
  forever - a page that cannot scroll, with nothing on screen to
  explain why. The `PetalCommandDialog` hook now records the
  client-owned state in `beforeUpdate` and restores it in `updated`:
  the dialog re-opens in the same task (the `open` remove-and-re-add
  never reaches a style recalc, so the entrance animation does not
  replay), and focus lands back where the user left it, so a half-typed
  query keeps its cursor.

- **`<.progress />` with no `value` no longer raises.** `value` has always
  defaulted to `nil` and the percentage maths divided by it anyway, so the
  documented default blew up with an arithmetic error. It now renders an
  empty bar and leaves `aria-valuenow` off, which is how ARIA spells
  "indeterminate".

- **The dropdown family flips its panel upward when the viewport leaves
  no room below.** The canonical break was the user menu every app shell
  ends up with: an avatar pinned to the bottom of a sidebar dropped its
  menu clean off the bottom of the screen, with nothing to scroll to and
  no way to reach Sign out. The panel opened downward unconditionally
  because nothing measured it - the dropdown is LiveView.JS and CSS with
  no JS in the open path at all. A new `PetalDropdown` hook rides the
  panel (it already carries the id `JS.toggle` targets) and marks
  `data-flip` when there is no room below and more above, which is the
  same rule and the same attribute the combobox has used since 4.10;
  both now call one shared `flipDecision`, so the rule can't drift
  between them. The transform origin swaps with the flip, so a flipped
  panel still scales out of the trigger rather than unfolding away from
  it, and the side is re-measured on scroll and resize while the menu is
  open. Applies to everything built on `dropdown`: `user_dropdown_menu`,
  `language_select` and the `color_scheme_switch` dropdown variant.
  Register the bundled hooks (see the README) to get it - without them
  the panel keeps its previous always-downward behaviour.

- **`command_dialog` now locks background scroll while the palette is
  open.** A native modal `<dialog>` hands you the top layer, the focus
  trap and Escape, but it does not stop the page underneath from
  scrolling, so a trackpad flick while the palette was up slid the whole
  page behind it. The hook adds the same `overflow-hidden` body class
  `modal` and `slide_over` already use, so the treatment is one thing
  across the library. The release hangs off the dialog's native `close`
  event rather than each call site, because that is the single funnel
  every close path drains through: the hook's own close, a backdrop
  click, an item running, and Escape, including the case where the
  browser's close watcher fires `close` with no cancel to intercept. A
  patch that removes an open dialog fires no close event at all, so
  `destroyed()` releases it too, guarded on `open` so tearing down a
  closed palette cannot strip a lock another overlay owns.

### 4.14.0 - 2026-08-11

#### Added

- **New `border_plasma` effect: a glowing border that breathes in place,
  or sweeps a conic gradient around the ring.** `border_beam` sends one
  travelling light around the edge, which reads as motion crossing the
  screen. Plasma lights the whole ring instead, so it pulls the eye
  without dragging it - the treatment you want on a pricing card or a
  hero CTA that sits next to body copy. `mode="pulse"` is the default
  breath; `mode="rotate"` spins a conic arc for something busier. Three
  `intensity` steps (subtle, medium, strong) set how hard the ring burns
  and how far the bloom carries, and `spread` overrides the bloom
  distance on its own. Unlike the rest of the effects family, the
  default colours come off the theme rail (`--color-primary-500` and
  `--color-secondary-500`) rather than hard-coded hexes, so a plasma
  picks up a consumer's brand without being told - `color_from` and
  `color_to` still take literals when you want them. Pure CSS: a
  registered `--pc-plasma-angle` drives the sweep and a registered
  `--pc-plasma-t` drives the breath, both masked to the border ring with
  the padding-box trick. No hook, nothing to wire up. Reduced motion is
  handled by never starting the animation rather than hiding the effect,
  and the breath rests at full brightness, so those users get a static
  lit ring instead of a dead border.

### 4.13.0 - 2026-08-11

#### Fixed

- **Radio cards no longer inflate into pills at `radius="full"`.** The
  card surface (`.pc-radio-card__fake-input`) joins the tall-element
  clamp (1rem ceiling) the other multi-line controls already use. The
  4.10.0 sweep capped the six controls that grow past one line but
  missed this one - a radio card does too the moment it carries a
  description, and at the full stop the resulting ellipse crowded the
  `end` and `corner` indicator dots. Every stop below full is
  unchanged.
- **`combo_box` has an accessible name, and `<.field type="combobox">`
  no longer warns at compile time.** The role=combobox input carried no
  label mechanism at all - `{@rest}` lands on the wrapper, so
  `aria-label` named a roleless div and the placeholder was the only
  name a screen reader had. There is a `label` attr now, rendered onto
  the element that carries the role, and `<.field>` points its `for=` at
  the control that actually renders (the input, or the trigger button)
  and passes the label down. Separately, `combobox` was never added to
  field's declared `:type` values, so every call site warned - fatal in
  projects building with `--warnings-as-errors`.
- **A `required` combo_box no longer deadlocks the form.** `required`
  sits on the hidden select, which is `inert` and `sr-only` - so the
  browser could neither draw its validation bubble nor move focus to it,
  and submit was blocked with nothing visible, nothing announced, and
  focus on `<body>`. The hook takes the report over: the browser's own
  message goes into a `role="alert"` region on the control,
  `aria-required` and `aria-invalid` reach the a11y tree, and focus
  lands somewhere the user can act.
- **`max_items` is a real stop instead of a visual one.** The cap was
  enforced in CSS alone, so the keyboard still walked onto capped
  options, `aria-activedescendant` still pointed at them, and Enter was
  refused in silence. Capped options are `aria-disabled` now, the
  keyboard skips them, the cap is announced, and the placeholder says
  the same thing on screen as in the live region rather than being
  blanked to transparent.
- **A disabled combo_box no longer ships a working clear button.** The
  input variant's clear stayed focusable and clickable, and because a
  disabled select posts nothing, clearing it desynced client from
  server.
- **Backspace removes the chip you can see.** It read the hidden
  select's DOM order while chips render in pick order, so picking out of
  option order made Backspace delete a chip from the middle of the row.
- **The trigger variant's clear leaves a coherent state.** It used to
  leave the panel open with focus parked on the trigger - outside the
  panel - so arrows and typing were dead and Escape leaked to the
  enclosing modal instead of closing the panel. It closes the panel and
  returns focus to the trigger.
- **`combo_box` group headings reach assistive tech**, the empty row
  moved out of `role="listbox"` (which may only contain options and
  groups), a stranded pointerdown no longer disarms outside-tap
  dismissal for the rest of an open session, `updated()` re-reads
  `multiple` / the chips container / the clear button so
  `clearable={@editing}` behaves like the server state it is,
  `destroyed()` no longer throws on half-mounted markup, and a focusable
  control in a `:header` / `:footer` slot can take a pointer press.
- **The carousel honours `prefers-reduced-motion` when sliding.** The
  hook always requested `scrollTo({behavior: "smooth"})`, and the
  stylesheet's reduced-motion override targeted a `smooth-scroll` class
  nothing ever applies - an explicit scrollTo behavior beats the CSS
  property anyway, so the animation never turned off. Every slide
  scroll (`goto()` and the two loop-wrap paths) now funnels through one
  `scrollSlidesTo()` that checks the media query and jumps instantly,
  the same path the loop teleports already use.
- **The radio group's empty message uses its own class.** The
  `options={[]}` branch emitted `pc-checkbox-group--empty-message`
  (copy-pasted from the checkbox group), leaving
  `pc-radio-group--empty-message` in the stylesheet matching nothing.
  The radio-card group's empty message also picks up the same `text-sm`
  styling as its siblings - it previously had no rule at all.
- **Four more dead selectors swept out of `default.css`**, found by the
  same audit that resolved #582: `.select-wrapper select` (its markup
  was renamed to `pc-time-select`/`pc-datetime-select`/`pc-date-select`
  in early 2023), the two carousel `.smooth-scroll` rules above,
  `.pc-pagination__item--current` (pagination emits `--is-current`),
  and `.pc-carousel__icon`. None ever matched rendered markup, so
  nothing changes visually.
- **The radio-card "checked" rules that tripped strict CSS parsers are
  gone.** Three selectors in `default.css` escaped their colons with
  `\\:` instead of `\:`, so Tailwind v4's `--minify` optimizer
  (Lightning CSS) warned "not recognized as a valid pseudo-class" four
  times on every consumer asset build. They were also dead selectors:
  nothing the field component renders carries those literal
  `peer-checked:*` class names - the checked state has lived on
  `.pc-radio-card__input:checked ~ .pc-radio-card__fake-input` since
  the card got its fake-input anatomy. Deleted, and a guard test now
  fails the suite if a Tailwind utility name ever leaks into a shipped
  selector again. (#582)
- **Decimal columns now filter and sort.** `%Decimal{}` - what every
  Ecto money column holds - was readable by no operator (every filter
  silently matched zero rows) and sorted by struct internals, so
  -10.00 ordered as the largest value. Found by the differential gate:
  the same `State` run through the in-memory engine and through a
  Flop/Postgres bridge over identical rows, where 31 of 39
  disagreements traced to this one defect. Decimals now compare
  numerically everywhere - equality, comparators, `:between`, sorting -
  and read as text for `:in` and the pattern ops, like every scalar.
- **`:between` now works on any ordered column.** It was guarded to
  numbers, so a date range - the most common data-table filter there
  is - matched nothing while `:gte`/`:lte` on the same column worked.
  It is now defined as `:gte` AND `:lte`, one ladder, so ranges behave
  identically to the comparators they decompose into.
- **`:in` and the pattern operators work on date and Decimal columns**
  via their text form - a select filter on a date column used to match
  nothing at all.
- **Default quick-search fields survive Ecto structs.** The sweep used
  `for {k, v} <- row`, which raises on structs - exactly the rows a
  database engine produces.
- **A JSON-null filter value is dropped** for value-carrying operators
  instead of quietly reading as `""` and matching empty-string rows.

- **`sticky_header` never worked.** `.pc-table--basic` and `--ghost`
  used `overflow: hidden`, which makes the table a scroll container and
  traps `position: sticky` - so the header scrolled away in every
  configuration. They now use `overflow: clip`, which clips identically
  (rounded corners intact) without creating a scrollport.
- **`column_toggle` on its own rendered a dead button.** The Columns
  trigger is driven by the `PetalDataTable` hook, but `column_toggle`
  was missing from the condition that mounts it, so a table using only
  column visibility rendered a button that did nothing.

#### Added

- **Two more pinned contract rules**, both cross-engine findings:
  date operators are defined only for date-typed cells (a text column
  holding an ISO string does not match - no SQL engine would cast
  every row to find out), and an empty `order_by` or a tie within one
  has no defined cross-engine row order - append a unique tiebreaker
  for stable paging.

- **Column reordering (`reorderable`).** Move up/down controls in the
  Columns menu, riding the `on_ui` event as a `move_column` op carrying
  a `field` + `dir` delta, applied server-side via the new
  `DataTable.move_column/4` helper - one line in the handler, and
  race-free by construction: a computed destination would be a snapshot
  of the DOM the user saw, so two rapid moves would both start from it
  and the second would silently undo the first. `column_order`
  is presentation state like `hidden_columns` (never in URLs; stale
  saved orders with unknown fields are ignored, not crashed on), and
  the table, the menu and the filter buttons all follow it together.
  Buttons rather than drag by design: the op grammar is the contract,
  so drag can layer on later as a pure enhancement pushing the same op.
  When a move disables the button that was pressed (the column reached
  an edge), keyboard focus falls to its enabled sibling instead of
  dying.

- **The case-sensitivity of text equality is now a written contract,
  decided with evidence rather than inherited.** `:eq` (with `:neq`,
  `:in`, `:not_in`) folds case - a person picking "is" in a filter
  means "this value", not "these bytes". This matches every major grid
  (TanStack, AG Grid and MUI all default text-equals to
  case-insensitive), and the case-sensitive camp's own behaviour:
  Airtable's help tells users to switch to "contains", and Django's
  admin overrides its own case-sensitive ORM with `iexact`. Accents
  are NOT folded, and the pin says so. If byte-exact equality is ever
  needed it will arrive as a new operator (`:eq_sensitive`), never as
  a change to this one. `State`'s moduledoc gains a "Writing an
  adapter" section with the measured index guidance - including that
  on `citext` columns plain `=` must be used, since wrapping it in
  `lower()` defeats the index (~28x, measured).

- **The range summary is now a live region.** Filtering 74 rows down to
  3 previously announced nothing. It speaks a written-out sentence
  ("26 to 50 of 74 results") separate from the visible text, because
  the visible en dash is frequently read as nothing at all, and because
  the visible string is empty in the zero case - the one that matters
  most. Localizable via `results_label`.
- **`data_table` gains `row_label`** for naming rows in the selection
  checkbox's accessible name, and `actions_label` for the actions
  column's announced-but-unseen header.
- **`pagination` gains `aria_label`** to name its navigation landmark.

- **`data_table` gains `max_height`**, which caps the body and makes it
  scroll under a pinned header. This is what `sticky_header` needs
  inside a data table: the capped region becomes the scrollport the
  header sticks to, because a wrapper that scrolls only sideways cannot
  pin anything - a CSS constraint rather than something a property can
  undo.

- **Comparators now work on every column type.** `:neq` was guarded on
  numbers, so "is not" against any text column matched nothing - and
  matched nothing *silently*, since an unhandled combination falls
  through to a catch-all rather than raising. `:eq`, `:lt` and `:gt`
  had the same hole for dates. Every comparator now tries numbers, then
  dates, then text, so an operator means the same thing whatever the
  column holds.
- **A filter operator without a label no longer crashes the render.**
  Two `Map.fetch!` lookups raised a `KeyError` while drawing the
  toolbar; unlabelled (for example adapter-specific) ops now render
  humanised.

- **A drag on the page no longer dismisses an open `data_table` menu.**
  Dismissal was firing on pointer*down* outside, so the ordinary way
  anyone scrolls a phone - press the page and drag - killed the menu
  before it moved. It now takes a *tap*: press and release must both
  land outside, within a small movement slop, and a gesture the browser
  hands to the scroller (which cancels rather than releases) leaves the
  menu alone. This mirrors the native popover's own light-dismiss.
- **`data_table` filter and column menus live in the page, not the
  browser's top layer.** A top-layer panel is positioned against the
  viewport while its trigger sits in the page, so JavaScript had to
  re-sync them on every scroll event - and JS runs after the frame is
  already painted (iOS often doesn't repaint fixed content at all
  during a momentum flick, then snaps it). No amount of throttling
  fixes that. The panels are now absolutely positioned next to their
  triggers, so the browser moves both together at compositor speed:
  there are no scroll listeners left, and nothing to drift. Geometry
  (flip above, slide sideways into view, cap height) runs once on open
  and on resize. The `PetalDataTable` hook owns open state, so a menu
  survives the patches that a filter or column toggle triggers.
  `<.popover top_layer>` is unchanged and remains the tool for panels
  that must escape a clipping container.
- **Top-layer popovers stay anchored to their trigger.** They were
  clamped into the viewport on *both* axes, so a panel with no room
  below was shunted up until it detached from its trigger - pinned to
  the top of the screen, over the header, over the button that opened
  it. Clamping now applies to the cross axis only (keeping a panel on
  screen sideways never detaches it); the main axis is handled by
  flipping sides, and a panel with more content than room is capped
  with `max-height` and scrolls. A panel whose trigger scrolls out of
  view hides with it rather than stranding itself against an edge.
- **Repositioning is throttled to one pass per animation frame**, so
  a panel tracks a scrolling page smoothly instead of juddering
  behind a burst of scroll events, and writes whole-pixel offsets.
- **An unpositioned top-layer panel centres instead of landing in the
  corner.** A native `popovertarget` works from first paint, so a fast
  tap can open a panel before the hook mounts; it now reads as a
  centred sheet, and the hook anchors it as soon as it mounts.
- **Top-layer popovers follow the visual viewport.** Opening a mobile
  keyboard shrinks and offsets the visual viewport without firing
  window `scroll` or `resize`, so a panel anchored on layout-viewport
  numbers was left behind - off-screen while typing, then adrift on
  the next scroll. `PetalPopover` now subscribes to `visualViewport`
  events and measures space and clamps against that box, so an open
  editor stays put and stays visible above the keyboard.
- **Fields with an explicit height no longer sit their text low.** The
  data table's search input and filter operator/value controls set
  `h-9` while inheriting the base `py-2`; at 16px (coarse pointers)
  the line box overflowed the content box and pushed the text down.
  They now zero the vertical padding, like the per-page select
  already did.
- **Top-layer popovers no longer flash at the top-left corner.** The
  panel's `margin: 0` (which defeats the browser's centring) meant an
  unpositioned panel sat at 0,0, and `toggle` fires late enough for a
  frame to paint there. `PetalPopover` now gates opacity in
  `beforetoggle` - which runs synchronously *before* the panel is
  shown - so the first painted frame is already the positioned one.
- **Top-layer popovers survive LiveView patches.** A patch merges
  server attributes onto the panel, dropping the inline `top`/`left`
  the hook owns and snapping an open panel to 0,0 (hit by the data
  table's Columns dropdown, where every toggle patches). The hook now
  re-asserts position in `updated()`, tracking open state on the hook
  instance rather than a DOM attribute the same merge would strip.
- **`data_table` filter controls no longer trigger iOS zoom.** Safari
  zooms the viewport when a focused field's text is under 16px, which
  scrolled popover editors out of view. The search input, filter
  operator selects, filter values and the per-page select scale to
  16px on coarse pointers, keeping their `h-9` box.
- **`::backdrop` is transparent for top-layer panels**, so no UA can
  paint a dimming layer behind an anchored popover.
- **Five operators the vocabulary was missing**: `:not_contains`,
  `:gte`, `:lte`, `:not_in`, and the null-ness pair `:is_empty` /
  `:is_not_empty`. Measured against Flop, Ash, Ecto, TanStack, AG Grid,
  MUI and the filter menus of Notion and Airtable, these were the
  near-universal ones we lacked. Value-less operators hide their value
  input (CSS `:has()`, no JS) and are understood by both wiring modes.
- **`State.ops/0` and `State.valueless_op?/1`**, so an adapter can
  enumerate the contract rather than hardcode it.
- **Operator semantics are now pinned in writing** - `:between` is
  inclusive, `:is_empty` matches nil/`""`/`[]`, text comparison is
  case-insensitive - because "obvious" differs per query library.

- **`<.data_table>` - the component core (4.12 data table, milestone 1).**
  Composed around `<.table>`, driven entirely by `DataTable.State`:
  `:col` slots (field, label, sortable, align), sortable headers with
  aria-sort in BOTH wiring modes - link mode patches per-column URLs
  built via `State.to_params` (shareable state, working back button),
  event mode pushes one op-grammar event (`sort`/`page`/
  `clear_filters`) - a range-summary footer with pagination that
  auto-picks numbered (total known) or simple (cursor mode), loading
  skeleton rows, a filters-aware empty state with the clear-filters
  way out, `:action`/`:toolbar`/`:empty` slots, and density/striped/
  sticky pass-through. Toolbar search + filter editors arrive next
  milestone (the combobox trigger listbox was built for them).
- **`<.data_table>` quick search + rows-per-page (4.12 data table,
  milestone 2, part 1).** `searchable` renders a debounced toolbar
  search input driving the new `State.search` term (trimmed, blank
  drops the param, always resets to page 1); `Engine.List` sweeps it
  case-insensitively across string fields (scope with the new
  `:search_fields` option) before filters so totals stay honest.
  `page_size_options` renders a rows-per-page footer select
  (`State.put_page_size/2`). A "Reset filters" ghost button appears
  in the toolbar while filters are active. Event mode posts new
  `search`/`page_size` ops through plain forms; link mode wires both
  through the new `PetalDataTable` hook, which fills in URL templates
  and clicks a hidden patch link so navigation stays LiveView's own.
- **`<.data_table>` column filters (4.12 data table, milestone 2,
  part 2).** `:col` gains `filterable` ("text" | "number" | "select" |
  "date") and `options`; each filterable column renders a toolbar
  filter button that opens a popover editor typed per column -
  operator select + value for text/number/date (`between` reveals its
  second bound via `:has()`, no JS), a checkbox list posting `:in`
  for select. Active buttons read their predicate ("Email contains d",
  "Amount between 300\u2013320", "+N" overflow for long picks) with an
  inline clear. `State.handle_op/3` speaks the entire event grammar
  (sort/page/search/page_size/filter/clear_filters, whitelisted
  fields, no atom creation) so an event-mode handler is one call;
  link mode extends the `PetalDataTable` hook with a `:filters`
  placeholder mirrored from a JSON stamp, and filter URLs now carry
  list/range values as Phoenix-style indexed params. Operator names
  localize via `filter_op_labels`.
- **`<.data_table>` row selection (4.12 data table, milestone 3a).**
  `selectable` renders a leading checkbox column keyed by `row_id`
  (field atom or function); the header checkbox is tri-state (the
  `PetalDataTable` hook mirrors an indeterminate stamp onto the DOM
  property). While rows are selected the toolbar morphs into
  "N selected" + the new `:bulk_action` slot (`:let` receives the
  ids) + a clear button. Selection is UI state, not query state: it
  rides an event in BOTH wiring modes (`on_ui`, defaulting to
  `on_change`) with three ops - `select` (id), `select_all`,
  `clear_selection` - and never touches URLs. `table`'s `:col` label
  now accepts any rendered fragment, which is how the header checkbox
  rides in.
- **`<.data_table>` columns-visibility dropdown (4.12 data table,
  milestone 3b).** `column_toggle` renders a toolbar Columns dropdown
  (top-layer popover, stays open for multi-toggling); `hidden_columns`
  is presentation state riding the `on_ui` event as
  `%{"op" => "toggle_column", "field" => f}` - never in URLs. The
  last visible column's checkbox disables (a table needs one), and
  filter buttons stay independent of visibility (filtering is not
  display).
- **Data table showcase + rules (4.12 data table, milestone 4).**
  Three new registry examples - the full toolbar (search + typed
  filters + per-page), row selection with the morphing toolbar, and
  columns visibility - powering the playground page and the upcoming
  petal.build docs. `rules.md` gains the data table pattern (the
  two-call event-mode backend, UI-state-vs-URL-state doctrine) for AI
  assistants.
- **`data_table` filter popovers are viewport-aware**: the editors now
  ride the popover's top-layer mode, so `PetalPopover` flips and clamps
  them inside the viewport - a filter button at the screen edge no
  longer opens its editor off-screen (mobile). The `PetalDataTable`
  hook closes them through the native popover API after an Apply, in
  both wiring modes.
- **`data_table` never widens its container**: the root carries
  `min-w-0 max-w-full` so flex/grid parents can't size it to the
  table's min-content; footer children shrink and wrap. Wide tables
  scroll inside `pc-data-table__scroll`, never the page.
- **`table` `on_sort` accepts a 1-arity function** of the sort key -
  per-column events/JS, how the data table patches sort URLs.
- **`pagination` event mode grows up**: `event` accepts a custom event
  name (string) and `event_values` adds phx-value-* pairs - page
  clicks can speak any consumer's event grammar.

### 4.12.0 - 2026-08-08

#### Added

- **`combo_box` M4 - field citizenship and sizes.**
  `<.field type="combobox">` brings the full field grammar - label,
  changeset errors (with the wrapper error ring on the control and
  trigger), `help_text`, required - and forwards every combobox attr;
  `combo_variant` selects the anatomy (`:variant` belongs to
  radio-card), the field size family maps onto the new combobox
  `size` attr (`sm`/`md`/`lg`; `xs`/`xl` clamp), and `clearable`
  passes through. Multiple gets the empty hidden input so forms post
  cleanly. Rich slots (`:option`, `:selected`, `:chip`,
  `:header`/`:footer`) stay on the bare component by design.

- **`combo_box` M3b - the modes: `free_text`, `create`, remote search.**
  The last of the Tom Select parity surface, on the new architecture:
  - `free_text`: Enter at the empty stop commits the typed text as a
    dynamic option in the hidden select, so forms post it like any
    choice. Existing labels are chosen instead of duplicated
    (case-insensitive). The server owns persistence.
  - `create`: free_text plus an explicit, keyboard-reachable
    "Create …" row (the last arrow stop) that appears for novel
    queries. `create_label` localizes the verb.
  - `remote_options_event_name` + `remote_options_target`: the
    contract preserved verbatim - typing pushes the raw term
    (debounced 300ms), the handler replies
    `{:reply, %{results: [%{text: …, value: …}]}, socket}`, and the
    hook renders the results (the listbox is hook-owned in remote
    mode - one writer per region). Designed loading row
    (`loading_label`), stale replies dropped by sequence, chosen
    results inserted into the select.

- **`combo_box` M3a - the slot family completes: `:header`, `:footer`,
  `:selected`, `:chip`.** All four speak the `:option` slot's grammar
  (`:let` receives normalized options with `meta`), all render-only, no
  new hook state machines. `:header`/`:footer` are panel chrome OUTSIDE
  the listbox - captions, counts, manage links - keyboard navigation
  and filtering never touch them. `:selected` renders rich closed-state
  content in the trigger (colored label dots with a "+N" overflow is
  pure composition, not an attr); `:chip` renders rich chips with the
  remove button intact. Both closed-state slots reconcile by
  server-wins-on-patch: client picks show plain optimistic text, the
  LiveView patch swaps the rich content back in, and fresh
  server-rendered DOM is left untouched whenever it already matches
  the selection (value-stamped diffing on the label and per-chip
  `data-value`).

- **`DataTable.State` + the in-memory engine - the 4.12 data table
  foundation.** `PetalComponents.DataTable.State` is the whole backend
  contract in one struct (multi-sort `order_by`, typed `filters`, page,
  page_size, total) with `from_params/2` / `to_params/2` for URL-as-state
  round-trips (whitelisted fields, no atom creation from user input,
  clamped sizes) plus the interaction helpers (`toggle_sort/2` cycling
  asc→desc→off, `put_filter/4`, `clear_filters/1`, `total_pages/1`).
  `Engine.List.run/2` sorts, filters and paginates a plain list against
  that state - case-insensitive strings, nils always last, numeric and
  date coercion from string params - so registry examples and the
  playground get a working table with zero setup. The `<.data_table>`
  component builds on this next.

- **`combo_box` trigger variant supports `clearable`.** A chosen
  single-select trigger had no road back to the empty state (Nic's
  find - the input variant had the X, the trigger silently ignored the
  attr). A button can't nest inside the trigger button, so the clear is
  a sibling positioned over the trigger's right rail before the chevron
  (Base UI anatomy), gated by the same `data-has-value` state, with a
  24px hit target. Clearing empties the select, restores the
  placeholder label, keeps the panel closed and returns focus to the
  trigger. Multiple mode stays clear-less by design on both variants -
  chips and panel toggles are its road back.

- **`combo_box` `:option` slot - rich options.** Render anything inside
  each panel option (avatars, flags, secondary text); `:let` receives
  the normalized option - `label`, `value`, `disabled`, and `meta`
  carrying whatever extra data the option tuple's keyword list held
  (`{"Amelia", "am", role: "Engineering"}`). Filtering, chips and the
  trigger label keep using the plain label, so rich content never
  affects search or the closed state.
- **`combo_box` `variant="trigger"` - the picker anatomy.** A select-like
  button shows the chosen value (or "N selected" with `multiple` -
  `count_label` localizes the word) and the search input lives inside
  the panel, command-palette style. Open from the button, arrow keys or
  click; search; choose - single select closes and returns focus to the
  button, multiple stays open and the count label tracks live. Same
  hidden select underneath, same form behavior, same positioning
  (flip + space cap). This is the anatomy pickers use - and the exact
  shape the 4.12 data table's filter editors are built from.

- **`combo_box` grows up: `multiple` with chips, `clearable`, and the
  hardening pass** (combobox M2 core). `multiple` turns the trigger into
  a chip row - removable tokens, panel stays open while picking,
  Backspace in an empty input removes the last chip - backed by a real
  `<select multiple>` whose name gains `[]`, so every choice survives
  the form post like a native multiple select. `max_items` caps the
  count (at the cap, unchosen options rest until something is removed).
  `clearable` adds a real clear *button* - hit target, focus ring,
  aria-label - to single selects. Riders: the hidden select is `inert`
  (dialog autofocus can never land on it), `form.reset()` re-syncs the
  chrome, and a polite live region announces result counts as you
  filter. The native WebKit search-cancel X is suppressed on pc search
  inputs package-wide - the clear affordance is the house clearable
  pattern, never browser chrome. The hook's behavioral contract is now
  pinned by a committed vitest spec (the session harness, ported).

- **`combo_box` - the searchable select, milestone 1 of the combobox arc**
  (tasks/data-table-combobox-plan.md §6, Matt-approved). Type to filter,
  arrow keys to move, Enter to choose: the command palette's proven
  keyboard + scoring machinery (`PetalComboBox` forks `PetalCommand`)
  wired to a real hidden native `<select>`. The select IS the form
  control - name/value from a `field` or manual attrs, bubbling
  input/change on selection - so changesets, `phx-change` and LiveView
  form recovery behave exactly like a plain select. No
  `phx-update="ignore"` island, no Tom Select, zero JS dependencies.
  Options accept the `select` shapes: strings, `{label, value}`,
  `{label, value, disabled: true}` and `{group_label, options}` groups
  (headed in the listbox, `optgroup` in the select, hidden when filtered
  empty). ARIA done properly for a combobox: `aria-selected` marks the
  CHOSEN option (with the check mark); the keyboard highlight is virtual
  (`data-highlighted` + `aria-activedescendant`), focus never leaves the
  input. The control carries the field surface (input_group doctrine:
  ring on the wrapper, borderless inner input); the panel follows the
  dropdown grammar with the 1rem radius clamp. Single select, static
  options; multiple/chips, free-text autocomplete and the remote-search
  contract land in the next milestones.

- **`pagination` gains `variant="simple"`** - Previous/Next outline buttons
  with disabled boundary states, instead of the numbered page window. The
  right form when a list is short or a total is unreliable (cursor-style
  paging), and the footer grammar the upcoming `data_table` uses when
  `total` is unknown. `previous_label`/`next_label` attrs make the copy
  localizable; link and event modes work unchanged. The numbered layout is
  untouched and stays the default (`variant="numbered"`).

#### Changed

- **`combo_box` multiple: the placeholder stays visible with chips
  present** ("Add members…" style - the reui/Mantine TagsInput
  convention) instead of vanishing after the first pick, and it rests
  while `max_items` is reached (pure CSS on `data-max-reached` - the
  attribute itself stays server truth, so live placeholder changes
  always win). Single-select behavior unchanged.

#### Fixed

- **`combo_box`: iOS taps on control chrome and the trigger button
  reliably toggle the panel.** iOS Safari fires `focusout` with
  `relatedTarget: null` even when focus moves WITHIN the component, so
  a chevron or trigger tap closed the panel mid-press and the tap's own
  click instantly reopened it - an invisible flash that read as a dead
  chevron zone (input variant) and a picker that never closes (trigger
  variant). Device-log verified. The focusout close now defers one tick
  and verifies where focus actually landed instead of trusting
  `relatedTarget`; genuine Tab-away and click-away close exactly as
  before.

- **`combo_box`: a touch-scroll no longer dismisses the panel.** The
  outside dismiss closed on `pointerdown`, so starting a scroll gesture
  anywhere outside the panel killed it the instant the finger landed
  (Nic's iOS find). The dismiss is now a completed press - `pointerdown`
  arms it, `pointerup` in (roughly) the same spot closes; a scroll ends
  in `pointercancel` or a far-away release and leaves the panel open,
  matching shadcn/Base UI and the old Tom Select behavior. A clean tap
  outside still closes, and the desktop focusout path is unchanged.

- **`combo_box`: chevron press reliably toggles the panel closed on
  every platform.** Two interacting bugs: on desktop, pressing the
  (non-focusable) chevron blurred the input, focusout closed the panel
  mid-press, and the click then saw a closed panel and REOPENED it -
  the toggle flashed instead of closing. On iOS no blur fires, but tap-
  target correction rewrites the synthesized click's target and
  coordinates onto the nearby text field, so the tap read as caret work
  and nothing closed. Fix: chrome-vs-caret is decided at `pointerdown`
  (which hit-tests the real touch point and is never rewritten), the
  click consumes that record, and chrome presses are preventDefaulted
  so the input never blurs mid-press. Input presses keep caret
  behavior and never discard the active query.

- **`combo_box` multiple: the highlight stays on the item just picked.**
  Choosing used to reset the filter and re-home the highlight on the
  first option - a disorienting jump when picking from the middle of the
  list (Nic's on-device find). Now arrowing resumes from the item you
  just toggled (Base UI/downshift grammar); the trigger variant's
  multiple mode gets the same fix through the shared path.

### 4.11.3 - 2026-08-05

#### Fixed

- **Adjacent pressed toggle chips no longer merge into one block.** The solid variant's pressed chip drew its definition edge as an outward `ring-1` - a box-shadow with 1px spread, which paints outside the border box without taking layout. In a multi-select rail two neighbouring pressed chips each bled 1px into the rail's 2px gap, so the gap read as zero and the chips looked welded together (outline and accent set `ring-0` and never showed it). The ring is now inset: same edge, gap restored, and every variant separates its pressed chips identically.
- **The input_group composer toolbar uses square icon buttons.** Its three formatting buttons were `size="xs"` holding an icon, so they rendered as 38x30 pills while the same Bold button in the button_group and tooltip examples - `size="icon"` - is a 34x34 square. The example now uses the size built for the job. No component change: `size="icon"` and the full `icon_button` ladder (36 through 56, all square) were already there.

#### Changed

- **Every toggle group variant washes on hover, not just outline.** Solid and accent shifted text colour alone, which is a weak tell that a chip is clickable - and it meant one of three variants behaved differently from the other two for no reason anyone could name. The wash now lives on the base item so all three get it, translucent so it composites over whichever rail it sits on; outline keeps its own tuned step (its rail is transparent, the others sit on a wash). Pressed chips are untouched - their rules land later at equal specificity or higher, so pressed paint survives hover - and disabled items are explicitly excluded in both forms, including the radio form where `disabled` lives on the input and needs the `:has()` rule.
- **Custom scheme-switch icons centre instead of huddling top-left.** The scheme wrappers force slotted children to fill the box, which is right for masked hero spans but left text content - the emoji example - pinned to the top-left corner of a block box. The forced child is now a centring flex box: text and emoji slot content centres, masked icons render identically (the mask fills the box regardless of display type).
- **Icon-only toggle chips are squares, not pills.** The rail's per-size horizontal padding made icon-only items wider than tall (36x28 at md), while the scheme toggle - the component it sits next to in every toolbar - is a perfect square. Icon-only items now drop their horizontal padding to match the vertical (28x28 at md), keyed off the aria-label the icon-only contract already requires: it sits on the item itself in multiple mode and on the hidden radio in single mode, and items with visible text must not carry one (the slot attr doc now says so). The comment above the icon sizing rule always claimed "a square hit target" - now it's true of the chip, not just the icon.

### 4.11.2 - 2026-08-05

#### Fixed

- **Two icon-geometry sites the 4.11.1 sweep missed join the `!important` contract.** 4.11.1 restored the bangs at the sites the 4.11.0 audit had de-banged - but two rules were never in that audit because they never had bangs to begin with, and both lose the same cascade fight (consumer hero-* geometry from the utilities layer or unlayered): the toggle group's icon-only item sizing (on petal.build the pressed chip stretched to 24x20 and the rail read non-uniform, icon riding left) and the alert kind-glyph fill inside its 20px container. Both banged, both verified with the same compiled-CSS probe against unlayered consumer hero rules: 16x16 icons, uniform 36x28 chips.

### 4.11.1 - 2026-08-05

#### Fixed

- **The icon sizing contract gets its `!important` back - 4.11.0's de-bang broke icon geometry in every phx.new-style app.** 4.11.0 dropped `!important` from the nine icon-sizing sites on the belief that a consumer's heroicons plugin lands in the components layer, where the doubled selector's (0,2,0) wins on specificity. That premise is false in the two setups that matter: Tailwind v4 `@plugin` (what every phx.new app vendors, petal_pro included) emits hero-* rules into the *utilities* layer, which beats any components-layer rule regardless of specificity - so the plugin's `width: spacing.6; height: 1lh` won and avatars' placeholder silhouettes shrank off-centre while scheme-switch glyphs rode high in their boxes. And generated heroicon stylesheets often sit unlayered, which beats layered rules too. The doubled selectors stay (they carry flattened builds, where specificity does decide) and the geometry declarations are `!important` again, including the colour-scheme wrappers that had shipped bang-less since 4.9 and were quietly broken in layered builds the whole time. Verified by compiled-CSS geometry probes against a phx.new-style build: avatar placeholder back to filling its circle, scheme glyphs back to 20x20 centred. The honest cost is restored too and documented at the contract's canonical comment: these internal icons are fixed-size, and even a bang utility can't resize them.
- **Toggle group radios stay invisible mid round-trip.** The hidden radio that fills each toggle_group item was hidden by `opacity: 0` alone - but app CSS routinely forces opacity back up: phx.new's default `phx-click-loading` styling is a *utility* at opacity .5, and utilities beat the components layer. So with `@tailwindcss/forms` loaded, every server round-trip flashed the full-chip-size radio at half opacity - blue fill, white centre dot, focus ring - for the length of the round trip plus a 1s fade. The input now paints nothing even when visible: `appearance: none`, no background, no border, no box-shadow, all in the components layer where they beat the forms plugin's base-layer styling. Reproduced and verified against the compiled playground stylesheet with the loading class applied: 4.11.0 shows the dot, patched shows a normal pressed chip.

### 4.11.0 - 2026-08-05

#### Added

- **`hide_header` on `<.modal>` - headerless confirmation dialogs without an accessibility trade-off.** Confirmation-style modals (think "unsubscribed successfully") carry their heading centered in the content, but the component always rendered its header bar, so an empty strip sat above the content unless you hand-rolled CSS to hide it. `hide_header` now does it properly: the header collapses to a screen-reader-only box (sr-only, never `display: none`) because the dialog's `aria-labelledby` points at the title inside it - pass a real `title` and the dialog keeps its accessible name while showing none of the bar. It also skips the corner close button (an invisible button you can still tab to is a keyboard trap, not a feature), so give the content its own way out - escape and click-away still work by default. New "Headerless confirmation" example in the showcase registry.
- **`tailwind-gray.css` - stock Tailwind gray back in one import.** The `gray` role deliberately ships zinc values under the gray name, which also decides what an app's own `text-gray-*` utilities render as - and since the stock values only ever lived under that name, no `var()` can reach them once zinc holds it. This file restores them verbatim: import it after `default.css` and every gray in the app is Tailwind's original again. Any other neutral (slate, stone, neutral) never needed it - those remain live variables you can remap a role to in one line per stop.
- **The toggle group gets a live example.** Every toggle_group registry example rendered inert, so the docs pages read as screenshots. The new "Try it - this one is live" example is the exception on purpose: the single rail is native radios, so the browser moves the pressed chip with no JavaScript and no server, and the multiple rail toggles each chip client-side through `JS.toggle_attribute` on `on_change`. The description says out loud what a real app would do instead (send the event, let the server own the value).

#### Changed

- **The alert page leads with the semantic ramps in outline.** Same first example, same anchor, but the four alerts now carry `variant="outline"` - the coloured border and glyph on a calm surface reads better at first glance than four filled light bars. The description points out that dropping the variant gives you light, the component default, which is unchanged.

#### Fixed

- **A consumer `@theme` block placed before the petal_components import no longer loses silently.** The shipped colour ramps were a plain `@theme` - a hard declaration - so an app that defined its brand palette above the import (the natural place for it) got every ramp quietly replaced with our defaults, `primary` included, with nothing to say why. The ramps are now `@theme default`, the same soft-fallback convention Tailwind uses for its own palette: your `@theme` wins wherever it sits, and a fresh install with no overrides renders exactly as before. Verified against Tailwind 4.3.1's compiler in both orderings.
- **Component icons can be resized again - icon sizing drops `!important` for a real contract.** Nine icon-sizing sites (pagination and menu chevrons, accordion plus/minus, the avatar placeholder silhouette, the chat family's reasoning chevron, marker, action-bar and composer-send icons) defended their geometry with `!important`, on the belief that a consumer's heroicons plugin sizes `.hero-*` in the utilities layer. It doesn't: the plugin every phx.new app vendors registers icons through `matchComponents` - the same components layer as our rules, at single-class specificity - so the fight was always a coin flip on import order, and `!important` was both overkill and a lockout (important component declarations beat even a consumer's `w-6!`, so those icons were genuinely un-resizable). All nine now use the doubled-selector contract the colour-scheme controls proved out in 4.9.0: `(0,2,0)` outranks the plugin in either import order, and a plain `w-* h-*` utility on the icon overrides cleanly via the utilities layer. The carousel's slide-mode positioning also drops three `!important`s its own selector specificity already made redundant, and the two keepers now say why inline: the showcase `<pre>` background fights an inline style from mdex's `:html_inline` formatter (only `!important` outranks an inline style), and the reduced-motion `1ms` override is the standard accessibility pattern.
- **The rest of the bang utilities go too - the whole file is now `!important`-honest.** The legacy `has-error` form styling (label, span, text inputs, selects, textareas, the file-input rule) carried a pile of `!` suffixes it never needed: form.ex puts `has-error` on the same element as the pc class, so `input.has-error` at (0,1,1) outranks every single-class base rule, and its focus variants at (0,2,1) outrank the base focus-visible styling - specificity was always enough. Same story for the scheme dropdown's positioning overrides (`!w-auto !min-w-0 !left-1/2 !right-auto` refine base dropdown rules they already beat on source order) and the checkbox label's `mb-0!`. All de-banged with zero rendered change, each site commented with why no bang is needed - and consumer CSS can now override every one of them the normal way. The audit also unearthed one rule that was never alive: `input[type="file_input"].has-error` targeted a type attribute nothing renders (`Form.file_input` has always emitted `type="file"`), so it's removed outright - which also means error-state file inputs have never had danger styling; giving them some for real is a separate design decision.

### 4.10.1 - 2026-08-04

#### Fixed

- **Showcase frames no longer trap overlay examples under the host page's chrome.** `.pc-showcase__preview` carried a `z-10`, and a z-index on a positioned element creates a stacking context - so the modal and slide-over examples embedded on docs pages had their `fixed z-50` overlays flattened to an effective z-10 against the page. On petal.build, the docs sidebar (`fixed z-20`) and navbar painted over an open slide over, and the dark overlay skipped them. The `z-10` had no layering job (the preview and code panels are non-overlapping siblings; nothing in the stylesheet uses a negative z that relied on the context) so it's simply removed, and the rule now carries a comment explaining why it must never get one back. Raising the overlay's z-index could never have fixed this - a z-index only competes inside its own context. Verified in headless Chrome against the compiled stylesheet: with the trap, a z-20 sidebar wins even against an overlay forced to z-9999; without it, the overlay covers everything, and page content behaves identically. **Scope: docs surfaces only** (petal.build and the playground render showcase frames; consumer apps never do). The command palette was never affected - its native `<dialog>` lives in the browser's top layer, which no ancestor stacking context can trap. That immunity is the direction of travel for modal and slide over.
- **Opening a modal or slide over no longer nudges the layout around it.** The root element each renders (`.pc-modal`, `.pc-slide-over`) was an in-flow div - a 0x0 box, since its overlay and panel children are `fixed` - but in-flow means it becomes a real flex/grid item the moment JS reveals it. Inside any gapped or centered container that costs a `gap`: on the petal.build docs pages the trigger button jumped 8px left on open and back on close (the showcase preview is a centered flex row), and the same happens in any consumer toolbar or button row built the same way. Both roots are now `fixed`: out of flow, zero layout contribution, opening an overlay can never move its siblings. The overlay and panel were always viewport-fixed, so nothing about how modals and slide overs look or position changes - verified in headless Chrome against the compiled stylesheet (8px shift before, 0px after, panel and overlay placement identical). The one consumer-visible nuance: custom CSS that absolutely positioned something against the root's old `position: relative` would need its own positioning context now.

### 4.10.0 - 2026-08-04

#### Added

- Nine new registry examples across six thin modules - toast's remaining
  severities (warning, loading, neutral), carousel thumbnail navigation
  and a slides_per_view row, the avatar size ladder + presence dots and
  the avatar_group team stack, marquee's vertical feed, local_time's
  threshold flip, and the colour-scheme switch labelled in German plus
  custom icon slots. petal.build renders these registries directly, so
  the docs pages inherit every example in the same release.
- `language_select/1` graduates from Petal Pro: the locale dropdown, now
  a free composition of `dropdown/1`. Plain links carry `?locale=`
  (`&`-joined when the path already has a query - the Pro version broke
  there), the current language gets `aria-current` plus a check, and an
  unknown `current_locale` falls back gracefully instead of raising.
  Beyond the port: `variant="code"` / `variant="label"` put text on the
  trigger instead of a flag, options may omit `:flag` entirely - a flag
  is a country, not a language - and `show_chevron={false}` leaves the
  trigger standing alone.
- `social_button/1` graduates from Petal Pro - the very first Pro
  component (May 2022), now free and rebuilt on `pc-button` geometry so
  provider buttons follow the theme, sizes and radius like every other
  button. Nine providers (google, github, apple, x, facebook, microsoft,
  gitlab, discord, linkedin - the 2022 Twitter bird retires), outline
  default with coloured glyphs, solid brand paint, auto "Continue with"
  labels, and `icon_only` with the label as the accessible name.
- `brand_icon/1` - the nine provider glyphs as standalone inline SVGs,
  `currentColor` by default, `colored` for the official brand treatment
  (gitlab and discord vendored from simple-icons, CC0). Heroicons ships
  no logos; now the package does. The Card login example dogfoods the
  pair.
- **`command_trigger` - the visible opener for the ⌘K dialog.** The search pill every command-palette app puts in its header (magnifier, label, kbd hint) plus an icon-only variant for tight rows, so consumers stop hand-rolling it - marketing, the playground topbar and the docs example had three bespoke copies between them. Opens the `command_dialog` named in `dialog_id` through the new `PetalCommandTrigger` hook rather than a phx-click JS command, so it works on dead views too (hooks mount there since LiveView 1.1; JS commands do not run). The shortcut itself still lives on the dialog - the kbd chip is the visible hint, and `kbd={nil}` hides it.
- **The segmented family joins the button radius curve.** `color_scheme_switch`'s segmented variant and `toggle_group` now round at token x1.2 (rail) over x1 (chips) instead of the old pill-at-default x2.4/x2. Every radius-token step now produces a distinct, perceptible corner change - the old curve spent its whole range between 0 and the default and then saturated - and only `full` pills, exactly like buttons. One curve across the system; at the shipped default the rails read rounded rather than pill. Nested menu items complete the same doctrine: the scheme dropdown's options and the command palette's items now derive their radius from the clamped panel (the dropdown-item rule) instead of the raw token, so `full` can no longer pill an item inside a 16px panel - and the scheme dropdown adopts the dropdown's hover/selected wash ramp while it's there.
- **`toggle_group` - a segmented selection rail.** Where `button_group` groups actions, `toggle_group` holds a selection: one pressed option by default, any number with `multiple`. Server-driven and stateless the LiveView way - pass `value`, handle `on_change` (the pressed option arrives in `phx-value-toggle`), no hook, no client state. Single select renders native radios (the scheme-switch segmented mechanics): real radiogroup semantics, one tab stop, arrow keys move the selection. Multiple renders `aria-pressed` toggle buttons. Three variants - `solid` (wash rail, neutral chip), `outline` (bordered toolbar rail on the outline-button ramp) and `accent` (the selection painted in the brand colour) - three sizes on the scheme-segmented radii math, per-item or whole-rail `disabled`, items take any content. The radios detach from surrounding forms, so a rail inside a `<.form>` never posts a stray param. Ships with registry examples (including the device rail) and a playground page with live demos.
- **`review_card` works without a photo.** `img` is optional now: leave it off and the card hashes a deterministic gradient monogram from the reviewer's name - testimonial walls with zero photo assets. With `img` set, nothing changes.
- **Showcase registry: marquee grows the striking spread.** The logo strip (styled wordmarks - swap in your `<img>` logos and nothing else changes) and the testimonial wall (two counter-rotating rows of photo-less review cards). The playground marquee page renders both.

#### Changed

- Dropdown menus size to their content: the panel's fixed `w-56` becomes
  `w-max min-w-36 max-w-72`, so short menus (user menu, language select)
  stop floating in dead space while long items still cap at a sane width.
  Pin a fixed width back with `menu_items_wrapper_class` if a layout
  relied on it.
- The user menu's trigger chevron had drifted bright (`dark:text-gray-100`)
  while the rest of the dropdown family runs muted - both now share the
  new `.pc-dropdown__chevron` class, so the colour can't drift again.
  `user_dropdown_menu` also gains `show_chevron={false}` for the
  chevron-less avatar trigger.
- **LiveView floor moves to `~> 1.1`** (Matt-approved, 3 Aug). The 4.8+ components already relied on 1.1 behaviour - the colour scheme switch and command palette mount hooks on dead views, which 1.0 never did - so the requirement now states what the package actually needs. Anyone still on LiveView 1.0 stays on petal_components 4.9. This also makes `command_trigger`'s dead-view support unconditional across the supported range.

#### Fixed

- `toggle_group` items: `aria-label` is now a declared slot attr.
  Icon-only items were passing it through with a compile warning - fatal
  for consumers building with `--warnings-as-errors`.
- Tall elements no longer inflate into ellipses at `radius="full"`: the
  panel clamp (1rem ceiling) now also covers textareas, multi-selects,
  block input groups (the composer pattern), alerts, the chat composer
  and tooltips. One-line controls keep their pills. The earlier clamp
  pass covered floating panels but never audited form controls - this
  sweep checked every raw token consumer (40) and capped the six that
  can grow past one line.
- **Playground: dark mode paints the overscroll.** `html` and `body` carry the scheme backgrounds and `theme-color` metas, so iOS rubber-banding no longer flashes white above and below a dark page. (Deployed playground only - no package change.)

### 4.9.0 - 2026-07-30

#### Added

- **Showcase registry: the effects join - the registry now covers the whole library.** Shine border, meteors, marquee, spotlight card, number ticker, text animation and confetti get curated, compile-checked example modules (meteors seeded so the same sky renders every time; text animation fans out to all four functions). With this the 4.9 conversion sweep is complete: every playground component page renders from the shared registry.
- **Showcase registry: the structure set joins.** Card, tabs, table, pagination, breadcrumbs, stepper, button group, user menu and badge get curated, compile-checked example modules, and the form-field registry gains the sliders (range and range-dual are field types) - 24 examples covering composed cards, the three tab styles, honest-sorting tables with people cells, link- and event-mode pagination, steps from plain maps in all three arrangements, fused/split/toolbar/mixed-rail button groups, and the app-shell user menu.
- **`link_type="button"` is now a declared value on `tab` - and safe inside forms.** `Link.a` always rendered it (the playground has used button tabs since the tabs page shipped), but the attr declaration didn't admit it, so every compile emitted value warnings. Declared and documented - and the tab pins `type="button"`, because a bare `<button>` defaults to submit and a tab inside a form would have submitted it on every switch. Callers can still override via `type`.
- **Showcase registry: the feedback set joins.** Alert, progress, rating, skeleton and loading get curated, compile-checked example modules - 16 examples covering semantic alerts (with the callout form, :actions slot, custom icons and dismissal), progress labels plus the status live-region line, ratings as real radio fieldsets (sentiment faces, fractional display, the :glyph slot), composable skeletons with the skeleton_group accessibility wrapper, and the spinner in buttons, panels and custom colours.
- **Showcase registry: the overlays join.** Modal, slide over, dropdown, tooltip and popover get curated, compile-checked example modules - 10 examples covering the invite-dialog modal wiring (show_modal / hide_modal on plain phx-clicks), edge-attached sheets with pinned footers, menu grammar (labels, separators, kbd hints, destructive items, custom triggers), CSS-only tooltips and top-layer popovers that escape clipped containers. Overlays render closed (hide / click-to-open), so examples embed safely on any page.
- **Showcase registry: the form surface joins.** input, select, checkbox, radio and switch arrive as one `PetalComponents.Showcase.Field` module - they are all one `<.field type=...>` component - alongside new `InputOtp` and `InputGroup` modules: 23 curated, compile-checked examples covering field anatomy, error states, in-field actions, every native type, option groups, multiple select, checkbox groups, radio cards (payment rows, icon tiles, per-option disable) and the input-group compositions (addons, buttons, selects, block rows). The playground's form pages render their slices of the shared spread and keep their interactive dials. Two teaching corrections ride along: the multiple-select example names its field with `[]` so every choice survives the form post, and the checkbox-group example drops the `[]` the component already appends itself.
- **Showcase registry: `button` joins.** The playground's button sections (variants, semantic colours, sizes, states, icon button) become registry examples - shown code is the rendered code, captured at compile time - so the playground, petal.build and the curated examples mcp.petal.build serves to AI assistants all document buttons from one source. The playground page keeps its interactive dials, and the states example now also shows `icon_placement="right"`.

#### Fixed

- **`color_scheme_switch` - icons no longer ride high in consumer apps.** The controls' icon-fill rule tied on specificity with the host app's own heroicon CSS, so whichever stylesheet loaded last won - petal.build's heroicon rules loaded after the package CSS and pushed the glyphs to 20x24 inside the 20px icon boxes. The fill rule now carries (0,2,0) specificity and forces `display: block`, so the wrapper is the sizing contract regardless of the consumer's heroicon setup or import order. Playground and custom icon slots verified unchanged.

### 4.8.1 - 2026-07-28

#### Fixed

- **`toast` - timers no longer wedge on touch devices after dismissing via the X.** Touch taps synthesize a compatibility `mouseenter` but never the matching `mouseleave` (the emulated pointer only moves on the next tap), so one tap inside the stack latched hover-to-pause permanently: every later toast mounted unarmed with its progress bar frozen at 100%, never auto-dismissing until a page refresh. Hover-to-pause is now wired through `pointerenter`/`pointerleave` and applies to real mice only; touch gets the natural counterpart instead - **press and hold a toast to pause its timers, release to resume** (which also stops a mid-drag expiry yanking a toast out from under a swipe, on any pointer). Desktop behaviour is unchanged.

- **`toast` - a second `toast_group` on the page no longer duplicates every toast.** Toast delivery is global (LiveView fans `push_event` to every mounted hook; the `petal:toast` CustomEvent reaches all of them), so two mounted groups each rendered an identical toast at the same position - a burst of 6 dismissed as 12. The first-mounted group now owns global events; extra groups stay inert and `console.warn` naming both ids. The internal `Showcase.Toast` example also no longer renders its own group (hosts provide the single layout group, per the documented contract). Decided 2026-07-28 with Nic: this rides the next feature release rather than a 4.8.1 - no normal 4.8.0 usage hits it, since it requires mounting two groups against the documented one-group contract.

#### Internal

- First JS test harness (vitest + jsdom, `test/js/`, separate `js` CI job). Dev-only: the Hex package still ships raw `assets/js/petal_components.js` and none of the harness; hooks remain plain vanilla JS with no build step. Scope rule: specs are added for behaviour that can only fail at runtime (like the toast ownership election), not as a coverage program.

### 4.8.0 - 2026-07-28

#### Added

- **`color_scheme_switch` - light / dark / system, in three faces.** `variant="toggle"` flips light/dark instantly with the rotating sun/moon; `variant="dropdown"` opens Light / Dark / System from the same compact trigger (icon-only rail by default; `labels` adds text) and dismisses on select, like every menu should; `variant="segmented"` is the three-way pill with every state visible. All three share one no-flash contract: render `<.color_scheme_script />` once in your layout's `<head>` and it applies the scheme before first paint, follows the OS live while the preference is system (`matchMedia`), keeps every open tab in sync (`storage` events), and dispatches `petal:scheme-changed` with `{preference, resolved}` for your own code. Stores explicit choices in `localStorage.scheme` - drop-in compatible with existing petal apps, and safe where storage is blocked (private browsing, sandboxed iframes). Default icons are Heroicons; `light_icon` / `dark_icon` / `system_icon` slots take any svg - it inherits the sizing and the toggle's rotate transition (which honours `prefers-reduced-motion`). Requires the `PetalColorScheme` hook from the bundle.
- **`toast` - notifications with the modern interaction grammar, LiveView-native.** One `<.toast_group flash={@flash} />` in the root layout. The client grammar is the full modern set: a collapsed stack (newest on top, older peeking behind at decreasing scale) that expands on hover, per-toast timeout with a progress bar, every timer pausing while you read, swipe/drag to dismiss, six positions, a queue past `max`, and reduced-motion support. The LiveView-native parts are the differentiators: `Toast.send_toast(socket, :success, title: ...)` pushes from the server; pushing again with the same `id` updates the toast in place - the loading -> success morph for async jobs; `action: %{label: "Undo", event: ..., value: ...}` renders a button that pushes a real event back to your LiveView; and anything set with `put_flash` renders as a toast and clears itself, so controllers and redirects get modern notifications for free. Plain JS can toast too via a `petal:toast` CustomEvent. The retraction half is `Toast.dismiss_toast(socket, id | :all)` - dismiss a loading toast when the job cancels, or clear the stack on logout - and every dismissal (timer, swipe, close, programmatic) bubbles a `petal:toast-dismissed` event with `{id, kind}`. Danger toasts announce as `role="alert"`, the rest as polite status. Floating-panel material, kind-coloured icons and progress, zero dependencies.
- **`carousel` - ported home from petal_marketing.** The battle-tested carousel (fade and scroll-snap slide transitions, touch swipe and mouse-drag physics, keyboard navigation, autoplay with interaction pause, bar/dot indicators, overlay/below/outside/none button placements ('outside' flanks the frame along the travel axis - left/right when horizontal, above/below when vertical), `aspect` sizing (video/photo/square - height derives from width, so a narrow wrapper gives the compact product-card look, with thumbnails matching the ratio), `indicator_position="below"` for page-coloured dots under the frame, multi-slide gallery views with edge gradients, vertical orientation, clickable slides, loop control, screen-reader announcements) joins the free library as `PetalComponents.Carousel` with the `PetalCarousel` hook. Zero JavaScript dependencies. It had been documented behind a Pro badge on petal.build since 2025 without shipping anywhere - it now actually exists where the docs said it did. Interaction logic is unchanged from the extensively tested original. New in the port: **synced thumbnails** (`thumbnails` - a strip below the frame, auto-derived from slide images with numbered chips for imageless slides; click to jump, active thumb follows, riding the same sync point as the indicators), slide corners **derive from the `--pc-radius` token by default** - amplified so the dial's steps register at surface scale and clamped at 24px so a full-radius theme gets a media-card corner, never a stadium (`rounded="none"` opts out, or pin a size), and every slide change dispatches a bubbling **`petal:carousel-change`** CustomEvent with `{id, index, count}`. Also fixed a latent bug the original never hit: controls living outside the `phx-update="ignore"` frame (thumbnails, below/sides buttons) now shield themselves from LiveView patches - previously any re-render of the parent LiveView would desync their state and silently detach their listeners. The material pass brings it onto the design system: overlay controls are true glass (backdrop blur, edge ring, deliberately light in both schemes - they float on imagery, not the page), below/sides buttons use the ghost material, indicators go rounded with focus-visible rings, edge gradients match the shipped dark surface, and the W3C behaviours land - autoplay respects prefers-reduced-motion, pauses on hover, and silences its live region while auto-advancing so screen readers aren't spammed.
- **`local_time` - timestamps in the visitor's own timezone and language.** The server renders a semantic `<time datetime>` carrying the UTC instant (accepts a `DateTime` in any zone - normalised without a timezone database - a `NaiveDateTime`, or an ISO string); the `PetalLocalTime` hook formats it with the browser's `Intl` - no timezone tables, no date library. Presets for `datetime`/`date`/`time`, a map passes raw `Intl.DateTimeFormat` options straight through, and `format="relative"` gives "12 seconds ago" / "yesterday" / "in 3 weeks" (`Intl.RelativeTimeFormat`, numeric auto) with a decaying live tick (fresh timestamps update every few seconds, old ones hourly), a re-render when a background tab wakes so a page left open never greets you with a stale "2 minutes ago", a hover `title` carrying the full date, and a `threshold` beyond which the absolute form renders instead. `locale` and `timezone` pin specific renderings per element. The SSR fallback - and the no-JS story - is the honest UTC ISO string.
- **Showcase registry covers the 4.8 components.** Carousel, Toast, ColorSchemeSwitch and Avatar join the shared example registry (shown code is the rendered code, captured at compile time), so petal.build and the playground document them from one source. Every playground page now also renders an auto-generated Properties table straight from each component's real attrs.
- **`icon_placement` on `button`.** `icon_placement="right"` puts the icon after the label - arrows, external-link, clipboard. The loading spinner takes the icon's side, so a button doesn't reflow when it enters its loading state. Defaults to `"left"`; nothing changes for existing callers.

- **`status` on `progress` - the "Downloading assets..." line.** A status message under the bar in the help-text tone, wrapped in a polite live region so screen readers hear stage changes without being spammed by every percent. Works with the top label row or on its own (a bare bar with a status gains the wrapper automatically). The top label row also moves to the system's 8px label rhythm - it sat 2px tighter than every form label.
- **`label_placement="bottom"` on `stepper`.** The classic wizard look - circles in a row, labels centred underneath, connectors pinned to the circle centres. Horizontal only (vertical always keeps labels beside); the stacked mobile layout is unchanged. Default stays `"beside"`.
- **`random_gradient` on `avatar`.** A fancier `random_color`: a diagonal two-stop gradient hashed from the name, so the same person always gets the same gradient. Wins over `random_color` when both are set.
- **`alert` grows up: correct ARIA, an actions slot, custom icons.** Every alert had `role="dialog"` - the modal-window role, flatly wrong for a message. Danger and warning now announce as `role="alert"` (assertive), the rest as `role="status"` (polite) - the same kind split the toast uses. An `:actions` slot renders buttons or links under the message, indented with the text column, and `icon="hero-lock-closed"` swaps the kind icon for any Heroicon.
- **`variant="callout"` on `alert` - the toast-cohesive form.** The classic variants paint the surface in the semantic colour; the callout follows the toast's principle instead: a neutral panel surface (the floating-panel material, in flow), colour arriving as accent - a 3px left bar and a solid kind icon - with neutral text. The GitHub-markdown-alert school. This also codifies the icon rule the two components now share: tinted surfaces take outline icons, neutral surfaces take solid ones.
- **`shape="rounded"` on `avatar` and `avatar_group`.** Proportional soft corners for orgs, teams and workspaces - circles stay the convention for people. Works across photos, monograms, art, status dots and group stacks. Deliberately independent of the `--pc-radius` dial: avatars are identity, not surface, so a sharp-cornered theme keeps soft avatars.
- **`art` on `avatar` - generative art placeholders.** `art="mesh"` draws a soft multi-hue gradient orb (layered radial blobs at hashed positions), `art="dither"` a two-tone ordered-dither blend with solid corners and a chunky pixel band across the diagonal - the boringavatars school, natively. Deterministic per name, pure CSS plus a ~1KB inline SVG, no JavaScript, no dependencies. Pure art by default; on mesh, `initials` overlays a dark hue-tinted monogram (the mesh reads light, so it always contrasts). Dither stays pure art - a discrete pixel pattern never lets text sit cleanly, and it holds the bar better without. The name always labels the avatar for screen readers, and a photo `src` wins when present.

#### Changed

- **The xl progress bar's inside label stays legible at any fill.** It was a single white label inside the fill, so at low percentages it sat white-on-light-track and couldn't be read until the bar grew past it (the Bootstrap-style limitation). It's now a two-layer wipe: a dark copy reads on the empty track, a light copy clipped to the filled width reads on the fill, both stacked at the same centred spot so they line up as one label that wipes colour as the bar advances. Pure CSS, clip-path animated in sync with the fill.
- **In-field actions (viewable, copyable, clearable) speak the action grammar.** The eye and clipboard were solid glyphs while the clear X was a stroke; all three are stroke now - in this system solid weight marks status, stroke marks actions. Copying flips to a check in the success colour for two seconds (the GitHub convention - the old same-grey clipboard-check swap was easy to miss entirely) and announces "Copied to clipboard" through a polite live region. The password and copy buttons gain the aria-labels they never had (with `aria-pressed` state on the toggle), all three icons unify at gray-400 resting and brighten on hover - they never dim - and every button gets the standard focus-visible ring. `copy_icon` / `copied_icon` defaults change accordingly; overrides are untouched.
- **Radio-card selection follows the colour-as-accent doctrine: fill first, border second, dot carries the accent.** Selection used to be a full-strength `primary-600` border alone - on a monochrome primary that resolves to a glaring near-white frame in dark mode and a heavy near-black one in light. A selected outline card now takes a faint alpha fill (`primary-600/5`, dark `primary-500/10` - a subtle gray step on monochrome, a soft hue glow on colour themes) with a calibrated border (`primary-500`, dark at 60% alpha - alpha softens a monochrome's poles more than it dulls a hue, so blue stays bold while monochrome goes REUI-restrained). And because the fill now means "selected", the outline hover no longer washes the background - hovering an unselected card firms the border instead, so hover can never impersonate selection. The classic variant is already a filled chip, so it keeps its material and speaks through the border alone.
- **Checkbox and radio labels sit tighter, top-aligned, and carry descriptions properly.** The box-to-label gap tightens from 12px to 8px and the label weight steps up to medium, matching block field labels (the shadcn schooling). The control top-aligns against the first text line instead of centring against the whole block, so multi-line labels don't float the box. And a checkbox `help_text` now stacks in the label's text column - indented with the label, never orphaned under the box at the field's left edge. The file input's button-to-filename gap tightens to match (16px to 12px).
- **Stepper labels scale with the size dial.** `sm`/`lg` used to resize only the circles while titles and descriptions stayed fixed (true since the component first shipped); now the type follows - `sm` tightens to caption sizes, `lg` steps up to base.
- **Icon spacing is part of the base button.** `.pc-button` carries the gap itself now, so composed icons - `<.button>Continue <.icon name="hero-arrow-right" class="w-4 h-4" /></.button>` - space correctly with no extra attr. `with_icon` is a legacy no-op, kept for compatibility and removed in 5.0.

#### Fixed

- **`input_group` addon geometry: buttons, selects and kbd hints sit where the eye expects.** Three drifts from 4.4: a nested `<.button>` had a lopsided frame (7px right, 2px above/below) and kept its full corner radius, so its curve fought the group's - it now sits as an inset chip with an even 2px frame and a concentric corner (group radius minus the frame, tracking the dial at every stop). A nested `<select>` kept `pc-select`'s standalone padding - a 40px chevron zone that invisibly overlapped the field and pushed its label ~25px in - it now hugs its text with the chevron tight beside it. And a trailing `<kbd>` hint sat 9px from its edge while a leading icon sat 13px from its own; both ends now inset equally. The kbd chip also gained the shadcn-style micro-gap between keys: mark each modifier as its own element - `<kbd><span>⌘</span>K</kbd>` - and the chip spaces them 2px apart; plain text stays set solid.
- **Disabling a whole radio-card group looks disabled.** `disabled` on the field reached every input (they were unclickable) but the grey-out style only applied to per-option `disabled: true`, so a group-disabled card set looked fully active. Both paths grey now. Plain checkbox and radio labels also dim with their control - the box greyed but the label text stayed full-strength.
- **Bare fields and inputs no longer require `value` (or `label`).** `<.field type="file" name="upload" />` - the natural way to write a file picker, which never carries a value - raised a `KeyError` unless you passed a pointless `value=""`; same for `<.input>`. Both now backfill a nil value, and a bare field without a label humanises one from the name, exactly as the form-field path always did. In a LiveView, that crash didn't even show on first paint: it hit on the websocket join and looped the page through endless reloads.
- **The single-thumb range is a designed slider now, and both sliders speak one language.** `type="range"` rendered the browser's native control - default blue thumb, different geometry on every OS. It now gets the full custom treatment sharing the dual-range's exact grammar: 6px rounded track in the neutral material, 20px primary thumb with the white ring, hover grow, and the standard focus ring - identical across browsers. The dual-range came up to the current system in the same pass: its dark track sheds the old `gray-700` for the gray-alpha material, its Firefox thumb finally gets a dark-mode ring (it was hardcoded white), and both sliders' focus rings move from the old paired-shade rings to the standard `primary-500/50`. The single track's dark colour now rides a variable set on the input element instead of a `dark:` utility applied to the `::-webkit-slider-runnable-track` pseudo-element - the latter compiles to a trailing `:where(.dark, …)` that can never match a pseudo-element, so the single track had been silently staying light in dark mode. And thumbs are now the same size in every browser: the preflight `border-box` reset can't reach thumb pseudo-elements, and the UA defaults disagree - WebKit sizes them border-box, Firefox content-box - so Firefox drew 26px thumbs against WebKit's 20px (on the dual-range too, since it shipped). Explicit `box-sizing: border-box` on all four thumb rules; verified pixel-identical (14px centre + 3px ring) in headless Chrome and Firefox.
- **`fill` on `type="range"` - an optional primary fill up to the thumb.** Off by default (the plain track is right for balance and pan controls, where a fill implies a wrong zero point); `fill` paints the track primary from the start to the thumb. Firefox fills natively via `::-moz-range-progress`; webkit has no native lower-fill, so the track paints a hard-stop gradient whose split the new `PetalRangeFill` hook keeps in sync, with the initial position server-rendered so it is correct before the hook connects and with JS off. On `<.input>` and `<.field>`.
- **One close-button grammar across alert, modal, slide-over and toast.** The four X buttons had drifted into four behaviours: the alert's oversized hit area grew headingless alerts when dismissible, the modal's X had no dark-mode styles at all (so hovering *dimmed* it on dark), washes and focus rings were present or absent at random. Now every X follows the same rules: a bare glyph (no hover box - a wash rectangle in a corner draws chrome where nothing else has any, and can never sit misaligned against text) that brightens on hover, a generous invisible hit area that never participates in layout, a focus-visible ring, and it never dims. The alert's glyph keeps its per-colour tinted hover.
- **`alert` no longer crashes when `on_dismiss` is nil.** Conditionally passing the attr - `on_dismiss={if @dismissible, do: JS.dispatch(...)}` - is a natural pattern, and the nil case raised at render. Nil now behaves like the empty default: no dismiss button.
- **Textareas clamp the radius token.** A full-radius theme turned multiline fields into over-rounded pills that ate their own text; textareas now cap at 1rem while single-line inputs keep the pill option - that one is a real style.
- **The avatar group's +N chip is opaque in dark mode again.** The chip shares an element with the initials placeholder, whose dark ghost alpha was winning the cascade - so the overlapped avatar photo bled through the count. The opaque chip rule now sits after the placeholder rule it has to beat.
- **Radio dots and checkbox ticks survive a monochrome primary in dark mode.** The forms plugin bakes a white glyph into its svg, which vanishes when `primary-600` resolves light (the shadcn-style inverted monochrome accent). The radio dot is now drawn as a gradient riding `--pc-button-solid-fg` - the same on-primary token solid button labels use - so it inverts automatically. The checkbox tick can't be a gradient, so the tick image itself is now the `--pc-checkbox-check` token; themes with an inverting primary point it at a dark tick in dark mode.

### 4.7.0 - 2026-07-20

The charts release. A declarative `<.chart>` powered by Apache ECharts that themes itself from your design tokens, and a zero-JavaScript `<.sparkline>` for inline trends.

#### Added

- **`chart` - declarative charts on Apache ECharts.** The spec is a plain Elixir map (the ECharts option object), so the whole chart lives server-side and travels the LiveView wire as data: update the assign and the chart animates in place; `push_event("chart:update:<id>", ...)` merges partials for high-frequency streams. Colours derive from your CSS tokens at mount - series palette from `--pc-chart-1..8` (falling back to the semantic ramps, with hue collisions demoted so adjacent series stay distinct), axes/gridlines/tooltips from the `gray` ramp using the dark ghost alphas - and the theme re-derives automatically when dark mode or theme attributes change (`window.dispatchEvent(new Event("petal:retheme"))` is the manual hook). Presentation defaults are the modern dashboard look: label-only axes, horizontal-only gridlines, rounded bar ends, dotless lines with a hover point, a radius-token tooltip. Two conveniences bridge server specs and client-only knowledge: `areaStyle: %{color: "petal:fade"}` renders the soft gradient fade in the series' own colour, and named formatters (`"petal:number"`, `"petal:percent"`, `"petal:currency:USD"`, `"petal:currency-compact:USD"`) stand in for the JavaScript callbacks ECharts normally wants anywhere a `formatter`/`valueFormatter` accepts them. A `loading` attr shows a theme-coloured spinner for async data, `renderer="svg"` swaps the paint engine, `group` connects tooltips across charts, and ECharts' aria description generation is on by default. **The engine is bring-your-own** (like Alpine): add the ECharts script or npm package and the `PetalChart` hook finds `window.echarts` - see the install rules.
- **`sparkline` - inline trends as pure server-rendered SVG.** Zero JavaScript, works in stat cards, table cells and anywhere else HTML renders. Catmull-Rom smoothing (or straight segments), an optional soft area fill, `currentColor` stroke so a text class sets the colour, and non-scaling stroke so any CSS size keeps the line weight.
- **Showcase registry entries for both** (`Showcase.Chart`, `Showcase.Sparkline`), so the playground and petal.build render the same examples.

#### Playground

A new **Chart** page under Data: a flagship line/bar chart that morphs between types (shared series id + `universalTransition`), with dials for series count, day count, area fade/solid/none, line shape, dots, bar gap density and chromeless mode - plus the registry examples and props tables. The theme dials up top recolour every chart live.

### 4.6.2 - 2026-07-18

The dark "ghost" material now carries your neutral's hue. If you remap `gray` to slate, stone, or any tinted neutral, inputs, hover fills and hairline borders finally match your panels instead of reading as colourless zinc next to them. On a stock zinc or neutral install nothing changes.

#### Changed

- **Ghost surfaces follow the temperature of your gray.** The dark material for inputs, interactive fills and hairline borders was built on `gray-100` at low alpha - technically on your gray, but the 100 step has almost no colour in any ramp, so the hue never survived the mix. The carrier moves to the ramp's chroma peak (`gray-400`) at lightness-matched alphas, so brightness is unchanged and the hue comes through. Remap `--color-gray-*` to slate and your dropdown trigger is slate like its panel; stone and it warms with everything else. Nothing to do on your side.
### 4.6.1 - 2026-07-17

A theming fix. If you remap `gray` to another neutral, fifteen components now follow you instead of quietly staying zinc. Nothing changes on a stock install.

#### Fixed

- **Dark surfaces follow your `gray`, not a hardcoded `zinc`.** The library styles its dark material with `gray-*` and defines gray's values as zinc, so remapping `--color-gray-*` in an `@theme` block re-skins the whole library. Seventeen declarations missed that rule and named `zinc` outright, so on an app with a remapped gray these fifteen components stayed zinc while everything around them changed: `dropdown`, `command`, `popover`, `avatar`, `avatar_group`, `tab`, `card`, `accordion`, `modal`, `slide_over`, `rating`, `navigation_menu`, `shine_border`, `border_beam` and `spotlight_card`. They ride the dial now. On a stock install the compiled CSS is byte-identical, so there is nothing to do and nothing to see.
### 4.6.0 - 2026-07-16

The single-source-examples release. Component examples move into the package as a versioned artifact, so the dev playground and petal.build render the exact same previews - the code you copy always matches what you see. Additive; nothing to change in your app.

#### Added

- **Showcase registry - one source of truth for examples.** Component examples now live in `PetalComponents.Showcase.*` modules, authored once as a `~H` block. Both the dev playground and petal.build render the same registry, so the code you copy can never drift from the live preview (the `example` macro captures the block's exact source and compiles it to a render function). Two new components power it: `<.showcase_example>` (a preview joined to a collapsible, syntax-highlighted code panel with a copy button - pure CSS, no Alpine) and `<.showcase_props>` (an attrs/slots table straight from `Phoenix.Component.__components__/0`, so props docs can't go stale). The `showcase/` modules are docs tooling, not app components - add `@source not ".../lib/petal_components/showcase"` to your Tailwind setup (see the install rules) so they add nothing to your CSS.

#### Fixed

- **Chat icons under a heroicons plugin.** The composer send button, message-action icons, reasoning chevron and marker icons are sized in the component layer, which a stock Phoenix heroicons plugin overrides (it sizes every `.hero-*` in the utilities layer). In a consumer app they rendered oversized - the send arrow at 24x20 instead of 16x16. They're pinned with `!important` now so they hold their intended size everywhere.
- **Chat code highlighting.** The optional `lumis` highlighter is pinned to `~> 0.6` now - `0.5.0` is incompatible with `mdex_native 0.2.5` and silently disabled highlighting, so code blocks rendered plain. If you use the chat's markdown with `mdex` + `lumis`, make sure `lumis` resolves to 0.6+ and set `config :mdex_native, syntax_highlighter: :lumis`.

### 4.5.0 - 2026-07-14

The interaction release. Two new components - a ⌘K command palette and an ambient aurora backdrop - arrive alongside a ground-up overhaul of the AI chat kit and a navigation menu that opens on hover. Under that, a consistency pass pulls the last components onto the shared surface and radius system from 4.4. Mostly additive, with a few default changes to know about - see Upgrading.

#### Added

- **`command` - a ⌘K command palette.** Built on the native `<dialog>` element (real top layer, focus trap, backdrop for free), so it escapes every `overflow: hidden` container without a portal. Filter input, grouped items via `command_group` / `command_item`, an open shortcut (`data-shortcut`, e.g. ⌘K / Ctrl-K), selecting an item closes the palette (opt out per item with `data-keep-open`), and optional reset-on-close. Powered by the new `PetalCommand` and `PetalCommandDialog` hooks, zero dependencies.
- **`aurora` - an ambient gradient backdrop.** Ported from Petal Pro and rebuilt for the free library. A `colors` list builds the gradient blend, `invert` (`auto` / `none` / `always`) adapts it for dark mode, and the motion is driven by the `PetalAurora` hook, which holds still under `prefers-reduced-motion`. Drop it behind a hero for a slow, living wash.
- **The AI chat kit, overhauled.** `<.conversation>` gained a `variant="plain"` (the ChatGPT / Claude look: full-width turns, no bubbles) alongside the existing `bubbles`. A new `<.marker>` renders inline / separator / border section dividers ("Today", "New messages", a tool-call header) with an optional loading spinner and rotating chevron. `<.chat_message>` takes a role-agnostic `:actions` slot (copy, edit, retry) that reveals on hover. `<.prompt_input>` grew an edit mode (`editing`, `edit_label`, `on_cancel_edit`) that shows a ChatGPT-style banner, an arrow-icon send button by default (`submit_label` brings back a text button), and a `copy_button`. Streaming follows the live edge now, and loading a page of history keeps your scroll position. Powered by the `PetalChatStream`, `PetalChatComposer` and `PetalChatScroll` hooks.
- **`navigation_menu` opens on hover.** The new default (`trigger="hover"`), driven by the `PetalNavMenu` hook: panels open on pointer hover or keyboard focus, hold open across the trigger-to-panel gap with a close grace period, toggle on click too (shadcn parity), and nudge horizontally to stay inside the viewport. `trigger="click"` keeps the pure-LiveView.JS tap-to-toggle from 4.4.
- **`button_group` became a composition wrapper.** Wrap `<.button>`, `<.input>` and `<.button_group_text>` in `<.button_group>` and it fuses them into one segmented control: borders collapse, only the outer corners round, focus lifts the active segment. `orientation="vertical"` stacks them; `<.button_group_separator>` drops a divider. The old `:button` slot API still works unchanged.
- **Avatar presence and overflow.** `status` (`online` / `offline` / `away` / `busy`) renders a ring-cut presence dot; `<.avatar_group max={4}>` collapses the rest into a `+N` chip.
- **More surface for the everyday components.** `variant="muted"` on `card` (a filled, borderless card for nested panels and stats), `precision="half"` on `rating` (half-step selection, still zero JS), a `:footer` totals row on `table`, and `skeleton` rebuilt as one composable brick (three shapes, shimmer, an a11y-grouped loading region).

#### Changed

- **The surface and radius doctrine reached the rest of the library.** `tabs`, `table`, `pagination`, `breadcrumbs`, `card`, `accordion`, `avatar`, `marquee` and `slide_over` now sit on the same shared surfaces, ramps and `--pc-radius` token as the 4.4 forms pass - one material across the set, in both modes.
- **Radius stays sensible at the extremes.** The checkbox caps its corner radius, so a high `--pc-radius` rounds it to a soft-cornered square instead of a circle (a circular checkbox reads as a radio). The chat input and send button, and the navigation menu's panels, rows, triggers and icon tiles, now track `--pc-radius` too - one dial still moves everything.
- **Chat defaults to the plain variant.** `<.conversation>` renders full-width turns by default now; pass `variant="bubbles"` for the messaging-app look.
- **`prompt_input` is an uncontrolled textarea.** Its `value` is the initial value only; set it imperatively (the `pc-chat-set-input` event / `push_event`) rather than re-rendering `value=`. This is what fixed the composer losing focus on every keystroke. The send button also defaults to an arrow icon now.
- **`card` gained a two-name taxonomy** (`basic` + `muted`); `outline` is a legacy alias for `basic`. **`accordion`** likewise aliases its old `ghost` name. Both still render; both go away in 5.0.
- **Marquee edges fade with a mask** (a gradient mask instead of stacked overlay divs), so the fade sits correctly on any background, including dark.

#### Fixed

- **The command dialog hook cleans up all its listeners on destroy.** `mounted()` registered five listeners on the dialog element but `destroyed()` only removed the document shortcut, so a LiveView remount that reused the dialog node left stale handlers firing against a torn-down hook. All five are removed now.
- **Chat dark mode: the user bubble was white-on-white.** The bubble background rides `primary-600` (near-white under the monochrome dark theme) but the text was hardcoded white. The label colour now follows `--pc-button-solid-fg`, so it inverts correctly; the assistant tokens got proper dark values too.
- **The chat composer no longer loses focus while you type** (see the uncontrolled-textarea change above).
- **Streaming chat follows the live edge**, and loading older messages holds your scroll position instead of jumping - the scroll hook prioritises preserving the reader's anchor over following the bottom.
- **Nav click-to-close works, and hover panels behave.** The earlier click-to-close was defeated by a `:focus-within` CSS fallback (a real click focused the trigger, which held the panel open); visibility is driven only by the hook's `--open` class now. The hook's grace period and horizontal nudging fix the gap-close and off-screen-panel issues that pure CSS `:hover` can't.
- **Dark-mode hairlines that live in `::before` / `::after`** (the chat separator line, the OTP caret) were near-invisible because `dark:` utilities silently drop inside pseudo-element selectors. Their colour moved to a parent custom property that both modes set.

#### Playground

The `dev.exs` playground gained a live streaming **AI Chat** page (turn-by-turn streaming, edit-forks-the-thread, markers and tool-call sections), a **command palette** demo, an interactive **stepper wizard** (the vertical layout puts the content beside the rail; the horizontal one hides its scrollbar), and a **shadcn-grade sidebar** built purely by composing the existing `menu` (workspace switcher, collapsible sub-items, account menu). Aurora and six marketing-parity coverage pages landed too, and every example identity is now generic (no personal names or domains).

#### Upgrading

A few default changes and a set of hooks to know about. Everything else is additive or a restyle.

- **`navigation_menu` now opens on hover by default.** Hover is driven by the `PetalNavMenu` hook. If you followed the install (`hooks: { ...PetalComponents }`), it is already registered, so hover just works after the upgrade. If you register hooks individually, add `PetalNavMenu`. If you can't run hooks at all, set `trigger="click"` to keep the 4.4 pure-LiveView.JS behaviour - in hover mode there is no click fallback without the hook, so the panels stay shut.
- **More components ship hooks now.** In addition to the input and chat hooks, `command` uses `PetalCommand` + `PetalCommandDialog`, `aurora` uses `PetalAurora`, and `navigation_menu` uses `PetalNavMenu`. The documented `hooks: { ...PetalComponents }` spread picks them all up; only cherry-picked hook setups need to add them by hand.
- **`conversation` defaults to `variant="plain"`.** Pass `variant="bubbles"` to keep the bubble layout.
- **`prompt_input` `value` is initial-only now** (uncontrolled). Set the text via the `pc-chat-set-input` event / `push_event` instead of re-rendering `value=`. The send button defaults to an arrow icon; pass `submit_label` for a labelled button.
- **`button_group`'s default is composition mode**, but the old `:button` slot still renders unchanged - no action needed unless you were overriding `.pc-button-group` internals.
- **`card` `outline` and `accordion` `ghost` are legacy aliases now** (for `basic` and the default). They still work; they'll be removed in 5.0.
- **Radius:** the checkbox no longer becomes a circle at high `--pc-radius`, and the chat input / send and nav surfaces now follow the dial. If you set a large radius, expect those to round with everything else.

### 4.4.0 - 2026-07-10

The theming foundation and a forms overhaul. This release introduces the first public theme tokens, rebuilds every form control on one shared surface system, and adds the input primitives everyone reaches for. It is a restyle release: no breaking API changes, but plenty of deliberate visual refinement - see Upgrading.

#### Added

- **Theme tokens.** `--pc-radius` (default `0.625rem`) now drives the corner radius of buttons, badges, alerts, inputs, selects, checkboxes, radio cards, tooltips, popovers, dropdowns and modals - override one custom property and the whole library follows. `--pc-button-solid-fg` (default `#fff`) sets the text colour on solid primary surfaces, so monochrome themes (black button in light, white button in dark) invert their label correctly. Both have safe fallbacks: if you set nothing, you get the current look.
- **`input_group` - prefix/suffix addons on one field surface.** Wrap any input with `:leading`/`:trailing` slots for text ("https://", "$", "USD"), icons, buttons or `<kbd>` hints, plus `:block_start`/`:block_end` rows for toolbars and character counters. The group carries the border, radius and focus ring; the input inside sheds its own surface automatically, so `<.input>` drops in unchanged.
- **`input_otp` - a segmented one-time-code input.** One real (invisible) input stretched across painted segments, which is why paste, SMS autofill (`autocomplete="one-time-code"`) and form posts all just work - unlike the N-separate-inputs pattern. Numeric or alphanumeric, optional grouping with a separator, fires `petal:otp-complete` when full. Powered by the new `PetalInputOTP` hook, zero dependencies.
- **`variant="soft"` on buttons.** The adaptive tint: pastel fill in light mode, a translucent wash in dark. The existing `light` variant keeps its original contract - it stays light in both modes.
- **Default colour ramps ship in the package.** `default.css` now carries a full token layer (blue `primary`, pink `secondary`, sky/green/yellow/red semantics, zinc `gray`), so a fresh install renders correctly with zero colour setup - previously a clean Phoenix project following the install steps failed to compile (`Cannot apply unknown utility class`) until you hand-defined every ramp. Your own definitions still win: anything you declare after the import overrides the defaults, so existing apps with a `colors.css` see no change at all.
- **`color="gray"` on alerts.** A monochrome alert for unbranded announcements, in all four variants. `info` remains the default.
- **`indicator` on radio cards, positioned where the pattern expects - plus icons and images in options.** `indicator` renders a visible radio dot in each card; `indicator_position` places it: `"end"` (default) centres it on the right edge - the plan-picker row; `"corner"` floats it top-right - the tile-grid and payment-method look; `"start"` leads the text. Options additionally take `icon:` (any Heroicon, rendered in a soft circle) and `image:` (a rounded thumbnail), so payment methods, feature tiles and people pickers come out of the box instead of being hand-rolled.
- **`dropdown_menu_label` and `dropdown_menu_separator`.** Group headings and `role="separator"` hairlines for dropdown menus - the two pieces that make real account/action menus composable. The default triggers were restyled onto the shared system too (the labelled trigger is the neutral outline button; the ellipsis is a ghost icon button; both follow the theme radius).
- **`shine_border` - an ambient border shimmer.** The quieter sibling of `border_beam`: a slow shine that sweeps the border ring instead of a discrete travelling light. Takes a single colour or a blend (`shine_color={["#f43f5e", "#8b5cf6", "#3b82f6"]}`), plus `duration` and `border_width`. Pure CSS, and it holds still under `prefers-reduced-motion`.
- **Border beam, rebuilt.** The corner geometry is fixed (the tail now fades smoothly around corners at any aspect ratio - the travelling gradient's path rounding must equal the beam size, and it now always does), and the beam self-clamps to its panel so it can never be configured into the broken zone. New powers, all still zero-JavaScript: `glow` (a symmetric comet with no sharp head - runs beautifully at very long sizes), `beams={n}` (evenly phased chasing beams), `reverse` (with the tail correctly trailing - the reference library gets this wrong), `easing="spring"` (a spring-release lap encoded as a CSS `linear()` curve: fast trace, a breath before the seam, then a launch through it), `initial_offset` (relocates where the spring parks - defaults to the top centre), plus `delay` and `border_width`. The wrapper is now a proper panel (surface, hairline border, theme radius), so content goes straight inside - no more nesting a card in it.
- **`angle`, `color` and `reverse` on meteors.** The meteor shower's direction and colour were hardcoded; both are attrs now (defaults unchanged), plus `reverse` mirrors the field so meteors can streak either way.
- **`label_position="top"` on progress.** A label row with the live percentage (tabular figures) above the bar, at any size; the inside-the-bar label remains for `xl`. Both paths now also expose `aria-valuetext`.

#### Changed

- **One surface system.** Outline-style surfaces (button/badge/alert outlines, every text-like input, select, checkbox, radio, the input group) now share a single definition: transparent in light with `gray-300` borders, a `white/5` wash in dark with `white/15` borders. Floating panels (popover, dropdown, modal) share theirs: white / `zinc-900` with a real border in both modes. Dark mode stops being a mix of `gray-700`/`gray-800` fills and becomes one material.
- **Semantic borders pair with their text.** Coloured outlines use the strong hue at low alpha (`600/30` light, `500/40` dark) instead of pastel `-300` borders, so an info alert's border finally looks like it belongs to its text.
- **Colour always tints - one rule, no exceptions.** `color` picks the ramp, `variant` picks the treatment, for every colour and every variant. Set primary to blue and your outline and ghost buttons are blue-tinted (like they were in 4.3, now on the considered formula above); secondary tints its outlines too (it used to fall back to gray, which made a secondary outline indistinguishable from a gray one). Want the shadcn look - a near-black button in light mode, near-white in dark, with a neutral outline? Make the primary ramp itself monochrome with `light-dark()` values; the neutral look lives in the token value, not in component special-cases. `color="gray"` remains the always-neutral chrome.
- **The error state calmed down.** Invalid fields show a `danger` border plus a permanent soft ring that deepens slightly on focus - and nothing else changes. Gone: pink input fills, red placeholder text, labels force-painted red with `!important`, red-filled checkboxes and switches, and the italic error message (now `text-sm`, regular).
- **Selection controls grew up.** Checkboxes and radios are both 16px (checkbox was 20), sit on the shared surface, and only show a focus ring for keyboard focus in your accent - the forms plugin's hardcoded blue ring that lit up on every mouse click is gone. Checked state is the solid-button statement (`primary-600`). Radio cards select by border colour at constant width (no more thickening border or dark-mode fill inversion) and finally surface keyboard focus. Switches match: doctrine track, `primary-600` when on, keyboard ring.
- **Solid buttons are uniform.** Every colour runs `600 -> 700` hover `-> 800` active with `shadow-xs`; the legacy `focus:` colour overrides (which repainted buttons on tab-focus) are gone - the `focus-visible` ring is the one focus treatment. Filled variants (solid/soft/light) plus outline carry `shadow-xs`; ghost never does.
- **Tooltips invert in both modes** - near-black bubble on light, near-white bubble with dark text on dark (the old dark bubble was `gray-700` mud). Modal scrim is a modern `black/50`. Dropdown menu items sit transparent on a padded panel with a hover wash and nested radius.
- **Progress joined the system**: washed tracks (hue at 15% alpha - the old `dark:*-900` tracks inverted badly under monochrome themes), `600` bars, pill-shaped at every size, and the bar now animates between values.
- **Native multiple selects are styled**: padded rows, themed selection washes that survive the browser's forced selection-text colours, and a thin scrollbar.
- **Every input type is on the surface** - date/time/month/week, color (with a nested-radius swatch), file (the file button is literally the outline button now, and the "No file chosen" text sits in the muted tier) and range all dropped their pre-4.4 one-off styles.

#### Fixed

- **`<.field type="checkbox">` and `type="switch"` without `value` no longer crash.** The clause heads pattern-matched on `value`, so a valueless checkbox mis-routed into the generic input branch and raised a KeyError. Omitting `value` now renders unchecked; an explicit `checked` still overrides. Same fix in `input.ex`'s switch.
- **`<.input type="text">` (and other bare text-like inputs) render with the field surface again** - the generic clause forwarded no surface class at all, so bare inputs were completely unstyled while `select`/`textarea` styled themselves.
- **Badge `size="xs"` and `size="xl"` actually render.** The API accepted five sizes but the stylesheet only ever defined three - xs and xl fell through to the unstyled base.
- **Radio cards and switches were invisible to keyboard users** - their real inputs are visually hidden and nothing surfaced `:focus-visible`. Both now ring.
- **Alert dismiss buttons** had pre-4.4 leftovers: rounding that only appeared on hover, and solid dark chips that clashed with the new washes. They are ghost-styled now and nest the theme radius.
- **Heroicon sizing is layer-safe in the playground/docs setup** - the icon mask CSS is imported into `layer(base)` so component and utility sizing can override it. If you import `heroicons.css` yourself, keep it inside a cascade layer.

#### Playground

The dev playground (`dev.exs`) was rebuilt as an app-shell with a component sidebar, a live theme rail (primary and secondary colour dials + radius, deep-linked in the URL), dark mode, and per-component pages with live controls and code snippets - 19 pages covering foundations, inputs, feedback, overlays and effects. The Colours page shows the full Tailwind palette you can map the dials from.

#### Upgrading

No API changes are required. Visual shifts to be aware of:

- `border_beam` wraps content in a real panel now (background + hairline border). If you were nesting your own card inside it, unwrap - the beam is the card.
- Corner radii now come from `--pc-radius` (10px default). Inputs and selects were `rounded-md` (6px) and badges `rounded-sm` - everything is slightly rounder out of the box. Set `--pc-radius: 0.375rem` on `:root` to keep the old feel.
- Dark mode is significantly different across the board (washes instead of solid gray fills, real borders on panels). Light mode changes are subtler: semantic outline borders are stronger, error states are calmer, checkboxes are 16px.
- Outline and ghost buttons (and outline badges) follow your primary/secondary ramps again, on the new border formula. If you kept the default blue primary, expect blue-tinted outlines where 4.3 gave you blue-tinted outlines too - the in-between builds briefly rendered them gray. For an always-neutral outline next to a coloured primary, use `color="gray"`.
- If you relied on the old error styling (red fills/labels), the state is now carried by the border, ring and message only.
### 4.3.0 - 2026-07-07

#### Added

- **`tooltip` - a pure-CSS tooltip primitive.** Appears on hover and keyboard focus, four placements (`top`/`bottom`/`left`/`right`), optional arrow, rich content via a `:content` slot, and a `disabled` attr. The bubble carries a stable `id` so the trigger can reference it with `aria-describedby` for screen readers. Toggle at runtime by adding the `pc-tooltip--suppressed` class on the wrapper (e.g. only show tooltips while a sidebar is collapsed). No JavaScript, no dependencies.
- **`popover` - a click-triggered anchored panel.** Opens on click, closes on click-away or Escape, 12 placements (side plus `-start`/`-end` alignment), rich slot content. Built on the same CSS technique as `dropdown` - zero npm dependencies. The trigger toggles `aria-expanded`, and Escape closes the panel and returns focus to the trigger. Pass `top_layer` to render the panel in the browser top layer via the native HTML popover attribute, so it escapes `overflow: hidden` containers (collapsed sidebars, table cells) - positioning handled by the new `PetalPopover` hook with side-flipping and viewport clamping.

#### Changed

- **Table headers read as proper labels.** `<.table>` header cells were muted (`gray-500`/`gray-400`) with extra letter-spacing, which rendered faint and loose. They now use the prominent text tone (`gray-900`/white) and normal tracking, matching the type scale from the 4.2.0 typography pass and how shadcn styles its table headers.

#### Playground

- Deep-linkable tabs (`?tab=navigation`), a `PORT` env override, and HEAD request support - all for CI and agent workflows.

#### Upgrading

No code changes are required - everything is additive or a CSS restyle. The one visual shift: `<.table>` headers are darker and no longer letter-spaced. To keep the old look on a specific table, pass `class` to override, or redefine `.pc-table__th` after your import.

### 4.2.1 - 2026-07-06

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
