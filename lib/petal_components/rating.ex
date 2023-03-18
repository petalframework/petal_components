defmodule PetalComponents.Rating do
  use Phoenix.Component
  import PetalComponents.Helpers
  alias Phoenix.LiveView.JS


  attr(:rating, :float, default: 0.0)
  attr(:total, :integer, default: 5)
  attr(:star_class, :string, default: "")
  attr(:with_rating_label, :boolean, default: false)

  def rating(assigns) do
    ~H"""
    <div class="pc-rating__wrapper">
      <%= for i <- 1..@total do %>
        <.star
          class={@star_class}
          type={calculate_type(i, @rating)}
        />
      <% end %>
      <%= if @with_rating_label do %>
        <span class="pc-rating__rating_label"><%= @rating %> out of <%= @total %></span>
      <% end %>
    </div>
    """
  end

  defp calculate_type(current_star, rating) do
    if current_star <= trunc(rating) do
      :filled
    else
      case rating - (current_star - 1) do
        0 -> :empty
        n when n >= 0.5 and n < 1 -> :half
        _ -> :empty
      end
    end
  end

  def star(%{type: :empty} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" class="pc-rating__star--empty">
      <path fill="none" d="M0 0h24v24H0z"/><path d="M12 18.26l-7.053 3.948 1.575-7.928L.587 8.792l8.027-.952L12 .5l3.386 7.34 8.027.952-5.935 5.488 1.575 7.928L12 18.26zm0-2.292l4.247 2.377-.949-4.773 3.573-3.305-4.833-.573L12 5.275l-2.038 4.42-4.833.572 3.573 3.305-.949 4.773L12 15.968z"/>
    </svg>
    """
  end

  def star(%{type: :filled} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" class="pc-rating__star--filled">
      <path fill="none" d="M0 0h24v24H0z"/><path d="M12 18.26l-7.053 3.948 1.575-7.928L.587 8.792l8.027-.952L12 .5l3.386 7.34 8.027.952-5.935 5.488 1.575 7.928z"/>
    </svg>
    """
  end

  def star(%{type: :half} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" class="pc-rating__star--half">
      <path fill="none" d="M0 0h24v24H0z"/><path d="M12 15.968l4.247 2.377-.949-4.773 3.573-3.305-4.833-.573L12 5.275v10.693zm0 2.292l-7.053 3.948 1.575-7.928L.587 8.792l8.027-.952L12 .5l3.386 7.34 8.027.952-5.935 5.488 1.575 7.928L12 18.26z"/>
    </svg>
    """
  end
end
