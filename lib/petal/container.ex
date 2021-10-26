defmodule Petal.Container do
  use Phoenix.Component

  def full_width(assigns) do
    ~H"""
    <div class={"
      mx-auto max-w-7xl sm:px-6 lg:px-8

      #{if assigns[:padding_on_mobile], do: "px-4", else: ""}
      #{if assigns[:class], do: @class, else: ""}
    "}>
      <div class="max-w-3xl mx-auto">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
