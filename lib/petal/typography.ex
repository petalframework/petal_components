defmodule Petal.Typography do
  use Phoenix.Component

  def h1(assigns) do
    ~H"""
    <h1 class="text-2xl font-bold leading-7 sm:leading-9 sm:truncate">
      <%= render_slot @inner_block %>
    </h1>
    """
  end
end
