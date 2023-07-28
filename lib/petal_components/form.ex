defmodule PetalComponents.Form do
  use Phoenix.Component

  import PetalComponents.Helpers
  alias Phoenix.HTML.Form

  @form_attrs ~w(autocomplete autocorrect autocapitalize disabled form max maxlength min minlength list
  pattern placeholder readonly required size step value name multiple prompt selected default year month day hour minute second builder options layout cols rows wrap checked accept)

  @checkbox_form_attrs ~w(checked_value unchecked_value checked hidden_input) ++ @form_attrs

  @moduledoc """
  Everything related to forms: inputs, labels etc

  Deprecated in favor of field.ex and input.ex, which use the new `%Phoenix.HTML.FormField{}` struct.
  """

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, doc: "CSS classes to add to your label")
  slot(:inner_block, required: false)
  attr(:rest, :global, include: ~w(for))

  def form_label(assigns) do
    assigns =
      assigns
      |> assign(:classes, label_classes(assigns))

    ~H"""
    <%= if @form && @field do %>
      <%= Form.label @form, @field, [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest) do %>
        <%= render_slot(@inner_block) || @label || Form.humanize(@field) %>
      <% end %>
    <% else %>
      <label class={@classes} {@rest}>
        <%= render_slot(@inner_block) || @label || Form.humanize(@field) %>
      </label>
    <% end %>
    """
  end

  @input_types [
    "text_input",
    "email_input",
    "number_input",
    "password_input",
    "search_input",
    "telephone_input",
    "url_input",
    "time_input",
    "time_select",
    "date_input",
    "date_select",
    "datetime_local_input",
    "datetime_select",
    "color_input",
    "file_input",
    "range_input",
    "textarea",
    "select",
    "checkbox",
    "checkbox_group",
    "radio_group",
    "switch",
    "hidden_input"
  ]

  attr(:form, :any, doc: "the form object", required: true)
  attr(:field, :atom, doc: "field in changeset / form", required: true)
  attr(:label, :string, doc: "labels your field")
  attr(:label_class, :string, default: nil, doc: "extra CSS for your label")
  attr(:help_text, :string, default: nil, doc: "context/help for your field")

  attr(:type, :string,
    default: "text_input",
    values: @input_types,
    doc: "The type of input"
  )

  attr(:wrapper_classes, :string, default: "pc-form-field-wrapper", doc: "CSS class for wrapper")
  attr :rest, :global, include: @form_attrs

  @doc "Use this when you want to include the label and some margin."
  def form_field(%{type: "hidden_input"} = assigns) do
    ~H"""
    <.hidden_input form={@form} field={@field} {@rest} />
    """
  end

  def form_field(assigns) do
    assigns =
      assigns
      |> assign_new(:label, fn ->
        if assigns[:field] do
          Form.humanize(assigns[:field])
        else
          nil
        end
      end)

    ~H"""
    <div class={@wrapper_classes} phx-feedback-for={Form.input_name(@form, @field)}>
      <%= case @type do %>
        <% "checkbox" -> %>
          <label class="pc-checkbox-label">
            <.checkbox form={@form} field={@field} {@rest} />
            <div class={
              label_classes(%{form: @form, field: @field, type: "checkbox", class: @label_class})
            }>
              <%= @label %>
            </div>
          </label>
        <% "switch" -> %>
          <label class="pc-checkbox-label">
            <.switch form={@form} field={@field} {@rest} />
            <div class={
              label_classes(%{form: @form, field: @field, type: "checkbox", class: @label_class})
            }>
              <%= @label %>
            </div>
          </label>
        <% "checkbox_group" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.checkbox_group form={@form} field={@field} {@rest} />
        <% "radio_group" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.radio_group form={@form} field={@field} {@rest} />
        <% "text_input" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.text_input form={@form} field={@field} {@rest} />
        <% "email_input" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.email_input form={@form} field={@field} {@rest} />
        <% "number_input" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.number_input form={@form} field={@field} {@rest} />
        <% "password_input" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.password_input form={@form} field={@field} {@rest} />
        <% "search_input" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.search_input form={@form} field={@field} {@rest} />
        <% "telephone_input" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.telephone_input form={@form} field={@field} {@rest} />
        <% "url_input" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.url_input form={@form} field={@field} {@rest} />
        <% "time_input" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.time_input form={@form} field={@field} {@rest} />
        <% "time_select" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.time_select form={@form} field={@field} {@rest} />
        <% "datetime_select" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.datetime_select form={@form} field={@field} {@rest} />
        <% "datetime_local_input" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.datetime_local_input form={@form} field={@field} {@rest} />
        <% "date_select" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.date_select form={@form} field={@field} {@rest} />
        <% "date_input" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.date_input form={@form} field={@field} {@rest} />
        <% "color_input" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.color_input form={@form} field={@field} {@rest} />
        <% "file_input" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.file_input form={@form} field={@field} {@rest} />
        <% "range_input" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.range_input form={@form} field={@field} {@rest} />
        <% "textarea" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.textarea form={@form} field={@field} {@rest} />
        <% "select" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.select form={@form} field={@field} {@rest} />
      <% end %>

      <.form_field_error form={@form} field={@field} />
      <.form_help_text help_text={@help_text} />
    </div>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def text_input(assigns) do
    assigns = assign_defaults(assigns, text_input_classes(field_has_errors?(assigns)))

    ~H"""
    <%= Form.text_input(
      @form,
      @field,
      [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
    ) %>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def email_input(assigns) do
    assigns = assign_defaults(assigns, text_input_classes(field_has_errors?(assigns)))

    ~H"""
    <%= Form.email_input(
      @form,
      @field,
      [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
    ) %>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def number_input(assigns) do
    assigns = assign_defaults(assigns, text_input_classes(field_has_errors?(assigns)))

    ~H"""
    <%= Form.number_input(
      @form,
      @field,
      [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
    ) %>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def password_input(assigns) do
    assigns = assign_defaults(assigns, text_input_classes(field_has_errors?(assigns)))

    ~H"""
    <%= Form.password_input(
      @form,
      @field,
      [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
    ) %>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def search_input(assigns) do
    assigns = assign_defaults(assigns, text_input_classes(field_has_errors?(assigns)))

    ~H"""
    <%= Form.search_input(
      @form,
      @field,
      [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
    ) %>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def telephone_input(assigns) do
    assigns = assign_defaults(assigns, text_input_classes(field_has_errors?(assigns)))

    ~H"""
    <%= Form.telephone_input(
      @form,
      @field,
      [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
    ) %>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def url_input(assigns) do
    assigns = assign_defaults(assigns, text_input_classes(field_has_errors?(assigns)))

    ~H"""
    <%= Form.url_input(
      @form,
      @field,
      [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
    ) %>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def time_input(assigns) do
    assigns = assign_defaults(assigns, text_input_classes(field_has_errors?(assigns)))

    ~H"""
    <%= Form.time_input(
      @form,
      @field,
      [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
    ) %>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def time_select(assigns) do
    assigns = assign_defaults(assigns, text_input_classes(field_has_errors?(assigns)))

    ~H"""
    <div class="pc-time-select">
      <%= Form.time_select(
        @form,
        @field,
        [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
      ) %>
    </div>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def datetime_local_input(assigns) do
    assigns = assign_defaults(assigns, text_input_classes(field_has_errors?(assigns)))

    ~H"""
    <%= Form.datetime_local_input(
      @form,
      @field,
      [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
    ) %>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def datetime_select(assigns) do
    assigns = assign_defaults(assigns, text_input_classes(field_has_errors?(assigns)))

    ~H"""
    <div class="pc-datetime-select">
      <%= Form.datetime_select(
        @form,
        @field,
        [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
      ) %>
    </div>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def date_select(assigns) do
    assigns = assign_defaults(assigns, text_input_classes(field_has_errors?(assigns)))

    ~H"""
    <div class="pc-date-select">
      <%= Form.date_select(
        @form,
        @field,
        [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
      ) %>
    </div>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def date_input(assigns) do
    assigns = assign_defaults(assigns, text_input_classes(field_has_errors?(assigns)))

    ~H"""
    <%= Form.date_input(
      @form,
      @field,
      [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
    ) %>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def color_input(assigns) do
    assigns = assign_defaults(assigns, color_input_classes(field_has_errors?(assigns)))

    ~H"""
    <%= Form.color_input(
      @form,
      @field,
      [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
    ) %>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def file_input(assigns) do
    assigns = assign_defaults(assigns, file_input_classes(field_has_errors?(assigns)))

    ~H"""
    <%= Form.file_input(
      @form,
      @field,
      [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
    ) %>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def range_input(assigns) do
    assigns = assign_defaults(assigns, range_input_classes(field_has_errors?(assigns)))

    ~H"""
    <%= Form.range_input(
      @form,
      @field,
      [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
    ) %>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def textarea(assigns) do
    assigns = assign_defaults(assigns, text_input_classes(field_has_errors?(assigns)))

    ~H"""
    <%= Form.textarea(
      @form,
      @field,
      [class: @classes, rows: "4", phx_feedback_for: Form.input_name(@form, @field)] ++
        Map.to_list(@rest)
    ) %>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:options, :list, default: [], doc: "options for the select")
  attr(:rest, :global, include: @form_attrs)

  def select(assigns) do
    assigns = assign_defaults(assigns, select_classes(field_has_errors?(assigns)))

    ~H"""
    <%= Form.select(
      @form,
      @field,
      @options,
      [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
    ) %>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")

  attr(:rest, :global,
    include: ~w(checked_value unchecked_value checked hidden_input) ++ @form_attrs
  )

  def checkbox(assigns) do
    assigns = assign_defaults(assigns, checkbox_classes(field_has_errors?(assigns)))

    ~H"""
    <%= Form.checkbox(
      @form,
      @field,
      [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
    ) %>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:options, :list, default: [], doc: "options for the select")
  attr(:layout, :atom, default: :col, values: [:row, :col], doc: "layout for the checkboxes")
  attr(:checked, :list, doc: "a list of checked values")
  attr(:rest, :global, include: @form_attrs)

  def checkbox_group(assigns) do
    assigns =
      assigns
      |> assign_defaults(checkbox_classes(field_has_errors?(assigns)))
      |> assign_new(:checked, fn ->
        values =
          case Form.input_value(assigns[:form], assigns[:field]) do
            value when is_binary(value) -> [value]
            value when is_list(value) -> value
            _ -> []
          end

        Enum.map(values, &to_string/1)
      end)
      |> assign_new(:id_prefix, fn -> Form.input_id(assigns[:form], assigns[:field]) <> "_" end)

    ~H"""
    <div class={checkbox_group_layout_classes(%{layout: @layout})}>
      <%= Form.hidden_input(@form, @field, name: Form.input_name(@form, @field), value: "") %>
      <%= for {label, value} <- @options do %>
        <label class={checkbox_group_layout_item_classes(%{layout: @layout})}>
          <.checkbox
            form={@form}
            field={@field}
            id={@id_prefix <> to_string(value)}
            name={Form.input_name(@form, @field) <> "[]"}
            checked_value={value}
            unchecked_value=""
            value={value}
            checked={to_string(value) in @checked}
            hidden_input={false}
            {@rest}
          />
          <div class={label_classes(%{form: @form, field: @field, type: "checkbox"})}>
            <%= label %>
          </div>
        </label>
      <% end %>
    </div>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:rest, :global, include: @checkbox_form_attrs)

  def switch(assigns) do
    base_class = if field_has_errors?(assigns), do: "has-error", else: ""
    assigns = assign_defaults(assigns, base_class)

    ~H"""
    <label class="pc-switch">
      <%= Form.checkbox(
        @form,
        @field,
        [
          class: "sr-only peer #{@classes}",
          phx_feedback_for: Form.input_name(@form, @field)
        ] ++ Map.to_list(@rest)
      ) %>
      <span class="pc-switch__fake-input"></span>
      <span class="pc-switch__fake-input-bg"></span>
    </label>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:value, :any, default: nil, doc: "the radio value")
  attr(:rest, :global, include: @form_attrs)

  def radio(assigns) do
    assigns = assign_defaults(assigns, radio_classes(field_has_errors?(assigns)))

    ~H"""
    <%= Form.radio_button(
      @form,
      @field,
      @value,
      [class: @classes, phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
    ) %>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :string, default: "", doc: "extra classes for the text input")
  attr(:options, :list, default: [], doc: "options for the select")
  attr(:layout, :atom, default: :col, values: [:row, :col], doc: "layout for the radio options")
  attr(:rest, :global, include: @form_attrs)

  def radio_group(assigns) do
    assigns =
      assigns
      |> assign_defaults(radio_classes(field_has_errors?(assigns)))

    ~H"""
    <div class={radio_group_layout_classes(%{layout: @layout})}>
      <%= for {label, value} <- @options do %>
        <label class={radio_group_layout_item_classes(%{layout: @layout})}>
          <.radio form={@form} field={@field} value={value} {@rest} />
          <div class={label_classes(%{form: @form, field: @field, type: "radio"})}><%= label %></div>
        </label>
      <% end %>
    </div>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:rest, :global, include: @form_attrs)

  def hidden_input(assigns) do
    assigns = assign_defaults(assigns, text_input_classes(field_has_errors?(assigns)))

    ~H"""
    <%= Form.hidden_input(
      @form,
      @field,
      [phx_feedback_for: Form.input_name(@form, @field)] ++ Map.to_list(@rest)
    ) %>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:class, :string, default: "", doc: "extra classes for the text input")

  def form_field_error(assigns) do
    assigns =
      assigns
      |> assign(:translated_errors, generated_translated_errors(assigns.form, assigns.field))

    ~H"""
    <%= if field_has_errors?(assigns) do %>
      <div class={@class}>
        <%= for translated_error <- @translated_errors do %>
          <div
            class="pc-form-field-error invalid-feedback"
            phx-feedback-for={Form.input_name(@form, @field)}
          >
            <%= translated_error %>
          </div>
        <% end %>
      </div>
    <% end %>
    """
  end

  attr(:class, :string, default: "", doc: "extra classes for the help text")
  attr(:help_text, :string, default: nil, doc: "context/help for your field")
  slot(:inner_block, required: false)
  attr(:rest, :global)

  def form_help_text(assigns) do
    ~H"""
    <div :if={render_slot(@inner_block) || @help_text} class={["pc-form-help-text", @class]} {@rest}>
      <%= render_slot(@inner_block) || @help_text %>
    </div>
    """
  end

  defp generated_translated_errors(form, field) do
    translate_error = translator_from_config() || (&translate_error/1)

    Keyword.get_values(form.errors || [], field)
    |> Enum.map(fn error ->
      translate_error.(error)
    end)
  end

  defp translate_error({msg, opts}) do
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      try do
        String.replace(acc, "%{#{key}}", to_string(value))
      rescue
        e ->
          IO.warn(
            """
            the fallback message translator for the form_field_error function cannot handle the given value.

            Hint: you can set up the `error_translator_function` to route all errors to your application helpers:

              config :petal_components, :error_translator_function, {MyAppWeb.ErrorHelpers, :translate_error}

            Given value: #{inspect(value)}

            Exception: #{Exception.message(e)}
            """,
            __STACKTRACE__
          )

          "invalid value"
      end
    end)
  end

  defp translator_from_config do
    case Application.get_env(:petal_components, :error_translator_function) do
      {module, function} -> &apply(module, function, [&1])
      nil -> nil
    end
  end

  defp assign_defaults(assigns, base_classes) do
    assigns
    |> assign_new(:type, fn -> "text" end)
    |> assign_new(:classes, fn ->
      build_class([base_classes, assigns[:class]])
    end)
  end

  defp label_classes(assigns) do
    type_classes =
      if Enum.member?(["checkbox", "radio"], assigns[:type]) do
        "pc-label--for-checkbox"
      else
        ""
      end

    "#{if field_has_errors?(assigns), do: "has-error", else: ""} #{type_classes} #{assigns[:class] || ""} pc-label"
  end

  defp text_input_classes(has_error) do
    "#{if has_error, do: "has-error", else: ""} pc-text-input"
  end

  defp select_classes(has_error) do
    "#{if has_error, do: "has-error", else: ""} pc-select"
  end

  defp file_input_classes(has_error) do
    "#{if has_error, do: "has-error", else: ""} pc-file-input"
  end

  defp color_input_classes(has_error) do
    "#{if has_error, do: "has-error", else: ""} pc-color-input"
  end

  defp range_input_classes(has_error) do
    "#{if has_error, do: "has-error", else: ""} pc-range-input"
  end

  defp checkbox_classes(has_error) do
    "#{if has_error, do: "has-error", else: ""} pc-checkbox"
  end

  defp checkbox_group_layout_classes(assigns) do
    case assigns[:layout] do
      :row ->
        "pc-checkbox-group--row"

      _col ->
        "pc-checkbox-group--col"
    end
  end

  defp checkbox_group_layout_item_classes(assigns) do
    case assigns[:layout] do
      :row ->
        "pc-checkbox-group__item--row"

      _col ->
        "pc-checkbox-group__item--col"
    end
  end

  defp radio_group_layout_classes(assigns) do
    case assigns[:layout] do
      :row ->
        "pc-radio-group--row"

      _col ->
        "pc-radio-group--col"
    end
  end

  defp radio_group_layout_item_classes(assigns) do
    case assigns[:layout] do
      :row ->
        "pc-radio-group__item--row"

      _col ->
        "pc-radio-group__item--col"
    end
  end

  defp radio_classes(has_error) do
    "#{if has_error, do: "has-error", else: ""} pc-radio"
  end

  defp field_has_errors?(%{form: form, field: field}) when is_map(form) do
    case Keyword.get_values(form.errors || [], field) do
      [] -> false
      _ -> true
    end
  end

  defp field_has_errors?(_), do: false
end
