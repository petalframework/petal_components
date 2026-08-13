defmodule PetalComponents.SlideOver do
  @moduledoc """
  An edge-attached panel - a "sheet" - for forms and detail views that don't warrant a
  full page. `origin` decides which edge it slides from.

      <.slide_over id="profile" origin="right" title="Edit profile">
        Body
        <:footer>
          <button>Save</button>
        </:footer>
      </.slide_over>

  ## Bottom-sheet drawer mode

  `origin="bottom"` is a first-class mobile drawer rather than a plain full-width panel:
  rounded top corners, a border, `env(safe-area-inset-bottom)` padding, and a grab-handle
  pill. The handle appears automatically - `handle` defaults to `nil`, which resolves to
  `true` for `origin="bottom"` and `false` everywhere else. Pass it explicitly to override
  in either direction.

      <.slide_over id="filters" origin="bottom" title="Filters">
        Body
      </.slide_over>

  Drag-to-dismiss is on by default for bottom sheets. Drag the sheet down past roughly a
  quarter of its height, or flick it down, and it closes through the exact same path as
  Escape, the close button and click-away - the server still receives one
  `"close_slide_over"` event.

      <.slide_over id="queue" origin="bottom" snap_points={[0.4, 0.9]} initial_snap={0.4}>
        Body
      </.slide_over>

  `snap_points` are viewport-height fractions the drawer can rest at. It opens at
  `initial_snap` (the first point when unset), drags between the points, and only a
  downward release below the lowest point dismisses.

  Dragging is a pointer-only enhancement layered over the dialog. Keyboard and
  screen-reader users get exactly the behaviour they had before: `role="dialog"`,
  `aria-modal`, focus moved into the panel on open, Escape to close. The handle is
  `aria-hidden` because it is decorative - the drag is the interaction, not the element.
  Snap changes are visual only and are not announced. Under `prefers-reduced-motion` the
  drawer settles instantly instead of springing.

  ## The `scale_background` trade-off

  `scale_background` shrinks and rounds the page behind an open drawer. It is off by
  default because it puts a `transform` on the page wrapper, and a transformed ancestor
  becomes the containing block for every `position: fixed` descendant - sticky headers and
  fixed toolbars inside the page will move with it. It also forces a full-page repaint on
  open and close. Turn it on only when the page behind the drawer is simple, and mark the
  wrapper it should scale:

      <div data-pc-drawer-wrapper>
        <%!-- page content --%>
      </div>

      <.slide_over id="share" origin="bottom" scale_background title="Share">
        Body
      </.slide_over>

  Left, right and top sheets are unchanged by all of the above: no handle, no drag, no
  hook.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import PetalComponents.Helpers, only: [compose_js: 2]
  import PetalComponents.Icon

  attr :id, :string, default: "slide-over"

  attr(:origin, :string,
    default: "right",
    values: ["left", "right", "top", "bottom"],
    doc: "slideover point of origin"
  )

  attr(:close_slide_over_target, :string,
    default: nil,
    doc:
      "close_slide_over_target allows you to target a specific live component for the close event to go to. eg: close_slide_over_target={@myself}"
  )

  attr(:close_on_click_away, :boolean,
    default: true,
    doc: "whether the slideover should close when a user clicks away"
  )

  attr(:close_on_escape, :boolean,
    default: true,
    doc: "whether the slideover should close when a user hits escape"
  )

  attr(:title, :string, default: nil, doc: "slideover title")

  attr(:description, :string,
    default: nil,
    doc: "a muted line under the title, for context the panel needs"
  )

  attr(:max_width, :string,
    default: "md",
    values: ["sm", "md", "lg", "xl", "2xl", "full"],
    doc: "sets container max-width"
  )

  attr :on_open, JS,
    default: %JS{},
    doc: "additional JS commands to run when the slide over opens"

  attr :on_close, JS,
    default: %JS{},
    doc: "additional JS commands to run when the slide over closes"

  attr(:handle, :boolean,
    default: nil,
    doc:
      ~s|show the grab-handle pill. Defaults to true when origin="bottom", false otherwise. Set explicitly to override.|
  )

  attr(:drag_to_dismiss, :boolean,
    default: true,
    doc:
      ~s|for origin="bottom": drag the sheet down past a threshold (or flick with enough velocity) to dismiss. Pointer-only; Escape and the close button always work regardless. Ignored for other origins.|
  )

  attr(:snap_points, :list,
    default: nil,
    doc:
      "optional list of viewport-height fractions the drawer can rest at, e.g. [0.4, 0.9]. Drag between them; a fast flick skips to the next point in the flick direction. nil means content-height with a single rest position."
  )

  attr(:initial_snap, :float,
    default: nil,
    doc:
      "which snap point the drawer opens at. Must be a member of snap_points. Defaults to the first entry."
  )

  attr(:scale_background, :boolean,
    default: false,
    doc:
      "scales and rounds the page behind the drawer while it is open. Off by default because it transforms the whole page (see the moduledoc for the trade-offs). Requires the consumer to mark the page wrapper with data-pc-drawer-wrapper."
  )

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:hide, :boolean, default: false, doc: "slideover is hidden")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  slot(:footer,
    required: false,
    doc: "a pinned action row at the bottom of the panel (save/cancel buttons)"
  )

  def slide_over(assigns) do
    assigns = assign_drawer(assigns)

    ~H"""
    <div
      {@rest}
      phx-mounted={!@hide && show_slide_over(@on_open, @origin, @id)}
      phx-remove={compose_js(@on_close, hide_slide_over(@origin, @id, @close_slide_over_target))}
      class="hidden pc-slide-over"
      id={@id}
    >
      <div id={"#{@id}-overlay"} class="hidden pc-slideover__overlay" aria-hidden="true"></div>

      <div
        class={["pc-slideover__wrapper", get_margin_classes(@origin), @class]}
        role="dialog"
        aria-modal="true"
        aria-labelledby={@title && "#{@id}-title"}
        aria-describedby={@description && "#{@id}-description"}
        aria-label={!@title && "slide over"}
      >
        <div
          id={"#{@id}-content"}
          class={[get_classes(@max_width, @origin, @class), @drawer? && "pc-slideover__box--drawer"]}
          style={@drawer_height}
          phx-hook={@drawer_hook}
          data-pc-drawer-hide={
            @drawer_hook &&
              compose_js(@on_close, hide_slide_over(@origin, @id, @close_slide_over_target))
          }
          data-drag-dismiss={@drawer? && @drag_to_dismiss && "true"}
          data-snap-points={@snap_points_attr}
          data-initial-snap={@initial_snap_attr}
          data-scale-background={@drawer? && @scale_background && "true"}
          phx-click-away={
            @close_on_click_away &&
              compose_js(@on_close, hide_slide_over(@origin, @id, @close_slide_over_target))
          }
          phx-window-keydown={
            @close_on_escape &&
              compose_js(@on_close, hide_slide_over(@origin, @id, @close_slide_over_target))
          }
          phx-key="escape"
        >
          <div
            :if={@show_handle?}
            class="pc-slideover__handle"
            data-pc-drawer-handle
            aria-hidden="true"
          >
            <span class="pc-slideover__handle__pill"></span>
          </div>
          <!-- Header -->
          <div class="pc-slideover__header">
            <div class="pc-slideover__header__container">
              <div class="pc-slideover__header__titles">
                <div :if={@title} id={"#{@id}-title"} class="pc-slideover__header__text">
                  {@title}
                </div>
                <div :if={@description} id={"#{@id}-description"} class="pc-slideover__description">
                  {@description}
                </div>
              </div>

              <button
                type="button"
                phx-click={
                  compose_js(@on_close, hide_slide_over(@origin, @id, @close_slide_over_target))
                }
                class="pc-slideover__header__button"
              >
                <div class="sr-only">Close</div>
                <.icon name="hero-x-mark" class="pc-slideover__header__close-svg" />
              </button>
            </div>
          </div>
          <!-- Content -->
          <div class="pc-slideover__content">
            {render_slot(@inner_block)}
          </div>
          <div :if={@footer != []} class="pc-slideover__footer">
            {render_slot(@footer)}
          </div>
        </div>
      </div>
    </div>
    """
  end

  def show_slide_over(origin, id) when is_binary(origin) and is_binary(id),
    do: show_slide_over(%JS{}, origin, id)

  def show_slide_over(origin) when is_binary(origin),
    do: show_slide_over(%JS{}, origin, "slide-over")

  def show_slide_over(js, origin, id) do
    {start_class, end_class} = get_transition_classes(origin)

    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-overlay",
      time: 300,
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-content",
      time: 300,
      display: "flex",
      transition: {"transition-all transform ease-out duration-300", start_class, end_class}
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  # The live view that calls <.slide_over> will need to handle the "close_slide_over" event. eg:
  # def handle_event("close_slide_over", _, socket) do
  #   {:noreply, push_patch(socket, to: Routes.moderate_users_path(socket, :index))}
  # end
  def hide_slide_over(origin, id \\ "slide-over", close_slide_over_target \\ nil) do
    {end_class, start_class} = get_transition_classes(origin)

    js =
      JS.remove_class("overflow-hidden", to: "body")
      |> JS.hide(
        transition: {"ease-in duration-200", "opacity-100", "opacity-0"},
        to: "##{id}-overlay"
      )
      |> JS.hide(
        transition: {"ease-in duration-200", start_class, end_class},
        to: "##{id}-content"
      )
      |> JS.hide(to: "##{id}", transition: {"duration-200", "", ""})

    if close_slide_over_target do
      JS.push(js, "close_slide_over", target: close_slide_over_target)
    else
      JS.push(js, "close_slide_over")
    end
  end

  defp get_transition_classes(origin) do
    case origin do
      "left" -> {"-translate-x-full", "translate-x-0"}
      "right" -> {"translate-x-full", "translate-x-0"}
      "top" -> {"-translate-y-full", "translate-y-0"}
      "bottom" -> {"translate-y-full", "translate-y-0"}
    end
  end

  defp get_classes(max_width, origin, class) do
    base_classes = "hidden pc-slideover__box"

    slide_over_classes =
      case origin do
        "left" ->
          "fixed left-0 inset-y-0 transform -translate-x-full border-r border-gray-200 dark:border-white/10"

        "right" ->
          "fixed right-0 inset-y-0 transform translate-x-full border-l border-gray-200 dark:border-white/10"

        "top" ->
          "fixed inset-x-0 top-0 transform -translate-y-full border-b border-gray-200 dark:border-white/10"

        "bottom" ->
          "fixed inset-x-0 bottom-0 transform translate-y-full border-t border-gray-200 dark:border-white/10"
      end

    max_width_class =
      case origin do
        x when x in ["left", "right"] ->
          "pc-slideover__box--#{max_width}"

        x when x in ["top", "bottom"] ->
          ""
      end

    custom_classes = class

    [slide_over_classes, max_width_class, base_classes, custom_classes]
  end

  # Bottom sheets are the only origin with a drag layer, so everything the hook
  # needs is resolved here and emitted as data attributes. Side sheets fall
  # through with every drawer assign nil - no handle, no hook, no new markup.
  defp assign_drawer(assigns) do
    drawer? = assigns.origin == "bottom"
    snaps = drawer? && normalize_snap_points(assigns.snap_points)

    assigns
    |> assign(:drawer?, drawer?)
    |> assign(:show_handle?, resolve_handle(assigns.handle, drawer?))
    |> assign(:drawer_hook, drawer_hook(assigns, drawer?, snaps))
    |> assign(:snap_points_attr, snaps && Enum.map_join(snaps, ",", &to_string/1))
    |> assign(:initial_snap_attr, snaps && to_string(resolve_initial_snap(assigns, snaps)))
    |> assign(:drawer_height, snaps && "height: #{format_dvh(Enum.max(snaps))}dvh")
  end

  # A fraction of 0.9 is 90.0 in Elixir, and "height: 90.0dvh" is not markup
  # anyone wants to read in devtools. Whole numbers print whole; the rest keep
  # their decimals, rounded to kill float-multiplication noise (0.29 * 100).
  defp format_dvh(fraction) do
    value = Float.round(fraction * 100.0, 4)

    if value == Float.floor(value) do
      value |> trunc() |> Integer.to_string()
    else
      :erlang.float_to_binary(value, [:short])
    end
  end

  # nil means "whatever suits this origin"; an explicit boolean always wins.
  defp resolve_handle(nil, drawer?), do: drawer?
  defp resolve_handle(handle, _drawer?), do: handle

  # Only bottom sheets that actually do something pointer-driven pay for a hook.
  # A plain non-draggable bottom sheet stays CSS + LiveView.JS only.
  defp drawer_hook(_assigns, false, _snaps), do: nil

  defp drawer_hook(assigns, true, snaps) do
    if assigns.drag_to_dismiss || snaps || assigns.scale_background do
      "PetalDrawer"
    end
  end

  defp normalize_snap_points(points) when is_list(points) and points != [] do
    points
    |> Enum.filter(&is_number/1)
    |> Enum.sort()
    |> case do
      [] -> nil
      sorted -> sorted
    end
  end

  defp normalize_snap_points(_points), do: nil

  # An initial_snap that isn't one of the points would leave the hook resting at a
  # position the user can never drag back to, so fall back to the lowest point.
  defp resolve_initial_snap(%{initial_snap: initial}, snaps) when is_number(initial) do
    if initial in snaps, do: initial, else: List.first(snaps)
  end

  defp resolve_initial_snap(_assigns, snaps), do: List.first(snaps)

  defp get_margin_classes(margin) do
    case margin do
      "left" -> "mr-10"
      "right" -> "ml-10"
      "top" -> "mb-10"
      "bottom" -> "mt-10"
    end
  end
end
