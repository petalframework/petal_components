defmodule PetalComponents.SpotlightCardTest do
  use ComponentCase
  import PetalComponents.SpotlightCard

  describe "basic rendering" do
    test "renders the card with glow layer, hook and content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.spotlight_card id="card">
          <div class="p-6">Feature</div>
        </.spotlight_card>
        """)

      assert html =~ "pc-spotlight-card"
      assert html =~ "pc-spotlight-card__glow"
      assert html =~ "pc-spotlight-card__content"
      assert html =~ ~s(phx-hook="PetalSpotlight")
      assert html =~ ~s(id="card")
      assert html =~ "Feature"
      assert html =~ "--pc-spotlight-color: rgb(120 119 198 / 0.18)"
      assert html =~ "--pc-spotlight-size: 350px"
    end
  end

  describe "customization" do
    test "applies custom spotlight color and size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.spotlight_card id="card" spotlight_color="rgb(56 189 248 / 0.2)" spotlight_size="500px">
          Content
        </.spotlight_card>
        """)

      assert html =~ "--pc-spotlight-color: rgb(56 189 248 / 0.2)"
      assert html =~ "--pc-spotlight-size: 500px"
    end

    test "applies custom classes and rest attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.spotlight_card id="card" class="custom-class" data-test="spotlight">Content</.spotlight_card>
        """)

      assert html =~ "custom-class"
      assert html =~ ~s(data-test="spotlight")
    end
  end
end
