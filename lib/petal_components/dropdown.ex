defmodule PetalComponents.Dropdown do
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

  attr :placement, :string,
    default: "left",
    values: ["left", "right"],
    doc:
      ~s|which way the panel GROWS from the trigger, not which side it sits on: "left" grows it leftward, right edges aligned, the way a menu in the right-hand corner of a navbar wants; "right" grows it rightward from the trigger's left edge|

  attr :direction, :string,
    default: "auto",
    values: ["auto", "up", "down"],
    doc:
      ~s|which way the panel opens vertically. "auto" measures on every open and flips upward when the viewport leaves no room below (needs the PetalDropdown hook). "up" and "down" are the answer when you already know - a menu pinned to the bottom of a sidebar opens up, full stop - and they skip the hook entirely: no measuring, no listeners, no first-frame correction|

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
    assigns =
      assigns
      |> assign_new(:options_container_id, fn -> "dropdown_#{Ecto.UUID.generate()}" end)

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
        {js_attributes("options_container", @options_container_id, @direction)}
        class={[
          placement_class(@placement),
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

  # The third argument is per-clause: "container" takes the caller's on_close
  # JS, "options_container" takes the resolved direction.
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
  defp js_attributes("options_container", _options_container_id, direction) do
    Map.merge(%{style: "display: none;"}, direction_attributes(direction))
  end

  # PetalDropdown measures on open and marks the panel `data-flip` when
  # the viewport leaves no room below the trigger - a user menu at the
  # bottom of a sidebar opens upward instead of off-screen. Register the
  # bundled hooks (see README) to get it; without them the panel keeps
  # its old always-downward behaviour rather than breaking.
  defp direction_attributes("auto"), do: %{"phx-hook": "PetalDropdown"}

  # An explicit direction is already the answer, so there is nothing to
  # measure. The hook never attaches: no scroll/resize listeners, no
  # MutationObserver, and for "up" no first frame rendered downward before
  # the measurement lands. "up" is simply the flipped state, held open - the
  # same `data-flip` the hook would have written, only it never comes off.
  defp direction_attributes("up"), do: %{"data-flip": ""}
  defp direction_attributes("down"), do: %{}

  defp placement_class("left"), do: "pc-dropdown__menu-items-wrapper-placement--left"
  defp placement_class("right"), do: "pc-dropdown__menu-items-wrapper-placement--right"

  defp get_disabled_classes(true), do: "pc-dropdown__menu-item--disabled"
  defp get_disabled_classes(false), do: ""
end
