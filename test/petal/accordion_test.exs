defmodule PetalComponents.AccordionTest do
  use ComponentCase
  import PetalComponents.Accordion

  test "accordion" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.accordion>
        <:item heading="Accordion">
          Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam quis. Ut enim ad minim veniam quis. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
        </:item>
      </.accordion>
      """)

    assert html =~ "x-data"
    assert html =~ "x-show"
    assert html =~ "<svg class="
    assert html =~ "dark:"

    # Test js_lib option
    html =
      rendered_to_string(~H"""
      <.accordion js_lib="live_view_js">
        <:item heading="Accordion">
          Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam quis. Ut enim ad minim veniam quis. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
        </:item>
      </.accordion>
      """)

    refute html =~ "x-data"
    assert html =~ "phx-click"
  end

  test "extra_assigns works" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.accordion custom-attrs="123" phx-click="some_event">
        <:item heading="Accordion">
          Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam quis. Ut enim ad minim veniam quis. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
        </:item>
      </.accordion>
      """)

    assert html =~ ~s{custom-attrs="123"}
    assert html =~ "phx-click"
    assert html =~ "some_event"
  end
end
