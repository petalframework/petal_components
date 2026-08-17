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

  example :availability, "Availability, with the taken days crossed out",
    description:
      "An artist's booking calendar. disabled_dates carries the days already spoken for - a list of Dates here, or a 1-arity function when the rule is computed - and the component blocks the click. Drawing the line through them is the slot's job: the day it hands you carries :disabled, which is the flag the treatment hangs off. The strike also nudges the colour a stop back toward legible, because a line drawn in the component's own disabled gray is a line you squint at." do
    ~H"""
    <.calendar
      id="showcase-calendar-availability"
      month={~D[2026-03-01]}
      value={~D[2026-03-17]}
      disabled_dates={[
        ~D[2026-03-04],
        ~D[2026-03-05],
        ~D[2026-03-12],
        ~D[2026-03-13],
        ~D[2026-03-19],
        ~D[2026-03-25],
        ~D[2026-03-26]
      ]}
    >
      <:day :let={day}>
        <span class={[day.disabled && "line-through text-gray-400 dark:text-gray-500"]}>
          {day.date.day}
        </span>
      </:day>
    </.calendar>
    """
  end

  example :booking, "Booking calendar, prices in the cells",
    description:
      "Two dials, one grid. --pc-calendar-cell-size makes room for a second line and the :day slot fills it. The slot owns the button's content, so the number is yours to render, and the day it hands you carries the flags the content needs: selected softens the price against the inverse chip instead of fighting it, outside keeps the neighbouring month quiet, and the lowest fares pick up the success colour." do
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
              cond do
                day.selected -> "opacity-70"
                Date.day_of_week(day.date) in [5, 6] -> "text-gray-500 dark:text-gray-400"
                true -> "text-success-600 dark:text-success-400"
              end
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

  example :appointments, "The appointment picker, composed",
    description:
      "The whole booking widget, and none of it is a calendar feature. A card holds the header, the grid and its time rail side by side, then a footer that carries what you picked and the button that commits it. The rail is a div with a max height and overflow-y-auto, the slots are buttons, the footer's rule is a border-t you add. The calendar paints no surface of its own, which is what lets it sit inside someone else's." do
    ~H"""
    <.card class="max-w-max">
      <.card_header title="Book your appointment" description="30 minutes, on a video call." />
      <.card_content class="flex flex-col gap-6 sm:flex-row">
        <.calendar
          id="showcase-calendar-appointments"
          month={~D[2026-03-01]}
          value={~D[2026-03-18]}
          disabled_dates={&(Date.day_of_week(&1) in [6, 7])}
        />
        <div class="flex flex-col gap-2 pr-1 overflow-y-auto max-h-56 sm:w-24">
          <.button color="gray" variant="outline" size="sm" label="09:00" />
          <.button color="gray" variant="outline" size="sm" label="09:30" />
          <.button color="gray" variant="outline" size="sm" label="10:00" />
          <.button color="gray" size="sm" label="10:30" />
          <.button color="gray" variant="outline" size="sm" label="11:00" />
          <.button color="gray" variant="outline" size="sm" label="13:30" />
          <.button color="gray" variant="outline" size="sm" label="14:00" />
          <.button color="gray" variant="outline" size="sm" label="14:30" />
        </div>
      </.card_content>
      <.card_footer class="justify-between pt-6 border-t border-gray-200 dark:border-gray-400/17">
        <span class="text-sm text-gray-500 dark:text-gray-400">Wednesday 18 March, 10:30</span>
        <.button size="sm" label="Confirm" />
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
