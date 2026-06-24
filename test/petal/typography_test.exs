defmodule PetalComponents.TypographyTest do
  use ComponentCase
  import PetalComponents.Typography

  test ".h1" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.h1>Heading 1</.h1>
      """)

    assert html =~ "Heading 1"
    assert html =~ "<h1 class="
    assert html =~ "pc-h1"
  end

  test ".h2" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.h2>Heading 2</.h2>
      """)

    assert html =~ "Heading 2"
    assert html =~ "<h2 class="
    assert html =~ "pc-h2"
  end

  test ".h3" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.h3>Heading 3</.h3>
      """)

    assert html =~ "Heading 3"
    assert html =~ "<h3 class="
    assert html =~ "pc-h3"
  end

  test ".h4" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.h4>Heading 4</.h4>
      """)

    assert html =~ "Heading 4"
    assert html =~ "<h4 class="
    assert html =~ "pc-h4"
  end

  test ".h5" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.h5>Heading 5</.h5>
      """)

    assert html =~ "Heading 5"
    assert html =~ "<h5 class="
    assert html =~ "pc-h5"
  end

  test ".h1 extra assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.h1 color_class="text-blue-500" no_margin x-text="blah">Heading</.h1>
      """)

    assert html =~ "blah"
    assert html =~ "x-text"
    refute html =~ "no-margin"
    refute html =~ "color-class"
  end

  test ".p" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.p>Paragraph</.p>
      """)

    assert html =~ "Paragraph"
    assert html =~ "<p class="
    assert html =~ "pc-text"
  end

  test ".p taking extra assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.p x-text="input">Paragraph</.p>
      """)

    assert html =~ "Paragraph"
    assert html =~ "<p class="
    assert html =~ "pc-text"
    assert html =~ "x-text="
    assert html =~ "input"
  end

  test ".prose" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.prose class="md:prose-lg" random-attribute="lol">
        <p>A paragraph</p>
      </.prose>
      """)

    assert html =~ "A paragraph"
    assert html =~ "<p>"
    assert html =~ "md:prose-lg"
    assert html =~ "dark"
    assert html =~ "random-attribute"
  end

  test ".ul" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.ul class="mb-5" random-attribute="lol">
        <li>Item 1</li>
        <li>Item 2</li>
      </.ul>
      """)

    assert html =~ "<ul"
    assert html =~ "Item 1"
    assert html =~ "mb-5"
    assert html =~ "pc-text"
    assert html =~ "random-attribute"
  end

  test ".ol" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.ol class="mb-5" random-attribute="lol">
        <li>Item 1</li>
        <li>Item 2</li>
      </.ol>
      """)

    assert html =~ "<ol"
    assert html =~ "Item 1"
    assert html =~ "mb-5"
    assert html =~ "pc-text"
    assert html =~ "random-attribute"
  end

  test ".lead" do
    assigns = %{}
    html = rendered_to_string(~H"<.lead>Intro</.lead>")
    assert html =~ "Intro"
    assert html =~ "pc-lead"
    assert html =~ "<p class="
  end

  test ".blockquote" do
    assigns = %{}
    html = rendered_to_string(~H"<.blockquote>A quote</.blockquote>")
    assert html =~ "A quote"
    assert html =~ "pc-blockquote"
    assert html =~ "<blockquote"
  end

  test ".inline_code" do
    assigns = %{}
    html = rendered_to_string(~H"<.inline_code>mix deps.get</.inline_code>")
    assert html =~ "mix deps.get"
    assert html =~ "pc-inline-code"
    assert html =~ "<code"
  end

  test ".text_muted / .text_large / .text_small" do
    assigns = %{}
    assert rendered_to_string(~H"<.text_muted>m</.text_muted>") =~ "pc-text-muted"
    assert rendered_to_string(~H"<.text_large>l</.text_large>") =~ "pc-text-large"

    small = rendered_to_string(~H"<.text_small>s</.text_small>")
    assert small =~ "pc-text-small"
    assert small =~ "<small"
  end

  test ".hr" do
    assigns = %{}
    html = rendered_to_string(~H|<.hr class="mt-10" />|)
    assert html =~ "<hr"
    assert html =~ "pc-hr"
    assert html =~ "mt-10"
  end
end
