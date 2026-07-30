defmodule PetalComponents.Showcase.NumberTicker do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.NumberTicker, title: "Number ticker"

  example :stats, "Numbers that count up",
    description:
      "The PetalNumberTicker hook animates on mount and on every value change - feed it new numbers and it animates the difference. prefix, suffix, decimal_places and locale handle formatting; duration tunes the count." do
    ~H"""
    <div class="flex gap-10 text-center">
      <div>
        <div class="text-2xl font-semibold tabular-nums">
          <.number_ticker id="showcase-ticker-stars" value={1024} suffix="+" />
        </div>
        <div class="mt-1 text-xs text-gray-400">GitHub stars</div>
      </div>
      <div>
        <div class="text-2xl font-semibold tabular-nums">
          <.number_ticker
            id="showcase-ticker-uptime"
            value={99.98}
            decimal_places={2}
            suffix="%"
            duration={2200}
          />
        </div>
        <div class="mt-1 text-xs text-gray-400">Uptime</div>
      </div>
    </div>
    """
  end
end
