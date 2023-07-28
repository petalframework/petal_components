defmodule PetalComponents.Field do
  use Phoenix.Component

  @doc """
  Renders an input with label and error messages. If you just want an input, check out input.ex

  A `%Phoenix.HTML.FormField{}` and type may be passed to the field
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.field field={@form[:email]} type="email" />
      <.field label="Name" value="" name="name" errors={["oh no!"]} />
  """
  attr :id, :any,
    default: nil,
    doc: "the id of the input. If not passed, it will be generated automatically from the field"

  attr :name, :any,
    doc: "the name of the input. If not passed, it will be generated automatically from the field"

  attr :label, :string,
    doc:
      "the label for the input. If not passed, it will be generated automatically from the field"

  attr :value, :any,
    doc:
      "the value of the input. If not passed, it will be generated automatically from the field"

  attr :type, :string,
    default: "text",
    values:
      ~w(checkbox checkbox-group color date datetime-local email file hidden month number password
               range radio-group search select switch tel text textarea time url week),
    doc: "the type of input"

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list,
    default: [],
    doc:
      "a list of errors to display. If not passed, it will be generated automatically from the field. Format is a list of strings."

  attr :checked, :any, doc: "the checked flag for checkboxes and checkbox groups"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :disabled_options, :list, default: [], doc: "the options to disable in a checkbox group"

  attr :group_layout, :string,
    values: ["row", "col"],
    default: "row",
    doc: "the layout of the inputs in a group (checkbox-group or radio-group)"

  attr :empty_message, :string,
    default: nil,
    doc:
      "the message to display when there are no options available, for checkbox-group or radio-group"

  attr :rows, :string, default: "4", doc: "rows for textarea"

  attr :class, :string, default: nil, doc: "the class to add to the input"
  attr :wrapper_class, :string, default: nil, doc: "the wrapper div classes"
  attr :help_text, :string, default: nil, doc: "context/help for your field"
  attr :label_class, :string, default: nil, doc: "extra CSS for your label"
  attr :selected, :any, default: nil, doc: "the selected value for select inputs"

  attr :required, :boolean,
    default: false,
    doc: "is this field required? is passed to the input and adds an asterisk next to the label"

  attr :rest, :global,
    include:
      ~w(autocomplete autocorrect autocapitalize disabled form max maxlength min minlength list
    pattern placeholder readonly required size step value name multiple prompt default year month day hour minute second builder options layout cols rows wrap checked accept),
    doc: "All other props go on the input"

  def field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn ->
      if assigns.multiple && assigns.type not in ["checkbox-group", "radio-group"],
        do: field.name <> "[]",
        else: field.name
    end)
    |> assign_new(:value, fn -> field.value end)
    |> assign_new(:label, fn -> Phoenix.HTML.Form.humanize(field.field) end)
    |> field()
  end

  def field(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class}>
      <label class={["pc-checkbox-label", @label_class]}>
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          required={@required}
          class={["pc-checkbox", @class]}
          {@rest}
        />
        <div class={[@required && "pc-label--required"]}>
          <%= @label %>
        </div>
      </label>
      <.field_error :for={msg <- @errors}><%= msg %></.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: "select"} = assigns) do
    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class}>
      <.field_label required={@required} for={@id} class={@label_class}>
        <%= @label %>
      </.field_label>
      <select
        id={@id}
        name={@name}
        class={["pc-text-input", @class]}
        multiple={@multiple}
        required={@required}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @selected || @value) %>
      </select>
      <.field_error :for={msg <- @errors}><%= msg %></.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: "textarea"} = assigns) do
    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class}>
      <.field_label required={@required} for={@id} class={@label_class}>
        <%= @label %>
      </.field_label>
      <textarea
        id={@id}
        name={@name}
        class={["pc-text-input", @class]}
        rows={@rows}
        required={@required}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.field_error :for={msg <- @errors}><%= msg %></.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: "switch", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class}>
      <label class={["pc-checkbox-label", @label_class]}>
        <input type="hidden" name={@name} value="false" />
        <label class="pc-switch">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            required={@required}
            class={["sr-only peer", @class]}
            {@rest}
          />

          <span class="pc-switch__fake-input"></span>
          <span class="pc-switch__fake-input-bg"></span>
        </label>
        <div class={[@required && "pc-label--required"]}><%= @label %></div>
      </label>
      <.field_error :for={msg <- @errors}><%= msg %></.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: "checkbox-group"} = assigns) do
    assigns =
      assigns
      |> assign_new(:checked, fn ->
        values =
          case assigns.value do
            value when is_binary(value) -> [value]
            value when is_list(value) -> value
            _ -> []
          end

        Enum.map(values, &to_string/1)
      end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class}>
      <.field_label required={@required} for={@id} class={@label_class}>
        <%= @label %>
      </.field_label>
      <input type="hidden" name={@name} value="" />
      <div class={[
        "pc-checkbox-group",
        @group_layout == "row" && "pc-checkbox-group--row",
        @group_layout == "col" && "pc-checkbox-group--col",
        @class
      ]}>
        <%= for {label, value} <- @options do %>
          <label class="pc-checkbox-label">
            <input
              type="checkbox"
              name={@name <> "[]"}
              checked_value={value}
              unchecked_value=""
              value={value}
              checked={to_string(value) in @checked}
              hidden_input={false}
              class="pc-checkbox"
              disabled={value in @disabled_options}
              {@rest}
            />
            <div>
              <%= label %>
            </div>
          </label>
        <% end %>

        <%= if @empty_message && Enum.empty?(@options) do %>
          <div class="pc-checkbox-group--empty-message">
            <%= @empty_message %>
          </div>
        <% end %>
      </div>
      <.field_error :for={msg <- @errors}><%= msg %></.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: "radio-group"} = assigns) do
    assigns = assign_new(assigns, :checked, fn -> nil end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class}>
      <.field_label required={@required} for={@id} class={@label_class}>
        <%= @label %>
      </.field_label>
      <div class={[
        "pc-radio-group",
        @group_layout == "row" && "pc-radio-group--row",
        @group_layout == "col" && "pc-radio-group--col",
        @class
      ]}>
        <input type="hidden" name={@name} value="" />
        <%= for {label, value} <- @options do %>
          <label class="pc-checkbox-label">
            <input
              type="radio"
              name={@name}
              value={value}
              checked={
                to_string(value) == to_string(@value) || to_string(value) == to_string(@checked)
              }
              class="pc-radio"
              {@rest}
            />
            <div>
              <%= label %>
            </div>
          </label>
        <% end %>

        <%= if @empty_message && Enum.empty?(@options) do %>
          <div class="pc-checkbox-group--empty-message">
            <%= @empty_message %>
          </div>
        <% end %>
      </div>
      <.field_error :for={msg <- @errors}><%= msg %></.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: "hidden"} = assigns) do
    ~H"""
    <input
      type={@type}
      name={@name}
      id={@id}
      value={Phoenix.HTML.Form.normalize_value(@type, @value)}
      class={@class}
      {@rest}
    />
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def field(assigns) do
    assigns = assign(assigns, class: [assigns.class, get_class_for_type(assigns.type)])

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class}>
      <.field_label required={@required} for={@id} class={@label_class}>
        <%= @label %>
      </.field_label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={@class}
        required={@required}
        {@rest}
      />
      <.field_error :for={msg <- @errors}><%= msg %></.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  attr :class, :string, default: nil
  attr :errors, :list, default: []
  attr :name, :string
  attr :rest, :global
  slot :inner_block, required: true

  def field_wrapper(assigns) do
    ~H"""
    <div
      phx-feedback-for={@name}
      {@rest}
      class={[
        @class,
        "pc-form-field-wrapper",
        @errors != [] && "pc-form-field-wrapper--error"
      ]}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global
  attr :required, :boolean, default: false
  slot :inner_block, required: true

  def field_label(assigns) do
    ~H"""
    <label for={@for} class={["pc-label", @class, @required && "pc-label--required"]} {@rest}>
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def field_error(assigns) do
    ~H"""
    <p class="pc-form-field-error">
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  attr :class, :string, default: "", doc: "extra classes for the help text"
  attr :help_text, :string, default: nil, doc: "context/help for your field"
  slot :inner_block, required: false
  attr :rest, :global

  def field_help_text(assigns) do
    ~H"""
    <div :if={render_slot(@inner_block) || @help_text} class={["pc-form-help-text", @class]} {@rest}>
      <%= render_slot(@inner_block) || @help_text %>
    </div>
    """
  end

  defp get_class_for_type("radio"), do: "pc-radio"
  defp get_class_for_type("checkbox"), do: "pc-checkbox"
  defp get_class_for_type("color"), do: "pc-color-input"
  defp get_class_for_type("file"), do: "pc-file-input"
  defp get_class_for_type("range"), do: "pc-range-input"
  defp get_class_for_type(_), do: "pc-text-input"

  defp translate_error({msg, opts}) do
    config_translator = get_translator_from_config()

    if config_translator do
      config_translator.({msg, opts})
    else
      fallback_translate_error(msg, opts)
    end
  end

  defp fallback_translate_error(msg, opts) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      try do
        String.replace(acc, "%{#{key}}", to_string(value))
      rescue
        e ->
          IO.warn(
            """
            the fallback message translator for the form_field_error function cannot handle the given value.

            Hint: you can set up the `error_translator_function` to route all errors to your application helpers:

              config :petal_components, :error_translator_function, {MyAppWeb.CoreComponents, :translate_error}

            Given value: #{inspect(value)}

            Exception: #{Exception.message(e)}
            """,
            __STACKTRACE__
          )

          "invalid value"
      end
    end)
  end

  defp get_translator_from_config do
    case Application.get_env(:petal_components, :error_translator_function) do
      {module, function} -> &apply(module, function, [&1])
      nil -> nil
    end
  end
end
