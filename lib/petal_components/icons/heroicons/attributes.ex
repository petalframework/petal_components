defmodule PetalComponents.Heroicons.Attributes do
  @moduledoc """
  SVG attributes for better accessibility.
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
