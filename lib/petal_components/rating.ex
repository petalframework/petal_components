defmodule PetalComponents.Rating do
  use Phoenix.Component

  attr(:rating, :any, default: 0, doc: "The rating to display (integer or float)")

  attr(:round_to_nearest_half, :boolean,
    default: true,
    doc: "Whether to round the rating to the nearest half star (eg. 3.3 -> 3.5"
  )

  attr(:total, :integer, default: 5, doc: "The total number of stars to display")
  attr(:class, :string, default: nil, doc: "Any additional CSS classes for the rating wrapper")

  attr(:star_class, :string,
    default: nil,
    doc:
      "Any additional CSS classes for the individual stars. Eg. you could change the size of the stars with 'h-10 w-10'"
  )

  attr(:include_label, :boolean,
    default: false,
    doc: "Whether to include an automatically generated rating label"
  )

  attr(:label_class, :string, default: nil, doc: "Any additional CSS classes for the rating label")

  def rating(assigns) do
    assigns =
      assigns
      |> assign(:rating_as_float, to_float(assigns.rating))

    ~H"""
    <div class={["pc-rating__wrapper", @class]}>
      <%= for i <- 1..@total do %>
        <.rating_star
          class={@star_class}
          type={calculate_type(i, @rating_as_float, @round_to_nearest_half)}
        />
      <% end %>

      <%= if @include_label do %>
        <span class={["pc-rating__label", @label_class]}>
          <%= @rating_as_float %> out of <%= @total %>
        </span>
      <% end %>
    </div>
    """
  end

  def to_float(value) when is_integer(value), do: value + 0.0
  def to_float(value) when is_float(value), do: value

  def round_to_half(number) do
    round(number * 2) / 2
  end

  defp calculate_type(current_star, rating, round_to_nearest_half) do
    maybe_rounded = if round_to_nearest_half, do: round_to_half(rating), else: rating

    if current_star <= trunc(rating) do
      :filled
    else
      case maybe_rounded - (current_star - 1) do
        n when n >= 0.5 and n < 1 -> :half
        _ -> :empty
      end
    end
  end

  attr :class, :string, default: nil, doc: "Any additional CSS classes for the star"
  attr :type, :atom, default: :empty, doc: "The type of star to display"

  def rating_star(%{type: :empty} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      class={["pc-rating__star--empty", @class]}
    >
      <path fill="none" d="M0 0h24v24H0z" /><path d="M12 18.26l-7.053 3.948 1.575-7.928L.587 8.792l8.027-.952L12 .5l3.386 7.34 8.027.952-5.935 5.488 1.575 7.928L12 18.26zm0-2.292l4.247 2.377-.949-4.773 3.573-3.305-4.833-.573L12 5.275l-2.038 4.42-4.833.572 3.573 3.305-.949 4.773L12 15.968z" />
    </svg>
    """
  end

  def rating_star(%{type: :filled} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      class={["pc-rating__star--filled", @class]}
    >
      <path fill="none" d="M0 0h24v24H0z" /><path d="M12 18.26l-7.053 3.948 1.575-7.928L.587 8.792l8.027-.952L12 .5l3.386 7.34 8.027.952-5.935 5.488 1.575 7.928z" />
    </svg>
    """
  end

  def rating_star(%{type: :half} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      class={["pc-rating__star--half", @class]}
    >
      <path fill="none" d="M0 0h24v24H0z" /><path d="M12 15.968l4.247 2.377-.949-4.773 3.573-3.305-4.833-.573L12 5.275v10.693zm0 2.292l-7.053 3.948 1.575-7.928L.587 8.792l8.027-.952L12 .5l3.386 7.34 8.027.952-5.935 5.488 1.575 7.928L12 18.26z" />
    </svg>
    """
  end
end
