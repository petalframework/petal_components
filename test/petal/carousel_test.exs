defmodule PetalComponents.CarouselTest do
  use ComponentCase
  import PetalComponents.Carousel

  describe "carousel/1" do
    test "renders a hook-bound region with slides and aria wiring" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.carousel id="c">
          <:slide title="One" />
          <:slide title="Two" />
          <:slide title="Three" />
        </.carousel>
        """)

      assert html =~ ~s(phx-hook="PetalCarousel")
      assert html =~ ~s(aria-roledescription="carousel")
      assert html =~ ~s(aria-label="Slide 1 of 3")
      assert html =~ ~s(aria-label="Slide 3 of 3")
      # first slide active by default
      assert html =~ "pc-carousel__slide--active"
      # live region for screen reader announcements
      assert html =~ ~s(aria-live="polite")
    end

    test "overlay buttons render by default; none hides them" do
      assigns = %{}

      with_buttons =
        rendered_to_string(~H"""
        <.carousel id="c">
          <:slide title="One" />
        </.carousel>
        """)

      without =
        rendered_to_string(~H"""
        <.carousel id="c" button_style="none">
          <:slide title="One" />
        </.carousel>
        """)

      assert with_buttons =~ "pc-carousel__button--overlay"
      assert with_buttons =~ ~s(aria-label="Previous slide")
      refute without =~ "pc-carousel__button"
    end

    test "outside placement flanks the frame along the travel axis" do
      assigns = %{}

      outside =
        rendered_to_string(~H"""
        <.carousel id="c" button_style="outside">
          <:slide title="One" />
        </.carousel>
        """)

      assert outside =~ "pc-carousel-wrapper--outside"
      assert outside =~ "pc-carousel__button--outside"
    end

    test "indicators are opt-in with bar and dot styles" do
      assigns = %{}

      none =
        rendered_to_string(~H"""
        <.carousel id="c">
          <:slide title="One" />
        </.carousel>
        """)

      dots =
        rendered_to_string(~H"""
        <.carousel id="c" indicator indicator_style="dots">
          <:slide title="One" />
          <:slide title="Two" />
        </.carousel>
        """)

      refute none =~ "pc-carousel__indicators"
      assert dots =~ "pc-carousel__indicator--dots"
    end

    test "behaviour attrs travel to the hook as data attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.carousel
          id="c"
          transition_type="slide"
          autoplay
          autoplay_interval={3500}
          loop={false}
          slides_per_view={3}
        >
          <:slide title="One" />
        </.carousel>
        """)

      assert html =~ ~s(data-transition-type="slide")
      assert html =~ ~s(data-autoplay="true")
      assert html =~ ~s(data-autoplay-interval="3500")
      assert html =~ ~s(data-loop="false")
      assert html =~ ~s(data-slides-per-view="3")
    end

    test "vertical orientation flips classes and chevrons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.carousel id="c" orientation="vertical">
          <:slide title="One" />
        </.carousel>
        """)

      assert html =~ "pc-carousel--vertical"
      assert has_icon?(html, "hero-chevron-up")
      assert html =~ ~s|aria-label="Previous slide (up)"|
    end

    test "thumbnails render a synced strip with image and numbered fallbacks" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.carousel id="c" thumbnails>
          <:slide image="/a.jpg" title="One" />
          <:slide title="Two" />
        </.carousel>
        """)

      assert html =~ "pc-carousel__thumbs"
      assert html =~ ~s(data-thumb-index="0")
      assert html =~ ~s(data-thumb-index="1")
      assert html =~ ~s(aria-label="Go to slide 2")
      # image slide gets its image; imageless slide gets a numbered chip
      assert html =~ ~s(src="/a.jpg")
      assert html =~ "pc-carousel__thumb-fallback"
      # first thumb active on initial render
      assert html =~ "pc-carousel__thumb--active"
    end

    test "slide radius rides the theme token by default, none opts out" do
      assigns = %{}

      default =
        rendered_to_string(~H"""
        <.carousel id="c">
          <:slide title="One" />
        </.carousel>
        """)

      square =
        rendered_to_string(~H"""
        <.carousel id="c" rounded="none">
          <:slide title="One" />
        </.carousel>
        """)

      pinned =
        rendered_to_string(~H"""
        <.carousel id="c" rounded="xl">
          <:slide title="One" />
        </.carousel>
        """)

      assert default =~ "pc-carousel__slide-content--radius"
      refute square =~ "pc-carousel__slide-content--radius"
      assert pinned =~ "rounded-xl"
      refute pinned =~ "pc-carousel__slide-content--radius"
    end

    test "clickable slides render a covering link with an indicator" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.carousel id="c">
          <:slide title="One" href="https://example.com" />
        </.carousel>
        """)

      assert html =~ "pc-carousel__link"
      assert html =~ ~s(target="_blank")
      assert has_icon?(html, "hero-arrow-top-right-on-square")
    end
  end
end
