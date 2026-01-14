defmodule PetalComponents.Field do
  use Phoenix.Component
  import PetalComponents.Icon

  @doc """
  Renders an input with label and error messages. If you just want an input, check out input.ex

  A `%Phoenix.HTML.FormField{}` and type may be passed to the field
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.field field={@form[:email]} type="email" />
      <.field label="Name" value="" name="name" errors={["oh no!"]} />
  """
  # Basic Attributes
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
      ~w(checkbox checkbox-group radio-card radio-group color date datetime-local email file hidden month number password
         range range-dual range-numeric search select switch tel text textarea time url week),
    doc: "the type of input"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "the size of the switch (xs, sm, md, lg or xl) or radio card (sm, md or lg)"

  attr :variant, :any, default: "outline", doc: "outline, classic - used by radio-card"

  attr :viewable, :boolean,
    default: false,
    doc: "If true, adds a toggle to show/hide the password text"

  attr :copyable, :boolean,
    default: false,
    doc: "If true, adds a copy button to the field and disables the input"

  attr :clearable, :boolean,
    default: false,
    doc: "If true, adds a clear button to clear the field value"

  attr :no_margin, :boolean, default: false, doc: "removes the margin from the field wrapper"

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

  attr :class, :any, default: nil, doc: "the class to add to the input"
  attr :wrapper_class, :any, default: nil, doc: "the wrapper div classes"
  attr :help_text, :string, default: nil, doc: "context/help for your field"
  attr :label_class, :any, default: nil, doc: "extra CSS for your label"
  attr :selected, :any, default: nil, doc: "the selected value for select inputs"

  attr :required, :boolean,
    default: false,
    doc: "is this field required? is passed to the input and adds an asterisk next to the label"

  # Range and Dual Range Specific Attributes
  attr :range_min, :integer, default: 0, doc: "minimum value for range inputs"
  attr :range_max, :integer, default: 100, doc: "maximum value for range inputs"
  attr :step, :integer, default: 1, doc: "step value for range inputs"

  attr :min_field, :map,
    default: nil,
    doc: "min field for dual range (required for range-dual and range-numeric)"

  attr :max_field, :map,
    default: nil,
    doc: "max field for dual range (required for range-dual and range-numeric)"

  attr :range_min_label, :string, default: nil, doc: "optional label for minimum range value"
  attr :range_max_label, :string, default: nil, doc: "optional label for maximum range value"

  attr :formatter, :any,
    default: nil,
    doc: "function to format range values (e.g., Money.to_string!)"

  attr :rest, :global,
    include:
      ~w(autocomplete autocorrect autocapitalize disabled form max maxlength min minlength list
         pattern placeholder readonly required size step value name multiple prompt default year month day hour minute second builder options layout cols rows wrap checked accept),
    doc: "All other props go on the input"

  # When a FormField struct is provided, normalize and delegate rendering.
  def field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn ->
      if assigns.multiple && assigns.type not in ["checkbox-group", "radio-group"],
        do: field.name <> "[]",
        else: field.name
    end)
    |> assign_new(:value, fn -> field.value end)
    |> assign_new(:label, fn -> PhoenixHTMLHelpers.Form.humanize(field.field) end)
    |> field()
  end

  # Render a checkbox
  def field(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", value)
      end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
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
          {@label}
        </div>
      </label>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  # Range Numeric Input – Two numeric text fields
  def field(%{type: "range-numeric"} = assigns) do
    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <div class="flex flex-row gap-2">
        <.field
          type="text"
          step={@step}
          name={@min_field.name}
          label={@label}
          value={@min_field.value}
          placeholder="No Min"
          min={@range_min}
          max={@max_field.value}
          id={@id <> "_min"}
          inputmode="numeric"
          wrapper_class="w-full"
        />
        <div class="flex flex-col items-center justify-center">-</div>
        <.field
          type="text"
          step={@step}
          name={@max_field.name}
          label=""
          value={@max_field.value}
          placeholder="No Max"
          min={@min_field.value}
          max={@range_max}
          id={@id <> "_max"}
          inputmode="numeric"
          wrapper_class="w-full"
        />
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  # Dual Range Slider Input – Two range inputs with a colored track
  def field(%{type: "range-dual"} = assigns) do
    formatter = assigns[:formatter] || (&format_range_value/1)

    assigns =
      assign(assigns,
        class: [assigns.class, get_class_for_type(assigns.type)],
        format_value: formatter
      )

    # Set default values if nil
    min_value = assigns.min_field.value || assigns.range_min
    max_value = assigns.max_field.value || assigns.range_max

    # Get sample formatted value to detect format pattern (e.g., "$50")
    sample_formatted = assigns.format_value.(min_value)

    assigns =
      assign(assigns,
        min_value: min_value,
        max_value: max_value,
        sample_formatted: sample_formatted
      )

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label>{@label}</.field_label>
      <div
        id={@id}
        class="relative h-12 mt-4"
        phx-update="ignore"
        x-data={"{
          rangeMin: #{@range_min},
          rangeMax: #{@range_max},
          minValue: #{@min_value},
          maxValue: #{@max_value},

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
            const sample = #{Jason.encode!(@sample_formatted)};
            if (sample.includes('$')) {
              return '$' + val;
            }
            return val.toString();
          }
        }"}
      >
        <div class="flex flex-row items-center justify-center space-x-2">
          <div class="relative w-full h-1.5">
            <div class="pc-slider-track"></div>
            <div
              x-ref="rangeTrack"
              class="pc-slider-range"
              id={@id <> "_slider-range"}
              style={"left: #{calculate_slider_position(@min_value, @range_min, @range_max)}%; right: #{100 - calculate_slider_position(@max_value, @range_min, @range_max)}%;"}
            >
            </div>
            <input
              x-ref="minSlider"
              type="range"
              min={@range_min}
              max={@range_max}
              step={@step}
              name={@min_field.name}
              value={@min_value}
              class="pc-slider-input"
              id={@id <> "_min-range"}
              @input="updateMinValue($event.target.value)"
            />
            <input
              x-ref="maxSlider"
              type="range"
              min={@range_min}
              max={@range_max}
              step={@step}
              name={@max_field.name}
              value={@max_value}
              class="pc-slider-input"
              id={@id <> "_max-range"}
              @input="updateMaxValue($event.target.value)"
            />
          </div>
        </div>
        <div class="grid grid-cols-3 mt-4 text-sm">
          <span class="flex items-start justify-start text-gray-500 dark:text-gray-400">
            {@range_min_label || @format_value.(@range_min)}
          </span>
          <span
            class="flex justify-center text-gray-600 dark:text-gray-300"
            x-text="formatValue(minValue) + ' - ' + formatValue(maxValue)"
          >
            {@format_value.(@min_value) <> " - " <> @format_value.(@max_value)}
          </span>
          <span class="flex items-end justify-end text-gray-500 dark:text-gray-400">
            {@range_max_label || @format_value.(@range_max)}
          </span>
        </div>
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  # Standard Select Input
  def field(%{type: "select"} = assigns) do
    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label required={@required} for={@id} class={@label_class}>
        {@label}
      </.field_label>
      <select
        id={@id}
        name={@name}
        class={["pc-text-input", @class]}
        multiple={@multiple}
        required={@required}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @selected || @value)}
      </select>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  # Textarea Input
  def field(%{type: "textarea"} = assigns) do
    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label required={@required} for={@id} class={@label_class}>
        {@label}
      </.field_label>
      <textarea
        id={@id}
        name={@name}
        class={["pc-text-input", @class]}
        rows={@rows}
        required={@required}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  # Switch Input
  def field(%{type: "switch", value: value} = assigns) do
    assigns =
      assigns
      |> assign_new(:checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", value)
      end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <label class={["pc-checkbox-label", @label_class]}>
        <input type="hidden" name={@name} value="false" />
        <label class={["pc-switch", "pc-switch--#{@size}"]}>
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
          <span class={["pc-switch__fake-input", "pc-switch__fake-input--#{@size}"]}></span>
          <span class={["pc-switch__fake-input-bg", "pc-switch__fake-input-bg--#{@size}"]}></span>
        </label>
        <div class={[@required && "pc-label--required"]}>{@label}</div>
      </label>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  # Checkbox Group
  def field(%{type: "checkbox-group"} = assigns) do
    assigns =
      assigns
      |> assign_new(:checked, fn ->
        case assigns.value do
          value when is_binary(value) -> [value]
          value when is_list(value) -> value
          _ -> []
        end
        |> Enum.map(&to_string/1)
      end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label required={@required} class={@label_class}>
        {@label}
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
            <div>{label}</div>
          </label>
        <% end %>
        <%= if @empty_message && Enum.empty?(@options) do %>
          <div class="pc-checkbox-group--empty-message">
            {@empty_message}
          </div>
        <% end %>
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  # Radio Group
  def field(%{type: "radio-group"} = assigns) do
    assigns = assign_new(assigns, :checked, fn -> nil end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label required={@required} class={@label_class}>
        {@label}
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
                to_string(value) == to_string(@value) ||
                  to_string(value) == to_string(@checked)
              }
              class="pc-radio"
              {@rest}
            />
            <div>{label}</div>
          </label>
        <% end %>
        <%= if @empty_message && Enum.empty?(@options) do %>
          <div class="pc-checkbox-group--empty-message">
            {@empty_message}
          </div>
        <% end %>
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  # Radio Card
  def field(%{type: "radio-card"} = assigns) do
    assigns =
      assigns
      |> assign_new(:checked, fn -> nil end)
      |> assign_new(:options, fn -> [] end)
      |> assign_new(:group_layout, fn -> "row" end)
      |> assign_new(:id_prefix, fn -> assigns.id || assigns.name || "radio_card" end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label required={@required} class={@label_class}>
        {@label}
      </.field_label>
      <div class={[
        "pc-radio-card-group",
        "pc-radio-card-group--#{@group_layout}",
        @class
      ]}>
        <input type="hidden" name={@name} value="" />
        <%= for option <- @options do %>
          <label class={[
            "pc-radio-card",
            "pc-radio-card--#{@size}",
            "pc-radio-card--#{@variant}",
            option[:disabled] && "pc-radio-card--disabled"
          ]}>
            <input
              type="radio"
              name={@name}
              id={"#{@id_prefix}_#{option[:value]}"}
              value={option[:value]}
              disabled={option[:disabled]}
              checked={
                to_string(option[:value]) == to_string(@value) ||
                  to_string(option[:value]) == to_string(@checked)
              }
              class="sr-only pc-radio-card__input"
              {@rest}
            />
            <div class="pc-radio-card__fake-input"></div>
            <div class="pc-radio-card__content">
              <div class="pc-radio-card__label">{option[:label]}</div>
              <div :if={option[:description]} class="pc-radio-card__description">
                {option[:description]}
              </div>
            </div>
          </label>
        <% end %>
        <%= if @empty_message && Enum.empty?(@options) do %>
          <div class="pc-radio-card-group--empty-message">
            {@empty_message}
          </div>
        <% end %>
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  # Hidden Input
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

  # Password with viewable toggle
  def field(%{type: "password", viewable: true} = assigns) do
    assigns = assign(assigns, class: [assigns.class, get_class_for_type(assigns.type)])

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label required={@required} for={@id} class={@label_class}>
        {@label}
      </.field_label>
      <div class="pc-password-field-wrapper" x-data="{ show: false }">
        <input
          x-bind:type="show ? 'text' : 'password'"
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[@class, "pc-password-field-input"]}
          required={@required}
          {@rest}
        />
        <button type="button" class="pc-password-field-toggle-button" @click="show = !show">
          <span x-show="!show" class="pc-password-field-toggle-icon-container">
            <.icon name="hero-eye-solid" class="pc-password-field-toggle-icon" />
          </span>
          <span x-show="show" class="pc-password-field-toggle-icon-container" style="display: none;">
            <.icon name="hero-eye-slash-solid" class="pc-password-field-toggle-icon" />
          </span>
        </button>
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  # Copyable Input
  def field(%{type: type, copyable: true} = assigns) when type in ["text", "url", "email"] do
    assigns = assign(assigns, class: [assigns.class, get_class_for_type(assigns.type)])

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label required={@required} for={@id} class={@label_class}>
        {@label}
      </.field_label>
      <div class="pc-copyable-field-wrapper" x-data="{ copied: false }">
        <input
          x-ref="copyInput"
          type={@type || "text"}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type || "text", @value)}
          class={[@class, "pc-copyable-field-input"]}
          readonly
          {@rest}
        />
        <button
          type="button"
          class="pc-copyable-field-button"
          @click="
          navigator.clipboard.writeText($refs.copyInput.value)
            .then(() => { copied = true; setTimeout(() => copied = false, 2000); })
        "
        >
          <span x-show="!copied" class="pc-copyable-field-icon-container">
            <.icon name="hero-clipboard-document-solid" class="pc-copyable-field-icon" />
          </span>
          <span x-show="copied" class="pc-copyable-field-icon-container" style="display: none;">
            <.icon name="hero-clipboard-document-check-solid" class="pc-copyable-field-icon" />
          </span>
        </button>
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  # Clearable Input
  def field(%{type: type, clearable: true} = assigns)
      when type in ["text", "search", "url", "email", "tel"] do
    assigns = assign(assigns, class: [assigns.class, get_class_for_type(assigns.type)])

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label required={@required} for={@id} class={@label_class}>
        {@label}
      </.field_label>
      <div
        class="pc-clearable-field-wrapper"
        x-data="{ showClearButton: false }"
        x-init="showClearButton = $refs.clearInput.value.length > 0"
      >
        <input
          x-ref="clearInput"
          type={@type || "text"}
          name={@name}
          id={@id}
          value={@value}
          class={[@class, "pc-clearable-field-input"]}
          required={@required}
          {@rest}
          x-on:input="showClearButton = $event.target.value.length > 0"
        />
        <button
          type="button"
          class="pc-clearable-field-button"
          x-show="showClearButton"
          x-on:click="
            $refs.clearInput.value = '';
            showClearButton = false;
            $refs.clearInput.dispatchEvent(new Event('input', { bubbles: true }));
          "
          style="display: none;"
          aria-label="Clear input"
        >
          <span class="pc-clearable-field-icon-container">
            <.icon name="hero-x-mark-solid" class="pc-clearable-field-icon" />
          </span>
        </button>
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  # Date/Time/Month/Week Inputs
  def field(%{type: type} = assigns)
      when type in ["date", "datetime-local", "time", "month", "week"] do
    assigns =
      assign(assigns,
        class: [assigns.class, "pc-date-input pc-date-picker-indicator"],
        icon_name: get_icon_for_type(assigns.type)
      )

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label required={@required} for={@id} class={@label_class}>
        {@label}
      </.field_label>
      <div class="pc-date-input-wrapper">
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={@class}
          required={@required}
          {@rest}
        />
        <div class="pc-date-input-icon">
          <.icon name={@icon_name} class="w-5 h-5 text-gray-400" />
        </div>
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  # Standard Single Range Slider
  def field(%{type: "range"} = assigns) do
    assigns = assign(assigns, class: [assigns.class, get_class_for_type(assigns.type)])

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label required={@required} for={@id} class={@label_class}>
        {@label}
      </.field_label>
      <input
        type="range"
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value("range", @value)}
        min={@range_min}
        max={@range_max}
        step={@step}
        class={@class}
        required={@required}
        {@rest}
      />
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  # Fallback for all other inputs (text, url, etc.)
  def field(assigns) do
    assigns = assign(assigns, class: [assigns.class, get_class_for_type(assigns.type)])

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label required={@required} for={@id} class={@label_class}>
        {@label}
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
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  # Wrapper and Label Helpers

  attr :class, :any, default: nil
  attr :errors, :list, default: []
  attr :name, :string
  attr :rest, :global
  slot :inner_block, required: true

  attr :no_margin, :boolean,
    default: false,
    doc: "removes the margin from the field wrapper"

  def field_wrapper(assigns) do
    ~H"""
    <div
      {@rest}
      class={[
        @class,
        "pc-form-field-wrapper",
        @no_margin && "pc-form-field-wrapper--no-margin",
        @errors != [] && "pc-form-field-wrapper--error"
      ]}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  attr :required, :boolean, default: false
  slot :inner_block, required: true

  def field_label(assigns) do
    ~H"""
    <%= if @for do %>
      <label for={@for} class={["pc-label", @class, @required && "pc-label--required"]} {@rest}>
        {render_slot(@inner_block)}
      </label>
    <% else %>
      <span class={["pc-label", @class, @required && "pc-label--required"]} {@rest}>
        {render_slot(@inner_block)}
      </span>
    <% end %>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def field_error(assigns) do
    ~H"""
    <p class="pc-form-field-error">
      {render_slot(@inner_block)}
    </p>
    """
  end

  attr :class, :any, default: nil, doc: "extra classes for the help text"
  attr :help_text, :string, default: nil, doc: "context/help for your field"
  slot :inner_block, required: false
  attr :rest, :global

  def field_help_text(assigns) do
    ~H"""
    <div :if={render_slot(@inner_block) || @help_text} class={["pc-form-help-text", @class]} {@rest}>
      {render_slot(@inner_block) || @help_text}
    </div>
    """
  end

  # Utility Functions

  defp get_class_for_type("radio"), do: "pc-radio"
  defp get_class_for_type("checkbox"), do: "pc-checkbox"
  defp get_class_for_type("color"), do: "pc-color-input"
  defp get_class_for_type("file"), do: "pc-file-input"
  defp get_class_for_type("range-dual"), do: "pc-slider-input"
  defp get_class_for_type("range"), do: "pc-range-input"
  defp get_class_for_type(_), do: "pc-text-input"

  defp get_icon_for_type("date"), do: "hero-calendar"
  defp get_icon_for_type("datetime-local"), do: "hero-calendar"
  defp get_icon_for_type("month"), do: "hero-calendar"
  defp get_icon_for_type("week"), do: "hero-calendar"
  defp get_icon_for_type("time"), do: "hero-clock"

  # Helper functions for dual range slider
  defp calculate_slider_position(nil, _range_min, _range_max), do: 0

  defp calculate_slider_position(_value, range_min, range_max)
       when range_min == range_max,
       do: 0

  defp calculate_slider_position(value, range_min, range_max) when is_integer(value) do
    round((value - range_min) / (range_max - range_min) * 100)
  end

  if Code.ensure_loaded?(Money) do
    defp calculate_slider_position(value, range_min, range_max) when is_struct(value, Money) do
      int_value =
        value
        |> Money.to_decimal()
        |> Decimal.round(0)
        |> Decimal.to_integer()

      round((int_value - range_min) / (range_max - range_min) * 100)
    end

    defp format_range_value(value) when is_struct(value, Money),
      do: Money.to_string!(value, no_fraction_if_integer: true)
  else
    defp calculate_slider_position(value, _range_min, _range_max) when is_struct(value, Money),
      do: 0

    defp format_range_value(value) when is_struct(value, Money), do: "0"
  end

  defp format_range_value(value) when is_integer(value), do: Integer.to_string(value)
  defp format_range_value(value) when is_float(value), do: Float.to_string(value)
  defp format_range_value(_), do: "0"

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
