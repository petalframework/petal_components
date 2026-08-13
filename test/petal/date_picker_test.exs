defmodule PetalComponents.DatePickerTest do
  use ComponentCase

  import PetalComponents.DatePicker

  defp query(html, selector), do: html |> parse_html() |> LazyHTML.query(selector)

  defp attr_of(html, selector, name),
    do: html |> query(selector) |> LazyHTML.attribute(name) |> List.first()

  defp form_field(value, errors \\ []) do
    %Phoenix.HTML.FormField{
      id: "booking_due_on",
      name: "booking[due_on]",
      errors: errors,
      field: :due_on,
      form: %Phoenix.HTML.Form{
        source: %{},
        impl: Phoenix.HTML.FormData.Map,
        id: "booking",
        name: "booking",
        params: %{},
        data: %{}
      },
      value: value
    }
  end

  describe "rendering" do
    test "renders a display input, a toggle and a hidden panel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="due_on" value={~D[2026-03-14]} />
        """)

      assert html =~ "pc-date-picker"
      assert attr_of(html, "#dp", "phx-hook") == "PetalDatePicker"
      assert attr_of(html, "#dp-input", "value") == "2026-03-14"
      assert attr_of(html, "#dp-panel", "style") == "display: none;"
      assert attr_of(html, "#dp-panel", "role") == "dialog"
      assert html =~ "pc-calendar"
    end

    test "renders the label, help text and errors on the field surface" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker
          id="dp"
          name="due_on"
          label="Due date"
          required
          help_text="Pick any weekday."
          errors={["can't be blank"]}
        />
        """)

      assert attr_of(html, "label", "for") == "dp-input"
      assert html =~ "Due date"
      assert html =~ "pc-label--required"
      assert html =~ "Pick any weekday."
      assert html =~ "pc-form-field-error"
      assert html =~ "can&#39;t be blank"
      assert html =~ "pc-form-field-wrapper--error"
    end

    test "the placeholder, disabled state and extra classes land where they should" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="d" placeholder="Pick a date" disabled class="mt-4" data-x="1" />
        """)

      assert attr_of(html, "#dp-input", "placeholder") == "Pick a date"
      assert attr_of(html, "#dp-input", "disabled") == ""
      assert attr_of(html, "#dp-toggle", "disabled") == ""
      assert html =~ "mt-4"
      assert attr_of(html, "#dp", "data-x") == "1"
    end
  end

  describe "what gets posted" do
    test "the hidden input posts ISO 8601 whatever the display format is" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="due_on" value={~D[2026-03-14]} format="%d %b %Y" />
        """)

      assert attr_of(html, "#dp-input", "value") == "14 Mar 2026"
      assert attr_of(html, "[data-pc-date-value]", "value") == "2026-03-14"
      assert attr_of(html, "[data-pc-date-value]", "name") == "due_on"
      # the visible input is display only, so it must never post
      assert attr_of(html, "#dp-input", "name") == nil
    end

    test "an ISO string value is accepted as readily as a Date" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="due_on" value="2026-03-14" />
        """)

      assert attr_of(html, "[data-pc-date-value]", "value") == "2026-03-14"
    end

    test "an unparseable value posts nothing rather than garbage" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="due_on" value="not a date" />
        """)

      assert attr_of(html, "[data-pc-date-value]", "value") == nil
      assert attr_of(html, "#dp-input", "value") == nil
    end

    test "range mode posts from and to sub-fields" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker
          id="dp"
          name="stay"
          mode="range"
          value={{~D[2026-03-09], ~D[2026-03-17]}}
          format="%d %b"
        />
        """)

      assert attr_of(html, "[data-pc-date-from]", "name") == "stay[from]"
      assert attr_of(html, "[data-pc-date-from]", "value") == "2026-03-09"
      assert attr_of(html, "[data-pc-date-to]", "name") == "stay[to]"
      assert attr_of(html, "[data-pc-date-to]", "value") == "2026-03-17"
      assert attr_of(html, "#dp-input", "value") == "09 Mar - 17 Mar"
      assert query(html, "[data-pc-date-value]") |> Enum.empty?()
    end

    test "range mode reads a from/to map, including string keys off a form" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker
          id="dp"
          name="stay"
          mode="range"
          value={%{"from" => "2026-03-09", "to" => "2026-03-17"}}
        />
        """)

      assert attr_of(html, "[data-pc-date-from]", "value") == "2026-03-09"
      assert attr_of(html, "[data-pc-date-to]", "value") == "2026-03-17"
    end

    test "a half-picked range renders the separator and posts only the anchor" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="stay" mode="range" value={{~D[2026-03-09], nil}} />
        """)

      assert attr_of(html, "[data-pc-date-from]", "value") == "2026-03-09"
      assert attr_of(html, "[data-pc-date-to]", "value") == nil
      assert attr_of(html, "#dp-input", "value") == "2026-03-09 - "
    end
  end

  describe "form field integration" do
    test "takes its name, value, id and label from a form field" do
      assigns = %{field: form_field(~D[2026-03-14])}

      html =
        rendered_to_string(~H"""
        <.date_picker field={@field} />
        """)

      assert attr_of(html, "[data-pc-date-value]", "name") == "booking[due_on]"
      assert attr_of(html, "[data-pc-date-value]", "value") == "2026-03-14"
      assert attr_of(html, "#booking_due_on-input", "value") == "2026-03-14"
      assert html =~ "Due on"
    end

    test "renders translated errors only once the input has been used" do
      assigns = %{field: form_field("", [{"can't be blank", []}])}

      html =
        rendered_to_string(~H"""
        <.date_picker field={@field} />
        """)

      # a fresh form field has not been used, so its errors stay quiet
      refute html =~ "can&#39;t be blank"
    end

    test "interpolates error bindings when no translator is configured" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker name="d" errors={["must be after 2026-01-01"]} />
        """)

      assert html =~ "must be after 2026-01-01"
    end
  end

  describe "clearable" do
    test "the clear button shows only when there is a value" do
      assigns = %{}

      with_value =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="d" clearable value={~D[2026-03-14]} />
        """)

      without =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="d" clearable />
        """)

      off =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="d" value={~D[2026-03-14]} />
        """)

      assert Enum.count(query(with_value, "[data-pc-date-clear]")) == 1
      assert Enum.empty?(query(without, "[data-pc-date-clear]"))
      assert Enum.empty?(query(off, "[data-pc-date-clear]"))
    end

    test "on_clear wires the clear button to an event" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="d" clearable value={~D[2026-03-14]} on_clear="clear" target="#x" />
        """)

      assert attr_of(html, "[data-pc-date-clear]", "phx-click") == "clear"
      assert attr_of(html, "[data-pc-date-clear]", "phx-target") == "#x"
    end
  end

  describe "the calendar inside" do
    test "passes the calendar attrs through and opens on the value's month" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker
          id="dp"
          name="d"
          value={~D[2026-03-14]}
          starts_on={7}
          min={~D[2026-03-10]}
          show_outside_days={false}
          on_select="pick"
          on_month_change="page"
        />
        """)

      assert html =~ "March 2026"
      assert attr_of(html, "#dp-calendar", "data-starts-on") == "7"
      assert attr_of(html, "#dp-calendar", "data-select-event") == "pick"
      assert attr_of(html, ~s([data-date="2026-03-09"]), "aria-disabled") == "true"
      assert Enum.empty?(query(html, "[data-outside]"))
    end

    test "two_months renders a second pane on the following month" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="d" mode="range" two_months month={~D[2026-12-01]} />
        """)

      assert Enum.count(query(html, ".pc-calendar")) == 2
      assert html =~ "December 2026"
      assert html =~ "January 2027"
      assert html =~ "pc-date-picker__months--two"

      # One set of arrows across both panes, so paging moves the pair by a month
      assert Enum.count(query(html, "[data-pc-nav]")) == 2
      assert Enum.empty?(query(html, "#dp-calendar-2 [data-pc-nav]"))
    end

    # Two panes are two grids, and roving tabindex is per composite widget, so
    # each keeps its own single tab stop rather than the dialog having one
    # between them. The cost is one extra Tab; the alternative is a right pane
    # you can only reach with a mouse, since arrow keys never cross a pane.
    test "each pane keeps its own single tab stop" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="d" mode="range" two_months month={~D[2026-12-01]} />
        """)

      assert Enum.count(query(html, ~s(#dp-calendar [data-date][tabindex="0"]))) == 1
      assert Enum.count(query(html, ~s(#dp-calendar-2 [data-date][tabindex="0"]))) == 1
    end

    test "one pane by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="d" mode="range" month={~D[2026-12-01]} />
        """)

      assert Enum.count(query(html, ".pc-calendar")) == 1
      refute html =~ "pc-date-picker__months--two"
    end

    test "custom month names reach the calendar" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker
          id="dp"
          name="d"
          month={~D[2026-03-01]}
          month_names={
            ~w(Janvier Fevrier Mars Avril Mai Juin Juillet Aout Septembre Octobre Novembre Decembre)
          }
        />
        """)

      assert html =~ "Mars 2026"
    end
  end

  describe "accessibility and panel wiring" do
    test "the input names the popup and reports its state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="d" open_label="Choose a due date" />
        """)

      assert attr_of(html, "#dp-input", "aria-haspopup") == "dialog"
      assert attr_of(html, "#dp-input", "aria-expanded") == "false"
      assert attr_of(html, "#dp-input", "aria-controls") == "dp-panel"
      assert attr_of(html, "#dp-panel", "aria-label") == "Choose a due date"
      assert attr_of(html, "#dp-toggle", "aria-label") == "Choose a due date"
    end

    # The icon button is the primary pointer target, so it has to report the
    # panel's state too - popover.ex toggles aria-expanded on its trigger for
    # the same reason.
    test "the toggle button reports the panel's state as well as the input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="d" />
        """)

      assert attr_of(html, "#dp-toggle", "aria-expanded") == "false"

      open = attr_of(html, "#dp-toggle", "phx-click")
      assert open =~ "dp-toggle"
      assert open =~ "aria-expanded"

      close = attr_of(html, "#dp", "phx-click-away")
      assert close =~ "dp-toggle"
    end

    test "the clear event reaches the hook so typing an empty box can clear" do
      assigns = %{}

      wired =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="d" on_select="pick" on_clear="wipe" />
        """)

      bare =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="d" on_select="pick" />
        """)

      assert attr_of(wired, "#dp", "data-clear-event") == "wipe"
      assert attr_of(bare, "#dp", "data-clear-event") == nil
    end

    test "Escape closes and click-away dismisses" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="d" />
        """)

      assert attr_of(html, "#dp", "phx-key") == "Escape"
      keydown = attr_of(html, "#dp", "phx-keydown")
      assert keydown =~ "focus"
      assert keydown =~ "dp-input"
      assert attr_of(html, "#dp", "phx-click-away") =~ "dp-panel"
    end

    test "the hook's data contract is on the wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="d" mode="range" format="%d %b %Y" range_separator=" to " />
        """)

      assert attr_of(html, "#dp", "data-mode") == "range"
      assert attr_of(html, "#dp", "data-format") == "%d %b %Y"
      assert attr_of(html, "#dp", "data-range-separator") == " to "
    end

    test "a disabled picker does not wire the input's open click" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="d" disabled />
        """)

      assert attr_of(html, "#dp-input", "phx-click") == nil
    end
  end
end
