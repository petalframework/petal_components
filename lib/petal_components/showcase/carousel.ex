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

  example :thumbnails, "Thumbnail navigation",
    description:
      "thumbnails swaps the indicators for miniature slides - the media-browser arrangement. Each thumbnail is the slide itself scaled down, so gradient panels, images and custom content all preview correctly." do
    ~H"""
    <.carousel
      id="showcase-carousel-thumbs"
      thumbnails
      transition_type="slide"
      class="max-w-lg mx-auto"
    >
      <:slide title="Overview" class="bg-gradient-to-br from-primary-500 to-secondary-500" />
      <:slide title="Pricing" class="bg-gradient-to-br from-secondary-500 to-primary-700" />
      <:slide title="Testimonials" class="bg-gradient-to-br from-primary-700 to-secondary-400" />
      <:slide title="FAQ" class="bg-gradient-to-br from-secondary-400 to-primary-500" />
    </.carousel>
    """
  end

  example :multi_view, "Several slides per view",
    description:
      "slides_per_view turns the carousel into a scrolling row - cards, products, team members - with gap between items and loop wrapping the ends. Swipe works on touch; the buttons page a full view at a time." do
    ~H"""
    <.carousel
      id="showcase-carousel-multi"
      slides_per_view={3}
      gap="1rem"
      loop
      size="small"
      class="max-w-2xl mx-auto"
    >
      <:slide title="Alpha" class="bg-gradient-to-br from-primary-400 to-primary-600" />
      <:slide title="Beta" class="bg-gradient-to-br from-secondary-400 to-secondary-600" />
      <:slide title="Gamma" class="bg-gradient-to-br from-primary-600 to-secondary-500" />
      <:slide title="Delta" class="bg-gradient-to-br from-secondary-600 to-primary-400" />
      <:slide title="Epsilon" class="bg-gradient-to-br from-primary-500 to-secondary-700" />
    </.carousel>
    """
  end
end
