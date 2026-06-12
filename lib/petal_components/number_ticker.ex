defmodule PetalComponents.NumberTicker do
  @moduledoc """
  A number that counts up (or down) to its value when it scrolls into view,
  and re-animates whenever the value changes — perfect for stats sections and
  live dashboards.

  Requires the `PetalNumberTicker` hook from the JS bundle. The final value is
  rendered server-side, so the component degrades gracefully without
  JavaScript.
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :value, :any, required: true, doc: "the target number (integer or float)"

  attr :start_value, :any,
    default: 0,
    doc: "where the first animation counts from"

  attr :duration, :integer, default: 1500, doc: "animation length in milliseconds"

  attr :decimal_places, :integer,
    default: 0,
    doc: "decimal places to show while counting"

  attr :prefix, :string, default: nil, doc: ~s|e.g. "$"|
  attr :suffix, :string, default: nil, doc: ~s|e.g. "+" or "%"|

  attr :locale, :string,
    default: nil,
    doc: ~s|BCP 47 locale for number formatting (e.g. "de-DE"); defaults to the browser locale|

  attr :class, :any, default: nil, doc: "extra classes (set font size/weight here)"
  attr :rest, :global

  @doc """
  Renders an animated counter.

      <.number_ticker id="stars-count" value={5200} suffix="+" class="text-4xl font-bold" />

  In a LiveView, updating the assign re-animates from the previous value to
  the new one:

      <.number_ticker id="mrr" value={@mrr} prefix="$" decimal_places={2} />
  """
  def number_ticker(assigns) do
    ~H"""
    <span
      id={@id}
      class={["pc-number-ticker", @class]}
      phx-hook="PetalNumberTicker"
      data-value={to_string(@value)}
      data-start-value={to_string(@start_value)}
      data-duration={@duration}
      data-decimal-places={@decimal_places}
      data-prefix={@prefix}
      data-suffix={@suffix}
      data-locale={@locale}
      {@rest}
    >
      {@prefix}{@value}{@suffix}
    </span>
    """
  end
end
