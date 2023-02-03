defmodule PetalComponents.ContainerTest do
  use ComponentCase
  import PetalComponents.Container

  test "full" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.container max_width="full"></.container>
      """)

    assert html =~ "<div class="
    assert html =~ "pc-container--full"
  end

  test "xl" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.container max_width="xl"></.container>
      """)

    assert html =~ "pc-container--xl"
  end

  test "lg" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.container max_width="lg"></.container>
      """)

    assert html =~ "<div class="
    assert html =~ "pc-container--lg"
  end

  test "md" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.container max_width="md"></.container>
      """)

    assert html =~ "<div class="
    assert html =~ "pc-container--md"
  end

  test "sm" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.container max_width="sm"></.container>
      """)

    assert html =~ "<div class="
    assert html =~ "pc-container--sm"
  end

  test "should include additional assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.container custom-attrs="123"></.container>
      """)

    assert html =~ ~s{custom-attrs="123"}
  end
end
