defmodule PetalComponents.InputOtpTest do
  @moduledoc """
  Tests for PetalComponents.InputOtp - the segmented one-time-code input.
  """

  use ComponentCase
  import PetalComponents.InputOtp

  test "renders one real input plus the requested number of slots" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input_otp name="code" />
      """)

    assert html =~ "pc-otp"
    assert html =~ ~s(phx-hook="PetalInputOTP")
    assert html =~ ~s(autocomplete="one-time-code")
    assert html =~ ~s(inputmode="numeric")
    assert html =~ ~s(maxlength="6")
    assert length(String.split(html, "data-pc-otp-slot")) - 1 == 6
  end

  test "group_size splits slots with separators" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input_otp name="code" length={6} group_size={3} />
      """)

    assert length(String.split(html, "pc-otp__group\"")) - 1 == 2
    assert html =~ "pc-otp__separator"
  end

  test "alphanumeric pattern switches inputmode and data attr" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input_otp name="pin" length={4} pattern="alphanumeric" />
      """)

    assert html =~ ~s(inputmode="text")
    assert html =~ ~s(data-pattern="alphanumeric")
    assert html =~ ~s(maxlength="4")
  end

  test "disabled reaches the real input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input_otp name="code" disabled />
      """)

    assert html =~ "disabled"
  end
end
