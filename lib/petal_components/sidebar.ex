defmodule PetalComponents.Sidebar do
  @moduledoc """
  The app-shell navigation sidebar: a fixed rail of grouped links that collapses
  to icons on desktop and takes over as a sheet on mobile.

  This is the chrome, not the list. `sidebar_item/1` is here for when you are
  writing the nav markup anyway, but when your nav already ships as data,
  `PetalComponents.Menu.vertical_menu/1` renders the same list from plain maps
  and drops straight into the content area. The sidebar is the shell it sits in.

  Five function components compose the shell:

    * `sidebar_shell/1` - the flex wrapper holding the sidebar and your page content
    * `sidebar/1` - the `<nav>` landmark itself, with header/footer slots
    * `sidebar_group/1` - a labelled (optionally collapsible) run of items
    * `sidebar_item/1` - one link, or a parent with nested sub-items
    * `sidebar_trigger/1` - the button that collapses the rail or opens the sheet

  ## Usage

      <.sidebar_shell for="app-sidebar">
        <:sidebar>
          <.sidebar id="app-sidebar" label="Main" collapsible="icon">
            <:header>
              <.icon name="hero-cube" class="w-6 h-6 shrink-0" />
              <span class="pc-sidebar__brand">Acme</span>
            </:header>

            <.sidebar_group label="Workspace">
              <.sidebar_item label="Dashboard" path="/" icon="hero-home" active />
              <.sidebar_item label="Inbox" path="/inbox" icon="hero-inbox" badge="12" />
            </.sidebar_group>

            <.sidebar_group label="Account" collapsible open>
              <.sidebar_item label="Settings" icon="hero-cog-6-tooth">
                <.sidebar_item label="Profile" path="/settings/profile" />
                <.sidebar_item label="Billing" path="/settings/billing" />
              </.sidebar_item>
            </.sidebar_group>

            <:footer>
              <.sidebar_item label="Sign out" path="/sign-out" icon="hero-arrow-left-start-on-rectangle" />
            </:footer>
          </.sidebar>
        </:sidebar>

        <header class="flex items-center gap-3 p-4">
          <.sidebar_trigger for="app-sidebar" target="mobile" />
          <h1>Dashboard</h1>
        </header>
        <main class="p-4">Your page</main>
      </.sidebar_shell>

  ## Collapse and state

  Collapse is client-side by design: `sidebar_trigger/1` flips a `data-collapsed`
  attribute on the sidebar with `Phoenix.LiveView.JS`, and CSS does the rest. No
  round trip, no hook.

  The server still owns the *initial* value through the `collapsed` attr, so the
  first paint is already correct and a `live_redirect` cannot flash the wrong
  state - the attribute is rendered, not read back from the client. To persist
  the choice across navigation, keep it in your own assign (or a session cookie
  you read in the plug pipeline) and pass it back in:

      <.sidebar id="app-sidebar" collapsed={@sidebar_collapsed}>

  ...then have the trigger tell the server as well as the DOM:

      <.sidebar_trigger for="app-sidebar" on_click={JS.push("toggle_sidebar")} />

  ## Responsive behaviour

  Below the `md` breakpoint (768px) a `collapsible="icon"` or `"offcanvas"`
  sidebar leaves the flow entirely and becomes an off-canvas sheet, opened by a
  `target="mobile"` trigger. While the sheet is open the shell's content region
  is marked `inert`, Escape closes it, clicking the scrim closes it, and focus
  returns to the trigger. `collapsible="none"` stays put at every width.

  ## Theming

  The sidebar reads two custom properties, so apps can retune widths without
  touching `pc-*` internals:

      .pc-sidebar { --pc-sidebar-width: 18rem; --pc-sidebar-icon-width: 4.5rem; }

  The breakpoint is fixed at `md` in this version; CSS media queries cannot read
  custom properties.
  """
  use Phoenix.Component

  import PetalComponents.Helpers, only: [compose_js: 2, uniq_id: 2]
  import PetalComponents.Icon
  import PetalComponents.Link

  alias Phoenix.LiveView.JS

  attr :for, :string,
    required: true,
    doc:
      "id of the `sidebar/1` this shell wraps. The content region is rendered as `<for>-main` so the trigger can mark it inert while the mobile sheet is open"

  attr :class, :any, default: nil, doc: "CSS class for the shell wrapper"
  attr :rest, :global

  slot :sidebar, required: true, doc: "the `sidebar/1` itself"

  slot :inner_block,
    required: true,
    doc:
      "everything else in the shell - topbar, page content. Marked inert while the sheet is open"

  @doc """
  The app shell: a flex row holding the sidebar beside your page content.

  Optional - a `sidebar/1` works inside your own layout too - but the shell is
  what gives the mobile sheet something to mark `inert`, so use it if you want
  the accessible sheet behaviour for free.
  """
  def sidebar_shell(assigns) do
    assigns = assign(assigns, :main_id, "#{Map.fetch!(assigns, :for)}-main")

    ~H"""
    <div class={["pc-sidebar-shell", @class]} {@rest}>
      {render_slot(@sidebar)}
      <div id={@main_id} class="pc-sidebar-shell__main">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :id, :string, required: true, doc: "unique id - `sidebar_trigger/1` targets this"

  attr :label, :string,
    default: "Sidebar",
    doc: "accessible name for the nav landmark (`aria-label`)"

  attr :side, :string,
    default: "left",
    values: ["left", "right"],
    doc: "which edge the sidebar sits on. Two sidebars in one shell just need different ids"

  attr :collapsible, :string,
    default: "icon",
    values: ["icon", "offcanvas", "none"],
    doc:
      "icon collapses to a rail of icons, offcanvas hides it completely, none pins it open at every width"

  attr :collapsed, :boolean,
    default: false,
    doc: "initial collapsed state, rendered server-side so the first paint is never wrong"

  attr :on_close, JS,
    default: %JS{},
    doc: "additional JS commands to run when the mobile sheet closes (LiveView.JS only)"

  attr :class, :any, default: nil, doc: "CSS class for the sidebar"
  attr :rest, :global

  slot :header, doc: "pinned top area - logo, workspace switcher"

  slot :footer,
    doc:
      ~s|pinned bottom area, typically a user menu. A dropdown here should align with the rail: align="start" on a left sidebar, align="end" on a right one, so the panel grows into the page instead of off the viewport|

  slot :inner_block, required: true, doc: "`sidebar_group/1` and `sidebar_item/1` content"

  @doc """
  The sidebar itself: a `<nav>` landmark wrapped in the collapse/sheet machinery.
  """
  def sidebar(assigns) do
    ~H"""
    <div
      id={@id}
      class={["pc-sidebar", @class]}
      data-side={@side}
      data-collapsible={@collapsible}
      data-collapsed={to_string(@collapsed)}
      data-mobile-open="false"
      data-close={hide_sidebar(@on_close, @id)}
      phx-window-keydown={JS.exec("data-close", to: "##{@id}[data-mobile-open='true']")}
      phx-key="escape"
      {@rest}
    >
      <div
        class="pc-sidebar__scrim"
        aria-hidden="true"
        phx-click={JS.exec("data-close", to: "##{@id}")}
      >
      </div>

      <%!-- Deliberately NOT LiveView's focus_wrap: its hook focuses the
      first focusable at mount whenever the element is displayed, and this
      panel is always displayed on desktop - so every page holding a
      sidebar stole keyboard focus into the nav on load. The sheet's
      containment doesn't need it: while open, the shell's content region
      is inert (nothing outside the sheet is focusable), show_sidebar
      moves focus in, and hide_sidebar returns it to the trigger. --%>
      <div id={"#{@id}-panel"} class="pc-sidebar__panel">
        <nav class="pc-sidebar__nav" aria-label={@label}>
          <div :if={@header != []} class="pc-sidebar__header">
            {render_slot(@header)}
          </div>

          <div class="pc-sidebar__content">
            {render_slot(@inner_block)}
          </div>

          <div :if={@footer != []} class="pc-sidebar__footer">
            {render_slot(@footer)}
          </div>
        </nav>
      </div>
    </div>
    """
  end

  attr :id, :string, default: nil, doc: "defaults to a slug of the label"
  attr :label, :string, default: nil, doc: "group heading. Omit for an unlabelled run of items"

  attr :collapsible, :boolean,
    default: false,
    doc: "turns the label into a disclosure button (WAI-ARIA disclosure pattern)"

  attr :open, :boolean, default: true, doc: "initial state when collapsible"

  attr :on_toggle, JS,
    default: %JS{},
    doc: "additional JS commands to run when the group is toggled (LiveView.JS only)"

  attr :class, :any, default: nil, doc: "CSS class for the group"
  attr :rest, :global

  slot :inner_block, required: true, doc: "`sidebar_item/1` children"

  @doc """
  A labelled run of items. Pass `collapsible` to make the label a disclosure toggle.
  """
  def sidebar_group(assigns) do
    # `attr default: nil` already puts :id in assigns, so assign_new would no-op.
    assigns =
      assign(assigns, :id, assigns.id || uniq_id(assigns.label || "group", "pc-sidebar-group"))

    ~H"""
    <div class={["pc-sidebar-group", @class]} {@rest}>
      <button
        :if={@label && @collapsible}
        type="button"
        class="pc-sidebar-group__toggle"
        aria-expanded={to_string(@open)}
        aria-controls={"#{@id}-items"}
        phx-click={toggle_group(@on_toggle, @id)}
      >
        <span class="pc-sidebar-group__label">{@label}</span>
        <.icon name="hero-chevron-right" class="pc-sidebar-group__chevron" />
      </button>

      <div :if={@label && !@collapsible} class="pc-sidebar-group__label">{@label}</div>

      <div id={"#{@id}-items"} class="pc-sidebar-group__items" data-open={to_string(@open)}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :id, :string, default: nil, doc: "defaults to a slug of the label"

  attr :label, :string,
    required: true,
    doc: "the item text. Kept for screen readers when collapsed"

  attr :path, :string, default: nil, doc: "where the item links to. Omit when it has sub-items"

  attr :icon, :any,
    default: nil,
    doc:
      ~s|a heroicon name ("hero-home"), a function component, or a raw SVG string - the house icon convention|

  attr :active, :boolean,
    default: false,
    doc:
      "marks the current page. Emits `aria-current=\"page\"`. Your app decides, never the component"

  attr :badge, :string, default: nil, doc: "trailing badge text, e.g. an unread count"

  attr :link_type, :string,
    default: "live_redirect",
    values: ["live_redirect", "live_patch", "a", "button"],
    doc: "how the item navigates, matching `PetalComponents.Link.a/1`"

  attr :open, :boolean, default: false, doc: "initial state of the sub-menu, when it has one"

  attr :on_toggle, JS,
    default: %JS{},
    doc: "additional JS commands to run when the sub-menu is toggled (LiveView.JS only)"

  attr :class, :any, default: nil, doc: "CSS class for the item"
  attr :rest, :global

  slot :inner_block, doc: "nested `sidebar_item/1` children. Turns the item into a disclosure"

  @doc """
  One navigation item: icon, label, optional badge, optional nested sub-items.
  """
  def sidebar_item(%{inner_block: []} = assigns) do
    ~H"""
    <.a
      to={@path}
      link_type={@link_type}
      class={["pc-sidebar-item", @active && "pc-sidebar-item--active", @class]}
      title={@label}
      aria-current={@active && "page"}
      {@rest}
    >
      <.sidebar_icon :if={@icon} icon={@icon} />
      <span class="pc-sidebar-item__label">{@label}</span>
      <span :if={@badge} class="pc-sidebar-item__badge">{@badge}</span>
    </.a>
    """
  end

  def sidebar_item(assigns) do
    assigns = assign(assigns, :id, assigns.id || uniq_id(assigns.label, "pc-sidebar-item"))

    ~H"""
    <div class="pc-sidebar-item__parent">
      <button
        type="button"
        class={["pc-sidebar-item", @active && "pc-sidebar-item--active", @class]}
        title={@label}
        aria-expanded={to_string(@open)}
        aria-controls={"#{@id}-sub"}
        phx-click={toggle_group(@on_toggle, @id)}
        {@rest}
      >
        <.sidebar_icon :if={@icon} icon={@icon} />
        <span class="pc-sidebar-item__label">{@label}</span>
        <span :if={@badge} class="pc-sidebar-item__badge">{@badge}</span>
        <.icon name="hero-chevron-right" class="pc-sidebar-item__chevron" />
      </button>

      <div id={"#{@id}-sub"} class="pc-sidebar-item__sub" data-open={to_string(@open)}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :for, :string, required: true, doc: "id of the `sidebar/1` this button controls"

  attr :id, :string,
    default: nil,
    doc:
      ~s|a `target="mobile"` trigger defaults to `"<for>-trigger"`, which is where focus returns when the sheet closes. Collapse triggers get no id by default, so a shell can carry both without colliding|

  attr :target, :string,
    default: "collapse",
    values: ["collapse", "mobile"],
    doc:
      "collapse toggles the desktop rail (hidden below md); mobile opens the off-canvas sheet (hidden from md up)"

  attr :label, :string, default: "Toggle sidebar", doc: "accessible name for the button"

  attr :on_click, JS,
    default: %JS{},
    doc:
      "additional JS commands to run on click - e.g. `JS.push(\"toggle_sidebar\")` to mirror the state server-side"

  attr :class, :any, default: nil, doc: "CSS class for the trigger"
  attr :rest, :global

  slot :inner_block, doc: "custom button content. Defaults to a hamburger/panel icon"

  @doc """
  The button that collapses the rail (`target="collapse"`) or opens the mobile
  sheet (`target="mobile"`).
  """
  def sidebar_trigger(assigns) do
    # Only the mobile trigger claims the derived id: it is where hide_sidebar/2
    # restores focus to, so exactly one element may hold it. A shell commonly has
    # both a burger and a rail toggle pointing at the same sidebar, and giving
    # them the same default id would duplicate it.
    assigns =
      assign(
        assigns,
        :id,
        assigns.id || if(assigns.target == "mobile", do: "#{Map.fetch!(assigns, :for)}-trigger")
      )

    ~H"""
    <button
      id={@id}
      type="button"
      class={["pc-sidebar-trigger", "pc-sidebar-trigger--#{@target}", @class]}
      aria-label={@label}
      aria-controls={@for}
      aria-expanded={@target == "mobile" && "false"}
      phx-click={
        if @target == "mobile",
          do: show_sidebar(@on_click, @for),
          else: toggle_sidebar(@on_click, @for)
      }
      {@rest}
    >
      <%= if @inner_block != [] do %>
        {render_slot(@inner_block)}
      <% else %>
        <.icon
          name={if @target == "mobile", do: "hero-bars-3", else: "hero-view-columns"}
          class="pc-sidebar-trigger__icon"
        />
      <% end %>
    </button>
    """
  end

  @doc """
  Toggles the desktop collapsed state of the sidebar with the given id.

  Pure client-side: flips `data-collapsed` and lets CSS do the work.
  """
  def toggle_sidebar(js \\ %JS{}, id) do
    compose_js(
      js,
      JS.toggle_attribute({"data-collapsed", "true", "false"}, to: "##{id}")
    )
  end

  @doc """
  Opens the mobile sheet for the sidebar with the given id.

  Marks the shell's content region inert, locks body scroll and moves focus into
  the nav.
  """
  def show_sidebar(js \\ %JS{}, id) do
    compose_js(
      js,
      %JS{}
      |> JS.set_attribute({"data-mobile-open", "true"}, to: "##{id}")
      |> JS.set_attribute({"aria-expanded", "true"}, to: "##{id}-trigger")
      |> JS.set_attribute({"inert", ""}, to: "##{id}-main")
      |> JS.add_class("overflow-hidden", to: "body")
      |> JS.focus_first(to: "##{id} .pc-sidebar__nav")
    )
  end

  @doc """
  Closes the mobile sheet for the sidebar with the given id and restores focus to
  its trigger.
  """
  def hide_sidebar(js \\ %JS{}, id) do
    compose_js(
      js,
      %JS{}
      |> JS.set_attribute({"data-mobile-open", "false"}, to: "##{id}")
      |> JS.set_attribute({"aria-expanded", "false"}, to: "##{id}-trigger")
      |> JS.remove_attribute("inert", to: "##{id}-main")
      |> JS.remove_class("overflow-hidden", to: "body")
      |> JS.focus(to: "##{id}-trigger")
    )
  end

  # Disclosure toggle shared by groups and parent items: flip aria-expanded on
  # the button that was clicked, and data-open on the panel it controls.
  defp toggle_group(js, id) do
    compose_js(
      js,
      %JS{}
      |> JS.toggle_attribute({"aria-expanded", "true", "false"})
      |> JS.toggle_attribute({"data-open", "true", "false"}, to: "##{id}-sub, ##{id}-items")
    )
  end

  attr :icon, :any, required: true

  defp sidebar_icon(assigns) do
    ~H"""
    <%= cond do %>
      <% is_function(@icon) -> %>
        {Phoenix.LiveView.TagEngine.component(
          @icon,
          [class: "pc-sidebar-item__icon"],
          {__ENV__.module, __ENV__.function, __ENV__.file, __ENV__.line}
        )}
      <% is_binary(@icon) and String.match?(@icon, ~r/svg|img/) -> %>
        <span class="pc-sidebar-item__icon">{Phoenix.HTML.raw(@icon)}</span>
      <% true -> %>
        <.icon name={@icon} class="pc-sidebar-item__icon" />
    <% end %>
    """
  end
end
