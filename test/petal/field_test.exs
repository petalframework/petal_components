defmodule PetalComponents.FieldTest do
  use ComponentCase
  import PetalComponents.Field

  test "field as text" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          field={@form[:name]}
          placeholder="eg. Sally"
          class="!w-max"
          itemid="something"
          value="John"
          help_text="Help text"
          label_class="label-class"
        />
      </.form>
      """)

    assert html =~ "label"
    assert html =~ "Name"
    assert html =~ "input"
    assert html =~ "Sally"
    assert html =~ "user[name]"
    assert html =~ "itemid"
    assert html =~ "something"
    refute html =~ " disabled "
    assert html =~ "pc-text-input"
    assert html =~ "!w-max"
    assert html =~ ~s|value="John"|
    assert html =~ "Help text"
    assert html =~ "label-class"
  end

  test "Unedited field as text with field errors" do
    assigns = %{
      field: %Phoenix.HTML.FormField{
        errors: [
          {"can't be blank", [validation: :required]},
          {"too short!", [validation: :length]}
        ],
        name: "name",
        value: "",
        field: :name,
        id: "name",
        form: %Phoenix.HTML.Form{
          params: %{"_unused_name" => ""}
        }
      }
    }

    html =
      rendered_to_string(~H"""
      <.field field={@field} />
      """)

    assert html =~ "name"
    assert html =~ "Name"
    refute html =~ "pc-form-field-error"
    refute html =~ html_escape("can't be blank")
    refute html =~ html_escape("too short!")
  end

  test "Edited field as text with field errors" do
    assigns = %{
      field: %Phoenix.HTML.FormField{
        errors: [
          {"can't be blank", [validation: :required]},
          {"too short!", [validation: :length]}
        ],
        name: "name",
        value: "",
        field: :name,
        id: "name",
        form: %Phoenix.HTML.Form{
          params: %{"name" => ""}
        }
      }
    }

    html =
      rendered_to_string(~H"""
      <.field field={@field} />
      """)

    assert html =~ "name"
    assert html =~ "Name"
    assert html =~ "pc-form-field-error"
    assert html =~ html_escape("can't be blank")
    assert html =~ html_escape("too short!")
  end

  test "field as text with custom errors" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          label="Name"
          value=""
          name="name"
          errors={[
            "can't be blank",
            "too short!"
          ]}
        />
      </.form>
      """)

    assert html =~ "pc-form-field-error"
    assert html =~ html_escape("can't be blank")
    assert html =~ html_escape("too short!")
  end

  test "field standard inputs" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field field={@form[:name]} type="color" />
        <.field field={@form[:name]} type="date" />
        <.field field={@form[:name]} type="datetime-local" />
        <.field field={@form[:name]} type="email" />
        <.field field={@form[:name]} type="file" />
        <.field field={@form[:name]} type="hidden" />
        <.field field={@form[:name]} type="month" />
        <.field field={@form[:name]} type="number" />
        <.field field={@form[:name]} type="password" />
        <.field field={@form[:name]} type="range" />
        <.field field={@form[:name]} type="search" />
        <.field field={@form[:name]} type="tel" />
        <.field field={@form[:name]} type="text" />
        <.field field={@form[:name]} type="time" />
        <.field field={@form[:name]} type="url" />
        <.field field={@form[:name]} type="week" />
      </.form>
      """)

    assert html =~ "input"
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

  test "field text disabled" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field disabled field={@form[:name]} />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ "user[name]"
    assert html =~ "disabled"
  end

  test "field checkbox" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field type="checkbox" field={@form[:read_terms]} itemid="something" />
      </.form>
      """)

    assert html =~ "checkbox"
    assert html =~ "user[read_terms]"
    assert html =~ "itemid"

    # It includes a hidden field for when the switch is not checked
    assert html =~ ~s|<input type="hidden" name="user[read_terms]" value="false">|
  end

  test "field select" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          type="select"
          class="custom-class"
          field={@form[:role]}
          options={[Admin: "admin", User: "user"]}
          itemid="something"
        />
      </.form>
      """)

    assert html =~ "<select"
    assert html =~ "user[role]"
    assert html =~ "itemid"
    assert html =~ "<option"
    assert html =~ "admin"
    assert html =~ "Admin"
    assert html =~ "custom-class"
  end

  test "field select selected attributes" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          type="select"
          class="custom-class"
          field={@form[:role]}
          options={[Admin: "admin", User: "user"]}
          itemid="something"
          selected="admin"
        />
      </.form>
      """)

    assert html =~ "option selected"
  end

  test "field textarea" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          class="custom-class"
          type="textarea"
          field={@form[:description]}
          itemid="something"
          placeholder="dummy text"
          rows="8"
        />
      </.form>
      """)

    assert html =~ "<textarea"
    assert html =~ "user[description]"
    assert html =~ "itemid"
    assert html =~ "placeholder"
    assert html =~ "dummy text"
    assert html =~ "custom-class"
    assert html =~ "rows=\"8\""
  end

  test "field checkbox-group" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          class="custom-class"
          type="checkbox-group"
          field={@form[:roles]}
          options={[{"Read", "read"}, {"Write", "write"}]}
        />
      </.form>
      """)

    assert html =~ "checkbox"
    assert html =~ "user[roles][]"
    assert html =~ "Read"
    assert html =~ "Write"
    refute html =~ " checked "
    assert html =~ "hidden"
    assert html =~ "custom-class"
  end

  test "field checkbox-group disabled_options" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          type="checkbox-group"
          field={@form[:roles]}
          options={[{"Option 1", "1"}, {"Option 2", "2"}, {"Option 3", "3"}]}
          disabled_options={["1", "3"]}
        />
      </.form>
      """)

    assert html =~ "disabled"
    count_disabled = length(String.split(html, "disabled")) - 1
    assert count_disabled == 2
  end

  test "field checkbox-group checked" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          type="checkbox-group"
          checked={["read"]}
          field={@form[:roles]}
          options={[{"Read", "read"}, {"Write", "write"}]}
        />
      </.form>
      """)

    assert html =~ " checked "

    assigns = %{form: to_form(%{"roles" => ["read"]}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          class="custom-class"
          type="checkbox-group"
          field={@form[:roles]}
          options={[{"Read", "read"}, {"Write", "write"}]}
        />
      </.form>
      """)

    assert html =~ " checked "
  end

  test "field checkbox-group group_layout" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          type="checkbox-group"
          checked={["read"]}
          field={@form[:roles]}
          group_layout="col"
          options={[{"Read", "read"}, {"Write", "write"}]}
        />
      </.form>
      """)

    assert html =~ "pc-checkbox-group--col"

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          type="checkbox-group"
          checked={["read"]}
          field={@form[:roles]}
          group_layout="row"
          options={[{"Read", "read"}, {"Write", "write"}]}
        />
      </.form>
      """)

    assert html =~ "pc-checkbox-group--row"
  end

  test "field checkbox-group empty options" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          type="checkbox-group"
          checked={["read"]}
          field={@form[:roles]}
          options={[]}
          empty_message="No options"
        />
      </.form>
      """)

    assert html =~ "No options"

    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          type="checkbox-group"
          checked={["read"]}
          field={@form[:roles]}
          options={[{"Read", "read"}, {"Write", "write"}]}
          empty_message="No options"
        />
      </.form>
      """)

    refute html =~ "No options"
  end

  test "field radio-group" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          class="custom-class"
          type="radio-group"
          field={@form[:roles]}
          options={[{"Read", "read"}, {"Write", "write"}]}
        />
      </.form>
      """)

    assert html =~ "radio"
    assert html =~ "user[roles]"
    assert html =~ "Read"
    assert html =~ "Write"
    refute html =~ " checked "
    assert html =~ "hidden"
    assert html =~ "custom-class"
  end

  test "field radio-group checked on form field" do
    assigns = %{form: to_form(%{"roles" => "write"}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          class="custom-class"
          type="radio-group"
          field={@form[:roles]}
          options={[{"Read", "read"}, {"Write", "write"}]}
        />
      </.form>
      """)

    assert html =~ ~s|value="write" checked|

    # Test when value is an integer
    assigns = %{form: to_form(%{"roles" => 2}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          class="custom-class"
          type="radio-group"
          field={@form[:roles]}
          options={[{"Read", "1"}, {"Write", "2"}]}
        />
      </.form>
      """)

    assert html =~ ~s|value="2" checked|
  end

  test "field radio-group checked attr" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          class="custom-class"
          type="radio-group"
          field={@form[:roles]}
          checked="write"
          options={[{"Read", "read"}, {"Write", "write"}]}
        />
      </.form>
      """)

    assert html =~ ~s|value="write" checked|
  end

  test "field radio-group empty options" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          class="custom-class"
          type="radio-group"
          field={@form[:roles]}
          options={[]}
          empty_message="No options"
        />
      </.form>
      """)

    assert html =~ "No options"

    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          class="custom-class"
          type="radio-group"
          field={@form[:roles]}
          options={[{"Read", "read"}, {"Write", "write"}]}
          empty_message="No options"
        />
      </.form>
      """)

    refute html =~ "No options"
  end

  test "field radio-card" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          class="custom-class"
          type="radio-card"
          group_layout="col"
          field={@form[:plans]}
          options={[
            %{label: "Basic Plan", value: "basic"},
            %{label: "Pro Plan", value: "pro", description: "Most popular choice"}
          ]}
        />
      </.form>
      """)

    assert html =~ "radio"
    assert html =~ "user[plans]"
    assert html =~ "pc-radio-card-group--col"
    assert html =~ "Basic Plan"
    assert html =~ "Pro Plan"
    refute html =~ " checked "
    assert html =~ "hidden"
    assert html =~ "custom-class"
  end

  test "field radio-card group_layout attr" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field type="radio-card" field={@form[:plans]} />
      </.form>
      """)

    assert html =~ "pc-radio-card-group--row"
  end

  test "field radio-card checked on form field" do
    assigns = %{form: to_form(%{"plans" => "pro"}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          class="custom-class"
          type="radio-card"
          field={@form[:plans]}
          options={[
            %{label: "Basic Plan", value: "basic"},
            %{label: "Pro Plan", value: "pro", description: "Most popular choice"}
          ]}
        />
      </.form>
      """)

    assert html =~ ~s|value="pro" checked|

    # Test when value is an integer
    assigns = %{form: to_form(%{"plans" => 2}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          class="custom-class"
          type="radio-card"
          field={@form[:plans]}
          options={[
            %{label: "Basic Plan", value: "1"},
            %{label: "Pro Plan", value: "2", description: "Most popular choice"}
          ]}
        />
      </.form>
      """)

    assert html =~ ~s|value="2" checked|
  end

  test "field radio-card checked attr" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          class="custom-class"
          type="radio-card"
          field={@form[:plans]}
          checked="pro"
          options={[
            %{label: "Basic Plan", value: "basic"},
            %{label: "Pro Plan", value: "pro", description: "Most popular choice"}
          ]}
        />
      </.form>
      """)

    assert html =~ ~s|value="pro" checked|
  end

  test "field radio-card empty options" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field type="radio-card" field={@form[:plans]} empty_message="No options" />
      </.form>
      """)

    assert html =~ "No options"

    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          class="custom-class"
          type="radio-card"
          field={@form[:plans]}
          options={[
            %{label: "Basic Plan", value: "basic"},
            %{label: "Pro Plan", value: "pro", description: "Most popular choice"}
          ]}
          empty_message="No options"
        />
      </.form>
      """)

    refute html =~ "No options"
  end

  test "field switch and size" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field type="switch" field={@form[:read_terms]} data-extra="true" />
      </.form>
      """)

    assert html =~ "checkbox"
    assert html =~ "user[read_terms]"
    assert html =~ "data-extra"

    # It includes a hidden field for when the switch is not checked
    assert html =~ ~s|<input type="hidden" name="user[read_terms]" value="false">|

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field type="switch" size="xs" field={@form[:read_terms]} data-extra="true" />
      </.form>
      """)

    assert html =~ "pc-switch pc-switch--xs"
  end

  test "field radio group" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          type="radio-group"
          field={@form[:read_terms]}
          options={[{"Read", "read"}, {"Write", "write"}]}
          data-extra="true"
        />
      </.form>
      """)

    assert html =~ "checkbox"
    assert html =~ "user[read_terms]"
    assert html =~ "data-extra"
  end

  test "field with copyable" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          field={@form[:text]}
          placeholder="This is just a placeholder"
          value="https://example.com/invite/your-invite-code"
          label="Copyable"
          copyable
        />
      </.form>
      """)

    assert html =~ "<label"
    assert html =~ "Copyable"
    assert html =~ "<input"
    assert html =~ ~s|type="text"|
    assert html =~ "readonly"
    assert html =~ ~s|value="https://example.com/invite/your-invite-code"|
    assert html =~ "pc-copyable-field-button"
    assert html =~ "clipboard-document-solid"
    assert html =~ "pc-copyable-field-icon"
    assert html =~ "x-data"
    assert html =~ ~s|x-ref="copyInput"|
    assert html =~ "@click"
    assert html =~ "x-show"
  end

  test "field with viewable" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          type="password"
          field={@form[:password]}
          label="Viewable"
          placeholder="Placeholder"
          viewable
        />
      </.form>
      """)

    assert html =~ "<label"
    assert html =~ "Viewable"
    assert html =~ "<input"
    assert html =~ "x-bind:type"
    assert html =~ "x-data"
    assert html =~ "@click"
    assert html =~ "x-show"
    assert html =~ "pc-password-field-toggle-button"
    assert html =~ "hero-eye-solid"
    assert html =~ "pc-password-field-toggle-icon"
  end

  test "field with clearable" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field field={@form[:text]} placeholder="Enter text" label="Clearable" type="text" clearable />
      </.form>
      """)

    assert html =~ "<label"
    assert html =~ "Clearable"
    assert html =~ "<input"
    assert html =~ ~s|type="text"|
    assert html =~ "pc-clearable-field-button"
    assert html =~ "hero-x-mark-solid"
    assert html =~ "pc-clearable-field-icon"
    assert html =~ "x-data"
    assert html =~ "x-on:input"
    assert html =~ "x-on:click"
    assert html =~ "x-show"
  end

  test "field_help_text" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.field_help_text help_text="Inline" />
      """)

    assert html =~ "Inline"

    html =
      rendered_to_string(~H"""
      <.field_help_text>Utilising slot</.field_help_text>
      """)

    assert html =~ "Utilising slot"

    html =
      rendered_to_string(~H"""
      <.field_help_text class="mt-1" help_text="Test class" />
      """)

    assert html =~ "Test class"
    assert html =~ "mt-1"

    html =
      rendered_to_string(~H"""
      <.field_help_text />
      """)

    refute html =~ "pc-form-help-text"
  end

  test "required fields" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field required type="textarea" field={@form[:textarea]} />
        <.field required type="text" field={@form[:text]} />
        <.field required type="switch" field={@form[:switch]} />
        <.field required type="checkbox" field={@form[:checkbox]} />
        <.field required type="color" field={@form[:color]} />
        <.field required type="date" field={@form[:date]} />
        <.field required type="datetime-local" field={@form[:datetime_local]} />
        <.field required type="email" field={@form[:email]} />
        <.field required type="file" field={@form[:file]} />
        <.field required type="month" field={@form[:month]} />
        <.field required type="number" field={@form[:number]} />
        <.field required type="password" field={@form[:password]} />
        <.field required type="range" field={@form[:range]} />
        <.field required type="search" field={@form[:search]} />
        <.field required type="tel" field={@form[:tel]} />
        <.field required type="time" field={@form[:time]} />
        <.field required type="url" field={@form[:url]} />
        <.field required type="week" field={@form[:week]} />
        <.field required type="select" field={@form[:select]} options={["1"]} />
        <.field required type="checkbox-group" field={@form[:checkbox_group]} options={["1"]} />
        <.field required type="radio-group" field={@form[:radio_group]} options={["1"]} />
      </.form>
      """)

    assert count_substring(html, "pc-label--required") == 21

    # Check for setting the `required` attribute on the element
    # We check for 19 because `checkbox-group` and `radio-group` have multiple inputs so we don't put `required` on any of them
    assert count_substring(html, " required") == 19

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field type="textarea" field={@form[:textarea]} />
        <.field type="text" field={@form[:text]} />
        <.field type="switch" field={@form[:switch]} />
        <.field type="checkbox" field={@form[:checkbox]} />
        <.field type="color" field={@form[:color]} />
        <.field type="date" field={@form[:date]} />
        <.field type="datetime-local" field={@form[:datetime_local]} />
        <.field type="email" field={@form[:email]} />
        <.field type="file" field={@form[:file]} />
        <.field type="month" field={@form[:month]} />
        <.field type="number" field={@form[:number]} />
        <.field type="password" field={@form[:password]} />
        <.field type="range" field={@form[:range]} />
        <.field type="search" field={@form[:search]} />
        <.field type="tel" field={@form[:tel]} />
        <.field type="time" field={@form[:time]} />
        <.field type="url" field={@form[:url]} />
        <.field type="week" field={@form[:week]} />
        <.field type="select" field={@form[:select]} options={["1"]} />
        <.field type="checkbox-group" field={@form[:checkbox_group]} options={["1"]} />
        <.field type="radio-group" field={@form[:radio_group]} options={["1"]} />
      </.form>
      """)

    assert count_substring(html, "pc-label--required") == 0
    assert count_substring(html, " required") == 0
  end

  defmodule Extension do
    @behaviour PetalComponents.Field.Extension
    @impl true
    def render(assigns) do
      ~H'''
      <input id={@id} field={@name} value={@value} class={@class} datalist={@datalist} {@rest}/>
      <datalist id={@datalist}>
        <option :for={{value, option} <- @options} value={value}><%= option %></option>
      </datalist>
      '''
    end

    @impl true
    def get_class_for_type("locale"), do: "pc--test--class"
  end

  test "extension field" do
    Application.put_env(:petal_components, :field_type_extensions, locale: PetalComponents.FieldTest.Extension)

    on_exit(fn ->
      Application.delete_env(:petal_components, :field_type_extensions)
    end)

    assigns = %{form: to_form(%{}, as: :user)}
    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.field
          id="123"
          type={%{type: "locale", datalist: "locales"}}
          field={@form[:name]}
          options={[]}
          placeholder="eg. Sally"
          class="!w-max"
          itemid="something"
          value="John"
        />
      </.form>
      """)

    assert count_substring(html, ~s(<input id="123" field="user[name]" value="John" class="!w-max pc--test--class" datalist="locales")) == 1
    assert count_substring(html, ~s(<datalist id="locales">\n  \n</datalist>)) == 1
  end
end
