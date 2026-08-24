defmodule PetalComponents.Scrollspy do
  @moduledoc """
  Scroll-position-aware navigation: the "On this page" rail that sits beside a
  long docs article and highlights the section you are currently reading.

  The markup is inert on its own. A `PetalScrollspy` JS hook watches the
  sections with an `IntersectionObserver` and moves the active state as the
  reader scrolls - there is no CSS-only way to know which heading is at the
  reading position, so this component ships a hook.

  ## Built-in renderer

  Pass the entries as `items`. Each one is a map with a `:label` and a
  `:target` - the `id` of the section element on the page, without the leading
  `#`:

      <.scrollspy
        id="docs-toc"
        heading="On this page"
        items={[
          %{label: "Install", target: "install"},
          %{label: "Usage", target: "usage"},
          %{label: "Theming", target: "theming"}
        ]}
      />

  One level of nesting (h2 with its h3s) is supported through `:children`:

      items={[
        %{
          label: "Usage",
          target: "usage",
          children: [
            %{label: "Options", target: "options"},
            %{label: "Events", target: "events"}
          ]
        }
      ]}

  Deeper nesting is deliberately not supported - past two levels a rail stops
  being scannable and wants a different component.

  ## Bare markup (the data-attribute contract)

  The hook is not tied to this renderer. Put `phx-hook="PetalScrollspy"` on any
  container and give its descendant links a `data-scrollspy-target` pointing at
  a section id, and the hook takes over - zero `pc-scrollspy` classes required:

      <nav id="my-toc" phx-hook="PetalScrollspy" data-offset="6rem" aria-label="On this page">
        <ul>
          <li><a href="#install" data-scrollspy-target="install">Install</a></li>
          <li><a href="#usage" data-scrollspy-target="usage">Usage</a></li>
        </ul>
      </nav>

  On the active link the hook sets `aria-current="location"` and adds
  `pc-scrollspy-link--active`, removing both from every other link. Style the
  active state however you like; `pc-scrollspy-link--active` is just a class.

  The hook reads two attributes off its own element:

    * `data-offset` - a length applied as `scroll-margin-top` to every target,
      so a fixed site header does not cover the heading you just jumped to
    * `data-threshold` - an optional `rootMargin` override for the observer,
      which is what moves the activation line up or down the viewport

  ## How the active section is chosen

    * **The section owning the activation line wins.** When several sections
      are in view at once, the active one is the section nearest the top of the
      viewport that has already reached the line - so a new heading takes over
      the moment it arrives at reading position, not when the previous section
      finally scrolls away.
    * **Bottom snap.** At the very bottom of the scroll container the last
      section activates even if it is too short to ever reach the line -
      otherwise a two-line closing section could never be highlighted.
    * **Hash navigation.** On mount and on `hashchange`, a `location.hash` that
      matches a target activates immediately instead of waiting for the
      observer. Scrolling never rewrites the hash (that would spam history);
      only clicking a link does, natively.

  ## Motion

  The hook sets `scroll-behavior: smooth` on the scroll container so clicking a
  link glides, and restores the previous value when the component unmounts.
  Under `prefers-reduced-motion: reduce` it leaves the scroll behaviour alone
  (jumps are instant) and CSS drops the indicator transition - the bar still
  tracks the active link, it just moves without animating.

  ## Accessibility

    * The rail is a `<nav>` with an `aria-label` ("On this page" by default),
      so screen reader users can find and skip it.
    * The active link carries `aria-current="location"` - the correct token for
      "you are here within this page" - so the state is not colour-only.
    * Entries are plain `<a href="#id">` anchors: Tab moves through them, Enter
      follows them, and the browser's own focus handling applies. There is no
      roving tabindex and no custom key handling.
    * Scrolling never moves focus. The hook only toggles classes and
      `aria-current`; the reader's focus and caret stay where they were.
    * The indicator bar is decorative and marked `aria-hidden="true"`.
  """
  use Phoenix.Component

  attr :id, :string, required: true, doc: "id of the nav element; required by the JS hook"

  attr :items, :list,
    required: true,
    doc: """
    The nav entries. Each item is a map: `%{label: "Install", target: "install"}`,
    where `target` is the id of the section element (no leading `#`). One level
    of nesting is supported for h2/h3 structure via a `:children` key:
    `%{label: "Usage", target: "usage", children: [%{label: "Options", target: "options"}]}`.
    """

  attr :offset, :string,
    default: "6rem",
    doc:
      "scroll-margin-top applied to the target sections, so a click-scroll clears a fixed header"

  attr :threshold, :string,
    default: nil,
    doc:
      ~s|optional override for the observer rootMargin (the activation line), e.g. "-20% 0px -70% 0px". Defaults to a reading-position tuned value baked into the hook|

  attr :indicator, :string,
    default: "bar",
    values: ["bar", "none"],
    doc:
      ~s|the active indicator. "bar": a rail with a bar that slides to the active link. "none": no rail and no bar, active state is carried by the link colour and aria-current alone|

  attr :heading, :string,
    default: nil,
    doc: ~s|optional small heading above the list, e.g. "On this page"|

  attr :aria_label, :string,
    default: "On this page",
    doc: "accessible name for the nav landmark"

  attr :class, :any, default: nil, doc: "extra classes for the nav element"
  attr :rest, :global

  @doc """
  Renders a scrollspy navigation rail.

  See `PetalComponents.Scrollspy` for the item shape, the bare-markup
  contract, and how the active section is chosen.

      <.scrollspy
        id="docs-toc"
        heading="On this page"
        items={[%{label: "Install", target: "install"}, %{label: "Usage", target: "usage"}]}
      />
  """
  def scrollspy(assigns) do
    ~H"""
    <nav
      id={@id}
      class={["pc-scrollspy", "pc-scrollspy--#{@indicator}", @class]}
      phx-hook="PetalScrollspy"
      data-offset={@offset}
      data-threshold={@threshold}
      aria-label={@aria_label}
      {@rest}
    >
      <span :if={@heading} class="pc-scrollspy__heading">{@heading}</span>
      <div :if={@indicator == "bar"} class="pc-scrollspy__indicator" aria-hidden="true"></div>
      <ul class="pc-scrollspy__list">
        <li :for={item <- @items} class="pc-scrollspy__item">
          <a
            href={"##{item.target}"}
            class="pc-scrollspy-link"
            data-scrollspy-target={item.target}
          >
            {item.label}
          </a>
          <ul :if={children(item) != []} class="pc-scrollspy__sublist">
            <li :for={child <- children(item)} class="pc-scrollspy__item">
              <a
                href={"##{child.target}"}
                class="pc-scrollspy-link pc-scrollspy-link--nested"
                data-scrollspy-target={child.target}
              >
                {child.label}
              </a>
            </li>
          </ul>
        </li>
      </ul>
    </nav>
    """
  end

  # Children are optional, and one level deep only - a grandchild key is
  # ignored rather than rendered, so a too-deep tree degrades instead of
  # producing a rail nobody can scan.
  defp children(item), do: Map.get(item, :children) || []
end
