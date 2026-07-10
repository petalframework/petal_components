defmodule PetalComponents.Rating do
  @moduledoc """
  Ratings, two ways:

    * **Display** (default) — render a score, with half-star precision.
    * **Interactive** (`interactive` + `name`) — a real radio group, so the
      value posts in forms, arrow keys work natively, and the hover preview
      is pure CSS. No JavaScript anywhere.

  Three icon sets: `star` (classic), `heart` (cumulative, like stars), and
  `face` — a five-point sentiment scale where each position is a different
  expression from awful to great, each with its own colour. Faces highlight
  only the chosen expression; stars and hearts fill cumulatively.
  """
  use Phoenix.Component

  attr(:rating, :any, default: 0, doc: "The rating to display (integer or float)")

  attr(:round_to_nearest_half, :boolean,
    default: true,
    doc: "Whether to round the rating to the nearest half star (eg. 3.3 -> 3.5"
  )

  attr(:total, :integer, default: 5, doc: "The total number of icons to display")

  attr(:icon, :string,
    default: "star",
    values: ["star", "heart", "face"],
    doc: "the icon set. Faces are a five-point sentiment scale (total is ignored)"
  )

  attr(:size, :string, default: "md", values: ["sm", "md", "lg"], doc: "icon size")

  attr(:interactive, :boolean,
    default: false,
    doc: "render as a radio group: clickable, keyboard-accessible, posts in forms. Requires name"
  )

  attr(:name, :string, default: nil, doc: "the input name (required when interactive)")

  attr(:disabled, :boolean, default: false, doc: "disable the interactive radios")

  attr(:label, :string,
    default: "Rating",
    doc: "accessible name for the interactive radio group"
  )

  attr(:class, :any, default: nil, doc: "Any additional CSS classes for the rating wrapper")

  attr(:star_class, :any,
    default: nil,
    doc:
      "Any additional CSS classes for the individual icons. Eg. you could change the size of the stars with 'h-10 w-10'"
  )

  attr(:include_label, :boolean,
    default: false,
    doc: "Whether to include an automatically generated rating label"
  )

  attr(:label_class, :any,
    default: nil,
    doc: "Any additional CSS classes for the rating label"
  )

  attr(:label_position, :string,
    default: "right",
    values: ["right", "bottom"],
    doc: "where the generated label sits relative to the icons"
  )

  attr(:rest, :global)

  slot(:glyph,
    required: false,
    doc:
      "a custom glyph (an svg or icon component) used for every position instead of the built-in sets. Design it to inherit currentColor/fill; recolour the active state with the --pc-rating-active-color CSS variable"
  )

  def rating(%{interactive: true} = assigns) do
    if is_nil(assigns.name) do
      raise ArgumentError, "an interactive <.rating> requires a name attribute"
    end

    assigns =
      assigns
      |> assign(:icon_kind, if(assigns.glyph != [], do: "custom", else: assigns.icon))
      |> assign(:value, assigns.rating |> to_float() |> round() |> trunc())

    assigns =
      assign(assigns, :total, if(assigns.icon_kind == "face", do: 5, else: assigns.total))

    ~H"""
    <fieldset
      class={[
        "pc-rating__group",
        "pc-rating--#{@icon_kind}",
        "pc-rating--#{@size}",
        @label_position == "bottom" && "pc-rating--label-bottom",
        @disabled && "pc-rating--disabled",
        @class
      ]}
      disabled={@disabled}
      {@rest}
    >
      <legend class="sr-only">{@label}</legend>
      <div class="pc-rating__icons">
        <label
          :for={i <- 1..@total}
          class="pc-rating__item"
          data-index={i}
          title={item_title(@icon_kind, i, @total)}
        >
          <input
            type="radio"
            name={@name}
            value={i}
            checked={@value == i}
            class="pc-rating__input"
            aria-label={item_title(@icon_kind, i, @total)}
          />
          <%= if @icon_kind == "custom" do %>
            {render_slot(@glyph, i)}
          <% else %>
            <.rating_icon icon={@icon_kind} index={i} class={@star_class} />
          <% end %>
        </label>
      </div>
      <span :if={@include_label} class={["pc-rating__label", @label_class]}>
        {generated_label(@icon_kind, @value + 0.0, @total)}
      </span>
    </fieldset>
    """
  end

  def rating(assigns) do
    assigns =
      assigns
      |> assign(:icon_kind, if(assigns.glyph != [], do: "custom", else: assigns.icon))
      |> assign(:rating_as_float, to_float(assigns.rating))

    assigns =
      assign(assigns, :total, if(assigns.icon_kind == "face", do: 5, else: assigns.total))

    ~H"""
    <div
      class={[
        "pc-rating__wrapper",
        "pc-rating--#{@icon_kind}",
        "pc-rating--#{@size}",
        @label_position == "bottom" && "pc-rating--label-bottom",
        @class
      ]}
      {@rest}
    >
      <div class="pc-rating__icons">
        <%= if @icon_kind == "star" do %>
          <.rating_star
            :for={i <- 1..@total}
            class={@star_class}
            type={calculate_type(i, @rating_as_float, @round_to_nearest_half)}
          />
        <% end %>
        <%= if @icon_kind == "face" do %>
          <span
            :for={i <- 1..@total}
            class="pc-rating__item"
            data-index={i}
            data-selected={round(@rating_as_float) == i && "true"}
            title={item_title("face", i, @total)}
          >
            <.rating_icon icon="face" index={i} class={@star_class} />
          </span>
        <% end %>
        <%= if @icon_kind in ["heart", "custom"] do %>
          <span :for={i <- 1..@total} class="pc-rating__item" data-index={i}>
            <%= if @icon_kind == "custom" do %>
              {render_slot(@glyph, i)}
            <% else %>
              <.rating_icon icon="heart" index={i} class={@star_class} />
            <% end %>
            <span
              class="pc-rating__fill"
              style={"--pc-rating-fill: #{fill_percent(i, @rating_as_float, @round_to_nearest_half)}%"}
              aria-hidden="true"
            >
              <%= if @icon_kind == "custom" do %>
                {render_slot(@glyph, i)}
              <% else %>
                <.rating_icon icon="heart" index={i} class={@star_class} />
              <% end %>
            </span>
          </span>
        <% end %>
      </div>

      <%= if @include_label do %>
        <span class={["pc-rating__label", @label_class]}>
          {generated_label(@icon_kind, @rating_as_float, @total)}
        </span>
      <% end %>
    </div>
    """
  end

  # cumulative sets fill each icon 0-100%; the fraction lands on one icon
  defp fill_percent(index, rating, round_to_half?) do
    rating = if round_to_half?, do: round_to_half(rating), else: rating

    cond do
      index <= trunc(rating) -> 100
      index - 1 < rating -> round((rating - (index - 1)) * 100)
      true -> 0
    end
  end

  defp generated_label("face", rating, _total) when rating >= 0.5,
    do: Enum.at(["Awful", "Bad", "Okay", "Good", "Great"], min(round(rating), 5) - 1)

  defp generated_label("face", _rating, _total), do: "Not rated"

  defp generated_label(_icon, rating, total) do
    rating = if rating == trunc(rating), do: trunc(rating), else: rating
    "#{rating} out of #{total}"
  end

  defp item_title("face", index, _total),
    do: Enum.at(["Awful", "Bad", "Okay", "Good", "Great"], index - 1)

  defp item_title(_icon, index, total), do: "#{index} of #{total}"

  defp to_float(value) when is_integer(value), do: value + 0.0
  defp to_float(value) when is_float(value), do: value

  defp round_to_half(number) do
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

  attr :icon, :string, required: true
  attr :index, :integer, required: true
  attr :class, :any, default: nil

  defp rating_icon(%{icon: "star"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" class={["pc-rating__icon", @class]}>
      <path fill="none" d="M0 0h24v24H0z" /><path d="M12 18.26l-7.053 3.948 1.575-7.928L.587 8.792l8.027-.952L12 .5l3.386 7.34 8.027.952-5.935 5.488 1.575 7.928z" />
    </svg>
    """
  end

  defp rating_icon(%{icon: "heart"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" class={["pc-rating__icon", @class]}>
      <path d="M11.645 20.91l-.007-.003-.022-.012a15.247 15.247 0 01-.383-.218 25.18 25.18 0 01-4.244-3.17C4.688 15.36 2.25 12.174 2.25 8.25 2.25 5.322 4.714 3 7.688 3A5.5 5.5 0 0112 5.052 5.5 5.5 0 0116.313 3c2.973 0 5.437 2.322 5.437 5.25 0 3.925-2.438 7.111-4.739 9.256a25.175 25.175 0 01-4.244 3.17 15.247 15.247 0 01-.383.219l-.022.012-.007.004-.003.001a.752.752 0 01-.704 0l-.003-.001z" />
    </svg>
    """
  end

  defp rating_icon(%{icon: "face"} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.8"
      stroke-linecap="round"
      class={["pc-rating__icon", @class]}
    >
      <circle cx="12" cy="12" r="9" />
      <circle cx="8.75" cy="9.75" r="0.5" fill="currentColor" stroke-width="1.5" />
      <circle cx="15.25" cy="9.75" r="0.5" fill="currentColor" stroke-width="1.5" />
      <path :if={@index == 1} d="M8.5 16.75q3.5 -3.25 7 0" />
      <path :if={@index == 2} d="M8.75 16q3.25 -1.75 6.5 0" />
      <path :if={@index == 3} d="M8.75 15.5h6.5" />
      <path :if={@index == 4} d="M8.75 14.75q3.25 2 6.5 0" />
      <path :if={@index == 5} d="M8.25 14.25q3.75 3.5 7.5 0" />
    </svg>
    """
  end

  attr :class, :any, default: nil, doc: "Any additional CSS classes for the star"
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
