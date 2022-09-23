defmodule PetalComponents.BadgeTest do
  use ComponentCase
  import PetalComponents.Badge

  test "it renders colors and label correctly" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.badge color="primary" label="Primary" />
      """)

    assert html =~ "Primary"
    assert html =~ "text-primary"

    html =
      rendered_to_string(~H"""
      <.badge color="secondary" label="Secondary" />
      """)

    assert html =~ "Secondary"
    assert html =~ "text-secondary"

    html =
      rendered_to_string(~H"""
      <.badge color="info" label="Info" />
      """)

    assert html =~ "Info"
    assert html =~ "text-blue"

    html =
      rendered_to_string(~H"""
      <.badge color="success" label="Success" />
      """)

    assert html =~ "Success"
    assert html =~ "text-green"

    html =
      rendered_to_string(~H"""
      <.badge color="warning" label="Warning" />
      """)

    assert html =~ "Warning"
    assert html =~ "text-yellow"

    html =
      rendered_to_string(~H"""
      <.badge color="danger" label="Danger" />
      """)

    assert html =~ "Danger"
    assert html =~ "text-red"

    html =
      rendered_to_string(~H"""
      <.badge color="gray" label="Gray" />
      """)

    assert html =~ "Gray"
    assert html =~ "text-gray"
  end

  test "it allows you to add a class" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.badge color="gray" label="Gray" class="blah" />
      """)

    assert html =~ "blah"
  end

  test "dark mode" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.badge color="gray" label="Gray" class="blah" />
      """)

    assert html =~ "blah"
    assert html =~ "dark:"
  end

  test "works with icon" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.badge color="gray" variant="light" icon label="SM" size="sm">
        <Heroicons.clock solid class="w-3 h-3 pb-[0.05rem]" />
        2 hours ago
      </.badge>
      """)

    assert html =~ "<svg"
  end

  test "should include additional assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.badge color="primary" label="Primary" custom-attrs="123" />
      """)

    assert html =~ ~s{custom-attrs="123"}
  end
end
