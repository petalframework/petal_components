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

  test "range-dual renders two range inputs with shared track" do
    assigns = %{form: to_form(%{"price_min" => 20, "price_max" => 80}, as: :filters)}

    html =
      rendered_to_string(~H"""
      <.input
        type="range-dual"
        min_field={@form[:price_min]}
        max_field={@form[:price_max]}
        range_min={0}
        range_max={100}
      />
      """)

    assert html =~ ~s|type="range"|
    assert html =~ "pc-dual-range"
    assert html =~ "pc-dual-range__thumb"
    assert html =~ ~s|data-pc-range-min|
    assert html =~ ~s|data-pc-range-max|
    assert html =~ ~s|data-pc-range-track|
    assert html =~ ~s|data-pc-range-display|
    assert html =~ "PetalDualRangeSlider"
    assert html =~ "filters[price_min]"
    assert html =~ "filters[price_max]"
  end

  test "range-dual reflects initial field values" do
    assigns = %{
      min_field: %Phoenix.HTML.FormField{
        name: "filters[price_min]",
        value: 25,
        field: :price_min,
        id: "filters_price_min",
        errors: [],
        form: %Phoenix.HTML.Form{params: %{}}
      },
      max_field: %Phoenix.HTML.FormField{
        name: "filters[price_max]",
        value: 75,
        field: :price_max,
        id: "filters_price_max",
        errors: [],
        form: %Phoenix.HTML.Form{params: %{}}
      }
    }

    html =
      rendered_to_string(~H"""
      <.input
        type="range-dual"
        min_field={@min_field}
        max_field={@max_field}
        range_min={0}
        range_max={100}
      />
      """)

    assert html =~ ~s|value="25"|
    assert html =~ ~s|value="75"|
    assert html =~ "25"
    assert html =~ "75"
  end

  test "range-dual falls back to range_min/range_max when field values are nil" do
    assigns = %{form: to_form(%{}, as: :filters)}

    html =
      rendered_to_string(~H"""
      <.input
        type="range-dual"
        min_field={@form[:price_min]}
        max_field={@form[:price_max]}
        range_min={10}
        range_max={90}
      />
      """)

    assert html =~ ~s|value="10"|
    assert html =~ ~s|value="90"|
  end

  test "range-dual renders value_prefix and value_suffix" do
    assigns = %{
      min_field: %Phoenix.HTML.FormField{
        name: "filters[price_min]",
        value: 20,
        field: :price_min,
        id: "filters_price_min",
        errors: [],
        form: %Phoenix.HTML.Form{params: %{}}
      },
      max_field: %Phoenix.HTML.FormField{
        name: "filters[price_max]",
        value: 80,
        field: :price_max,
        id: "filters_price_max",
        errors: [],
        form: %Phoenix.HTML.Form{params: %{}}
      }
    }

    html =
      rendered_to_string(~H"""
      <.input
        type="range-dual"
        min_field={@min_field}
        max_field={@max_field}
        range_min={0}
        range_max={100}
        value_prefix="$"
        value_suffix=" USD"
      />
      """)

    assert html =~ ~s|data-value-prefix="$"|
    assert html =~ ~s|data-value-suffix=" USD"|
    assert html =~ "$20"
    assert html =~ "$100"
  end

  test "range-dual renders custom bound labels" do
    assigns = %{form: to_form(%{}, as: :filters)}

    html =
      rendered_to_string(~H"""
      <.input
        type="range-dual"
        min_field={@form[:price_min]}
        max_field={@form[:price_max]}
        range_min={0}
        range_max={1000}
        range_min_label="Free"
        range_max_label="$1k+"
      />
      """)

    assert html =~ "Free"
    assert html =~ "$1k+"
  end

  test "range-dual disabled state" do
    assigns = %{form: to_form(%{}, as: :filters)}

    html =
      rendered_to_string(~H"""
      <.input
        type="range-dual"
        min_field={@form[:price_min]}
        max_field={@form[:price_max]}
        disabled
      />
      """)

    assert html =~ "pc-dual-range--disabled"
    assert html =~ " disabled"
  end
end
