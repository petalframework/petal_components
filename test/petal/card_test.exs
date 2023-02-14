defmodule PetalComponents.CardTest do
  use ComponentCase
  import PetalComponents.Card

  test "Basic card" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card>
        <.card_content category="Article" heading="Enhance your Phoenix development">
          <div class="mt-4 font-light text-gray-500 text-md">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eget leo interdum, feugiat ligula eu, facilisis massa. Nunc sollicitudin massa a elit laoreet.
          </div>
        </.card_content>
      </.card>
      """)

    assert html =~ "Enhance"
    assert html =~ "Article"
    assert html =~ "pc-card--basic"
  end

  test "Outline card" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card variant="outline">
        <.card_content category="Article" heading="Enhance your Phoenix development">
          <div class="mt-4 font-light text-gray-500 text-md">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eget leo interdum, feugiat ligula eu, facilisis massa. Nunc sollicitudin massa a elit laoreet.
          </div>
        </.card_content>
      </.card>
      """)

    assert html =~ "Enhance"
    assert html =~ "Article"
    assert html =~ "pc-card--outline"
  end

  test "Card with media no url" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card variant="outline">
        <.card_media class="h-48" />
        <.card_content category="Article" heading="Enhance your Phoenix development">
          <div class="mt-4 font-light text-gray-500 text-md">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eget leo interdum, feugiat ligula eu, facilisis massa. Nunc sollicitudin massa a elit laoreet.
          </div>
        </.card_content>
      </.card>
      """)

    assert html =~ "Enhance"
    assert html =~ "Article"
    assert html =~ "pc-card--outline"
    assert html =~ "pc-card__image-placeholder"
  end

  test "Card with media and url" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card variant="outline">
        <.card_media
          class="h-48"
          src="https://images.unsplash.com/photo-1551434678-e076c223a692?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2340&q=80"
        />
        <.card_content category="Article" heading="Enhance your Phoenix development">
          <div class="mt-4 font-light text-gray-500 text-md">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eget leo interdum, feugiat ligula eu, facilisis massa. Nunc sollicitudin massa a elit laoreet.
          </div>
        </.card_content>
      </.card>
      """)

    assert html =~ "Enhance"
    assert html =~ "Article"
    assert html =~ "pc-card--outline"
    assert html =~ "<img"
  end

  test "dark mode" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card variant="outline">
        <.card_media
          class="h-48"
          src="https://images.unsplash.com/photo-1551434678-e076c223a692?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2340&q=80"
        />
        <.card_content category="Article" heading="Enhance your Phoenix development">
          <div class="mt-4 font-light text-gray-500 text-md">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eget leo interdum, feugiat ligula eu, facilisis massa. Nunc sollicitudin massa a elit laoreet.
          </div>
        </.card_content>
      </.card>
      """)

    assert html =~ "Enhance"
    assert html =~ "Article"
    assert html =~ "pc-card--outline"
    assert html =~ "<img"
  end

  test "should include additional assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card variant="outline" custom-attr="1">
        <.card_media
          custom-attr="2"
          class="h-48"
          src="https://images.unsplash.com/photo-1551434678-e076c223a692?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2340&q=80"
        />
        <.card_media custom-attr="3" class="h-48" />
        <.card_content custom-attr="4" category="Article" heading="Enhance your Phoenix development">
          <div class="mt-4 font-light text-gray-500 text-md">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eget leo interdum, feugiat ligula eu, facilisis massa. Nunc sollicitudin massa a elit laoreet.
          </div>
        </.card_content>
        <.card_footer custom-attr="5">FOOTER</.card_footer>
      </.card>
      """)

    for i <- 1..5 do
      assert html =~ ~s{custom-attr="#{i}"}
    end
  end
end
