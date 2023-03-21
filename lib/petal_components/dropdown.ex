defmodule PetalComponents.Dropdown do
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias PetalComponents.Link

  @transition_in_base "transition transform ease-out duration-100"
  @transition_in_start "transform opacity-0 scale-95"
  @transition_in_end "transform opacity-100 scale-100"

  @transition_out_base "transition ease-in duration-75"
  @transition_out_start "transform opacity-100 scale-100"
  @transition_out_end "transform opacity-0 scale-95"

  attr(:options_container_id, :string)
  attr(:label, :string, default: nil, doc: "labels your dropdown option")
  attr(:class, :string, default: "", doc: "any extra CSS class for the parent container")

  attr(:menu_items_wrapper_class, :string,
    default: "",
    doc: "any extra CSS class for menu item wrapper container"
  )

  attr(:js_lib, :string,
    default: "alpine_js",
    values: ["alpine_js", "live_view_js"],
    doc: "javascript library used for toggling"
  )

  attr(:placement, :string, default: "left", values: ["left", "right"])
  attr(:rest, :global)
  slot(:trigger_element)
  slot(:inner_block, required: false)

  @doc """
    <.dropdown label="Dropdown" js_lib="alpine_js|live_view_js">
      <.dropdown_menu_item link_type="button">
        <Heroicons.home class="w-5 h-5 text-gray-500" />
        Button item with icon
      </.dropdown_menu_item>
      <.dropdown_menu_item link_type="a" to="/" label="a item" />
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
      {js_attributes("container", @js_lib, @options_container_id)}
      class={[@class, "pc-dropdown"]}
    >
      <div>
        <button
          type="button"
          class={trigger_button_classes(@label, @trigger_element)}
          {js_attributes("button", @js_lib, @options_container_id)}
          aria-haspopup="true"
        >
          <span class="sr-only">Open options</span>

          <%= if @label do %>
            <%= @label %>
            <Heroicons.chevron_down solid class="pc-dropdown__chevron" />
          <% end %>

          <%= if @trigger_element do %>
            <%= render_slot(@trigger_element) %>
          <% end %>

          <%= if !@label && @trigger_element == [] do %>
            <Heroicons.ellipsis_vertical solid class="pc-dropdown__ellipsis" />
          <% end %>
        </button>
      </div>
      <div
        {js_attributes("options_container", @js_lib, @options_container_id)}
        class={"#{placement_class(@placement)} #{@menu_items_wrapper_class} pc-dropdown__menu-items-wrapper"}
        role="menu"
        id={@options_container_id}
        aria-orientation="vertical"
        aria-labelledby="options-menu"
      >
        <div class="py-1" role="none">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  attr(:to, :string, default: nil, doc: "link path")
  attr(:label, :string, doc: "link label")
  attr(:class, :string, default: "", doc: "any additional CSS classes")

  attr(:link_type, :string,
    default: "button",
    values: ["a", "live_patch", "live_redirect", "button"]
  )

  attr(:rest, :global, include: ~w(method download hreflang ping referrerpolicy rel target type))
  slot(:inner_block, required: false)

  def dropdown_menu_item(assigns) do
    ~H"""
    <Link.a link_type={@link_type} to={@to} class={"#{@class} pc-dropdown__menu-item"} {@rest}>
      <%= render_slot(@inner_block) || @label %>
    </Link.a>
    """
  end

  defp trigger_button_classes(nil, []),
    do: "pc-dropdown__trigger-button--no-label"

  defp trigger_button_classes(_label, []),
    do: "pc-dropdown__trigger-button--with-label"

  defp trigger_button_classes(_label, _trigger_element),
    do: "pc-dropdown__trigger-button--with-label-and-trigger-element"

  defp js_attributes("container", "alpine_js", _options_container_id) do
    %{
      "x-data": "{open: false}",
      "@keydown.escape.stop": "open = false",
      "@click.outside": "open = false"
    }
  end

  defp js_attributes("button", "alpine_js", _options_container_id) do
    %{
      "@click": "open = !open",
      "@click.outside": "open = false",
      "x-bind:aria-expanded": "open.toString()"
    }
  end

  defp js_attributes("options_container", "alpine_js", _options_container_id) do
    %{
      "x-cloak": true,
      "x-show": "open",
      "x-transition:enter": @transition_in_base,
      "x-transition:enter-start": @transition_in_start,
      "x-transition:enter-end": @transition_in_end,
      "x-transition:leave": @transition_out_base,
      "x-transition:leave-start": @transition_out_start,
      "x-transition:leave-end": @transition_out_end
    }
  end

  defp js_attributes("container", "live_view_js", options_container_id) do
    %{
      "phx-click-away":
        JS.hide(
          to: "##{options_container_id}",
          transition: {@transition_out_base, @transition_out_start, @transition_out_end}
        )
    }
  end

  defp js_attributes("button", "live_view_js", options_container_id) do
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

  defp js_attributes("options_container", "live_view_js", _options_container_id) do
    %{
      style: "display: none;"
    }
  end

  defp placement_class("left"), do: "pc-dropdown__menu-items-wrapper-placement--left"
  defp placement_class("right"), do: "pc-dropdown__menu-items-wrapper-placement--right"
end
