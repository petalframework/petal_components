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
               range radio search select switch tel text textarea time url week)

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
      <option :if={@prompt} value=""><%= @prompt %></option>
      <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
    </select>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <textarea id={@id} name={@name} class={[@class, "pc-text-input"]} {@rest}><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
    """
  end

  def input(%{type: "switch", value: value} = assigns) do
    assigns =
      assigns
      |> assign_new(:checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

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

    ~H"""
    <div class="pc-password-field-wrapper" x-data="{ show: false }">
      <input
        x-bind:type="show ? 'text' : 'password'"
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[@class, "pc-password-field-input"]}
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
    """
  end

  def input(%{type: type, copyable: true} = assigns) when type in ["text", "url", "email"] do
    assigns = assign(assigns, class: [assigns.class, get_class_for_type(assigns.type)])

    ~H"""
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
    """
  end

  def input(%{type: type, clearable: true} = assigns)
      when type in ["text", "search", "url", "email", "tel"] do
    assigns = assign(assigns, class: [assigns.class, get_class_for_type(assigns.type)])

    ~H"""
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
          $refs.clearInput.dispatchEvent(new Event('input'));
        "
        style="display: none;"
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

  def input(assigns) do
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
end
