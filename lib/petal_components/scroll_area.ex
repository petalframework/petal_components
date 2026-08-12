defmodule PetalComponents.ScrollArea do
  @moduledoc """
  A themed scroll container, so an overflow region looks like it belongs to
  the design system instead of inheriting whatever the OS decided.

  It is one `<div>` and zero JavaScript. Modern `scrollbar-width` and
  `scrollbar-color` do the work where the engine honours them (Chrome 121+,
  Firefox), and a `::-webkit-scrollbar` block covers older Chromium and
  current Safari. The thumb rides the gray ramp in both light and dark mode
  and steps one shade toward the foreground on hover.

  Size the viewport with classes, not attrs - that is deliberate, so the
  component never grows a parallel sizing vocabulary next to Tailwind's:

      <.scroll_area class="max-h-72 rounded-lg border border-gray-200 p-4 dark:border-gray-800">
        <p :for={item <- @items}>{item}</p>
      </.scroll_area>

  Scroll sideways instead, and hint at the content past the edge:

      <.scroll_area orientation="horizontal" fade_edges class="w-full pb-2">
        <div class="flex gap-2">
          <.badge :for={tag <- @tags} label={tag} />
        </div>
      </.scroll_area>

  Both axes at once, with the scrollbar space reserved so the content does
  not shift the moment a scrollbar appears:

      <.scroll_area orientation="both" gutter_stable class="max-h-64 max-w-full">
        <pre><code>{@snippet}</code></pre>
      </.scroll_area>

  ## The platform truth

  Scrollbars are the operating system's, not ours. On macOS with "Show
  scroll bars: Automatically" - the default - the scrollbar is an overlay
  that appears while you scroll, sits on top of the content, ignores most
  theming and has no gutter to reserve. Most mobile browsers behave the
  same way. On Windows and Linux, and on macOS set to "Always", you get a
  classic scrollbar that takes real layout space and picks up the theming
  in full.

  So `<.scroll_area>` themes what the platform exposes. It does not fight
  the OS, and it will not make a Mac look like a PC:

    * `visibility="always"` is a *request*. WebKit honours it, because
      giving `::-webkit-scrollbar` an explicit size opts that element out
      of overlay rendering. Firefox has no force-visible mechanism, so
      there it is silently ignored.
    * `gutter_stable` is a no-op wherever scrollbars are overlays, because
      an overlay has no gutter to reserve. It is not broken; there is
      simply nothing to reserve.
    * `scrollbar-color` has no hover state, so on Chrome 121+ and Firefox
      the thumb keeps one colour. The hover step only shows on engines
      taking the `::-webkit-scrollbar` path.

  ## Fade edges

  `fade_edges` applies a `mask-image` gradient on the scrolling axis (both,
  composited, when `orientation="both"`). The mask is static: it fades both
  edges regardless of scroll position, so content that fits without
  scrolling still gets softened at its edges. That is the v1 trade -
  scroll-position-aware fading needs either JS or `animation-timeline`,
  and neither earns its keep yet. Reach for `fade_edges` on regions that
  genuinely overflow.

  The mask is decorative and adds no DOM, so there is nothing for assistive
  tech to skip. It does apply to the whole element, though, border and
  background included - so put the border on a wrapper rather than on the
  scroll area itself when you combine the two, or you will watch the border
  fade out along with the content:

      <div class="rounded-lg border border-gray-200 p-4 dark:border-gray-800">
        <.scroll_area fade_edges class="max-h-56">...</.scroll_area>
      </div>

  ## Accessibility

  There is no ARIA pattern for a scroll container. What matters is that a
  keyboard user can reach the content and move it:

    * The container renders `tabindex="0"`, which is what makes arrow keys,
      Page Up/Down, Home and End scroll it. That is native browser
      behaviour and needs no JS. Being focusable, it takes the standard
      `focus-visible` ring - never a persistent focus fill.
    * Pass `tabindex="-1"` to remove the tab stop when everything inside is
      already focusable (a list of links, a menu). A second tab stop in
      front of focusable content is noise; a tab stop in front of a wall of
      unreachable text is the only way in.
    * Give it a name when it is a standalone region:
      `<.scroll_area aria-label="Chat messages">`. With `aria-label` or
      `aria-labelledby` present the container also renders `role="region"`,
      so it lands in the landmark list under that name. Without a name no
      role is emitted - an unnamed region is landmark noise, not a service.
      An explicit `role` you pass always wins.
  """
  use Phoenix.Component

  attr :orientation, :string,
    default: "vertical",
    values: ["vertical", "horizontal", "both"],
    doc: "which axis scrolls: vertical (overflow-y), horizontal (overflow-x), or both"

  attr :fade_edges, :boolean,
    default: false,
    doc:
      "fade content out at the scroll edges with a mask-image gradient, hinting that more content exists past the clip. Masks apply on the scrolling axis only, and are static - they do not track scroll position"

  attr :gutter_stable, :boolean,
    default: false,
    doc:
      "reserve scrollbar space with scrollbar-gutter: stable so content does not shift when the scrollbar appears or disappears. Classic scrollbars only - overlay scrollbars have no gutter to reserve"

  attr :visibility, :string,
    default: "auto",
    values: ["auto", "always"],
    doc:
      "auto follows the platform (overlay scrollbars appear on scroll on macOS); always requests a persistently visible scrollbar where the engine allows it - see the platform-truth note in the module docs"

  attr :class, :any,
    default: nil,
    doc:
      "size the viewport here, e.g. class=\"max-h-72\" or class=\"max-w-full\" - sizing is deliberately class-driven, not attr-driven"

  attr :rest, :global

  slot :inner_block, required: true

  @doc """
  A themed scroll container: native scrollbars, styled to match.

  See `PetalComponents.ScrollArea` for usage, the platform caveats around
  overlay scrollbars, and the accessibility notes.
  """
  def scroll_area(assigns) do
    assigns = update(assigns, :rest, &a11y_defaults/1)

    ~H"""
    <div
      class={[
        "pc-scroll-area",
        "pc-scroll-area--#{@orientation}",
        @fade_edges && "pc-scroll-area--fade",
        @gutter_stable && "pc-scroll-area--gutter-stable",
        @visibility == "always" && "pc-scroll-area--always",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # tabindex="0" is what makes the arrow keys work, so it is the default -
  # but it is a plain global, so `tabindex="-1"` from the caller wins.
  # role="region" only rides along when there is a name to give it: an
  # unnamed landmark adds an entry to the region list that says nothing.
  defp a11y_defaults(rest) do
    rest = Map.put_new(rest, :tabindex, "0")

    if named?(rest) do
      Map.put_new(rest, :role, "region")
    else
      rest
    end
  end

  defp named?(rest) do
    Map.has_key?(rest, :"aria-label") or Map.has_key?(rest, :"aria-labelledby")
  end
end
