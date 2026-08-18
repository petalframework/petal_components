defmodule PetalComponents.UserDropdownMenu do
  use Phoenix.Component
  import PetalComponents.Avatar
  import PetalComponents.Dropdown
  import PetalComponents.Icon

  attr :user_menu_items, :list,
    doc: "list of maps with keys :path, :icon (atom), :label, :method (atom - optional)"

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
      ~s|which way the menu extends from the trigger, passed through to the dropdown. The default "left" hangs the panel leftward (right edges aligned) - use "right" when the trigger sits against the left viewport edge, like an avatar at the bottom of a sidebar, so the panel grows into the viewport instead of off it|

  def user_dropdown_menu(assigns) do
    # current_user_name is declared without a default, so the assign is simply
    # absent when a caller leaves it out. The "icon" branch only ever reaches
    # it through assigns[...]; the "sidebar" branch renders it, so give the key
    # a nil to land on rather than moving the published attr default.
    assigns = assign_new(assigns, :current_user_name, fn -> nil end)

    ~H"""
    <.dropdown
      :if={@user_menu_items != []}
      placement={@placement}
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
      <%= for menu_item <- @user_menu_items do %>
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

  # The sidebar row needs the width dialled up on the dropdown container (which
  # is inline-block) as well as on the trigger button it wraps. Both stay nil
  # for "icon", so that variant renders byte for byte what it always did.
  defp sidebar_container_class("sidebar"), do: "pc-user-menu--sidebar"
  defp sidebar_container_class(_variant), do: nil

  defp sidebar_trigger_class("sidebar"), do: "pc-user-menu__row"
  defp sidebar_trigger_class(_variant), do: nil
end
