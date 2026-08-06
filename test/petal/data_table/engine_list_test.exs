defmodule PetalComponents.DataTable.Engine.ListTest do
  use ExUnit.Case, async: true

  alias PetalComponents.DataTable.Engine.List, as: Engine
  alias PetalComponents.DataTable.State

  @rows [
    %{id: 1, email: "dan@a.com", name: "Dan", amount: 120, joined: ~D[2026-01-05]},
    %{id: 2, email: "bea@b.com", name: "bea", amount: 40, joined: ~D[2026-03-10]},
    %{id: 3, email: "amy@c.com", name: "Amy", amount: 300, joined: ~D[2026-02-01]},
    %{id: 4, email: "cal@d.com", name: nil, amount: 40, joined: ~D[2026-01-05]},
    %{id: 5, email: "dee@e.com", name: "Dee", amount: 88.5, joined: ~D[2026-04-20]}
  ]

  defp run(state_attrs) do
    Engine.run(@rows, struct!(State, state_attrs))
  end

  defp ids({rows, _state}), do: Enum.map(rows, & &1.id)

  describe "pagination and total" do
    test "returns the requested page and fills total in" do
      {rows, state} = run(page: 2, page_size: 2)
      assert length(rows) == 2
      assert state.total == 5
    end

    test "a page past the end is empty, not an error" do
      {rows, _} = run(page: 9, page_size: 10)
      assert rows == []
    end

    test "total counts the FILTERED set, not the source list" do
      {_, state} =
        run(filters: [%{field: :amount, op: :eq, value: "40"}], page_size: 1)

      assert state.total == 2
    end
  end

  describe "sorting" do
    test "sorts strings case-insensitively" do
      assert ids(run(order_by: [name: :asc], page_size: 10)) == [3, 2, 1, 5, 4]
    end

    test "nils sort last in both directions" do
      asc = ids(run(order_by: [name: :asc], page_size: 10))
      desc = ids(run(order_by: [name: :desc], page_size: 10))
      assert List.last(asc) == 4
      assert List.last(desc) == 4
    end

    test "multi-sort: ties on the first key break on the second" do
      assert ids(run(order_by: [amount: :asc, email: :desc], page_size: 10)) ==
               [4, 2, 5, 1, 3]
    end

    test "sorts dates" do
      assert ids(run(order_by: [joined: :desc], page_size: 10)) |> hd() == 5
    end
  end

  describe "filtering" do
    test "contains is case-insensitive" do
      assert ids(run(filters: [%{field: :name, op: :contains, value: "DE"}])) == [5]
    end

    test "starts_with" do
      assert ids(run(filters: [%{field: :email, op: :starts_with, value: "d"}])) == [1, 5]
    end

    test "string eq is case-insensitive" do
      assert ids(run(filters: [%{field: :name, op: :eq, value: "BEA"}])) == [2]
    end

    test "numeric ops coerce string values from params" do
      assert ids(run(filters: [%{field: :amount, op: :gt, value: "100"}])) == [1, 3]
      assert ids(run(filters: [%{field: :amount, op: :lt, value: "50"}])) == [2, 4]
      assert ids(run(filters: [%{field: :amount, op: :neq, value: "40"}])) == [1, 3, 5]

      assert ids(run(filters: [%{field: :amount, op: :between, value: ["40", "120"]}])) ==
               [1, 2, 4, 5]
    end

    test "between accepts the min/max map shape phoenix forms produce" do
      filter = %{field: :amount, op: :between, value: %{"min" => "80", "max" => "200"}}
      assert ids(run(filters: [filter])) == [1, 5]
    end

    test "a non-numeric value never matches numeric ops instead of raising" do
      assert ids(run(filters: [%{field: :amount, op: :gt, value: "abc"}])) == []
    end

    test "in matches any of the listed values" do
      assert ids(run(filters: [%{field: :name, op: :in, value: ["amy", "Dee"]}])) == [3, 5]
    end

    test "date ops compare against ISO8601 strings from params" do
      assert ids(run(filters: [%{field: :joined, op: :before, value: "2026-02-01"}])) == [1, 4]
      assert ids(run(filters: [%{field: :joined, op: :on, value: "2026-01-05"}])) == [1, 4]
      assert ids(run(filters: [%{field: :joined, op: :after, value: "2026-03-01"}])) == [2, 5]
    end

    test "non-scalar filter values (raw param shapes) never match and never raise" do
      for junk <- [%{"a" => 1}, [%{"b" => 2}], [["nested"]], {:tuple, 1}] do
        assert ids(run(filters: [%{field: :name, op: :contains, value: junk}])) == []
        assert ids(run(filters: [%{field: :name, op: :starts_with, value: junk}])) == []
        assert ids(run(filters: [%{field: :name, op: :eq, value: junk}])) == []
        assert ids(run(filters: [%{field: :name, op: :in, value: [junk]}])) == []
      end
    end

    test "date ops accept ISO 8601 datetime strings, including datetime-local's offset-less shape" do
      assert ids(run(filters: [%{field: :joined, op: :on, value: "2026-01-05T10:30:00Z"}])) ==
               [1, 4]

      assert ids(run(filters: [%{field: :joined, op: :on, value: "2026-01-05T10:30"}])) ==
               [1, 4]

      assert ids(run(filters: [%{field: :joined, op: :before, value: "not-a-date"}])) == []
    end

    test "nil field values never match" do
      assert ids(run(filters: [%{field: :name, op: :contains, value: ""}])) ==
               [1, 2, 3, 5]
    end

    test "filters stack with AND semantics" do
      filters = [
        %{field: :amount, op: :lt, value: "150"},
        %{field: :email, op: :contains, value: "a"}
      ]

      assert ids(run(filters: filters)) == [1, 2, 4]
    end
  end

  test "the full pipeline composes: filter, then sort, then paginate" do
    {rows, state} =
      run(
        filters: [%{field: :amount, op: :lt, value: "150"}],
        order_by: [amount: :desc],
        page: 1,
        page_size: 2
      )

    assert Enum.map(rows, & &1.id) == [1, 5]
    assert state.total == 4
    assert State.total_pages(state) == 2
  end
end
