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

  attr :placement, :string, default: "left", values: ["left", "right"]
  attr :rest, :global

  slot :trigger_element
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
        >
          <span class="sr-only">Open options</span>

          <%= if @label do %>
            {@label}
            <.icon name="hero-chevron-down-solid" class="w-5 h-5 pc-dropdown__chevron" />
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
        {js_attributes("options_container", @options_container_id)}
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

  defp trigger_button_classes(nil, []),
    do: "pc-dropdown__trigger-button--no-label"

  defp trigger_button_classes(_label, []),
    do: "pc-dropdown__trigger-button--with-label"

  defp trigger_button_classes(_label, _trigger_element),
    do: "pc-dropdown__trigger-button--with-label-and-trigger-element"

  defp js_attributes(type, options_container_id, on_close \\ %JS{})

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

  defp js_attributes("options_container", _options_container_id, _on_close) do
    %{
      style: "display: none;"
    }
  end

  defp placement_class("left"), do: "pc-dropdown__menu-items-wrapper-placement--left"
  defp placement_class("right"), do: "pc-dropdown__menu-items-wrapper-placement--right"

  defp get_disabled_classes(true), do: "pc-dropdown__menu-item--disabled"
  defp get_disabled_classes(false), do: ""
end
