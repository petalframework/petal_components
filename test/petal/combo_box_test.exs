defmodule PetalComponents.ComboBoxTest do
  use ComponentCase
  import PetalComponents.ComboBox

  test "renders the hidden select as the real form control" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.combo_box id="countries" name="country" options={["Australia", "Japan"]} />
      """)

    assert html =~ ~s|<select|
    assert html =~ ~s|name="country"|
    assert html =~ ~s|class="pc-combo-box__select"|
    assert html =~ ~s|tabindex="-1"|
    assert html =~ ~s|aria-hidden="true"|
    # the empty option so "no selection" posts ""
    assert html =~ ~s|<option value=""|
    assert html =~ ~s|<option value="Australia"|
  end

  test "wires the WAI-ARIA combobox pattern" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.combo_box id="countries" name="country" options={["Australia"]} />
      """)

    assert html =~ ~s|phx-hook="PetalComboBox"|
    assert html =~ ~s|role="combobox"|
    assert html =~ ~s|aria-expanded="false"|
    assert html =~ ~s|aria-autocomplete="list"|
    assert html =~ ~s|aria-controls="countries-listbox"|
    assert html =~ ~s|role="listbox"|
    assert html =~ ~s|role="option"|
    assert html =~ ~s|autocomplete="off"|
  end

  test "a chosen value selects the option, fills the display input and check-marks it" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.combo_box id="tz" name="tz" value="syd" options={[{"Sydney", "syd"}, {"Tokyo", "tyo"}]} />
      """)

    assert html =~ ~s|value="syd" selected|
    assert html =~ ~s|value="Sydney"|
    assert html =~ ~s|aria-selected="true"|
  end

  test "no value means empty display and nothing selected" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.combo_box id="tz" name="tz" options={[{"Sydney", "syd"}]} />
      """)

    refute html =~ ~s| selected>|
    refute html =~ ~s|aria-selected="true"|
  end

  test "groups render optgroups in the select and headed groups in the listbox" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.combo_box
        id="cities"
        name="city"
        options={[{"Oceania", [{"Sydney", "syd"}]}, {"Europe", [{"Lisbon", "lis"}]}]}
      />
      """)

    assert html =~ ~s|<optgroup label="Oceania">|
    assert html =~ ~s|data-pc-combo-group|
    assert html =~ "Oceania"
    assert html =~ ~s|data-value="lis"|
  end

  test "flat options between groups keep their position without a heading" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.combo_box
        id="mixed"
        name="pick"
        options={["Loose", {"Grouped", [{"Inside", "in"}]}]}
      />
      """)

    assert html =~ ~s|data-value="Loose"|
    assert html =~ ~s|<optgroup label="Grouped">|
  end

  test "disabled options are inert in both the select and the listbox" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.combo_box id="tz" name="tz" options={[{"Sydney", "syd", disabled: true}]} />
      """)

    assert html =~ ~s|value="syd" disabled|
    assert html =~ ~s|data-disabled="true"|
    assert html =~ ~s|aria-disabled="true"|
  end

  test "disabling the component disables both the input and the select" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.combo_box id="tz" name="tz" disabled options={["Sydney"]} />
      """)

    # both the select and the input carry disabled
    assert [_, _, _] = String.split(html, ~s| disabled|)
  end

  test "a form field supplies name, value and a stable derived id" do
    assigns = %{
      field: %Phoenix.HTML.FormField{
        id: "user_country",
        name: "user[country]",
        value: "au",
        errors: [],
        field: :country,
        form: %Phoenix.HTML.Form{}
      }
    }

    html =
      rendered_to_string(~H"""
      <.combo_box field={@field} options={[{"Australia", "au"}]} />
      """)

    assert html =~ ~s|id="user_country_combo_box"|
    assert html =~ ~s|name="user[country]"|
    assert html =~ ~s|value="au" selected|
  end

  test "required and form_id render on the native select, not the wrapper" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.combo_box id="tz" name="tz" required form_id="filters" options={["Sydney"]} />
      """)

    [select_tag | _] = String.split(html, "</select>")
    assert select_tag =~ ~s| required|
    assert select_tag =~ ~s|form="filters"|
    [wrapper_tag | _] = String.split(html, ">")
    refute wrapper_tag =~ "required"
  end

  describe "multiple" do
    test "the select is multiple, the name gains [], no empty option" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="tags" name="tags" multiple options={["a", "b"]} />
        """)

      assert html =~ ~s|multiple|
      assert html =~ ~s|name="tags[]"|
      refute html =~ ~s|<option value=""|
      assert html =~ ~s|aria-multiselectable="true"|
    end

    test "chosen values render as chips with labelled remove buttons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box
          id="tags"
          name="tags"
          multiple
          value={["b", "a"]}
          options={[{"Alpha", "a"}, {"Beta", "b"}]}
        />
        """)

      assert html =~ "pc-combo-box__chip"
      # chip order follows chosen order
      assert html =~ ~r/Beta.*Alpha/s
      assert html =~ ~s|aria-label="Remove Beta"|
      assert html =~ ~s|data-pc-combo-chip-remove|
    end

    test "chips mode is a token field - no chevron" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="tags" name="tags" multiple options={["a"]} />
        """)

      refute html =~ "pc-combo-box__chevron"
    end

    test "max_items lands as a data attribute for the hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="tags" name="tags" multiple max_items={3} options={["a"]} />
        """)

      assert html =~ ~s|data-max-items="3"|
    end
  end

  describe "trigger variant" do
    test "renders a combobox button with the search input inside the panel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="pick" name="pick" variant="trigger" options={["Sydney"]} />
        """)

      assert html =~ ~s|data-pc-combo-trigger|
      assert html =~ ~s|aria-haspopup="listbox"|
      assert html =~ "pc-combo-box__search"
      # the search input lives in the panel, not a control row
      refute html =~ "pc-combo-box__control"
      # placeholder state on an empty trigger
      assert html =~ ~s|data-placeholder="true"|
    end

    test "single trigger shows the chosen label; multiple shows the count" do
      assigns = %{}

      single =
        rendered_to_string(~H"""
        <.combo_box id="s" name="s" variant="trigger" value="syd" options={[{"Sydney", "syd"}]} />
        """)

      assert single =~ ~r/data-count-label="selected">\s*Sydney\s*</
      refute single =~ ~s|data-placeholder="true"|

      multi =
        rendered_to_string(~H"""
        <.combo_box
          id="m"
          name="m"
          variant="trigger"
          multiple
          value={["a", "b"]}
          options={[{"Alpha", "a"}, {"Beta", "b"}]}
        />
        """)

      assert multi =~ ~r/data-count-label="selected">\s*2 selected\s*</
    end
  end

  describe "clearable and hardening" do
    test "clearable renders the labelled clear button and data-has-value tracks the value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="tz" name="tz" clearable value="syd" options={[{"Sydney", "syd"}]} />
        """)

      assert html =~ ~s|data-pc-combo-clear|
      assert html =~ ~s|aria-label="Clear selection"|
      assert html =~ ~s|data-has-value|
    end

    test "the hidden select is inert so dialog autofocus can never land on it" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="tz" name="tz" options={["Sydney"]} />
        """)

      [select_tag | _] = String.split(html, "</select>")
      assert select_tag =~ ~s| inert|
    end

    test "the polite live region renders with its labels" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="tz" name="tz" options={["Sydney"]} />
        """)

      assert html =~ ~s|aria-live="polite"|
      assert html =~ ~s|data-results-label="results"|
    end
  end

  describe "the :option slot" do
    test "renders custom content per option with meta passthrough; filter attrs intact" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="who" name="who" options={[{"Amelia Ward", "am", role: "Engineering"}]}>
          <:option :let={opt}>
            <strong>{opt.label}</strong>
            <em>{opt.meta[:role]}</em>
          </:option>
        </.combo_box>
        """)

      assert html =~ "<strong>Amelia Ward</strong>"
      assert html =~ "<em>Engineering</em>"
      assert html =~ "pc-combo-box__option-content"
      # the filter text still rides data-label, custom content or not
      assert html =~ ~s|data-label="Amelia Ward"|
      refute html =~ "pc-combo-box__option-label"
    end

    test "without the slot the plain label renders as before" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="who" name="who" options={["Amelia"]} />
        """)

      assert html =~ "pc-combo-box__option-label"
      refute html =~ "pc-combo-box__option-content"
    end
  end

  describe "M3a slots" do
    test ":header and :footer render as panel chrome OUTSIDE the listbox" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="hf" name="hf" options={["A"]}>
          <:header>Frameworks</:header>
          <:footer>12 teammates</:footer>
        </.combo_box>
        """)

      assert html =~ "pc-combo-box__header"
      assert html =~ "pc-combo-box__footer"
      # chrome, not options: both live outside the listbox element
      [_, after_list_open] = String.split(html, ~s|role="listbox"|, parts: 2)
      [inside_list, after_list] = String.split(after_list_open, "pc-combo-box__footer", parts: 2)
      refute inside_list =~ "pc-combo-box__header"
      assert after_list =~ "12 teammates"
    end

    test "no header/footer chrome renders without the slots" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="nf" name="nf" options={["A"]} />
        """)

      refute html =~ "pc-combo-box__header"
      refute html =~ "pc-combo-box__footer"
    end

    test ":selected renders rich closed-state content in the trigger, list of chosen options" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box
          id="sel"
          name="sel"
          variant="trigger"
          multiple
          value={["a", "b"]}
          options={[{"Alpha", "a", color: "sky"}, {"Beta", "b", color: "rose"}]}
        >
          <:selected :let={chosen}>
            <span :for={opt <- chosen} class={"dot-#{opt.meta[:color]}"}></span>
            <span>{length(chosen)} labels</span>
          </:selected>
        </.combo_box>
        """)

      assert html =~ "pc-combo-box__selected-content"
      assert html =~ "dot-sky"
      assert html =~ "dot-rose"
      assert html =~ "2 labels"
      refute html =~ "2 selected"
    end

    test ":selected stamps data-values as JSON (no delimiter to collide; hook compares as a multiset)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box
          id="ord"
          name="ord"
          variant="trigger"
          multiple
          value={["b", "a"]}
          options={[{"Alpha", "a"}, {"Beta", "b"}]}
        >
          <:selected :let={chosen}>{length(chosen)}</:selected>
        </.combo_box>
        """)

      assert html =~ ~s|data-values="[&quot;b&quot;,&quot;a&quot;]"|
    end

    test "duplicated caller values dedupe - one chip, stamp matches what the select yields" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box
          id="dup"
          name="dup"
          variant="trigger"
          multiple
          value={["a", "a"]}
          options={[{"Alpha", "a"}]}
        >
          <:selected :let={chosen}>{length(chosen)}</:selected>
        </.combo_box>
        """)

      assert html =~ ~s|data-values="[&quot;a&quot;]"|

      chips =
        rendered_to_string(~H"""
        <.combo_box id="dupc" name="dupc" multiple value={["a", "a"]} options={[{"Alpha", "a"}]} />
        """)

      assert length(String.split(chips, "data-pc-combo-chip\"")) - 1 <= 2
      assert length(String.split(chips, ~s|class="pc-combo-box__chip"|)) - 1 == 1
    end

    test ":selected falls back to the placeholder when nothing is chosen" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="sel2" name="sel2" variant="trigger" placeholder="Pick…" options={["A"]}>
          <:selected :let={_chosen}>never</:selected>
        </.combo_box>
        """)

      refute html =~ "pc-combo-box__selected-content"
      assert html =~ "Pick…"
    end

    test ":chip renders one inert template per option for instant client-side rich chips" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="tpl" name="tpl" multiple options={[{"Alpha", "a"}, {"Beta", "b"}]}>
          <:chip :let={opt}><em>{opt.label}</em></:chip>
        </.combo_box>
        """)

      assert length(String.split(html, "data-pc-combo-chip-template")) - 1 == 2
      assert html =~ "<em>Alpha</em>"
      assert html =~ "<em>Beta</em>"

      # no templates without the slot, and none for single select
      plain =
        rendered_to_string(~H"""
        <.combo_box id="np" name="np" multiple options={[{"Alpha", "a"}]} />
        """)

      refute plain =~ "data-pc-combo-chip-template"
    end

    test "the chips container is hook-owned: phx-update ignore with a stable id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="own" name="own" multiple options={[{"Alpha", "a"}]} />
        """)

      assert html =~ ~s|id="own-chips"|
      assert html =~ ~s|phx-update="ignore"|
    end

    test ":chip renders rich chip content with the remove button intact; chips carry data-value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box
          id="ch"
          name="ch"
          multiple
          value={["a"]}
          options={[{"Alpha", "a", color: "sky"}]}
        >
          <:chip :let={opt}>
            <em>{opt.meta[:color]}</em> {opt.label}
          </:chip>
        </.combo_box>
        """)

      assert html =~ "<em>sky</em>"
      assert html =~ ~s|data-value="a"|
      assert html =~ "pc-combo-box__chip-remove"
    end
  end

  test "trigger variant with clearable renders the sibling clear over the rail" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.combo_box id="t" name="who" variant="trigger" clearable value="a" options={[{"A", "a"}]} />
      """)

    assert html =~ "pc-combo-box__trigger-clear"
    assert html =~ "pc-combo-box__trigger--clearable"
    # the clear is a SIBLING, never nested inside the trigger button
    [before_panel, _] = String.split(html, "pc-combo-box__panel", parts: 2)

    assert before_panel =~
             ~r/<\/button>\s*(<!--.*?-->\s*)?<button[^>]*pc-combo-box__trigger-clear/s

    # multiple never renders a trigger clear (the panel toggles are the road back)
    multi =
      rendered_to_string(~H"""
      <.combo_box id="tm" name="who" variant="trigger" clearable multiple options={[{"A", "a"}]} />
      """)

    refute multi =~ "pc-combo-box__trigger-clear"
  end

  describe "M3b modes" do
    test "free_text and create mark the root; create renders the row" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="ft" name="ft" free_text options={["A"]} />
        """)

      assert html =~ ~s|data-free-text="true"|
      refute html =~ "pc-combo-box__create"

      created =
        rendered_to_string(~H"""
        <.combo_box id="cr" name="cr" create create_label="Add" options={["A"]} />
        """)

      assert created =~ ~s|data-free-text="true"|
      assert created =~ "pc-combo-box__create"
      assert created =~ "Add \""
      assert created =~ "data-pc-combo-create-query"
    end

    test "remote mode: event/target attrs, loading row, hook-owned listbox" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box
          id="rm"
          name="rm"
          remote_options_event_name="search"
          remote_options_target="3"
          loading_label="Looking…"
          options={[]}
        />
        """)

      assert html =~ ~s|data-remote-event="search"|
      assert html =~ ~s|data-remote-target="3"|
      assert html =~ "pc-combo-box__loading"
      assert html =~ "Looking…"
      # one writer per region: the hook renders result rows
      assert html =~ ~r/role="listbox"[^>]*phx-update="ignore"/s or
               html =~ ~r/phx-update="ignore"[^>]*role="listbox"/s

      plain =
        rendered_to_string(~H"""
        <.combo_box id="pl" name="pl" options={["A"]} />
        """)

      refute plain =~ "pc-combo-box__loading"
      refute plain =~ ~r/role="listbox"[^>]*phx-update/s
    end
  end

  describe "accessible name" do
    test "label names the visible input, not the wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="c" name="country" label="Country" options={["Australia"]} />
        """)

      # the name has to sit on the role=combobox element itself - the
      # wrapper is a roleless div and naming it names nothing
      assert html =~ ~r/<input[^>]*id="c-input"[^>]*aria-label="Country"/s
      refute html =~ ~r/<div[^>]*id="c"[^>]*aria-label=/s
    end

    test "the trigger anatomy names the button and the panel's search input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box
          id="t"
          name="country"
          variant="trigger"
          label="Country"
          search_placeholder="Find a country…"
          options={["Australia"]}
        />
        """)

      assert html =~ ~r/<button[^>]*aria-label="Country"[^>]*data-pc-combo-trigger/s

      assert html =~ ~r/<input[^>]*id="t-input"[^>]*aria-label="Find a country…"/s
    end

    test "no label leaves no empty aria-label behind" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="c" name="country" options={["Australia"]} />
        """)

      refute html =~ "aria-label=\"\""
    end
  end

  describe "required" do
    test "renders aria-required on the visible combobox and an error region to report into" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="c" name="country" label="Country" required options={["Australia"]} />
        """)

      # the state has to reach the a11y tree: the select carrying it is
      # aria-hidden, so aria-required on the visible control is the only cue
      assert html =~ ~r/<input[^>]*id="c-input"[^>]*aria-required="true"/s
      assert html =~ ~r/<input[^>]*id="c-input"[^>]*aria-describedby="c-error"/s
      assert html =~ ~r/<div[^>]*id="c-error"[^>]*role="alert"[^>]*hidden/s
      assert html =~ "data-pc-combo-error"
      # still the real constraint - the hook only takes over the reporting
      assert html =~ ~r/<select[^>]*required/s
    end

    test "the trigger anatomy carries the same state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="t" name="country" variant="trigger" required options={["Australia"]} />
        """)

      assert html =~ ~r/<button[^>]*aria-required="true"[^>]*data-pc-combo-trigger/s
      assert html =~ ~s|aria-describedby="t-error"|
    end

    test "without required there is no error region and no dangling description" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combo_box id="c" name="country" options={["Australia"]} />
        """)

      refute html =~ "data-pc-combo-error"
      refute html =~ "aria-describedby"
      refute html =~ "aria-required"
    end
  end

  test "a disabled combobox ships no live clear button" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.combo_box id="c" name="city" clearable disabled value="syd" options={[{"Sydney", "syd"}]} />
      """)

    # the clear used to stay tabbable and clickable inside a disabled
    # widget, and clearing it desynced the server (a disabled select posts
    # nothing) - both anatomies disable it now
    assert html =~ ~r/<button[^>]*pc-combo-box__clear[^>]*disabled/s

    trigger =
      rendered_to_string(~H"""
      <.combo_box
        id="t"
        name="city"
        variant="trigger"
        clearable
        disabled
        value="syd"
        options={[{"Sydney", "syd"}]}
      />
      """)

    assert trigger =~ ~r/<button[^>]*pc-combo-box__trigger-clear[^>]*disabled/s
  end

  test "groups expose their heading instead of hiding it" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.combo_box
        id="c"
        name="city"
        options={[{"Oceania", [{"Sydney", "syd"}]}, {"Europe", [{"Lisbon", "lis"}]}]}
      />
      """)

    assert html =~ ~r/role="group"[^>]*aria-label="Oceania"/s
    assert html =~ ~r/role="group"[^>]*aria-label="Europe"/s
    # the heading used to be aria-hidden, so the sections vanished entirely
    refute html =~ ~r/pc-combo-box__group-heading[^>]*aria-hidden/s
  end

  test "the empty row is panel chrome, not a listbox child" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.combo_box id="c" name="city" no_results_text="Nothing here" options={[{"Sydney", "syd"}]} />
      """)

    assert html =~ "Nothing here"
    # a listbox may only contain options and groups; every other chrome
    # region (loading, header, footer) already lives outside it
    [_, after_list] = String.split(html, ~s|role="listbox"|, parts: 2)
    [inside_list, outside_list] = String.split(after_list, "</div>\n", parts: 2)
    refute inside_list =~ "pc-combo-box__empty"
    assert outside_list =~ "pc-combo-box__empty"
  end

  test "max_items carries the cap announcement and the placeholder to restore" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.combo_box
        id="c"
        name="tags"
        multiple
        max_items={2}
        placeholder="Build your stack…"
        max_items_text="That's the lot"
        options={["a", "b", "c"]}
      />
      """)

    assert html =~ ~s|data-max-items="2"|
    assert html =~ ~s|data-max-items-text="That&#39;s the lot"|
    # the hook swaps the placeholder at the cap and restores from here, so
    # a server-rendered placeholder stays the truth
    assert html =~ ~s|data-placeholder-text="Build your stack…"|
  end

  test "raises without any id source" do
    assigns = %{}

    assert_raise ArgumentError, ~r/stable id/, fn ->
      rendered_to_string(~H"""
      <.combo_box options={["Australia"]} />
      """)
    end
  end
end
