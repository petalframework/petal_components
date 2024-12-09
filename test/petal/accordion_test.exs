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
      <.accordion variant="ghost">
        <:item heading="Accordion">
          Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam quis. Ut enim ad minim veniam quis. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
        </:item>
      </.accordion>
      """)

    assert html =~ "pc-accordion--ghost"

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
        <:item :let={entry}>{entry.content}</:item>
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

  test "accordion with open_index" do
    assigns = %{container_id: "test_accordion"}

    html =
      rendered_to_string(~H"""
      <.accordion container_id={@container_id} open_index={1}>
        <:item heading="Accordion 1">
          Content 1
        </:item>
        <:item heading="Accordion 2">
          Content 2
        </:item>
        <:item heading="Accordion 3">
          Content 3
        </:item>
      </.accordion>
      """)

    # Extract the HTML for each accordion item
    items_html =
      String.split(html, ~r{<div[^>]+data-i="}, trim: true)
      |> Enum.filter(fn x ->
        String.starts_with?(x, "0") or String.starts_with?(x, "1") or String.starts_with?(x, "2")
      end)
      |> Enum.map(fn x -> "<div data-i=\"" <> x end)

    for item_html <- items_html do
      # Extract the index from data-i attribute
      [_, idx_str | _] = Regex.run(~r{data-i="(\d+)"}, item_html)
      idx = String.to_integer(idx_str)

      if idx == 1 do
        # For the open item, assert that it has 'rotate-180' in the chevron class
        assert Regex.match?(
                 ~r{<span[^>]*class="[^"]*pc-accordion-item__chevron[^"]*rotate-180[^"]*"}s,
                 item_html
               )

        # Also assert data-open="true"
        assert item_html =~ ~s{data-open="true"}
      else
        # For closed items, refute that they have 'rotate-180' in the chevron class
        refute Regex.match?(
                 ~r{<span[^>]*class="[^"]*pc-accordion-item__chevron[^"]*rotate-180[^"]*"}s,
                 item_html
               )

        # Also assert data-open="false"
        assert item_html =~ ~s{data-open="false"}
      end
    end

    # Additional assertions for the content panels
    assert html =~ ~s{id="acc-content-panel-test_accordion-1"}
    assert Regex.match?(~r{id="acc-content-panel-test_accordion-1".*?x-show="expanded"}s, html)
  end
end
