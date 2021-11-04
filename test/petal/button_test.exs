defmodule PetalComponents.ButtonTest do
  use ComponentCase
  alias PetalComponents.Button

  test "Button.button" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <Button.button label="Press me" phx-click="click_event" />
      """
    )

    assert html =~ "Press me"
  end

  test "Button.a" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <Button.a label="Press me" href="/" phx-click="Press me" />
      """
    )
    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "phx-click"
  end

  test "Button.patch" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <Button.patch label="Press me" href="/" phx-click="click_event" />
      """
    )
    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "phx-click"
  end

  test "Button.redirect" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <Button.redirect label="Press me" href="/" phx-click="click_event" />
      """
    )
    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "phx-click"
  end

  test "Button.button with inner_block" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <Button.button phx-click="click_event">Press me</Button.button>
      """
    )
    assert html =~ "<button"
    assert html =~ "Press me"
  end
end
