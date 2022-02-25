defmodule PetalComponents.Link do
  use Phoenix.Component

  # prop class, :string
  # prop label, :string
  # prop link_type, :string, options: ["a", "live_patch", "live_redirect", "button"]
  # slot default
  def link(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:link_type, fn -> "a" end)
      |> assign_new(:label, fn -> nil end)
      |> assign_new(:to, fn -> nil end)
      |> assign_new(:inner_block, fn -> nil end)
      |> assign_new(:extra_assigns, fn ->
        assigns_to_attributes(assigns, [
          :class,
          :link_type,
          :label
        ])
      end)

    ~H"""
    <.custom_link
      inner_block={@inner_block}
      link_type={@link_type}
      to={@to}
      extra_assigns={@extra_assigns}
      class={@class}
      label={@label}
    />
    """
  end

  def custom_link(%{link_type: "a"} = assigns) do
    ~H"""
    <%= Phoenix.HTML.Link.link [to: @to, class: @class] ++ @extra_assigns, do: (if @inner_block, do: render_slot(@inner_block), else: @label) %>
    """
  end
  def custom_link(%{link_type: "live_patch"} = assigns) do
    ~H"""
    <%= live_patch [to: @to, class: @class] ++ @extra_assigns, do: (if @inner_block, do: render_slot(@inner_block), else: @label) %>
    """
  end
  def custom_link(%{link_type: "live_redirect"} = assigns) do
    ~H"""
    <%= live_redirect [to: @to, class: @class] ++ @extra_assigns, do: (if @inner_block, do: render_slot(@inner_block), else: @label) %>
    """
  end
  def custom_link(%{link_type: "button"} = assigns) do
    ~H"""
    <button class={@class} {@extra_assigns}><%= if @inner_block, do: render_slot(@inner_block), else: @label %></button>
    """
  end
end
