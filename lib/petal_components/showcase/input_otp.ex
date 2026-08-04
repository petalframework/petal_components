defmodule PetalComponents.Showcase.InputOtp do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.InputOtp, title: "Input OTP"

  example :basic, "Six digits",
    description:
      "One real input under the segmented boxes, so paste, SMS autofill and form posts all just work - the boxes are presentation only. length defaults to 6; pattern=\"alphanumeric\" accepts letter codes too. Needs the PetalInputOTP hook from the bundle." do
    ~H"""
    <.input_otp name="otp_code" />
    """
  end

  example :grouped, "Grouped",
    description:
      "group_size splits the boxes with a separator - the 3-3 airline-code look. Typing, arrows and backspace flow across the gap as one field." do
    ~H"""
    <.input_otp name="grouped_code" length={6} group_size={3} />
    """
  end

  example :error_state, "In a form field",
    description:
      "Drop it inside a field wrapper and the error tone carries through to the boxes - the shared form-field classes do the painting, no OTP-specific styling." do
    ~H"""
    <div class="pc-form-field-wrapper pc-form-field-wrapper--error mb-0">
      <.input_otp name="error_code" length={6} value="123" />
      <p class="pc-form-field-error">that code has expired - we sent a new one</p>
    </div>
    """
  end
end
