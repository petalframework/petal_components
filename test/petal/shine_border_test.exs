defmodule PetalComponents.ShineBorderTest do
  @moduledoc """
  Tests for PetalComponents.ShineBorder - the ambient border shimmer.
  """

  use ComponentCase
  import PetalComponents.ShineBorder

  test "renders the shine layer and default variables" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.shine_border>Content</.shine_border>
      """)

    assert html =~ "pc-shine-border"
    assert html =~ "pc-shine-border__shine"
    assert html =~ ~s(aria-hidden="true")
    assert html =~ "--pc-shine-colors: #a1a1aa"
    assert html =~ "--pc-shine-duration: 14s"
    assert html =~ "Content"
  end

  test "single custom colour" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.shine_border shine_color="#f43f5e" duration="8s">Content</.shine_border>
      """)

    assert html =~ "--pc-shine-colors: #f43f5e"
    assert html =~ "--pc-shine-duration: 8s"
  end

  test "a list of colours is joined for the gradient" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.shine_border shine_color={["#f43f5e", "#8b5cf6", "#3b82f6"]}>Content</.shine_border>
      """)

    assert html =~ "--pc-shine-colors: #f43f5e, #8b5cf6, #3b82f6"
  end

  test "border_radius attr overrides the theme default" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.shine_border border_radius="2rem">Content</.shine_border>
      """)

    assert html =~ "--pc-shine-radius: 2rem"
  end
end
