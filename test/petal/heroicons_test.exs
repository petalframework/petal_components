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
      <Heroicons.Solid.render icon="document_text" />
      """)

    assert html =~ "<svg class="
    assert html =~ "currentColor"

    also_html =
      rendered_to_string(~H"""
      <Heroicons.Solid.render icon={:document_text} />
      """)

    assert also_html == html
    assert also_html =~ "<svg class="
    assert also_html =~ "currentColor"
  end

  test "it renders heroicons solid with dash" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Heroicons.Solid.render icon="document-text" />
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
      <Heroicons.Outline.render icon="document_text" />
      """)

    assert html =~ "<svg class="
    assert html =~ "none"

    also_html =
      rendered_to_string(~H"""
      <Heroicons.Outline.render icon={:document_text} />
      """)

    assert also_html == html
    assert also_html =~ "<svg class="
    assert also_html =~ "none"
  end

  test "it renders heroicons outline with dash" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Heroicons.Outline.render icon="document-text" />
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

  test "it includes title element in outline icons when specified" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Heroicons.Outline.home title="foo" />
      """)

    assert html =~ "<title>foo</title>"
  end

  test "it includes title element in solid icons when specified" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Heroicons.Solid.home title="foo" />
      """)

    assert html =~ "<title>foo</title>"
  end
end
