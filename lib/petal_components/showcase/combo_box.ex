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
      "Type to filter, arrow keys to move, Enter to choose - the command palette's keyboard machinery on a form control. The visible input is chrome; a hidden native select carries the name and value, so changesets, phx-change and LiveView form recovery behave exactly like a plain select. Zero JS dependencies." do
    ~H"""
    <div class="w-full max-w-xs mx-auto">
      <.combo_box
        id="sx-combo-basic"
        name="country"
        placeholder="Select a country…"
        options={["Australia", "Japan", "New Zealand", "Portugal", "Sweden"]}
      />
    </div>
    """
  end

  example :preselected, "A chosen value",
    description:
      "value (or the form field's value) marks the chosen option: it renders in the trigger, carries aria-selected and the check mark, and the highlight homes on it when the panel opens. Options are label/value tuples here - the shapes select accepts all work." do
    ~H"""
    <div class="w-full max-w-xs mx-auto">
      <.combo_box
        id="sx-combo-chosen"
        name="tz"
        value="au_syd"
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

  example :groups, "Groups and disabled options",
    description:
      "{group_label, options} renders a heading and keeps its position between flat options; a group hides itself when the query filters out every option inside. {label, value, disabled: true} renders the option present but inert - visible in the list, skipped by the keyboard." do
    ~H"""
    <div class="w-full max-w-xs mx-auto">
      <.combo_box
        id="sx-combo-groups"
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
