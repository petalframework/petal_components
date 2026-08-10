defmodule TestSupport.SearchRow do
  @moduledoc false
  # stands in for an Ecto schema struct: not Enumerable, carries a
  # __meta__-like field the search sweep must skip
  defstruct [:id, :name, :email, __meta__: :stub]
end

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

    test "hand-built states with page 0 or size 0 clamp instead of slicing from the end" do
      {rows, state} = run(page: 0, page_size: 10)
      assert Enum.map(rows, & &1.id) == [1, 2, 3, 4, 5]
      assert state.page == 1

      {rows, state} = run(page: 1, page_size: 0)
      assert length(rows) == 1
      assert state.page_size == 1
      assert State.total_pages(%State{total: 74, page_size: 0}) == 74
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

  describe "search" do
    test "matches case-insensitively across string fields by default" do
      assert ids(run(search: "AM")) == [3]
      assert ids(run(search: "@a.com")) == [1]
    end

    test "search_fields scopes the sweep" do
      {rows, _} =
        Engine.run(@rows, struct!(State, search: "amy"), search_fields: [:email])

      assert Enum.map(rows, & &1.id) == [3]

      {rows, _} = Engine.run(@rows, struct!(State, search: "amy"), search_fields: [:name])
      assert Enum.map(rows, & &1.id) == [3]

      {rows, _} = Engine.run(@rows, struct!(State, search: "a.com"), search_fields: [:name])
      assert rows == []
    end

    test "search composes with filters and fills the filtered total" do
      {_, state} = run(search: "e", filters: [%{field: :amount, op: :lt, value: "100"}])
      assert state.total == 2
    end
  end

  describe "comparators across column types" do
    @typed [
      %{id: 1, name: "Amy", amount: 300, joined: ~D[2026-01-15], note: nil},
      %{id: 2, name: "Bea", amount: 40, joined: ~D[2026-06-01], note: ""},
      %{id: 3, name: "Cal", amount: 150, joined: ~D[2026-03-10], note: "hi"}
    ]

    defp names(filter) do
      {rows, _} = Engine.run(@typed, struct!(State, filters: [filter]))
      Enum.map(rows, & &1.name)
    end

    test "neq works on text, not only numbers" do
      # guarded on is_number before: "is not" against any text column
      # matched nothing, silently, because the catch-all returns false
      assert names(%{field: :name, op: :neq, value: "Amy"}) == ["Bea", "Cal"]
      assert names(%{field: :amount, op: :neq, value: "40"}) == ["Amy", "Cal"]
    end

    test "eq and the comparators work on dates, not only numbers" do
      assert names(%{field: :joined, op: :eq, value: "2026-01-15"}) == ["Amy"]
      assert names(%{field: :joined, op: :lt, value: "2026-06-01"}) == ["Amy", "Cal"]
      assert names(%{field: :joined, op: :gte, value: "2026-03-10"}) == ["Bea", "Cal"]
    end

    test "gte and lte include the boundary" do
      assert names(%{field: :amount, op: :gte, value: "150"}) == ["Amy", "Cal"]
      assert names(%{field: :amount, op: :lte, value: "150"}) == ["Bea", "Cal"]
    end

    test "negations mirror their positive op exactly" do
      assert names(%{field: :name, op: :not_contains, value: "a"}) == []
      assert names(%{field: :name, op: :not_in, value: ["Amy"]}) == ["Bea", "Cal"]
    end

    test "a negation never inverts a coercion failure into matching everything" do
      # :neq "abc" against a numeric column cannot be evaluated - the
      # positive form fails to coerce, and a bare `not` would turn that
      # into every row matching
      assert names(%{field: :amount, op: :neq, value: "abc"}) == []
      assert names(%{field: :joined, op: :neq, value: "not-a-date"}) == []
      assert names(%{field: :name, op: :not_contains, value: nil}) == []
      assert names(%{field: :name, op: :not_in, value: []}) == []

      # and the usable cases still invert normally
      assert names(%{field: :amount, op: :neq, value: "40"}) == ["Amy", "Cal"]
      assert names(%{field: :joined, op: :neq, value: "2026-01-15"}) == ["Bea", "Cal"]
    end

    test "atom and boolean columns compare like any other scalar" do
      rows = [
        %{name: "Amy", status: :active, admin?: true},
        %{name: "Bea", status: :archived, admin?: false}
      ]

      pick = fn filter ->
        {out, _} = Engine.run(rows, struct!(State, filters: [filter]))
        Enum.map(out, & &1.name)
      end

      # :eq fell through to date coercion for atoms, so an atom column
      # matched nothing - and :neq then inverted that into everything
      assert pick.(%{field: :status, op: :eq, value: "active"}) == ["Amy"]
      assert pick.(%{field: :status, op: :neq, value: "active"}) == ["Bea"]
      assert pick.(%{field: :admin?, op: :eq, value: "true"}) == ["Amy"]
      assert pick.(%{field: :admin?, op: :neq, value: "true"}) == ["Bea"]
    end

    test "a negation does not include rows whose field the positive op cannot read" do
      rows = [
        %{name: "Amy", meta: %{nested: 1}},
        %{name: "Bea", meta: "text"}
      ]

      pick = fn filter ->
        {out, _} = Engine.run(rows, struct!(State, filters: [filter]))
        Enum.map(out, & &1.name)
      end

      # :contains / :in / :eq cannot read a map field - their negations
      # must exclude that row rather than invert an unreadable field
      assert pick.(%{field: :meta, op: :not_contains, value: "zz"}) == ["Bea"]
      assert pick.(%{field: :meta, op: :not_in, value: ["y"]}) == ["Bea"]
      assert pick.(%{field: :meta, op: :neq, value: "x"}) == ["Bea"]
    end

    test "emptiness counts nil, empty string and empty list - and nothing else" do
      # the only ops for which a nil field is a match rather than a miss
      assert names(%{field: :note, op: :is_empty, value: true}) == ["Amy", "Bea"]
      assert names(%{field: :note, op: :is_not_empty, value: true}) == ["Cal"]
    end
  end

  describe "case folding - the published contract" do
    # These pin the decision, made pre-publish with the evidence in
    # PR #, that text equality folds case: a person picking "is" in a
    # filter means "this value", not "these bytes". A byte-exact
    # equality, if ever needed, arrives as a NEW operator - these
    # assertions are here to make silently changing this one impossible.
    @cased [
      %{id: 1, name: "Alice", status: :Active},
      %{id: 2, name: "alice", status: :active},
      %{id: 3, name: "Bob", status: :archived}
    ]

    defp cased(filter) do
      {rows, _} = Engine.run(@cased, struct!(State, filters: [filter]))
      Enum.map(rows, & &1.id)
    end

    test "eq/neq/in/not_in all fold case, together" do
      # one equality primitive - a half-folded family would let
      # "is not alice" leave a visible Alice on screen
      assert cased(%{field: :name, op: :eq, value: "ALICE"}) == [1, 2]
      assert cased(%{field: :name, op: :neq, value: "ALICE"}) == [3]
      assert cased(%{field: :name, op: :in, value: ["ALICE"]}) == [1, 2]
      assert cased(%{field: :name, op: :not_in, value: ["ALICE"]}) == [3]
      assert cased(%{field: :status, op: :eq, value: "ACTIVE"}) == [1, 2]
    end

    test "case folds; accents do not" do
      rows = [%{id: 1, name: "café"}, %{id: 2, name: "CAFÉ"}, %{id: 3, name: "cafe"}]

      {hit, _} =
        Engine.run(rows, struct!(State, filters: [%{field: :name, op: :eq, value: "café"}]))

      assert Enum.map(hit, & &1.id) == [1, 2]
    end
  end

  describe "differential-gate findings" do
    # Every case here was found by running the same State through this
    # engine AND through a Flop/Postgres bridge over identical rows -
    # the two-implementation test that unit tests cannot perform.

    @money [
      %{id: 1, name: "Amy", price: Decimal.new("10.50"), joined: ~D[2026-01-15]},
      %{id: 2, name: "Bea", price: Decimal.new("-10.00"), joined: ~D[2026-03-10]},
      %{id: 3, name: "Cal", price: Decimal.new("99.99"), joined: ~D[2026-06-01]},
      %{id: 4, name: "Dee", price: nil, joined: nil}
    ]

    defp money(filter) do
      {rows, _} = Engine.run(@money, struct!(State, filters: [filter]))
      Enum.map(rows, & &1.id)
    end

    test "Decimal columns filter like numbers (E1: every op matched zero rows)" do
      assert money(%{field: :price, op: :eq, value: "10.50"}) == [1]
      assert money(%{field: :price, op: :neq, value: "10.50"}) == [2, 3]
      assert money(%{field: :price, op: :gt, value: "0"}) == [1, 3]
      assert money(%{field: :price, op: :lte, value: "10.50"}) == [1, 2]
      assert money(%{field: :price, op: :between, value: ["0", "50"]}) == [1]
      assert money(%{field: :price, op: :is_empty, value: true}) == [4]
    end

    test "Decimal columns sort by value, not by struct internals (E1: -10.00 sorted largest)" do
      {rows, _} = Engine.run(@money, struct!(State, order_by: [price: :asc]))
      # nils last, then numeric order - negative first
      assert Enum.map(rows, & &1.id) == [2, 1, 3, 4]

      {rows, _} = Engine.run(@money, struct!(State, order_by: [price: :desc]))
      assert Enum.map(rows, & &1.id) == [3, 1, 2, 4]
    end

    test "between works on dates, exactly like the comparators it decomposes into (E2)" do
      assert money(%{field: :joined, op: :between, value: ["2026-02-01", "2026-06-01"]}) ==
               [2, 3]

      # inclusive both bounds, matching the pinned semantics
      assert money(%{field: :joined, op: :between, value: ["2026-01-15", "2026-03-10"]}) ==
               [1, 2]
    end

    test ":in works on date and Decimal columns via text form (G4: select filters matched nothing)" do
      assert money(%{field: :joined, op: :in, value: ["2026-01-15", "2026-06-01"]}) == [1, 3]
      assert money(%{field: :price, op: :in, value: ["10.50"]}) == [1]
      # text-form comparison: a padded "010.50" is not the same text
      assert money(%{field: :price, op: :in, value: ["010.50"]}) == []
    end

    test "comparators and between treat text cells as text, even ISO-looking ones" do
      rows = [
        %{id: 1, stamp: "2026-01-05T09:00"},
        %{id: 2, stamp: "2026-01-05T23:00"},
        %{id: 3, stamp: ~D[2026-01-05]}
      ]

      pick = fn filter ->
        {out, _} = Engine.run(rows, struct!(State, filters: [filter]))
        Enum.map(out, & &1.id)
      end

      # text between is lexicographic - the 23:00 STRING is outside a
      # range ending at 12:00 (date-coercion would have flattened it to
      # the day and wrongly included it), while the true Date cell
      # rightly matches a range within its own day
      assert pick.(%{field: :stamp, op: :between, value: ["2026-01-05T00:00", "2026-01-05T12:00"]}) ==
               [1, 3]

      # a real Date cell still compares as a date
      assert pick.(%{field: :stamp, op: :gte, value: "2026-01-05"}) == [3]
    end

    test "date ops are defined only for date-typed cells (G5)" do
      rows = [%{id: 1, when: "2026-01-05"}, %{id: 2, when: ~D[2026-01-05]}]

      {hit, _} =
        Engine.run(rows, struct!(State, filters: [%{field: :when, op: :on, value: "2026-01-05"}]))

      # the text cell holding an ISO string does NOT match - no SQL
      # engine would cast every row to find out
      assert Enum.map(hit, & &1.id) == [2]
    end

    test "default quick-search fields survive Ecto-style structs (G3)" do
      rows = [
        struct(TestSupport.SearchRow, id: 1, name: "Amy", email: "amy@x.com"),
        struct(TestSupport.SearchRow, id: 2, name: "Bea", email: "bea@x.com")
      ]

      {hit, _} = Engine.run(rows, struct!(State, search: "amy"))
      assert Enum.map(hit, & &1.id) == [1]
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

    test "composite ROW field values (maps, lists, tuples in cells) never match and never raise" do
      rows = [
        %{id: 1, tags: %{a: 1}},
        %{id: 2, tags: [1, 2]},
        %{id: 3, tags: {:t, 1}},
        %{id: 4, tags: "real"}
      ]

      state = struct!(State, filters: [%{field: :tags, op: :contains, value: "real"}])
      {out, _} = Engine.run(rows, state)
      assert Enum.map(out, & &1.id) == [4]

      state = struct!(State, filters: [%{field: :tags, op: :in, value: ["real"]}])
      {out, _} = Engine.run(rows, state)
      assert Enum.map(out, & &1.id) == [4]
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
