defmodule PetalComponents.NumberFieldTest do
  @moduledoc """
  Tests for PetalComponents.NumberField - the spinbutton composition on the
  input-group surface. The hook consumes the data-* attrs asserted here, and
  test/js/number_field.test.js pins the other half of that contract; change
  the anatomy and both move together.
  """

  use ComponentCase

  import PetalComponents.Field
  import PetalComponents.NumberField

  defp doc(html), do: LazyHTML.from_fragment(html)
  defp one(html, selector), do: html |> doc() |> LazyHTML.query(selector) |> Enum.at(0)
  defp all(html, selector), do: html |> doc() |> LazyHTML.query(selector) |> Enum.to_list()

  defp at(nil, _name), do: nil

  defp at(node, name) do
    node |> LazyHTML.attribute(name) |> Enum.at(0)
  end

  describe "anatomy" do
    test "renders the input-group surface, the input and the stacked buttons by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="quantity" value="3" />
        """)

      assert_has_class(html, "pc-input-group")
      assert_has_class(html, "pc-number-field")
      assert_has_class(html, "pc-number-field--stacked")
      assert_has_class(html, "pc-number-field--md")
      assert_has_class(html, "pc-number-field__stack")

      input = one(html, "input.pc-number-field__input")
      assert at(input, "type") == "text"
      assert at(input, "inputmode") == "decimal"
      assert at(input, "name") == "quantity"
      assert at(input, "value") == "3"

      assert length(all(html, "button[data-pc-number-step]")) == 2
    end

    test "split puts the decrement in the leading addon and the increment in the trailing one" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="qty" value="3" variant="split" />
        """)

      assert_has_class(html, "pc-number-field--split")
      refute_has_class(html, "pc-number-field__stack")

      leading = one(html, ".pc-input-group__addon--leading button")
      trailing = one(html, ".pc-input-group__addon--trailing button")

      assert at(leading, "data-pc-number-step") == "dec"
      assert at(trailing, "data-pc-number-step") == "inc"
    end

    test "plain renders no buttons at all" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="qty" value="3" variant="plain" />
        """)

      assert_has_class(html, "pc-number-field--plain")
      assert all(html, "button[data-pc-number-step]") == []
      assert all(html, ".pc-input-group__addon") == []
    end

    test "renders leading and trailing slots alongside the buttons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="price" value="10">
          <:leading>$</:leading>
          <:trailing>USD</:trailing>
        </.number_field>
        """)

      assert html =~ "$"
      assert html =~ "USD"
      assert length(all(html, "button[data-pc-number-step]")) == 2
    end

    test "each size lands its modifier and extra classes ride along" do
      for size <- ~w(sm md lg) do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <.number_field name="qty" value="1" size={@size} class="max-w-xs" />
          """)

        assert_has_class(html, "pc-number-field--#{size}")
        assert_has_class(html, "max-w-xs")
      end
    end
  end

  describe "hook wiring" do
    test "emits the hook, a stable wrapper id and every data-* the hook reads" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field
          id="qty"
          name="quantity"
          value="5"
          min={1}
          max={99}
          step={0.5}
          big_step={5}
          precision={2}
        />
        """)

      group = one(html, ".pc-number-field")
      assert at(group, "phx-hook") == "PetalNumberField"
      assert at(group, "id") == "qty-field"
      assert at(group, "data-min") == "1"
      assert at(group, "data-max") == "99"
      assert at(group, "data-step") == "0.5"
      assert at(group, "data-big-step") == "5"
      assert at(group, "data-precision") == "2"

      assert at(one(html, "input"), "id") == "qty"
    end

    test "big_step defaults to ten steps" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="qty" value="1" step={0.5} />
        """)

      assert at(one(html, ".pc-number-field"), "data-big-step") == "5"
    end

    test "unset bounds emit no data attributes to read" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="qty" value="1" />
        """)

      group = one(html, ".pc-number-field")
      assert at(group, "data-min") == nil
      assert at(group, "data-max") == nil
      assert at(group, "data-precision") == nil
    end

    test "the id is derived from the name when none is passed" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="order[quantity]" value="1" />
        """)

      assert at(one(html, "input"), "id") == "number_field_order_quantity_"
      assert at(one(html, ".pc-number-field"), "id") == "number_field_order_quantity_-field"
    end

    test "no identity at all is a loud programming error" do
      assigns = %{}

      assert_raise ArgumentError, ~r/requires a field, an id or a name/, fn ->
        rendered_to_string(~H"""
        <.number_field value="1" />
        """)
      end
    end
  end

  describe "accessibility" do
    test "the input is a spinbutton with its bounds and value mirrored" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="qty" value="7" min={1} max={99} />
        """)

      input = one(html, "input")
      assert at(input, "role") == "spinbutton"
      assert at(input, "aria-valuenow") == "7"
      assert at(input, "aria-valuemin") == "1"
      assert at(input, "aria-valuemax") == "99"
    end

    test "a blank or unparseable value reports no aria-valuenow" do
      for value <- [nil, "", "abc"] do
        assigns = %{value: value}

        html =
          rendered_to_string(~H"""
          <.number_field name="qty" value={@value} />
          """)

        assert at(one(html, "input"), "aria-valuenow") == nil
      end
    end

    test "aria-valuenow describes the ROUNDED value the user sees, not the raw parse" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="qty" value="5.5" precision={0} min={1} max={6} />
        """)

      input = one(html, "input")
      # display rounds 5.5 -> 6; announcing 5.5 against a visible 6 would
      # desync the first paint from what the hook later syncs
      assert at(input, "value") == "6"
      assert at(input, "aria-valuenow") == "6"
      # and the bound check follows the rounded value: 6 IS at max
      assert one(html, "[data-pc-number-step=inc]") |> at("aria-disabled") == "true"
    end

    test "aria-label rides the global attrs for standalone use" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="qty" value="3" aria-label="Quantity" />
        """)

      assert at(one(html, "input"), "aria-label") == "Quantity"
    end

    test "buttons are labelled, typed and kept out of the tab order" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="qty" value="3" />
        """)

      for button <- all(html, "button[data-pc-number-step]") do
        assert at(button, "type") == "button"
        assert at(button, "tabindex") == "-1"
        assert at(button, "aria-label") in ["Increase value", "Decrease value"]
      end
    end

    test "button labels are overridable" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field
          name="qty"
          value="3"
          increment_label="Add one seat"
          decrement_label="Remove one seat"
        />
        """)

      assert html =~ "Add one seat"
      assert html =~ "Remove one seat"
    end

    test "a value at a bound marks that button aria-disabled, not disabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="qty" value="1" min={1} max={10} />
        """)

      dec = one(html, "button[data-pc-number-step=dec]")
      inc = one(html, "button[data-pc-number-step=inc]")

      assert at(dec, "aria-disabled") == "true"
      assert at(dec, "disabled") == nil
      assert at(inc, "aria-disabled") == nil
    end

    test "a value past the upper bound still marks the increment spent" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="qty" value="42" max={10} />
        """)

      assert at(one(html, "button[data-pc-number-step=inc]"), "aria-disabled") == "true"
      assert at(one(html, "button[data-pc-number-step=dec]"), "aria-disabled") == nil
    end

    test "an empty value disables neither button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="qty" value="" min={1} max={10} />
        """)

      for button <- all(html, "button[data-pc-number-step]") do
        assert at(button, "aria-disabled") == nil
      end
    end

    test "disabled uses the native attribute on the input and both buttons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="qty" value="3" disabled />
        """)

      assert at(one(html, "input"), "disabled") == ""

      for button <- all(html, "button[data-pc-number-step]") do
        assert at(button, "disabled") == ""
      end
    end

    test "readonly and required pass through to the input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="qty" value="3" readonly required placeholder="0" />
        """)

      input = one(html, "input")
      assert at(input, "readonly") == ""
      assert at(input, "required") == ""
      assert at(input, "placeholder") == "0"
    end
  end

  describe "precision" do
    test "pads and rounds the rendered value so the first paint matches post-blur" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="price" value="24.5" precision={2} />
        """)

      assert at(one(html, "input"), "value") == "24.50"
    end

    test "precision 0 rounds to a whole number" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="price" value="24.6" precision={0} />
        """)

      assert at(one(html, "input"), "value") == "25"
    end

    test "without precision the value is rendered as given" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="price" value="24.50" />
        """)

      assert at(one(html, "input"), "value") == "24.50"
    end

    test "text that is not a number rides through untouched" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_field name="price" value="12." precision={2} />
        """)

      assert at(one(html, "input"), "value") == "12."
    end

    test "integer and float values both render" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <div>
          <.number_field name="a" value={5} />
          <.number_field name="b" value={5.5} />
        </div>
        """)

      assert at(Enum.at(all(html, "input"), 0), "value") == "5"
      assert at(Enum.at(all(html, "input"), 1), "value") == "5.5"
    end
  end

  describe "form integration" do
    defp form_field(value, errors \\ []) do
      %Phoenix.HTML.FormField{
        id: "order_quantity",
        name: "order[quantity]",
        errors: errors,
        field: :quantity,
        # errors only surface for a field the user has actually touched, so
        # the form has to carry params for the error case to be honest
        form: %Phoenix.HTML.Form{params: %{"quantity" => value}},
        value: value
      }
    end

    test "derives id, name and value from a form field" do
      assigns = %{field: form_field("4")}

      html =
        rendered_to_string(~H"""
        <.number_field field={@field} min={1} />
        """)

      input = one(html, "input")
      assert at(input, "id") == "order_quantity"
      assert at(input, "name") == "order[quantity]"
      assert at(input, "value") == "4"
      assert at(input, "aria-valuenow") == "4"
      assert at(one(html, ".pc-number-field"), "id") == "order_quantity-field"
    end

    test "an explicit id wins over the form field's" do
      assigns = %{field: form_field("4")}

      html =
        rendered_to_string(~H"""
        <.number_field field={@field} id="custom" />
        """)

      assert at(one(html, "input"), "id") == "custom"
      assert at(one(html, "input"), "name") == "order[quantity]"
    end

    test "type=\"number-field\" renders the label, the control and the help text" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.field type="number-field" name="seats" value="3" label="Seats" min={1} help_text="1 to 20" />
        """)

      assert_has_class(html, "pc-form-field-wrapper")
      assert_has_class(html, "pc-number-field")
      assert html =~ "Seats"
      assert html =~ "1 to 20"

      label = one(html, "label")
      assert at(label, "for") == at(one(html, "input"), "id")
      assert at(one(html, ".pc-number-field"), "data-min") == "1"
    end

    test "type=\"number-field\" surfaces errors through the wrapper" do
      assigns = %{field: form_field("0", [{"must be at least 1", []}])}

      html =
        rendered_to_string(~H"""
        <.field type="number-field" field={@field} label="Quantity" min={1} />
        """)

      assert_has_class(html, "pc-form-field-wrapper--error")
      assert html =~ "must be at least 1"
      assert at(one(html, "input"), "name") == "order[quantity]"
    end

    test "type=\"number-field\" maps the xs-xl field sizes onto sm/md/lg" do
      for {field_size, expected} <- [{"xs", "sm"}, {"sm", "sm"}, {"md", "md"}, {"xl", "lg"}] do
        assigns = %{size: field_size}

        html =
          rendered_to_string(~H"""
          <.field type="number-field" name="qty" value="1" size={@size} />
          """)

        assert_has_class(html, "pc-number-field--#{expected}")
      end
    end

    test "type=\"number-field\" carries the variant and the hook attrs through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.field
          type="number-field"
          name="qty"
          value="2"
          number_variant="split"
          min={1}
          max={9}
          step={0.5}
          precision={1}
        />
        """)

      group = one(html, ".pc-number-field")
      assert_has_class(html, "pc-number-field--split")
      assert at(group, "data-step") == "0.5"
      assert at(group, "data-precision") == "1"
      assert at(one(html, "input"), "value") == "2.0"
    end
  end
end
