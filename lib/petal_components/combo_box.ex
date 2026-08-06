defmodule PetalComponents.ComboBox do
  @moduledoc """
  A searchable select: type to filter, arrow keys to move, Enter to choose.

  The visible input is display-only chrome; the real form control is a
  hidden native `<select>` kept in sync by the `PetalComboBox` hook. That
  makes the component form-native: changesets, `phx-change` and LiveView
  form recovery all work exactly as they do for a plain select - there is
  no `phx-update="ignore"` island and no client-owned state to lose.
  (Recovery follows the standard LiveView rules: the enclosing form needs
  an id and a phx-change.)

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
  the highlight. Arrow keys wrap through an empty stop: Down past the
  last option clears the highlight, Down again starts from the top.

      <.form :let={f} for={@form} phx-change="validate">
        <.combo_box field={f[:country]} options={["Australia", "Japan", "Portugal"]} />
      </.form>

  ## Multiple

  `multiple` turns the trigger into a chip row: each chosen option renders
  as a removable token, the panel stays open while picking, Backspace in
  an empty input removes the last chip, and the hidden select becomes a
  real `<select multiple>` (the name gains `[]` so every choice survives
  the form post). `max_items` caps how many can be chosen - at the cap,
  unchosen options render inert until something is removed.

      <.combo_box
        field={f[:tags]}
        multiple
        max_items={5}
        options={["elixir", "phoenix", "liveview"]}
      />

  ## Options

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

  attr :value, :any,
    default: nil,
    doc: "current value - or list of values when multiple (overrides field)"

  attr :options, :list,
    default: [],
    doc:
      "strings, {label, value} tuples, {label, value, opts} (opts: disabled: true), or {group_label, options} groups"

  attr :variant, :string,
    default: "input",
    values: ["input", "trigger"],
    doc:
      "input is the searchable field; trigger is a select-like button whose panel carries the search input - the picker anatomy, and the data table's filter editor"

  attr :search_placeholder, :string,
    default: "Search…",
    doc: "trigger variant: placeholder for the search input inside the panel"

  attr :count_label, :string,
    default: "selected",
    doc: "trigger variant with multiple: the word after the count in the closed label"

  attr :multiple, :boolean,
    default: false,
    doc: "chip-row selection: the hidden select becomes select multiple and the name gains []"

  attr :max_items, :integer,
    default: nil,
    doc: "multiple only: cap on chosen options; at the cap, unchosen options render inert"

  attr :clearable, :boolean,
    default: false,
    doc: "single select only: show a clear button in the control when a value is chosen"

  attr :placeholder, :string, default: "Select an option…"
  attr :disabled, :boolean, default: false

  attr :required, :boolean,
    default: false,
    doc: "renders on the hidden select, so native required validation guards the real control"

  attr :form_id, :string,
    default: nil,
    doc: "the form this control belongs to when rendered outside it (the select's form attribute)"

  attr :no_results_text, :string, default: "No results found"
  attr :results_label, :string, default: "results", doc: "the live-region word after the count"
  attr :clear_label, :string, default: "Clear selection", doc: "aria-label for the clear button"

  attr :remove_label, :string,
    default: "Remove",
    doc: "aria-label prefix for chip remove buttons; the option label is appended"

  attr :listbox_label, :string, default: "Options", doc: "accessible name for the listbox"
  attr :class, :any, default: nil, doc: "extra classes for the wrapper"
  attr :rest, :global

  def combo_box(assigns) do
    groups = normalize_options(assigns.options)
    values = current_values(assigns)
    id = resolve_id(assigns)

    assigns =
      assigns
      |> assign(:groups, groups)
      |> assign(:current_values, values)
      |> assign(:id, id)
      |> assign(:input_name, input_name(assigns))
      |> assign(
        :selected_label,
        if(assigns.multiple, do: nil, else: selected_label(groups, values))
      )
      |> assign(:selected_options, selected_options(groups, values))
      |> assign(:trigger_label, trigger_label(assigns, groups, values))

    ~H"""
    <div
      id={@id}
      class={["pc-combo-box", @class]}
      phx-hook="PetalComboBox"
      data-max-items={@max_items}
      data-has-value={@current_values != [] && "true"}
      {@rest}
    >
      <select
        id={"#{@id}-select"}
        name={@input_name}
        class="pc-combo-box__select"
        tabindex="-1"
        aria-hidden="true"
        inert
        multiple={@multiple}
        disabled={@disabled}
        required={@required}
        form={@form_id}
      >
        <option :if={!@multiple} value=""></option>
        <%= for group <- @groups do %>
          <%= if group.label do %>
            <optgroup label={group.label}>
              <option
                :for={opt <- group.options}
                value={opt.value}
                selected={selected?(opt, @current_values)}
                disabled={opt.disabled}
              >
                {opt.label}
              </option>
            </optgroup>
          <% else %>
            <option
              :for={opt <- group.options}
              value={opt.value}
              selected={selected?(opt, @current_values)}
              disabled={opt.disabled}
            >
              {opt.label}
            </option>
          <% end %>
        <% end %>
      </select>

      <button
        :if={@variant == "trigger"}
        type="button"
        id={"#{@id}-trigger"}
        class="pc-combo-box__trigger"
        role="combobox"
        aria-haspopup="listbox"
        aria-expanded="false"
        aria-controls={"#{@id}-listbox"}
        data-pc-combo-trigger
        data-placeholder={@current_values == [] && "true"}
        disabled={@disabled}
      >
        <span
          class="pc-combo-box__trigger-label"
          data-pc-combo-trigger-label
          data-placeholder-text={@placeholder}
          data-count-label={@count_label}
        >{@trigger_label}</span>
        <.icon name="hero-chevron-down-mini" class="pc-combo-box__chevron" />
      </button>

      <div :if={@variant == "input"} class="pc-combo-box__control">
        <div class="pc-combo-box__content">
          <div
            :if={@multiple}
            class="pc-combo-box__chips"
            data-pc-combo-chips
            data-remove-label={@remove_label}
          >
            <span :for={opt <- @selected_options} class="pc-combo-box__chip" data-pc-combo-chip>
              <span class="pc-combo-box__chip-label">{opt.label}</span>
              <button
                type="button"
                class="pc-combo-box__chip-remove"
                data-pc-combo-chip-remove
                data-value={opt.value}
                aria-label={"#{@remove_label} #{opt.label}"}
                tabindex="-1"
              >
                <.icon name="hero-x-mark-mini" class="pc-combo-box__chip-remove-icon" />
              </button>
            </span>
          </div>
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
            placeholder={if @multiple && @current_values != [], do: nil, else: @placeholder}
            value={@selected_label}
            disabled={@disabled}
          />
        </div>
        <button
          :if={@clearable && !@multiple}
          type="button"
          class="pc-combo-box__clear"
          data-pc-combo-clear
          aria-label={@clear_label}
        >
          <.icon name="hero-x-mark-mini" class="pc-combo-box__clear-icon" />
        </button>
        <%!-- chips mode is a token field, not a dropdown: the chips and input
        are the affordance, so the single-select chevron would mislead
        (shadcn chips, Tom Select multi and the token-field family all drop
        it) --%>
        <.icon :if={!@multiple} name="hero-chevron-down-mini" class="pc-combo-box__chevron" />
      </div>

      <div class="pc-combo-box__panel" data-pc-combo-panel hidden>
        <div :if={@variant == "trigger"} class="pc-combo-box__search">
          <.icon name="hero-magnifying-glass-mini" class="pc-combo-box__search-icon" />
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
            placeholder={@search_placeholder}
          />
        </div>
        <div
          role="listbox"
          id={"#{@id}-listbox"}
          class="pc-combo-box__list"
          aria-label={@listbox_label}
          aria-multiselectable={@multiple && "true"}
        >
          <%= for group <- @groups do %>
            <%= if group.label do %>
              <div class="pc-combo-box__group" role="group" data-pc-combo-group>
                <div class="pc-combo-box__group-heading" aria-hidden="true">{group.label}</div>
                <.option_items options={group.options} current_values={@current_values} />
              </div>
            <% else %>
              <.option_items options={group.options} current_values={@current_values} />
            <% end %>
          <% end %>
          <div class="pc-combo-box__empty" data-pc-combo-empty hidden>{@no_results_text}</div>
        </div>
      </div>

      <div
        class="pc-combo-box__live"
        data-pc-combo-live
        data-results-label={@results_label}
        data-no-results-text={@no_results_text}
        aria-live="polite"
      >
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
      aria-selected={to_string(selected?(opt, @current_values))}
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

  # -- value / name / id resolution -----------------------------------------

  defp current_values(%{value: value}) when not is_nil(value) and value != [],
    do: value |> List.wrap() |> Enum.map(&to_string/1)

  defp current_values(%{field: %{value: value}}) when not is_nil(value) and value != [],
    do: value |> List.wrap() |> Enum.map(&to_string/1)

  defp current_values(_assigns), do: []

  defp selected?(_opt, []), do: false
  defp selected?(opt, values), do: opt.value in values

  defp selected_label(_groups, []), do: nil

  defp selected_label(groups, [value | _]) do
    groups
    |> Enum.flat_map(& &1.options)
    |> Enum.find_value(fn opt -> if opt.value == value, do: opt.label end)
  end

  defp selected_options(_groups, []), do: []

  defp selected_options(groups, values) do
    all = Enum.flat_map(groups, & &1.options)
    # chip order follows the chosen order, not the option order
    Enum.flat_map(values, fn value -> Enum.filter(all, &(&1.value == value)) end)
  end

  defp trigger_label(%{variant: "trigger"} = assigns, groups, values) do
    case values do
      [] -> assigns.placeholder
      _ when assigns.multiple -> "#{length(values)} #{assigns.count_label}"
      [value | _] -> selected_label(groups, [value]) || assigns.placeholder
    end
  end

  defp trigger_label(_assigns, _groups, _values), do: nil

  defp input_name(%{multiple: true} = assigns) do
    case assigns.name || (assigns.field && assigns.field.name) do
      nil -> nil
      name -> if String.ends_with?(name, "[]"), do: name, else: name <> "[]"
    end
  end

  defp input_name(assigns), do: assigns.name || (assigns.field && assigns.field.name)

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
