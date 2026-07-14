defmodule PetalComponents.AuroraTest do
  use ComponentCase
  import PetalComponents.Aurora

  test "renders backdrop, lights and content wrapper with defaults" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.aurora>
        <h1>Hello</h1>
      </.aurora>
      """)

    assert html =~ "pc-aurora"
    assert html =~ "pc-aurora__backdrop"
    assert html =~ ~s(aria-hidden="true")
    assert html =~ "data-pc-aurora"
    assert html =~ ~s(phx-hook="PetalAurora")
    assert html =~ "pc-aurora__content"
    assert html =~ "<h1>Hello</h1>"
    # gradient built from the default palette
    assert html =~ "repeating-linear-gradient(100deg, #3b82f6 10%, #a5b4fc 15%"
    assert html =~ "--pc-aurora-speed: 60s;"
  end

  test "colors builds the gradient stops in order" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.aurora colors={["red", "green", "blue"]} speed="20s" opacity="0.8" />
      """)

    assert html =~ "repeating-linear-gradient(100deg, red 10%, green 15%, blue 20%)"
    assert html =~ "--pc-aurora-speed: 20s;"
    assert html =~ "--pc-aurora-opacity: 0.8;"
  end

  test "invert forces ride on modifiers, auto adds none" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.aurora invert="always" />
      """)

    assert html =~ "pc-aurora--invert"

    html =
      rendered_to_string(~H"""
      <.aurora invert="none" />
      """)

    assert html =~ "pc-aurora--no-invert"

    html =
      rendered_to_string(~H"""
      <.aurora />
      """)

    refute html =~ "pc-aurora--invert"
    refute html =~ "pc-aurora--no-invert"
  end
end
