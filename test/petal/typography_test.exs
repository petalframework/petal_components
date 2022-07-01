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
    assert html =~ "text-4xl"
  end

  test ".h2" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.h2>Heading 2</.h2>
      """)

    assert html =~ "Heading 2"
    assert html =~ "<h2 class="
    assert html =~ "text-2xl"
  end

  test ".h3" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.h3>Heading 3</.h3>
      """)

    assert html =~ "Heading 3"
    assert html =~ "<h3 class="
    assert html =~ "text-xl"
  end

  test ".h4" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.h4>Heading 4</.h4>
      """)

    assert html =~ "Heading 4"
    assert html =~ "<h4 class="
    assert html =~ "text-lg font-bold"
  end

  test ".h5" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.h5>Heading 5</.h5>
      """)

    assert html =~ "Heading 5"
    assert html =~ "<h5 class="
    assert html =~ "text-lg font-medium"
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
    assert html =~ "dark:text-gray-400"
  end

  test ".p taking extra assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.p x-text="input">Paragraph</.p>
      """)

    assert html =~ "Paragraph"
    assert html =~ "<p class="
    assert html =~ "dark:text-gray-400"
    assert html =~ "x-text="
    assert html =~ "input"
  end

  test ".prose" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.prose class="md:prose-lg" random-attribute="lol"><p>A paragraph</p></.prose>
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
    assert html =~ "dark"
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
    assert html =~ "dark"
    assert html =~ "random-attribute"
  end
end
