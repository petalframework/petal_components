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
end
