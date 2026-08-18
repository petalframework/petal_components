defmodule PetalComponents.UserDropdownMenu do
  use Phoenix.Component
  import PetalComponents.Avatar
  import PetalComponents.Dropdown
  import PetalComponents.Icon

  attr :user_menu_items, :list,
    default: [],
    doc:
      "list of maps with keys :path, :icon (atom), :label, :method (atom - optional). Leave it out when you pass your own panel through the inner block"

  attr :current_user_name, :string, doc: "the current signed in user's name"

  attr :current_user_email, :string,
    default: nil,
    doc:
      ~s|the current signed in user's email. It renders as the second line of the "sidebar" variant's row, under the name - leave it out and the row is a single line. The "icon" variant has nowhere to put it and ignores it|

  attr :avatar_src, :string, default: nil, doc: "the current signed in user's avatar image src"

  attr :variant, :string,
    default: "icon",
    values: ["icon", "sidebar"],
    doc:
      ~s|"icon" is the compact navbar trigger - avatar plus chevron, no wider than it needs to be, which is what a top bar wants. "sidebar" is the full-width row that belongs at the bottom of a sidebar: avatar, name over email, and a chevron-up-down on the right, because from down there the panel genuinely can open either way. Reach for it when the menu has a whole sidebar width to itself and the name is worth showing at rest; pair it with placement="right" when that sidebar sits against the left edge of the screen|

  attr :show_chevron, :boolean,
    default: true,
    doc: "hide for the chevron-less avatar trigger - the leaner app-shell look"

  attr :placement, :string,
    default: "left",
    values: ["left", "right"],
    doc:
      ~s|which way the panel GROWS from the trigger, not which side it sits on: "left" grows it leftward, right edges aligned, the way a menu in the right-hand corner of a navbar wants; "right" grows it rightward from the trigger's left edge. Passed through to the dropdown. Reach for "right" when the trigger sits against the left viewport edge, like an avatar at the bottom of a sidebar, so the panel grows into the viewport instead of off it|

  attr :direction, :string,
    default: "auto",
    values: ["auto", "up", "down"],
    doc:
      ~s|which way the panel opens vertically, passed through to the dropdown. "auto" measures and flips when the viewport leaves no room below. At the bottom of a sidebar you already know the answer, so say it: direction="up" renders the panel in the flipped state from the start and skips the measuring hook altogether|

  attr :menu_items_wrapper_class, :any,
    default: nil,
    doc:
      ~s|extra classes for the panel itself, passed through to the dropdown. The panel is content-width by default; this is where you pin it, e.g. "w-60" for an account panel that should not breathe as its rows change|

  slot :inner_block,
    doc:
      "your own panel content, in place of the user_menu_items list. Use it when the menu is more than a list of links - an org switcher, a theme row, a group label or two - and compose it from dropdown_menu_item, dropdown_menu_label, dropdown_menu_row and dropdown_menu_separator. The trigger stays exactly the same"

  def user_dropdown_menu(assigns) do
    # current_user_name is declared without a default, so the assign is simply
    # absent when a caller leaves it out. The "icon" branch only ever reaches
    # it through assigns[...]; the "sidebar" branch renders it, so give the key
    # a nil to land on rather than moving the published attr default.
    assigns = assign_new(assigns, :current_user_name, fn -> nil end)

    ~H"""
    <.dropdown
      :if={@user_menu_items != [] or @inner_block != []}
      placement={@placement}
      direction={@direction}
      menu_items_wrapper_class={@menu_items_wrapper_class}
      class={sidebar_container_class(@variant)}
      trigger_class={sidebar_trigger_class(@variant)}
    >
      <:trigger_element :if={@variant == "sidebar"}>
        <.avatar
          name={@current_user_name}
          src={@avatar_src}
          size="sm"
          random_color
          aria-hidden={@current_user_name && "true"}
        />

        <span class="pc-user-menu__identity">
          <span :if={@current_user_name} class="pc-user-menu__name">{@current_user_name}</span>
          <span :if={@current_user_email} class="pc-user-menu__email">{@current_user_email}</span>
        </span>

        <.icon :if={@show_chevron} name="hero-chevron-up-down" class="pc-dropdown__chevron" />
      </:trigger_element>
      <:trigger_element :if={@variant != "sidebar"}>
        <div class="inline-flex items-center justify-center w-full gap-1 align-middle focus:outline-hidden">
          <%= if assigns[:current_user_name] || assigns[:avatar_src] do %>
            <.avatar name={@current_user_name} src={@avatar_src} size="sm" random_color />
          <% else %>
            <.avatar size="sm" />
          <% end %>

          <.icon
            :if={@show_chevron}
            name="hero-chevron-down-mini"
            class="pc-dropdown__chevron"
          />
        </div>
      </:trigger_element>
      {render_slot(@inner_block)}
      <%= for menu_item <- menu_items(@inner_block, @user_menu_items) do %>
        <.dropdown_menu_item
          link_type={if menu_item[:method], do: "a", else: "live_redirect"}
          method={if menu_item[:method], do: menu_item[:method], else: nil}
          to={menu_item.path}
        >
          <%= cond do %>
            <% is_function(menu_item.icon) -> %>
              {Phoenix.LiveView.TagEngine.component(
                menu_item.icon,
                [class: "w-5 h-5 text-gray-500 dark:text-gray-400"],
                {__ENV__.module, __ENV__.function, __ENV__.file, __ENV__.line}
              )}
            <% is_binary(menu_item.icon) && String.match?(menu_item.icon, ~r/svg|img/) -> %>
              {Phoenix.HTML.raw(menu_item.icon)}
            <% true -> %>
              <.icon name={menu_item.icon} class="w-5 h-5 text-gray-500 dark:text-gray-400" />
          <% end %>

          {menu_item.label}
        </.dropdown_menu_item>
      <% end %>
    </.dropdown>
    """
  end

  # A panel passed in wholesale REPLACES the generated list rather than stacking
  # on top of it: the two are alternatives, and rendering both would only ever
  # be somebody's mistake.
  defp menu_items([], user_menu_items), do: user_menu_items
  defp menu_items(_inner_block, _user_menu_items), do: []

  # The sidebar row needs the width dialled up on the dropdown container (which
  # is inline-block) as well as on the trigger button it wraps. Both stay nil
  # for "icon", so that variant renders byte for byte what it always did.
  defp sidebar_container_class("sidebar"), do: "pc-user-menu--sidebar"
  defp sidebar_container_class(_variant), do: nil

  defp sidebar_trigger_class("sidebar"), do: "pc-user-menu__row"
  defp sidebar_trigger_class(_variant), do: nil
end
