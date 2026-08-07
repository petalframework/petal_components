defmodule PetalComponents.Showcase.ComboBox do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.ComboBox,
    title: "Combobox"

  example :multiple, "Chips - multiple selection",
    description:
      "multiple turns the trigger into a chip row: every choice renders as a removable token, the panel stays open while picking, and Backspace in an empty input removes the last chip. The hidden select becomes a real select multiple - its name gains [] - so every choice survives the form post exactly like a native multiple select. max_items caps the count; at the cap, unchosen options rest until something is removed." do
    ~H"""
    <div class="w-full max-w-sm mx-auto">
      <.combo_box
        id="sx-combo-multi"
        name="stack"
        multiple
        max_items={4}
        value={["phx", "lv"]}
        placeholder="Build your stack…"
        options={[
          {"Phoenix", "phx"},
          {"LiveView", "lv"},
          {"Ecto", "ecto"},
          {"Oban", "oban"},
          {"Tailwind", "tw"},
          {"Postgres", "pg"}
        ]}
      />
    </div>
    """
  end

  example :basic, "The searchable select",
    description:
      "Type to filter, arrow keys to move, Enter to choose - the command palette's keyboard machinery on a form control. The visible input is chrome; a hidden native select carries the name and value, so changesets, phx-change and LiveView form recovery behave exactly like a plain select. Zero JS dependencies. Emoji in a label is just text - flags need no slot, no assets, and filtering still matches the country name." do
    ~H"""
    <div class="w-full max-w-xs mx-auto">
      <.combo_box
        id="sx-combo-basic"
        name="country"
        placeholder="Select a country…"
        clearable
        options={[
          {"🇦🇺 Australia", "au"},
          {"🇯🇵 Japan", "jp"},
          {"🇳🇿 New Zealand", "nz"},
          {"🇵🇹 Portugal", "pt"},
          {"🇸🇪 Sweden", "se"}
        ]}
      />
    </div>
    """
  end

  example :preselected, "A chosen value, clearable",
    description:
      "value (or the form field's value) marks the chosen option: it renders in the trigger, carries aria-selected and the check mark, and the highlight homes on it when the panel opens. clearable adds an X button whenever a value is chosen - one press empties the selection. Options are label/value tuples here - the shapes select accepts all work." do
    ~H"""
    <div class="w-full max-w-xs mx-auto">
      <.combo_box
        id="sx-combo-chosen"
        name="tz"
        value="au_syd"
        clearable
        options={[
          {"Sydney", "au_syd"},
          {"Tokyo", "jp_tyo"},
          {"Lisbon", "pt_lis"},
          {"Stockholm", "se_sto"}
        ]}
      />
    </div>
    """
  end

  example :trigger, "The picker - trigger variant",
    description:
      "variant=\"trigger\" is the select-like anatomy: a button shows the chosen value (or a count with multiple), and the search input lives inside the panel. This is the shape pickers and the data table's filter editors use - open it from anywhere, search, choose, and focus returns to the button. Same hidden select underneath, same form behavior." do
    ~H"""
    <div class="flex flex-col items-center w-full max-w-xs gap-4 mx-auto">
      <.combo_box
        id="sx-combo-trigger"
        name="assignee"
        clearable
        variant="trigger"
        placeholder="Assign to…"
        options={[
          {"Amelia Ward", "amelia"},
          {"Jonah Reyes", "jonah"},
          {"Priya Anand", "priya"},
          {"Tom Hale", "tom"}
        ]}
      />
      <.combo_box
        id="sx-combo-trigger-multi"
        name="labels"
        variant="trigger"
        multiple
        value={["bug", "ui"]}
        placeholder="Labels…"
        count_label="labels"
        options={[
          {"Bug", "bug"},
          {"UI", "ui"},
          {"Docs", "docs"},
          {"Performance", "perf"}
        ]}
      />
    </div>
    """
  end

  example :labels, "Label picker - the :selected slot",
    description:
      "The :selected slot renders rich CLOSED-state content in the trigger - here colored dots with a +N overflow, pure composition, no overflow attr. :let receives the list of chosen normalized options (label, value, meta). Client-side picks show the plain count until the LiveView patch re-renders the slot (server wins); a preset value shows the rich state immediately." do
    ~H"""
    <div class="w-full max-w-xs mx-auto">
      <.combo_box
        id="sx-combo-labels"
        name="labels"
        variant="trigger"
        multiple
        placeholder="Labels…"
        count_label="labels"
        value={["feat", "bug", "imp", "des"]}
        options={[
          {"Feature", "feat", color: "#0ea5e9"},
          {"Bug", "bug", color: "#f43f5e"},
          {"Improvement", "imp", color: "#10b981"},
          {"Design", "des", color: "#a855f7"},
          {"Docs", "docs", color: "#f59e0b"}
        ]}
      >
        <:selected :let={chosen}>
          <span
            :for={opt <- Enum.take(chosen, 3)}
            class="h-3 w-3 shrink-0 rounded-full"
            style={"background-color: #{opt.meta[:color]}"}
          ></span>
          <span :if={length(chosen) > 3} class="text-xs tabular-nums text-gray-500 dark:text-gray-400">
            +{length(chosen) - 3}
          </span>
        </:selected>
        <:option :let={opt}>
          <span
            class="h-2.5 w-2.5 shrink-0 rounded-full"
            style={"background-color: #{opt.meta[:color]}"}
          ></span>
          <span class="truncate">{opt.label}</span>
        </:option>
      </.combo_box>
    </div>
    """
  end

  example :team, "Avatar chips - the :chip slot",
    description:
      "The :chip slot renders rich chip content - the remove button stays appended. Client-side picks build plain optimistic chips until the LiveView patch swaps the rich ones back in (server wins on patch); server-rendered chips are left intact whenever they already match the selection." do
    ~H"""
    <div class="w-full max-w-sm mx-auto">
      <.combo_box
        id="sx-combo-team"
        name="team"
        multiple
        placeholder="Add members…"
        value={["amelia", "jonah"]}
        options={[
          {"Amelia Ward", "amelia", role: "Engineering"},
          {"Jonah Reyes", "jonah", role: "Design"},
          {"Priya Anand", "priya", role: "Support"},
          {"Tom Hale", "tom", role: "Engineering"}
        ]}
      >
        <:chip :let={opt}>
          <.avatar size="xs" name={opt.label} random_gradient />
          <span class="truncate">{opt.label}</span>
        </:chip>
        <:option :let={opt}>
          <.avatar size="xs" name={opt.label} random_gradient />
          <span class="flex min-w-0 flex-col leading-tight">
            <span class="truncate">{opt.label}</span>
            <span class="truncate text-xs text-gray-500 dark:text-gray-400">{opt.meta[:role]}</span>
          </span>
        </:option>
      </.combo_box>
    </div>
    """
  end

  example :panel_chrome, "Panel chrome - :header and :footer",
    description:
      "Panel chrome lives OUTSIDE the listbox: a caption above the options, a summary or manage link below. Keyboard navigation and filtering never touch either - options stay the only stops." do
    ~H"""
    <div class="w-full max-w-xs mx-auto">
      <.combo_box
        id="sx-combo-chrome"
        name="dest"
        placeholder="Where to?"
        options={[
          {"🇯🇵 Tokyo", "tyo"},
          {"🇵🇹 Lisbon", "lis"},
          {"🇸🇪 Stockholm", "sto"},
          {"🇦🇺 Sydney", "syd"},
          {"🇰🇷 Seoul", "sel"}
        ]}
      >
        <:header>Popular destinations</:header>
        <:footer>
          <span class="flex items-center justify-between">
            <span>5 cities</span>
            <span class="font-medium text-primary-600 dark:text-primary-400">Manage list</span>
          </span>
        </:footer>
      </.combo_box>
    </div>
    """
  end

  example :rich_options, "Rich options - the :option slot",
    description:
      "The :option slot renders anything inside each panel option - avatars, flags, secondary text - with :let receiving the normalized option (label, value, disabled, and meta: whatever extra data the option tuple carried). Filtering, chips and the trigger label keep using the plain label, so rich content never affects search or the closed state." do
    ~H"""
    <div class="w-full max-w-sm mx-auto">
      <.combo_box
        id="sx-combo-rich"
        name="assignee"
        clearable
        placeholder="Assign to…"
        options={[
          {"Amelia Ward", "amelia", role: "Engineering"},
          {"Jonah Reyes", "jonah", role: "Design"},
          {"Priya Anand", "priya", role: "Support"},
          {"Tom Hale", "tom", role: "Engineering"}
        ]}
      >
        <:option :let={opt}>
          <.avatar size="xs" name={opt.label} random_gradient />
          <span class="flex min-w-0 flex-col leading-tight">
            <span class="truncate">{opt.label}</span>
            <span class="truncate text-xs text-gray-500 dark:text-gray-400">{opt.meta[:role]}</span>
          </span>
        </:option>
      </.combo_box>
    </div>
    """
  end

  example :groups, "Groups and disabled options",
    description:
      "{group_label, options} renders a heading and keeps its position between flat options; a group hides itself when the query filters out every option inside. {label, value, disabled: true} renders the option present but inert - visible in the list, skipped by the keyboard." do
    ~H"""
    <div class="w-full max-w-xs mx-auto">
      <.combo_box
        id="sx-combo-groups"
        clearable
        name="city"
        placeholder="Pick a city…"
        options={[
          {"Oceania", [{"Sydney", "syd"}, {"Auckland", "akl"}]},
          {"Europe", [{"Lisbon", "lis"}, {"Stockholm", "sto", disabled: true}]}
        ]}
      />
    </div>
    """
  end
end
