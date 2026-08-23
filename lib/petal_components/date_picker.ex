defmodule PetalComponents.DatePicker do
  use Phoenix.Component

  import PetalComponents.Calendar
  import PetalComponents.Field, only: [field_wrapper: 1, field_label: 1, field_error: 1]
  import PetalComponents.Icon

  alias Phoenix.LiveView.JS

  @transition_in {"transition transform ease-out duration-100", "transform opacity-0 scale-95",
                  "transform opacity-100 scale-100"}
  @transition_out {"transition ease-in duration-75", "transform opacity-100 scale-100",
                   "transform opacity-0 scale-95"}

  @moduledoc """
  A text input with a `<.calendar>` in a panel underneath it. The input shows a
  formatted date you can type into; the form always posts ISO 8601.

  ## Examples

      <.date_picker name="due_on" label="Due date" value={~D[2026-03-14]} format="%d %b %Y" />

  Wired to a form field, it takes its name, value, errors and label the same way
  `<.field>` does:

      <.form for={@form} phx-change="validate" phx-submit="save">
        <.date_picker field={@form[:due_on]} label="Due date" min={Date.utc_today()} />
      </.form>

  Range mode posts `from` and `to` sub-fields, so `params["stay"]` comes back as
  `%{"from" => "2026-03-10", "to" => "2026-03-17"}`:

      <.date_picker
        name="stay"
        mode="range"
        two_months
        min={Date.utc_today()}
        value={{~D[2026-03-10], ~D[2026-03-17]}}
      />

  ## What gets posted

  The visible input is display-only: it is not named, so it never posts. A hidden
  input carries the value in ISO 8601 (`YYYY-MM-DD`) whatever `format` you show,
  because a strftime string is for humans and a form value is for your changeset.

  ## Parse on blur

  You can type in the input. On blur (or Enter) the picker tries, in order:

    1. `Date.from_iso8601/1`, so `2026-03-14` always works
    2. a lenient parse of the configured `format`, so `14 Mar 2026` works when
       `format` is `"%d %b %Y"`

  On success the hidden value and the calendar's month both move to the parsed
  date. On failure the input reverts to the last valid formatted value, so a
  half-typed date can never silently post as nothing. Enter commits the same
  way blur does, and when it lands a COMPLETE selection - both ends in range
  mode - it also closes the panel; a partial or failed parse keeps it open.
  Clicking a day keeps the same contract: the click that completes the
  selection (any single-mode click, a range's second end) closes the panel
  and hands focus back to the input; a range's anchor click keeps browsing.
  The calendar icon is a true toggle - it opens a closed panel and closes an
  open one.

  While the panel is open, typing does not even wait for blur: the moment the
  text parses to a complete selection, the calendar pages to it and paints it,
  with the caret and your text left exactly where they are (`14 Mar 2027`
  canonicalises to the configured format on blur or Enter, not mid-keystroke).
  Incomplete text does nothing - previews never revert. Server-owned pickers
  (`on_select`) keep the blur/Enter contract only, so your handler is never
  fed per-keystroke half-states.

  One wiring requirement that bites: with `on_month_change` left `nil`, month
  navigation renders as patch links carrying `month_param` - which only pages
  if your LiveView actually handles that param in `handle_params/3` and feeds
  it back through `month`. In a LiveView that ignores the param, prev/next do
  nothing and a typed far-away date cannot bring its month into view. Either
  handle the param, or pass `on_month_change` and assign the pushed month -
  the typed-date month jump works through whichever wiring you chose.

  With `on_select` set the server owns the value, so a parsed date is pushed to
  you as that same event rather than written client-side - typing `12 Jun 1987`
  and clicking 12 June 1987 arrive at `handle_event/3` identically. In range mode
  a typed range arrives as two events in reading order, exactly as two clicks
  would, so the handler you already have keeps working. Emptying the input pushes
  `on_clear` when you have wired one; without one there is nothing the picker can
  push, so the display reverts rather than sit there disagreeing with the value
  that will actually post.

  ## LiveView and dead views

  With `on_select` set, clicking a day pushes that event with the ISO date and
  your `handle_event/3` owns the value. Without it, the `PetalDatePicker` hook
  writes the hidden input itself and dispatches `input`/`change`, which is enough
  for a plain form post or a `phx-change` form. The panel opens and closes with
  `Phoenix.LiveView.JS` either way: Escape closes it and returns focus to the
  input, and clicking outside dismisses it.
  """

  @doc """
  Renders a date input with a calendar panel. See the module docs above for what
  gets posted, the parse-on-blur contract, and the LiveView vs dead-view wirings.

      <.date_picker field={@form[:due_on]} label="Due date" format="%d %b %Y" />
  """

  attr :id, :string, doc: "the picker id; autogenerated if not set"

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "a form field; wires name, value, errors and label like <.field>"

  attr :name, :any, default: nil, doc: "the posted field name; derived from field when given"

  attr :value, :any,
    default: nil,
    doc: "a Date, an ISO string, or a {from, to} pair in range mode"

  attr :label, :string, default: nil, doc: "the field label; omitted when nil"
  attr :errors, :list, default: [], doc: "error messages rendered under the input"
  attr :help_text, :string, default: nil, doc: "context shown under the input"

  attr :mode, :string, default: "single", values: ~w(single range), doc: "selection behaviour"

  attr :format, :string,
    default: "%Y-%m-%d",
    doc:
      "strftime format for the display input (Calendar.strftime/2); the posted value is always ISO 8601"

  attr :range_separator, :string,
    default: " - ",
    doc: "what sits between the two dates in the display input in range mode"

  attr :placeholder, :string, default: nil, doc: "placeholder for the display input"

  attr :clearable, :boolean,
    default: false,
    doc: "show a clear button whenever the field holds text"

  attr :two_months, :boolean,
    default: false,
    doc: "range mode only: render two month panes side by side"

  attr :disabled, :boolean, default: false, doc: "disable the input and the panel"
  attr :required, :boolean, default: false, doc: "mark the field required"

  attr :month, :any, default: nil, doc: "the displayed month as any Date within it"
  attr :min, :any, default: nil, doc: "earliest selectable Date (inclusive)"
  attr :max, :any, default: nil, doc: "latest selectable Date (inclusive)"

  attr :disabled_dates, :any,
    default: nil,
    doc: "a list of Dates, or a 1-arity function Date -> boolean"

  attr :today, :any, default: nil, doc: "the date treated as today; defaults to Date.utc_today/0"

  attr :starts_on, :integer,
    default: 1,
    values: [1, 2, 3, 4, 5, 6, 7],
    doc: "first day of the week, ISO day numbers (1 = Monday, 7 = Sunday)"

  attr :show_outside_days, :boolean, default: true, doc: "render adjacent-month days in the grid"
  attr :fixed_weeks, :boolean, default: false, doc: "always render 6 week rows"
  attr :day_names, :list, default: nil, doc: "7 short day labels ordered Monday-first"
  attr :day_names_long, :list, default: nil, doc: "7 full day labels ordered Monday-first"
  attr :month_names, :list, default: nil, doc: "12 month labels"

  attr :on_select, :any,
    default: nil,
    doc: "event pushed when a day is clicked, with the ISO date"

  attr :on_month_change, :any, default: nil, doc: "event pushed by the prev/next month buttons"
  attr :on_clear, :any, default: nil, doc: "event pushed when the clear button is clicked"
  attr :target, :any, default: nil, doc: "phx-target for the picker's events"

  attr :open_label, :string, default: "Choose date", doc: "accessible label for the toggle button"
  attr :clear_label, :string, default: "Clear date", doc: "accessible label for the clear button"

  attr :class, :any, default: nil, doc: "extra classes for the wrapper"
  attr :panel_class, :any, default: nil, doc: "extra classes for the panel"
  attr :rest, :global

  def date_picker(assigns) do
    assigns =
      assigns
      |> from_field()
      |> assign_new(:id, fn -> "date_picker_#{Ecto.UUID.generate()}" end)
      |> normalise()

    ~H"""
    <div
      id={@id}
      class={["pc-date-picker", @class]}
      phx-hook="PetalDatePicker"
      data-mode={@mode}
      data-format={@format}
      data-range-separator={@range_separator}
      data-clear-event={@on_clear}
      phx-click-away={close(@id)}
      data-close={close(@id)}
      data-open={open(@id, :grid)}
      phx-keydown={close_and_refocus(@id)}
      phx-key="Escape"
      {@rest}
    >
      <.field_wrapper errors={@errors} name={@name || @id} no_margin={@errors == []}>
        <.field_label :if={@label} for={"#{@id}-input"} required={@required}>{@label}</.field_label>

        <div class="pc-date-picker__control">
          <input
            type="text"
            id={"#{@id}-input"}
            class="pc-text-input pc-date-picker__input"
            value={@display_value}
            placeholder={@placeholder}
            disabled={@disabled}
            autocomplete="off"
            data-pc-date-input
            aria-haspopup="dialog"
            aria-expanded="false"
            aria-controls={"#{@id}-panel"}
            phx-click={!@disabled && open(@id)}
          />
          <button
            :if={@clearable}
            type="button"
            class="pc-date-picker__clear"
            data-pc-date-clear
            hidden={@display_value in [nil, ""]}
            disabled={@disabled}
            aria-label={@clear_label}
            phx-click={@on_clear}
            phx-target={@on_clear && @target}
          >
            <.icon name="hero-x-mark-mini" class="pc-date-picker__clear-icon" />
          </button>
          <button
            type="button"
            id={"#{@id}-toggle"}
            class="pc-date-picker__toggle"
            data-pc-date-toggle
            disabled={@disabled}
            aria-label={@open_label}
            aria-haspopup="dialog"
            aria-expanded="false"
            aria-controls={"#{@id}-panel"}
          >
            <.icon name="hero-calendar" class="pc-date-picker__toggle-icon" />
          </button>
        </div>

        <input
          :if={@mode == "single"}
          type="hidden"
          name={@name}
          value={@iso_value}
          data-pc-date-value
        />
        <input
          :if={@mode == "range"}
          type="hidden"
          name={@name && "#{@name}[from]"}
          value={@iso_from}
          data-pc-date-from
        />
        <input
          :if={@mode == "range"}
          type="hidden"
          name={@name && "#{@name}[to]"}
          value={@iso_to}
          data-pc-date-to
        />

        <div
          id={"#{@id}-panel"}
          role="dialog"
          aria-label={@open_label}
          style="display: none;"
          class={["pc-date-picker__panel", @panel_class]}
        >
          <div class={["pc-date-picker__months", @two_months && "pc-date-picker__months--two"]}>
            <.calendar
              id={"#{@id}-calendar"}
              mode={@mode}
              value={@calendar_value}
              month={@panel_month}
              min={@min}
              max={@max}
              disabled_dates={@disabled_dates}
              today={@today}
              starts_on={@starts_on}
              show_outside_days={@show_outside_days}
              fixed_weeks={@fixed_weeks}
              on_select={@on_select}
              on_month_change={@on_month_change}
              target={@target}
              {@calendar_labels}
            />
            <.calendar
              :if={@two_months}
              nav="none"
              id={"#{@id}-calendar-2"}
              mode={@mode}
              value={@calendar_value}
              month={next_month(@panel_month)}
              min={@min}
              max={@max}
              disabled_dates={@disabled_dates}
              today={@today}
              starts_on={@starts_on}
              show_outside_days={@show_outside_days}
              fixed_weeks={@fixed_weeks}
              on_select={@on_select}
              on_month_change={@on_month_change}
              target={@target}
              {@calendar_labels}
            />
          </div>
        </div>

        <.field_error :for={msg <- @errors}>{msg}</.field_error>
        <div :if={@help_text} class="pc-form-help-text">{@help_text}</div>
      </.field_wrapper>
    </div>
    """
  end

  # Both the input and the icon button open the panel, so both have to report
  # its state - the icon is the primary pointer target, and a trigger stuck on
  # aria-expanded="false" tells a screen reader nothing happened.
  #
  # The event carries WHO asked. Opening from the toggle (or ArrowDown) is
  # browse intent and the hook moves focus into the grid; opening from the
  # input is TYPING intent and focus stays exactly where the caret is - a
  # grid that steals focus from a typeable input makes the input untypeable,
  # which is the bug this argument exists to prevent.
  @doc false
  def open(id, focus \\ nil) do
    %JS{}
    |> JS.show(to: "##{id}-panel", transition: @transition_in)
    |> JS.set_attribute({"aria-expanded", "true"}, to: "##{id}-input")
    |> JS.set_attribute({"aria-expanded", "true"}, to: "##{id}-toggle")
    |> JS.dispatch("pc:date-picker:open",
      to: "##{id}",
      detail: %{focus: to_string(focus || "")}
    )
  end

  @doc false
  def close(id) do
    %JS{}
    |> JS.hide(to: "##{id}-panel", transition: @transition_out)
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{id}-input")
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{id}-toggle")
    |> JS.dispatch("pc:date-picker:close", to: "##{id}")
  end

  defp close_and_refocus(id), do: JS.focus(close(id), to: "##{id}-input")

  # ----------------------------------------------------------------------------
  # Value plumbing. A picker deals in three shapes of the same thing: the Date
  # the calendar highlights, the ISO string the form posts, and the strftime
  # string a human reads.
  # ----------------------------------------------------------------------------

  defp from_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if used_input?(field), do: Enum.map(field.errors, &translate_error/1), else: []

    assigns
    |> assign(field: nil)
    |> assign_new(:id, fn -> field.id end)
    |> assign(:errors, assigns.errors ++ errors)
    |> assign(:name, assigns.name || field.name)
    |> assign(:value, assigns.value || field.value)
    |> assign(:label, assigns.label || PhoenixHTMLHelpers.Form.humanize(field.field))
  end

  defp from_field(assigns), do: assigns

  defp normalise(assigns) do
    {from, to} = value_pair(assigns.mode, assigns.value)

    assigns
    |> assign(:iso_value, iso(from))
    |> assign(:iso_from, iso(from))
    |> assign(:iso_to, iso(to))
    |> assign(:display_value, display(assigns, from, to))
    |> assign(:calendar_value, if(assigns.mode == "range", do: {from, to}, else: from))
    |> assign(:panel_month, assigns.month || from || to || assigns.today || Date.utc_today())
    |> assign(:calendar_labels, calendar_labels(assigns))
  end

  # Only forward the name-list attrs the caller actually set, so the calendar's
  # English defaults stay in charge when they didn't.
  defp calendar_labels(assigns) do
    [
      day_names: assigns.day_names,
      day_names_long: assigns.day_names_long,
      month_names: assigns.month_names
    ]
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp value_pair("range", value) do
    case value do
      {from, to} -> {to_date(from), to_date(to)}
      %{from: from, to: to} -> {to_date(from), to_date(to)}
      %{"from" => from, "to" => to} -> {to_date(from), to_date(to)}
      other -> {to_date(other), nil}
    end
  end

  defp value_pair(_mode, value), do: {to_date(value), nil}

  defp to_date(%Date{} = date), do: date
  defp to_date(%DateTime{} = dt), do: DateTime.to_date(dt)
  defp to_date(%NaiveDateTime{} = ndt), do: NaiveDateTime.to_date(ndt)

  defp to_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp to_date(_), do: nil

  defp iso(%Date{} = date), do: Date.to_iso8601(date)
  defp iso(_), do: nil

  defp display(%{mode: "range"} = assigns, from, to) do
    case {from, to} do
      {nil, nil} ->
        nil

      {from, nil} ->
        strftime(from, assigns.format) <> assigns.range_separator

      {nil, to} ->
        assigns.range_separator <> strftime(to, assigns.format)

      {from, to} ->
        strftime(from, assigns.format) <> assigns.range_separator <> strftime(to, assigns.format)
    end
  end

  defp display(assigns, from, _to), do: from && strftime(from, assigns.format)

  defp strftime(%Date{} = date, format), do: Calendar.strftime(date, format)

  defp next_month(%Date{} = date), do: date |> Date.end_of_month() |> Date.add(1)

  # Same contract as <.field>: route errors through the app's translator when one
  # is configured, otherwise interpolate the bindings ourselves.
  defp translate_error({msg, opts}) do
    case Application.get_env(:petal_components, :error_translator_function) do
      {module, function} ->
        apply(module, function, [{msg, opts}])

      nil ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
    end
  end

  defp translate_error(msg) when is_binary(msg), do: msg
end
