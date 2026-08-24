defmodule PetalComponents.DataTable.FilterEditor do
  @moduledoc false
  # The typed value editors shared by `PetalComponents.DataTable` (per-column
  # filter popovers) and `PetalComponents.Filters` (the standalone filter bar),
  # plus the State -> URL encoding both use to build link-mode patch URLs.
  #
  # One home for three things that must never diverge between the two
  # components: the operator display names, the value formatting shown on a
  # trigger or a chip, and the exact form markup the `PetalDataTable` hook
  # reads back in link mode (`values[]`, `filter_op`, `value`, `value2`). The
  # `pc-data-table__filter-*` class names are deliberately kept - the hook
  # queries them and `assets/default.css` already carries the JS-free `:has`
  # rules that hide the value input for valueless ops and reveal the second
  # bound for `:between`.
  #
  # Editors are named by SHAPE, not by a caller's type vocabulary, because the
  # two components spell their types differently (the data table's "select" is
  # a checkbox list, the filter bar's "select" is a single choice):
  #
  #   * "text"    - operator select + text input
  #   * "number"  - operator select + number input (+ a second bound for :between)
  #   * "date"    - operator select + date input (+ a second bound for :between)
  #   * "options" - checkbox list posting `values[]`, always the :in operator
  #   * "choice"  - operator select + single <select name="value"> from options
  #   * "boolean" - a yes/no select, operator pinned to :eq (no picker)

  use Phoenix.Component

  alias PetalComponents.DataTable.State

  # eight or more options get a client-side filter box - a checkbox wall
  # with no way to narrow it is where long lists go to die
  @option_filter_threshold 8

  @doc false
  def default_op_labels do
    %{
      contains: "contains",
      eq: "is",
      starts_with: "starts with",
      not_contains: "does not contain",
      neq: "is not",
      gt: ">",
      gte: "≥",
      lt: "<",
      lte: "≤",
      not_in: "is none of",
      is_empty: "is empty",
      is_not_empty: "is not empty",
      between: "between",
      in: "is any of",
      before: "before",
      on: "on",
      after: "after"
    }
  end

  attr :type, :string,
    required: true,
    values: ["text", "number", "date", "options", "choice", "boolean"],
    doc: "the editor shape to render"

  attr :ops, :list,
    default: [],
    doc: "the operator subset offered, all members of `State.ops/0`"

  attr :default_op, :atom, default: :eq, doc: "the operator preselected when no filter is active"
  attr :filter, :any, default: nil, doc: "the active filter map for this field, or nil"
  attr :options, :list, default: [], doc: "normalized `{label, value}` pairs"
  attr :op_labels, :map, required: true, doc: "operator atom -> display name"
  attr :label, :string, required: true, doc: "the field's human label, used for aria names"

  attr :filter_options_placeholder, :string,
    default: "Filter options…",
    doc: "the option-filter box's placeholder"

  @doc false
  def filter_editor(%{type: "options"} = assigns) do
    current = assigns.filter |> current_values() |> Enum.map(&to_string/1)

    assigns =
      assigns
      |> assign(:current, current)
      |> assign(:show_option_filter, length(assigns.options) >= @option_filter_threshold)

    ~H"""
    <input
      :if={@show_option_filter}
      type="text"
      data-pc-dt-option-filter
      autocomplete="off"
      placeholder={@filter_options_placeholder}
      aria-label={"#{@label} option filter"}
      class="pc-text-input pc-data-table__filter-value pc-data-table__option-filter"
    />
    <div class="pc-data-table__filter-options" role="group" aria-label={"#{@label} options"}>
      <label :for={{label, value} <- @options} class="pc-data-table__filter-option">
        <input
          type="checkbox"
          name="values[]"
          value={value}
          checked={to_string(value) in @current}
          class="pc-checkbox"
        />
        <span>{label}</span>
      </label>
    </div>
    """
  end

  def filter_editor(%{type: "number"} = assigns) do
    {value, value2} = current_pair(assigns.filter)

    assigns =
      assigns
      |> assign(:current_op, (assigns.filter && assigns.filter.op) || assigns.default_op)
      |> assign(:value, value)
      |> assign(:value2, value2)

    ~H"""
    <.filter_op_select ops={@ops} current_op={@current_op} op_labels={@op_labels} label={@label} />
    <input
      type="number"
      step="any"
      name="value"
      value={@value}
      aria-label={"#{@label} lower bound"}
      class="pc-text-input pc-data-table__filter-value"
    />
    <input
      :if={:between in @ops}
      type="number"
      step="any"
      name="value2"
      value={@value2}
      class="pc-text-input pc-data-table__filter-value pc-data-table__filter-value2"
      aria-label={"#{@label} upper bound"}
    />
    """
  end

  def filter_editor(%{type: "date"} = assigns) do
    {value, value2} = current_pair(assigns.filter)

    assigns =
      assigns
      |> assign(:current_op, (assigns.filter && assigns.filter.op) || assigns.default_op)
      |> assign(:value, value && to_string(value))
      |> assign(:value2, value2 && to_string(value2))

    ~H"""
    <.filter_op_select ops={@ops} current_op={@current_op} op_labels={@op_labels} label={@label} />
    <input
      type="date"
      name="value"
      value={@value}
      aria-label={"#{@label} value"}
      class="pc-text-input pc-data-table__filter-value"
    />
    <input
      :if={:between in @ops}
      type="date"
      name="value2"
      value={@value2}
      class="pc-text-input pc-data-table__filter-value pc-data-table__filter-value2"
      aria-label={"#{@label} upper bound"}
    />
    """
  end

  # A single choice from the registered options. Unlike "options" this posts
  # one `value`, so `:eq` / `:neq` mean what the operator select says.
  def filter_editor(%{type: "choice"} = assigns) do
    assigns =
      assigns
      |> assign(:current_op, (assigns.filter && assigns.filter.op) || assigns.default_op)
      |> assign(:value, (assigns.filter && to_string(assigns.filter.value)) || "")

    ~H"""
    <.filter_op_select ops={@ops} current_op={@current_op} op_labels={@op_labels} label={@label} />
    <select
      name="value"
      class="pc-select pc-data-table__filter-value"
      aria-label={"#{@label} value"}
    >
      <option value=""></option>
      <option :for={{label, value} <- @options} value={value} selected={to_string(value) == @value}>
        {label}
      </option>
    </select>
    """
  end

  # There is exactly one operator worth offering for a boolean, so the picker
  # is a hidden input rather than a one-item select nobody can act on.
  def filter_editor(%{type: "boolean"} = assigns) do
    assigns =
      assign(assigns, :value, (assigns.filter && to_string(assigns.filter.value)) || "true")

    ~H"""
    <input type="hidden" name="filter_op" value="eq" />
    <select
      name="value"
      class="pc-select pc-data-table__filter-value"
      aria-label={"#{@label} value"}
    >
      <option value="true" selected={@value == "true"}>Yes</option>
      <option value="false" selected={@value == "false"}>No</option>
    </select>
    """
  end

  def filter_editor(assigns) do
    assigns =
      assigns
      |> assign(:current_op, (assigns.filter && assigns.filter.op) || assigns.default_op)
      |> assign(:value, (assigns.filter && to_string(assigns.filter.value)) || nil)

    ~H"""
    <.filter_op_select ops={@ops} current_op={@current_op} op_labels={@op_labels} label={@label} />
    <input
      type="text"
      name="value"
      value={@value}
      aria-label={"#{@label} value"}
      class="pc-text-input pc-data-table__filter-value"
    />
    """
  end

  attr :ops, :list, required: true
  attr :current_op, :atom, required: true
  attr :op_labels, :map, required: true
  attr :label, :string, required: true

  defp filter_op_select(assigns) do
    ~H"""
    <select
      name="filter_op"
      class="pc-select pc-data-table__filter-op"
      aria-label={"#{@label} operator"}
    >
      <option :for={op <- @ops} value={op} selected={op == @current_op}>
        {op_label(@op_labels, op)}
      </option>
    </select>
    """
  end

  # An op with no label is a custom one an adapter added - render the atom
  # rather than raising mid-render, which is what Map.fetch!/2 did.
  @doc false
  def op_label(labels, op), do: Map.get(labels, op, humanize_op(op))

  defp humanize_op(op), do: op |> to_string() |> String.replace("_", " ")

  @doc false
  def normalize_options(options) do
    Enum.map(options, fn
      {label, value} -> {label, value}
      value -> {humanize(value), value}
    end)
  end

  @doc false
  def current_values(nil), do: []
  def current_values(%{value: value}), do: List.wrap(value)

  # the engine accepts both range shapes, so both must render
  @doc false
  def current_pair(%{op: :between, value: [min, max]}), do: {min, max}
  def current_pair(%{op: :between, value: %{"min" => min, "max" => max}}), do: {min, max}
  def current_pair(%{op: :between}), do: {nil, nil}
  def current_pair(%{value: value}) when not is_list(value), do: {value, nil}
  def current_pair(_other), do: {nil, nil}

  @doc false
  def predicate_text(label, filter, op_labels, options) do
    case State.valueless_op?(filter.op) do
      true -> "#{label} #{op_label(op_labels, filter.op)}"
      false -> "#{label} #{op_label(op_labels, filter.op)} #{display_value(filter, options)}"
    end
  end

  @doc false
  def display_value(%{op: :in, value: values}, options) do
    labels = Map.new(options, fn {label, value} -> {to_string(value), label} end)
    shown = values |> List.wrap() |> Enum.map(&Map.get(labels, to_string(&1), to_string(&1)))

    case Enum.split(shown, 2) do
      {first_two, []} -> Enum.join(first_two, ", ")
      {first_two, rest} -> Enum.join(first_two, ", ") <> " +#{length(rest)}"
    end
  end

  def display_value(%{op: :between, value: [min, max]}, _options), do: "#{min}–#{max}"

  def display_value(%{op: :between, value: %{"min" => min, "max" => max}}, _options),
    do: "#{min}–#{max}"

  # hand-built states can carry shapes no editor produces - never crash
  # the toolbar over one
  def display_value(%{value: value}, _options) when is_list(value),
    do: Enum.map_join(value, ", ", &to_string/1)

  def display_value(%{value: %{} = value}, _options), do: inspect(value)

  def display_value(%{value: value}, options) do
    labels = Map.new(options, fn {label, v} -> {to_string(v), label} end)
    Map.get(labels, to_string(value), to_string(value))
  end

  @doc false
  def humanize(field) do
    field |> to_string() |> String.replace("_", " ") |> String.capitalize()
  end

  # -- link-mode URL encoding -------------------------------------------------
  # Both components patch the SAME query shape, so the encoding lives once.

  @doc false
  def url_for(path, %State{} = state) do
    query = state |> State.to_params() |> flatten_params() |> URI.encode_query()
    join_query(path, query)
  end

  # a base path may already carry a query string - join accordingly
  @doc false
  def join_query(path, ""), do: path

  def join_query(path, query) do
    joiner = if String.contains?(path, "?"), do: "&", else: "?"
    path <> joiner <> query
  end

  # filters encode as a list of maps - flatten to Phoenix-style indexed
  # params so encode_query can carry them and from_params reads them
  # back. Returns pairs, not a map: a list value (the :in op) needs the
  # same key repeated ("...[value][]"), which a map cannot hold.
  @doc false
  def flatten_params(params) do
    {filters, rest} = Map.pop(params, "filters")

    Enum.sort(rest) ++
      (filters
       |> List.wrap()
       |> Enum.with_index()
       |> Enum.flat_map(fn {filter, i} ->
         Enum.flat_map(filter, fn {k, v} -> filter_pairs("filters[#{i}][#{k}]", v) end)
       end))
  end

  defp filter_pairs(key, values) when is_list(values),
    do: Enum.map(values, &{"#{key}[]", &1})

  defp filter_pairs(key, %{} = map),
    do: Enum.map(map, fn {k, v} -> {"#{key}[#{k}]", v} end)

  defp filter_pairs(key, value), do: [{key, value}]
end
