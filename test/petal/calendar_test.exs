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
    # The ends of a range are also selected, so the day never needed its own
    # range modifiers - and a class with no rule behind it is dead weight in
    # every consumer's stylesheet.
    test "range ends carry no day-level modifiers the stylesheet does not define" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.calendar month={~D[2026-03-01]} mode="range" value={{~D[2026-03-10], ~D[2026-03-14]}} />
        """)

      assert Enum.empty?(cells(html, ".pc-calendar__day--range-start"))
      assert Enum.empty?(cells(html, ".pc-calendar__day--range-end"))
      assert Enum.count(cells(html, ".pc-calendar__day--selected")) == 5
      assert Enum.count(cells(html, ".pc-calendar__day--in-range")) == 3
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
