defmodule PetalComponents.LoadingTest do
  use ComponentCase
  alias PetalComponents.Loading

  test "spinner" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <Loading.spinner show={true} />
      """
    )
    assert html =~ "<svg"
    refute html =~ "hidden"

    html = rendered_to_string(
      ~H"""
      <Loading.spinner show={true} size="sm" />
      """
    )
    assert html =~ "h-5"

    html = rendered_to_string(
      ~H"""
      <Loading.spinner show={true} class="some_class" />
      """
    )
    assert html =~ "some_class"
  end

  test "spinner defaults to hidden" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <Loading.spinner />
      """
    )
    assert html =~ "<svg"
    assert html =~ "hidden"
  end
end
