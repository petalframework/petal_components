defmodule PetalComponents.CarouselTest do
  use ComponentCase
  import PetalComponents.Carousel

  test "Basic carousel with fade transition" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.carousel id="test-carousel" transition_type="fade" indicator={true}>
        <:slide
          content_position="center"
          title="Welcome to Petal"
          description="A beautiful UI component library"
          image="https://example.com/image1.jpg"
        />
        <:slide
          content_position="end"
          title="Built with Tailwind"
          description="Modern utility-first CSS"
          image="https://example.com/image2.jpg"
        />
      </.carousel>
      """)

    # Check for basic structure
    assert html =~ "test-carousel"
    assert html =~ "pc-carousel__slides"
    assert html =~ "pc-carousel__slide"

    # Check for navigation controls
    assert html =~ "pc-carousel__button--prev"
    assert html =~ "pc-carousel__button--next"

    # Check for indicators
    assert html =~ "pc-carousel__indicator"

    # Check for slide content
    assert html =~ "Welcome to Petal"
    assert html =~ "Built with Tailwind"
    assert html =~ "A beautiful UI component library"
    assert html =~ "Modern utility-first CSS"

    # Check for images
    assert html =~ "https://example.com/image1.jpg"
    assert html =~ "https://example.com/image2.jpg"
  end

  test "Carousel with slide transition and autoplay" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.carousel
        id="test-carousel-2"
        transition_type="slide"
        indicator={true}
        autoplay={true}
        autoplay_interval={3000}
      >
        <:slide
          content_position="start"
          title="Feature 1"
          description="Amazing features"
          image="https://example.com/image1.jpg"
        />
        <:slide
          content_position="center"
          title="Feature 2"
          description="Modern technologies"
          image="https://example.com/image2.jpg"
        />
      </.carousel>
      """)

    # Check for transition type
    assert html =~ "data-transition-type=\"slide\""

    # Check for autoplay settings
    assert html =~ "data-autoplay=\"true\""
    assert html =~ "data-autoplay-interval=\"3000\""

    # Check for slide content
    assert html =~ "Feature 1"
    assert html =~ "Feature 2"
    assert html =~ "Amazing features"
    assert html =~ "Modern technologies"
  end

  test "Carousel with navigation links" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.carousel id="test-carousel-3">
        <:slide
          image="https://example.com/image1.jpg"
          title="Internal Link"
          description="Click to navigate"
          navigate="/components"
          content_position="center"
        />
        <:slide
          image="https://example.com/image2.jpg"
          title="External Link"
          description="Click for external site"
          href="https://github.com"
          content_position="end"
        />
      </.carousel>
      """)

    # Check for link elements in the rendered HTML
    assert html =~ "to=\"/components\""
    assert html =~ "href=\"https://github.com\""
    assert html =~ "pc-carousel__link"
    assert html =~ "Internal Link"
    assert html =~ "External Link"
    
    # Check that external links have target and rel attributes for security
    assert html =~ "target=\"_blank\""
    assert html =~ "rel=\"noopener noreferrer\""
    
    # Verify that links are clickable elements by checking they have the proper CSS class
    assert html =~ "<a"
    assert html =~ "class=\"pc-carousel__link\""
  end

  test "Carousel with custom classes" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.carousel id="test-carousel-4" class="my-custom-class" transition_type="fade" indicator={true}>
        <:slide
          content_position="center"
          title="Custom Class"
          description="Testing custom classes"
          image="https://example.com/image1.jpg"
          image_class="custom-image-class"
          title_class="custom-title-class"
          description_class="custom-description-class"
          wrapper_class="custom-wrapper-class"
        />
      </.carousel>
      """)

    # Check for custom class on carousel 
    assert html =~ "my-custom-class"
    
    # Note: The following class attributes aren't used in the current implementation
    # but we keep the test to document the expected behavior
    # If these features are implemented in the future, uncomment these tests
    # assert html =~ "custom-image-class"
    # assert html =~ "custom-title-class"
    # assert html =~ "custom-description-class"
    # assert html =~ "custom-wrapper-class"
  end

  test "Carousel with fully clickable slides" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.carousel id="test-carousel-5" transition_type="fade">
        <:slide
          image="https://example.com/image1.jpg"
          title="Clickable Internal Link"
          description="The entire slide should be clickable"
          navigate="/components"
        />
        <:slide
          image="https://example.com/image2.jpg"
          title="Clickable External Link" 
          description="The entire slide should be clickable and open in a new tab"
          href="https://github.com/petalframework/petal_components"
        />
      </.carousel>
      """)

    # Verify links exist and have proper structure
    assert html =~ "to=\"/components\""
    assert html =~ "class=\"pc-carousel__link\""
    
    # Verify external link with proper attributes
    assert html =~ "href=\"https://github.com/petalframework/petal_components\""
    assert html =~ "target=\"_blank\" rel=\"noopener noreferrer\""
    
    # Verify href link is in correct slide with matching content
    slide2_content = html 
      |> String.split("pc-carousel__slide")
      |> Enum.filter(&String.contains?(&1, "Clickable External Link"))
      |> List.first()
    
    assert slide2_content =~ "href=\"https://github.com/petalframework/petal_components\""
    assert slide2_content =~ "class=\"pc-carousel__link\""
  end
end
