defmodule PetalComponents.Form do
  use Phoenix.Component

  alias PhoenixHTMLHelpers.Form

  @form_attrs ~w(autocomplete autocorrect autocapitalize disabled form max maxlength min minlength list
  pattern placeholder readonly required size step value name multiple prompt selected default year month day hour minute second builder options layout cols rows wrap checked accept)

  @checkbox_form_attrs ~w(checked_value unchecked_value checked hidden_input) ++ @form_attrs

  @moduledoc """
  Everything related to forms: inputs, labels etc

  Deprecated in favor of field.ex and input.ex, which use the new `%Phoenix.HTML.FormField{}` struct.
  """

  attr :form, :any, default: nil, doc: ""
  attr :field, :atom, default: nil, doc: ""
  attr :label, :string, default: nil, doc: "labels your field"
  attr :class, :any, doc: "CSS classes to add to your label"

  attr :compound, :boolean, default: false, doc: "Avoid using label/for for compound inputs"

  slot :inner_block, required: false
  attr :rest, :global, include: ~w(for)

  def form_label(assigns) do
    assigns =
      assigns
      |> assign(:classes, label_classes(assigns))

    ~H"""
    <%= if @form && @field && !@compound do %>
      <%= Form.label @form, @field, [class: @classes] ++ Map.to_list(@rest) do %>
        {render_slot(@inner_block) || @label || Form.humanize(@field)}
      <% end %>
    <% else %>
      <span class={@classes} {@rest}>
        {render_slot(@inner_block) || @label || Form.humanize(@field)}
      </span>
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
    "range_dual",
    "range_numeric",
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
  attr(:label_class, :any, default: nil, doc: "extra CSS for your label")
  attr(:help_text, :string, default: nil, doc: "context/help for your field")

  attr(:type, :string,
    default: "text_input",
    values: @input_types,
    doc: "The type of input"
  )

  attr(:wrapper_classes, :string, default: "pc-form-field-wrapper", doc: "CSS class for wrapper")

  attr :no_margin, :boolean,
    default: false,
    doc: "removes the bottom margin from the field wrapper"

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
      |> assign(
        :wrapper_classes,
        if assigns[:wrapper_classes] do
          assigns.wrapper_classes
        else
          [
            "pc-form-field-wrapper",
            assigns.no_margin && "pc-form-field-wrapper--no-margin"
          ]
        end
      )

    ~H"""
    <div class={@wrapper_classes}>
      <%= case @type do %>
        <% "checkbox" -> %>
          <label class="pc-checkbox-label">
            <.checkbox form={@form} field={@field} {@rest} />
            <div class={
              label_classes(%{form: @form, field: @field, type: "checkbox", class: @label_class})
            }>
              {@label}
            </div>
          </label>
        <% "switch" -> %>
          <label class="pc-checkbox-label">
            <.switch form={@form} field={@field} {@rest} />
            <div class={
              label_classes(%{form: @form, field: @field, type: "checkbox", class: @label_class})
            }>
              {@label}
            </div>
          </label>
        <% "checkbox_group" -> %>
          <.form_label
            form={@form}
            field={@field}
            label={@label}
            class={@label_class}
            compound={true}
          />
          <.checkbox_group form={@form} field={@field} {@rest} />
        <% "radio_group" -> %>
          <.form_label
            form={@form}
            field={@field}
            label={@label}
            class={@label_class}
            compound={true}
          />
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
          <.form_label
            form={@form}
            field={@field}
            label={@label}
            class={@label_class}
            compound={true}
          />
          <.time_select form={@form} field={@field} {@rest} />
        <% "datetime_select" -> %>
          <.form_label
            form={@form}
            field={@field}
            label={@label}
            class={@label_class}
            compound={true}
          />
          <.datetime_select form={@form} field={@field} {@rest} />
        <% "datetime_local_input" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <.datetime_local_input form={@form} field={@field} {@rest} />
        <% "date_select" -> %>
          <.form_label
            form={@form}
            field={@field}
            label={@label}
            class={@label_class}
            compound={true}
          />
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
        <% "range_dual" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <%
            # Set default values if nil
            min_value = @min_field.value || @range_min
            max_value = @max_field.value || @range_max

            # Get formatter function
            formatter = assigns[:formatter] || (&to_string/1)

            # Get sample formatted value to detect format pattern (e.g., "$50")
            sample_formatted = formatter.(min_value)
          %>
          <div
            id={@id || Phoenix.HTML.Form.input_id(@form, @field)}
            class="relative h-12 mt-4"
            phx-update="ignore"
            x-data={"{
              rangeMin: #{@range_min},
              rangeMax: #{@range_max},
              minValue: #{min_value},
              maxValue: #{max_value},

              init() {
                this.$nextTick(() => {
                  this.updateRange();
                });
              },

              updateMinValue(value) {
                this.minValue = parseInt(value);
                if (this.minValue > this.maxValue) {
                  this.minValue = this.maxValue;
                  this.$refs.minSlider.value = this.minValue;
                }
                this.updateRange();
              },

              updateMaxValue(value) {
                this.maxValue = parseInt(value);
                if (this.maxValue < this.minValue) {
                  this.maxValue = this.minValue;
                  this.$refs.maxSlider.value = this.maxValue;
                }
                this.updateRange();
              },

              updateRange() {
                if (this.rangeMax === this.rangeMin) {
                  this.$refs.rangeTrack.style.left = '0%';
                  this.$refs.rangeTrack.style.right = '0%';
                  return;
                }
                const leftPercent = ((this.minValue - this.rangeMin) / (this.rangeMax - this.rangeMin)) * 100;
                const rightPercent = 100 - ((this.maxValue - this.rangeMin) / (this.rangeMax - this.rangeMin)) * 100;

                this.$refs.rangeTrack.style.left = leftPercent + '%';
                this.$refs.rangeTrack.style.right = rightPercent + '%';
              },

              formatValue(val) {
                const sample = #{Jason.encode!(sample_formatted)};
                if (sample.includes('$')) {
                  return '$' + val;
                }
                return val.toString();
              }
            }"}
          >
            <div class="flex flex-row items-center justify-center space-x-2">
              <div class="relative w-full h-1">
                <div class="pc-slider-track"></div>
                <div
                  x-ref="rangeTrack"
                  class="pc-slider-range"
                  id={@id || Phoenix.HTML.Form.input_id(@form, @field) <> "_slider-range"}
                  style={"left: #{calculate_slider_position(min_value, @range_min, @range_max)}%; right: #{100 - calculate_slider_position(max_value, @range_min, @range_max)}%;"}
                >
                </div>
                <input
                  x-ref="minSlider"
                  type="range"
                  min={@range_min}
                  max={@range_max}
                  step={@step}
                  name={@min_field.name}
                  value={min_value}
                  class="pc-slider-input"
                  id={@id || Phoenix.HTML.Form.input_id(@form, @field) <> "_min-range"}
                  @input="updateMinValue($event.target.value)"
                />
                <input
                  x-ref="maxSlider"
                  type="range"
                  min={@range_min}
                  max={@range_max}
                  step={@step}
                  name={@max_field.name}
                  value={max_value}
                  class="pc-slider-input"
                  id={@id || Phoenix.HTML.Form.input_id(@form, @field) <> "_max-range"}
                  @input="updateMaxValue($event.target.value)"
                />
              </div>
            </div>
            <div class="grid grid-cols-3 mt-4 text-sm">
              <span class="flex items-start justify-start text-gray-500 dark:text-gray-400">
                {assigns[:range_min_label] || formatter.(@range_min)}
              </span>
              <span
                class="flex justify-center text-gray-600 dark:text-gray-300"
                x-text="formatValue(minValue) + ' - ' + formatValue(maxValue)"
              >
                {formatter.(min_value) <> " - " <> formatter.(max_value)}
              </span>
              <span class="flex items-end justify-end text-gray-500 dark:text-gray-400">
                {assigns[:range_max_label] || formatter.(@range_max)}
              </span>
            </div>
          </div>
          <.form_field_error form={@form} field={@field} />
          <.form_help_text help_text={@help_text} />
        <% "range_numeric" -> %>
          <.form_label form={@form} field={@field} label={@label} class={@label_class} />
          <div class="flex flex-row gap-2">
            <.form_field
              type="number_input"
              form={@form}
              field={@min_field.name}
              label=""
              placeholder="No Min"
              min={@range_min}
              max={@max_field.value}
              value={@min_field.value}
              wrapper_classes="w-full"
            />

            <div class="flex flex-col items-center justify-center">-</div>

            <.form_field
              type="number_input"
              form={@form}
              field={@max_field.name}
              label=""
              placeholder="No Max"
              min={@min_field.value}
              max={@range_max}
              value={@max_field.value}
              wrapper_classes="w-full"
            />
          </div>
          <.form_field_error form={@form} field={@field} />
          <.form_help_text help_text={@help_text} />
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
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def text_input(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, text_input_classes(errors))

    ~H"""
    {Form.text_input(@form, @field, [class: @classes] ++ Map.to_list(@rest))}
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def email_input(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, text_input_classes(errors))

    ~H"""
    {Form.email_input(@form, @field, [class: @classes] ++ Map.to_list(@rest))}
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def number_input(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, text_input_classes(errors))

    ~H"""
    {Form.number_input(@form, @field, [class: @classes] ++ Map.to_list(@rest))}
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def password_input(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, text_input_classes(errors))

    ~H"""
    {Form.password_input(@form, @field, [class: @classes] ++ Map.to_list(@rest))}
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def search_input(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, text_input_classes(errors))

    ~H"""
    {Form.search_input(@form, @field, [class: @classes] ++ Map.to_list(@rest))}
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def telephone_input(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, text_input_classes(errors))

    ~H"""
    {Form.telephone_input(@form, @field, [class: @classes] ++ Map.to_list(@rest))}
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def url_input(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, text_input_classes(errors))

    ~H"""
    {Form.url_input(@form, @field, [class: @classes] ++ Map.to_list(@rest))}
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def time_input(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, text_input_classes(errors))

    ~H"""
    {Form.time_input(@form, @field, [class: @classes, bob: "yo"] ++ Map.to_list(@rest))}
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def time_select(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, text_input_classes(errors))

    ~H"""
    <div class="pc-time-select">
      {Form.time_select(@form, @field, [class: @classes] ++ Map.to_list(@rest))}
    </div>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def datetime_local_input(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, text_input_classes(errors))

    ~H"""
    {Form.datetime_local_input(@form, @field, [class: @classes] ++ Map.to_list(@rest))}
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def datetime_select(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, text_input_classes(errors))

    ~H"""
    <div class="pc-datetime-select">
      {Form.datetime_select(@form, @field, [class: @classes] ++ Map.to_list(@rest))}
    </div>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def date_select(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, text_input_classes(errors))

    ~H"""
    <div class="pc-date-select">
      {Form.date_select(@form, @field, [class: @classes] ++ Map.to_list(@rest))}
    </div>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def date_input(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, text_input_classes(errors))

    ~H"""
    {Form.date_input(@form, @field, [class: @classes] ++ Map.to_list(@rest))}
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def color_input(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, color_input_classes(errors))

    ~H"""
    {Form.color_input(@form, @field, [class: @classes] ++ Map.to_list(@rest))}
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def file_input(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, file_input_classes(errors))

    ~H"""
    {Form.file_input(@form, @field, [class: @classes] ++ Map.to_list(@rest))}
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def range_input(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, range_input_classes(errors))

    ~H"""
    {Form.range_input(@form, @field, [class: @classes] ++ Map.to_list(@rest))}
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:rest, :global, include: @form_attrs)

  def textarea(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, text_input_classes(errors))

    ~H"""
    {Form.textarea(@form, @field, [class: @classes, rows: "4"] ++ Map.to_list(@rest))}
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:options, :list, default: [], doc: "options for the select")
  attr(:rest, :global, include: @form_attrs)

  def select(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, select_classes(errors))

    ~H"""
    {Form.select(@form, @field, @options, [class: @classes] ++ Map.to_list(@rest))}
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")

  attr(:rest, :global,
    include: ~w(checked_value unchecked_value checked hidden_input) ++ @form_attrs
  )

  def checkbox(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, checkbox_classes(errors))

    ~H"""
    {Form.checkbox(@form, @field, [class: @classes] ++ Map.to_list(@rest))}
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:options, :list, default: [], doc: "options for the select")
  attr(:layout, :atom, default: :col, values: [:row, :col], doc: "layout for the checkboxes")
  attr(:checked, :list, doc: "a list of checked values")
  attr(:rest, :global, include: @form_attrs)

  def checkbox_group(assigns) do
    errors = used_input_errors(assigns)

    assigns =
      assigns
      |> assign_defaults(checkbox_classes(errors))
      |> assign_new(:checked, fn ->
        values =
          case Phoenix.HTML.Form.input_value(assigns[:form], assigns[:field]) do
            value when is_binary(value) -> [value]
            value when is_list(value) -> value
            _ -> []
          end

        Enum.map(values, &to_string/1)
      end)
      |> assign_new(:id_prefix, fn ->
        Phoenix.HTML.Form.input_id(assigns[:form], assigns[:field]) <> "_"
      end)

    ~H"""
    <div class={checkbox_group_layout_classes(%{layout: @layout})}>
      {Form.hidden_input(@form, @field,
        name: Phoenix.HTML.Form.input_name(@form, @field),
        value: ""
      )}
      <%= for {label, value} <- @options do %>
        <label class={checkbox_group_layout_item_classes(%{layout: @layout})}>
          <.checkbox
            form={@form}
            field={@field}
            id={@id_prefix <> to_string(value)}
            name={Phoenix.HTML.Form.input_name(@form, @field) <> "[]"}
            checked_value={value}
            unchecked_value=""
            value={value}
            checked={to_string(value) in @checked}
            hidden_input={false}
            {@rest}
          />
          <div class={label_classes(%{form: @form, field: @field, type: "checkbox"})}>
            {label}
          </div>
        </label>
      <% end %>
    </div>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:size, :string, default: "md", values: ~w(xs sm md lg xl), doc: "the size of the switch")
  attr(:rest, :global, include: @checkbox_form_attrs)

  def switch(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, switch_classes(errors))

    ~H"""
    <label class={["pc-switch", "pc-switch--#{@size}"]}>
      {Form.checkbox(@form, @field, [class: @classes] ++ Map.to_list(@rest))}
      <span class={["pc-switch__fake-input", "pc-switch__fake-input--#{@size}"]}></span>
      <span class={["pc-switch__fake-input-bg", "pc-switch__fake-input-bg--#{@size}"]}></span>
    </label>
    """
  end

  defp switch_classes(errors) do
    "#{if errors != [], do: "has-error", else: ""} sr-only peer"
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:value, :any, default: nil, doc: "the radio value")
  attr(:rest, :global, include: @form_attrs)

  def radio(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, radio_classes(errors))

    ~H"""
    {Form.radio_button(@form, @field, @value, [class: @classes] ++ Map.to_list(@rest))}
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:label, :string, default: nil, doc: "labels your field")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")
  attr(:options, :list, default: [], doc: "options for the select")
  attr(:layout, :atom, default: :col, values: [:row, :col], doc: "layout for the radio options")
  attr(:rest, :global, include: @form_attrs)

  def radio_group(assigns) do
    errors = used_input_errors(assigns)

    assigns =
      assigns
      |> assign_defaults(radio_classes(errors))

    ~H"""
    <div class={radio_group_layout_classes(%{layout: @layout})}>
      <%= for {label, value} <- @options do %>
        <label class={radio_group_layout_item_classes(%{layout: @layout})}>
          <.radio form={@form} field={@field} value={value} {@rest} />
          <div class={label_classes(%{form: @form, field: @field, type: "radio"})}>{label}</div>
        </label>
      <% end %>
    </div>
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:rest, :global, include: @form_attrs)

  def hidden_input(assigns) do
    errors = used_input_errors(assigns)
    assigns = assign_defaults(assigns, text_input_classes(errors))

    ~H"""
    {Form.hidden_input(@form, @field, Map.to_list(@rest))}
    """
  end

  attr(:form, :any, default: nil, doc: "")
  attr(:field, :atom, default: nil, doc: "")
  attr(:class, :any, default: nil, doc: "extra classes for the text input")

  def form_field_error(assigns) do
    assigns =
      assigns
      |> assign(:translated_errors, generated_translated_errors(assigns))

    ~H"""
    <div :if={@translated_errors != []} class={@class}>
      <div :for={translated_error <- @translated_errors} class="pc-form-field-error invalid-feedback">
        {translated_error}
      </div>
    </div>
    """
  end

  attr(:class, :any, default: nil, doc: "extra classes for the help text")
  attr(:help_text, :string, default: nil, doc: "context/help for your field")
  slot(:inner_block, required: false)
  attr(:rest, :global)

  def form_help_text(assigns) do
    ~H"""
    <div :if={render_slot(@inner_block) || @help_text} class={["pc-form-help-text", @class]} {@rest}>
      {render_slot(@inner_block) || @help_text}
    </div>
    """
  end

  defp generated_translated_errors(assigns) do
    translate_error = translator_from_config() || (&translate_error/1)

    used_input_errors(assigns)
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
      [base_classes, assigns[:class]]
    end)
  end

  defp label_classes(assigns) do
    errors = used_input_errors(assigns)

    type_classes =
      if Enum.member?(["checkbox", "radio"], assigns[:type]) do
        "pc-label--for-checkbox"
      else
        ""
      end

    "#{if errors != [], do: "has-error", else: ""} #{type_classes} #{assigns[:class] || ""} pc-label"
  end

  defp text_input_classes(errors) do
    "#{if errors != [], do: "has-error", else: ""} pc-text-input"
  end

  defp select_classes(errors) do
    "#{if errors != [], do: "has-error", else: ""} pc-select"
  end

  defp file_input_classes(errors) do
    "#{if errors != [], do: "has-error", else: ""} pc-file-input"
  end

  defp color_input_classes(errors) do
    "#{if errors != [], do: "has-error", else: ""} pc-color-input"
  end

  defp range_input_classes(errors) do
    "#{if errors != [], do: "has-error", else: ""} pc-range-input"
  end

  # Helper functions for dual range slider
  defp calculate_slider_position(nil, _range_min, _range_max), do: 0

  defp calculate_slider_position(value, range_min, range_max) when is_integer(value) do
    round((value - range_min) / (range_max - range_min) * 100)
  end

  defp calculate_slider_position(value, range_min, range_max) do
    value =
      case value do
        v when is_binary(v) -> String.to_integer(v)
        v when is_integer(v) -> v
        _ -> range_min
      end

    round((value - range_min) / (range_max - range_min) * 100)
  end

  defp checkbox_classes(errors) do
    "#{if errors != [], do: "has-error", else: ""} pc-checkbox"
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

  defp radio_classes(errors) do
    "#{if errors != [], do: "has-error", else: ""} pc-radio"
  end

  defp used_input_errors(%{form: form, field: field}) when not is_nil(form) do
    if used_input?(form[field]), do: form[field].errors, else: []
  end

  defp used_input_errors(_), do: []
end
