defmodule PetalComponents.InputTest do
  use ComponentCase
  import PetalComponents.Input

  test "field standard inputs" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.input field={@form[:name]} type="text" />
        <.input field={@form[:name]} type="color" />
        <.input field={@form[:name]} type="date" />
        <.input field={@form[:name]} type="datetime-local" />
        <.input field={@form[:name]} type="email" />
        <.input field={@form[:name]} type="file" />
        <.input field={@form[:name]} type="hidden" />
        <.input field={@form[:name]} type="month" />
        <.input field={@form[:name]} type="number" />
        <.input field={@form[:name]} type="password" />
        <.input field={@form[:name]} type="range" />
        <.input field={@form[:name]} type="search" />
        <.input field={@form[:name]} type="tel" />
        <.input field={@form[:name]} type="text" />
        <.input field={@form[:name]} type="time" />
        <.input field={@form[:name]} type="url" />
        <.input field={@form[:name]} type="week" />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ ~s|type="text"|
    assert html =~ ~s|type="color"|
    assert html =~ ~s|type="date"|
    assert html =~ ~s|type="datetime-local"|
    assert html =~ ~s|type="email"|
    assert html =~ ~s|type="file"|
    assert html =~ ~s|type="hidden"|
    assert html =~ ~s|type="month"|
    assert html =~ ~s|type="number"|
    assert html =~ ~s|type="password"|
    assert html =~ ~s|type="range"|
    assert html =~ ~s|type="search"|
    assert html =~ ~s|type="tel"|
    assert html =~ ~s|type="text"|
    assert html =~ ~s|type="time"|
    assert html =~ ~s|type="url"|
    assert html =~ ~s|type="week"|
  end

  test "input can be passed a class attribute" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.input field={@form[:name]} class="rounted-r-none" type="text" />
      </.form>
      """)

    assert html =~ "rounted-r-none"
  end

  test "dual range slider renders with Alpine.js directives" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input
        type="range-dual"
        id="test_range"
        range_min={0}
        range_max={100}
        min_field={%{name: "min_val", value: 20}}
        max_field={%{name: "max_val", value: 80}}
      />
      """)

    # Check for Alpine.js directives
    assert html =~ "x-data"
    assert html =~ "x-ref=\"minSlider\""
    assert html =~ "x-ref=\"maxSlider\""
    assert html =~ "x-ref=\"rangeTrack\""
    assert html =~ "@input=\"updateMinValue"
    assert html =~ "@input=\"updateMaxValue"

    # Check for phx-update="ignore" to prevent LiveView conflicts
    assert html =~ ~s|phx-update="ignore"|

    # Check for two range inputs
    assert html =~ ~s|type="range"|
    assert html =~ ~s|name="min_val"|
    assert html =~ ~s|name="max_val"|

    # Check for values
    assert html =~ ~s|value="20"|
    assert html =~ ~s|value="80"|

    # Check for range bounds
    assert html =~ ~s|min="0"|
    assert html =~ ~s|max="100"|

    # Check for slider CSS classes
    assert html =~ "pc-slider-input"
    assert html =~ "pc-slider-track"
    assert html =~ "pc-slider-range"

    # Check for value display with x-text
    assert html =~ "x-text"
  end

  test "dual range slider with custom formatter" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input
        type="range-dual"
        id="price_range"
        range_min={0}
        range_max={500}
        range_min_label="$0"
        range_max_label="$500"
        min_field={%{name: "min_price", value: 50}}
        max_field={%{name: "max_price", value: 200}}
        format_value={&("$#{&1}")}
      />
      """)

    # Check that formatter is used for initial render
    assert html =~ "$50"
    assert html =~ "$200"
    assert html =~ "$0"
    assert html =~ "$500"

    # Check that Alpine formatValue function detects $ format
    assert html =~ "formatValue"
  end

  test "dual range slider handles edge case when range_min equals range_max" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input
        type="range-dual"
        id="edge_case_range"
        range_min={100}
        range_max={100}
        min_field={%{name: "min_val", value: 100}}
        max_field={%{name: "max_val", value: 100}}
      />
      """)

    # Should render without crashing
    assert html =~ "x-data"
    assert html =~ ~s|min="100"|
    assert html =~ ~s|max="100"|

    # Should have guard clause for division by zero
    assert html =~ "if (this.rangeMax === this.rangeMin)"
  end
end
