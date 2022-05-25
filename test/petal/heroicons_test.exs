defmodule PetalComponents.HeroiconsTest do
  use ComponentCase
  alias PetalComponents.Heroicons

  test "it renders heroicons solid icon and color correctly" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Heroicons.Solid.home />
      """)

    assert html =~ "<svg class="
    assert html =~ "currentColor"
  end

  test "it renders heroicons solid icon and color correctly via render component" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Heroicons.Solid.render icon="home" />
      """)

    assert html =~ "<svg class="
    assert html =~ "currentColor"

    html =
      rendered_to_string(~H"""
      <Heroicons.Solid.render icon={:home} />
      """)

    assert html =~ "<svg class="
    assert html =~ "currentColor"
  end

  test "it renders heroicons outline icon and color correctly" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Heroicons.Outline.home />
      """)

    assert html =~ "<svg class="
    assert html =~ "none"
  end

  test "it renders heroicons outline icon and color correctly via render component" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Heroicons.Outline.render icon="home" />
      """)

    assert html =~ "<svg class="
    assert html =~ "none"

    html =
      rendered_to_string(~H"""
      <Heroicons.Outline.render icon={:home} />
      """)

    assert html =~ "<svg class="
    assert html =~ "none"
  end

  test "it forwards extra params to the underlying svg element" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Heroicons.Outline.home blah="xxx" />
      """)

    assert html =~ "blah"
    assert html =~ "xxx"
  end
end
