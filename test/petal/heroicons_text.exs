defmodule PetalComponents.HeroiconsTest do
  use ComponentCase
  import PetalComponents.Heroicons

  test "it renders heroicons solid icon and color correctly" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <Heroicons.Solid.home />
      """

      assert html =~ "<svg class="
      assert html =~ "currentColor"
    end

  test "it renders heroicons outline icon and color correctly" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <Heroicons.Outline.home />
      """

      assert html =~ "<svg class="
      assert html =~ "none"
    end
  end
