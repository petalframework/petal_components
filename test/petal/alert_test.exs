defmodule PetalComponents.AlertTest do
  use ComponentCase
  import PetalComponents.Alert

  test "it renders colors and icon correctly" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.alert with_icon color="info" label="Info alert" />
      """)

    assert html =~ "Info alert"
    assert find_icon(html, "hero-information-circle")
    assert html =~ "pc-alert--info"

    html =
      rendered_to_string(~H"""
      <.alert with_icon color="warning" label="Label" />
      """)

    assert find_icon(html, "hero-exclamation-circle")
    assert html =~ "pc-alert--warning"

    html =
      rendered_to_string(~H"""
      <.alert with_icon color="danger" label="Label" />
      """)

    assert find_icon(html, "hero-x-circle")
    assert html =~ "pc-alert--danger"

    html =
      rendered_to_string(~H"""
      <.alert with_icon color="success" label="Label" />
      """)

    assert html =~ "pc-alert--success"
    assert find_icon(html, "hero-check-circle")
  end

  test "default color is info" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.alert label="Label" />
      """)

    assert html =~ "pc-alert--info"
  end

  test "when there is no label it doesn't render anything" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.alert label="" />
      """)

    assert html == ""
  end

  test "can supply a heading" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.alert label="x" heading="Success!" />
      """)

    assert html =~ "Success!"
  end

  test "dark mode" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.alert label="x" heading="Success!" />
      """)

    assert html =~ "Success!"
    assert html =~ "pc-alert--info"
  end

  test "should include additional assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.alert label="x" custom-attrs="123" heading="Success!" />
      """)

    assert html =~ ~s{custom-attrs="123"}
  end

  test "dismissable alerts renders go away box with correct colours" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.alert
        with_icon
        color="info"
        label="Info alert"
        close_button_properties={["phx-click": "do_something"]}
      />
      """)

    assert html =~ "pc-alert__dismiss-button--info"

    html =
      rendered_to_string(~H"""
      <.alert color="warning" label="Label" close_button_properties={["phx-click": "do_something"]} />
      """)

    assert html =~ "pc-alert__dismiss-button--warning"

    html =
      rendered_to_string(~H"""
      <.alert color="danger" label="Label" close_button_properties={["phx-click": "do_something"]} />
      """)

    assert html =~ "pc-alert__dismiss-button--danger"

    html =
      rendered_to_string(~H"""
      <.alert color="success" label="Label" close_button_properties={["phx-click": "do_something"]} />
      """)

    assert html =~ "pc-alert__dismiss-button--success"
  end
end
