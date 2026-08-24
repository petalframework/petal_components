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
      ~w(checkbox checkbox-group color combobox date datetime-local email file hidden month number number-field password
               range range-dual radio-group radio-card search select switch tel text textarea time url week),
    doc: "the type of input"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "the size of the switch (xs, sm, md, lg or xl) or radio card (sm, md or lg)"

  attr :variant, :any,
    default: "outline",
    doc:
      ~s(radio-card: outline, classic. switch: "pill" swaps the round thumb for an iOS-style capsule; the track is unchanged)

  attr :combo_variant, :string,
    values: ["input", "trigger"],
    doc: "combobox only: the anatomy - searchable input (default) or select-like trigger button"

  attr :number_variant, :string,
    values: ["stacked", "split", "plain"],
    doc:
      "number-field only: the anatomy - \"stacked\" spinner, the default, \"split\" minus/plus, or \"plain\" with no buttons"

  attr :indicator_position, :string,
    default: "end",
    values: ~w(start end corner),
    doc:
      ~s(where the radio-card dot sits: "end" centres it on the right edge, "corner" floats it top-right - the tile-grid look, "start" leads the text)

  attr :indicator, :boolean,
    default: false,
    doc: "radio-card only: shows a radio dot inside each card"

  attr :viewable, :boolean,
    default: false,
    doc: "If true, adds a toggle to show/hide the password text"

  attr :copyable, :boolean,
    default: false,
    doc: "If true, adds a copy button to the field and disables the input"

  attr :copy_icon, :string,
    default: "hero-clipboard-document",
    doc: "Icon name for the copy button"

  attr :copied_icon, :string,
    default: "hero-check",
    doc: "Icon name shown after copying (rendered in the success colour)"

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

  attr :fill, :boolean,
    default: false,
    doc: ~s(type="range" only: fills the track with the primary colour up to the thumb)

  # Dual range slider — requires min_field + max_field instead of the standard field attr.
  attr :min_field, Phoenix.HTML.FormField,
    doc: "form field for the minimum value; required for type=\"range-dual\""

  attr :max_field, Phoenix.HTML.FormField,
    doc: "form field for the maximum value; required for type=\"range-dual\""

  attr :range_min, :any,
    default: 0,
    doc: "absolute lower bound of the range; used with type=\"range-dual\""

  attr :range_max, :any,
    default: 100,
    doc: "absolute upper bound of the range; used with type=\"range-dual\""

  attr :range_min_label, :string,
    default: nil,
    doc: "override label for the lower bound; defaults to the formatted range_min value"

  attr :range_max_label, :string,
    default: nil,
    doc: "override label for the upper bound; defaults to the formatted range_max value"

  attr :value_prefix, :string,
    default: "",
    doc: ~s(string prepended to displayed values, e.g. "$"; used with type="range-dual")

  attr :value_suffix, :string,
    default: "",
    doc: ~s(string appended to displayed values, e.g. "%"; used with type="range-dual")

  attr :rest, :global,
    include:
      ~w(autocomplete autocorrect autocapitalize disabled form max maxlength min minlength list
    pattern placeholder readonly required size step value name multiple prompt default year month day hour minute second builder options layout cols rows wrap checked accept
    free_text create create_label max_items count_label search_placeholder listbox_label no_results_text results_label clear_label remove_label loading_label remote_options_event_name remote_options_target form_id
    big_step precision decrement_label increment_label inputmode),
    doc: "All other props go on the input"

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

  # Without a form field, `value` and `label` are plain optional attrs - a bare
  # `<.field type="file" name="upload" />` must render, not raise. They have no
  # attr default because the form-field clause above derives them via assign_new.
  # range-dual is exempt: it derives its label from min_field, not name.
  def field(assigns)
      when assigns.type != "range-dual" and
             (not is_map_key(assigns, :value) or not is_map_key(assigns, :label)) do
    assigns
    |> assign_new(:value, fn -> nil end)
    |> assign_new(:label, fn ->
      if assigns[:name], do: PhoenixHTMLHelpers.Form.humanize(assigns.name)
    end)
    |> field()
  end

  def field(%{type: "checkbox"} = assigns) do
    assigns =
      assigns
      |> assign_new(:value, fn -> nil end)
      |> assign_new(:checked, fn %{value: value} ->
        Phoenix.HTML.Form.normalize_value("checkbox", value)
      end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <label class={["pc-checkbox-label", @label_class]}>
        <input :if={!@rest[:disabled]} type="hidden" name={@name} value="false" />
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
        <div class="pc-checkbox-text">
          <span class={[@required && "pc-label--required"]}>
            {@label}
          </span>
          <.field_help_text help_text={@help_text} class="pc-checkbox-text__help" />
        </div>
      </label>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
    </.field_wrapper>
    """
  end

  def field(%{type: "select"} = assigns) do
    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label required={@required} for={@id} class={@label_class}>
        {@label}
      </.field_label>
      <input :if={@multiple} type="hidden" name={@name} value="" />
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

  def field(%{type: "combobox"} = assigns) do
    assigns =
      assigns
      |> assign_new(:options, fn -> [] end)
      # the field size family spans xs-xl; the combobox speaks sm/md/lg
      |> assign(
        :combo_size,
        case assigns.size do
          "xs" -> "sm"
          "xl" -> "lg"
          s -> s
        end
      )
      # :variant belongs to radio-card here - the combobox anatomy rides
      # combo_variant ("input" | "trigger")
      |> assign_new(:combo_variant, fn -> "input" end)
      # combo_box derives its own id from the name when none is passed, and
      # the label's for= has to name a control that actually exists - so
      # resolve the id HERE and pass it down. One id, no way to drift.
      # No identity at all (no id, no field, nil/empty name) resolves to
      # nil so the call flows into combo_box's own ArgumentError - a loud
      # programming error beats minting the same constant id for every
      # instance on the page.
      |> then(fn a ->
        id =
          a.id ||
            case a.name do
              name when name in [nil, ""] -> nil
              name -> "combo_box_" <> String.replace(name, ~r/[^A-Za-z0-9_]/, "_")
            end

        a
        |> assign(:combo_id, id)
        |> assign(
          :combo_label_for,
          id && if(a.combo_variant == "trigger", do: "#{id}-trigger", else: "#{id}-input")
        )
      end)
      # the combobox appends [] itself for multiple; the hidden empty
      # input must post the SAME name or a bare-name field submits a
      # mixed shape (the FormField path appends [] upstream already)
      |> then(fn a ->
        assign(
          a,
          :hidden_name,
          if(a.multiple && a.name && !String.ends_with?(a.name, "[]"),
            do: a.name <> "[]",
            else: a.name
          )
        )
      end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <%!-- @id lands on the combobox WRAPPER (a roleless div), so for= has to
      name the focusable control inside it: the input, or the trigger button
      in the trigger anatomy. Both are labelable elements, so clicking the
      label focuses the real control. The label also rides down as the
      combobox's accessible name. --%>
      <.field_label required={@required} for={@combo_label_for} class={@label_class}>
        {@label}
      </.field_label>
      <input :if={@multiple} type="hidden" name={@hidden_name} value="" />
      <PetalComponents.ComboBox.combo_box
        id={@combo_id}
        name={@name}
        label={@label}
        value={@selected || @value}
        options={@options}
        multiple={@multiple}
        required={@required}
        size={@combo_size}
        variant={@combo_variant}
        clearable={@clearable}
        class={@class}
        {@rest}
      />
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  # The spinbutton flavour of a number input. It paints its own surface (the
  # input group), so the wrapper contributes the label, help text and the
  # error tone that `.pc-form-field-wrapper--error .pc-input-group` picks up.
  def field(%{type: "number-field"} = assigns) do
    assigns =
      assigns
      # the field size family spans xs-xl; the number field speaks sm/md/lg
      |> assign(
        :number_size,
        case assigns.size do
          "xs" -> "sm"
          "xl" -> "lg"
          s -> s
        end
      )
      |> assign_new(:number_variant, fn -> "stacked" end)
      # the label's for= has to name the control that actually exists, and the
      # number field derives its own id from the name when none is passed -
      # so resolve it HERE, once, and hand it down.
      |> then(fn a ->
        assign(a, :id, PetalComponents.NumberField.resolve_id(a.id, a[:name]))
      end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label required={@required} for={@id} class={@label_class}>
        {@label}
      </.field_label>
      <PetalComponents.NumberField.number_field
        id={@id}
        name={@name}
        value={@value}
        variant={@number_variant}
        size={@number_size}
        class={@class}
        required={@required}
        {@rest}
      />
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

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

  def field(%{type: "switch"} = assigns) do
    assigns =
      assigns
      |> assign_new(:value, fn -> nil end)
      |> assign_new(:checked, fn %{value: value} ->
        Phoenix.HTML.Form.normalize_value("checkbox", value)
      end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <label class={["pc-checkbox-label", @label_class]}>
        <input :if={!@rest[:disabled]} type="hidden" name={@name} value="false" />
        <label class={["pc-switch", "pc-switch--#{@size}", @variant == "pill" && "pc-switch--pill"]}>
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
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label required={@required} class={@label_class}>
        {@label}
      </.field_label>
      <input :if={!@rest[:disabled]} type="hidden" name={@name <> "[]"} value="" />
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
              {label}
            </div>
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
                to_string(value) == to_string(@value) || to_string(value) == to_string(@checked)
              }
              class="pc-radio"
              {@rest}
            />
            <div>
              {label}
            </div>
          </label>
        <% end %>

        <%= if @empty_message && Enum.empty?(@options) do %>
          <div class="pc-radio-group--empty-message">
            {@empty_message}
          </div>
        <% end %>
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

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
            (@indicator || option[:icon] || option[:image]) && "pc-radio-card--indicator",
            @indicator && "pc-radio-card--indicator-#{@indicator_position}",
            (option[:disabled] || @rest[:disabled]) && "pc-radio-card--disabled"
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
            <span
              :if={@indicator && @indicator_position == "corner"}
              class="pc-radio-card__dot pc-radio-card__dot--corner"
              aria-hidden="true"
            ></span>
            <div class={[
              "pc-radio-card__content",
              (@indicator || option[:icon] || option[:image]) && "pc-radio-card__content--indicator"
            ]}>
              <span
                :if={@indicator && @indicator_position == "start"}
                class="pc-radio-card__dot"
                aria-hidden="true"
              ></span>
              <img :if={option[:image]} src={option[:image]} alt="" class="pc-radio-card__image" />
              <span :if={!option[:image] && option[:icon]} class="pc-radio-card__icon">
                <.icon name={option[:icon]} class="pc-radio-card__icon-glyph" />
              </span>
              <div class="pc-radio-card__text">
                <div class="pc-radio-card__label">{option[:label]}</div>
                <div :if={option[:description]} class="pc-radio-card__description">
                  {option[:description]}
                </div>
              </div>
              <span
                :if={@indicator && @indicator_position == "end"}
                class="pc-radio-card__dot"
                aria-hidden="true"
              ></span>
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

  def field(%{type: "password", viewable: true} = assigns) do
    assigns =
      assigns
      |> assign(class: [assigns.class, get_class_for_type(assigns.type)])
      |> assign_new(:wrapper_id, fn -> "pc-pw-#{Ecto.UUID.generate()}" end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label required={@required} for={@id} class={@label_class}>
        {@label}
      </.field_label>
      <div class="pc-password-field-wrapper" id={@wrapper_id} phx-hook="PetalPasswordToggle">
        <input
          type="password"
          data-pc-password-input
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[@class, "pc-password-field-input"]}
          required={@required}
          {@rest}
        />
        <button
          type="button"
          class="pc-password-field-toggle-button"
          data-pc-password-toggle
          aria-label="Show password"
          aria-pressed="false"
        >
          <span data-pc-icon-show class="pc-password-field-toggle-icon-container">
            <.icon name="hero-eye" class="pc-password-field-toggle-icon" />
          </span>
          <span data-pc-icon-hide class="pc-password-field-toggle-icon-container hidden">
            <.icon name="hero-eye-slash" class="pc-password-field-toggle-icon" />
          </span>
        </button>
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: type, copyable: true} = assigns) when type in ["text", "url", "email"] do
    assigns =
      assigns
      |> assign(class: [assigns.class, get_class_for_type(assigns.type)])
      |> assign_new(:wrapper_id, fn -> "pc-copy-#{Ecto.UUID.generate()}" end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <!-- Field Label -->
      <.field_label required={@required} for={@id} class={@label_class}>
        {@label}
      </.field_label>
      <!-- Copyable Field Wrapper -->
      <div class="pc-copyable-field-wrapper" id={@wrapper_id} phx-hook="PetalCopyInput">
        <!-- Input Field -->
        <input
          data-pc-copy-input
          type={@type || "text"}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type || "text", @value)}
          class={[@class, "pc-copyable-field-input"]}
          readonly
          {@rest}
        />
        <!-- Copy Button -->
        <button
          type="button"
          class="pc-copyable-field-button"
          data-pc-copy-btn
          aria-label="Copy to clipboard"
        >
          <!-- Copy Icon -->
          <span data-pc-copy-default class="pc-copyable-field-icon-container">
            <.icon name={@copy_icon} class="pc-copyable-field-icon" />
          </span>
          <!-- Copied Icon -->
          <span data-pc-copy-done class="pc-copyable-field-icon-container hidden">
            <.icon name={@copied_icon} class="pc-copyable-field-icon pc-copyable-field-icon--done" />
          </span>
        </button>
        <span data-pc-copy-announce class="sr-only" aria-live="polite"></span>
      </div>
      <!-- Error Message -->
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <!-- Help Text -->
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: type, clearable: true} = assigns)
      when type in ["text", "search", "url", "email", "tel"] do
    assigns =
      assigns
      |> assign(class: [assigns.class, get_class_for_type(assigns.type)])
      |> assign_new(:wrapper_id, fn -> "pc-clear-#{Ecto.UUID.generate()}" end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <!-- Field Label -->
      <.field_label required={@required} for={@id} class={@label_class}>
        {@label}
      </.field_label>
      <!-- Clearable Field Wrapper -->
      <div class="pc-clearable-field-wrapper" id={@wrapper_id} phx-hook="PetalClearableInput">
        <!-- Input Field -->
        <input
          data-pc-clear-input
          type={@type || "text"}
          name={@name}
          id={@id}
          value={@value}
          class={[@class, "pc-clearable-field-input"]}
          required={@required}
          {@rest}
        />
        <!-- Clear Button -->
        <button
          type="button"
          class="pc-clearable-field-button hidden"
          data-pc-clear-btn
          aria-label="Clear input"
        >
          <!-- Clear Icon -->
          <span class="pc-clearable-field-icon-container">
            <.icon name="hero-x-mark-mini" class="pc-clearable-field-icon" />
          </span>
        </button>
      </div>
      <!-- Error Message -->
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <!-- Help Text -->
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

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
        <span class="pc-date-input-icon" aria-hidden="true">
          <.icon name={@icon_name} class="pc-date-input-icon-glyph" />
        </span>
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: "range-dual"} = assigns) do
    min_errors =
      if used_input?(assigns.min_field),
        do: Enum.map(assigns.min_field.errors, &translate_error(&1)),
        else: []

    max_errors =
      if used_input?(assigns.max_field),
        do: Enum.map(assigns.max_field.errors, &translate_error(&1)),
        else: []

    assigns =
      assigns
      |> assign(:errors, Enum.uniq(min_errors ++ max_errors))
      |> assign_new(:label, fn -> PhoenixHTMLHelpers.Form.humanize(assigns.min_field.field) end)
      |> assign(:id, assigns.id || assigns.min_field.id)

    ~H"""
    <.field_wrapper
      errors={@errors}
      name={@min_field.name}
      class={@wrapper_class}
      no_margin={@no_margin}
    >
      <.field_label class={@label_class}>
        {@label}
      </.field_label>
      <PetalComponents.Input.input
        type="range-dual"
        min_field={@min_field}
        max_field={@max_field}
        range_min={@range_min}
        range_max={@range_max}
        range_min_label={@range_min_label}
        range_max_label={@range_max_label}
        value_prefix={@value_prefix}
        value_suffix={@value_suffix}
        id={@id}
        class={@class}
        {@rest}
      />
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  # All other inputs (text, url, etc.) are handled here...
  # Range routes through Input.input so the fill option gets its hook and
  # server-rendered initial fill; the wrapper carries the label and help.
  def field(%{type: "range"} = assigns) do
    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label :if={@label} required={@required} for={@id} class={@label_class}>
        {@label}
      </.field_label>
      <PetalComponents.Input.input
        type="range"
        fill={@fill}
        name={@name}
        id={@id}
        value={@value}
        class={@class}
        required={@required}
        {@rest}
      />
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

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

  defp get_class_for_type("radio"), do: "pc-radio"
  defp get_class_for_type("checkbox"), do: "pc-checkbox"
  defp get_class_for_type("color"), do: "pc-color-input"
  defp get_class_for_type("file"), do: "pc-file-input"
  defp get_class_for_type("range"), do: "pc-range-input"
  defp get_class_for_type(_), do: "pc-text-input"

  defp get_icon_for_type("date"), do: "hero-calendar"
  defp get_icon_for_type("datetime-local"), do: "hero-calendar"
  defp get_icon_for_type("month"), do: "hero-calendar"
  defp get_icon_for_type("week"), do: "hero-calendar"
  defp get_icon_for_type("time"), do: "hero-clock"

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
