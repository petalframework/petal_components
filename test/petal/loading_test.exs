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

    assert html =~ "pc-spinner--sm"

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

  test "should include additional assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.spinner custom-attrs="123" />
      """)

    assert html =~ ~s{custom-attrs="123"}
  end
end
