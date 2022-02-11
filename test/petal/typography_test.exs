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
end
