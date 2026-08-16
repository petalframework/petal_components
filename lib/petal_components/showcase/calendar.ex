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

  example :booking, "Booking calendar, prices in the cells",
    description:
      "Two dials, one grid. --pc-calendar-cell-size makes room for a second line and the :day slot fills it. The slot owns the button's content, so the number is yours to render, and the day it hands you carries the flags the content needs: selected softens the price against the inverse chip instead of fighting it, outside keeps the neighbouring month quiet." do
    ~H"""
    <.calendar
      id="showcase-calendar-booking"
      mode="range"
      value={{~D[2026-03-09], ~D[2026-03-13]}}
      month={~D[2026-03-01]}
      class="[--pc-calendar-cell-size:3.5rem]"
    >
      <:day :let={day}>
        <span class="flex flex-col items-center gap-0.5 leading-none">
          <span>{day.date.day}</span>
          <span
            :if={!day.outside}
            class={[
              "text-xs",
              if(day.selected, do: "opacity-70", else: "text-gray-500 dark:text-gray-400")
            ]}
          >
            {if Date.day_of_week(day.date) in [5, 6], do: "$320", else: "$240"}
          </span>
        </span>
      </:day>
    </.calendar>
    """
  end

  example :in_card, "Composed into a card",
    description:
      "The calendar paints no background and no padding of its own, so it drops straight into another component's surface. Here it is the body of a card, between the card's own header and footer - no calendar variant required." do
    ~H"""
    <.card class="max-w-max">
      <.card_header title="Book a consultation" description="Weekdays only, 45 minutes." />
      <.card_content>
        <.calendar
          id="showcase-calendar-card"
          month={~D[2026-03-01]}
          value={~D[2026-03-18]}
          disabled_dates={&(Date.day_of_week(&1) in [6, 7])}
        />
      </.card_content>
      <.card_footer>
        <.button size="sm" label="Confirm 18 March" />
      </.card_footer>
    </.card>
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
