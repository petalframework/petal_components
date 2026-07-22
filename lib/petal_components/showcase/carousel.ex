defmodule PetalComponents.Showcase.Carousel do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Carousel, title: "Carousel"

  example :content_slides, "Content slides",
    description:
      "Slides are built from attrs - a per-slide class gives you gradient panels with no images at all. Fade transition, dot indicators, glass overlay buttons." do
    ~H"""
    <.carousel id="showcase-carousel" indicator indicator_style="dots" class="max-w-lg mx-auto">
      <:slide
        title="Ship the whole feature"
        description="Auth, billing, orgs - the boring parts, done."
        class="bg-gradient-to-br from-primary-500 to-secondary-500"
      />
      <:slide
        title="Style with the dials"
        description="Primary, gray and radius tokens restyle everything."
        class="bg-gradient-to-br from-secondary-500 to-primary-700"
      />
      <:slide
        title="Zero JS dependencies"
        description="Scroll snap and a thin hook. Nothing from npm."
        class="bg-gradient-to-br from-primary-700 to-secondary-400"
      />
    </.carousel>
    """
  end

  example :below_the_frame, "Controls outside the frame",
    description:
      "The slide transition with buttons flanking the frame and page-coloured dots underneath - the product-gallery arrangement." do
    ~H"""
    <.carousel
      id="showcase-carousel-outside"
      transition_type="slide"
      button_style="outside"
      indicator
      indicator_position="below"
      class="max-w-lg mx-auto"
    >
      <:slide title="Slide one" class="bg-gradient-to-br from-gray-700 to-gray-900" />
      <:slide title="Slide two" class="bg-gradient-to-br from-gray-600 to-gray-800" />
      <:slide title="Slide three" class="bg-gradient-to-br from-gray-500 to-gray-700" />
    </.carousel>
    """
  end
end
