defmodule PetalComponents.BadgeTest do
  use ComponentCase
  import PetalComponents.Badge

  test "it renders colors and label correctly" do
    assigns = %{}

    html = rendered_to_string(
      ~H"""
      <.badge color="primary" label="Primary" />
      """
    )
    assert html =~ "Primary"
    assert html =~ "text-primary"

    html = rendered_to_string(
      ~H"""
      <.badge color="secondary" label="Secondary" />
      """
    )
    assert html =~ "Secondary"
    assert html =~ "text-secondary"

    html = rendered_to_string(
      ~H"""
      <.badge color="white" label="White" />
      """
    )
    assert html =~ "White"
    assert html =~ "text-black"

    html = rendered_to_string(
      ~H"""
      <.badge color="black" label="Black" />
      """
    )
    assert html =~ "Black"
    assert html =~ "text-white"

    html = rendered_to_string(
      ~H"""
      <.badge color="green" label="Green" />
      """
    )
    assert html =~ "Green"
    assert html =~ "text-green"

    html = rendered_to_string(
      ~H"""
      <.badge color="red" label="Red" />
      """
    )
    assert html =~ "Red"
    assert html =~ "text-red"

    html = rendered_to_string(
      ~H"""
      <.badge color="blue" label="Blue" />
      """
    )
    assert html =~ "Blue"
    assert html =~ "text-blue"

    html = rendered_to_string(
      ~H"""
      <.badge color="gray" label="Gray" />
      """
    )
    assert html =~ "Gray"
    assert html =~ "text-gray"

    html = rendered_to_string(
      ~H"""
      <.badge color="gray-light" label="Light Gray" />
      """
    )
    assert html =~ "Light Gray"
    assert html =~ "text-gray"

    html = rendered_to_string(
      ~H"""
      <.badge color="pink" label="Pink" />
      """
    )
    assert html =~ "Pink"
    assert html =~ "text-pink"

    html = rendered_to_string(
      ~H"""
      <.badge color="purple" label="Purple" />
      """
    )
    assert html =~ "Purple"
    assert html =~ "text-purple"

    html = rendered_to_string(
      ~H"""
      <.badge color="orange" label="Orange" />
      """
    )
    assert html =~ "Orange"
    assert html =~ "text-yellow"

    html = rendered_to_string(
      ~H"""
      <.badge color="yellow" label="Yellow" />
      """
    )
    assert html =~ "Yellow"
    assert html =~ "text-yellow"
  end
end
