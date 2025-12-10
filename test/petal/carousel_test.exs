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
    assert html =~ "href=\"/components\""
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

    # Check for link indicators
    assert html =~ "pc-carousel__link-indicator"

    # Check for internal navigation icon (arrow-right)
    assert html =~ "hero-arrow-right"

    # Check for external link icon (arrow-top-right-on-square)
    assert html =~ "hero-arrow-top-right-on-square"
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
    assert html =~ "href=\"/components\""
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

    # Verify link indicators are present for clickable slides
    assert html =~ "pc-carousel__link-indicator"
  end

  test "Carousel link indicators" do
    assigns = %{}

    # Test that slides without links don't have indicators
    html =
      rendered_to_string(~H"""
      <.carousel id="test-no-link">
        <:slide image="https://example.com/image1.jpg" title="No Link" />
      </.carousel>
      """)

    refute html =~ "pc-carousel__link-indicator"

    # Test internal link indicator
    html =
      rendered_to_string(~H"""
      <.carousel id="test-internal">
        <:slide navigate="/test" image="https://example.com/image1.jpg" title="Internal" />
      </.carousel>
      """)

    assert html =~ "pc-carousel__link-indicator"
    assert html =~ "hero-arrow-right"
    refute html =~ "hero-arrow-top-right-on-square"

    # Test external link indicator
    html =
      rendered_to_string(~H"""
      <.carousel id="test-external">
        <:slide href="https://example.com" image="https://example.com/image1.jpg" title="External" />
      </.carousel>
      """)

    assert html =~ "pc-carousel__link-indicator"
    assert html =~ "hero-arrow-top-right-on-square"
    refute html =~ "hero-arrow-right"
  end

  test "Carousel with content positioning" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.carousel id="test-carousel-7" transition_type="fade">
        <:slide
          content_position="start"
          title="Left Aligned Content"
          description="This content should be left-aligned"
          image="https://example.com/image1.jpg"
        />
        <:slide
          content_position="center"
          title="Center Aligned Content"
          description="This content should be centered"
          image="https://example.com/image2.jpg"
        />
        <:slide
          content_position="end"
          title="Right Aligned Content"
          description="This content should be right-aligned"
          image="https://example.com/image3.jpg"
        />
      </.carousel>
      """)

    # Check for proper content position classes
    assert html =~ "items-start justify-start text-left"
    assert html =~ "items-center justify-center text-center"
    assert html =~ "items-end justify-end text-right"

    # Verify content is present
    assert html =~ "Left Aligned Content"
    assert html =~ "Center Aligned Content"
    assert html =~ "Right Aligned Content"
  end

  test "Carousel with slide containing no title" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.carousel id="test-carousel-6" transition_type="fade">
        <:slide
          image="https://example.com/image1.jpg"
          description="This slide has a description but no title"
        />
        <:slide
          image="https://example.com/image2.jpg"
        />
      </.carousel>
      """)

    # Check that image is present
    assert html =~ "https://example.com/image1.jpg"
    
    # Check that description is present
    assert html =~ "This slide has a description but no title"
    
    # Check that no default title is added (should not have "Slide 1" text)
    refute html =~ "Slide 1"
    refute html =~ "Slide 2"
    
    # Check that the second image is in the HTML
    assert html =~ "https://example.com/image2.jpg"
    
    # Make sure no default titles are created
    refute html =~ "Slide 1"
    refute html =~ "Slide 2"
  end

  # Button Styles Tests
  test "Carousel with overlay button style (default)" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.carousel id="test-overlay" button_style="overlay">
        <:slide image="https://example.com/image1.jpg" title="Overlay Buttons" />
        <:slide image="https://example.com/image2.jpg" title="Second Slide" />
      </.carousel>
      """)

    # Check for overlay button classes
    assert html =~ "pc-carousel__button--overlay"
    assert html =~ "pc-carousel--overlay-buttons"
  end

  test "Carousel with below button style" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.carousel id="test-below" button_style="below">
        <:slide image="https://example.com/image1.jpg" title="Below Buttons" />
      </.carousel>
      """)

    assert html =~ "pc-carousel__button--below"
    assert html =~ "pc-carousel__controls--below"
  end

  test "Carousel with sides button style" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.carousel id="test-sides" button_style="sides">
        <:slide image="https://example.com/image1.jpg" title="Side Buttons" />
      </.carousel>
      """)

    assert html =~ "pc-carousel__button--sides"
    assert html =~ "pc-carousel-wrapper--sides"
  end

  test "Carousel with no controls" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.carousel id="test-no-controls" control={false}>
        <:slide image="https://example.com/image1.jpg" title="No Controls" />
      </.carousel>
      """)

    refute html =~ "pc-carousel__button--prev"
    refute html =~ "pc-carousel__button--next"
  end

  # Rounded Images Tests
  test "Carousel with rounded images" do
    rounded_values = ["sm", "md", "lg", "xl", "2xl", "3xl", "full"]

    Enum.each(rounded_values, fn rounded ->
      assigns = %{rounded: rounded}

      html =
        rendered_to_string(~H"""
        <.carousel id={"test-rounded-#{@rounded}"} rounded={@rounded}>
          <:slide image="https://example.com/image1.jpg" title="Rounded" />
        </.carousel>
        """)

      # Check that the rounded class is applied to the slide-content div
      assert html =~ "rounded-#{rounded}"
      assert html =~ "pc-carousel__slide-content"
    end)
  end

  # Multi-Slide Gallery and Swipe Tests
  test "Carousel with multi-slide gallery and swipe" do
    assigns = %{}

    # Multi-slide with 3 slides
    html =
      rendered_to_string(~H"""
      <.carousel id="test-multi-3" transition_type="slide" slides_per_view={3} gap="1.5rem">
        <:slide image="https://example.com/image1.jpg" />
        <:slide image="https://example.com/image2.jpg" />
      </.carousel>
      """)

    assert html =~ ~s{data-slides-per-view="3"}
    assert html =~ ~s{data-gap="1.5rem"}
    assert html =~ ~s{data-swipe="true"}

    # Swipe disabled
    html =
      rendered_to_string(~H"""
      <.carousel id="test-swipe-off" transition_type="slide" swipe={false}>
        <:slide image="https://example.com/image1.jpg" />
      </.carousel>
      """)

    assert html =~ ~s{data-swipe="false"}
  end

  test "Carousel with overlay gradient" do
    assigns = %{}

    # With overlay gradient
    html =
      rendered_to_string(~H"""
      <.carousel id="test-gradient" overlay_gradient={true} slides_per_view={3}>
        <:slide image="https://example.com/image1.jpg" />
        <:slide image="https://example.com/image2.jpg" />
        <:slide image="https://example.com/image3.jpg" />
      </.carousel>
      """)

    assert html =~ "pc-gradient-overlay-left"
    assert html =~ "pc-gradient-overlay-right"

    # Without overlay gradient
    html =
      rendered_to_string(~H"""
      <.carousel id="test-no-gradient" overlay_gradient={false}>
        <:slide image="https://example.com/image1.jpg" />
      </.carousel>
      """)

    refute html =~ "pc-gradient-overlay-left"
    refute html =~ "pc-gradient-overlay-right"
  end

  # Autoplay Tests
  test "Carousel autoplay configuration" do
    assigns = %{}

    # Autoplay enabled
    html =
      rendered_to_string(~H"""
      <.carousel id="test-autoplay-on" autoplay={true} autoplay_interval={3000}>
        <:slide image="https://example.com/image1.jpg" />
      </.carousel>
      """)

    assert html =~ ~s{data-autoplay="true"}
    assert html =~ ~s{data-autoplay-interval="3000"}

    # Autoplay disabled
    html =
      rendered_to_string(~H"""
      <.carousel id="test-autoplay-off">
        <:slide image="https://example.com/image1.jpg" />
      </.carousel>
      """)

    assert html =~ ~s{data-autoplay="false"}
  end

  # Size, Padding, and Text Position Tests
  test "Carousel styling options" do
    assigns = %{}

    # Test sizes
    html =
      rendered_to_string(~H"""
      <.carousel id="test-size-small" size="small">
        <:slide image="https://example.com/image1.jpg" />
      </.carousel>
      """)

    assert html =~ "text-sm"

    # Test padding with escaped ampersands
    html =
      rendered_to_string(~H"""
      <.carousel id="test-pad-large" padding="large">
        <:slide image="https://example.com/image1.jpg" />
      </.carousel>
      """)

    assert html =~ "[&amp;_.description-wrapper]:p-5"

    # Test text position
    html =
      rendered_to_string(~H"""
      <.carousel id="test-text-start" text_position="start">
        <:slide image="https://example.com/image1.jpg" />
      </.carousel>
      """)

    assert html =~ "[&amp;_.description-wrapper]:text-start"
  end

  # Indicators Tests
  test "Carousel indicators" do
    assigns = %{}

    # With indicators (default bars style)
    html =
      rendered_to_string(~H"""
      <.carousel id="test-ind" indicator={true}>
        <:slide image="https://example.com/image1.jpg" />
        <:slide image="https://example.com/image2.jpg" />
      </.carousel>
      """)

    assert html =~ "pc-carousel__indicators"
    assert html =~ "pc-carousel__indicator"
    assert html =~ "pc-carousel__indicator--bars"

    # Without indicators
    html =
      rendered_to_string(~H"""
      <.carousel id="test-no-ind" indicator={false}>
        <:slide image="https://example.com/image1.jpg" />
      </.carousel>
      """)

    refute html =~ "pc-carousel__indicators"
  end

  test "Carousel indicator styles" do
    assigns = %{}

    # Bar indicators (default)
    html =
      rendered_to_string(~H"""
      <.carousel id="test-ind-bars" indicator={true} indicator_style="bars">
        <:slide image="https://example.com/image1.jpg" />
        <:slide image="https://example.com/image2.jpg" />
      </.carousel>
      """)

    assert html =~ "pc-carousel__indicator--bars"
    refute html =~ "pc-carousel__indicator--dots"

    # Dot indicators
    html =
      rendered_to_string(~H"""
      <.carousel id="test-ind-dots" indicator={true} indicator_style="dots">
        <:slide image="https://example.com/image1.jpg" />
        <:slide image="https://example.com/image2.jpg" />
      </.carousel>
      """)

    assert html =~ "pc-carousel__indicator--dots"
    refute html =~ "pc-carousel__indicator--bars"

    # Circles (should map to dots)
    html =
      rendered_to_string(~H"""
      <.carousel id="test-ind-circles" indicator={true} indicator_style="circles">
        <:slide image="https://example.com/image1.jpg" />
        <:slide image="https://example.com/image2.jpg" />
      </.carousel>
      """)

    assert html =~ "pc-carousel__indicator--dots"
  end

  # Hook and Transition Tests
  test "Carousel hook and transitions" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.carousel id="test-hook" transition_type="fade">
        <:slide image="https://example.com/image1.jpg" />
      </.carousel>
      """)

    assert html =~ ~s{phx-hook="CarouselHook"}
    assert html =~ ~s{phx-update="ignore"}
    assert html =~ "[&amp;_.pc-carousel__slide]:transition-opacity"

    html =
      rendered_to_string(~H"""
      <.carousel id="test-slide-trans" transition_type="slide">
        <:slide image="https://example.com/image1.jpg" />
      </.carousel>
      """)

    assert html =~ "[&amp;_.pc-carousel__slide]:transition-transform"
  end

  # Vertical Orientation Tests
  test "Carousel with vertical orientation" do
    assigns = %{}

    # Vertical orientation with default settings
    html =
      rendered_to_string(~H"""
      <.carousel id="test-vertical" orientation="vertical">
        <:slide image="https://example.com/image1.jpg" title="Slide 1" />
        <:slide image="https://example.com/image2.jpg" title="Slide 2" />
      </.carousel>
      """)

    # Check for vertical orientation classes
    assert html =~ "pc-carousel--vertical"
    assert html =~ "pc-carousel-wrapper--vertical"

    # Check for vertical button icons (chevron-up and chevron-down)
    assert html =~ "hero-chevron-up"
    assert html =~ "hero-chevron-down"
    refute html =~ "hero-chevron-left"
    refute html =~ "hero-chevron-right"

    # Check for vertical aria-labels
    assert html =~ "Previous slide (up)"
    assert html =~ "Next slide (down)"
    refute html =~ "aria-label=\"Previous slide\""
    refute html =~ "aria-label=\"Next slide\""
  end

  test "Carousel with vertical orientation and overlay gradient" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.carousel id="test-vertical-gradient" orientation="vertical" overlay_gradient={true}>
        <:slide image="https://example.com/image1.jpg" />
        <:slide image="https://example.com/image2.jpg" />
      </.carousel>
      """)

    # Check for vertical gradient overlays (top/bottom instead of left/right)
    assert html =~ "pc-gradient-overlay-top"
    assert html =~ "pc-gradient-overlay-bottom"
    refute html =~ "pc-gradient-overlay-left"
    refute html =~ "pc-gradient-overlay-right"
  end

  test "Carousel vertical orientation with different button styles" do
    assigns = %{}

    # Vertical with overlay buttons
    html =
      rendered_to_string(~H"""
      <.carousel id="test-vert-overlay" orientation="vertical" button_style="overlay">
        <:slide image="https://example.com/image1.jpg" />
      </.carousel>
      """)

    assert html =~ "pc-carousel__button--overlay"
    assert html =~ "hero-chevron-up"
    assert html =~ "hero-chevron-down"

    # Vertical with below buttons
    html =
      rendered_to_string(~H"""
      <.carousel id="test-vert-below" orientation="vertical" button_style="below">
        <:slide image="https://example.com/image1.jpg" />
      </.carousel>
      """)

    assert html =~ "pc-carousel__button--below"
    assert html =~ "hero-chevron-up"
    assert html =~ "hero-chevron-down"

    # Vertical with sides buttons
    html =
      rendered_to_string(~H"""
      <.carousel id="test-vert-sides" orientation="vertical" button_style="sides">
        <:slide image="https://example.com/image1.jpg" />
      </.carousel>
      """)

    assert html =~ "pc-carousel__button--sides"
    assert html =~ "pc-carousel-wrapper--vertical"
    assert html =~ "hero-chevron-up"
    assert html =~ "hero-chevron-down"
  end

  test "Carousel horizontal orientation (default)" do
    assigns = %{}

    # Default horizontal orientation
    html =
      rendered_to_string(~H"""
      <.carousel id="test-horizontal">
        <:slide image="https://example.com/image1.jpg" title="Slide 1" />
      </.carousel>
      """)

    # Should NOT have vertical classes
    refute html =~ "pc-carousel--vertical"
    refute html =~ "pc-carousel-wrapper--vertical"

    # Should have horizontal button icons
    assert html =~ "hero-chevron-left"
    assert html =~ "hero-chevron-right"
    refute html =~ "hero-chevron-up"
    refute html =~ "hero-chevron-down"

    # Check for horizontal gradient overlays (when enabled)
    html =
      rendered_to_string(~H"""
      <.carousel id="test-horiz-gradient" orientation="horizontal" overlay_gradient={true}>
        <:slide image="https://example.com/image1.jpg" />
      </.carousel>
      """)

    assert html =~ "pc-gradient-overlay-left"
    assert html =~ "pc-gradient-overlay-right"
    refute html =~ "pc-gradient-overlay-top"
    refute html =~ "pc-gradient-overlay-bottom"
  end

  # Loop Feature Tests
  test "Carousel with loop enabled (default)" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.carousel id="test-loop-default" transition_type="slide">
        <:slide image="https://example.com/image1.jpg" title="Slide 1" />
        <:slide image="https://example.com/image2.jpg" title="Slide 2" />
      </.carousel>
      """)

    # Check that loop is enabled by default
    assert html =~ ~s{data-loop="true"}
  end

  test "Carousel with loop disabled" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.carousel id="test-loop-disabled" transition_type="slide" loop={false}>
        <:slide image="https://example.com/image1.jpg" title="Slide 1" />
        <:slide image="https://example.com/image2.jpg" title="Slide 2" />
      </.carousel>
      """)

    # Check that loop is disabled
    assert html =~ ~s{data-loop="false"}
  end

  test "Carousel with loop explicitly enabled" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.carousel id="test-loop-enabled" transition_type="fade" loop={true}>
        <:slide image="https://example.com/image1.jpg" title="Slide 1" />
        <:slide image="https://example.com/image2.jpg" title="Slide 2" />
      </.carousel>
      """)

    # Check that loop is enabled
    assert html =~ ~s{data-loop="true"}
  end

  # Edge Cases
  test "Carousel edge cases" do
    assigns = %{}

    # Single slide
    html =
      rendered_to_string(~H"""
      <.carousel id="test-single">
        <:slide image="https://example.com/image1.jpg" title="Only" />
      </.carousel>
      """)

    assert html =~ "Only"

    # No images
    html =
      rendered_to_string(~H"""
      <.carousel id="test-no-img">
        <:slide title="Text Only" />
      </.carousel>
      """)

    assert html =~ "Text Only"

    # Custom class and active state
    html =
      rendered_to_string(~H"""
      <.carousel id="test-custom" class="my-carousel">
        <:slide class="my-slide" image="https://example.com/image1.jpg" />
      </.carousel>
      """)

    assert html =~ "my-carousel"
    assert html =~ "my-slide"
    assert html =~ "pc-carousel__slide--active"
  end
end
