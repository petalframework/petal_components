defmodule PetalComponents.FieldA11yTest do
  use ComponentCase
  import PetalComponents.Field

  # <.field> ties its help text and its error messages to the control with
  # aria-describedby, and marks the control aria-invalid while it has errors.
  # The ids are <id>-help and <id>-errors; every message sits in one
  # <div class="pc-form-field-errors"> that carries the errors id.

  defp doc(html), do: LazyHTML.from_fragment(html)
  defp attr_of(html, sel, name), do: doc(html) |> LazyHTML.query(sel) |> LazyHTML.attribute(name)
  defp count(html, sel), do: doc(html) |> LazyHTML.query(sel) |> Enum.count()

  # Every id an aria-describedby names must exist in the same fragment.
  defp assert_no_dangling_references(html) do
    for value <-
          doc(html)
          |> LazyHTML.query("[aria-describedby]")
          |> LazyHTML.attribute("aria-describedby"),
        id <- String.split(value) do
      assert count(html, ~s([id="#{id}"])) == 1,
             "aria-describedby names #{id}, which is not rendered"
    end
  end

  defp form_field(name, errors, opts \\ []) do
    %Phoenix.HTML.FormField{
      errors: errors,
      name: "user[#{name}]",
      value: Keyword.get(opts, :value, ""),
      field: name,
      id: "user_#{name}",
      form: %Phoenix.HTML.Form{params: Keyword.get(opts, :params, %{to_string(name) => ""})}
    }
  end

  test "text field with errors and help text ties both to the input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.field
        id="user_email"
        name="user[email]"
        label="Email"
        value=""
        help_text="We never share it"
        errors={["can't be blank", "is invalid"]}
      />
      """)

    assert attr_of(html, "input#user_email", "aria-invalid") == ["true"]

    assert attr_of(html, "input#user_email", "aria-describedby") == [
             "user_email-help user_email-errors"
           ]

    assert count(html, "#user_email-errors.pc-form-field-errors .pc-form-field-error") == 2
    assert count(html, "#user_email-help.pc-form-help-text") == 1
    assert_no_dangling_references(html)
  end

  test "no errors: no aria-invalid, help only, no errors box" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.field id="user_email" name="user[email]" label="Email" value="" help_text="Hint" />
      """)

    assert attr_of(html, "input#user_email", "aria-invalid") == []
    assert attr_of(html, "input#user_email", "aria-describedby") == ["user_email-help"]
    assert count(html, "#user_email-errors") == 0
    assert count(html, ".pc-form-field-errors") == 0
  end

  test "neither help nor errors: no aria-describedby" do
    assigns = %{}
    html = rendered_to_string(~H|<.field id="a" name="a" label="A" value="" />|)
    assert attr_of(html, "input#a", "aria-describedby") == []
    assert attr_of(html, "input#a", "aria-invalid") == []
  end

  test "the caller's own aria-describedby is kept, first, and appears once" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.field
        id="a"
        name="a"
        label="A"
        value=""
        aria-describedby="mine"
        help_text="h"
        errors={["bad"]}
      />
      """)

    assert attr_of(html, "input#a", "aria-describedby") == ["mine a-help a-errors"]
    [_, after_input] = String.split(html, ~s|id="a"|, parts: 2)
    input_tag = after_input |> String.split(">", parts: 2) |> hd()
    assert length(Regex.scan(~r/aria-describedby=/, input_tag)) == 1
  end

  test "a caller's aria-invalid={false} switches it off even with errors" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.field id="a" name="a" label="A" value="" aria-invalid={false} errors={["bad"]} />
      """)

    assert attr_of(html, "input#a", "aria-invalid") == []
    # the message is still described
    assert attr_of(html, "input#a", "aria-describedby") == ["a-errors"]
  end

  test "a caller's aria-invalid string wins and appears once" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.field id="a" name="a" label="A" value="" aria-invalid="false" errors={["bad"]} />
      """)

    assert attr_of(html, "input#a", "aria-invalid") == ["false"]
    assert length(Regex.scan(~r/aria-invalid=/, html)) == 1
  end

  test "an atom id works" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.field id={:email} name="email" label="Email" value="" help_text="h" errors={["bad"]} />
      """)

    assert attr_of(html, "input#email", "aria-describedby") == ["email-help email-errors"]
    assert count(html, "#email-errors") == 1
    assert count(html, "#email-help") == 1
  end

  test "no id and no field: no ids are minted and nothing dangles" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.field name="email" label="Email" value="" help_text="h" errors={["bad"]} />
      """)

    assert attr_of(html, "input", "aria-describedby") == []
    assert attr_of(html, "input", "aria-invalid") == ["true"]
    assert count(html, ".pc-form-field-errors[id]") == 0
    assert count(html, ".pc-form-field-errors .pc-form-field-error") == 1
    assert count(html, ".pc-form-help-text[id]") == 0
  end

  test "an empty help_text still renders the element it references" do
    assigns = %{}

    html = rendered_to_string(~H|<.field id="a" name="a" label="A" value="" help_text="" />|)
    assert_no_dangling_references(html)
  end

  test "FormField errors (used input) set aria on the input" do
    assigns = %{field: form_field(:name, [{"can't be blank", [validation: :required]}])}

    html = rendered_to_string(~H|<.field field={@field} />|)
    assert attr_of(html, "input#user_name", "aria-invalid") == ["true"]
    assert attr_of(html, "input#user_name", "aria-describedby") == ["user_name-errors"]
    assert count(html, "#user_name-errors .pc-form-field-error") == 1
  end

  test "FormField errors on an unused input: no aria-invalid, no errors box" do
    assigns = %{
      field: form_field(:name, [{"can't be blank", [validation: :required]}], params: %{})
    }

    html = rendered_to_string(~H|<.field field={@field} />|)
    assert attr_of(html, "input#user_name", "aria-invalid") == []
    assert attr_of(html, "input#user_name", "aria-describedby") == []
    assert count(html, "#user_name-errors") == 0
  end

  test "the ids stay the same as errors come and go" do
    render = fn errors ->
      assigns = %{errors: errors}

      rendered_to_string(~H"""
      <.field id="a" name="a" label="A" value="" help_text="h" errors={@errors} />
      """)
    end

    valid = render.([])
    invalid = render.(["bad", "worse"])
    valid_again = render.([])

    assert attr_of(valid, "input#a", "aria-describedby") == ["a-help"]
    assert attr_of(invalid, "input#a", "aria-describedby") == ["a-help a-errors"]
    assert attr_of(invalid, "input#a", "aria-invalid") == ["true"]
    assert valid_again == valid
    assert attr_of(invalid, "#a-help", "id") == attr_of(valid, "#a-help", "id")
  end

  for type <-
        ~w(text email password search tel url number color file date datetime-local time month week textarea select switch checkbox range) do
    test "#{type}: control carries aria-invalid and aria-describedby" do
      type = unquote(type)
      assigns = %{type: type}

      html =
        rendered_to_string(~H"""
        <.field
          type={@type}
          id="f"
          name="f"
          label="F"
          value=""
          options={[{"A", "a"}]}
          help_text="h"
          errors={["bad"]}
        />
        """)

      sel = if type in ["textarea", "select"], do: "#{type}#f", else: "input#f"
      assert attr_of(html, sel, "aria-invalid") == ["true"]
      # a checkbox's help text sits inside its label, so it is already part
      # of the name: describing the box by it too would read it twice
      expected = if type == "checkbox", do: "f-errors", else: "f-help f-errors"
      assert attr_of(html, sel, "aria-describedby") == [expected]
      assert count(html, "#f-errors .pc-form-field-error") == 1
      assert_no_dangling_references(html)
    end
  end

  test "checkbox: help text is not an id target, it stays inside the label" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.field type="checkbox" id="c" name="c" label="C" help_text="h" />|)

    assert attr_of(html, "input#c", "aria-describedby") == []
    assert count(html, "label .pc-checkbox-text__help") == 1
    assert count(html, "#c-help") == 0
  end

  test "select multiple: the select carries aria" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.field
        type="select"
        multiple
        id="s"
        name="s"
        label="S"
        value={[]}
        options={[{"A", "a"}, {"B", "b"}]}
        errors={["bad"]}
      />
      """)

    assert attr_of(html, "select#s", "aria-invalid") == ["true"]
    assert attr_of(html, "select#s", "aria-describedby") == ["s-errors"]
  end

  test "range with fill: the attributes land on the input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.field type="range" fill id="r" name="r" label="R" value="5" help_text="h" errors={["bad"]} />
      """)

    assert attr_of(html, "input#r", "aria-invalid") == ["true"]
    assert attr_of(html, "input#r", "aria-describedby") == ["r-help r-errors"]
  end

  for {type, extra} <- [{"password", :viewable}, {"text", :copyable}, {"text", :clearable}] do
    test "#{type} #{extra}: control carries aria" do
      assigns = %{type: unquote(type), extra: unquote(extra)}

      html =
        rendered_to_string(~H"""
        <.field
          type={@type}
          id="f"
          name="f"
          label="F"
          value=""
          viewable={@extra == :viewable}
          copyable={@extra == :copyable}
          clearable={@extra == :clearable}
          help_text="h"
          errors={["bad"]}
        />
        """)

      assert attr_of(html, "input#f", "aria-invalid") == ["true"]
      assert attr_of(html, "input#f", "aria-describedby") == ["f-help f-errors"]
      assert_no_dangling_references(html)
    end
  end

  test "number-field: the spinbutton carries aria" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.field type="number-field" id="n" name="n" label="N" value="1" help_text="h" errors={["bad"]} />|
      )

    assert attr_of(html, "input#n", "aria-invalid") == ["true"]
    assert attr_of(html, "input#n", "aria-describedby") == ["n-help n-errors"]
  end

  test "number-field with only a name uses the id the number field derives" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.field type="number-field" name="qty" label="Qty" value="1" help_text="h" errors={["bad"]} />|
      )

    assert attr_of(html, "input#number_field_qty", "aria-invalid") == ["true"]

    assert attr_of(html, "input#number_field_qty", "aria-describedby") == [
             "number_field_qty-help number_field_qty-errors"
           ]

    assert_no_dangling_references(html)
  end

  for type <- ~w(radio-group checkbox-group radio-card) do
    test "#{type}: every option input carries aria" do
      assigns = %{type: unquote(type)}

      opts =
        if unquote(type) == "radio-card",
          do: [[label: "A", value: "a"], [label: "B", value: "b"]],
          else: [{"A", "a"}, {"B", "b"}]

      assigns = Map.put(assigns, :opts, opts)

      html =
        rendered_to_string(~H"""
        <.field
          type={@type}
          id="g"
          name="g"
          label="G"
          value=""
          options={@opts}
          help_text="h"
          errors={["bad"]}
        />
        """)

      sel =
        if unquote(type) == "checkbox-group",
          do: "input[type=checkbox]",
          else: "input[type=radio]"

      assert attr_of(html, sel, "aria-invalid") == ["true", "true"]
      assert attr_of(html, sel, "aria-describedby") == ["g-help g-errors", "g-help g-errors"]
      assert_no_dangling_references(html)
    end
  end

  for type <- ~w(radio-group checkbox-group) do
    test "#{type} from a FormField: every option input carries aria" do
      assigns = %{
        type: unquote(type),
        field: form_field(:role, [{"is invalid", []}])
      }

      html =
        rendered_to_string(~H"""
        <.field type={@type} field={@field} options={[{"A", "a"}, {"B", "b"}]} />
        """)

      sel =
        if unquote(type) == "checkbox-group",
          do: "input[type=checkbox]",
          else: "input[type=radio]"

      assert attr_of(html, sel, "aria-invalid") == ["true", "true"]
      assert attr_of(html, sel, "aria-describedby") == ["user_role-errors", "user_role-errors"]
      assert count(html, "#user_role-errors") == 1
    end
  end

  # Left out on purpose: the combobox draws its own control (its rest lands on
  # a roleless wrapper) and range-dual's thumbs sit in phx-update="ignore".
  # These pin that nothing is minted and the caller's attrs pass through.
  test "combobox: no ids are minted and the caller's aria passes through" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.field
        type="combobox"
        id="cb"
        name="cb"
        label="CB"
        value=""
        options={[{"A", "a"}]}
        aria-describedby="mine"
        help_text="h"
        errors={["bad"]}
      />
      """)

    assert count(html, "#cb-errors") == 0
    assert count(html, "#cb-help") == 0
    assert attr_of(html, "#cb", "aria-describedby") == ["mine"]
    assert count(html, ".pc-form-field-error") == 1
  end

  test "range-dual: no ids are minted" do
    assigns = %{
      min_field: form_field(:min, [{"too low", []}], value: 10, params: %{"min" => "10"}),
      max_field: form_field(:max, [], value: 90, params: %{"max" => "90"})
    }

    html =
      rendered_to_string(~H"""
      <.field type="range-dual" min_field={@min_field} max_field={@max_field} help_text="h" />
      """)

    assert count(html, "[id$='-errors']") == 0
    assert count(html, "[id$='-help']") == 0
    assert count(html, ".pc-form-field-error") == 1
  end
end
