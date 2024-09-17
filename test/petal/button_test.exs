defmodule PetalComponents.ButtonTest do
  use ComponentCase
  import PetalComponents.Button
  import PetalComponents.Icon

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
    assert html =~ "pc-button--primary-shadow"
  end

  test "button with dark mode" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button color="primary" variant="shadow" phx-click="click_event">Press me</.button>
      """)

    assert html =~ "<button"
    assert html =~ "Press me"
    assert html =~ "pc-button--primary-shadow"
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
        <.icon name="hero-clock-solid" />
      </.icon_button>
      """)

    assert find_icon(html, "hero-clock-solid")
    assert html =~ "pc-icon-button-bg--primary"
    refute html =~ "tooltip"
  end

  test "icon button with color" do
    colors = ~w(primary secondary success danger warning info gray)

    Enum.each(colors, fn color ->
      assigns = %{color: color}

      html =
        rendered_to_string(~H"""
        <.icon_button color={@color}>
          <.icon name="hero-clock" />
        </.icon_button>
        """)

      assert find_icon(html, "hero-clock")
      assert html =~ "pc-icon-button-bg--#{color}"
    end)
  end

  test "icon button with tooltip" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.icon_button to="/" link_type="button" size="xs" color="primary" tooltip="Hello world!">
        <.icon name="hero-clock-solid" />
      </.icon_button>
      """)

    assert find_icon(html, "hero-clock-solid")
    assert html =~ "pc-icon-button-bg--primary"
    assert html =~ "role=\"tooltip"
    assert html =~ "Hello world!"
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
      <.button icon="hero-home" label="Home" />
      """)

    assert html =~ "<button"
    assert find_icon(html, "hero-home")
  end

  test "disabled button" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button disabled label="Home" phx-click="click-me" />
      """)

    assert html =~ " disabled"
    refute html =~ " phx-"

    html =
      rendered_to_string(~H"""
      <.button disabled link_type="live_redirect" label="Home" />
      """)

    assert html =~ " disabled"
    refute html =~ "href"
    refute html =~ " phx-"
  end

  test "rest attrs" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button
        label="Home"
        method="x"
        download="x"
        hreflang="x"
        ping="x"
        referrerpolicy="x"
        rel="x"
        target="x"
        type="x"
        value="x"
        name="x"
        form="x"
      />
      """)

    assert html =~ ~s{method="x"}
  end
end
