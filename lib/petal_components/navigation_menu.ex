defmodule PetalComponents.NavigationMenu do
  @moduledoc """
  A horizontal navigation menu with flyout panels — the pattern marketing
  sites use for "Products / Solutions / Resources" menus that hold more than a
  simple dropdown can.

  Follows the W3C disclosure navigation pattern (recommended for site
  navigation over ARIA `menu` roles): each trigger is a `button` with
  `aria-expanded`/`aria-controls`, panels contain plain links, Escape and
  clicking away close any open panel. Interaction is click-to-toggle (touch
  friendly) and 100% LiveView.JS — no Alpine, no hooks.

  Panels are free-form: compose them from `navigation_menu_link/1` rows
  (icon + title + description), an optional `navigation_menu_footer/1` CTA
  strip, or any markup you like.

  ## Staying on screen

  Flyout panels anchor to their trigger's start edge and open rightward into
  the page (so a left-most trigger never opens back under a sidebar). For a
  trigger near the right edge, set `align="end"` on the item so its panel opens
  leftward instead and stays on screen. Panel widths are clamped to the viewport
  so a wide panel shrinks to fit instead of overflowing on a phone, and a panel
  taller than the screen scrolls rather than being cut off at the bottom.

  ## Full-width (mega menu) panels

  Set `full_width` on an item and the panel spans the nearest positioned
  ancestor — give your site header `class="relative"` and the panel becomes a
  full-width mega menu below it.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias PetalComponents.Link
  import PetalComponents.Icon

  @transition_in {"transition ease-out duration-200", "opacity-0 translate-y-1",
                  "opacity-100 translate-y-0"}
  @transition_out {"transition ease-in duration-150", "opacity-100 translate-y-0",
                   "opacity-0 translate-y-1"}

  attr :id, :string, required: true
  attr :class, :any, default: nil, doc: "extra classes for the nav element"

  attr :trigger, :string,
    default: "hover",
    values: ["hover", "click"],
    doc:
      "how flyout panels open. hover (default): opens on pointer hover or keyboard/touch focus, pure CSS, no round-trip - the convention for a top nav. click: explicit toggle via JS (opens on click, closes on click-away/Escape) - use for touch-first apps that want a deliberate tap"

  attr :rest, :global

  slot :item, required: true do
    attr :label, :string, required: true
    attr :to, :string, doc: "render a plain link instead of a flyout trigger"

    attr :link_type, :string,
      doc: ~s|for plain links: "a" (default), "live_patch" or "live_redirect"|

    attr :width, :string, doc: ~s|flyout panel width: "sm", "md" (default), "lg" or "xl"|

    attr :align, :string,
      doc:
        ~s|which edge of the trigger the flyout panel anchors to: "start" (default, opens rightward) or "end" (opens leftward). Use "end" for triggers near the right edge so the panel stays on screen.|

    attr :full_width, :boolean,
      doc: "span the panel across the nearest positioned ancestor (mega menu)"

    attr :current, :boolean, doc: "marks the active item with aria-current"
  end

  @doc """
  Renders the navigation menu.

      <.navigation_menu id="main-nav">
        <:item label="Products" width="md">
          <.navigation_menu_link
            to="/analytics"
            icon="hero-chart-bar"
            title="Analytics"
            description="Understand your traffic"
          />
          <.navigation_menu_link
            to="/automations"
            icon="hero-arrow-path"
            title="Automations"
            description="Put repetitive work on autopilot"
          />
          <.navigation_menu_footer>
            <.navigation_menu_footer_link to="/demo" icon="hero-play-circle" label="Watch demo" />
            <.navigation_menu_footer_link to="/contact" icon="hero-phone" label="Contact sales" />
          </.navigation_menu_footer>
        </:item>
        <:item label="Pricing" to="/pricing" />
        <:item label="Docs" to="/docs" current />
      </.navigation_menu>

  For multi-column panels, wrap the links in a grid:

      <:item label="Solutions" width="xl">
        <div class="grid grid-cols-2 gap-1">
          <.navigation_menu_link ... />
          <.navigation_menu_link ... />
        </div>
      </:item>
  """
  def navigation_menu(assigns) do
    ~H"""
    <nav
      id={@id}
      class={["pc-nav-menu", @trigger == "hover" && "pc-nav-menu--hover", @class]}
      phx-click-away={@trigger == "click" && hide_panels(@id)}
      phx-window-keydown={@trigger == "click" && hide_panels(@id)}
      phx-key={@trigger == "click" && "Escape"}
      {@rest}
    >
      <ul class="pc-nav-menu__list">
        <li
          :for={{item, index} <- Enum.with_index(@item)}
          class={["pc-nav-menu__item", !item[:full_width] && "relative"]}
        >
          <%= if item[:to] do %>
            <Link.a
              link_type={item[:link_type] || "a"}
              to={item[:to]}
              class="pc-nav-menu__link-item"
              aria-current={item[:current] && "page"}
            >
              {item.label}
            </Link.a>
          <% else %>
            <button
              type="button"
              class="pc-nav-menu__trigger"
              aria-expanded="false"
              aria-controls={panel_id(@id, index)}
              phx-click={@trigger == "click" && toggle_panel(@id, index)}
            >
              {item.label}
              <.icon name="hero-chevron-down-solid" class="pc-nav-menu__chevron" />
            </button>
            <div
              id={panel_id(@id, index)}
              class={[
                "pc-nav-menu__panel",
                panel_width_class(item[:width]),
                item[:align] == "end" && "pc-nav-menu__panel--end",
                item[:full_width] && "pc-nav-menu__panel--full"
              ]}
              style={@trigger == "click" && "display: none;"}
              data-pc-nav-panel
            >
              {render_slot(item)}
            </div>
          <% end %>
        </li>
      </ul>
    </nav>
    """
  end

  attr :to, :string, required: true, doc: "link destination"
  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :icon, :string, default: nil, doc: "heroicon name, e.g. hero-chart-bar"

  attr :link_type, :string,
    default: "a",
    values: ["a", "live_patch", "live_redirect"]

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(method download hreflang ping referrerpolicy rel target type)

  @doc """
  A flyout panel row: icon in a tinted square, bold title, muted one-line
  description.
  """
  def navigation_menu_link(assigns) do
    ~H"""
    <Link.a link_type={@link_type} to={@to} class={["pc-nav-menu__link group", @class]} {@rest}>
      <div :if={@icon} class="pc-nav-menu__link-icon">
        <.icon name={@icon} class="pc-nav-menu__link-icon-svg" />
      </div>
      <div class="pc-nav-menu__link-body">
        <span class="pc-nav-menu__link-title">{@title}</span>
        <span :if={@description} class="pc-nav-menu__link-description">{@description}</span>
      </div>
    </Link.a>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc """
  A full-bleed strip at the bottom of a flyout panel, usually holding one to
  three `navigation_menu_footer_link/1` CTAs.
  """
  def navigation_menu_footer(assigns) do
    ~H"""
    <div class={["pc-nav-menu__footer", @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :to, :string, required: true, doc: "link destination"
  attr :label, :string, required: true
  attr :icon, :string, default: nil, doc: "heroicon name, e.g. hero-play-circle"

  attr :link_type, :string,
    default: "a",
    values: ["a", "live_patch", "live_redirect"]

  attr :rest, :global, include: ~w(method download hreflang ping referrerpolicy rel target type)

  @doc """
  A compact centered CTA for `navigation_menu_footer/1`.
  """
  def navigation_menu_footer_link(assigns) do
    ~H"""
    <Link.a link_type={@link_type} to={@to} class="pc-nav-menu__footer-link" {@rest}>
      <.icon :if={@icon} name={@icon} class="pc-nav-menu__footer-link-icon" />
      {@label}
    </Link.a>
    """
  end

  defp panel_id(nav_id, index), do: "#{nav_id}-panel-#{index}"

  defp panel_width_class("sm"), do: "pc-nav-menu__panel--sm"
  defp panel_width_class("lg"), do: "pc-nav-menu__panel--lg"
  defp panel_width_class("xl"), do: "pc-nav-menu__panel--xl"
  defp panel_width_class(_), do: "pc-nav-menu__panel--md"

  # Opening a panel closes every other panel in the same nav first, then
  # toggles its own. aria-expanded is kept in sync so CSS (chevron rotation,
  # trigger highlight) can key off it.
  defp toggle_panel(nav_id, index) do
    panel = "##{panel_id(nav_id, index)}"

    JS.hide(to: "##{nav_id} [data-pc-nav-panel]:not(#{panel})", transition: @transition_out)
    |> JS.set_attribute({"aria-expanded", "false"},
      to: "##{nav_id} .pc-nav-menu__trigger:not([aria-controls=\"#{panel_id(nav_id, index)}\"])"
    )
    |> JS.toggle(to: panel, display: "block", in: @transition_in, out: @transition_out)
    |> JS.toggle_attribute({"aria-expanded", "true", "false"})
  end

  defp hide_panels(nav_id) do
    JS.hide(to: "##{nav_id} [data-pc-nav-panel]", transition: @transition_out)
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{nav_id} .pc-nav-menu__trigger")
  end
end
