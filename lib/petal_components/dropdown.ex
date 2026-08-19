defmodule PetalComponents.Dropdown do
  @moduledoc """
  The panel that hangs off a trigger, and the rows that go inside it.

  ## Where the panel opens: `side` and `align`

  Two questions, one attribute each. `side` is which side of the trigger the
  panel sits on: `"bottom"` is the ordinary menu, `"top"` opens it upward, and
  `"left"` / `"right"` open it *beside* the trigger instead of over the thing
  it belongs to - the account panel a sidebar pushes out into the content area.
  `align` is how the panel lines up along the other axis: `"start"` puts the
  leading edges flush, `"end"` the trailing ones. Above or below that reads
  horizontally (start grows the panel rightward, end grows it leftward); beside,
  it reads vertically (start aligns the tops, end aligns the bottoms).

  Leave `side` out and the panel opens downward and measures on every open,
  flipping upward when the viewport leaves no room below it. Name a side and
  there is nothing left to measure, so the hook never attaches.

  `placement` and `direction` are the older spelling of the same two questions.
  They keep working, unchanged, forever; prefer `side` and `align` in new code:

  | legacy              | prefer                        |
  | ------------------- | ----------------------------- |
  | `placement="left"`  | `align="end"`                 |
  | `placement="right"` | `align="start"`               |
  | `direction="up"`    | `side="top"`                  |
  | `direction="down"`  | `side="bottom"`               |
  | `direction="auto"`  | no `side` (the measured default) |

  Pass both spellings and `side` / `align` win.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias PetalComponents.Link
  import PetalComponents.Icon
  import PetalComponents.Helpers, only: [compose_js: 2]

  @transition_in_base "transition transform ease-out duration-100"
  @transition_in_start "transform opacity-0 scale-95"
  @transition_in_end "transform opacity-100 scale-100"

  @transition_out_base "transition ease-in duration-75"
  @transition_out_start "transform opacity-100 scale-100"
  @transition_out_end "transform opacity-0 scale-95"

  attr :options_container_id, :string
  attr :label, :string, default: nil, doc: "labels your dropdown option"
  attr :class, :any, default: nil, doc: "any extra CSS class for the parent container"

  attr :trigger_class, :string,
    default: nil,
    doc: "additional classes for the trigger button"

  attr :menu_items_wrapper_class, :any,
    default: nil,
    doc: "any extra CSS class for menu item wrapper container"

  attr :on_close, JS,
    default: %JS{},
    doc: "additional JS commands to run when the dropdown closes (LiveView.JS only)"

  attr :side, :string,
    default: nil,
    values: [nil, "bottom", "top", "left", "right"],
    doc:
      ~s|which side of the trigger the panel opens on. "bottom" is the ordinary menu and "top" opens it upward. "left" and "right" open it BESIDE the trigger, over whatever is next to it rather than over the thing it belongs to - the account panel a sidebar pushes out into the content area. Left out, the panel opens downward and measures on every open, flipping upward when the viewport leaves no room below (the PetalDropdown hook). Naming a side skips the hook: you have already answered the question it existed to ask|

  attr :align, :string,
    default: nil,
    values: [nil, "start", "end"],
    doc:
      ~s|how the panel lines up along the other axis: leading edges flush ("start") or trailing edges flush ("end"). Above or below the trigger that is horizontal - "start" aligns the left edges so the panel grows rightward, "end" aligns the right edges so it grows leftward, which is what a menu in a right-hand corner wants. Beside the trigger it is vertical - "start" aligns the tops, "end" aligns the bottoms, which is what a user menu at the bottom of a sidebar wants. Left out it falls back to placement above and below (so "end" by default), and to "start" beside|

  attr :placement, :string,
    default: "left",
    values: ["left", "right"],
    doc:
      ~s|the legacy spelling of align, kept working: "left" is align="end" (the panel grows leftward, right edges aligned, the way a menu in the right-hand corner of a navbar wants) and "right" is align="start" (it grows rightward from the trigger's left edge). Prefer align in new code, and note that placement only has an opinion about a panel above or below - beside the trigger, side already answers the horizontal question|

  attr :direction, :string,
    default: "auto",
    values: ["auto", "up", "down"],
    doc:
      ~s|the legacy spelling of side on the vertical axis, kept working: "up" is side="top", "down" is side="bottom", and "auto" is the measured default you get by naming neither - it flips upward when the viewport leaves no room below (needs the PetalDropdown hook). Prefer side in new code|

  attr :rest, :global

  slot :trigger_element,
    doc:
      "custom trigger content. Rendered INSIDE the dropdown's own <button>, so never nest interactive elements (<.button>, links) here - browsers split nested buttons and the toggle binding breaks. Style the built-in trigger via trigger_class instead, e.g. trigger_class=\"pc-button pc-button--primary pc-button--md\""

  slot :inner_block, required: false

  @doc """
    <.dropdown label="Dropdown">
      <.dropdown_menu_item link_type="button">
        <.icon name="hero-home" class="w-5 h-5 text-gray-500" />
        Button item with icon
      </.dropdown_menu_item>
      <.dropdown_menu_item link_type="a" to="/" label="a item" />
      <.dropdown_menu_item link_type="a" to="/" disabled label="disabled item" />
      <.dropdown_menu_item link_type="live_patch" to="/" label="Live Patch item" />
      <.dropdown_menu_item link_type="live_redirect" to="/" label="Live Redirect item" />
    </.dropdown>
  """
  def dropdown(assigns) do
    side = resolve_side(assigns.side, assigns.direction)

    assigns =
      assigns
      |> assign_new(:options_container_id, fn -> "dropdown_#{Ecto.UUID.generate()}" end)
      |> assign(:resolved_side, side)
      |> assign(:resolved_align, resolve_align(assigns.align, assigns.placement, side))

    ~H"""
    <div
      {@rest}
      {js_attributes("container", @options_container_id, @on_close)}
      class={[@class, "pc-dropdown"]}
    >
      <div>
        <button
          type="button"
          class={[
            trigger_button_classes(@label, @trigger_element),
            @trigger_class
          ]}
          {js_attributes("button", @options_container_id)}
          aria-haspopup="true"
          data-pc-dropdown-trigger
        >
          <span class="sr-only">Open options</span>

          <%= if @label do %>
            {@label}
            <.icon name="hero-chevron-down-mini" class="pc-dropdown__chevron" />
          <% end %>

          <%= if @trigger_element do %>
            {render_slot(@trigger_element)}
          <% end %>

          <%= if !@label && @trigger_element == [] do %>
            <.icon name="hero-ellipsis-vertical-solid" class="w-5 h-5 pc-dropdown__ellipsis" />
          <% end %>
        </button>
      </div>
      <div
        {js_attributes("options_container", @options_container_id, @resolved_side)}
        class={[
          side_class(@resolved_side, @resolved_align),
          align_class(@resolved_side, @resolved_align),
          @menu_items_wrapper_class,
          "pc-dropdown__menu-items-wrapper"
        ]}
        role="menu"
        id={@options_container_id}
        aria-orientation="vertical"
        aria-labelledby="options-menu"
      >
        <div class="py-1" role="none">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  attr :to, :string, default: nil, doc: "link path"
  attr :label, :string, doc: "link label"
  attr :class, :any, default: nil, doc: "any additional CSS classes"
  attr :disabled, :boolean, default: false

  attr :link_type, :string,
    default: "button",
    values: ["a", "live_patch", "live_redirect", "button"]

  attr :rest, :global, include: ~w(method download hreflang ping referrerpolicy rel target type)
  slot :inner_block, required: false

  def dropdown_menu_item(assigns) do
    ~H"""
    <Link.a
      link_type={@link_type}
      to={@to}
      class={[@class, "pc-dropdown__menu-item", get_disabled_classes(@disabled)]}
      disabled={@disabled}
      role="menuitem"
      {@rest}
    >
      {render_slot(@inner_block) || @label}
    </Link.a>
    """
  end

  @doc """
  A non-interactive heading for a group of menu items.

      <.dropdown_menu_label>Signed in as matt@petal.build</.dropdown_menu_label>
  """
  attr :class, :any, default: nil, doc: "any additional CSS classes"
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu_label(assigns) do
    ~H"""
    <div class={["pc-dropdown__label", @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  A row of panel content that is a control rather than a command - a theme
  switcher, a plan badge, a storage meter. Same padding and type scale as a
  menu item, but it never behaves like one.

      <.dropdown_menu_row>
        <span>Theme</span>
        <.color_scheme_switch id="menu-scheme" variant="segmented" class="ml-auto" />
      </.dropdown_menu_row>

  ## The ARIA call

  `role="none"` is deliberate. The panel is a `role="menu"`, whose only valid
  children are menu items, groups and separators, so a widget parked straight
  underneath it is out of spec whichever way you slice it. The two ways round
  that both cost something: re-express the control as `menuitemradio` items
  (conformant, but then it is a list of commands, not a switch), or wrap it in
  a `menuitem` and cancel the activation (what a lot of React menus do, and a
  `menuitem` containing focusable controls is its own violation). This row
  takes the third road: it opts *out* of the menu with `role="none"` - the
  same marker the panel already puts on its own inner wrapper - and lets
  whatever you put inside keep its native semantics. A radio group stays a
  radio group, reachable by Tab and announced as one.

  The honest caveat: a screen reader driving the panel in menu mode may skip
  the row, because as far as the menu is concerned it isn't there. Put nothing
  in it that has no other home in your UI. If the choice really belongs in the
  menu, express it as menu items instead - `color_scheme_switch`'s "dropdown"
  variant is exactly that shape.
  """
  attr :class, :any, default: nil, doc: "any additional CSS classes"
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu_row(assigns) do
    ~H"""
    <div class={["pc-dropdown__row", @class]} role="none" {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  A thin divider between groups of menu items.
  """
  attr :class, :any, default: nil, doc: "any additional CSS classes"
  attr :rest, :global

  def dropdown_menu_separator(assigns) do
    ~H"""
    <div class={["pc-dropdown__separator", @class]} role="separator" {@rest}></div>
    """
  end

  defp trigger_button_classes(nil, []),
    do: "pc-dropdown__trigger-button--no-label"

  defp trigger_button_classes(_label, []),
    do: "pc-dropdown__trigger-button--with-label"

  defp trigger_button_classes(_label, _trigger_element),
    do: "pc-dropdown__trigger-button--with-label-and-trigger-element"

  # side + align are the vocabulary. placement + direction are the older
  # spelling of the same two questions, and they resolve onto it here, once,
  # so nothing downstream has to know there were ever two ways to ask. An
  # explicit side or align wins over the legacy attr it replaces.
  #
  # :auto is the one state `side` has no name for: no side, no direction, so
  # the panel measures on open. It is an atom rather than a string precisely
  # because it is not a value a caller can pass.
  defp resolve_side(nil, "auto"), do: :auto
  defp resolve_side(nil, "up"), do: "top"
  defp resolve_side(nil, "down"), do: "bottom"
  defp resolve_side(side, _direction), do: side

  # placement is a horizontal idea, so it only answers for a panel above or
  # below. Beside the trigger, `side` has already settled the horizontal
  # question and align is the vertical one placement never had an opinion
  # about, so it starts from tops-flush rather than from placement's default.
  defp resolve_align(nil, placement, side) when side in [:auto, "bottom", "top"],
    do: legacy_align(placement)

  defp resolve_align(nil, _placement, _side), do: "start"
  defp resolve_align(align, _placement, _side), do: align

  defp legacy_align("left"), do: "end"
  defp legacy_align("right"), do: "start"

  # The third argument is per-clause: "container" takes the caller's on_close
  # JS, "options_container" takes the resolved side.
  defp js_attributes(type, options_container_id, opt \\ %JS{})

  defp js_attributes("container", options_container_id, on_close) do
    hide =
      compose_js(
        on_close,
        JS.hide(
          to: "##{options_container_id}",
          transition: {@transition_out_base, @transition_out_start, @transition_out_end}
        )
      )

    %{
      "phx-click-away": hide,
      "phx-window-keydown": hide,
      "phx-key": "Escape"
    }
  end

  defp js_attributes("button", options_container_id, _on_close) do
    %{
      "phx-click":
        JS.toggle(
          to: "##{options_container_id}",
          display: "block",
          in: {@transition_in_base, @transition_in_start, @transition_in_end},
          out: {@transition_out_base, @transition_out_start, @transition_out_end}
        )
    }
  end

  # One merged map, not a second `{...}` interpolation on the panel: attribute
  # order inside one map is at least a single decision, where two adjacent
  # interpolations pin phx-hook after style whatever the map does. (Erlang's
  # small-map iteration order is not something to lean on either way - a clean
  # rebuild of an untouched tree reorders these attributes on its own.)
  defp js_attributes("options_container", _options_container_id, side) do
    Map.merge(%{style: "display: none;"}, side_attributes(side))
  end

  # PetalDropdown measures on open and marks the panel `data-flip` when
  # the viewport leaves no room below the trigger - a user menu at the
  # bottom of a sidebar opens upward instead of off-screen. Register the
  # bundled hooks (see README) to get it; without them the panel keeps
  # its old always-downward behaviour rather than breaking.
  defp side_attributes(:auto), do: %{"phx-hook": "PetalDropdown"}

  # An explicit side is already the answer, so there is nothing to measure.
  # The hook never attaches: no scroll/resize listeners, no MutationObserver,
  # and for "top" no first frame rendered downward before the measurement
  # lands. "top" is simply the flipped state, held open - the same
  # `data-flip` the hook would have written, only it never comes off.
  defp side_attributes("top"), do: %{"data-flip": ""}
  defp side_attributes("bottom"), do: %{}

  # A panel beside the trigger has no vertical flip to measure - it isn't
  # sitting on the axis the flip is about. If it runs off the bottom of a
  # short viewport that is the placement the caller chose, and the honest
  # fix is the other side, not a second measuring pass. (One could come
  # later; there is nothing here to migrate when it does.)
  defp side_attributes(side) when side in ["left", "right"], do: %{}

  # Above or below, align is the horizontal question, and the two classes
  # that answer it are the ones placement has always emitted: --left is
  # align="end" (right edges flush), --right is align="start". The class
  # NAMES stay as they are because they are a published CSS contract that
  # consumers override by name; only the attribute that picks them is new.
  defp side_class(side, align) when side in [:auto, "bottom", "top"],
    do: vertical_align_class(align)

  defp side_class("left", _align), do: "pc-dropdown__menu-items-wrapper-side--left"
  defp side_class("right", _align), do: "pc-dropdown__menu-items-wrapper-side--right"

  defp vertical_align_class("end"), do: "pc-dropdown__menu-items-wrapper-placement--left"
  defp vertical_align_class("start"), do: "pc-dropdown__menu-items-wrapper-placement--right"

  # Only a side-out panel carries a second class: the side rule anchors it
  # horizontally, this one anchors it vertically (and spends the horizontal
  # half of the transform origin the side rule set). Above and below, one
  # class already says everything, and a nil here keeps that markup exactly
  # as it was.
  defp align_class(side, _align) when side in [:auto, "bottom", "top"], do: nil
  defp align_class(_side, "start"), do: "pc-dropdown__menu-items-wrapper-align--start"
  defp align_class(_side, "end"), do: "pc-dropdown__menu-items-wrapper-align--end"

  defp get_disabled_classes(true), do: "pc-dropdown__menu-item--disabled"
  defp get_disabled_classes(false), do: ""
end
