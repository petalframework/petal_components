defmodule PetalComponents.Link do
  use Phoenix.Component

  attr(:class, :string, default: "", doc: "CSS class for link")
  attr(:link_type, :string, default: "a", values: ["a", "live_patch", "live_redirect", "button"])
  attr(:label, :string, default: nil, doc: "label your link")
  attr(:to, :string, default: nil, doc: "link path")
  attr(:disabled, :boolean, default: false, doc: "disables your link")
  attr(:rest, :global, include: ~w(method download))
  slot(:inner_block, required: false)

  def a(%{link_type: "button", disabled: true} = assigns) do
    assigns = update_in(assigns.rest, &Map.drop(&1, [:"phx-click"]))

    ~H"""
    <button class={@class} disabled={@disabled} {@rest}>
      <%= if @label, do: @label, else: render_slot(@inner_block) %>
    </button>
    """
  end

  def a(%{disabled: true} = assigns) do
    assigns = update_in(assigns.rest, &Map.drop(&1, [:"phx-click"]))

    ~H"""
    <%= Phoenix.HTML.Link.link([to: "#", class: @class, disabled: @disabled] ++ Map.to_list(@rest),
      do: if(@label, do: @label, else: render_slot(@inner_block))
    ) %>
    """
  end

  def a(%{link_type: "a"} = assigns) do
    ~H"""
    <%= Phoenix.HTML.Link.link([to: @to, class: @class, disabled: @disabled] ++ Map.to_list(@rest),
      do: if(@label, do: @label, else: render_slot(@inner_block))
    ) %>
    """
  end

  def a(%{link_type: "live_patch"} = assigns) do
    ~H"""
    <%= live_patch([to: @to, class: @class, disabled: @disabled] ++ Map.to_list(@rest),
      do: if(@label, do: @label, else: render_slot(@inner_block))
    ) %>
    """
  end

  def a(%{link_type: "live_redirect"} = assigns) do
    ~H"""
    <%= live_redirect([to: @to, class: @class, disabled: @disabled] ++ Map.to_list(@rest),
      do: if(@label, do: @label, else: render_slot(@inner_block))
    ) %>
    """
  end

  def a(%{link_type: "button"} = assigns) do
    ~H"""
    <button class={@class} disabled={@disabled} {@rest}>
      <%= if @label, do: @label, else: render_slot(@inner_block) %>
    </button>
    """
  end
end
