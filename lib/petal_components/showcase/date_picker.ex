defmodule PetalComponents.Showcase.DatePicker do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.DatePicker, title: "Date picker"

  example :basic, "Input plus calendar",
    description:
      "The input shows a formatted date you can type into; a hidden input posts ISO 8601 whatever the display format is. Click the calendar icon, or press Escape to close and land back on the input." do
    ~H"""
    <.date_picker
      id="showcase-date-picker"
      name="due_on"
      label="Due date"
      value={~D[2026-03-14]}
      format="%d %b %Y"
      clearable
    />
    """
  end

  example :range, "Two-month range",
    description:
      "Range mode posts from and to sub-fields. two_months puts the second pane beside the first, which is what a booking flow wants." do
    ~H"""
    <.date_picker
      id="showcase-date-picker-range"
      name="stay"
      mode="range"
      label="Stay"
      two_months
      format="%d %b"
      value={{~D[2026-03-09], ~D[2026-03-17]}}
    />
    """
  end

  example :errors, "Field surface",
    description:
      "Errors, help text and the required marker come from the same field surface as <.field>, so a picker sits in a form without looking bolted on." do
    ~H"""
    <.date_picker
      id="showcase-date-picker-errors"
      name="starts_on"
      label="Start date"
      required
      placeholder="Pick a start date"
      help_text="We only take bookings from tomorrow."
      errors={["can't be blank"]}
    />
    """
  end
end
