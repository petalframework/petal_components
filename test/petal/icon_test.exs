defmodule PetalComponents.IconTest do
  use ComponentCase
  import PetalComponents.Icon

  test "it renders a dynamic Heroicon" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.icon name={:arrow_right} class="text-gray-300"/>
      """)

    assert html =~ "<svg"
    assert html =~ "text-gray-300"
  end
end
