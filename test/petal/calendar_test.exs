defmodule PetalComponents.CalendarTest do
  use ComponentCase

  import PetalComponents.Calendar

  # Every date here is fixed. A calendar test that leans on Date.utc_today/0 is a
  # test that fails on one day of the year, usually a leap one.
  @march ~D[2026-03-01]

  defp days(html) do
    html |> parse_html() |> LazyHTML.query("[data-date]")
  end

  defp day_isos(html) do
    html |> days() |> Enum.map(&(&1 |> LazyHTML.attribute("data-date") |> List.first()))
  end

  defp rows(html) do
    html |> parse_html() |> LazyHTML.query("tbody tr")
  end

  defp cells(html, selector) do
    html |> parse_html() |> LazyHTML.query(selector)
  end

  describe "rendering" do
    test "renders a month grid with a caption and the ARIA grid roles" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar id="cal" month={~D[2026-03-01]} />
        """)

      assert html =~ ~s(id="cal")
      assert html =~ "pc-calendar"
      assert html =~ ~s(role="grid")
      assert html =~ ~s(role="row")
      assert html =~ ~s(role="gridcell")
      assert html =~ ~s(role="columnheader")
      assert html =~ ~s(aria-labelledby="cal-caption")
      assert html =~ "March 2026"
    end

    test "announces the month in a polite live region" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar id="cal" month={~D[2026-03-01]} />
        """)

      announcer = html |> parse_html() |> LazyHTML.query(".pc-calendar__announcer")

      assert LazyHTML.attribute(announcer, "aria-live") == ["polite"]
      assert LazyHTML.attribute(announcer, "role") == ["status"]
      assert LazyHTML.text(announcer) =~ "March 2026"
    end

    test "passes global attributes and extra classes through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar id="cal" month={~D[2026-03-01]} class="mt-4" data-test="x" />
        """)

      assert html =~ "mt-4"
      assert html =~ ~s(data-test="x")
    end

    test "every day is a real button carrying its ISO date and a full aria-label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar id="cal" month={~D[2026-03-01]} show_outside_days={false} />
        """)

      buttons = html |> parse_html() |> LazyHTML.query("button[data-date]")
      assert Enum.count(buttons) == 31

      first = html |> parse_html() |> LazyHTML.query(~s([data-date="2026-03-01"]))
      assert LazyHTML.attribute(first, "aria-label") == ["1 March 2026"]
      assert LazyHTML.attribute(first, "type") == ["button"]
    end
  end

  describe "month maths" do
    test "a 31-day month starting on a Sunday still fits its own days" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} show_outside_days={false} />
        """)

      isos = day_isos(html)
      assert "2026-03-01" in isos
      assert "2026-03-31" in isos
      assert Enum.count(isos) == 31
    end

    test "February 2024 is a leap February and February 2026 is not" do
      assigns = %{}

      leap =
        rendered_to_string(~H"""
        <.calendar month={~D[2024-02-01]} show_outside_days={false} />
        """)

      plain =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-02-01]} show_outside_days={false} />
        """)

      assert "2024-02-29" in day_isos(leap)
      assert Enum.count(day_isos(leap)) == 29
      refute "2026-02-29" in day_isos(plain)
      assert Enum.count(day_isos(plain)) == 28
    end

    test "December rolls the year over in both directions" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-12-05]} on_month_change="change" />
        """)

      assert html =~ ~s(phx-value-month="2026-11-01")
      assert html =~ ~s(phx-value-month="2027-01-01")

      january =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-01-20]} on_month_change="change" />
        """)

      assert january =~ ~s(phx-value-month="2025-12-01")
      assert january =~ ~s(phx-value-month="2026-02-01")
    end

    test "the grid's first and last week carry the adjacent months' days" do
      assigns = %{}

      # 1 March 2026 is a Sunday, so a Monday-first grid leads with 23 February.
      html =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} />
        """)

      isos = day_isos(html)
      assert List.first(isos) == "2026-02-23"
      assert List.last(isos) == "2026-04-05"
    end

    test "fixed_weeks always renders six rows, off it renders only what is needed" do
      assigns = %{}

      fixed =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-02-01]} fixed_weeks />
        """)

      loose =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-02-01]} />
        """)

      assert Enum.count(rows(fixed)) == 6
      assert Enum.count(rows(loose)) == 5
      assert Enum.count(day_isos(fixed)) == 42
    end

    test "the month defaults to the selected value's month, then to today" do
      assigns = %{}

      from_value =
        rendered_to_string(~H"""
        <.calendar value={~D[2027-07-04]} />
        """)

      assert from_value =~ "July 2027"

      from_today =
        rendered_to_string(~H"""
        <.calendar today={~D[2030-09-09]} />
        """)

      assert from_today =~ "September 2030"
    end
  end

  describe "starts_on" do
    test "Monday-first is the default header order" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} />
        """)

      headers = html |> parse_html() |> LazyHTML.query("th") |> LazyHTML.attribute("abbr")
      assert headers == ~w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)
    end

    test "starts_on rotates the header and the grid together" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} starts_on={7} />
        """)

      headers = html |> parse_html() |> LazyHTML.query("th") |> LazyHTML.attribute("abbr")
      assert headers == ~w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)

      # Sunday-first: 1 March 2026 is itself a Sunday, so the grid starts there.
      assert List.first(day_isos(html)) == "2026-03-01"
    end

    test "every ISO week start renders a seven-column header" do
      for starts_on <- 1..7 do
        assigns = %{starts_on: starts_on}

        html =
          rendered_to_string(~H"""
          <.calendar month={~D[2026-03-01]} starts_on={@starts_on} />
          """)

        headers = html |> parse_html() |> LazyHTML.query("th")
        assert Enum.count(headers) == 7
        assert rem(Enum.count(day_isos(html)), 7) == 0
      end
    end
  end

  describe "selection" do
    test "single mode marks exactly one day aria-selected" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} value={~D[2026-03-14]} />
        """)

      selected = cells(html, ~s(td[aria-selected="true"]))
      assert Enum.count(selected) == 1
      assert html =~ "pc-calendar__day--selected"

      day = cells(html, ~s([data-date="2026-03-14"]))
      assert day |> LazyHTML.attribute("class") |> List.first() =~ "pc-calendar__day--selected"
    end

    test "range mode marks both ends and every day between" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} mode="range" value={{~D[2026-03-10], ~D[2026-03-14]}} />
        """)

      selected = cells(html, ~s(td[aria-selected="true"]))
      assert Enum.count(selected) == 5

      assert Enum.count(cells(html, ".pc-calendar__cell--range-start")) == 1
      assert Enum.count(cells(html, ".pc-calendar__cell--range-end")) == 1
      assert Enum.count(cells(html, ".pc-calendar__cell--in-range")) == 3
    end

    # The band and its rounded ends live on the cell so it runs edge to edge.
    # The chip lives on the button, and only the two ends of the range wear it:
    # a day in the middle is aria-selected but carries no chip class, so the
    # band's continuity is never a specificity argument with dark mode.
    test "only the ends of a range wear the chip; the middle wears the band" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} mode="range" value={{~D[2026-03-10], ~D[2026-03-14]}} />
        """)

      assert Enum.count(cells(html, ".pc-calendar__day--selected")) == 2
      assert Enum.count(cells(html, ".pc-calendar__day--range-start")) == 1
      assert Enum.count(cells(html, ".pc-calendar__day--range-end")) == 1
      assert Enum.count(cells(html, ".pc-calendar__day--in-range")) == 3

      for iso <- ~w(2026-03-11 2026-03-12 2026-03-13) do
        classes = html |> cells(~s([data-date="#{iso}"])) |> LazyHTML.attribute("class")
        refute List.first(classes) =~ "pc-calendar__day--selected"
      end

      assert html
             |> cells(".pc-calendar__day--range-start")
             |> LazyHTML.attribute("data-date") == ["2026-03-10"]

      assert html
             |> cells(".pc-calendar__day--range-end")
             |> LazyHTML.attribute("data-date") == ["2026-03-14"]
    end

    # Nothing to merge into means nothing to square off against: an anchor with
    # no other end, and a range that starts and finishes on the same day, are
    # both a plain chip on a plain cell.
    test "a range with no span carries no band classes on either the cell or the day" do
      for value <- [
            {~D[2026-03-10], nil},
            {nil, ~D[2026-03-10]},
            {~D[2026-03-10], ~D[2026-03-10]}
          ] do
        assigns = %{value: value}

        html =
          rendered_to_string(~H"""
          <.calendar month={~D[2026-03-01]} mode="range" value={@value} />
          """)

        assert Enum.count(cells(html, ".pc-calendar__day--selected")) == 1
        assert Enum.empty?(cells(html, ".pc-calendar__cell--in-range"))
        assert Enum.empty?(cells(html, ".pc-calendar__cell--range-start"))
        assert Enum.empty?(cells(html, ".pc-calendar__cell--range-end"))
        assert Enum.empty?(cells(html, ".pc-calendar__day--range-start"))
        assert Enum.empty?(cells(html, ".pc-calendar__day--range-end"))
      end
    end

    test "range mode accepts a map and orders a backwards pair" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar
          month={~D[2026-03-01]}
          mode="range"
          value={%{from: ~D[2026-03-14], to: ~D[2026-03-10]}}
        />
        """)

      assert Enum.count(cells(html, ~s(td[aria-selected="true"]))) == 5
      start = cells(html, ".pc-calendar__cell--range-start")

      assert start |> LazyHTML.query("[data-date]") |> LazyHTML.attribute("data-date") == [
               "2026-03-10"
             ]
    end

    test "a half-open range renders the anchor and nothing else" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} mode="range" value={{~D[2026-03-10], nil}} />
        """)

      assert Enum.count(cells(html, ~s(td[aria-selected="true"]))) == 1
      assert Enum.empty?(cells(html, ".pc-calendar__cell--in-range"))
    end

    test "multiple mode marks every date in the list" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar
          month={~D[2026-03-01]}
          mode="multiple"
          value={[~D[2026-03-03], ~D[2026-03-11], ~D[2026-03-25]]}
        />
        """)

      assert Enum.count(cells(html, ~s(td[aria-selected="true"]))) == 3
    end

    test "an empty or nil value selects nothing in any mode" do
      assigns = %{}

      for html <- [
            rendered_to_string(~H"""
            <.calendar month={~D[2026-03-01]} />
            """),
            rendered_to_string(~H"""
            <.calendar month={~D[2026-03-01]} mode="range" value={nil} />
            """),
            rendered_to_string(~H"""
            <.calendar month={~D[2026-03-01]} mode="multiple" value={[]} />
            """)
          ] do
        assert Enum.empty?(cells(html, ~s(td[aria-selected="true"])))
      end
    end
  end

  # ---------------------------------------------------------------------------
  # The parity lock, Elixir half.
  #
  # The date picker has a second painter. With a select event wired the server
  # renders every click through build_day/4 below; without one the
  # PetalDatePicker hook paints the same selection in the browser, and for a
  # while it painted the pre-restyle vocabulary - a chip on every day of a
  # range, no band on the cells. Same component, same dates, two pictures.
  #
  # So both halves are held to one file. This test renders the server against
  # test/fixtures/calendar_selection_classes.json; its twin,
  # "PetalDatePicker parity with the server's range anatomy" in
  # test/js/calendar.test.js, runs the hook's painter over the same JSON. A
  # restyle turns both red, which is the point: update the matrix in the fixture
  # first, then make each painter agree with it again.
  # ---------------------------------------------------------------------------
  describe "the class matrix the client hook is held to" do
    @fixture "test/fixtures/calendar_selection_classes.json"

    test "the server renders every scenario in the shared fixture" do
      fixture = @fixture |> File.read!() |> Jason.decode!()

      for scenario <- fixture["scenarios"] do
        matrix = scenario |> render_scenario(fixture) |> selection_matrix(fixture)

        for iso <- Map.keys(scenario["days"]) do
          assert Map.has_key?(matrix, iso),
                 "#{scenario["name"]}: the fixture names #{iso}, the grid does not render it"
        end

        assert matrix == expected_matrix(scenario, Map.keys(matrix)), scenario["name"]
      end
    end
  end

  defp render_scenario(scenario, fixture) do
    assigns = %{
      mode: scenario["mode"],
      month: Date.from_iso8601!(fixture["month"]),
      starts_on: fixture["starts_on"],
      value: scenario_value(scenario)
    }

    rendered_to_string(~H"""
    <.calendar mode={@mode} month={@month} starts_on={@starts_on} value={@value} />
    """)
  end

  defp scenario_value(%{"mode" => "range"} = scenario),
    do: {as_date(scenario["from"]), as_date(scenario["to"])}

  defp scenario_value(scenario), do: as_date(scenario["from"])

  defp as_date(nil), do: nil
  defp as_date(iso), do: Date.from_iso8601!(iso)

  # Every cell in the grid, not just the ones the fixture names: a class left
  # behind on a day outside the range is exactly what this lock is watching for.
  defp selection_matrix(html, fixture) do
    html
    |> parse_html()
    |> LazyHTML.query(~s(td[role="gridcell"]))
    |> Map.new(fn cell ->
      day = LazyHTML.query(cell, "[data-date]")

      {day |> LazyHTML.attribute("data-date") |> List.first(),
       %{
         aria_selected: LazyHTML.attribute(cell, "aria-selected") == ["true"],
         cell: vocabulary_on(cell, fixture["cell_vocabulary"]),
         day: vocabulary_on(day, fixture["day_vocabulary"])
       }}
    end)
  end

  defp vocabulary_on(node, vocabulary) do
    classes = node |> LazyHTML.attribute("class") |> List.first() |> to_string() |> String.split()

    vocabulary |> Enum.filter(&(&1 in classes)) |> Enum.sort()
  end

  defp expected_matrix(scenario, isos) do
    Map.new(isos, fn iso ->
      day = Map.get(scenario["days"], iso, %{"aria_selected" => false, "cell" => [], "day" => []})

      {iso,
       %{
         aria_selected: day["aria_selected"] == true,
         cell: Enum.sort(day["cell"]),
         day: Enum.sort(day["day"])
       }}
    end)
  end

  describe "min, max and disabled dates" do
    test "min and max disable everything outside the window, inclusively" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar
          month={~D[2026-03-01]}
          show_outside_days={false}
          min={~D[2026-03-10]}
          max={~D[2026-03-20]}
        />
        """)

      disabled =
        html
        |> parse_html()
        |> LazyHTML.query(~s([aria-disabled="true"]))
        |> LazyHTML.attribute("data-date")

      assert "2026-03-09" in disabled
      refute "2026-03-10" in disabled
      refute "2026-03-20" in disabled
      assert "2026-03-21" in disabled
    end

    test "a disabled day keeps aria-disabled and loses its click wiring" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar
          month={~D[2026-03-01]}
          min={~D[2026-03-10]}
          on_select="pick"
          show_outside_days={false}
        />
        """)

      day = cells(html, ~s([data-date="2026-03-05"]))
      assert LazyHTML.attribute(day, "aria-disabled") == ["true"]
      assert LazyHTML.attribute(day, "phx-click") == []

      enabled = cells(html, ~s([data-date="2026-03-15"]))
      assert LazyHTML.attribute(enabled, "phx-click") == ["pick"]
    end

    test "disabled_dates takes a list" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar
          month={~D[2026-03-01]}
          disabled_dates={[~D[2026-03-05], ~D[2026-03-06]]}
          show_outside_days={false}
        />
        """)

      disabled =
        html
        |> parse_html()
        |> LazyHTML.query(~s([aria-disabled="true"]))
        |> LazyHTML.attribute("data-date")

      assert disabled == ["2026-03-05", "2026-03-06"]
    end

    test "disabled_dates takes a function" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar
          month={~D[2026-03-01]}
          disabled_dates={&(Date.day_of_week(&1) in [6, 7])}
          show_outside_days={false}
        />
        """)

      disabled =
        html
        |> parse_html()
        |> LazyHTML.query(~s([aria-disabled="true"]))
        |> LazyHTML.attribute("data-date")

      # March 2026 opens on a Sunday: five Sundays, four Saturdays.
      assert Enum.count(disabled) == 9
      assert "2026-03-07" in disabled
      refute "2026-03-09" in disabled
    end
  end

  describe "outside days and today" do
    test "outside days render marked distinctly by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} />
        """)

      outside = cells(html, ~s([data-outside="true"]))
      refute Enum.empty?(outside)
      assert html =~ "pc-calendar__day--outside"
    end

    test "show_outside_days false leaves the cells empty, not the rows short" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} show_outside_days={false} />
        """)

      assert Enum.empty?(cells(html, ~s([data-outside="true"])))
      assert Enum.count(cells(html, "td")) == Enum.count(rows(html)) * 7
    end

    test "today is marked, and can be both today and selected" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} today={~D[2026-03-14]} value={~D[2026-03-14]} />
        """)

      day = cells(html, ~s([data-date="2026-03-14"]))
      assert LazyHTML.attribute(day, "data-today") == ["true"]
      classes = day |> LazyHTML.attribute("class") |> List.first()
      assert classes =~ "pc-calendar__day--today"
      assert classes =~ "pc-calendar__day--selected"
    end
  end

  describe "wiring" do
    test "event mode pushes ISO strings for days and months" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} on_select="pick" on_month_change="page" target="#x" />
        """)

      assert html =~ ~s(phx-click="pick")
      assert html =~ ~s(phx-value-date="2026-03-14")
      assert html =~ ~s(phx-click="page")
      assert html =~ ~s(phx-value-month="2026-02-01")
      assert html =~ ~s(phx-target="#x")
      refute html =~ "<a"
    end

    test "link mode renders patch links carrying the month param" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} month_param="m" />
        """)

      links = html |> parse_html() |> LazyHTML.query("a[data-pc-nav]")
      assert Enum.count(links) == 2
      assert LazyHTML.attribute(links, "href") == ["?m=2026-02-01", "?m=2026-04-01"]
      assert LazyHTML.attribute(links, "data-phx-link") == ["patch", "patch"]
    end

    test "a name turns days into submit buttons that post the ISO date" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} name="booking[date]" show_outside_days={false} />
        """)

      day = cells(html, ~s([data-date="2026-03-14"]))
      assert LazyHTML.attribute(day, "type") == ["submit"]
      assert LazyHTML.attribute(day, "name") == ["booking[date]"]
      assert LazyHTML.attribute(day, "value") == ["2026-03-14"]
    end

    test "on_select wins over name, and disabled days never carry the field name" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar
          month={~D[2026-03-01]}
          name="booking[date]"
          on_select="pick"
          show_outside_days={false}
        />
        """)

      day = cells(html, ~s([data-date="2026-03-14"]))
      assert LazyHTML.attribute(day, "type") == ["button"]
      assert LazyHTML.attribute(day, "name") == []
    end

    test "nav picks which arrows render, and spaces the gap so the caption stays centred" do
      assigns = %{}

      both =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} />
        """)

      prev_only =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} nav="prev" />
        """)

      none =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} nav="none" />
        """)

      assert Enum.count(cells(both, "[data-pc-nav]")) == 2
      assert Enum.empty?(cells(both, ".pc-calendar__nav-spacer"))

      assert cells(prev_only, "[data-pc-nav]") |> LazyHTML.attribute("data-pc-nav") == ["prev"]
      assert Enum.count(cells(prev_only, ".pc-calendar__nav-spacer")) == 1

      assert Enum.empty?(cells(none, "[data-pc-nav]"))
      assert Enum.count(cells(none, ".pc-calendar__nav-spacer")) == 2
    end

    test "the hook and its data contract are on the wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar id="cal" month={~D[2026-03-01]} starts_on={7} on_select="pick" />
        """)

      root = html |> parse_html() |> LazyHTML.query("#cal")
      assert LazyHTML.attribute(root, "phx-hook") == ["PetalCalendar"]
      assert LazyHTML.attribute(root, "data-month") == ["2026-03-01"]
      assert LazyHTML.attribute(root, "data-starts-on") == ["7"]
      assert LazyHTML.attribute(root, "data-select-event") == ["pick"]
      assert root |> LazyHTML.attribute("data-month-names") |> List.first() =~ "January,February"

      assert root |> LazyHTML.attribute("data-day-names-long") |> List.first() =~
               "Monday,Tuesday"
    end

    # The hook clamps keyboard paging to the same window the server disables
    # days with, so it needs the window itself, not just the result of it.
    test "the min and max window reaches the hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar id="cal" month={~D[2026-03-01]} min={~D[2026-03-05]} max={~D[2026-03-20]} />
        """)

      root = html |> parse_html() |> LazyHTML.query("#cal")
      assert LazyHTML.attribute(root, "data-min") == ["2026-03-05"]
      assert LazyHTML.attribute(root, "data-max") == ["2026-03-20"]
    end

    test "no window means no attributes to clamp against" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar id="cal" month={~D[2026-03-01]} min={false} />
        """)

      root = html |> parse_html() |> LazyHTML.query("#cal")
      assert LazyHTML.attribute(root, "data-min") == []
      assert LazyHTML.attribute(root, "data-max") == []
    end
  end

  describe "roving tabindex" do
    test "exactly one day is tabbable, and it is the selected one" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} value={~D[2026-03-14]} />
        """)

      tabbable = cells(html, ~s([data-date][tabindex="0"]))
      assert Enum.count(tabbable) == 1
      assert LazyHTML.attribute(tabbable, "data-date") == ["2026-03-14"]
    end

    test "with no selection it falls to today, then to the first enabled day" do
      assigns = %{}

      today =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} today={~D[2026-03-20]} />
        """)

      assert today |> cells(~s([data-date][tabindex="0"])) |> LazyHTML.attribute("data-date") ==
               ["2026-03-20"]

      neither =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} today={~D[2030-01-01]} min={~D[2026-03-09]} />
        """)

      assert neither |> cells(~s([data-date][tabindex="0"])) |> LazyHTML.attribute("data-date") ==
               ["2026-03-09"]

      assert Enum.count(cells(neither, ~s([data-date][tabindex="-1"]))) ==
               Enum.count(day_isos(neither)) - 1
    end
  end

  describe "the :day slot" do
    # The whole promise of the slot is that not using it costs nothing. This
    # renders every shape the grid can take, with and without an empty slot
    # list in play, and demands the markup match to the byte.
    test "no slot renders exactly what the component rendered before it existed" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar
          id="cal"
          mode="range"
          month={~D[2026-03-01]}
          value={{~D[2026-03-09], ~D[2026-03-17]}}
          today={~D[2026-03-14]}
          min={~D[2026-03-04]}
          on_select="pick"
        />
        """)

      # The bare number, its surrounding whitespace and the closing tag: the
      # exact text an added conditional around the content would disturb.
      assert html =~ ~s(phx-value-date="2026-03-14">\n  14\n</button>)
      assert html =~ ~s(phx-value-date="2026-03-01">\n  1\n</button>)
      assert Enum.empty?(cells(html, ".pc-calendar__day *"))
      assert Enum.count(days(html)) == 42
    end

    test "the slot replaces the number, and the day it receives carries the flags" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar id="cal" month={~D[2026-03-01]} value={~D[2026-03-14]} today={~D[2026-03-20]}>
          <:day :let={day}>
            <span class="num">{day.date.day}</span>
            <span class="iso">{day.iso}</span>
            <span :if={day.selected} class="flag">selected</span>
            <span :if={day.today} class="flag">today</span>
            <span :if={day.outside} class="flag">outside</span>
          </:day>
        </.calendar>
        """)

      selected = cells(html, ~s([data-date="2026-03-14"]))
      assert LazyHTML.text(selected) =~ "14"
      assert LazyHTML.text(selected) =~ "2026-03-14"
      assert selected |> LazyHTML.query(".flag") |> LazyHTML.text() == "selected"

      assert html |> cells(~s([data-date="2026-03-20"] .flag)) |> LazyHTML.text() == "today"
      assert html |> cells(~s([data-date="2026-02-23"] .flag)) |> LazyHTML.text() == "outside"

      # Every rendered day went through the slot, the number included.
      assert Enum.count(cells(html, ".num")) == Enum.count(days(html))
    end

    test "the slot changes the content and nothing else about the button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar
          id="cal"
          mode="range"
          month={~D[2026-03-01]}
          value={{~D[2026-03-10], ~D[2026-03-14]}}
          today={~D[2026-03-10]}
          min={~D[2026-03-04]}
          on_select="pick"
        >
          <:day :let={day}>
            <span class="price">${day.date.day}0</span>
          </:day>
        </.calendar>
        """)

      # State classes, wiring and the roving tabindex are still the
      # component's; the slot only ever filled the button in.
      assert Enum.count(cells(html, ".pc-calendar__day--selected")) == 2
      assert Enum.count(cells(html, ".pc-calendar__day--in-range")) == 3
      assert Enum.count(cells(html, ".pc-calendar__cell--in-range")) == 3
      assert Enum.count(cells(html, ".pc-calendar__day--today")) == 1
      assert Enum.count(cells(html, ~s([data-date][tabindex="0"]))) == 1

      day = cells(html, ~s([data-date="2026-03-14"]))
      assert LazyHTML.attribute(day, "phx-click") == ["pick"]
      assert LazyHTML.attribute(day, "phx-value-date") == ["2026-03-14"]

      disabled = cells(html, ~s([data-date="2026-03-02"]))
      assert LazyHTML.attribute(disabled, "aria-disabled") == ["true"]
      assert disabled |> LazyHTML.query(".price") |> LazyHTML.text() == "$20"
    end

    # The visual layer is the slot's; the accessible name is not. A screen
    # reader still hears the date, never the price under it.
    test "aria-label stays the full date whatever the slot renders" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar id="cal" month={~D[2026-03-01]} show_outside_days={false}>
          <:day :let={day}>
            <span>{day.date.day}</span>
            <span>$240</span>
          </:day>
        </.calendar>
        """)

      day = cells(html, ~s([data-date="2026-03-14"]))
      assert LazyHTML.attribute(day, "aria-label") == ["14 March 2026"]
      assert LazyHTML.text(day) =~ "$240"
    end
  end

  describe "cell size token" do
    @css File.read!(Path.expand("../../assets/default.css", __DIR__))

    test "the day, the weekday header and the nav all size off one token" do
      # The grid only stays in register at a custom cell size if the day
      # button and the column header read the SAME property. A hardcoded w-9
      # left behind on either one is a header that no longer lines up with the
      # days under it.
      assert @css =~
               ~r/\.pc-calendar__day \{[^}]*width: var\(--pc-calendar-cell-size, 2\.25rem\)/s

      assert @css =~
               ~r/\.pc-calendar__day \{[^}]*height: var\(--pc-calendar-cell-size, 2\.25rem\)/s

      assert @css =~
               ~r/\.pc-calendar__weekday \{[^}]*width: var\(--pc-calendar-cell-size, 2\.25rem\)/s

      for selector <- ~w(.pc-calendar__nav .pc-calendar__nav-spacer) do
        assert @css =~ ~r/#{Regex.escape(selector)} \{[^}]*width: var\(--pc-calendar-nav-size\)/s
      end

      # Nothing sizes a day the old hardcoded way any more.
      refute @css =~ ~r/\.pc-calendar__(day|weekday|nav|nav-spacer) \{[^}]*@apply[^;]*\bw-\d/s
    end

    test "the token is read with a fallback, never declared on the calendar root" do
      # Declaring the default on .pc-calendar would shadow a value set on a
      # wrapper, which is one of the two documented ways to set it.
      root = Regex.run(~r/\.pc-calendar \{(.*?)\}/s, @css) |> Enum.at(1)

      refute root =~ ~r/--pc-calendar-cell-size\s*:/
      assert root =~ "--pc-calendar-nav-size:"
      assert root =~ "var(--pc-calendar-cell-size, 2.25rem)"
    end

    test "a consumer's arbitrary-property class rides through to the wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar id="cal" month={~D[2026-03-01]} class="[--pc-calendar-cell-size:3.5rem]" />
        """)

      root = html |> parse_html() |> LazyHTML.query("#cal")
      classes = root |> LazyHTML.attribute("class") |> List.first()
      assert classes =~ "pc-calendar"
      assert classes =~ "[--pc-calendar-cell-size:3.5rem]"
    end
  end

  describe "labels" do
    test "day and month names are plain attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar
          month={~D[2026-03-01]}
          day_names={~w(Lu Ma Me Je Ve Sa Di)}
          day_names_long={~w(Lundi Mardi Mercredi Jeudi Vendredi Samedi Dimanche)}
          month_names={
            ~w(Janvier Fevrier Mars Avril Mai Juin Juillet Aout Septembre Octobre Novembre Decembre)
          }
        />
        """)

      assert html =~ "Mars 2026"
      assert html =~ "Lu"
      assert html =~ "Lundi"
      assert html =~ ~s(aria-label="1 Mars 2026")
    end

    test "a short label list falls back to English in the holes rather than rendering blanks" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} day_names={~w(Lu Ma)} />
        """)

      headers = html |> parse_html() |> LazyHTML.query("th") |> LazyHTML.attribute("abbr")
      assert Enum.count(headers) == 7
      assert html =~ "Lu"
      assert html =~ "We"
    end

    test "the nav buttons carry overridable accessible labels" do
      assigns = %{month: @march}

      html =
        rendered_to_string(~H"""
        <.calendar month={@month} prev_label="Mois precedent" next_label="Mois suivant" />
        """)

      assert html =~ ~s(aria-label="Mois precedent")
      assert html =~ ~s(aria-label="Mois suivant")
    end
  end
end
