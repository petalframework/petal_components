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
  alias Phoenix.HTML.Link
  import PetalComponents.Link

  @doc """
  The `carousel` component is used to create interactive carousels with customizable attributes
  such as `size`, `padding`, and `transition_type`. It supports adding multiple slides with different content,
  and includes options for navigation controls and indicators.

  ## Examples

  ```elixir
  <.carousel id="carousel-test-one" transition_type="fade" indicator={true}>
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
  attr :control, :boolean, default: true, doc: "Determines whether to show navigation controls"
  attr :active_index, :integer, default: 0, doc: "Index of the active slide (starts at 0)"
  attr :autoplay, :boolean, default: false, doc: "Enable or disable autoplay functionality"
  attr :autoplay_interval, :integer, default: 5000, doc: "Time between slides in ms"

  attr :transition_type, :string,
    default: "fade",
    doc: "Type of transition between slides (fade or slide)"

  attr :transition_duration, :integer, default: 500, doc: "Duration of transition in milliseconds"

  slot :slide, required: true do
    attr :title, :string, doc: "Title of the slide"
    attr :description, :string, doc: "Description of the slide"
    attr :class, :string, doc: "Custom CSS class for additional styling"
    attr :image, :string, doc: "URL of the image to display in the slide"
    attr :navigate, :string, doc: "Internal route to navigate to when the slide is clicked"
    attr :href, :string, doc: "External URL to navigate to when the slide is clicked"
  end

  def carousel(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> "carousel-#{random_id()}" end)
      |> assign_new(:transition_class, fn -> transition_class(assigns.transition_type) end)

    ~H"""
    <div
      id={@id}
      phx-hook="CarouselHook"
      phx-update="ignore"
      data-active-index={@active_index}
      data-autoplay={to_string(@autoplay)}
      data-autoplay-interval={@autoplay_interval}
      data-transition-type={@transition_type}
      data-transition-duration={@transition_duration}
      class={[
        "pc-carousel",
        @transition_class,
        size_class(@size),
        padding_class(@padding),
        text_position_class(@text_position),
        @class
      ]}
    >
      <button
        :if={@control}
        id={"#{@id}-carousel-prev"}
        class="pc-carousel__button pc-carousel__button--prev"
        aria-label="Previous slide"
      >
        <.icon name="hero-chevron-left-solid" class="pc-carousel__icon" />
      </button>

      <button
        :if={@control}
        id={"#{@id}-carousel-next"}
        class="pc-carousel__button pc-carousel__button--next"
        aria-label="Next slide"
      >
        <.icon name="hero-chevron-right-solid" class="pc-carousel__icon" />
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
          style={
            if @transition_type == "fade" do
              if index == @active_index,
                do: "opacity: 1; z-index: 10;",
                else: "opacity: 0; z-index: 0;"
            else
              if index == @active_index,
                do: "opacity: 1; z-index: 10; transform: translateX(0);",
                else: "opacity: 0; z-index: 0; transform: translateX(100%);"
            end
          }
        >
          <.slide_content
            slide={slide}
            index={index}
            navigate={slide[:navigate]}
            href={slide[:href]}
            image={slide[:image]}
            title={slide[:title] || "Slide #{index + 1}"}
            description={slide[:description]}
          />
        </div>
      </div>

      <.slide_indicators :if={@indicator} id={@id} count={length(@slide)} />
    </div>
    """
  end

  defp slide_indicators(assigns) do
    ~H"""
    <div id={"#{@id}-carousel-slide-indicator"} class="pc-carousel__indicators">
      <button
        :for={indicator_item <- 1..@count}
        id={"#{@id}-carousel-indicator-#{indicator_item}"}
        data-indicator-index={"#{indicator_item - 1}"}
        class="pc-carousel__indicator"
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
  
  defp slide_content(assigns) do
    ~H"""
    <div class="pc-carousel__slide-content">
      <div :if={!is_nil(@image)} class="pc-carousel__image-wrapper">
        <img src={@image} class="pc-carousel__image" />
      </div>
      <div class="pc-carousel__content">
        <div class="pc-carousel__content-wrapper">
          <div class="pc-carousel__title">
            {@title}
          </div>
          <p :if={!is_nil(@description)} class="pc-carousel__description">
            {@description}
          </p>
        </div>
      </div>
    </div>
    
    <.link :if={@navigate} to={@navigate} class="pc-carousel__link absolute inset-0 z-20">
      <span class="sr-only">View slide details</span>
    </.link>
    <a :if={@href} href={@href} class="pc-carousel__link absolute inset-0 z-20">
      <span class="sr-only">View external link</span>
    </a>
    """
  end
end
