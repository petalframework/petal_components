defmodule PetalComponents.DataTable.StateTest do
  use ExUnit.Case, async: true

  alias PetalComponents.DataTable.State

  @fields ~w(email name amount inserted_at)a

  describe "from_params/2" do
    test "empty params produce the defaults" do
      state = State.from_params(%{}, fields: @fields)
      assert state == %State{order_by: [], filters: [], page: 1, page_size: 10, total: nil}
    end

    test "parses order_by with directions, defaulting asc" do
      state = State.from_params(%{"order_by" => "email:desc,name"}, fields: @fields)
      assert state.order_by == [email: :desc, name: :asc]
    end

    test "drops order_by fields outside the whitelist - no atom creation from input" do
      state =
        State.from_params(%{"order_by" => "email,__struct__:desc,secret"}, fields: @fields)

      assert state.order_by == [email: :asc]
    end

    test "an unknown direction falls back to asc" do
      state = State.from_params(%{"order_by" => "email:sideways"}, fields: @fields)
      assert state.order_by == [email: :asc]
    end

    test "parses filters from a list" do
      params = %{"filters" => [%{"field" => "email", "op" => "contains", "value" => "d"}]}
      state = State.from_params(params, fields: @fields)
      assert state.filters == [%{field: :email, op: :contains, value: "d"}]
    end

    test "parses filters from Phoenix-style indexed maps, in index order" do
      params = %{
        "filters" => %{
          "1" => %{"field" => "name", "op" => "eq", "value" => "b"},
          "0" => %{"field" => "email", "op" => "contains", "value" => "a"}
        }
      }

      state = State.from_params(params, fields: @fields)
      assert Enum.map(state.filters, & &1.field) == [:email, :name]
    end

    test "drops filters with unknown fields or ops, and malformed entries" do
      params = %{
        "filters" => [
          %{"field" => "secret", "op" => "contains", "value" => "x"},
          %{"field" => "email", "op" => "drop_table", "value" => "x"},
          %{"nope" => true},
          %{"field" => "email", "op" => "eq", "value" => "keep"}
        ]
      }

      state = State.from_params(params, fields: @fields)
      assert state.filters == [%{field: :email, op: :eq, value: "keep"}]
    end

    test "parses and clamps page and page_size" do
      state =
        State.from_params(%{"page" => "3", "page_size" => "500"},
          fields: @fields,
          max_page_size: 100
        )

      assert state.page == 3
      assert state.page_size == 100
    end

    test "misconfigured non-positive size options clamp to the contract" do
      state = State.from_params(%{}, fields: @fields, page_size: 0)
      assert state.page_size == 1

      state =
        State.from_params(%{"page_size" => "50"}, fields: @fields, max_page_size: -5)

      assert state.page_size == 1
    end

    test "garbage page values fall back to defaults" do
      state =
        State.from_params(%{"page" => "-2", "page_size" => "abc"},
          fields: @fields,
          page_size: 25
        )

      assert state.page == 1
      assert state.page_size == 25
    end
  end

  describe "to_params/1 round-trip" do
    test "defaults encode to an empty map - clean URLs" do
      assert State.to_params(%State{}) == %{}
    end

    test "a full state round-trips through from_params" do
      state = %State{
        order_by: [email: :desc, name: :asc],
        filters: [%{field: :amount, op: :gt, value: "100"}],
        page: 3,
        page_size: 25,
        total: 74
      }

      params =
        state
        |> State.to_params()
        |> Map.new(fn {k, v} -> {k, v} end)

      rebuilt = State.from_params(stringify(params), fields: @fields)

      assert rebuilt.order_by == state.order_by
      assert rebuilt.filters == state.filters
      assert rebuilt.page == state.page
      assert rebuilt.page_size == state.page_size
      # total is a result, not a request - it never round-trips
      assert rebuilt.total == nil
    end
  end

  describe "search" do
    test "round-trips, trims, and blanks to nil" do
      state = State.from_params(%{"search" => "  amy "}, fields: @fields)
      assert state.search == "amy"
      assert State.to_params(state) == %{"search" => "amy"}
      assert State.from_params(%{"search" => "   "}, fields: @fields).search == nil
      assert State.to_params(%State{}) == %{}
    end

    test "put_search/2 sets, clears on blank, and resets the page" do
      state = State.put_search(%State{page: 5}, "amy")
      assert state.search == "amy"
      assert state.page == 1
      assert State.put_search(state, "").search == nil
    end
  end

  describe "handle_op/3" do
    @opts [fields: [:name, :amount, :status]]

    test "dispatches the whole event grammar" do
      state = %State{page: 3}

      assert State.handle_op(state, %{"op" => "sort", "field" => "name"}, @opts).order_by ==
               [name: :asc]

      assert State.handle_op(state, %{"op" => "page", "page" => "2"}, @opts).page == 2
      assert State.handle_op(state, %{"op" => "search", "term" => "x"}, @opts).search == "x"

      assert State.handle_op(state, %{"op" => "page_size", "page_size" => "50"}, @opts).page_size ==
               50

      filtered = %{state | filters: [%{field: :name, op: :contains, value: "a"}]}
      assert State.handle_op(filtered, %{"op" => "clear_filters"}, @opts).filters == []
    end

    test "unknown ops and non-whitelisted fields leave the state unchanged" do
      state = %State{}
      assert State.handle_op(state, %{"op" => "drop_tables"}, @opts) == state
      assert State.handle_op(state, %{"op" => "sort", "field" => "secret"}, @opts) == state

      assert State.handle_op(
               state,
               %{"op" => "filter", "field" => "secret", "value" => "x"},
               @opts
             ) == state
    end

    test "filter op normalizes by editor shape" do
      state = %State{}

      text =
        State.handle_op(
          state,
          %{"op" => "filter", "field" => "name", "filter_op" => "contains", "value" => "am"},
          @opts
        )

      assert text.filters == [%{field: :name, op: :contains, value: "am"}]

      selected =
        State.handle_op(
          state,
          %{"op" => "filter", "field" => "status", "filter_op" => "in", "values" => ["a", "b"]},
          @opts
        )

      assert selected.filters == [%{field: :status, op: :in, value: ["a", "b"]}]

      # the select editor posts values[] with no filter_op - still :in
      bare =
        State.handle_op(
          state,
          %{"op" => "filter", "field" => "status", "values" => ["a"]},
          @opts
        )

      assert bare.filters == [%{field: :status, op: :in, value: ["a"]}]

      between =
        State.handle_op(
          state,
          %{
            "op" => "filter",
            "field" => "amount",
            "filter_op" => "between",
            "value" => "10",
            "value2" => "90"
          },
          @opts
        )

      assert between.filters == [%{field: :amount, op: :between, value: ["10", "90"]}]

      half_range =
        State.handle_op(
          between,
          %{"op" => "filter", "field" => "amount", "filter_op" => "between", "value" => "10"},
          @opts
        )

      assert half_range.filters == []

      removed = State.handle_op(text, %{"op" => "filter", "field" => "name"}, @opts)
      assert removed.filters == []
    end
  end

  describe "toggle_sort/2" do
    test "cycles asc -> desc -> removed and resets the page" do
      state = %State{page: 7}

      s1 = State.toggle_sort(state, :email)
      assert s1.order_by == [email: :asc]
      assert s1.page == 1

      s2 = State.toggle_sort(s1, :email)
      assert s2.order_by == [email: :desc]

      s3 = State.toggle_sort(s2, :email)
      assert s3.order_by == []
    end

    test "sorting a new field replaces the previous sort" do
      state = %State{order_by: [email: :desc]}
      assert State.toggle_sort(state, :name).order_by == [name: :asc]
    end
  end

  describe "put_filter/4 and clear_filters/1" do
    test "adds, replaces per field, and resets the page" do
      state =
        %State{page: 4}
        |> State.put_filter(:email, :contains, "a")
        |> State.put_filter(:name, :eq, "bo")
        |> State.put_filter(:email, :contains, "b")

      assert state.filters == [
               %{field: :name, op: :eq, value: "bo"},
               %{field: :email, op: :contains, value: "b"}
             ]

      assert state.page == 1
    end

    test "a nil/empty value removes the field's filter" do
      state =
        %State{}
        |> State.put_filter(:email, :contains, "a")
        |> State.put_filter(:email, :contains, "")

      assert state.filters == []
    end

    test "clear_filters/1 empties everything" do
      state = %State{filters: [%{field: :email, op: :eq, value: "x"}], page: 3}
      assert State.clear_filters(state) == %State{filters: [], page: 1}
    end
  end

  describe "total_pages/1" do
    test "nil total means unknown" do
      assert State.total_pages(%State{total: nil}) == nil
    end

    test "rounds up and floors at 1" do
      assert State.total_pages(%State{total: 74, page_size: 10}) == 8
      assert State.total_pages(%State{total: 0, page_size: 10}) == 1
    end
  end

  defp stringify(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), stringify(v)} end)
  end

  defp stringify(list) when is_list(list), do: Enum.map(list, &stringify/1)
  defp stringify(value) when is_integer(value), do: Integer.to_string(value)
  defp stringify(value), do: value
end
