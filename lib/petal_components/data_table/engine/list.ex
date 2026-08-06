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

  @doc "Runs the full pipeline: filter -> sort -> count -> paginate."
  def run(rows, %State{} = state) when is_list(rows) do
    filtered = Enum.reduce(state.filters, rows, &apply_filter(&2, &1))
    total = length(filtered)

    page_rows =
      filtered
      |> sort(state.order_by)
      |> Enum.slice((state.page - 1) * state.page_size, state.page_size)

    {page_rows, %{state | total: total}}
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

  defp matches?(nil, _op, _value), do: false

  defp matches?(field_value, :contains, value),
    do: with_text(value, &String.contains?(downcase(field_value), &1))

  defp matches?(field_value, :starts_with, value),
    do: with_text(value, &String.starts_with?(downcase(field_value), &1))

  defp matches?(field_value, :eq, value) when is_binary(field_value),
    do: with_text(value, &(downcase(field_value) == &1))

  defp matches?(field_value, :eq, value) when is_number(field_value),
    do: with_number(value, &(field_value == &1))

  defp matches?(field_value, :neq, value) when is_number(field_value),
    do: with_number(value, &(field_value != &1))

  defp matches?(field_value, :gt, value) when is_number(field_value),
    do: with_number(value, &(field_value > &1))

  defp matches?(field_value, :lt, value) when is_number(field_value),
    do: with_number(value, &(field_value < &1))

  defp matches?(field_value, :between, [min, max]) when is_number(field_value) do
    with_number(min, fn lo ->
      with_number(max, fn hi -> field_value >= lo and field_value <= hi end)
    end)
  end

  defp matches?(field_value, :between, %{"min" => min, "max" => max}),
    do: matches?(field_value, :between, [min, max])

  defp matches?(field_value, :in, values) when is_list(values) do
    Enum.any?(values, &values_equal?(field_value, &1))
  end

  defp matches?(field_value, op, value) when op in [:before, :on, :after] do
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

  defp values_equal?(a, b) when is_binary(a),
    do: with_text(b, &(downcase(a) == &1))

  defp values_equal?(a, b) when is_atom(a),
    do: with_text(b, &(String.downcase(Atom.to_string(a)) == &1))

  defp values_equal?(a, b),
    do: with_text(b, &(String.downcase(to_string(a)) == &1))

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
