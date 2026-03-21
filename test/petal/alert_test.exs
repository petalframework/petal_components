defmodule PetalComponents.AlertTest do
  @moduledoc """
  Tests for PetalComponents.Alert component.

  Validates alert rendering with different colors, variants, icons,
  dismissible behavior, and proper handling of edge cases.
  """

  use ComponentCase
  import PetalComponents.Alert

  describe "alert/1 - basic rendering" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders alert with label", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert label="Test alert message" />
        """)

      assert html =~ "Test alert message"
    end

    test "renders with heading and label", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert heading="Success!" label="Operation completed" />
        """)

      assert html =~ "Success!"
      assert html =~ "Operation completed"
    end

    test "does not render when label is empty", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert label="" />
        """)

      assert html == ""
    end

    test "includes additional assigns as attributes", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert label="Alert" custom-attrs="123" data-test="value" />
        """)

      assert_attribute(html, "custom-attrs", "123")
      assert_attribute(html, "data-test", "value")
    end
  end

  describe "alert/1 - colors and default" do
    setup do
      %{assigns: default_assigns()}
    end

    test "defaults to info color when not specified", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert label="Default alert" />
        """)

      assert_has_class(html, alert_class("info"))
    end

    test "renders all color variants correctly" do
      ~w(info warning danger success) |> Enum.each(fn color ->
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <.alert color={@color} label="Alert message" />
          """)

        assert_has_class(html, alert_class(color))
      end)
    end
  end

  describe "alert/1 - icons" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders info icon for info alerts with with_icon flag", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert with_icon color="info" label="Info alert" />
        """)

      assert has_icon?(html, "hero-information-circle")
      assert_has_class(html, alert_class("info"))
    end

    test "renders warning icon for warning alerts", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert with_icon color="warning" label="Warning alert" />
        """)

      assert has_icon?(html, "hero-exclamation-circle")
      assert_has_class(html, alert_class("warning"))
    end

    test "renders danger icon for danger alerts", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert with_icon color="danger" label="Danger alert" />
        """)

      assert has_icon?(html, "hero-x-circle")
      assert_has_class(html, alert_class("danger"))
    end

    test "renders success icon for success alerts", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert with_icon color="success" label="Success alert" />
        """)

      assert has_icon?(html, "hero-check-circle")
      assert_has_class(html, alert_class("success"))
    end

    test "does not render icon without with_icon flag", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert color="info" label="Info alert" />
        """)

      assert count_icons(html) == 0
    end
  end

  describe "alert/1 - variants" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders all variant styles correctly" do
      ~w(light dark soft outline) |> Enum.each(fn variant ->
        assigns = %{variant: variant}

        html =
          rendered_to_string(~H"""
          <.alert variant={@variant} color="info" label="Alert" />
          """)

        assert html =~ "Alert"
        assert_has_class(html, alert_class("info"))
      end)
    end
  end

  describe "alert/1 - dismissible alerts" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders dismiss button with proper color classes for all colors and default variant" do
      ~w(info warning danger success) |> Enum.each(fn color ->
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <.alert
            color={@color}
            label="Dismissible alert"
            close_button_properties={["phx-click": "dismiss"]}
          />
          """)

        assert_has_class(html, alert_dismiss_button_class(color))
        assert_attribute(html, "phx-click", "dismiss")
      end)
    end

    test "renders dismiss button with variant-specific classes" do
      test_cases = for color <- ~w(info warning danger success),
                        variant <- ~w(dark soft outline),
                        do: {color, variant}

      Enum.each(test_cases, fn {color, variant} ->
        assigns = %{color: color, variant: variant}

        html =
          rendered_to_string(~H"""
          <.alert
            color={@color}
            variant={@variant}
            label="Alert"
            close_button_properties={["phx-click": "dismiss"]}
          />
          """)

        assert_has_class(html, alert_dismiss_button_class(color, variant))
      end)
    end

    test "non-dismissible alert does not render close button", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert label="Basic alert" />
        """)

      refute html =~ "pc-alert__dismiss-button"
      assert html =~ "Basic alert"
    end
  end

  describe "alert/1 - accessibility" do
    setup do
      %{assigns: default_assigns()}
    end

    test "alert has proper semantic role", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert label="Alert message" role="alert" />
        """)

      assert_attribute(html, "role", "alert")
    end

    test "dismiss button is keyboard accessible", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert
          label="Alert"
          close_button_properties={["phx-click": "dismiss", "aria-label": "Close alert"]}
        />
        """)

      assert_attribute(html, "aria-label", "Close alert")
    end

    test "icon alerts maintain semantic meaning with aria-label", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert
          with_icon
          color="danger"
          label="Error occurred"
          aria-label="Error: Error occurred"
        />
        """)

      assert_attribute(html, "aria-label", "Error: Error occurred")
    end
  end

  describe "alert/1 - edge cases" do
    setup do
      %{assigns: default_assigns()}
    end

    test "handles nil label by not rendering", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert label={nil} />
        """)

      assert html == ""
    end

    test "handles empty string label by not rendering", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert label="" />
        """)

      assert html == ""
    end

    test "handles very long alert messages", %{assigns: assigns} do
      long_message = String.duplicate("This is a long alert message. ", 20)
      assigns = %{message: long_message}

      html =
        rendered_to_string(~H"""
        <.alert label={@message} />
        """)

      assert html =~ long_message
    end

    test "handles heading without label gracefully", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert heading="Heading Only" label="" />
        """)

      assert html == ""
    end

    test "handles nil color with default", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert color={nil} label="Alert" />
        """)

      assert html =~ "Alert"
    end
  end

  describe "alert/1 - negative cases" do
    setup do
      %{assigns: default_assigns()}
    end

    test "dismiss button without phx-click properties still renders", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.alert label="Alert" close_button_properties={[]} />
        """)

      assert html =~ "Alert"
    end

    test "with_icon without valid color raises error", %{assigns: assigns} do
      assert_raise FunctionClauseError, fn ->
        rendered_to_string(~H"""
        <.alert with_icon color="invalid" label="Alert" />
        """)
      end
    end
  end
end
