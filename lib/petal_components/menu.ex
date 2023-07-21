defmodule PetalComponents.Menu do
  use Phoenix.Component, global_prefixes: ~w(x-)
  import PetalComponents.Link
  import PetalComponents.Icon

  @doc """
  ## Menu items structure

  Menu items (main_menu_items + user_menu_items) should have this structure:

        [
          %{
            name: :sign_in,
            label: "Sign in",
            path: "/sign-in,
            icon: :key,
          }
        ]

  ### Name

  The name is used to identify the menu item. It is used to highlight the current menu item.

      <.sidebar_layout current_page={:sign_in} ...>

  ### Label

  This is the text that will be displayed in the menu.

  ### Path

  This is the path that the user will be taken to when they click the menu item.
  The default link type is a live_redirect. This will work for non-live view links too.

  #### Live patching

  Let's say you have three menu items that point to the same live view. In this case we can utilize a live_patch link. To do this, you add the `patch_group` key to the menu item.

      [
        %{name: :one, label: "One", path: "/one, icon: :key, patch_group: :my_unique_group},
        %{name: :two, label: "Two", path: "/two, icon: :key, patch_group: :my_unique_group},
        %{name: :three, label: "Three", path: "/three, icon: :key, patch_group: :my_unique_group},
        %{name: :another_link, label: "Other", path: "/other, icon: :key},
      ]

  Now, if you're on page `:one`, and click a link in the menu to either `:two`, or `:three`, the live view will be patched because they are in the same `patch_group`. If you click `:another_link`, the live view will be redirected.

  ### Icons

  The icon should match to a Heroicon (Petal Components must be installed).
  If you have your own icon, you can pass a function to the icon attribute instead of an atom:

        [
          %{
            name: :sign_in,
            label: "Sign in",
            path: "/sign-in,
            icon: &my_cool_icon/1,
          }
        ]

  Or just pass a string of HTML:

        [
          %{
            name: :sign_in,
            label: "Sign in",
            path: "/sign-in,
            icon: "<svg>...</svg>",
          }
        ]

  ## Nested menu items

  You can have nested menu items that will be displayed in a dropdown menu. To do this, you add a `menu_items` key to the menu item. eg:

        [
          %{
            name: :auth,
            label: "Auth",
            icon: :key,
            menu_items: [
              %{
                name: :sign_in,
                label: "Sign in",
                path: "/sign-in,
                icon: :key,
              },
              %{
                name: :sign_up,
                label: "Sign up",
                path: "/sign-up,
                icon: :key,
              },
            ]
          }
        ]

  ## Menu groups

  Sidebar supports multi menu groups for the side menu. eg:

  User
  - Profile
  - Settings

  Company
  - Dashboard
  - Company Settings

  To enable this, change the structure of main_menu_items to this:

      main_menu_items = [
        %{
          title: "Menu group 1",
          menu_items: [ ... menu items ... ]
        },
        %{
          title: "Menu group 2",
          menu_items: [ ... menu items ... ]
        },
      ]
  """

  attr :menu_items, :list, required: true
  attr :current_page, :atom, required: true
  attr :title, :string, default: nil

  def vertical_menu(assigns) do
    ~H"""
    <%= if menu_items_grouped?(@menu_items) do %>
      <div class="flex flex-col gap-5">
        <.menu_group
          :for={menu_group <- @menu_items}
          title={menu_group[:title]}
          menu_items={menu_group.menu_items}
          current_page={@current_page}
        />
      </div>
    <% else %>
      <.menu_group title={@title} menu_items={@menu_items} current_page={@current_page} />
    <% end %>
    """
  end

  attr :current_page, :atom
  attr :menu_items, :list
  attr :title, :string

  def menu_group(assigns) do
    ~H"""
    <nav>
      <h3 :if={@title} class="pl-3 mb-3 text-xs font-semibold leading-6 text-gray-400 uppercase">
        <%= @title %>
      </h3>

      <div class="divide-y divide-gray-300">
        <div class="space-y-1">
          <.vertical_menu_item
            :for={menu_item <- @menu_items}
            all_menu_items={@menu_items}
            current_page={@current_page}
            {menu_item}
          />
        </div>
      </div>
    </nav>
    """
  end

  attr :current_page, :atom
  attr :path, :string, default: nil
  attr :icon, :any, default: nil
  attr :label, :string
  attr :name, :atom, default: nil
  attr :menu_items, :list, default: nil
  attr :all_menu_items, :list, default: nil
  attr :patch_group, :atom, default: nil
  attr :link_type, :string, default: "live_redirect"

  def vertical_menu_item(%{menu_items: nil} = assigns) do
    current_item = find_item(assigns.name, assigns.all_menu_items)
    assigns = assign(assigns, :current_item, current_item)

    ~H"""
    <.a
      to={@path}
      link_type={
        if @current_item[:patch_group] &&
             @current_item[:patch_group] == @patch_group,
           do: "live_patch",
           else: "live_redirect"
      }
      class={menu_item_classes(@current_page, @name)}
    >
      <.menu_icon icon={@icon} />
      <div class="flex-1"><%= @label %></div>
    </.a>
    """
  end

  def vertical_menu_item(%{menu_items: _} = assigns) do
    ~H"""
    <div
      x-data={"{ open: #{if menu_item_active?(@name, @current_page, @menu_items), do: "true", else: "false"} }"}
      phx-update="ignore"
      id={"dropdown_#{@label |> String.downcase() |> String.replace(" ", "_")}"}
    >
      <button
        type="button"
        class={menu_item_classes(@current_page, @name)}
        @click.prevent="open = !open"
      >
        <.menu_icon icon={@icon} />
        <div class="flex-1 text-left"><%= @label %></div>

        <div class="relative inline-block">
          <div class="ml-2">
            <Heroicons.chevron_right
              class="w-3 h-3 transition duration-200 transform"
              x-bind:class="{ 'rotate-90': open }"
            />
          </div>
        </div>
      </button>
      <div
        class="mt-1 ml-3 space-y-1"
        x-show="open"
        x-cloak={!menu_item_active?(@name, @current_page, @menu_items)}
      >
        <.vertical_menu_item :for={menu_item <- @menu_items} current_page={@current_page} {menu_item} />
      </div>
    </div>
    """
  end

  attr :icon, :any, default: nil

  defp menu_icon(assigns) do
    ~H"""
    <.icon :if={is_atom(@icon)} outline name={@icon} class={menu_icon_classes()} />

    <%= if is_function(@icon) do %>
      <%= Phoenix.LiveView.TagEngine.component(
        @icon,
        [class: menu_icon_classes()],
        {__ENV__.module, __ENV__.function, __ENV__.file, __ENV__.line}
      ) %>
    <% end %>

    <%= if is_binary(@icon) do %>
      <%= Phoenix.HTML.raw(@icon) %>
    <% end %>
    """
  end

  defp menu_items_grouped?(menu_items) do
    Enum.all?(menu_items, fn menu_item ->
      Map.has_key?(menu_item, :title)
    end)
  end

  # Check whether the current namge equals the current page or whether any of the menu items have the current page as their name. A menu_item may have sub-items, so we need to check recursively.
  defp menu_item_active?(name, current_page, menu_items) do
    name == current_page ||
      Enum.any?(menu_items, fn menu_item ->
        menu_item_active?(menu_item[:name], current_page, menu_item[:menu_items] || [])
      end)
  end

  defp menu_icon_classes(),
    do: "w-5 h-5 flex-shrink-0"

  defp menu_item_base(),
    do:
      "flex items-center text-sm font-semibold leading-none px-3 py-2 gap-3 transition duration-200 w-full rounded-md group"

  # Active state
  defp menu_item_classes(page, page),
    do: "#{menu_item_base()} text-primary-700 dark:text-primary-400 bg-gray-50 dark:bg-gray-800"

  # Inactive state
  defp menu_item_classes(_current_page, _link_page),
    do:
      "#{menu_item_base()} text-gray-700 hover:bg-gray-50 dark:text-gray-200 hover:text-gray-900 dark:hover:text-white dark:hover:bg-gray-700"

  defp find_item(name, menu_items) when is_list(menu_items) do
    Enum.find(menu_items, fn menu_item ->
      if menu_item[:name] == name do
        true
      else
        find_item(name, menu_item[:menu_items] || [])
      end
    end)
  end

  defp find_item(_, _), do: nil
end
