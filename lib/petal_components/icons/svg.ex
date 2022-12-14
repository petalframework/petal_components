defmodule PetalComponents.Svg do
  @moduledoc """
  SVG helper components.
  """
  use Phoenix.Component

  def title(assigns) do
    ~H"""
    <%= if not is_nil(@title) do %>
      <title><%= @title %></title>
    <% end %>
    """
  end
end
