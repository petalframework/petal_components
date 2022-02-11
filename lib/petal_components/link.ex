defmodule PetalComponents.Link do
  use Phoenix.Component

  # prop class, :string
  # prop label, :string
  # prop link_type, :string, options: ["a", "live_patch", "live_redirect"]
  def link(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:link_type, fn -> "a" end)
      |> assign_new(:label, fn -> nil end)
      |> assign_new(:inner_block, fn -> nil end)
      |> assign_new(:extra_assigns, fn ->
        assigns_to_attributes(assigns, [
          :class,
          :link_type,
          :type,
          :inner_block,
          :label
        ])
      end)

    ~H"""
    <%= case @link_type do %>
      <% "a" -> %>
        <%= Phoenix.HTML.Link.link [to: @to, class: @class] ++ @extra_assigns do %>
          <%= if @inner_block do %>
            <%= render_slot(@inner_block) %>
          <% else %>
            <%= @label %>
          <% end %>
        <% end %>
      <% "live_patch" -> %>
        <%= live_patch [
          to: @to,
          class: @class,
        ] ++ @extra_assigns do %>
          <%= if @inner_block do %>
            <%= render_slot(@inner_block) %>
          <% else %>
            <%= @label %>
          <% end %>
        <% end %>
      <% "live_redirect" -> %>
        <%= live_redirect [
          to: @to,
          class: @class,
        ] ++ @extra_assigns do %>
          <%= if @inner_block do %>
            <%= render_slot(@inner_block) %>
          <% else %>
            <%= @label %>
          <% end %>
        <% end %>
    <% end %>
    """
  end
end
