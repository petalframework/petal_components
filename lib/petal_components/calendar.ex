defmodule PetalComponents.Calendar do
  use Phoenix.Component

  import PetalComponents.Icon

  @default_day_names ~w(Mo Tu We Th Fr Sa Su)
  @default_month_names ~w(January February March April May June July August September October November December)
  @default_day_names_long ~w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)

  @moduledoc """
  A server-rendered month grid built on Elixir's `Date`. No time, no timezone,
  no DateTime: values in and out are `%Date{}` and anything posted is ISO 8601.

  The grid follows the WAI-ARIA grid pattern. Every day is a real `<button>`, so
  Tab plus Enter works with JavaScript disabled; the `PetalCalendar` hook layers
  roving tabindex and the arrow-key map on top.

  ## Two wirings

  With `on_select` and `on_month_change` set, days and nav buttons push events
  carrying ISO strings:

      <.calendar
        id="due-date"
        value={@due_on}
        month={@month}
        on_select="pick_date"
        on_month_change="change_month"
      />

      def handle_event("pick_date", %{"date" => iso}, socket) do
        {:ok, date} = Date.from_iso8601(iso)
        {:noreply, assign(socket, due_on: date)}
      end

      def handle_event("change_month", %{"month" => iso}, socket) do
        {:ok, month} = Date.from_iso8601(iso)
        {:noreply, assign(socket, month: month)}
      end

  With them left `nil`, month navigation renders as patch links carrying
  `month_param`, which works in a dead view as a plain query-string link:

      <.calendar month={@month} value={@value} month_param="month" name="booking[date]" />

  Give it a `name` and each day becomes a submit button, so a form wrapping the
  calendar posts the clicked ISO date with no JavaScript at all.

  ## Selection modes

      <.calendar mode="single" value={~D[2026-03-14]} />
      <.calendar mode="range" value={{~D[2026-03-10], ~D[2026-03-17]}} />
      <.calendar mode="multiple" value={[~D[2026-03-03], ~D[2026-03-09]]} />

  In range mode either side may be `nil` while a selection is in flight, so a
  half-open `{~D[2026-03-10], nil}` renders the anchor day and nothing else.

  ## Limiting what can be picked

      <.calendar
        min={Date.utc_today()}
        max={Date.add(Date.utc_today(), 30)}
        disabled_dates={&(Date.day_of_week(&1) in [6, 7])}
      />

  `disabled_dates` takes a list of dates or a 1-arity function. Disabled days
  still render and stay focusable (per the APG), they just cannot be selected.

  ## Today, and timezones

  `today` defaults to `Date.utc_today/0`. A `%Date{}` has no timezone, so the
  component never converts one for you. If your users are not on UTC, pass the
  date you consider today:

      <.calendar today={DateTime.to_date(DateTime.shift_zone!(DateTime.utc_now(), @tz))} />

  ## Localisation

  There is no date-localisation dependency here. Day and month names are plain
  attrs, so wire them to gettext yourself:

      <.calendar
        day_names={Enum.map(~w(Mon Tue Wed Thu Fri Sat Sun), &gettext("day_short_%{d}", d: &1))}
        month_names={for m <- 1..12, do: Gettext.gettext(MyApp.Gettext, month_key(m))}
      />

  `day_names` is always ordered Monday-first; the component rotates it to match
  `starts_on`.

  ## Cell size

  Day cells are square, and one CSS custom property sizes them:
  `--pc-calendar-cell-size`, default `2.25rem`. Set it on the calendar or on
  anything above it and the days, the weekday headers and the month-nav arrows
  all move together, so the grid stays in register:

      <.calendar class="[--pc-calendar-cell-size:3rem]" />

      <div style="--pc-calendar-cell-size: 4rem">
        <.calendar />
      </div>

  There is deliberately no `size` attr. The token is the API, the way
  `--pc-radius` is for corners: one dial, set wherever you already set classes,
  with no new attr values to learn or version. Being a class, it takes
  breakpoint variants like any other - big cells cannot fit seven columns on a
  phone, so a booking grid steps its size:

      <.calendar class="[--pc-calendar-cell-size:2.75rem] sm:[--pc-calendar-cell-size:3.5rem]" />

  ## Custom day content

  The `:day` slot replaces the content of every day button. The classic case is
  a booking grid with a price under each date, which is a cell size and a slot
  together:

      <.calendar mode="range" value={@stay} class="[--pc-calendar-cell-size:3.5rem]">
        <:day :let={day}>
          <span class="flex flex-col items-center gap-0.5 leading-none">
            <span>{day.date.day}</span>
            <span :if={!day.outside} class={["text-xs", !day.selected && "text-gray-500"]}>
              {price_for(day.date)}
            </span>
          </span>
        </:day>
      </.calendar>

  The slot owns the whole content of the button, so **you render the number**.
  It receives the day the component already built:

    * `:date` - the `%Date{}`
    * `:iso` - that date as an ISO 8601 string
    * `:today`, `:outside`, `:disabled`, `:selected` - booleans
    * `:range_start`, `:range_middle`, `:range_end` - booleans, range mode

  The button itself is untouched: the selection chip, the range band, the today
  dot and the disabled treatment are still the component's job, and the
  `aria-label` is still the full date. The slot is what a sighted user sees
  inside the button, not what a screen reader is told it is. Use `:selected`
  to keep a muted second line readable once the inverse chip lands under it.
  """

  @doc """
  Renders a month grid. See the module docs above for the two wiring modes, the
  selection shapes each `mode` accepts, and the gettext recipe for day and month
  names.

      <.calendar value={@due_on} month={@month} on_select="pick" on_month_change="page" />
  """

  attr :id, :string, doc: "the calendar id; autogenerated if not set"

  attr :mode, :string,
    default: "single",
    values: ~w(single range multiple),
    doc: "selection behaviour"

  attr :value, :any,
    default: nil,
    doc:
      "the selection: a Date (single), a {from, to} tuple or a map with :from/:to (range, either side may be nil mid-selection), or a list of Dates (multiple)"

  attr :month, :any,
    default: nil,
    doc:
      "the displayed month as any Date within it; defaults to the selected value's month, else today"

  attr :min, :any, default: nil, doc: "earliest selectable Date (inclusive)"
  attr :max, :any, default: nil, doc: "latest selectable Date (inclusive)"

  attr :disabled_dates, :any,
    default: nil,
    doc:
      "a list of Dates, or a 1-arity function Date -> boolean; disabled days render but are not selectable"

  attr :today, :any,
    default: nil,
    doc:
      "the date treated as today; defaults to Date.utc_today/0. Pass the user's local date if UTC is not good enough"

  attr :starts_on, :integer,
    default: 1,
    values: [1, 2, 3, 4, 5, 6, 7],
    doc: "first day of the week, ISO day numbers (1 = Monday, 7 = Sunday)"

  attr :show_outside_days, :boolean,
    default: true,
    doc: "render leading/trailing days from adjacent months"

  attr :fixed_weeks, :boolean,
    default: false,
    doc: "always render 6 week rows so the grid height never jumps"

  attr :day_names, :list,
    default: @default_day_names,
    doc: "7 short day labels ordered Monday-first; default English"

  attr :month_names, :list, default: @default_month_names, doc: "12 month labels; default English"

  attr :day_names_long, :list,
    default: @default_day_names_long,
    doc: "7 full day labels ordered Monday-first, used for screen readers; default English"

  attr :on_select, :any,
    default: nil,
    doc: "event name pushed when a day is clicked; the payload carries the ISO date"

  attr :on_month_change, :any,
    default: nil,
    doc:
      "event name for prev/next month; when nil, nav renders as patch links using the month_param query param"

  attr :target, :any,
    default: nil,
    doc:
      "phx-target for the select and month-change events; set it to @myself when the calendar lives inside a LiveComponent"

  attr :month_param, :string,
    default: "month",
    doc: "query param used for link-based month navigation"

  attr :name, :any,
    default: nil,
    doc:
      "when set (and no on_select), day buttons submit this form field with the ISO date as value"

  attr :nav, :string,
    default: "both",
    values: ~w(both prev next none),
    doc:
      "which month-nav arrows to render; two side-by-side panes want prev on the left pane and next on the right"

  attr :prev_label, :string,
    default: "Previous month",
    doc: "accessible label for the prev button"

  attr :next_label, :string, default: "Next month", doc: "accessible label for the next button"
  attr :class, :any, default: nil, doc: "extra classes for the calendar wrapper"
  attr :rest, :global

  slot :day,
    doc:
      "content for every day button, in place of the bare number - render the number yourself. Receives the day: :date (a Date), :iso, and the :today, :outside, :disabled, :selected, :range_start, :range_middle and :range_end flags. Pair it with a bigger --pc-calendar-cell-size when the content needs a second line"

  def calendar(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> "calendar_#{Ecto.UUID.generate()}" end)
      |> assign(:today, assigns.today || Date.utc_today())
      |> normalise()

    ~H"""
    <div
      id={@id}
      class={["pc-calendar", @class]}
      phx-hook="PetalCalendar"
      data-mode={@mode}
      data-month={Date.to_iso8601(@month_start)}
      data-starts-on={@starts_on}
      data-select-event={@on_select}
      data-month-names={Enum.join(@month_names, ",")}
      data-day-names-long={Enum.join(@day_names_long, ",")}
      data-min={iso_attr(@min)}
      data-max={iso_attr(@max)}
      {@rest}
    >
      <div class="pc-calendar__header">
        <.month_nav
          :if={@nav in ~w(both prev)}
          direction="prev"
          month={@prev_month}
          label={@prev_label}
          icon="hero-chevron-left"
          on_month_change={@on_month_change}
          target={@target}
          month_param={@month_param}
        />
        <div :if={@nav not in ~w(both prev)} class="pc-calendar__nav-spacer" aria-hidden="true"></div>
        <div class="pc-calendar__caption" id={"#{@id}-caption"}>{@caption}</div>
        <.month_nav
          :if={@nav in ~w(both next)}
          direction="next"
          month={@next_month}
          label={@next_label}
          icon="hero-chevron-right"
          on_month_change={@on_month_change}
          target={@target}
          month_param={@month_param}
        />
        <div :if={@nav not in ~w(both next)} class="pc-calendar__nav-spacer" aria-hidden="true"></div>
      </div>

      <div class="pc-calendar__announcer" aria-live="polite" role="status">{@caption}</div>

      <table role="grid" aria-labelledby={"#{@id}-caption"} class="pc-calendar__grid">
        <thead class="pc-calendar__head">
          <tr role="row">
            <th
              :for={{short, long} <- @weekday_labels}
              role="columnheader"
              scope="col"
              abbr={long}
              class="pc-calendar__weekday"
            >
              <span aria-hidden="true">{short}</span>
              <span class="sr-only">{long}</span>
            </th>
          </tr>
        </thead>
        <tbody class="pc-calendar__body">
          <tr :for={week <- @weeks} role="row" class="pc-calendar__week">
            <td
              :for={day <- week}
              role="gridcell"
              aria-selected={day.selected && "true"}
              class={[
                "pc-calendar__cell",
                day.range_middle && "pc-calendar__cell--in-range",
                day.band_start && "pc-calendar__cell--range-start",
                day.band_end && "pc-calendar__cell--range-end"
              ]}
            >
              <.day
                :if={!day.hidden}
                day={day}
                day_slot={@day}
                on_select={@on_select}
                target={@target}
                name={@name}
              />
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr :direction, :string, required: true
  attr :month, :any, required: true
  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :on_month_change, :any, required: true
  attr :target, :any, required: true
  attr :month_param, :string, required: true

  defp month_nav(assigns) do
    assigns = assign(assigns, :iso, Date.to_iso8601(assigns.month))

    ~H"""
    <button
      :if={@on_month_change}
      type="button"
      class="pc-calendar__nav"
      data-pc-nav={@direction}
      phx-click={@on_month_change}
      phx-target={@target}
      phx-value-month={@iso}
      aria-label={@label}
    >
      <.icon name={@icon} class="pc-calendar__nav-icon" />
    </button>
    <.link
      :if={!@on_month_change}
      patch={"?#{URI.encode_query(%{@month_param => @iso})}"}
      class="pc-calendar__nav"
      data-pc-nav={@direction}
      aria-label={@label}
    >
      <.icon name={@icon} class="pc-calendar__nav-icon" />
    </.link>
    """
  end

  # The :day slot changes the button's CONTENT and nothing else. Every state
  # class (chip, band, today, disabled), the wiring and the aria-label are
  # still decided here, so a custom cell cannot accidentally opt out of them -
  # and an empty slot renders exactly the bare number it always did.
  #
  # What it receives is the day map the grid already built. It carries the
  # flags a custom cell actually needs (:selected to survive the inverse chip,
  # :outside to stay quiet, :disabled to grey out) and building a second,
  # narrower struct per day would cost 42 allocations a render to hide keys
  # nobody is hurt by seeing.
  attr :day, :map, required: true
  attr :day_slot, :any, required: true
  attr :on_select, :any, required: true
  attr :target, :any, required: true
  attr :name, :any, required: true

  defp day(assigns) do
    assigns =
      assign(assigns,
        type: day_type(assigns),
        classes: day_classes(assigns.day)
      )

    ~H"""
    <button
      type={@type}
      class={@classes}
      data-date={@day.iso}
      data-disabled={@day.disabled && "true"}
      data-outside={@day.outside && "true"}
      data-today={@day.today && "true"}
      tabindex={@day.tabindex}
      aria-label={@day.aria_label}
      aria-disabled={@day.disabled && "true"}
      name={!@day.disabled && @type == "submit" && @name}
      value={@type == "submit" && @day.iso}
      phx-click={!@day.disabled && @on_select}
      phx-target={@on_select && @target}
      phx-value-date={@on_select && @day.iso}
    >
      {if @day_slot == [], do: @day.date.day, else: render_slot(@day_slot, @day)}
    </button>
    """
  end

  # A day is a submit button only when nothing else claims the click: an event
  # wiring wins, and without one a `name` is what makes a dead-view form post.
  defp day_type(%{on_select: nil, name: name}) when name not in [nil, false], do: "submit"
  defp day_type(_assigns), do: "button"

  # The band is on the cell, so it runs edge to edge between days; the chip is on
  # the button. They are different jobs and get different classes: the two ends
  # of a range wear the chip, the days between them wear the band and nothing
  # else. A range-middle day is still `aria-selected`, but it deliberately does
  # not get `--selected` - painting a chip and then painting it out again put the
  # two rules in a specificity fight that `dark:` won, which is how every day in
  # a dark-mode range ended up as its own rounded box.
  #
  # `band_start` / `band_end` are the ends of a band that actually spans, so a
  # half-open range (or a one-day one) stays a plain chip with nothing to merge
  # into, and only a real band asks its ends to square off on the inward side.
  @day_flags [
    {:outside, "pc-calendar__day--outside"},
    {:today, "pc-calendar__day--today"},
    {:chip, "pc-calendar__day--selected"},
    {:band_start, "pc-calendar__day--range-start"},
    {:band_end, "pc-calendar__day--range-end"},
    {:disabled, "pc-calendar__day--disabled"},
    {:range_middle, "pc-calendar__day--in-range"}
  ]

  defp day_classes(day) do
    ["pc-calendar__day" | for({flag, class} <- @day_flags, Map.fetch!(day, flag), do: class)]
  end

  # ----------------------------------------------------------------------------
  # Date maths. Everything below is plain Elixir Date arithmetic - no sigils in
  # the hot path, no external libraries, and nothing that touches a timezone.
  # ----------------------------------------------------------------------------

  defp normalise(assigns) do
    # Pad once, up front: every downstream reader (the caption, the aria labels,
    # the column headers and the data attrs the hook parses) then sees a full
    # list, so a caller who passes six day names gets English in the hole rather
    # than an empty column header or a truncated hook contract.
    assigns =
      assigns
      |> assign(:month_names, pad(assigns.month_names, @default_month_names, 12))
      |> assign(:day_names, pad(assigns.day_names, @default_day_names, 7))
      |> assign(:day_names_long, pad(assigns.day_names_long, @default_day_names_long, 7))

    selection = selection(assigns.mode, assigns.value)
    month_start = month_start(assigns.month, selection, assigns.today)
    weeks = month_start |> build_weeks(assigns) |> assign_tabindex()

    assign(assigns,
      month_start: month_start,
      prev_month: shift_month(month_start, -1),
      next_month: shift_month(month_start, 1),
      caption: caption(month_start, assigns.month_names),
      weekday_labels:
        weekday_labels(assigns.day_names, assigns.day_names_long, assigns.starts_on),
      weeks: weeks
    )
  end

  # The selection normalises to {:single, date | nil} | {:range, from, to} |
  # {:multiple, [date]} so every downstream check is a straight comparison.
  defp selection("single", %Date{} = date), do: {:single, date}
  defp selection("single", _), do: {:single, nil}
  defp selection("range", {from, to}), do: {:range, as_date(from), as_date(to)}
  defp selection("range", %{from: from, to: to}), do: {:range, as_date(from), as_date(to)}
  defp selection("range", %Date{} = date), do: {:range, date, nil}
  defp selection("range", _), do: {:range, nil, nil}

  defp selection("multiple", dates) when is_list(dates),
    do: {:multiple, Enum.filter(dates, &date?/1)}

  defp selection("multiple", %Date{} = date), do: {:multiple, [date]}
  defp selection("multiple", _), do: {:multiple, []}

  defp as_date(%Date{} = date), do: date
  defp as_date(_), do: nil

  defp date?(%Date{}), do: true
  defp date?(_), do: false

  defp month_start(%Date{} = month, _selection, _today), do: Date.beginning_of_month(month)
  defp month_start(_, {:single, %Date{} = date}, _today), do: Date.beginning_of_month(date)
  defp month_start(_, {:range, %Date{} = from, _to}, _today), do: Date.beginning_of_month(from)
  defp month_start(_, {:range, nil, %Date{} = to}, _today), do: Date.beginning_of_month(to)

  defp month_start(_, {:multiple, [%Date{} = date | _]}, _today),
    do: Date.beginning_of_month(date)

  defp month_start(_, _selection, today), do: Date.beginning_of_month(today)

  # Month arithmetic without a dependency: land on the first of the month, then
  # walk a day either side of the boundary. Handles December -> January (and the
  # year with it) and never lands on a day-of-month the target month lacks.
  defp shift_month(%Date{} = date, -1) do
    date |> Date.beginning_of_month() |> Date.add(-1) |> Date.beginning_of_month()
  end

  defp shift_month(%Date{} = date, 1) do
    date |> Date.end_of_month() |> Date.add(1)
  end

  defp build_weeks(month_start, assigns) do
    selection = selection(assigns.mode, assigns.value)
    last = Date.end_of_month(month_start)

    # ISO day-of-week is 1 (Monday) .. 7 (Sunday). Rotating by starts_on is pure
    # modular arithmetic, so every one of the seven values works.
    offset = rem(Date.day_of_week(month_start) - assigns.starts_on + 7, 7)
    grid_start = Date.add(month_start, -offset)

    rows =
      if assigns.fixed_weeks do
        6
      else
        ceil((offset + last.day) / 7)
      end

    0..(rows * 7 - 1)
    |> Enum.map(&Date.add(grid_start, &1))
    |> Enum.map(&build_day(&1, month_start, selection, assigns))
    |> Enum.chunk_every(7)
  end

  defp build_day(date, month_start, selection, assigns) do
    outside = date.month != month_start.month or date.year != month_start.year
    {range_start, range_middle, range_end} = range_position(date, selection)
    banded = banded?(selection)
    selected = selected?(date, selection)

    %{
      date: date,
      iso: Date.to_iso8601(date),
      outside: outside,
      hidden: outside and not assigns.show_outside_days,
      today: Date.compare(date, assigns.today) == :eq,
      disabled: disabled?(date, assigns),
      selected: selected,
      chip: selected and not range_middle,
      range_start: range_start,
      range_middle: range_middle,
      range_end: range_end,
      band_start: banded and range_start,
      band_end: banded and range_end,
      aria_label: aria_label(date, assigns.month_names),
      tabindex: "-1"
    }
  end

  # A band only exists once both ends are in and they are different days. Until
  # then the anchor is just a selected day, so it keeps all four corners.
  defp banded?({:range, %Date{} = from, %Date{} = to}), do: Date.compare(from, to) != :eq
  defp banded?(_selection), do: false

  defp selected?(date, {:single, %Date{} = selected}), do: Date.compare(date, selected) == :eq
  defp selected?(_date, {:single, nil}), do: false
  defp selected?(date, {:multiple, dates}), do: Enum.any?(dates, &(Date.compare(date, &1) == :eq))

  defp selected?(date, {:range, _from, _to} = range) do
    {a, b, c} = range_position(date, range)
    a or b or c
  end

  defp range_position(date, {:range, %Date{} = from, %Date{} = to}) do
    {first, last} = if Date.compare(from, to) == :gt, do: {to, from}, else: {from, to}

    {Date.compare(date, first) == :eq, Date.after?(date, first) and Date.before?(date, last),
     Date.compare(date, last) == :eq}
  end

  defp range_position(date, {:range, %Date{} = from, nil}),
    do: {Date.compare(date, from) == :eq, false, false}

  defp range_position(date, {:range, nil, %Date{} = to}),
    do: {false, false, Date.compare(date, to) == :eq}

  defp range_position(_date, _selection), do: {false, false, false}

  defp disabled?(date, assigns) do
    below_min?(date, assigns.min) or above_max?(date, assigns.max) or
      matches_disabled?(date, assigns.disabled_dates)
  end

  defp below_min?(date, %Date{} = min), do: Date.before?(date, min)
  defp below_min?(_date, _min), do: false

  defp above_max?(date, %Date{} = max), do: Date.after?(date, max)
  defp above_max?(_date, _max), do: false

  defp matches_disabled?(date, dates) when is_list(dates),
    do: Enum.any?(dates, &(date?(&1) and Date.compare(date, &1) == :eq))

  defp matches_disabled?(date, fun) when is_function(fun, 1), do: !!fun.(date)
  defp matches_disabled?(_date, _), do: false

  # Roving tabindex: exactly one day in the grid is tabbable. Preference order is
  # the selected day, then today, then the first enabled day of the month, then
  # the first day rendered - so the grid is never a tab dead end.
  defp assign_tabindex(weeks) do
    focus = focus_day(weeks)
    Enum.map(weeks, fn week -> Enum.map(week, &tabbable(&1, focus)) end)
  end

  defp tabbable(day, nil), do: day

  defp tabbable(day, focus) do
    if day.iso == focus.iso and day.hidden == focus.hidden,
      do: %{day | tabindex: "0"},
      else: day
  end

  defp focus_day(weeks) do
    candidates = weeks |> List.flatten() |> Enum.reject(& &1.hidden)

    Enum.find_value(focus_rules(), List.first(candidates), fn rule ->
      Enum.find(candidates, rule)
    end)
  end

  defp focus_rules do
    [
      fn day -> day.selected and not day.outside end,
      fn day -> day.selected end,
      fn day -> day.today and not day.outside end,
      fn day -> not day.outside and not day.disabled end,
      fn day -> not day.outside end
    ]
  end

  defp caption(month_start, month_names) do
    "#{month_name(month_start.month, month_names)} #{month_start.year}"
  end

  defp aria_label(date, month_names) do
    "#{date.day} #{month_name(date.month, month_names)} #{date.year}"
  end

  defp month_name(month, month_names), do: Enum.at(month_names, month - 1)

  # min/max can arrive as false from a playground-style toggle, and an absent
  # attribute is what tells the hook there is no window to clamp against.
  defp iso_attr(%Date{} = date), do: Date.to_iso8601(date)
  defp iso_attr(_), do: nil

  # day_names arrive Monday-first whatever starts_on is, so rotating them here
  # keeps the attr's contract stable when the dial changes.
  defp weekday_labels(short, long, starts_on) do
    Enum.map(0..6, fn i ->
      index = rem(starts_on - 1 + i, 7)
      {Enum.at(short, index), Enum.at(long, index)}
    end)
  end

  # A caller who passes a short (or gappy) list gets English in the holes rather
  # than a nil rendering as an empty column header.
  defp pad(names, fallback, size) do
    names = List.wrap(names)
    Enum.map(0..(size - 1), fn i -> Enum.at(names, i) || Enum.at(fallback, i) end)
  end
end
