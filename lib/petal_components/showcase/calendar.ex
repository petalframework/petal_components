defmodule PetalComponents.Showcase.Calendar do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Calendar, title: "Calendar"

  example :basic, "A month, selected",
    description:
      "A server-rendered month grid on plain Elixir Date. Wire on_select and on_month_change and your handle_event owns the value; leave them off and the nav becomes query-param links that work in a dead view." do
    ~H"""
    <.calendar id="showcase-calendar" value={~D[2026-03-14]} month={~D[2026-03-01]} />
    """
  end

  example :range, "Range selection",
    description:
      "Range mode takes a {from, to} pair. Either side may be nil while a selection is in flight, so the half-picked state renders without a special case." do
    ~H"""
    <.calendar
      id="showcase-calendar-range"
      mode="range"
      value={{~D[2026-03-09], ~D[2026-03-17]}}
      month={~D[2026-03-01]}
    />
    """
  end

  example :multiple, "Multiple days",
    description:
      "Pass a list and every date in it is selected. Handy for availability and recurring-day pickers." do
    ~H"""
    <.calendar
      id="showcase-calendar-multiple"
      mode="multiple"
      value={[~D[2026-03-03], ~D[2026-03-11], ~D[2026-03-25]]}
      month={~D[2026-03-01]}
    />
    """
  end

  example :limits, "Windows and blackout days",
    description:
      "min and max bound the window; disabled_dates takes a list or a function. Disabled days still render and stay focusable, per the APG - they just can't be picked." do
    ~H"""
    <.calendar
      id="showcase-calendar-limits"
      month={~D[2026-03-01]}
      min={~D[2026-03-04]}
      max={~D[2026-03-27]}
      disabled_dates={&(Date.day_of_week(&1) in [6, 7])}
    />
    """
  end

  example :week_start, "Sunday-first, fixed height",
    description:
      "starts_on takes ISO day numbers, so 7 is Sunday. fixed_weeks always draws six rows, which stops the grid jumping height as you page through the year." do
    ~H"""
    <.calendar
      id="showcase-calendar-sunday"
      month={~D[2026-02-01]}
      starts_on={7}
      fixed_weeks
      show_outside_days={false}
    />
    """
  end
end
