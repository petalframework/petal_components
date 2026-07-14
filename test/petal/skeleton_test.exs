defmodule PetalComponents.SkeletonTest do
  use ComponentCase
  import PetalComponents.Skeleton

  test "bare skeleton is the composable brick" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.skeleton class="h-4 w-48" />
      """)

    assert html =~ "pc-skeleton"
    assert html =~ "pc-skeleton--block"
    assert html =~ ~s(aria-hidden="true")
    assert html =~ "h-4 w-48"
  end

  test "brick variants and explicit animation" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <div>
        <.skeleton variant="circle" class="size-12" />
        <.skeleton variant="text" animation="shimmer" />
        <.skeleton animation="none" />
      </div>
      """)

    assert html =~ "pc-skeleton--circle"
    assert html =~ "pc-skeleton--text"
    assert html =~ "pc-skeleton--anim-shimmer"
    assert html =~ "pc-skeleton--anim-none"
  end

  test "skeleton_text renders varied deterministic lines" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.skeleton_text lines={4} />
      """)

    assert 4 == html |> String.split("pc-skeleton--text") |> length() |> Kernel.-(1)
    assert html =~ "width: 100%"
    # the last line trails off
    assert html =~ "width: 60%"
  end

  test "skeleton_group announces loading and cascades animation" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.skeleton_group label="Loading posts" animation="shimmer">
        <.skeleton variant="text" />
      </.skeleton_group>
      """)

    assert html =~ ~s(role="status")
    assert html =~ ~s(aria-busy="true")
    assert html =~ "pc-skeleton-group--anim-shimmer"
    assert html =~ "Loading posts"
  end

  test "renders skeleton specifying kind as default" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.skeleton kind={:default} />
      """)

    assert html =~ "data-skeleton=\"default\""
    assert html =~ "Loading"
  end

  test "renders skeleton specifying kind as image" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.skeleton kind={:image} />
      """)

    assert html =~ "data-skeleton=\"image\""
    assert html =~ "Loading"
  end

  test "renders skeleton specifying kind as video" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.skeleton kind={:video} />
      """)

    assert html =~ "data-skeleton=\"video\""
    assert html =~ "Loading"
  end

  test "renders skeleton specifying kind as text" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.skeleton kind={:text} />
      """)

    assert html =~ "data-skeleton=\"text\""
    assert html =~ "Loading"
  end

  test "renders skeleton specifying kind as card" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.skeleton kind={:card} />
      """)

    assert html =~ "data-skeleton=\"card\""
    assert html =~ "Loading"
  end

  test "renders skeleton specifying kind as widget" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.skeleton kind={:widget} />
      """)

    assert html =~ "data-skeleton=\"widget\""
    assert html =~ "Loading"
  end

  test "renders skeleton specifying kind as list" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.skeleton kind={:list} />
      """)

    assert html =~ "data-skeleton=\"list\""
    assert html =~ "Loading"
  end

  test "renders skeleton specifying kind as testimonial" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.skeleton kind={:testimonial} />
      """)

    assert html =~ "data-skeleton=\"testimonial\""
    assert html =~ "Loading"
  end
end
