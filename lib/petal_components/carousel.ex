defmodule PetalComponents.Carousel do
  @moduledoc """
  Provides a versatile and customizable carousel component.

  This component enables the creation of carousels with various features such as
  slide indicators, navigation controls, and dynamic slide content.

  ## Features

  - **Slides**: Define multiple slides, each with custom content.
  - **Navigation Controls**: Include previous and next buttons to manually navigate through the slides.
  - **Indicators**: Optional indicators show the current slide and allow direct navigation to any slide.
  - **Transition Types**: Choose between fade and slide transitions.
  - **Responsive Design**: Supports various sizes and padding options to adapt to different screen sizes.
  """

  use Phoenix.Component
  import PetalComponents.Icon, only: [icon: 1]
  import Phoenix.LiveView.Utils, only: [random_id: 0]

  @doc """
  The `carousel` component is used to create interactive carousels with customizable attributes
  such as `size`, `padding`, and `transition_type`. It supports adding multiple slides with different content,
  and includes options for navigation controls and indicators.

  ## Examples

  ### Basic carousel with bar indicators (default)
  ```elixir
  <.carousel id="carousel-test-one" transition_type="fade" indicator={true}>
    <:slide title="Slide 1" />
    <:slide title="Slide 2" />
    <:slide title="Slide 3" />
  </.carousel>
  ```

  ### Carousel with circular dot indicators
  ```elixir
  <.carousel id="carousel-test-two" transition_type="slide" indicator={true} indicator_style="dots">
    <:slide title="Slide 1" />
    <:slide title="Slide 2" />
    <:slide title="Slide 3" />
  </.carousel>
  ```
  """
  @doc type: :component
  attr :id, :string, doc: "A unique identifier is used to manage state and interaction"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :size, :string, default: "large", doc: "Determines the overall size of the elements"
  attr :padding, :string, default: "medium", doc: "Determines padding for items"
  attr :text_position, :string, default: "center", doc: "Determines the element's text position"
  attr :rest, :global, doc: "Global attributes can define defaults"
  attr :indicator, :boolean, default: false, doc: "Specifies whether to show element indicators"

  attr :indicator_style, :string,
    default: "bars",
    doc: "Style of indicators: 'bars' (horizontal bars) or 'dots' (circular dots)"

  attr :control, :boolean, default: true, doc: "Determines whether to show navigation controls"
  attr :active_index, :integer, default: 0, doc: "Index of the active slide (starts at 0)"
  attr :autoplay, :boolean, default: false, doc: "Enable or disable autoplay functionality"
  attr :autoplay_interval, :integer, default: 5000, doc: "Time between slides in ms"

  attr :transition_type, :string,
    default: "fade",
    doc: "Type of transition between slides (fade or slide)"

  attr :transition_duration, :integer, default: 500, doc: "Duration of transition in milliseconds"

  attr :button_style, :string,
    default: "overlay",
    doc: "Button style: 'overlay' (on sides), 'below' (under carousel), 'sides' (outside carousel), or 'none'"

  attr :rounded, :string,
    default: nil,
    doc: "Border radius for images: 'sm', 'md', 'lg', 'xl', '2xl', '3xl', or 'full'"

  attr :slides_per_view, :integer,
    default: 1,
    doc: "Number of slides visible at once (1 for single slide, 3 for multi-slide gallery view)"

  attr :gap, :string,
    default: "1rem",
    doc: "Gap between slides when slides_per_view > 1"

  attr :swipe, :boolean,
    default: true,
    doc: "Enable touch swipe navigation on mobile devices (only applies to slide transitions)"

  attr :loop, :boolean,
    default: true,
    doc: "Enable infinite looping (when false, carousel has definitive start/end)"

  attr :overlay_gradient, :boolean,
    default: false,
    doc: "Add gradient overlay at edges (especially useful for multi-slide views)"

  attr :orientation, :string,
    default: "horizontal",
    values: ["horizontal", "vertical"],
    doc: "Orientation of the carousel: 'horizontal' (default) or 'vertical'"

  slot :slide, required: true do
    attr :title, :string, doc: "Title of the slide"
    attr :description, :string, doc: "Description of the slide"
    attr :class, :string, doc: "Custom CSS class for additional styling"
    attr :image, :string, doc: "URL of the image to display in the slide"
    attr :navigate, :string, doc: "Internal route to navigate to when the slide is clicked"
    attr :href, :string, doc: "External URL to navigate to when the slide is clicked"
    attr :content_position, :string, doc: "Position of content (start, center, end)"
  end

  def carousel(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> "carousel-#{random_id()}" end)
      |> assign_new(:transition_class, fn -> transition_class(assigns.transition_type) end)
      |> assign_new(:is_vertical, fn -> assigns.orientation == "vertical" end)

    ~H"""
    <div class={["pc-carousel-wrapper", button_wrapper_class(@button_style), @is_vertical && "pc-carousel-wrapper--vertical"]}>
      <button
        :if={@control && @button_style == "sides"}
        id={"#{@id}-carousel-prev"}
        class="pc-carousel__button pc-carousel__button--prev pc-carousel__button--sides"
        aria-label={@is_vertical && "Previous slide (up)" || "Previous slide"}
      >
        <.icon name={@is_vertical && "hero-chevron-up" || "hero-chevron-left"} class="w-3 h-3 md:w-4 md:h-4" />
      </button>

      <div
        id={@id}
        phx-hook="CarouselHook"
        phx-update="ignore"
        data-active-index={@active_index}
        data-autoplay={to_string(@autoplay)}
        data-autoplay-interval={@autoplay_interval}
        data-transition-type={@transition_type}
        data-transition-duration={@transition_duration}
        data-slides-per-view={@slides_per_view}
        data-gap={@gap}
        data-swipe={to_string(@swipe)}
        data-loop={to_string(@loop)}
        class={[
          "pc-carousel",
          @transition_class,
          size_class(@size),
          padding_class(@padding),
          text_position_class(@text_position),
          button_style_class(@button_style),
          @is_vertical && "pc-carousel--vertical",
          @class
        ]}
      >
        <button
          :if={@control && @button_style == "overlay"}
          id={"#{@id}-carousel-prev"}
          class="pc-carousel__button pc-carousel__button--prev pc-carousel__button--overlay"
          aria-label={@is_vertical && "Previous slide (up)" || "Previous slide"}
        >
          <.icon name={@is_vertical && "hero-chevron-up" || "hero-chevron-left"} class="w-4 h-4 md:w-6 md:h-6" />
        </button>

        <button
          :if={@control && @button_style == "overlay"}
          id={"#{@id}-carousel-next"}
          class="pc-carousel__button pc-carousel__button--next pc-carousel__button--overlay"
          aria-label={@is_vertical && "Next slide (down)" || "Next slide"}
        >
          <.icon name={@is_vertical && "hero-chevron-down" || "hero-chevron-right"} class="w-4 h-4 md:w-6 md:h-6" />
        </button>

        <div class="pc-carousel__slides">
          <div
            :for={{slide, index} <- Enum.with_index(@slide)}
            id={"#{@id}-carousel-slide-#{index}"}
            class={[
              "pc-carousel__slide",
              if(index == @active_index,
                do: "pc-carousel__slide--active",
                else: "pc-carousel__slide--inactive"
              ),
              slide[:class]
            ]}
          >
            <.slide_content
              slide={slide}
              index={index}
              navigate={slide[:navigate]}
              href={slide[:href]}
              image={slide[:image]}
              title={slide[:title]}
              description={slide[:description]}
              rounded={@rounded}
            />
          </div>
        </div>

        <.slide_indicators :if={@indicator} id={@id} count={length(@slide)} style={@indicator_style} />

        <%= if @overlay_gradient do %>
          <%= if @is_vertical do %>
            <div class="pc-gradient-overlay-top"></div>
            <div class="pc-gradient-overlay-bottom"></div>
          <% else %>
            <div class="pc-gradient-overlay-left"></div>
            <div class="pc-gradient-overlay-right"></div>
          <% end %>
        <% end %>
      </div>

      <div :if={@control && @button_style == "below"} class="pc-carousel__controls pc-carousel__controls--below">
        <button
          id={"#{@id}-carousel-prev"}
          class="pc-carousel__button pc-carousel__button--prev pc-carousel__button--below"
          aria-label={@is_vertical && "Previous slide (up)" || "Previous slide"}
        >
          <.icon name={@is_vertical && "hero-chevron-up" || "hero-chevron-left"} class="w-3 h-3 md:w-4 md:h-4" />
        </button>

        <button
          id={"#{@id}-carousel-next"}
          class="pc-carousel__button pc-carousel__button--next pc-carousel__button--below"
          aria-label={@is_vertical && "Next slide (down)" || "Next slide"}
        >
          <.icon name={@is_vertical && "hero-chevron-down" || "hero-chevron-right"} class="w-3 h-3 md:w-4 md:h-4" />
        </button>
      </div>

      <button
        :if={@control && @button_style == "sides"}
        id={"#{@id}-carousel-next"}
        class="pc-carousel__button pc-carousel__button--next pc-carousel__button--sides"
        aria-label={@is_vertical && "Next slide (down)" || "Next slide"}
      >
        <.icon name={@is_vertical && "hero-chevron-down" || "hero-chevron-right"} class="w-3 h-3 md:w-4 md:h-4" />
      </button>
    </div>
    """
  end

  defp slide_indicators(assigns) do
    indicator_class = indicator_style_class(assigns.style)

    assigns = assign(assigns, :indicator_class, indicator_class)

    ~H"""
    <div id={"#{@id}-carousel-slide-indicator"} class="pc-carousel__indicators">
      <button
        :for={indicator_item <- 1..@count}
        id={"#{@id}-carousel-indicator-#{indicator_item}"}
        data-indicator-index={"#{indicator_item - 1}"}
        class={["pc-carousel__indicator", @indicator_class]}
        aria-label={"Slide #{indicator_item}"}
      />
    </div>
    """
  end

  defp transition_class("fade") do
    "[&_.pc-carousel__slide]:transition-opacity [&_.pc-carousel__slide]:duration-500 [&_.pc-carousel__slide]:ease-in-out"
  end

  defp transition_class("slide") do
    "[&_.pc-carousel__slide]:transition-transform [&_.pc-carousel__slide]:duration-500 [&_.pc-carousel__slide]:ease-in-out"
  end

  defp transition_class(_), do: ""

  defp size_class("small"), do: "text-sm [&_.description-wrapper]:max-w-96"
  defp size_class("medium"), do: "text-base [&_.description-wrapper]:max-w-xl"
  defp size_class("large"), do: "text-lg [&_.description-wrapper]:max-w-2xl"
  defp size_class(_), do: ""

  defp padding_class("small"), do: "[&_.description-wrapper]:p-3"
  defp padding_class("medium"), do: "[&_.description-wrapper]:p-4"
  defp padding_class("large"), do: "[&_.description-wrapper]:p-5"
  defp padding_class(_), do: ""

  defp text_position_class("start"), do: "[&_.description-wrapper]:text-start"
  defp text_position_class("center"), do: "[&_.description-wrapper]:text-center"
  defp text_position_class("end"), do: "[&_.description-wrapper]:text-end"
  defp text_position_class(_), do: ""

  defp button_style_class("overlay"), do: "pc-carousel--overlay-buttons"
  defp button_style_class("below"), do: "pc-carousel--below-buttons"
  defp button_style_class("sides"), do: "pc-carousel--sides-buttons"
  defp button_style_class("none"), do: ""
  defp button_style_class(_), do: "pc-carousel--overlay-buttons"

  defp button_wrapper_class("below"), do: "pc-carousel-wrapper--below"
  defp button_wrapper_class("sides"), do: "pc-carousel-wrapper--sides"
  defp button_wrapper_class(_), do: ""

  defp slide_rounded_class(nil), do: ""
  defp slide_rounded_class("sm"), do: "rounded-sm"
  defp slide_rounded_class("md"), do: "rounded-md"
  defp slide_rounded_class("lg"), do: "rounded-lg"
  defp slide_rounded_class("xl"), do: "rounded-xl"
  defp slide_rounded_class("2xl"), do: "rounded-2xl"
  defp slide_rounded_class("3xl"), do: "rounded-3xl"
  defp slide_rounded_class("full"), do: "rounded-full"
  defp slide_rounded_class(_), do: ""

  defp indicator_style_class("dots"), do: "pc-carousel__indicator--dots"
  defp indicator_style_class("circles"), do: "pc-carousel__indicator--dots"
  defp indicator_style_class("bars"), do: "pc-carousel__indicator--bars"
  defp indicator_style_class(_), do: "pc-carousel__indicator--bars"

  defp slide_content(assigns) do
    content_position_class =
      case Map.get(assigns, :slide)[:content_position] do
        "start" -> "items-start justify-start text-left"
        "end" -> "items-end justify-end text-right"
        "center" -> "items-center justify-center text-center"
        # Default to center
        _ -> "items-center justify-center text-center"
      end

    rounded_class = slide_rounded_class(Map.get(assigns, :rounded))

    assigns =
      assigns
      |> assign(:content_position_class, content_position_class)
      |> assign(:rounded_class, rounded_class)

    ~H"""
    <div class={["pc-carousel__slide-content", @rounded_class]}>
      <div :if={!is_nil(@image)} class="pc-carousel__image-wrapper">
        <img src={@image} class="pc-carousel__image" />
      </div>
      <div class="pc-carousel__content">
        <div class={"pc-carousel__content-wrapper #{@content_position_class}"}>
          <div :if={!is_nil(@title)} class="pc-carousel__title">
            {@title}
          </div>
          <p :if={!is_nil(@description)} class="pc-carousel__description">
            {@description}
          </p>
        </div>
      </div>
    </div>

    <%= if @navigate do %>
      <div class="pc-carousel__link-indicator" aria-hidden="true">
        <.icon name="hero-arrow-right" class="w-5 h-5" />
      </div>
      <a href={@navigate} class="pc-carousel__link">
        <span class="sr-only">Navigate to {@navigate}</span>
      </a>
    <% end %>
    <%= if @href do %>
      <div class="pc-carousel__link-indicator" aria-hidden="true">
        <.icon name="hero-arrow-top-right-on-square" class="w-5 h-5" />
      </div>
      <a href={@href} class="pc-carousel__link" target="_blank" rel="noopener noreferrer">
        <span class="sr-only">Open external link (opens in new tab)</span>
      </a>
    <% end %>
    """
  end
end
