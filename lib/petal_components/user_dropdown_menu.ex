defmodule PetalComponents.UserDropdownMenu do
  use Phoenix.Component
  import PetalComponents.Avatar
  import PetalComponents.Dropdown
  import PetalComponents.Icon

  attr :user_menu_items, :list,
    doc: "list of maps with keys :path, :icon (atom), :label, :method (atom - optional)"

  attr :current_user_name, :string, doc: "the current signed in user's name"
  attr :avatar_src, :string, default: nil, doc: "the current signed in user's avatar image src"

  def user_dropdown_menu(assigns) do
    ~H"""
    <.dropdown :if={@user_menu_items != []}>
      <:trigger_element>
        <div class="inline-flex items-center justify-center w-full align-middle focus:outline-none">
          <%= if @current_user_name || @avatar_src do %>
            <.avatar name={@current_user_name} src={@avatar_src} size="sm" random_color />
          <% else %>
            <.avatar size="sm" />
          <% end %>

          <Heroicons.chevron_down mini class="w-4 h-4 ml-1 -mr-1 text-gray-400 dark:text-gray-100" />
        </div>
      </:trigger_element>
      <%= for menu_item <- @user_menu_items do %>
        <.dropdown_menu_item
          link_type={if menu_item[:method], do: "a", else: "live_redirect"}
          method={if menu_item[:method], do: menu_item[:method], else: nil}
          to={menu_item.path}
        >
          <%= if is_atom(menu_item.icon) do %>
            <.icon outline name={menu_item.icon} class="w-5 h-5 text-gray-500 dark:text-gray-400" />
          <% end %>

          <%= if is_function(menu_item.icon) do %>
            <%= Phoenix.LiveView.TagEngine.component(
              menu_item.icon,
              [class: "w-5 h-5 text-gray-500 dark:text-gray-400"],
              {__ENV__.module, __ENV__.function, __ENV__.file, __ENV__.line}
            ) %>
          <% end %>

          <%= if is_binary(menu_item.icon) do %>
            <%= Phoenix.HTML.raw(menu_item.icon) %>
          <% end %>

          <%= menu_item.label %>
        </.dropdown_menu_item>
      <% end %>
    </.dropdown>
    """
  end
end
