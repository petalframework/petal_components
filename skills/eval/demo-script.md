# Demo script - the reproducible before/after eval

Three arms, four fixed tasks, four measurable deltas. This is both the proof (skill arm beats MCP arm beats bare) and the source of the marketing before/after. Run it exactly - a cherry-picked demo is worthless; publish the run you measured, including any metric the skill arm loses.

## Setup

One fresh Phoenix app with petal_components installed per rules.md, at the same commit for all arms. Three clean sessions, output to `out/bare/`, `out/mcp/`, `out/skill/`. Same model, same task prompts verbatim, one attempt, no retries, no steering. If an arm asks a question, reply exactly: `your call`.

## Arms

- **bare** - no MCP, no skill. Preamble: `Work in this Phoenix app. petal_components is installed. Complete the task below.`
- **mcp** - MCP connected, no skill. Preamble: bare's text plus `The petal MCP server is connected (mcp.petal.build) - use its tools to look up components before writing HEEx.`
- **skill** - MCP connected AND the skill copied to `.claude/skills/petal-design/`. Preamble: identical to mcp, word for word. The skill must trigger untold - naming it in the prompt is coaching and voids the run. Run mcp and skill against the same MCP availability.

## Tasks (fixed - never reword between arms)

**T1 - settings page.** Prompt: `Build a settings LiveView at /settings: profile section (name, email, avatar), notification toggles, and a billing section with a table of the last 10 invoices (date, amount, status, PDF link) plus a plan card with an upgrade button. Support light and dark mode.`

**T2 - soup conversion.** Prompt: `Convert this template to idiomatic petal_components usage:` followed by this snippet verbatim:

```heex
<div class="p-6">
  <h2 class="text-xl font-bold text-zinc-800 mb-4">Invoices</h2>
  <table class="w-full border border-zinc-200 rounded-lg">
    <thead>
      <tr class="bg-zinc-100 text-left">
        <th class="px-4 py-2 text-sm text-zinc-500">Date</th>
        <th class="px-4 py-2 text-sm text-zinc-500">Amount</th>
        <th class="px-4 py-2 text-sm text-zinc-500">Status</th>
      </tr>
    </thead>
    <tbody>
      <tr :for={inv <- @invoices} class="border-t border-zinc-200 hover:bg-zinc-50">
        <td class="px-4 py-2 text-sm text-zinc-700">{inv.date}</td>
        <td class="px-4 py-2 text-sm text-zinc-700">{inv.amount}</td>
        <td class="px-4 py-2"><span class="px-2 py-1 rounded-full text-xs bg-green-100 text-green-800">{inv.status}</span></td>
      </tr>
    </tbody>
  </table>
  <button class="mt-4 px-4 py-2 bg-blue-600 text-white rounded-lg hover:opacity-90 focus:outline-none" phx-click={JS.show(to: "#confirm")}>Delete all</button>
  <div id="confirm" class="hidden fixed inset-0 z-50 bg-black/50 flex items-center justify-center">
    <div class="bg-white rounded-lg p-6 w-96 shadow-xl">
      <h3 class="font-bold text-zinc-800">Are you sure?</h3>
      <p class="text-sm text-zinc-500 mt-2">This cannot be undone.</p>
      <button class="mt-4 px-4 py-2 bg-red-600 text-white rounded-lg" phx-click="delete_all">OK</button>
    </div>
  </div>
</div>
```

**T3 - dark-mode a light-only view.** Prompt: `Add dark mode to this view. Light styling stays exactly as is.` Input fixture (custom chrome on purpose - the test is ghost ladder vs mechanical inversion):

```heex
<div class="rounded-lg border border-gray-200 bg-white p-6 shadow-xs">
  <h3 class="font-semibold text-gray-900">API keys</h3>
  <p class="mt-1 text-sm text-gray-500">Rotate keys regularly.</p>
  <input type="text" class="mt-4 block w-full rounded-lg border-gray-300 text-gray-900 placeholder:text-gray-400" placeholder="sk-..." />
  <button class="mt-4 rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700">Rotate</button>
</div>
```

Pass signal: `dark:bg-gray-900` panel, `dark:border-gray-400/17` hairline, input surface `dark:bg-gray-400/8` with `dark:border-gray-400/25`, text `dark:text-gray-100` / muted `dark:text-gray-400`. Fail signal: `dark:bg-gray-800` everywhere, `dark:bg-white/10`, `dark:text-gray-600`.

**T4 - review a seeded diff.** Prompt: `Review this diff for design-system violations. List findings as file:line - what - why.` Build the fixture diff once, seeding exactly these 11 violations (expected recall list): (1) `text-zinc-500` on chrome text; (2) `.pc-button { width: 100% !important; }` in app.css; (3) hand-rolled `fixed inset-0` overlay; (4) `<.pc_button>` function prefix; (5) `<.dropdown placement="bottom-end">` deprecated attr; (6) `@keyframes` animating `transform` instead of `translate`; (7) raw `<button class=...>` in an app template; (8) `bg-white text-gray-900` with no `dark:` pair; (9) `<.field type="combobox" variant="input">` - wants `combo_variant`; (10) `dark:bg-white/10` ghost surface - wants gray-400 alpha; (11) `<.button size="xxl">` - enum is `["xs","sm","md","lg","xl","icon"]`. Score = seeded-found / 11, minus a note for each false positive.

## Measurable deltas

Run over each arm's changed `.heex`/`.ex` files. Record all four numbers per arm per task.

1. **Grep-table violation count** - run every row of `skills/petal-design/references/review.md`'s grep table; the total is the score. Representative row: `grep -rnE 'slate-|zinc-|stone-' --include='*.heex' --include='*.ex' out/<arm> | wc -l`. A clean grep is a floor, not proof - but a dirty one is a real defect count.
2. **Schema-invalid attrs** - list components used: `grep -rhoE '<\.[a-z_]+' --include='*.heex' out/<arm> | sort -u`. For each, pull the legal attr names: `jq -r '.components[] | select(.name=="button") | .attrs[].name' skills/petal-design/data/schemas.json` (and `.values` for enums). Count every attr not in the list and every enum value outside `.values`. Multi-line calls need eyeballing; count usages, not files.
3. **Dark-pair coverage %** - share of color-bearing class strings that also carry `dark:`: `grep -rhoE 'class="[^"]*"' --include='*.heex' out/<arm> | grep -E '(bg|text|border)-(gray|primary|secondary|info|success|warning|danger)-[0-9]' | grep -c 'dark:'` divided by the same pipeline without the final grep.
4. **Component-vs-raw ratio** - `c=$(grep -rhoE '<\.[a-z_]+' --include='*.heex' out/<arm> | wc -l); r=$(grep -rhoE '<(button|table|input|select|textarea)\b' --include='*.heex' out/<arm> | wc -l); echo "$c:$r"`.

## Marketing capture

Render each arm's T1 route with identical seed data. Screenshot at 1280px viewport width, headless Chrome at 2x, light AND dark, into `screenshots/<version>/` per its README naming (e.g. `skill-eval-t1-bare-dark.png`, `skill-eval-t1-skill-dark.png`). The before/after pair is bare vs skill, same theme, side by side, no annotations - if the delta needs arrows, rerun the eval instead of decorating it. Pair the images with the four-number table from the deltas above; numbers are the headline, screenshots are the story.
