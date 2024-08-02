defmodule PetalComponents.Link do
  use Phoenix.Component

  attr :class, :any, default: nil, doc: "CSS class for link (either a string or list)"
  attr :link_type, :string, default: "a", values: ["a", "live_patch", "live_redirect", "button"]
  attr :label, :string, default: nil, doc: "label your link"
  attr :to, :string, default: nil, doc: "link path"

  attr :disabled, :boolean,
    default: false,
    doc: "disables the link. This will turn an <a> into a <button> (<a> tags can't be disabled)"

  attr :rest, :global, include: ~w(method download)
  slot :inner_block, required: false

  def a(%{link_type: "button", disabled: true} = assigns) do
    assigns = update_in(assigns.rest, &Map.drop(&1, [:"phx-click"]))

    ~H"""
    <button class={@class} disabled={@disabled} {@rest}>
      <%= if @label, do: @label, else: render_slot(@inner_block) %>
    </button>
    """
  end

  # Since the <a> tag can't be disabled, we turn it into a disabled button (looks exactly the same and does nothing when clicked)
  def a(%{disabled: true, link_type: type} = assigns) when type != "button" do
    a(Map.put(assigns, :link_type, "button"))
  end

  def a(%{link_type: "a"} = assigns) do
    ~H"""
    <.link href={@to} class={@class} {@rest}>
      <%= if(@label, do: @label, else: render_slot(@inner_block)) %>
    </.link>
    """
  end

  def a(%{link_type: "live_patch"} = assigns) do
    ~H"""
    <.link patch={@to} class={@class} {@rest}>
      <%= if(@label, do: @label, else: render_slot(@inner_block)) %>
    </.link>
    """
  end

  def a(%{link_type: "live_redirect"} = assigns) do
    ~H"""
    <.link navigate={@to} class={@class} {@rest}>
      <%= if(@label, do: @label, else: render_slot(@inner_block)) %>
    </.link>
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
