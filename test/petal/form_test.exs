defmodule PetalComponents.FormTest do
  use ComponentCase
  import PetalComponents.Form
  import Phoenix.LiveView.Helpers

  test "text_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.text_input
          form={f}
          field={:name}
          placeholder="eg. John"
          random-element="something"
        />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "John"
    assert html =~ "user[name]"
    assert html =~ "random-element"
    assert html =~ "something"
    refute html =~ " disabled "
  end

  test "text_input disabled" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
        <.form let={f} for={:user}>
          <.text_input disabled
            form={f}
            field={:name}
            placeholder="eg. John"
            random-element="something"
          />
        </.form>
      """)

    assert html =~ "input"
    assert html =~ "John"
    assert html =~ "user[name]"
    assert html =~ "random-element"
    assert html =~ "something"
    assert html =~ "bg-gray-100"
    assert html =~ " disabled "
  end

  test "textarea" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.textarea
          form={f}
          field={:description}
          random-element="something"
          placeholder="dummy text"
        />
      </.form>
      """)

    assert html =~ "<textarea"
    assert html =~ "user[description]"
    assert html =~ "random-element"
    assert html =~ "placeholder"
    assert html =~ "dummy text"
  end

  test "select" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.select
          form={f}
          field={:role}
          options={["Admin": "admin", "User": "user"]}
          random-element="something"
        />
      </.form>
      """)

    assert html =~ "<select"
    assert html =~ "user[role]"
    assert html =~ "random-element"
    assert html =~ "<option"
    assert html =~ "admin"
    assert html =~ "Admin"
  end

  test "checkbox" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.checkbox
          form={f}
          field={:read_terms}
          random-element="something"
        />
      </.form>
      """)

    assert html =~ "checkbox"
    assert html =~ "user[read_terms]"
    assert html =~ "random-element"
  end

  test "radio" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.radio
          form={f}
          field={:eye_color}
          value="green"
          random-element="something"
        />
      </.form>
      """)

    assert html =~ "radio"
    assert html =~ "user[eye_color]"
    assert html =~ "green"
    assert html =~ "random-element"
  end

  test "form_label" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.form_label form={f} field={:name} />
      </.form>
      """)

    assert html =~ "label"
    assert html =~ "Name"

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
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
      <.form let={f} as={:user} for={%Ecto.Changeset{
        action: :update,
        data: %{name: ""},
        errors: [
          name: {"can't be blank", [validation: :required]},
          name: {"too long", [validation: :required]},
        ]}
      }>
        <.form_field_error form={f} field={:name} class="mt-1" />
      </.form>
      """)

    assert html =~ "text-red-500"
    assert html =~ "phx-feedback-for"
    assert html =~ "blank"
    assert html =~ "too long"
    assert html =~ "mt-1"
  end

  test "form_field text_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} as={:user} for={%Ecto.Changeset{
        action: :update,
        data: %{name: ""},
        errors: [
          name: {"can't be blank", [validation: :required]},
          name: {"too long", [validation: :required]},
        ]}
      }>
        <.form_field
          type="text_input"
          form={f}
          field={:name}
          placeholder="eg. John"
        />
      </.form>
      """)

    assert html =~ "label"
    assert html =~ "<input"
    assert html =~ "user[name]"
    assert html =~ "John"
    assert html =~ "too long"
    assert html =~ "blank"
  end

  test "number_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.number_input
          form={f}
          field={:name}
          random-element="something"
        />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "number"
    assert html =~ "user[name]"
    assert html =~ "random-element"
    assert html =~ "something"
  end

  test "email_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.email_input
          form={f}
          field={:name}
          random-element="something"
        />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "email"
    assert html =~ "user[name]"
    assert html =~ "random-element"
    assert html =~ "something"
  end

  test "password_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.password_input
          form={f}
          field={:name}
          random-element="something"
        />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "password"
    assert html =~ "user[name]"
    assert html =~ "random-element"
    assert html =~ "something"
  end

  test "search_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.search_input
          form={f}
          field={:name}
          random-element="something"
        />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "search"
    assert html =~ "user[name]"
    assert html =~ "random-element"
    assert html =~ "something"
  end

  test "telephone_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.telephone_input
          form={f}
          field={:name}
          random-element="something"
        />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "tel"
    assert html =~ "user[name]"
    assert html =~ "random-element"
    assert html =~ "something"
  end

  test "url_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.url_input
          form={f}
          field={:name}
          random-element="something"
        />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "url"
    assert html =~ "user[name]"
    assert html =~ "random-element"
    assert html =~ "something"
  end

  test "time_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.time_input
          form={f}
          field={:name}
          random-element="something"
        />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "time"
    assert html =~ "user[name]"
    assert html =~ "random-element"
    assert html =~ "something"
  end

  test "time_select" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.time_select
          form={f}
          field={:name}
        />
      </.form>
      """)

    assert html =~ "select"
    assert html =~ "user[name]"
  end

  test "datetime_local_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.datetime_local_input
          form={f}
          field={:name}
          random-element="something"
        />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "datetime-local"
    assert html =~ "user[name]"
    assert html =~ "random-element"
    assert html =~ "something"
  end

  test "datetime_select" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.datetime_select
          form={f}
          field={:name}
        />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "select"
    assert html =~ "user[name]"
  end

  test "date_select" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.date_select
          form={f}
          field={:name}
        />
      </.form>
      """)

    assert html =~ "select"
    assert html =~ "user[name]"
  end

  test "date_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.date_input
          form={f}
          field={:name}
          random-element="something"
        />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "date"
    assert html =~ "user[name]"
    assert html =~ "random-element"
    assert html =~ "something"
  end

  test "color_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.color_input
          form={f}
          field={:name}
          random-element="something"
        />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "color"
    assert html =~ "user[name]"
    assert html =~ "random-element"
    assert html =~ "something"
  end

  test "file_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user} multipart>
        <.file_input
          form={f}
          field={:name}
          random-element="something"
        />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "file"
    assert html =~ "user[name]"
    assert html =~ "random-element"
    assert html =~ "something"
    assert html =~ "bg-primary"
  end

  test "range_input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.range_input
          form={f}
          field={:name}
          random-element="something"
        />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "range"
    assert html =~ "user[name]"
    assert html =~ "random-element"
    assert html =~ "something"
  end

  test "text_input dark mode" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form let={f} for={:user}>
        <.text_input
          form={f}
          field={:name}
          placeholder="eg. John"
          random-element="something"
        />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "John"
    assert html =~ "user[name]"
    assert html =~ "random-element"
    assert html =~ "something"
    assert html =~ "dark:"
    refute html =~ " disabled "
  end
end
