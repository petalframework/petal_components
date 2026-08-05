defmodule PetalComponents.ComboBox do
  @moduledoc """
  A searchable select: type to filter, arrow keys to move, Enter to choose.

  The visible input is display-only chrome; the real form control is a
  hidden native `<select>` kept in sync by the `PetalComboBox` hook. That
  makes the component form-native: changesets, `phx-change` and LiveView
  form recovery all work exactly as they do for a plain select - there is
  no `phx-update="ignore"` island and no client-owned state to lose.

  Filtering happens client-side in the hook (zero dependencies), reusing
  the command palette's scoring: value prefix beats word-boundary prefix
  beats substring beats fuzzy subsequence. Options are hidden, never
  reordered - the server owns DOM order, which keeps the listbox safe
  under LiveView patches.

  The markup follows the WAI-ARIA combobox pattern: the input carries
  `role="combobox"` and `aria-activedescendant`, the panel is a
  `listbox`, options are `option`s. Keyboard focus never leaves the
  input; the highlight is virtual (`data-highlighted`), and
  `aria-selected` means the *chosen* value - the check-marked one - not
  the highlight.

      <.form :let={f} for={@form} phx-change="validate">
        <.combo_box field={f[:country]} options={["Australia", "Japan", "Portugal"]} />
      </.form>

  Options accept the shapes `select` users expect:

    * `"Australia"` - label and value are the string
    * `{"Australia", "au"}` - label / value
    * `{"Australia", "au", disabled: true}` - with per-option opts
    * `{"Oceania", [...]}` - a group: heading plus its options
  """
  use Phoenix.Component

  import PetalComponents.Icon

  attr :id, :string,
    default: nil,
    doc: "unique id; the PetalComboBox hook mounts here. Derived from field or name when absent"

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "a form field, e.g. f[:country] - supplies name, value and id"

  attr :name, :string, default: nil, doc: "input name, when not using field"
  attr :value, :any, default: nil, doc: "current value, when not using field (overrides field)"

  attr :options, :list,
    default: [],
    doc:
      "strings, {label, value} tuples, {label, value, opts} (opts: disabled: true), or {group_label, options} groups"

  attr :placeholder, :string, default: "Select an option…"
  attr :disabled, :boolean, default: false

  attr :loop, :boolean,
    default: false,
    doc: "arrow keys wrap from the last option to the first and back"

  attr :required, :boolean,
    default: false,
    doc: "renders on the hidden select, so native required validation guards the real control"

  attr :form_id, :string,
    default: nil,
    doc: "the form this control belongs to when rendered outside it (the select's form attribute)"

  attr :no_results_text, :string, default: "No results found"
  attr :listbox_label, :string, default: "Options", doc: "accessible name for the listbox"
  attr :class, :any, default: nil, doc: "extra classes for the wrapper"
  attr :rest, :global

  def combo_box(assigns) do
    groups = normalize_options(assigns.options)
    value = current_value(assigns)
    id = resolve_id(assigns)

    assigns =
      assigns
      |> assign(:groups, groups)
      |> assign(:current_value, value)
      |> assign(:id, id)
      |> assign(:input_name, assigns.name || (assigns.field && assigns.field.name))
      |> assign(:selected_label, selected_label(groups, value))

    ~H"""
    <div
      id={@id}
      class={["pc-combo-box", @class]}
      phx-hook="PetalComboBox"
      data-loop={@loop && "true"}
      {@rest}
    >
      <select
        id={"#{@id}-select"}
        name={@input_name}
        class="pc-combo-box__select"
        tabindex="-1"
        aria-hidden="true"
        disabled={@disabled}
        required={@required}
        form={@form_id}
      >
        <option value=""></option>
        <%= for group <- @groups do %>
          <%= if group.label do %>
            <optgroup label={group.label}>
              <option
                :for={opt <- group.options}
                value={opt.value}
                selected={selected?(opt, @current_value)}
                disabled={opt.disabled}
              >
                {opt.label}
              </option>
            </optgroup>
          <% else %>
            <option
              :for={opt <- group.options}
              value={opt.value}
              selected={selected?(opt, @current_value)}
              disabled={opt.disabled}
            >
              {opt.label}
            </option>
          <% end %>
        <% end %>
      </select>

      <div class="pc-combo-box__control">
        <input
          type="text"
          id={"#{@id}-input"}
          class="pc-combo-box__input"
          role="combobox"
          aria-expanded="false"
          aria-autocomplete="list"
          aria-controls={"#{@id}-listbox"}
          autocomplete="off"
          autocorrect="off"
          spellcheck="false"
          placeholder={@placeholder}
          value={@selected_label}
          disabled={@disabled}
        />
        <.icon name="hero-chevron-down-mini" class="pc-combo-box__chevron" />
      </div>

      <div class="pc-combo-box__panel" data-pc-combo-panel hidden>
        <div
          role="listbox"
          id={"#{@id}-listbox"}
          class="pc-combo-box__list"
          aria-label={@listbox_label}
        >
          <%= for group <- @groups do %>
            <%= if group.label do %>
              <div class="pc-combo-box__group" role="group" data-pc-combo-group>
                <div class="pc-combo-box__group-heading" aria-hidden="true">{group.label}</div>
                <.option_items options={group.options} current_value={@current_value} />
              </div>
            <% else %>
              <.option_items options={group.options} current_value={@current_value} />
            <% end %>
          <% end %>
          <div class="pc-combo-box__empty" data-pc-combo-empty hidden>{@no_results_text}</div>
        </div>
      </div>
    </div>
    """
  end

  defp option_items(assigns) do
    ~H"""
    <div
      :for={opt <- @options}
      role="option"
      class="pc-combo-box__option"
      data-pc-combo-item
      data-value={opt.value}
      data-label={opt.label}
      data-disabled={opt.disabled && "true"}
      aria-disabled={opt.disabled && "true"}
      aria-selected={to_string(selected?(opt, @current_value))}
    >
      <span class="pc-combo-box__option-label">{opt.label}</span>
      <.icon name="hero-check-mini" class="pc-combo-box__check" />
    </div>
    """
  end

  # -- option normalization -------------------------------------------------

  # Everything becomes [%{label: group_or_nil, options: [%{label, value, disabled}]}].
  # Consecutive flat options gather under a nil group so rendering has one shape,
  # and groups keep their position between them.
  defp normalize_options(options) do
    options
    |> Enum.chunk_by(&group?/1)
    |> Enum.flat_map(fn [first | _] = chunk ->
      if group?(first) do
        Enum.map(chunk, fn {label, opts} ->
          %{label: to_string(label), options: Enum.map(opts, &normalize_option/1)}
        end)
      else
        [%{label: nil, options: Enum.map(chunk, &normalize_option/1)}]
      end
    end)
  end

  defp group?({_label, options}) when is_list(options), do: true
  defp group?(_entry), do: false

  defp normalize_option({label, value, opts}) when is_list(opts) do
    %{
      label: to_string(label),
      value: to_string(value),
      disabled: Keyword.get(opts, :disabled, false)
    }
  end

  defp normalize_option({label, value}) do
    %{label: to_string(label), value: to_string(value), disabled: false}
  end

  defp normalize_option(value) when is_binary(value) or is_atom(value) or is_number(value) do
    %{label: to_string(value), value: to_string(value), disabled: false}
  end

  # -- value / id resolution ------------------------------------------------

  defp current_value(%{value: value}) when not is_nil(value), do: to_string(value)
  defp current_value(%{field: %{value: value}}) when not is_nil(value), do: to_string(value)
  defp current_value(_assigns), do: nil

  defp selected?(_opt, nil), do: false
  defp selected?(opt, value), do: opt.value == value

  defp selected_label(groups, value) do
    groups
    |> Enum.flat_map(& &1.options)
    |> Enum.find_value(fn opt -> if selected?(opt, value), do: opt.label end)
  end

  defp resolve_id(%{id: id}) when is_binary(id), do: id
  defp resolve_id(%{field: %{id: id}}) when is_binary(id), do: "#{id}_combo_box"

  defp resolve_id(%{name: name}) when is_binary(name) do
    "combo_box_" <> String.replace(name, ~r/[^A-Za-z0-9_]/, "_")
  end

  defp resolve_id(_assigns) do
    raise ArgumentError,
          "combo_box needs an :id, a :field or a :name - the hook requires a stable id"
  end
end
