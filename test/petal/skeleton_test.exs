defmodule PetalComponents.SkeletonTest do
  use ComponentCase
  import PetalComponents.Skeleton

  test "renders skeleton without specifying kind" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.skeleton />
      """)

    assert html =~ "data-skeleton=\"default\""
    assert html =~ "Loading"
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
