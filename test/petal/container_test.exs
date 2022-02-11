defmodule PetalComponents.ContainerTest do
  use ComponentCase
  import PetalComponents.Container

  test "full" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.container max_width="full">
      </.container>
      """)

    assert html =~ "<div class="
    assert html =~ "max-w-full"
  end

  test "xl" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.container max_width="xl">
      </.container>
      """)

    assert html =~ "85rem"
  end

  test "lg" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.container max_width="lg">
      </.container>
      """)

    assert html =~ "<div class="
    assert html =~ "max-w-7xl"
  end

  test "md" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.container max_width="md">
      </.container>
      """)

    assert html =~ "<div class="
    assert html =~ "max-w-5xl"
  end

  test "sm" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.container max_width="sm">
      </.container>
      """)

    assert html =~ "<div class="
    assert html =~ "max-w-3xl"
  end
end
