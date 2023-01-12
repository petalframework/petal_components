defmodule PetalComponents.ButtonTest do
  use ComponentCase
  import PetalComponents.Button

  test "button" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button label="Press me" phx-click="click_event" />
      """)

    assert html =~ "<button"
    assert html =~ "Press me"
  end

  test "a" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button link_type="a" label="Press me" to="/" phx-click="Press me" />
      """)

    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "phx-click"
  end

  test "patch" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button link_type="live_patch" label="Press me" to="/" phx-click="click_event" />
      """)

    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "phx-click"
  end

  test "redirect" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button link_type="live_redirect" label="Press me" to="/" phx-click="click_event" />
      """)

    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "phx-click"
  end

  test "button with inner_block" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button phx-click="click_event">Press me</.button>
      """)

    assert html =~ "<button"
    assert html =~ "Press me"
  end

  test "button with loading but no size" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button loading phx-click="click_event">Press me</.button>
      """)

    assert html =~ "<button"
    assert html =~ "Press me"
    assert html =~ "<svg"
  end

  test "button with shadow" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button color="primary" variant="shadow" phx-click="click_event">Press me</.button>
      """)

    assert html =~ "<button"
    assert html =~ "Press me"
    assert html =~ "shadow-xl"
  end

  test "button with dark mode" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button color="primary" variant="shadow" phx-click="click_event">Press me</.button>
      """)

    assert html =~ "<button"
    assert html =~ "Press me"
    assert html =~ "dark:"
  end

  test "button with custom class" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button class="some-special-class">Press me</.button>
      """)

    assert html =~ "some-special-class"
  end

  test "icon button" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.icon_button to="/" link_type="button" size="xs" color="primary">
        <Heroicons.clock solid />
      </.icon_button>
      """)

    assert html =~ "<svg"
    assert html =~ "dark:hover:"
  end

  test "should include additional assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button custom-attr="123" type="button">Press me</.button>
      """)

    assert html =~ ~s{custom-attr="123"}
    assert html =~ ~s{type="button"}
  end

  test "button with icon attr" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button icon={:home} label="Home" />
      """)

    assert html =~ "<button"
    assert html =~ "<svg"
  end
end
