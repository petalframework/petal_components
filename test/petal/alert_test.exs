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
    assert html =~ "<svg"
    assert html =~ "text-blue"

    html =
      rendered_to_string(~H"""
      <.alert color="warning" label="Label" />
      """)

    assert html =~ "text-yellow"

    html =
      rendered_to_string(~H"""
      <.alert color="danger" label="Label" />
      """)

    assert html =~ "text-red"

    html =
      rendered_to_string(~H"""
      <.alert color="success" label="Label" />
      """)

    assert html =~ "text-green"
  end

  test "default color is info" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.alert label="Label" />
      """)

    assert html =~ "text-blue"
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
    assert html =~ "dark:"
  end

  test "should include additional assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.alert label="x" custom-attrs="123" heading="Success!" />
      """)

    assert html =~ ~s{custom-attrs="123"}
  end
end
