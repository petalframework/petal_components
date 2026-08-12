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
      "variant=\"compact\" is the density you want for a feed: tighter rhythm, smaller type, avatar markers. Timestamps are plain strings here - swap in <.local_time format=\"relative\"> and they stay right without a re-render." do
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
        state="current"
        time="just now"
        title="Deploying v4.2.0 to production"
      />
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
