defmodule PetalComponents.DataTable.Engine.List do
  @moduledoc """
  The in-memory engine: sort, filter and paginate a plain list of maps or
  structs against a `PetalComponents.DataTable.State`.

  This is the zero-setup path - the registry examples, the playground and
  any app with an already-loaded list get a working table with no database
  and no extra dependency. It is deliberately a toy for data that fits in
  memory; real query backends (Ecto/Flop adapters, cursor pagination) are
  the production wiring layer, not this module.

      {rows, state} = Engine.List.run(all_rows, state)

  returns the visible page plus the state with `total` filled in (the
  post-filter count), which is what the footer and pagination render from.

  Filter semantics by operator - all string comparisons are
  case-insensitive, `nil` field values never match:

    * `:contains`, `:starts_with`, `:eq` on strings
    * `:eq`, `:neq`, `:gt`, `:lt` numeric (value coerced from string)
    * `:between` with a `[min, max]` (or `%{"min" => _, "max" => _}`) value
    * `:in` with a list value (select/enum filters)
    * `:before`, `:on`, `:after` on `Date`/`DateTime`/ISO8601 strings
  """

  alias PetalComponents.DataTable.State

  # The only shapes text matching can safely coerce - anything else
  # (a map, a list, a tuple living in a row cell) is a no-match, never
  # a to_string crash. Guards both sides: row field values AND filter
  # values, which arrive raw from params.
  defguardp is_scalar(v) when is_binary(v) or is_number(v) or is_atom(v)

  @doc """
  Runs the full pipeline: search -> filter -> sort -> count -> paginate.

  Options:

    * `:search_fields` - the fields the quick-search term matches
      against (case-insensitive contains). Defaults to every field of
      the first row whose value is a string.
  """
  def run(rows, state, opts \\ [])

  def run(rows, %State{} = state, opts) when is_list(rows) do
    # from_params clamps, but hand-built structs can carry page 0 or a
    # non-positive size - a negative slice offset would silently take
    # rows from the END of the list, so clamp here too
    page = max(state.page, 1)
    page_size = max(state.page_size, 1)

    filtered =
      rows
      |> apply_search(state.search, Keyword.get(opts, :search_fields))
      |> then(&Enum.reduce(state.filters, &1, fn f, acc -> apply_filter(acc, f) end))

    total = length(filtered)

    page_rows =
      filtered
      |> sort(state.order_by)
      |> Enum.slice((page - 1) * page_size, page_size)

    {page_rows, %{state | page: page, page_size: page_size, total: total}}
  end

  # -- search ----------------------------------------------------------------

  defp apply_search(rows, nil, _fields), do: rows
  defp apply_search([], _term, _fields), do: []

  defp apply_search([first | _] = rows, term, fields) do
    fields = fields || default_search_fields(first)

    needle = String.downcase(term)

    Enum.filter(rows, fn row ->
      Enum.any?(fields, fn field ->
        case fetch(row, field) do
          v when is_binary(v) -> String.contains?(String.downcase(v), needle)
          _ -> false
        end
      end)
    end)
  end

  # Ecto structs are not Enumerable - `for {k, v} <- row` raises on
  # exactly the rows a database produces. Strip the struct plumbing and
  # sweep the string fields, same as for a plain map.
  defp default_search_fields(%_{} = row) do
    row
    |> Map.from_struct()
    |> Map.drop([:__meta__])
    |> Enum.flat_map(fn {k, v} -> if is_binary(v), do: [k], else: [] end)
  end

  defp default_search_fields(row) when is_map(row) do
    for {k, v} <- row, is_binary(v), do: k
  end

  # -- sorting ---------------------------------------------------------------

  defp sort(rows, []), do: rows

  defp sort(rows, order_by) do
    Enum.sort(rows, fn a, b -> compare_by(a, b, order_by) end)
  end

  defp compare_by(_a, _b, []), do: true

  defp compare_by(a, b, [{field, dir} | rest]) do
    av = fetch(a, field)
    bv = fetch(b, field)

    # nils sort last REGARDLESS of direction - a blank cell at the top of
    # a sorted column reads as a bug to users, not as collation - so the
    # nil rule sits outside the asc/desc flip.
    case {av, bv} do
      {nil, nil} ->
        compare_by(a, b, rest)

      {nil, _} ->
        false

      {_, nil} ->
        true

      _ ->
        case {dir, cmp(av, bv)} do
          {_, :eq} -> compare_by(a, b, rest)
          {:asc, :lt} -> true
          {:asc, :gt} -> false
          {:desc, :lt} -> false
          {:desc, :gt} -> true
        end
    end
  end

  # Decimal first: it is a struct too, but Erlang term order over its
  # fields (coef/exp/sign) sorted -10.00 as the LARGEST value
  defp cmp(%Decimal{} = a, %Decimal{} = b), do: Decimal.compare(a, b)
  defp cmp(%Decimal{} = a, b) when is_number(b), do: Decimal.compare(a, to_decimal(b))
  defp cmp(a, %Decimal{} = b) when is_number(a), do: Decimal.compare(to_decimal(a), b)

  defp cmp(%m{} = a, %m{} = b) when m in [Date, DateTime, NaiveDateTime, Time],
    do: m.compare(a, b)

  defp cmp(a, b) when is_binary(a) and is_binary(b) do
    da = String.downcase(a)
    db = String.downcase(b)

    cond do
      da == db -> :eq
      da < db -> :lt
      true -> :gt
    end
  end

  defp cmp(a, b) do
    cond do
      a == b -> :eq
      a < b -> :lt
      true -> :gt
    end
  end

  # -- filtering -------------------------------------------------------------

  defp apply_filter(rows, %{field: field, op: op, value: value}) do
    Enum.filter(rows, fn row -> matches?(fetch(row, field), op, value) end)
  end

  # These two run before the nil short-circuit below, because they are the
  # only ops where a nil field is a MATCH rather than a miss. Semantics
  # are pinned deliberately and documented in State: empty means nil, an
  # empty string, or an empty list - the shapes a form or an association
  # actually produces. A blank-ish " " is NOT empty; trim before filtering
  # if you want it to be.
  defp matches?(field_value, :is_empty, _value), do: empty_value?(field_value)
  defp matches?(field_value, :is_not_empty, _value), do: not empty_value?(field_value)

  defp matches?(nil, _op, _value), do: false

  # Struct scalars read as their text form for the text-shaped ops: a
  # select filter on a date column posts "2026-01-15" and must match
  # ~D[2026-01-15]; :in is a text-form comparison on every column type
  # ("010" does not match 10). Comparators and date ops keep their own
  # typed clauses below.
  defp matches?(%mod{} = field_value, op, value)
       when mod in [Decimal, Date, DateTime, NaiveDateTime, Time] and
              op in [:contains, :not_contains, :starts_with, :in, :not_in],
       do: matches?(to_string(field_value), op, value)

  defp matches?(field_value, :contains, value) when is_scalar(field_value),
    do: with_text(value, &String.contains?(downcase(field_value), &1))

  defp matches?(field_value, :starts_with, value) when is_scalar(field_value),
    do: with_text(value, &String.starts_with?(downcase(field_value), &1))

  defp matches?(field_value, :eq, value) when is_binary(field_value),
    do: with_text(value, &(downcase(field_value) == &1))

  defp matches?(field_value, :eq, value) when is_number(field_value),
    do: with_number(value, &(field_value == &1))

  # Money columns are %Decimal{} structs in every Ecto app - neither
  # is_number/1 nor is_scalar/1, so before this clause every operator
  # silently matched zero rows against them (found by the differential
  # gate, not by any of 860 unit tests)
  defp matches?(%Decimal{} = field_value, :eq, value),
    do: with_decimal(value, &(Decimal.compare(field_value, &1) == :eq))

  # Atoms and booleans compare as their text form - the same treatment
  # :in (values_equal?/2) and :contains already give them. Without this
  # clause :eq fell through to date coercion and a status: :active or
  # admin?: true column silently matched nothing.
  defp matches?(field_value, :eq, value) when is_atom(field_value),
    do: with_text(value, &(downcase(field_value) == &1))

  # Comparators are op-first, not type-first. Guarding :neq on numbers
  # meant "is not" against any text column matched nothing at all, and
  # guarding the comparators on numbers meant a plain :lt against a date
  # column did the same - silently, since an unmatched clause falls to
  # the catch-all `false` rather than raising. Each comparator now tries
  # numbers, then dates, then text, so the op means the same thing
  # whatever the column holds.
  # A negation must never turn "this filter cannot be evaluated" into a
  # match. :neq with "abc" against a numeric column would otherwise
  # invert a coercion failure into EVERY row matching - the loudest
  # possible wrong answer. An unusable filter matches nothing here, as
  # it does everywhere else in this engine.
  defp matches?(field_value, :neq, value),
    do: evaluable?(field_value, value) and not matches?(field_value, :eq, value)

  defp matches?(field_value, :gt, value), do: compare(field_value, value, [:gt])
  defp matches?(field_value, :gte, value), do: compare(field_value, value, [:gt, :eq])
  defp matches?(field_value, :lt, value), do: compare(field_value, value, [:lt])
  defp matches?(field_value, :lte, value), do: compare(field_value, value, [:lt, :eq])

  # between IS gte and lte - one definition, so a date range behaves
  # exactly like the two comparators it decomposes into (the gate found
  # the old number-only guard made a date range match nothing, silently)
  defp matches?(field_value, :between, [min, max]),
    do: matches?(field_value, :gte, min) and matches?(field_value, :lte, max)

  defp matches?(field_value, :between, %{"min" => min, "max" => max}),
    do: matches?(field_value, :between, [min, max])

  defp matches?(field_value, :eq, value) do
    case {to_date(field_value), to_date(value)} do
      {{:ok, a}, {:ok, b}} -> Date.compare(a, b) == :eq
      _ -> false
    end
  end

  defp matches?(field_value, :not_contains, value) when is_scalar(field_value),
    do: text_value?(value) and not matches?(field_value, :contains, value)

  defp matches?(field_value, :in, values) when is_list(values) do
    Enum.any?(values, &values_equal?(field_value, &1))
  end

  defp matches?(field_value, :not_in, values)
       when is_scalar(field_value) and is_list(values) and values != [],
       do: not matches?(field_value, :in, values)

  # Date ops are defined only for date-typed cells. The old clause
  # coerced binary cells too, so a :string column holding "2026-01-05"
  # matched :on filters here while no SQL engine would cast every row -
  # a cross-engine divergence waiting for pathological data.
  defp matches?(%mod{} = field_value, op, value)
       when mod in [Date, DateTime, NaiveDateTime] and op in [:before, :on, :after] do
    with {:ok, field_date} <- to_date(field_value),
         {:ok, value_date} <- to_date(value) do
      case {op, Date.compare(field_date, value_date)} do
        {:before, :lt} -> true
        {:on, :eq} -> true
        {:after, :gt} -> true
        _ -> false
      end
    else
      _ -> false
    end
  end

  defp matches?(_field_value, _op, _value), do: false

  # one comparison ladder for every comparator: numbers, then dates, then
  # text. `wanted` is the set of Erlang comparison results that count as
  # a match, so :gte is just :gt plus :eq rather than a second ladder.
  defp compare(field_value, value, wanted) do
    cond do
      is_number(field_value) ->
        with_number(value, &(cmp(field_value, &1) in wanted))

      is_struct(field_value, Decimal) ->
        with_decimal(value, &(Decimal.compare(field_value, &1) in wanted))

      # date comparison only for date-TYPED cells - a text cell that
      # happens to parse as a date stays text, per the pinned rule (and
      # ISO strings order correctly as text anyway, which is exactly
      # what a SQL engine does with a text column)
      is_struct(field_value, Date) or is_struct(field_value, DateTime) or
          is_struct(field_value, NaiveDateTime) ->
        with {{:ok, a}, {:ok, b}} <- {to_date(field_value), to_date(value)} do
          Date.compare(a, b) in wanted
        else
          _ -> false
        end

      is_scalar(field_value) ->
        with_text(value, &(cmp(downcase(field_value), &1) in wanted))

      true ->
        false
    end
  end

  # Can the positive form of this filter actually be evaluated against a
  # field of this shape? Mirrors the coercion the :eq clauses perform.
  defp evaluable?(field_value, value) when is_binary(field_value), do: text_value?(value)
  defp evaluable?(field_value, value) when is_number(field_value), do: number_value?(value)

  defp evaluable?(%Decimal{}, value), do: match?({:ok, _}, decimal(value))

  defp evaluable?(%mod{}, value) when mod in [Date, DateTime, NaiveDateTime],
    do: match?({:ok, _}, to_date(value))

  # a field the positive op cannot read is unevaluable regardless of
  # how good the value is - both sides have to be readable
  defp evaluable?(field_value, value), do: is_scalar(field_value) and text_value?(value)

  defp text_value?(value) when is_binary(value) or is_number(value), do: true
  defp text_value?(value) when is_atom(value), do: not is_nil(value)
  defp text_value?(_other), do: false

  defp number_value?(value), do: match?({:ok, _}, number(value))

  defp empty_value?(nil), do: true
  defp empty_value?(""), do: true
  defp empty_value?([]), do: true
  defp empty_value?(_other), do: false

  defp values_equal?(a, b) when is_scalar(a),
    do: with_text(b, &(downcase(a) == &1))

  defp values_equal?(_a, _b), do: false

  # -- coercion --------------------------------------------------------------

  defp fetch(row, field) when is_map(row), do: Map.get(row, field)

  defp downcase(value) when is_binary(value), do: String.downcase(value)
  defp downcase(value), do: value |> to_string() |> String.downcase()

  # Filter values come straight from params and can be ANY shape (a list,
  # a map, whatever the query string carried) - a text op against a
  # non-scalar is a no-match, never a to_string crash.
  defp with_text(value, fun) when is_binary(value), do: fun.(String.downcase(value))

  defp with_text(value, fun) when is_number(value) or is_atom(value),
    do: fun.(value |> to_string() |> String.downcase())

  defp with_text(_other, _fun), do: false

  defp with_decimal(value, fun) do
    case decimal(value) do
      {:ok, d} -> fun.(d)
      :error -> false
    end
  end

  defp decimal(%Decimal{} = d), do: {:ok, d}
  defp decimal(value) when is_integer(value), do: {:ok, Decimal.new(value)}
  defp decimal(value) when is_float(value), do: {:ok, Decimal.from_float(value)}

  defp decimal(value) when is_binary(value) do
    case Decimal.parse(value) do
      {d, ""} -> {:ok, d}
      _ -> :error
    end
  end

  defp decimal(_other), do: :error

  defp to_decimal(n) when is_integer(n), do: Decimal.new(n)
  defp to_decimal(n) when is_float(n), do: Decimal.from_float(n)

  defp number(value) when is_number(value), do: {:ok, value}

  defp number(value) when is_binary(value) do
    case Float.parse(value) do
      {n, ""} -> {:ok, n}
      _ -> :error
    end
  end

  defp number(_other), do: :error

  defp with_number(value, fun) do
    case number(value) do
      {:ok, n} -> fun.(n)
      :error -> false
    end
  end

  defp to_date(%Date{} = date), do: {:ok, date}
  defp to_date(%DateTime{} = dt), do: {:ok, DateTime.to_date(dt)}
  defp to_date(%NaiveDateTime{} = ndt), do: {:ok, NaiveDateTime.to_date(ndt)}

  # Accept both date and datetime ISO 8601 strings - "2026-01-05",
  # "2026-01-05T10:30:00Z" (datetime inputs) and the offset-less
  # "2026-01-05T10:30" that <input type="datetime-local"> submits.
  defp to_date(value) when is_binary(value) do
    with {:error, _} <- Date.from_iso8601(value),
         {:error, _} <- iso_datetime_to_date(value) do
      :error
    end
  end

  defp to_date(_other), do: :error

  defp iso_datetime_to_date(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} ->
        {:ok, DateTime.to_date(dt)}

      {:error, _} ->
        # datetime-local submits without seconds ("2026-01-05T10:30");
        # NaiveDateTime requires them, so retry with ":00" appended -
        # garbage just fails again.
        case NaiveDateTime.from_iso8601(value) do
          {:ok, ndt} ->
            {:ok, NaiveDateTime.to_date(ndt)}

          {:error, _} ->
            case NaiveDateTime.from_iso8601(value <> ":00") do
              {:ok, ndt} -> {:ok, NaiveDateTime.to_date(ndt)}
              {:error, _} = error -> error
            end
        end
    end
  end
end
