defmodule PetalComponents.FormTest do
  use ComponentCase
  import PetalComponents.Form

  test "text_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.text_input form={f} field={:name} placeholder="eg. John" class="!w-max" itemid="something" />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "John"
    assert html =~ "user[name]"
    assert html =~ "itemid"
    assert html =~ "something"
    refute html =~ " disabled "
    assert html =~ "pc-text-input"
    assert html =~ "!w-max"
  end

  test "text_input disabled" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.text_input disabled form={f} field={:name} placeholder="eg. John" itemid="something" />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "John"
    assert html =~ "user[name]"
    assert html =~ "itemid"
    assert html =~ "something"
    assert html =~ "pc-text-input"
    assert html =~ " disabled "
  end

  test "textarea" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.textarea form={f} field={:description} itemid="something" placeholder="dummy text" />
      </.form>
      """)

    assert html =~ "<textarea"
    assert html =~ "user[description]"
    assert html =~ "itemid"
    assert html =~ "placeholder"
    assert html =~ "dummy text"
  end

  test "select" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.select form={f} field={:role} options={[Admin: "admin", User: "user"]} itemid="something" />
      </.form>
      """)

    assert html =~ "<select"
    assert html =~ "user[role]"
    assert html =~ "itemid"
    assert html =~ "<option"
    assert html =~ "admin"
    assert html =~ "Admin"
  end

  test "checkbox" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.checkbox form={f} field={:read_terms} itemid="something" />
      </.form>
      """)

    assert html =~ "checkbox"
    assert html =~ "user[read_terms]"
    assert html =~ "itemid"
  end

  test "checkbox_group" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.checkbox_group form={f} field={:roles} options={[{"Read", "read"}, {"Write", "write"}]} />
      </.form>
      """)

    assert html =~ "checkbox"
    assert html =~ "user_roles"
    assert html =~ "user_roles_read"
    assert html =~ "user_roles_write"
    assert html =~ "user[roles][]"
    assert html =~ "Read"
    assert html =~ "Write"
    refute html =~ "checked"

    # Test "checked" attribute
    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.checkbox_group
          checked={["read"]}
          form={f}
          field={:roles}
          options={[{"Read", "read"}, {"Write", "write"}]}
        />
      </.form>
      """)

    assert html =~ "checked"
  end

  test "switch" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.switch form={f} field={:read_terms} itemid="something" />
      </.form>
      """)

    assert html =~ "checkbox"
    assert html =~ "user[read_terms]"
    assert html =~ "itemid"
    assert html =~ "sr-only"
    assert html =~ "peer"
  end

  test "radio" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.radio form={f} field={:eye_color} value="green" itemid="something" />
      </.form>
      """)

    assert html =~ "radio"
    assert html =~ "user[eye_color]"
    assert html =~ "green"
    assert html =~ "itemid"
  end

  test "form_label" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.form_label form={f} field={:name} class="text-pink-500" />
      </.form>
      """)

    assert html =~ "label"
    assert html =~ "Name"
    assert html =~ "text-pink-500"

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.form_label form={f} field={:name}>
          Something else
        </.form_label>
      </.form>
      """)

    assert html =~ "Something else"

    html =
      rendered_to_string(~H"""
      <.form_label>Simple</.form_label>
      """)

    assert html =~ "Simple"

    html =
      rendered_to_string(~H"""
      <.form_label label="Simpler" />
      """)

    assert html =~ "Simpler"
  end

  test "form_field_error" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form
        :let={f}
        as={:user}
        for={
          %Ecto.Changeset{
            action: :update,
            data: %{name: ""},
            errors: [
              name: {"can't be blank", [validation: :required]},
              name: {"too long", [validation: :required]}
            ],
            params: %{"name" => ""}
          }
        }
      >
        <.form_field_error form={f} field={:name} class="mt-1" />
      </.form>
      """)

    assert html =~ "pc-form-field-error"
    assert html =~ "blank"
    assert html =~ "too long"
  end

  test "Unedited form_field with error does not show errors" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form
        :let={f}
        as={:user}
        for={
          %Ecto.Changeset{
            action: :update,
            data: %{password: ""},
            errors: [
              password: {"can't be blank", [validation: :required]}
            ],
            # Simulate user only interacted with email field
            params: %{
              "_unused_password" => ""
            }
          }
        }
      >
        <.form_field type="password_input" form={f} field={:password} />
      </.form>
      """)

    # Password field (unused) should not show error
    refute html =~ "has-error"
    refute html =~ "can&#39;t be blank"
  end

  test "Edited form_field with error shows errors" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form
        :let={f}
        as={:user}
        for={
          %Ecto.Changeset{
            action: :update,
            data: %{password: ""},
            errors: [
              password: {"can't be blank", [validation: :required]}
            ],
            # Simulate user only interacted with email field
            params: %{
              "password" => ""
            }
          }
        }
      >
        <.form_field type="password_input" form={f} field={:password} />
      </.form>
      """)

    # Password field (unused) should not show error
    assert html =~ "has-error"
    assert html =~ "can&#39;t be blank"
  end

  test "form_help_text" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form_help_text help_text="Inline" />
      """)

    assert html =~ "Inline"

    html =
      rendered_to_string(~H"""
      <.form_help_text>Utilising slot</.form_help_text>
      """)

    assert html =~ "Utilising slot"

    html =
      rendered_to_string(~H"""
      <.form_help_text class="mt-1" help_text="Test class" />
      """)

    assert html =~ "Test class"
    assert html =~ "mt-1"

    html =
      rendered_to_string(~H"""
      <.form_help_text />
      """)

    refute html =~ "pc-form-help-text"
  end

  test "form_field wrapper_classes" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form
        :let={f}
        as={:user}
        for={
          %Ecto.Changeset{
            action: :update,
            data: %{name: ""},
            errors: [
              name: {"can't be blank", [validation: :required]},
              name: {"too long", [validation: :required]}
            ],
            params: %{"name" => ""}
          }
        }
      >
        <.form_field
          type="text_input"
          form={f}
          field={:name}
          placeholder="eg. John"
          wrapper_classes="wrapper-test"
          help_text="Help!"
        />
      </.form>
      """)

    assert html =~ "label"
    assert html =~ "<input"
    assert html =~ "user[name]"
    assert html =~ "John"
    assert html =~ "too long"
    assert html =~ "blank"
    assert html =~ "<div class=\"wrapper-test\">"
    assert html =~ "Help!"
  end

  test "form_field label_class" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} as={:user} for={%Ecto.Changeset{action: :update, data: %{name: ""}}}>
        <.form_field type="text_input" form={f} field={:name} label_class="label-class-test" />
      </.form>
      """)

    assert html =~ "label-class-test"
  end

  test "form_field text_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form
        :let={f}
        as={:user}
        for={
          %Ecto.Changeset{
            action: :update,
            data: %{name: ""},
            errors: [
              name: {"can't be blank", [validation: :required]},
              name: {"too long", [validation: :required]}
            ],
            params: %{"name" => ""}
          }
        }
      >
        <.form_field type="text_input" form={f} field={:name} class="w-max" placeholder="eg. John" />
      </.form>
      """)

    assert html =~ "label"
    assert html =~ "<input"
    assert html =~ "user[name]"
    assert html =~ "John"
    assert html =~ "too long"
    assert html =~ "blank"
    assert html =~ "pc-form-field-wrapper"
    assert html =~ "pc-text-input"
    assert html =~ "w-max"
  end

  test "form_fields generate appropriate label and inputs" do
    assigns = %{}

    html =
      ~H"""
      <.form :let={f} as={:user} for={%{}}>
        <.form_field type="text_input" form={f} field={:name} />
      </.form>
      """
      |> rendered_to_string()
      |> LazyHTML.from_fragment()

    assert LazyHTML.query(html, "label.pc-label") |> Enum.any?()
    assert LazyHTML.query(html, "input[type='text']") |> Enum.any?()

    html =
      ~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.form_field type="time_input" form={f} field={:name} />
      </.form>
      """
      |> rendered_to_string()
      |> LazyHTML.from_fragment()

    assert LazyHTML.query(html, "label.pc-label") |> Enum.any?()
    assert LazyHTML.query(html, "input[type='time']") |> Enum.any?()

    html =
      ~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.form_field
          type="checkbox_group"
          form={f}
          field={:roles}
          options={[{"Read", "read"}, {"Write", "write"}]}
        />
      </.form>
      """
      |> rendered_to_string()
      |> LazyHTML.from_fragment()

    assert LazyHTML.query(html, "span.pc-label") |> Enum.any?()
    assert LazyHTML.query(html, "input[type='checkbox']") |> Enum.any?()

    html =
      ~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.form_field
          type="radio_group"
          form={f}
          field={:roles}
          options={[{"Read", "read"}, {"Write", "write"}]}
        />
      </.form>
      """
      |> rendered_to_string()
      |> LazyHTML.from_fragment()

    assert LazyHTML.query(html, "span.pc-label") |> Enum.any?()
    assert LazyHTML.query(html, "input[type='radio']") |> Enum.any?()

    html =
      ~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.form_field type="time_select" form={f} field={:time} />
      </.form>
      """
      |> rendered_to_string()
      |> LazyHTML.from_fragment()

    assert LazyHTML.query(html, "span.pc-label") |> Enum.any?()
    assert LazyHTML.query(html, "select") |> Enum.any?()

    html =
      ~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.form_field type="datetime_select" form={f} field={:date_time} />
      </.form>
      """
      |> rendered_to_string()
      |> LazyHTML.from_fragment()

    assert LazyHTML.query(html, "span.pc-label") |> Enum.any?()
    assert LazyHTML.query(html, "select") |> Enum.any?()

    html =
      ~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.form_field type="datetime_local_input" form={f} field={:date_time} />
      </.form>
      """
      |> rendered_to_string()
      |> LazyHTML.from_fragment()

    assert LazyHTML.query(html, "label.pc-label") |> Enum.any?()
    assert LazyHTML.query(html, "input[type='datetime-local']") |> Enum.any?()

    html =
      ~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.form_field type="date_select" form={f} field={:date} />
      </.form>
      """
      |> rendered_to_string()
      |> LazyHTML.from_fragment()

    assert LazyHTML.query(html, "span.pc-label") |> Enum.any?()
    assert LazyHTML.query(html, "select") |> Enum.any?()

    # Date input
    html =
      ~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.form_field type="date_input" form={f} field={:date} />
      </.form>
      """
      |> rendered_to_string()
      |> LazyHTML.from_fragment()

    assert LazyHTML.query(html, "label.pc-label") |> Enum.any?()
    assert LazyHTML.query(html, "input[type='date']") |> Enum.any?()
  end

  test "form_field checkbox_group label" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.form_field
          type="checkbox_group"
          form={f}
          field={:roles}
          options={[{"Read", "read"}, {"Write", "write"}]}
        />
      </.form>
      """)

    assert html =~ "span"
    assert html =~ "Roles"

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.form_field
          type="checkbox_group"
          form={f}
          field={:roles}
          label="Something else"
          options={[{"Read", "read"}, {"Write", "write"}]}
        />
      </.form>
      """)

    assert html =~ "Something else"
  end

  test "form_field checkbox label" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} as={:user} for={%Ecto.Changeset{action: :update, data: %{name: ""}}}>
        <.form_field type="checkbox" form={f} field={:name} />
      </.form>
      """)

    assert html =~ "Name"

    html =
      rendered_to_string(~H"""
      <.form :let={f} as={:user} for={%Ecto.Changeset{action: :update, data: %{name: ""}}}>
        <.form_field type="checkbox" form={f} field={:name} label="Something else" />
      </.form>
      """)

    assert html =~ "Something else"
  end

  test "number_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.number_input form={f} field={:name} itemid="something" />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "number"
    assert html =~ "user[name]"
    assert html =~ "itemid"
    assert html =~ "something"
  end

  test "email_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.email_input form={f} field={:name} itemid="something" />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "email"
    assert html =~ "user[name]"
    assert html =~ "itemid"
    assert html =~ "something"
  end

  test "password_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.password_input form={f} field={:name} itemid="something" />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "password"
    assert html =~ "user[name]"
    assert html =~ "itemid"
    assert html =~ "something"
  end

  test "search_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.search_input form={f} field={:name} itemid="something" />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "search"
    assert html =~ "user[name]"
    assert html =~ "itemid"
    assert html =~ "something"
  end

  test "telephone_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.telephone_input form={f} field={:name} itemid="something" />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "tel"
    assert html =~ "user[name]"
    assert html =~ "itemid"
    assert html =~ "something"
  end

  test "url_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.url_input form={f} field={:name} itemid="something" />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "url"
    assert html =~ "user[name]"
    assert html =~ "itemid"
    assert html =~ "something"
  end

  test "time_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.time_input form={f} field={:name} itemid="something" />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "time"
    assert html =~ "user[name]"
    assert html =~ "itemid"
    assert html =~ "something"
  end

  test "time_select" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.time_select form={f} field={:name} />
      </.form>
      """)

    assert html =~ "select"
    assert html =~ "user[name]"
  end

  test "datetime_local_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.datetime_local_input form={f} field={:name} itemid="something" />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "datetime-local"
    assert html =~ "user[name]"
    assert html =~ "itemid"
    assert html =~ "something"
  end

  test "datetime_select" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.datetime_select form={f} field={:name} />
      </.form>
      """)

    assert html =~ "select"
    assert html =~ "user[name]"
  end

  test "date_select" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.date_select form={f} field={:name} />
      </.form>
      """)

    assert html =~ "select"
    assert html =~ "user[name]"
  end

  test "date_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.date_input form={f} field={:name} itemid="something" />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "date"
    assert html =~ "user[name]"
    assert html =~ "itemid"
    assert html =~ "something"
  end

  test "color_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.color_input form={f} field={:name} itemid="something" />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "color"
    assert html =~ "user[name]"
    assert html =~ "itemid"
    assert html =~ "something"
  end

  test "file_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user} multipart>
        <.file_input form={f} field={:name} itemid="something" />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "file"
    assert html =~ "user[name]"
    assert html =~ "itemid"
    assert html =~ "something"
    assert html =~ "pc-file-input"
  end

  test "range_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.range_input form={f} field={:name} itemid="something" />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "range"
    assert html =~ "user[name]"
    assert html =~ "itemid"
    assert html =~ "something"
  end

  test "hidden_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:user}>
        <.hidden_input form={f} field={:token} itemid="something" />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "hidden"
    assert html =~ "token"
    assert html =~ "user[token]"
    assert html =~ "itemid"
    assert html =~ "something"
  end

  test "dual range slider (range_dual) renders with Alpine.js" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:filter}>
        <.form_field
          type="range_dual"
          form={f}
          field={:price}
          label="Price Range"
          range_min={0}
          range_max={1000}
          step={10}
          min_field={%{name: "min_price", value: 100}}
          max_field={%{name: "max_price", value: 500}}
        />
      </.form>
      """)

    # Check for label
    assert html =~ "Price Range"

    # Check for Alpine.js directives
    assert html =~ "x-data"
    assert html =~ "x-ref"
    assert html =~ "rangeMin: 0"
    assert html =~ "rangeMax: 1000"
    assert html =~ "minValue: 100"
    assert html =~ "maxValue: 500"

    # Check for phx-update="ignore"
    assert html =~ ~s|phx-update="ignore"|

    # Check for range inputs
    assert html =~ ~s|name="min_price"|
    assert html =~ ~s|name="max_price"|
    assert html =~ ~s|type="range"|

    # Check for values
    assert html =~ ~s|value="100"|
    assert html =~ ~s|value="500"|

    # Check for min/max/step attributes
    assert html =~ ~s|min="0"|
    assert html =~ ~s|max="1000"|
    assert html =~ ~s|step="10"|

    # Check for slider classes
    assert html =~ "pc-slider-input"
    assert html =~ "pc-slider-track"
    assert html =~ "pc-slider-range"

    # Check for Alpine event handlers
    assert html =~ "@input"
    assert html =~ "updateMinValue"
    assert html =~ "updateMaxValue"
  end

  test "dual range slider with nil values uses range_min/range_max as defaults" do
    assigns = %{
      min_field: %{name: "min_price", value: nil},
      max_field: %{name: "max_price", value: nil}
    }

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:filter}>
        <.form_field
          type="range_dual"
          form={f}
          field={:price}
          range_min={0}
          range_max={1000}
          min_field={@min_field}
          max_field={@max_field}
        />
      </.form>
      """)

    # Should use range_min/range_max as defaults when values are nil
    assert html =~ "minValue: 0"
    assert html =~ "maxValue: 1000"
    assert html =~ ~s|value="0"|
    assert html =~ ~s|value="1000"|
  end

  test "dual range slider with negative ranges" do
    assigns = %{
      min_field: %{name: "min_temp", value: -50},
      max_field: %{name: "max_temp", value: 50}
    }

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:filter}>
        <.form_field
          type="range_dual"
          form={f}
          field={:temperature}
          range_min={-100}
          range_max={100}
          min_field={@min_field}
          max_field={@max_field}
        />
      </.form>
      """)

    assert html =~ "rangeMin: -100"
    assert html =~ "rangeMax: 100"
    assert html =~ "minValue: -50"
    assert html =~ "maxValue: 50"
    assert html =~ ~s|min="-100"|
    assert html =~ ~s|max="100"|
    assert html =~ ~s|value="-50"|
    assert html =~ ~s|value="50"|
  end

  test "dual range slider with custom formatter" do
    assigns = %{
      formatter: fn value -> "$#{value}" end,
      min_field: %{name: "min_price", value: 100},
      max_field: %{name: "max_price", value: 500}
    }

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:filter}>
        <.form_field
          type="range_dual"
          form={f}
          field={:price}
          range_min={0}
          range_max={1000}
          min_field={@min_field}
          max_field={@max_field}
          formatter={@formatter}
        />
      </.form>
      """)

    # Check that formatter is applied to labels
    assert html =~ "$0"
    assert html =~ "$100"
    assert html =~ "$500"
    assert html =~ "$1000"

    # Check that formatValue detects $ pattern in sample (HTML escaped)
    assert html =~ ~s|sample.includes(&#39;$&#39;)|
  end

  test "dual range slider with custom labels" do
    assigns = %{
      min_field: %{name: "min_price", value: 100},
      max_field: %{name: "max_price", value: 500}
    }

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:filter}>
        <.form_field
          type="range_dual"
          form={f}
          field={:price}
          range_min={0}
          range_max={1000}
          min_field={@min_field}
          max_field={@max_field}
          range_min_label="Min"
          range_max_label="Max"
        />
      </.form>
      """)

    assert html =~ "Min"
    assert html =~ "Max"
  end

  test "dual range slider handles edge case when range_min equals range_max" do
    assigns = %{
      min_field: %{name: "min_price", value: 100},
      max_field: %{name: "max_price", value: 100}
    }

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:filter}>
        <.form_field
          type="range_dual"
          form={f}
          field={:price}
          range_min={100}
          range_max={100}
          min_field={@min_field}
          max_field={@max_field}
        />
      </.form>
      """)

    # Check that component still renders with guard clause
    assert html =~ "x-data"
    assert html =~ "if (this.rangeMax === this.rangeMin)"
    assert html =~ "rangeMin: 100"
    assert html =~ "rangeMax: 100"
  end

  test "range_numeric renders with number inputs" do
    assigns = %{
      min_field: %{name: "min_price", value: 100},
      max_field: %{name: "max_price", value: 500}
    }

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:filter}>
        <.form_field
          type="range_numeric"
          form={f}
          field={:price}
          label="Price Range"
          range_min={0}
          range_max={1000}
          min_field={@min_field}
          max_field={@max_field}
        />
      </.form>
      """)

    # Check for label
    assert html =~ "Price Range"

    # Check for number inputs (form_field wraps them, so they become number inputs)
    assert html =~ ~s|type="number"|
    refute html =~ ~s|type="range"|

    # Check for field names (form_field namespaces them)
    assert html =~ ~s|name="filter[min_price]"|
    assert html =~ ~s|name="filter[max_price]"|

    # Check for placeholders
    assert html =~ "No Min"
    assert html =~ "No Max"

    # Check for min/max constraints
    assert html =~ ~s|min="0"|
    assert html =~ ~s|max="1000"|

    # Check for separator
    assert html =~ "-"
  end

  test "range_numeric with nil values" do
    assigns = %{
      min_field: %{name: "min_price", value: nil},
      max_field: %{name: "max_price", value: nil}
    }

    html =
      rendered_to_string(~H"""
      <.form :let={f} for={%{}} as={:filter}>
        <.form_field
          type="range_numeric"
          form={f}
          field={:price}
          range_min={0}
          range_max={1000}
          min_field={@min_field}
          max_field={@max_field}
        />
      </.form>
      """)

    # Should render with placeholders for nil values
    assert html =~ "No Min"
    assert html =~ "No Max"
    assert html =~ ~s|type="number"|
  end
end
