defmodule PetalComponents.DataTable.State do
  @moduledoc """
  The data table's entire backend contract in one struct.

  Flop-shaped on purpose, Flop-free on purpose: anything that can produce
  this struct can drive `<.data_table>`, and anything that can consume it
  can execute the query - the in-memory `Engine.List` for plain lists,
  or (Petal Pro) a Flop adapter for Ecto.

      %State{
        order_by: [{:email, :asc}],
        filters: [%{field: :email, op: :contains, value: "d"}],
        page: 1,
        page_size: 10,
        total: 74            # nil = cursor/unknown mode
      }

  `from_params/2` and `to_params/1` round-trip the struct through URL
  params, so URL-as-state (shareable sorts/filters, working back button)
  is a one-liner in `handle_params` rather than a hand-rolled encoding.

  ## Filter operators

  The vocabulary describes what the USER expressed, not how a database
  spells it. Each engine translates intent into its own query language,
  which is why `:contains` here means "text contains" even though some
  query libraries use that name for array membership.

    * text - `:contains`, `:not_contains`, `:eq`, `:neq`, `:starts_with`
    * ordered (numbers, dates) - `:gt`, `:gte`, `:lt`, `:lte`, `:between`
    * sets - `:in`, `:not_in`
    * null-ness - `:is_empty`, `:is_not_empty`
    * dates, read as intent - `:before`, `:on`, `:after`

  Semantics pinned deliberately, because "obvious" differs per engine:

    * `:between` is INCLUSIVE of both bounds.
    * `:is_empty` matches nil, `""` and `[]` - a blank-ish `" "` is not
      empty. Trim before filtering if you want it to be.
    * text comparisons fold CASE, and only case. `:eq`, `:neq`, `:in`,
      `:not_in`, `:contains`, `:not_contains`, `:starts_with`, the
      comparators against text columns, and the quick `search` all
      compare downcased on both sides. Accents are NOT folded: "cafe"
      does not match "café", while "CAFÉ" does. Folding is whatever
      `String.downcase/1` does; a SQL `lower()` is collation-dependent,
      so non-ASCII input can diverge between engines (Turkish dotless i
      is the classic case). ASCII agrees everywhere.
    * `:eq` is deliberately NOT SQL `=`. A person picking "is" in a
      filter means "this value", not "these bytes" - and the same
      dropdown offers `:contains` and `:starts_with`, which every
      engine folds, so a byte-exact `:eq` would make case behaviour
      silently flip as the user moves down the operator list. If a
      byte-exact equality is ever needed it will arrive as a NEW
      operator (`:eq_sensitive`), never as a change to this one.
    * comparators work on whatever the column holds - numbers, dates and
      text all compare with the same op.
    * `:before`/`:on`/`:after` are date-shaped aliases of `:lt`/`:eq`/
      `:gt`; they exist so a date filter reads as a date filter, and an
      adapter may map them to the same primitives. They are defined
      only for date-typed cells (`Date`, `DateTime`, `NaiveDateTime`) -
      a text column holding an ISO string does not match, because no
      SQL engine would cast every row to find out.
    * a `nil` value on a value-carrying op is unsatisfiable - it
      matches NO rows. `from_params/2` never emits one (a blank input
      drops the filter instead), so this only concerns hand-built
      states. Asking for empty cells is what `:is_empty` is for.
    * map-shaped cells are filter-only. Erlang orders maps by size,
      then keys, then values; jsonb has its own type-ordering rules,
      and no SQL expression reconciles the two - so a map column has
      NO defined sort order across engines. Don't mark one sortable.
    * an empty `order_by`, and ties within one, have NO defined row
      order across engines: this engine preserves input order, SQL
      without ORDER BY promises nothing. For stable paging, append a
      unique tiebreaker (the primary key) to every sort. That is the
      APPLICATION's job, at the point the state is built - an adapter
      must reproduce `order_by` exactly as given and never append one
      silently, or the same state would order differently per engine.

  Engines may support a subset. `ops/0` returns the recognised set and
  `valueless_op?/1` identifies the ops that carry no value.

  ## Writing an adapter

  Text equality in this contract folds case, so `lower(col) = lower($1)`
  is the SQL you want and plain `=` is wrong - for `:eq`, `:neq`, `:in`
  and `:not_in` alike, since they share one equality primitive. A
  half-folded implementation is worse than either extreme: "is not
  alice" leaving a visible "Alice" on screen is the loudest possible
  wrong answer.

  Plan for the index rather than discovering it: `lower(col)` will not
  use a plain btree index - add `CREATE INDEX ... ON t (lower(col))`,
  with the emitted expression matching the index expression exactly.
  Measured at one million rows (PostgreSQL 14), the functional index
  makes folded equality as fast as exact (`~0.02ms` either way);
  without it you get a sequential scan.

  One exception: on a `citext` column, plain `=` is ALREADY
  case-insensitive and index-backed - wrapping it in `lower()` defeats
  the index (measured ~28x slower). An adapter that knows a column is
  citext should emit plain `=` there.

  Reproduce `order_by` exactly - do not append a tiebreaker on the
  application's behalf (see the tie rule above), and do not reorder or
  drop entries. If the state's sort is unstable, that is the caller's
  bug to fix where the state is built.

  Text-shaped ops against float columns compare the TEXT FORM of the
  float, and Elixir and SQL format extremes differently:
  `to_string(1.0e20)` is `"1.0e20"` while Postgres renders `1e+20` -
  so `:contains`/`:in` against exponent-range floats can diverge
  between engines. Integral floats (`10.0`) agree. Money belongs in a
  decimal column, which has no such gap.

  ## Security

  `from_params/2` never creates atoms from user input: `:fields` is a
  required whitelist and anything outside it is dropped, ops outside the
  known set are dropped, and page/page_size are clamped (`:max_page_size`,
  default 100).
  """

  @enforce_keys []
  defstruct order_by: [], filters: [], search: nil, page: 1, page_size: 10, total: nil

  @type order :: {atom(), :asc | :desc}
  @type filter :: %{field: atom(), op: atom(), value: term()}
  @type t :: %__MODULE__{
          order_by: [order()],
          filters: [filter()],
          search: String.t() | nil,
          page: pos_integer(),
          page_size: pos_integer(),
          total: non_neg_integer() | nil
        }

  @ops ~w(contains not_contains eq neq starts_with gt gte lt lte between
          in not_in is_empty is_not_empty before on after)a

  # Ops that carry no value - the editors render no input for them and
  # put_filter/4 must not read them as "clear this filter".
  @valueless_ops ~w(is_empty is_not_empty)a
  @op_strings Map.new(@ops, &{Atom.to_string(&1), &1})
  @dir_strings %{"asc" => :asc, "desc" => :desc}

  @doc """
  Builds a `State` from URL/event params.

  Options:

    * `:fields` (required) - the whitelist of sortable/filterable fields,
      as atoms. Params referencing any other field are silently dropped.
    * `:page_size` - default page size when the params carry none (10).
    * `:max_page_size` - clamp ceiling for user-supplied sizes (100).

  Accepted param shapes (all optional, all strings - what `to_params/1`
  emits and what hand-written URLs naturally produce):

    * `"order_by"` - `"email"` or `"email:desc"` or `"email:desc,name"`
    * `"filters"` - a list (or Phoenix-style indexed map) of
      `%{"field" => f, "op" => op, "value" => v}`
    * `"page"`, `"page_size"` - integers as strings
  """
  def from_params(params, opts) when is_map(params) and is_list(opts) do
    fields = Keyword.fetch!(opts, :fields)
    field_strings = Map.new(fields, &{Atom.to_string(&1), &1})
    # misconfigured options must not violate the struct contract either -
    # a non-positive default or ceiling clamps to 1
    default_size = opts |> Keyword.get(:page_size, 10) |> max(1)
    max_size = opts |> Keyword.get(:max_page_size, 100) |> max(1)

    %__MODULE__{
      order_by: parse_order_by(params["order_by"], field_strings),
      filters: parse_filters(params["filters"], field_strings),
      search: parse_search(params["search"]),
      page: parse_pos_int(params["page"], 1),
      page_size: params["page_size"] |> parse_pos_int(default_size) |> min(max_size)
    }
  end

  @doc """
  Encodes the state as a flat params map suitable for `push_patch`
  query strings. Defaults (page 1, empty sorts/filters, the default
  page size) are omitted so URLs stay clean; `total` never round-trips -
  it is a result, not a request.

  Pass the same `:page_size` default given to `from_params/2` so the
  two stay symmetric (an omitted size decodes back to that default).
  """
  def to_params(%__MODULE__{} = state, opts \\ []) do
    default_size = Keyword.get(opts, :page_size, 10)

    %{}
    |> put_order_by(state.order_by)
    |> put_filters(state.filters)
    |> encode_search(state.search)
    |> put_unless("page", state.page, 1)
    |> put_unless("page_size", state.page_size, default_size)
  end

  @doc """
  Returns the state with `field` as the primary sort: cycles
  asc -> desc -> removed on repeated calls (the header-click grammar),
  and always resets to page 1 - a reordered page 7 is meaningless.
  """
  def toggle_sort(%__MODULE__{} = state, field) when is_atom(field) do
    order_by =
      case List.keyfind(state.order_by, field, 0) do
        nil -> [{field, :asc}]
        {^field, :asc} -> [{field, :desc}]
        {^field, :desc} -> []
      end

    %{state | order_by: order_by, page: 1}
  end

  @doc "The operators this contract recognises."
  def ops, do: @ops

  @doc "True for operators that carry no value, like `:is_empty`."
  def valueless_op?(op), do: op in @valueless_ops

  @doc "Replaces the filter for `field` (or removes it when `value` is nil/empty), resetting to page 1."
  def put_filter(%__MODULE__{} = state, field, op, value)
      when op in @valueless_ops do
    filter = %{field: field, op: op, value: value}
    rest = Enum.reject(state.filters, &(&1.field == field))
    %{state | filters: rest ++ [filter], page: 1}
  end

  def put_filter(%__MODULE__{} = state, field, _op, value)
      when value in [nil, "", []] do
    %{state | filters: Enum.reject(state.filters, &(&1.field == field)), page: 1}
  end

  def put_filter(%__MODULE__{} = state, field, op, value)
      when is_atom(field) and op in @ops do
    filter = %{field: field, op: op, value: value}
    rest = Enum.reject(state.filters, &(&1.field == field))
    %{state | filters: rest ++ [filter], page: 1}
  end

  @doc "Sets (or clears, for blank terms) the quick-search term, resetting to page 1."
  def put_search(%__MODULE__{} = state, term) do
    %{state | search: parse_search(term), page: 1}
  end

  @doc "Sets the page size (invalid values keep the current one), resetting to page 1."
  def put_page_size(%__MODULE__{} = state, size) do
    %{state | page_size: parse_pos_int(size, state.page_size), page: 1}
  end

  @doc """
  Applies one event-mode op payload - the entire `data_table` event
  grammar in one call, so an event-mode handler is a one-liner:

      def handle_event("table", params, socket) do
        state = State.handle_op(socket.assigns.table, params, fields: [:name, :email])
        {rows, state} = Engine.List.run(all_rows(), state)
        {:noreply, assign(socket, rows: rows, table: state)}
      end

  Ops: `sort` (field), `page` (page), `search` (term), `page_size`
  (page_size), `filter` (field, filter_op, value/value2/values), and
  `clear_filters`. Unknown ops and non-whitelisted fields leave the
  state unchanged; like `from_params/2`, no atoms are ever created
  from input.

  A `filter` op's value normalizes by editor shape: a `values` list
  posts as-is (the select editor's `:in`), `between` pairs
  `value`/`value2` into `[min, max]`, anything blank removes the
  field's filter.
  """
  def handle_op(%__MODULE__{} = state, params, opts) when is_map(params) and is_list(opts) do
    fields = Keyword.fetch!(opts, :fields)
    field_strings = Map.new(fields, &{Atom.to_string(&1), &1})

    case params do
      %{"op" => "sort", "field" => field} ->
        case Map.fetch(field_strings, to_string(field)) do
          {:ok, field} -> toggle_sort(state, field)
          :error -> state
        end

      %{"op" => "page", "page" => page} ->
        %{state | page: parse_pos_int(to_string(page), state.page)}

      %{"op" => "search", "term" => term} ->
        put_search(state, term)

      %{"op" => "page_size", "page_size" => size} ->
        put_page_size(state, size)

      %{"op" => "filter", "field" => field} ->
        case Map.fetch(field_strings, to_string(field)) do
          {:ok, field} -> apply_filter_op(state, field, params)
          :error -> state
        end

      %{"op" => "clear_filters"} ->
        clear_filters(state)

      _other ->
        state
    end
  end

  defp apply_filter_op(state, field, %{"filter_op" => op} = params)
       when is_binary(op) do
    case Map.fetch(@op_strings, op) do
      {:ok, valueless} when valueless in @valueless_ops ->
        put_filter(state, field, valueless, true)

      _ ->
        do_apply_filter_op(state, field, params)
    end
  end

  defp apply_filter_op(state, field, params), do: do_apply_filter_op(state, field, params)

  defp do_apply_filter_op(state, field, params) do
    resolved =
      cond do
        # the select editor's shape - its grammar is always :in, whether
        # or not the form said so
        is_list(params["values"]) ->
          {:in, Enum.reject(params["values"], &(&1 in [nil, ""]))}

        # no operator at all is the clear button's payload: removal
        is_nil(params["filter_op"]) ->
          {:eq, ""}

        true ->
          case Map.fetch(@op_strings, params["filter_op"]) do
            {:ok, :between} -> {:between, normalize_between(params["value"], params["value2"])}
            {:ok, op} -> {op, params["value"]}
            # a present-but-unknown operator gets from_params-grade
            # rejection: the state stays exactly as it was
            :error -> :reject
          end
      end

    case resolved do
      :reject -> state
      {op, value} -> put_filter(state, field, op, value)
    end
  end

  # a half-empty range can't match anything, so it reads as removal
  defp normalize_between(min, max) when min in [nil, ""] or max in [nil, ""], do: ""
  defp normalize_between(min, max), do: [min, max]

  @doc "Removes every filter, resetting to page 1."
  def clear_filters(%__MODULE__{} = state), do: %{state | filters: [], page: 1}

  @doc "Total pages when `total` is known, else nil (cursor/unknown mode)."
  def total_pages(%__MODULE__{total: nil}), do: nil

  def total_pages(%__MODULE__{total: total, page_size: size}),
    do: max(ceil(total / max(size, 1)), 1)

  # -- parsing ---------------------------------------------------------------

  defp parse_order_by(nil, _fields), do: []

  defp parse_order_by(value, fields) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.flat_map(fn part ->
      {field_part, dir} =
        case String.split(part, ":", parts: 2) do
          [f, d] -> {f, Map.get(@dir_strings, d, :asc)}
          [f] -> {f, :asc}
        end

      case Map.fetch(fields, field_part) do
        {:ok, field} -> [{field, dir}]
        :error -> []
      end
    end)
  end

  defp parse_order_by(_other, _fields), do: []

  defp parse_filters(nil, _fields), do: []

  # Phoenix decodes indexed params ("filters[0][field]=...") into a map of
  # index-string keys; a JSON payload arrives as a real list. Accept both.
  defp parse_filters(%{} = indexed, fields) do
    indexed
    |> Enum.sort_by(fn {k, _v} -> parse_pos_int(k, 0) end)
    |> Enum.map(fn {_k, v} -> v end)
    |> parse_filters(fields)
  end

  defp parse_filters(list, fields) when is_list(list) do
    Enum.flat_map(list, fn
      %{"field" => f, "op" => op, "value" => value} ->
        with {:ok, field} <- Map.fetch(fields, f),
             {:ok, op} <- Map.fetch(@op_strings, op),
             # a JSON null value is nonsense for a value-carrying op -
             # it would read as "" and quietly match empty-string rows
             false <- is_nil(value) and op not in @valueless_ops do
          [%{field: field, op: op, value: value}]
        else
          _skip -> []
        end

      _other ->
        []
    end)
  end

  defp parse_filters(_other, _fields), do: []

  defp parse_search(term) when is_binary(term) do
    case String.trim(term) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp parse_search(_other), do: nil

  defp encode_search(params, nil), do: params
  defp encode_search(params, term), do: Map.put(params, "search", term)

  defp parse_pos_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {n, ""} when n > 0 -> n
      _ -> default
    end
  end

  defp parse_pos_int(value, _default) when is_integer(value) and value > 0, do: value
  defp parse_pos_int(_other, default), do: default

  # -- encoding --------------------------------------------------------------

  defp put_order_by(params, []), do: params

  defp put_order_by(params, order_by) do
    encoded =
      Enum.map_join(order_by, ",", fn
        {field, :asc} -> Atom.to_string(field)
        {field, :desc} -> "#{field}:desc"
      end)

    Map.put(params, "order_by", encoded)
  end

  defp put_filters(params, []), do: params

  defp put_filters(params, filters) do
    encoded =
      Enum.map(filters, fn %{field: field, op: op, value: value} ->
        %{"field" => Atom.to_string(field), "op" => Atom.to_string(op), "value" => value}
      end)

    Map.put(params, "filters", encoded)
  end

  defp put_unless(params, _key, value, value), do: params
  defp put_unless(params, _key, nil, _default), do: params
  defp put_unless(params, key, value, _default), do: Map.put(params, key, value)
end
