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
    assert html =~ "shadow-lg"
  end

  test "Outline card" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card variant="outline" >
        <.card_content category="Article" heading="Enhance your Phoenix development">
          <div class="mt-4 font-light text-gray-500 text-md">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eget leo interdum, feugiat ligula eu, facilisis massa. Nunc sollicitudin massa a elit laoreet.
          </div>
        </.card_content>
      </.card>
      """)

    assert html =~ "Enhance"
    assert html =~ "Article"
    assert html =~ "border-gray-300"
  end

  test "Card with media no url" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card variant="outline" >
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
    assert html =~ "border-gray-300"
    assert html =~ "bg-gray-300"
  end

  test "Card with media and url" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card variant="outline" >
        <.card_media class="h-48" src="https://images.unsplash.com/photo-1551434678-e076c223a692?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2340&q=80" />
        <.card_content category="Article" heading="Enhance your Phoenix development">
          <div class="mt-4 font-light text-gray-500 text-md">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eget leo interdum, feugiat ligula eu, facilisis massa. Nunc sollicitudin massa a elit laoreet.
          </div>
        </.card_content>
      </.card>
      """)

    assert html =~ "Enhance"
    assert html =~ "Article"
    assert html =~ "border-gray-300"
    assert html =~ "<img"
  end

  test "dark mode" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card variant="outline" >
        <.card_media class="h-48" src="https://images.unsplash.com/photo-1551434678-e076c223a692?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2340&q=80" />
        <.card_content category="Article" heading="Enhance your Phoenix development">
          <div class="mt-4 font-light text-gray-500 text-md">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eget leo interdum, feugiat ligula eu, facilisis massa. Nunc sollicitudin massa a elit laoreet.
          </div>
        </.card_content>
      </.card>
      """)

    assert html =~ "Enhance"
    assert html =~ "Article"
    assert html =~ "border-gray-300"
    assert html =~ "<img"
    assert html =~ "dark:"
  end
end
