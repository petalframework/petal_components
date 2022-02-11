defmodule PetalComponents.LoadingTest do
  use ComponentCase
  import PetalComponents.Loading

  test "spinner" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.spinner show={true} />
      """)

    assert html =~ "<svg"
    refute html =~ "hidden"

    html =
      rendered_to_string(~H"""
      <.spinner show={true} size="sm" />
      """)

    assert html =~ "h-5"

    html =
      rendered_to_string(~H"""
      <.spinner show={true} class="some_class" />
      """)

    assert html =~ "some_class"
  end

  test "spinner defaults to visible" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.spinner />
      """)

    assert html =~ "<svg"
    refute html =~ "hidden"
  end
end
