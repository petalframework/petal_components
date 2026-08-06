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

      assert single =~ ">Sydney</span>"
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

      assert multi =~ ">2 selected</span>"
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

  test "raises without any id source" do
    assigns = %{}

    assert_raise ArgumentError, ~r/stable id/, fn ->
      rendered_to_string(~H"""
      <.combo_box options={["Australia"]} />
      """)
    end
  end
end
