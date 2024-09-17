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
    assert find_icon(html)
    assert html =~ "pc-accordion-item"

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

  test "rest works" do
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

  test "content through :item" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.accordion>
        <:item heading="heading-a">Item A</:item>
        <:item heading="heading-b">Item B</:item>
      </.accordion>
      """)

    assert html =~ "heading-a"
    assert html =~ "Item A"
    assert html =~ "heading-b"
    assert html =~ "Item B"
  end

  test "content through :entries" do
    assigns = %{
      entries: [
        %{heading: "heading-a", content: "Item A"},
        %{heading: "heading-b", content: "Item B"}
      ]
    }

    html =
      rendered_to_string(~H"""
      <.accordion entries={@entries}>
        <:item :let={entry}><%= entry.content %></:item>
      </.accordion>
      """)

    assert html =~ "heading-a"
    assert html =~ "Item A"
    assert html =~ "heading-b"
    assert html =~ "Item B"
  end

  test "content with doubly defined heading" do
    assigns = %{
      entries: [%{heading: "nope"}]
    }

    exception =
      assert_raise ArgumentError, fn ->
        rendered_to_string(~H"""
        <.accordion entries={@entries}>
          <:item heading="nope" />
        </.accordion>
        """)
      end

    assert Exception.message(exception) =~ "either :item or :entries"
  end
end
