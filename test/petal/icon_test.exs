defmodule PetalComponents.IconTest do
  use ComponentCase
  import PetalComponents.Icon

  test "it renders a dynamic Heroicon" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.icon name="hero-arrow-right" class="text-gray-300" />
      """)

    assert find_icon(html, "hero-arrow-right")
    assert html =~ "text-gray-300"
  end

  test "Atom is not a valid Heroicon" do
    assigns = %{}

    assert_raise ArgumentError, ~r/:arrow_right is not a valid heroicon name/, fn ->
      rendered_to_string(~H"""
      <.icon name={:arrow_right} class="text-gray-300" />
      """)
    end
  end

  test "Invalid name with 'hero-' prefix causes exception" do
    assigns = %{}

    assert_raise ArgumentError, ~r/"hero-does-not-exist" is not a valid heroicon name/, fn ->
      rendered_to_string(~H"""
      <.icon name="hero-does-not-exist" class="text-gray-300" />
      """)
    end
  end

  test "Name without 'hero-' prefix causes exception" do
    assigns = %{}

    assert_raise ArgumentError, ~r/"completely-made-up" is not a valid heroicon name/, fn ->
      rendered_to_string(~H"""
      <.icon name="completely-made-up" class="text-gray-300" />
      """)
    end
  end
end
