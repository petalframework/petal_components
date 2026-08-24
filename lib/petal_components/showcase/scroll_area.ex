defmodule PetalComponents.Showcase.ScrollArea do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.ScrollArea,
    title: "Scroll area"

  @deploy_log """
  09:14:01.118 [info]  release v4.15.0 building on builder-04 (elixir 1.19.1 / otp 28)
  09:14:04.902 [info]  ==> deps compiled in 3.7s, 214 modules
  09:14:11.470 [info]  ==> assets: tailwind 4.1.3 wrote priv/static/assets/app.css in 812ms
  09:14:12.006 [info]  ==> digest: 46 files, 1.9MB total, gzip 412KB
  09:14:19.331 [info]  image pushed: registry.fly.io/acme-prod:deployment-01K2 (sha256:9f21c4ab)
  09:14:26.884 [info]  machine 5683d9 updating in syd, waiting for health checks
  09:14:38.019 [info]  machine 5683d9 healthy after 11.1s, 1 of 2 machines updated
  09:14:51.744 [info]  machine 90e8ff healthy after 9.4s, 2 of 2 machines updated
  09:14:52.100 [info]  deployment complete, 0 failed, rollback not required\
  """

  @doc false
  def deploy_log, do: @deploy_log

  example :basic, "A vertical list",
    description:
      "The default. Size the viewport with classes - here max-h-56 - and everything past it scrolls with a thin themed scrollbar instead of the browser's default slab. tabindex=\"0\" comes for free, so the arrow keys and Page Up/Down work the moment you tab into it." do
    ~H"""
    <.scroll_area
      aria-label="Recent releases"
      class="max-h-56 w-full max-w-sm rounded-lg border border-gray-200 p-3 dark:border-gray-800"
    >
      <ul class="space-y-2 text-sm text-gray-700 dark:text-gray-300">
        <li :for={n <- 1..14} class="flex items-center justify-between gap-4">
          <span>Release note {n}</span>
          <span class="text-xs text-gray-400">v4.{n}.0</span>
        </li>
      </ul>
    </.scroll_area>
    """
  end

  example :horizontal_tags, "Horizontal, with faded edges",
    description:
      "A tag rail that runs off the side of a card. fade_edges masks the scrolling axis so the row dissolves at the clip rather than being guillotined - the visual cue that says there is more this way." do
    ~H"""
    <div class="w-full max-w-sm rounded-lg border border-gray-200 p-4 dark:border-gray-800">
      <div class="mb-3 text-sm font-medium text-gray-900 dark:text-gray-100">Topics</div>
      <.scroll_area orientation="horizontal" fade_edges class="w-full pb-2">
        <div class="flex w-max gap-2">
          <.badge
            :for={
              tag <- ~w(elixir phoenix liveview heex tailwind oban ecto postgres fly accessibility)
            }
            label={tag}
            variant="soft"
          />
        </div>
      </.scroll_area>
    </div>
    """
  end

  example :both_axes, "Both axes, gutter reserved",
    description:
      "A deploy log with orientation=\"both\": one container, two themed scrollbars and a themed corner where they meet. gutter_stable reserves the scrollbar's space up front, so the lines do not shuffle sideways the first time a scrollbar appears. On overlay scrollbars (the macOS default) there is no gutter to reserve and the flag quietly does nothing." do
    ~H"""
    <.scroll_area
      orientation="both"
      gutter_stable
      aria-label="Deploy log"
      class="max-h-48 w-full max-w-md rounded-lg bg-gray-900 p-4 dark:border dark:border-gray-800"
    >
      <pre class="w-max font-mono text-xs leading-6 text-gray-100">{PetalComponents.Showcase.ScrollArea.deploy_log()}</pre>
    </.scroll_area>
    """
  end

  example :always_visible, "Asking for a permanent scrollbar",
    description:
      "visibility=\"always\" asks the engine to keep the scrollbar drawn instead of fading it in on scroll. It is a request, not a guarantee: WebKit honours it, Firefox has no mechanism for it, and no browser overrides an OS set to hide scrollbars. Reach for it when a region would otherwise look like static text." do
    ~H"""
    <.scroll_area
      visibility="always"
      class="max-h-40 w-full max-w-sm rounded-lg border border-gray-200 p-3 text-sm text-gray-700 dark:border-gray-800 dark:text-gray-300"
    >
      <p class="mb-3">
        Scrollbars belong to the operating system. This component themes what the platform hands it - the thumb colour, the track, the width where that is ours to set - and leaves the behaviour alone.
      </p>
      <p class="mb-3">
        That means native momentum scrolling, native keyboard handling and native assistive-tech behaviour, none of which a JavaScript scrollbar reimplementation gets for free.
      </p>
      <p>
        The trade is that a Mac still looks like a Mac. We think that is the right way round.
      </p>
    </.scroll_area>
    """
  end
end
