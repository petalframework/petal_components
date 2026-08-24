defmodule PetalComponents.Showcase.Timeline do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Timeline, title: "Timeline"

  example :order_tracking, "Order tracking",
    description:
      "The default left rail. Icon markers carry the meaning of each step, the entry in flight is state=\"current\" (ringed, and the only one with aria-current), and everything after it is upcoming - muted, hollow marker, faded line running into it." do
    ~H"""
    <.timeline label="Order history">
      <:item
        marker="icon"
        icon="hero-check"
        color="success"
        time="Mon 9:41am"
        title="Order placed"
        description="Payment authorised, receipt emailed."
      />
      <:item
        marker="icon"
        icon="hero-cube"
        color="success"
        time="Mon 4:20pm"
        title="Packed"
        description="Picked and boxed at the Melbourne warehouse."
      />
      <:item
        marker="icon"
        icon="hero-truck"
        state="current"
        time="Tue 7:05am"
        title="Out for delivery"
        description="With the courier, tracking updates every 20 minutes."
      />
      <:item
        marker="icon"
        icon="hero-home"
        state="upcoming"
        time="Tue, by 6pm"
        title="Delivered"
        description="Signature required."
      />
    </.timeline>
    """
  end

  example :activity_feed, "Activity feed",
    description:
      "variant=\"compact\" is the density you want for a feed: tighter rhythm, smaller type, avatar markers. The last entry is state=\"loading\" - the thing that is still happening while you read about it. Timestamps are plain strings here - swap in <.local_time format=\"relative\"> and they stay right without a re-render." do
    ~H"""
    <.timeline variant="compact" label="Recent activity">
      <:item
        marker="avatar"
        name="Alex Chen"
        time="12 minutes ago"
        title="Alex pushed 3 commits to main"
        description="Fix the retry backoff on the webhook worker"
      />
      <:item
        marker="icon"
        icon="hero-check-circle"
        color="success"
        time="9 minutes ago"
        title="CI passed"
        description="418 tests, 2m 51s"
      />
      <:item
        marker="avatar"
        name="Sam Rivera"
        time="6 minutes ago"
        title="Sam approved the release"
      />
      <:item
        marker="icon"
        icon="hero-rocket-launch"
        state="loading"
        time="just now"
        title="Deploying v4.14.0 to production"
        description="Rolling through Sydney, Dublin and Ohio."
      />
    </.timeline>
    """
  end

  example :pipeline, "Pipeline steps",
    description:
      "A CI run read top to bottom. Finished stages carry a check and how long they took, the stage in flight is state=\"loading\" so its marker spins, and the one after it is upcoming. The title attr is a plain string, so anything that has to sit BESIDE the title - a duration chip, a status badge - goes in the entry's block on a flex row of its own. Reuse pc-timeline__title there and the row keeps the component's type and keeps fading when the entry is upcoming; mt-0 takes off the title's own first-line nudge, which a flex row does not want." do
    ~H"""
    <.timeline label="Pipeline run 482">
      <:item marker="icon" icon="hero-check" color="success">
        <div class="flex flex-wrap items-center gap-2">
          <h3 class="mt-0 pc-timeline__title">Checkout code</h3>
          <.badge size="sm" color="success" variant="light" label="12s" />
        </div>
        <div class="p-3 mt-2 border border-gray-200 rounded-lg dark:border-gray-400/17">
          <div class="flex items-center gap-2">
            <.avatar name="Alex Chen" alt="Alex Chen" size="2xs" />
            <span class="text-xs font-medium text-gray-700 dark:text-gray-300">alex-chen</span>
          </div>
          <p class="mt-1.5 text-xs text-gray-500 dark:text-gray-400">
            Pushed <span class="font-mono">a1b2c3d</span> to main, 4 files changed.
          </p>
        </div>
      </:item>
      <:item marker="icon" icon="hero-check" color="success">
        <div class="flex flex-wrap items-center gap-2">
          <h3 class="mt-0 pc-timeline__title">Install dependencies</h3>
          <.badge size="sm" color="success" variant="light" label="48s" />
        </div>
        <p class="mt-1.5 text-xs text-gray-500 dark:text-gray-400">
          Restored the cache, 3 of 214 packages fetched.
        </p>
      </:item>
      <:item marker="icon" color="warning" state="loading">
        <div class="flex flex-wrap items-center gap-2">
          <h3 class="mt-0 pc-timeline__title">Unit & integration tests</h3>
          <.badge size="sm" color="warning" variant="light" with_icon>
            <span class="w-1.5 h-1.5 rounded-full bg-current" aria-hidden="true"></span> Running
          </.badge>
        </div>
        <div class="p-3 mt-2 border border-gray-200 rounded-lg dark:border-gray-400/17">
          <p class="text-xs text-gray-500 dark:text-gray-400">
            311 of 418 tests, 2 shards on <span class="font-mono">ubuntu-24.04</span>.
          </p>
        </div>
      </:item>
      <:item marker="icon" icon="hero-cube" state="upcoming">
        <div class="flex flex-wrap items-center gap-2">
          <h3 class="mt-0 pc-timeline__title">Production build</h3>
          <.badge size="sm" color="gray" variant="light" label="Pending" />
        </div>
      </:item>
    </.timeline>
    """
  end

  example :deploy_feed, "Deploy feed",
    description:
      "time_placement=\"start\" hands the time a column of its own beside the rail, right-aligned against it, which is the layout for a log you scan by when rather than by what. The column is 8rem of --pc-timeline-time-col and it only shows up from sm - narrower than that the time drops back above the title and the markers do not move." do
    ~H"""
    <.timeline time_placement="start" label="Recent deploys">
      <:item color="success" time="12 minutes ago">
        <div class="flex flex-wrap items-center gap-2">
          <h3 class="mt-0 pc-timeline__title">Deploy to production</h3>
          <.badge size="sm" color="success" variant="light" with_icon>
            <span class="w-1.5 h-1.5 rounded-full bg-current" aria-hidden="true"></span> Success
          </.badge>
        </div>
        <p class="mt-1 font-mono text-xs text-gray-500 dark:text-gray-400">
          a1b2c3d · main · 42s
        </p>
      </:item>
      <:item color="danger" time="1 hour ago">
        <div class="flex flex-wrap items-center gap-2">
          <h3 class="mt-0 pc-timeline__title">Deploy to production</h3>
          <.badge size="sm" color="danger" variant="light" with_icon>
            <span class="w-1.5 h-1.5 rounded-full bg-current" aria-hidden="true"></span> Failed
          </.badge>
        </div>
        <p class="mt-1 font-mono text-xs text-gray-500 dark:text-gray-400">
          9f4e210 · main · 18s
        </p>
      </:item>
      <:item color="success" time="Yesterday, 4:02pm">
        <div class="flex flex-wrap items-center gap-2">
          <h3 class="mt-0 pc-timeline__title">Deploy to staging</h3>
          <.badge size="sm" color="success" variant="light" with_icon>
            <span class="w-1.5 h-1.5 rounded-full bg-current" aria-hidden="true"></span> Success
          </.badge>
        </div>
        <p class="mt-1 font-mono text-xs text-gray-500 dark:text-gray-400">
          c81d0a7 · release/4.15 · 39s
        </p>
      </:item>
    </.timeline>
    """
  end

  example :rich_entries, "Rich entry bodies",
    description:
      "Anything in an entry's inner block renders under the description, in every variant - a card, a diff, a thumbnail grid. Dashed connectors suit a log that has gaps in it." do
    ~H"""
    <.timeline connector="dashed">
      <:item color="gray" time="Yesterday" title="Incident opened">
        <div class="p-3 mt-3 text-sm border border-gray-200 rounded-lg text-gray-600 dark:border-gray-400/17 dark:text-gray-300">
          <span class="font-mono text-xs">api-gateway</span>
          returned 503 for 4% of requests over 11 minutes.
        </div>
      </:item>
      <:item color="success" time="Today" title="Resolved" description="Connection pool doubled.">
        <div class="flex gap-2 mt-3">
          <.badge color="success" label="No customer impact" />
          <.badge color="gray" label="Postmortem filed" />
        </div>
      </:item>
    </.timeline>
    """
  end

  example :alternating, "Alternating",
    description:
      "variant=\"alternating\" swings entries either side of a centre rail from md up, and folds back to the default left rail below that - two columns of text on a phone is not a timeline, it's a puzzle." do
    ~H"""
    <.timeline variant="alternating">
      <:item
        marker="number"
        time="2019"
        title="Founded"
        description="Two people, one office above a bakery."
      />
      <:item
        marker="number"
        time="2021"
        title="Series A"
        description="Team of 14, first 1,000 customers."
      />
      <:item
        marker="number"
        time="2023"
        title="Went global"
        description="Regions in Sydney, Dublin and Ohio."
      />
    </.timeline>
    """
  end

  example :horizontal, "Horizontal milestones",
    description:
      "orientation=\"horizontal\" puts the rail across the top with content underneath. It scrolls sideways with snap points when the row runs out of room, and the scroller takes keyboard focus so arrow keys work." do
    ~H"""
    <.timeline orientation="horizontal" label="Company milestones">
      <:item
        marker="number"
        color="gray"
        time="Q1"
        title="Research"
        description="40 customer interviews."
      />
      <:item
        marker="number"
        color="gray"
        time="Q2"
        title="Private beta"
        description="200 teams on the waitlist."
      />
      <:item
        marker="number"
        state="current"
        time="Q3"
        title="Launch"
        description="Public pricing goes live."
      />
      <:item
        marker="number"
        state="upcoming"
        time="Q4"
        title="Enterprise"
        description="SSO, audit logs, SLAs."
      />
    </.timeline>
    """
  end
end
