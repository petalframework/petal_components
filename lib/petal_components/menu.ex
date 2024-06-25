defmodule PetalComponents.Menu do
  use Phoenix.Component, global_prefixes: ~w(x-)
  import PetalComponents.Link
  import PetalComponents.Icon

  alias Phoenix.LiveView.JS

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

  attr(:js_lib, :string,
    default: PetalComponents.default_js_lib(),
    values: ["alpine_js", "live_view_js"],
    doc: "javascript library used for toggling"
  )

  def vertical_menu(%{menu_items: []} = assigns) do
    ~H"""

    """
  end

  def vertical_menu(assigns) do
    ~H"""
    <%= if menu_items_grouped?(@menu_items) do %>
      <div class="pc-vertical-menu">
        <.menu_group
          :for={menu_group <- @menu_items}
          js_lib={@js_lib}
          title={menu_group[:title]}
          menu_items={menu_group.menu_items}
          current_page={@current_page}
        />
      </div>
    <% else %>
      <.menu_group
        js_lib={@js_lib}
        title={@title}
        menu_items={@menu_items}
        current_page={@current_page}
      />
    <% end %>
    """
  end

  attr :current_page, :atom
  attr :menu_items, :list
  attr :title, :string

  attr(:js_lib, :string,
    default: PetalComponents.default_js_lib(),
    values: ["alpine_js", "live_view_js"],
    doc: "javascript library used for toggling"
  )

  def menu_group(assigns) do
    ~H"""
    <nav :if={@menu_items != []}>
      <h3 :if={@title} class="pc-vertical-menu__menu-group__title">
        <%= @title %>
      </h3>

      <div class="pc-vertical-menu__menu-group__wrapper">
        <div class="pc-vertical-menu__menu-group">
          <.vertical_menu_item
            :for={menu_item <- @menu_items}
            js_lib={@js_lib}
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

  attr(:js_lib, :string,
    default: PetalComponents.default_js_lib(),
    values: ["alpine_js", "live_view_js"],
    doc: "javascript library used for toggling"
  )

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
      <.menu_icon :if={@icon} icon={@icon} is_active={@current_page == @name} />
      <div class="pc-vertical-menu-item__label"><%= @label %></div>
    </.a>
    """
  end

  def vertical_menu_item(%{menu_items: _} = assigns) do
    assigns =
      assigns
      |> assign_new(:submenu_id, fn -> "submenu_#{Ecto.UUID.generate()}" end)
      |> assign_new(:icon_id, fn -> "icon_#{Ecto.UUID.generate()}" end)

    ~H"""
    <div
      phx-update="ignore"
      id={"dropdown_#{@label |> String.downcase() |> String.replace(" ", "_")}"}
      {js_attributes("container", @js_lib, %{name: @name, current_page: @current_page, menu_items: @menu_items})}
    >
      <button
        type="button"
        class={menu_item_classes(@current_page, @name)}
        {js_attributes("button", @js_lib, %{submenu_id: @submenu_id, icon_id: @icon_id})}
      >
        <.menu_icon icon={@icon} />
        <div class="pc-vertical-menu-item__toggle-label">
          <%= @label %>
        </div>

        <div class="pc-vertical-menu-item__toggle-chevron__wrapper">
          <Heroicons.chevron_right
            id={@icon_id}
            {js_attributes("icon", @js_lib, %{class: "pc-vertical-menu-item__toggle-chevron__icon", name: @name, current_page: @current_page, menu_items: @menu_items})}
          />
        </div>
      </button>
      <div
        id={@submenu_id}
        class="pc-vertical-menu-item__submenu-wrapper"
        {js_attributes("submenu", @js_lib, %{name: @name, current_page: @current_page, menu_items: @menu_items})}
      >
        <.vertical_menu_item :for={menu_item <- @menu_items} current_page={@current_page} {menu_item} />
      </div>
    </div>
    """
  end

  attr :icon, :any, default: nil
  attr :is_active, :boolean, default: false

  defp menu_icon(assigns) do
    ~H"""
    <.icon :if={is_atom(@icon)} outline name={@icon} class={menu_icon_classes(@is_active)} />

    <%= if is_function(@icon) do %>
      <%= Phoenix.LiveView.TagEngine.component(
        @icon,
        [class: menu_icon_classes(@is_active)],
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

  defp menu_icon_classes(is_active),
    do:
      "pc-vertical-menu-item__icon pc-vertical-menu-item__icon--#{if is_active, do: "active", else: "inactive"}"

  defp menu_item_base_classes(),
    do: "pc-vertical-menu-item"

  # Active state
  defp menu_item_classes(page, page),
    do: "#{menu_item_base_classes()} group pc-vertical-menu-item--active"

  # Inactive state
  defp menu_item_classes(_current_page, _link_page),
    do: "#{menu_item_base_classes()} group pc-vertical-menu-item--inactive"

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

  defp js_attributes("container", "alpine_js", %{
         name: name,
         current_page: current_page,
         menu_items: menu_items
       }) do
    %{
      "x-data": "{ open: #{menu_item_active?(name, current_page, menu_items)}}"
    }
  end

  defp js_attributes("button", "alpine_js", _args) do
    %{
      "@click.prevent": "open = !open"
    }
  end

  defp js_attributes("icon", "alpine_js", %{class: class}) do
    %{
      class: class,
      "x-bind:class": "{ 'rotate-90': open }"
    }
  end

  defp js_attributes("submenu", "alpine_js", %{
         name: name,
         current_page: current_page,
         menu_items: menu_items
       }) do
    %{
      "x-show": "open",
      "x-cloak": "#{!menu_item_active?(name, current_page, menu_items)}"
    }
  end

  defp js_attributes("container", "live_view_js", _args) do
    %{}
  end

  defp js_attributes("button", "live_view_js", %{submenu_id: submenu_id, icon_id: icon_id}) do
    click =
      JS.toggle(
        to: "##{submenu_id}",
        display: "block"
      )
      |> JS.remove_class(
        "rotate-90",
        to: "##{icon_id}.rotate-90"
      )
      |> JS.add_class(
        "rotate-90",
        to: "##{icon_id}:not(.rotate-90)"
      )

    %{
      "phx-click": click
    }
  end

  defp js_attributes("icon", "live_view_js", %{
         class: class,
         name: name,
         current_page: current_page,
         menu_items: menu_items
       }) do
    rotate = if menu_item_active?(name, current_page, menu_items), do: "rotate-90"

    %{
      class: [class, rotate]
    }
  end

  defp js_attributes("submenu", "live_view_js", %{
         name: name,
         current_page: current_page,
         menu_items: menu_items
       }) do
    display = if menu_item_active?(name, current_page, menu_items), do: "block", else: "none"

    %{
      style: "display: #{display};"
    }
  end
end
