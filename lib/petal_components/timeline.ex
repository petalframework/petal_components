defmodule PetalComponents.Timeline do
  @moduledoc """
  A record of things that happened, in order: activity feeds, deploy logs,
  order tracking, audit trails, company history.

  ## Timeline or stepper?

  `PetalComponents.Stepper` is **interactive progress** - clickable steps in a
  flow the user is moving through, with a notion of "where you are" that the app
  changes as they work. A timeline is a **record** - an append-only display of
  events. Nothing in it is clickable, nothing pushes an event, and the entries
  are whatever your data says they are. If the user is meant to navigate it,
  reach for `stepper/1`; if they are meant to read it, reach for `timeline/1`.

  ## Anatomy

  The root is an `<ol>` and each entry is an `<li>`, so screen readers announce
  position and count with no ARIA at all. Every entry has a marker on a rail, a
  connector to the next entry, and content: an optional time, title and
  description, plus an inner block for anything richer.

      <.timeline>
        <:item time="9:41am" title="Order placed" description="Payment authorised." />
        <:item time="11:02am" title="Packed" description="Left the Melbourne warehouse." />
        <:item time="Tomorrow" title="Delivered" state="upcoming" />
      </.timeline>

  ## Variants

  `default` is a left rail with the content beside it. `alternating` swings
  entries either side of a centre rail on `md` and up (collapsing back to
  `default` below). `compact` is activity-feed density - tighter spacing and
  smaller type, which is what you want with avatar markers:

      <.timeline variant="compact">
        <:item
          marker="avatar"
          src={~p"/images/alex.jpg"}
          name="Alex Chen"
          time="12 minutes ago"
          title="Alex pushed 3 commits"
        />
        <:item marker="icon" icon="hero-check-circle" color="success" time="10 minutes ago" title="CI passed" />
      </.timeline>

  `orientation="horizontal"` is the milestones layout instead - markers on a
  horizontal rail with content underneath, scrolling sideways with CSS
  scroll-snap when the row runs out of room. The `variant` attr is vertical-only
  and is ignored when horizontal.

  ## Leading times

  `time_placement="start"` moves the time out of the entry and into a column of
  its own on the far side of the rail, right-aligned against it, with the title
  and body to the right. It is the layout for a log you scan by when rather than
  by what - deploys, audit trails, a day's worth of events:

      <.timeline time_placement="start">
        <:item time="12 minutes ago" title="Deployed to production" />
        <:item time="1 hour ago" title="Merged #641" />
      </.timeline>

  The column is `--pc-timeline-time-col` wide (8rem, which clears "15 minutes
  ago" with room over). Set the property on the timeline to retune it:

      <.timeline time_placement="start" style="--pc-timeline-time-col: 11rem">

  Below `sm` there is no room for a third column, so the time falls back to the
  default placement above the title and the markers stay exactly where they
  were. Vertical `default` and `compact` only: `alternating` and
  `orientation="horizontal"` already spend the axis this column needs, so they
  accept the attr and ignore it, the same way `variant` is ignored when
  horizontal.

  ## Markers

  `marker` takes `"dot"` (the default), `"icon"` (pass `icon`), `"avatar"` (pass
  `src` and/or `name`, exactly as `PetalComponents.Avatar.avatar/1` takes them),
  or `"number"`, which prints the entry's 1-based position for you. `color`
  paints the marker in any of the seven semantic colours.

  ## States

  `state` is `"complete"` (default), `"current"`, `"loading"` or `"upcoming"`.
  The current entry is ringed and carries `aria-current="step"`; upcoming
  entries render muted with a hollow marker, and the connector running down to
  them is de-emphasised.

  `"loading"` is the entry that is happening while you watch it - a deploy
  mid-roll, a file still uploading. Its marker spins:

      <.timeline variant="compact">
        <:item marker="icon" icon="hero-check-circle" color="success" time="9 minutes ago" title="CI passed" />
        <:item marker="icon" state="loading" time="just now" title="Deploying v4.14.0 to production" />
      </.timeline>

  A loading marker shows the spinner instead of its icon, number or avatar,
  whatever `marker` says - a 10px dot has nowhere to put one - so the entry
  keeps the chip and the semantic colour but loses its glyph for the duration.
  The entry carries `aria-busy="true"`, and the spin stops under
  `prefers-reduced-motion`.

  ## Accessibility

  There is no WAI-ARIA pattern for a timeline, so this leans on native list
  semantics rather than inventing a role.

    * `<ol>` root, `<li>` entries. No `role` overrides, no interactive wrappers.
    * `aria-current="step"` on the current entry, and nowhere else.
    * `aria-busy="true"` on a loading entry, and nowhere else.
    * The rail (markers and connectors) is decorative and `aria-hidden`. State
      is never conveyed by colour alone - `current`, `loading` and `upcoming`
      entries each carry a visually-hidden label.
    * The horizontal scroll container takes focus so it can be scrolled by
      keyboard, with a visible focus ring, and its smooth scrolling is behind a
      `prefers-reduced-motion` guard.

  Rich content in the inner block renders below the description, in every
  variant:

      <.timeline>
        <:item time="2 hours ago" title="Deployed v4.2.0 to production">
          <.card class="mt-3">
            <.card_content>Rolled out to all regions in 3m 12s.</.card_content>
          </.card>
        </:item>
      </.timeline>
  """
  use Phoenix.Component

  alias PetalComponents.Loading

  import PetalComponents.Avatar
  import PetalComponents.Icon

  @colors ~w(primary secondary gray info success warning danger)
  @markers ~w(dot icon avatar number)
  @states ~w(complete current loading upcoming)

  attr :orientation, :string,
    default: "vertical",
    values: ["vertical", "horizontal"],
    doc: "horizontal is the milestones layout; scroll-snaps on small screens"

  attr :variant, :string,
    default: "default",
    values: ["default", "alternating", "compact"],
    doc: """
    vertical only, ignored when horizontal.
    default: left rail with entries to the right.
    alternating: entries alternate sides of a centre rail on md and up, collapsing to default below.
    compact: activity-feed density (tighter spacing, smaller type, suits avatar markers).
    """

  attr :connector, :string,
    default: "solid",
    values: ["solid", "dashed"],
    doc: "line style of the rail between markers"

  attr :time_placement, :string,
    default: "top",
    values: ["top", "start"],
    doc: """
    where each entry's time sits.
    top: above the title, inside the entry (the default).
    start: in its own column on the far side of the rail, right-aligned against it, from sm up - below that it falls back to top. Vertical default and compact only; alternating and horizontal ignore it. Width is the --pc-timeline-time-col custom property (8rem).
    """

  attr :label, :string,
    default: nil,
    doc:
      "accessible name for the list, announced instead of the generic \"list\" (e.g. \"Order history\"). Always set it on horizontal timelines: they are focusable scroll regions (tabindex=0), and a focusable region without a name is an a11y failure"

  attr :class, :any, default: nil, doc: "CSS class on the root list"
  attr :rest, :global

  slot :item, required: true, doc: "one entry per event, rendered in author order" do
    attr :title, :string, doc: "entry heading"

    attr :time, :string,
      doc:
        "plain-text timestamp; omit and slot in <.local_time> yourself for client-side formatting"

    attr :description, :string, doc: "one-line body; use the inner block instead for rich content"
    attr :marker, :string, doc: ~s|"dot" (default), "icon", "avatar", or "number"|

    attr :icon, :string,
      doc:
        ~s|heroicon name when marker="icon", e.g. "hero-truck". Defaults to "hero-check" when omitted|

    attr :src, :string, doc: ~s|image URL when marker="avatar"|

    attr :name, :string,
      doc:
        ~s|fallback initials source when marker="avatar" and src is absent (matches <.avatar> behaviour)|

    attr :color, :string,
      doc:
        ~s|semantic colour of the marker: "primary" (default), "secondary", "gray", "info", "success", "warning", "danger"|

    attr :state, :string,
      doc:
        ~s|"complete" (default), "current", "loading", or "upcoming". current gets a ringed marker + aria-current="step"; loading spins the marker and sets aria-busy; upcoming renders muted with the connector into it de-emphasised|

    attr :class, :any, doc: "CSS class on this entry's <li>"
  end

  @doc """
  Renders a timeline of events.

  See `PetalComponents.Timeline` for the variants, markers, states and the
  accessibility contract.
  """
  def timeline(assigns) do
    alternating? = assigns.variant == "alternating" and assigns.orientation == "vertical"

    assigns =
      assigns
      |> assign(:entries, entries(assigns.item, alternating?))
      |> assign(:horizontal?, assigns.orientation == "horizontal")
      |> assign(:time_start?, time_start?(assigns))

    ~H"""
    <ol
      class={[
        "pc-timeline",
        "pc-timeline--#{@orientation}",
        !@horizontal? && "pc-timeline--#{@variant}",
        @connector == "dashed" && "pc-timeline--dashed",
        @time_start? && "pc-timeline--time-start",
        @class
      ]}
      aria-label={@label}
      tabindex={@horizontal? && "0"}
      {@rest}
    >
      <li
        :for={entry <- @entries}
        class={[
          "pc-timeline__item",
          "pc-timeline__item--#{entry.state}",
          entry.side && "pc-timeline__item--#{entry.side}",
          entry.last? && "pc-timeline__item--last",
          entry.class
        ]}
        aria-current={entry.state == "current" && "step"}
        aria-busy={entry.loading? && "true"}
      >
        <%!-- The leading time is a sibling of the rail, not a child of the
              content, because it has to sit on the other side of it. Same
              element and same class either way, so nothing is announced twice
              and every rule that reaches a time still reaches this one. --%>
        <div :if={@time_start? && entry.time} class="pc-timeline__time">{entry.time}</div>
        <div class="pc-timeline__rail" aria-hidden="true">
          <span class={[
            "pc-timeline__marker",
            "pc-timeline__marker--#{entry.marker}",
            "pc-timeline__marker--#{entry.color}",
            "pc-timeline__marker--#{entry.state}"
          ]}>
            <%!-- A spinning marker replaces the glyph rather than sitting
                  beside it: the chip is 32px, and whatever the entry's marker
                  normally shows, while it's in flight the news is that it's in
                  flight. Same spinner the buttons use. --%>
            <Loading.spinner :if={entry.loading?} size_class="pc-timeline__spinner" />
            <.icon
              :if={!entry.loading? && entry.marker == "icon"}
              name={entry.icon}
              class="pc-timeline__icon"
            />
            <span :if={!entry.loading? && entry.marker == "number"} class="pc-timeline__number">
              {entry.index + 1}
            </span>
            <.avatar
              :if={!entry.loading? && entry.marker == "avatar"}
              src={entry.src}
              name={entry.name}
              alt={entry.name}
              size="sm"
              class="pc-timeline__avatar"
            />
          </span>
          <span
            :if={!entry.last?}
            class={[
              "pc-timeline__connector",
              entry.next_state == "upcoming" && "pc-timeline__connector--upcoming"
            ]}
          />
        </div>
        <div class="pc-timeline__content">
          <span :if={state_label(entry.state)} class="pc-timeline__state-label">
            {state_label(entry.state)}
          </span>
          <div :if={!@time_start? && entry.time} class="pc-timeline__time">{entry.time}</div>
          <h3 :if={entry.title} class="pc-timeline__title">{entry.title}</h3>
          <p :if={entry.description} class="pc-timeline__description">{entry.description}</p>
          <div :if={entry.body?} class="pc-timeline__body">{render_slot(entry.slot)}</div>
        </div>
      </li>
    </ol>
    """
  end

  # The leading time column costs a whole column of horizontal room, which only
  # the two single-rail vertical variants have going spare. Alternating already
  # owns both sides of its rail and horizontal runs the other way, so they take
  # the attr and ignore it rather than raising - same contract as `variant` when
  # orientation is horizontal.
  defp time_start?(assigns) do
    assigns.time_placement == "start" and assigns.orientation == "vertical" and
      assigns.variant in ["default", "compact"]
  end

  # Flattens each :item slot into everything the markup needs, so the template
  # stays a straight loop: defaults applied, 1-based numbering resolved, and the
  # neighbour lookups (last entry, next entry's state) done once. Sides exist
  # only for the alternating variant - every other layout gets side: nil so no
  # meaningless --start/--end classes land in the DOM.
  defp entries(items, alternating?) do
    states = Enum.map(items, &one_of(&1, :state, @states, "complete"))
    count = length(items)

    items
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      %{
        slot: item,
        index: index,
        last?: index == count - 1,
        state: Enum.at(states, index),
        loading?: Enum.at(states, index) == "loading",
        next_state: Enum.at(states, index + 1),
        side: alternating? && if(rem(index, 2) == 0, do: "start", else: "end"),
        marker: one_of(item, :marker, @markers, "dot"),
        color: one_of(item, :color, @colors, "primary"),
        icon: Map.get(item, :icon) || "hero-check",
        src: Map.get(item, :src),
        name: Map.get(item, :name),
        time: Map.get(item, :time),
        title: Map.get(item, :title),
        description: Map.get(item, :description),
        class: Map.get(item, :class),
        body?: item.inner_block != nil
      }
    end)
  end

  # Slot attrs are free-form strings, so an unknown value falls back to the
  # default rather than emitting a class nothing styles.
  defp one_of(item, key, allowed, default) do
    value = Map.get(item, key)
    if value in allowed, do: value, else: default
  end

  defp state_label("current"), do: "Current"
  defp state_label("loading"), do: "In progress"
  defp state_label("upcoming"), do: "Upcoming"
  defp state_label(_), do: nil
end
