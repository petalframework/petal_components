defmodule PetalComponents.BadgeTest do
  use ComponentCase
  import PetalComponents.Badge
  import PetalComponents.Icon

  test "it renders colors and label correctly" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.badge color="primary" label="Primary" />
      """)

    assert html =~ "Primary"
    assert html =~ "pc-badge--primary-light"

    html =
      rendered_to_string(~H"""
      <.badge color="secondary" label="Secondary" />
      """)

    assert html =~ "Secondary"
    assert html =~ "pc-badge--secondary-light"

    html =
      rendered_to_string(~H"""
      <.badge color="info" label="Info" />
      """)

    assert html =~ "Info"
    assert html =~ "pc-badge--info-light"

    html =
      rendered_to_string(~H"""
      <.badge color="success" label="Success" />
      """)

    assert html =~ "Success"
    assert html =~ "pc-badge--success-light"

    html =
      rendered_to_string(~H"""
      <.badge color="warning" label="Warning" />
      """)

    assert html =~ "Warning"
    assert html =~ "pc-badge--warning-light"

    html =
      rendered_to_string(~H"""
      <.badge color="danger" label="Danger" />
      """)

    assert html =~ "Danger"
    assert html =~ "pc-badge--danger-light"

    html =
      rendered_to_string(~H"""
      <.badge color="gray" label="Gray" />
      """)

    assert html =~ "Gray"
    assert html =~ "pc-badge--gray-light"
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
    assert html =~ "pc-badge--gray-light"
  end

  test "works with icon" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.badge color="gray" variant="light" with_icon label="SM" size="sm">
        <.icon name="hero-clock-solid" class="w-3 h-3 pb-[0.05rem]" /> 2 hours ago
      </.badge>
      """)

    assert find_icon(html, "hero-clock-solid")
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
