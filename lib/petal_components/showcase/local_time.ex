defmodule PetalComponents.Showcase.LocalTime do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.LocalTime,
    title: "Local time",
    functions: [:local_time]

  example :relative, "Relative, ticking live",
    description:
      "Intl.RelativeTimeFormat with numeric auto, so you get \"yesterday\" rather than \"1 day ago\". Fresh timestamps tick every few seconds, old ones barely at all, and past the threshold it flips to the absolute form. Hover for the full date." do
    ~H"""
    <div class="flex flex-col gap-2 text-sm">
      <.local_time
        id="showcase-lt-rel-1"
        at={DateTime.add(DateTime.utc_now(), -12)}
        format="relative"
      />
      <.local_time
        id="showcase-lt-rel-2"
        at={DateTime.add(DateTime.utc_now(), -540)}
        format="relative"
      />
      <.local_time
        id="showcase-lt-rel-3"
        at={DateTime.add(DateTime.utc_now(), -90_000)}
        format="relative"
      />
      <.local_time
        id="showcase-lt-rel-4"
        at={DateTime.add(DateTime.utc_now(), 1_800)}
        format="relative"
      />
    </div>
    """
  end

  example :absolute, "Absolute, in the visitor's locale",
    description:
      "The default is medium date + short time in the browser's own language and timezone. Presets cover date and time halves; a map of Intl.DateTimeFormat options unlocks the rest." do
    ~H"""
    <div class="flex flex-col gap-2 text-sm">
      <.local_time id="showcase-lt-abs-1" at={~U[2026-07-21 08:30:00Z]} />
      <.local_time id="showcase-lt-abs-2" at={~U[2026-07-21 08:30:00Z]} format="date" />
      <.local_time id="showcase-lt-abs-3" at={~U[2026-07-21 08:30:00Z]} format="time" />
      <.local_time
        id="showcase-lt-abs-4"
        at={~U[2026-07-21 08:30:00Z]}
        format={%{weekday: "long", day: "numeric", month: "long", hour: "2-digit", minute: "2-digit"}}
      />
    </div>
    """
  end

  example :zones, "Pinned locales and timezones",
    description:
      "The same instant for a Berlin colleague and a Sydney one - locale and timezone override the browser defaults per element." do
    ~H"""
    <div class="flex flex-col gap-2 text-sm">
      <.local_time
        id="showcase-lt-zone-1"
        at={~U[2026-07-21 08:30:00Z]}
        locale="de-DE"
        timezone="Europe/Berlin"
      />
      <.local_time
        id="showcase-lt-zone-2"
        at={~U[2026-07-21 08:30:00Z]}
        locale="en-AU"
        timezone="Australia/Sydney"
      />
    </div>
    """
  end
end
