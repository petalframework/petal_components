defmodule PetalComponents.LocalTime do
  @moduledoc """
  Timestamps rendered in the visitor's own timezone, language and calendar -
  no server timezone tables, no JavaScript date library. The server renders
  a semantic `<time datetime="...">` carrying the UTC instant; the
  `PetalLocalTime` hook formats it client-side with the browser's `Intl`.

      <.local_time id="t1" at={@message.inserted_at} />
      <.local_time id="t2" at={@message.inserted_at} format="relative" />
      <.local_time id="t3" at={@dt} format={%{dateStyle: "full"}} />

  ## Formats

    * `"datetime"` (default) - medium date + short time, e.g. "21 Jul 2026, 8:41 pm"
    * `"date"` / `"time"` - one half only
    * `"relative"` - "12 seconds ago", "yesterday", "in 3 weeks"
      (`Intl.RelativeTimeFormat`, numeric auto). Ticks live on a decaying
      cadence (5s while under a minute old, 30s under an hour, then
      15min/1h), re-renders when a background tab wakes (browsers throttle
      hidden timers), and flips to the absolute form once older than
      `threshold`. Hover shows the full absolute time via `title`.
    * a map - raw `Intl.DateTimeFormat` options with camelCase keys, passed
      through as-is: `%{weekday: "long", hour: "2-digit", minute: "2-digit"}`.

  Before the hook runs - and anywhere JavaScript never runs (RSS scrapes,
  reader modes, tests) - the element shows the UTC ISO string: honest,
  sortable, machine- and human-readable.

  `at` accepts a `DateTime` (any zone - normalised to UTC without needing a
  timezone database), a `NaiveDateTime` (assumed UTC), or an ISO8601 string
  (passed through untouched).
  """
  use Phoenix.Component

  attr :id, :string, required: true

  attr :at, :any,
    required: true,
    doc: "DateTime (any zone), NaiveDateTime (assumed UTC), or ISO8601 string"

  attr :format, :any,
    default: "datetime",
    doc:
      ~s|"datetime", "date", "time", "relative", or a map of Intl.DateTimeFormat options (camelCase keys)|

  attr :locale, :string,
    default: nil,
    doc: ~s|BCP 47 tag, e.g. "de-DE"; defaults to the browser's own|

  attr :timezone, :string,
    default: nil,
    doc: ~s|IANA zone, e.g. "Australia/Sydney"; defaults to the browser's own|

  attr :threshold, :integer,
    default: 604_800,
    doc:
      "relative format only: age in seconds beyond which the absolute form renders instead (default 7 days)"

  attr :title, :boolean,
    default: true,
    doc: "relative format only: show the absolute time on hover"

  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  Renders a localised `<time>` element bound to the `PetalLocalTime` hook.
  """
  def local_time(assigns) do
    {format, options} =
      case assigns.format do
        map when is_map(map) -> {"custom", Phoenix.json_library().encode!(map)}
        preset -> {preset, nil}
      end

    assigns = assign(assigns, iso: to_utc_iso(assigns.at), format_name: format, options: options)

    ~H"""
    <time
      id={@id}
      datetime={@iso}
      phx-hook="PetalLocalTime"
      data-format={@format_name}
      data-options={@options}
      data-locale={@locale}
      data-timezone={@timezone}
      data-threshold={@threshold}
      data-title={to_string(@title)}
      class={["pc-local-time", @class]}
      {@rest}
    >{@iso}</time>
    """
  end

  # Unix-roundtrip instead of shift_zone!/2: normalises any zone to UTC
  # without requiring a timezone database. The roundtrip would stamp full
  # microsecond precision onto clean timestamps, so restore the original
  # precision - this string is user-visible as the SSR fallback.
  defp to_utc_iso(%DateTime{} = dt) do
    utc = DateTime.from_unix!(DateTime.to_unix(dt, :microsecond), :microsecond)
    DateTime.to_iso8601(%{utc | microsecond: dt.microsecond})
  end

  defp to_utc_iso(%NaiveDateTime{} = ndt), do: NaiveDateTime.to_iso8601(ndt) <> "Z"
  defp to_utc_iso(iso) when is_binary(iso), do: iso
end
