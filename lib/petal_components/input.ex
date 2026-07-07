defmodule PetalComponents.Input do
  use Phoenix.Component
  import PetalComponents.Icon

  @moduledoc """
  Renders pure inputs (no label or errors).
  """

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range range-dual radio search select switch tel text textarea time url week)

  attr :size, :string, default: "md", values: ~w(xs sm md lg xl), doc: "the size of the switch"

  attr :viewable, :boolean,
    default: false,
    doc: "If true, adds a toggle to show/hide the password text"

  attr :copyable, :boolean,
    default: false,
    doc: "If true, adds a copy button to the field and disables the input"

  attr :clearable, :boolean,
    default: false,
    doc: "If true, adds a clear button to clear the field value"

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil, doc: "the class to add to the input"

  # Dual range slider — requires min_field + max_field instead of the standard field attr.
  # Needs the PetalDualRangeSlider hook registered in your LiveSocket (included in the
  # petal_components JS bundle via `import PetalComponents from ".../petal_components"`).
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
    pattern placeholder readonly required size step value name multiple prompt selected default year month day hour minute second builder options layout cols rows wrap checked accept)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign_new(:name, fn ->
      if assigns.multiple, do: field.name <> "[]", else: field.name
    end)
    |> assign_new(:value, fn -> field.value end)
    |> assign_new(:label, fn -> PhoenixHTMLHelpers.Form.humanize(field.field) end)
    |> assign(class: [assigns.class, get_class_for_type(assigns.type)])
    |> input()
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <select id={@id} name={@name} class={[@class, "pc-text-input"]} multiple={@multiple} {@rest}>
      <option :if={@prompt} value="">{@prompt}</option>
      {Phoenix.HTML.Form.options_for_select(@options, @value)}
    </select>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <textarea id={@id} name={@name} class={[@class, "pc-text-input"]} {@rest}><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
    """
  end

  def input(%{type: "switch"} = assigns) do
    assigns =
      assigns
      |> assign_new(:value, fn -> nil end)
      |> assign_new(:checked, fn %{value: value} ->
        Phoenix.HTML.Form.normalize_value("checkbox", value)
      end)

    ~H"""
    <label class={["pc-switch", "pc-switch--#{@size}"]}>
      <input
        type="checkbox"
        id={@id}
        name={@name}
        value="true"
        checked={@checked}
        class={["sr-only peer", @class]}
        {@rest}
      />

      <span class={["pc-switch__fake-input", "pc-switch__fake-input--#{@size}"]}></span>
      <span class={["pc-switch__fake-input-bg", "pc-switch__fake-input-bg--#{@size}"]}></span>
    </label>
    """
  end

  def input(%{type: "password", viewable: true} = assigns) do
    assigns = assign(assigns, class: [assigns.class, get_class_for_type(assigns.type)])

    assigns = assign_new(assigns, :wrapper_id, fn -> "pc-pw-#{Ecto.UUID.generate()}" end)

    ~H"""
    <div class="pc-password-field-wrapper" id={@wrapper_id} phx-hook="PetalPasswordToggle">
      <input
        type="password"
        data-pc-password-input
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[@class, "pc-password-field-input"]}
        {@rest}
      />
      <button type="button" class="pc-password-field-toggle-button" data-pc-password-toggle>
        <span data-pc-icon-show class="pc-password-field-toggle-icon-container">
          <.icon name="hero-eye-solid" class="pc-password-field-toggle-icon" />
        </span>
        <span data-pc-icon-hide class="pc-password-field-toggle-icon-container hidden">
          <.icon name="hero-eye-slash-solid" class="pc-password-field-toggle-icon" />
        </span>
      </button>
    </div>
    """
  end

  def input(%{type: type, copyable: true} = assigns) when type in ["text", "url", "email"] do
    assigns = assign(assigns, class: [assigns.class, get_class_for_type(assigns.type)])

    assigns = assign_new(assigns, :wrapper_id, fn -> "pc-copy-#{Ecto.UUID.generate()}" end)

    ~H"""
    <div class="pc-copyable-field-wrapper" id={@wrapper_id} phx-hook="PetalCopyInput">
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
      <button type="button" class="pc-copyable-field-button" data-pc-copy-btn>
        <span data-pc-copy-default class="pc-copyable-field-icon-container">
          <.icon name="hero-clipboard-document-solid" class="pc-copyable-field-icon" />
        </span>
        <span data-pc-copy-done class="pc-copyable-field-icon-container hidden">
          <.icon name="hero-clipboard-document-check-solid" class="pc-copyable-field-icon" />
        </span>
      </button>
    </div>
    """
  end

  def input(%{type: type, clearable: true} = assigns)
      when type in ["text", "search", "url", "email", "tel"] do
    assigns = assign(assigns, class: [assigns.class, get_class_for_type(assigns.type)])

    assigns = assign_new(assigns, :wrapper_id, fn -> "pc-clear-#{Ecto.UUID.generate()}" end)

    ~H"""
    <div class="pc-clearable-field-wrapper" id={@wrapper_id} phx-hook="PetalClearableInput">
      <input
        data-pc-clear-input
        type={@type || "text"}
        name={@name}
        id={@id}
        value={@value}
        class={[@class, "pc-clearable-field-input"]}
        {@rest}
      />
      <button
        type="button"
        class="pc-clearable-field-button hidden"
        data-pc-clear-btn
        aria-label="Clear input"
      >
        <span class="pc-clearable-field-icon-container">
          <.icon name="hero-x-mark-solid" class="pc-clearable-field-icon" />
        </span>
      </button>
    </div>
    """
  end

  def input(%{type: type} = assigns)
      when type in ["date", "datetime-local", "time", "month", "week"] do
    assigns =
      assign(assigns,
        class: [assigns.class, "pc-date-input pc-date-picker-indicator"],
        icon_name: get_icon_for_type(assigns.type)
      )

    ~H"""
    <div class="pc-date-input-wrapper">
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={@class}
        {@rest}
      />
      <button
        type="button"
        class="pc-date-input-icon"
        onclick="this.previousElementSibling.showPicker()"
      >
        <.icon name={@icon_name} class="w-5 h-5 text-gray-400" />
      </button>
    </div>
    """
  end

  def input(%{type: "range-dual"} = assigns) do
    min_value = coerce_range_value(assigns.min_field.value, assigns.range_min)
    max_value = coerce_range_value(assigns.max_field.value, assigns.range_max)
    step = assigns.rest[:step] || 1
    disabled = assigns.rest[:disabled] || false

    assigns =
      assigns
      |> assign(:min_value, min_value)
      |> assign(:max_value, max_value)
      |> assign(:step, step)
      |> assign(:disabled, disabled)
      |> assign(:id, assigns.id || "pc-dual-range-#{Ecto.UUID.generate()}")

    ~H"""
    <div
      id={@id}
      class={["pc-dual-range", @disabled && "pc-dual-range--disabled", @class]}
      phx-hook="PetalDualRangeSlider"
      phx-update="ignore"
      data-range-min={@range_min}
      data-range-max={@range_max}
      data-value-prefix={@value_prefix}
      data-value-suffix={@value_suffix}
    >
      <div class="pc-dual-range__track-wrapper">
        <div class="pc-dual-range__track"></div>
        <div
          class="pc-dual-range__range"
          data-pc-range-track
          style={"left: #{calculate_slider_position(@min_value, @range_min, @range_max)}%; right: #{100 - calculate_slider_position(@max_value, @range_min, @range_max)}%;"}
        >
        </div>
        <input
          type="range"
          min={@range_min}
          max={@range_max}
          step={@step}
          name={@min_field.name}
          value={@min_value}
          id={@id <> "_min"}
          class="pc-dual-range__thumb"
          data-pc-range-min
          disabled={@disabled}
          aria-label="Minimum"
          aria-valuemin={@range_min}
          aria-valuemax={@range_max}
          aria-valuenow={@min_value}
        />
        <input
          type="range"
          min={@range_min}
          max={@range_max}
          step={@step}
          name={@max_field.name}
          value={@max_value}
          id={@id <> "_max"}
          class="pc-dual-range__thumb"
          data-pc-range-max
          disabled={@disabled}
          aria-label="Maximum"
          aria-valuemin={@range_min}
          aria-valuemax={@range_max}
          aria-valuenow={@max_value}
        />
      </div>
      <div class="pc-dual-range__labels">
        <span class="pc-dual-range__bound">
          {@range_min_label || "#{@value_prefix}#{@range_min}#{@value_suffix}"}
        </span>
        <span class="pc-dual-range__display" data-pc-range-display>
          {@value_prefix}{@min_value}{@value_suffix} – {@value_prefix}{@max_value}{@value_suffix}
        </span>
        <span class="pc-dual-range__bound pc-dual-range__bound--end">
          {@range_max_label || "#{@value_prefix}#{@range_max}#{@value_suffix}"}
        </span>
      </div>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <input
      type={@type}
      name={@name}
      id={@id}
      value={Phoenix.HTML.Form.normalize_value(@type, @value)}
      class={[@class, get_class_for_type(@type)]}
      {@rest}
    />
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

  # Normalise a raw form field value (string, integer, float, or nil) to a number,
  # falling back to `default` when the value is absent or unparseable.
  defp coerce_range_value(nil, default), do: default
  defp coerce_range_value(v, _default) when is_integer(v) or is_float(v), do: v

  defp coerce_range_value(v, default) when is_binary(v) do
    case Integer.parse(v) do
      {int, ""} ->
        int

      _ ->
        case Float.parse(v) do
          {float, ""} -> float
          _ -> default
        end
    end
  end

  defp coerce_range_value(_, default), do: default

  # Returns the percentage position (0–100) of `value` within [range_min, range_max].
  # Used to set the server-rendered initial left/right style on the range highlight.
  defp calculate_slider_position(_value, range_min, range_max) when range_max == range_min,
    do: 0

  defp calculate_slider_position(value, range_min, range_max) do
    value = coerce_range_value(value, range_min)
    round((value - range_min) / (range_max - range_min) * 100)
  end
end
