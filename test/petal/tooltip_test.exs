defmodule PetalComponents.TooltipTest do
  use ComponentCase
  import PetalComponents.Tooltip

  test "renders label content with tooltip role and default top placement" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tooltip label="Add to library">
        <button>Trigger</button>
      </.tooltip>
      """)

    assert html =~ "Trigger"
    assert html =~ "Add to library"
    assert html =~ ~s(role="tooltip")
    assert html =~ "pc-tooltip"
    assert html =~ "pc-tooltip__content--top"
    assert html =~ "pc-tooltip__arrow--top"
  end

  test "supports every placement" do
    assigns = %{}

    for placement <- ["top", "bottom", "left", "right"] do
      assigns = Map.put(assigns, :placement, placement)

      html =
        rendered_to_string(~H"""
        <.tooltip label="Tip" placement={@placement}>
          <button>Trigger</button>
        </.tooltip>
        """)

      assert html =~ "pc-tooltip__content--#{placement}"
    end
  end

  test "renders rich content via the :content slot, overriding label" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tooltip label="ignored">
        <:content>
          Saved <span class="font-semibold">2 minutes ago</span>
        </:content>
        <button>Trigger</button>
      </.tooltip>
      """)

    assert html =~ "2 minutes ago"
    refute html =~ "ignored"
  end

  test "disabled renders trigger without any tooltip" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tooltip label="Tip" disabled>
        <button>Trigger</button>
      </.tooltip>
      """)

    assert html =~ "Trigger"
    refute html =~ ~s(role="tooltip")
    refute html =~ "Tip"
  end

  test "arrow can be turned off" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tooltip label="Tip" arrow={false}>
        <button>Trigger</button>
      </.tooltip>
      """)

    refute html =~ "pc-tooltip__arrow"
  end

  test "no tooltip is rendered without label or content" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tooltip>
        <button>Trigger</button>
      </.tooltip>
      """)

    refute html =~ ~s(role="tooltip")
  end

  test "no tooltip is rendered for an empty label" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tooltip label="">
        <button>Trigger</button>
      </.tooltip>
      """)

    refute html =~ ~s(role="tooltip")
  end

  test "passes through custom classes and global attrs" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tooltip label="Tip" class="wrapper-custom" content_class="bubble-custom" data-test="x">
        <button>Trigger</button>
      </.tooltip>
      """)

    assert html =~ "wrapper-custom"
    assert html =~ "bubble-custom"
    assert html =~ ~s(data-test="x")
  end
end
