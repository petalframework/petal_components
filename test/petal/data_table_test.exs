defmodule PetalComponents.DataTableTest do
  use ComponentCase

  import PetalComponents.DataTable

  alias PetalComponents.DataTable.State

  @rows [
    %{name: "Amy", email: "amy@x.com", amount: 300},
    %{name: "Bea", email: "bea@x.com", amount: 40}
  ]

  defp base(assigns \\ %{}) do
    Map.merge(%{rows: @rows, state: %State{total: 74}, path: "/orders"}, assigns)
  end

  test "searchable event mode: a phx-change form posts the search op with debounce" do
    assigns = base(%{state: %State{total: 74, search: "amy"}})

    html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} on_change="table" searchable>
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)

    assert html =~ ~s(phx-change="table")
    assert html =~ ~s(name="op" value="search")
    assert html =~ ~s(phx-debounce="300")
    assert html =~ ~s(value="amy")
    refute html =~ "PetalDataTable"
  end

  test "searchable link mode: the hook mounts with a :term URL template and a nav anchor" do
    assigns = base(%{state: %State{total: 74, order_by: [name: :desc]}})

    html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} path={@path} searchable>
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)

    assert html =~ ~s(phx-hook="PetalDataTable")
    assert html =~ "data-pc-dt-search"
    assert html =~ "data-pc-dt-nav"
    assert html =~ ~s(data-nav-template="/orders?search=:term&amp;order_by=name%3Adesc")
  end

  test "page_size_options renders the footer select in both wiring modes" do
    assigns = base(%{state: %State{total: 74, page_size: 20}})

    event_html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} on_change="table" page_size_options={[10, 20, 50]}>
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)

    assert event_html =~ ~s(name="op" value="page_size")
    assert event_html =~ ~s(<option value="20" selected>)

    link_html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} path={@path} page_size_options={[10, 20, 50]}>
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)

    assert link_html =~ "data-pc-dt-page-size"
    assert link_html =~ ~s(data-nav-template="/orders?page_size=:page_size")
  end

  test "filterable columns render popover editors typed per column" do
    assigns =
      base(%{
        rows: [
          %{name: "Amy", email: "amy@x.com", amount: 300, status: "pending"},
          %{name: "Bea", email: "bea@x.com", amount: 40, status: "paid"}
        ],
        state: %State{
          total: 74,
          filters: [%{field: :status, op: :in, value: ["pending", "paid"]}]
        }
      })

    html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} on_change="table">
        <:col :let={row} field={:email} filterable="text">{row.email}</:col>
        <:col :let={row} field={:amount} filterable="number">{row.amount}</:col>
        <:col :let={row} field={:status} filterable="select" options={["pending", "paid", "refunded"]}>
          {row.status}
        </:col>
      </.data_table>
      """)

    # text editor: op select with the text grammar
    assert html =~ ~s(name="filter_op")
    assert html =~ ~s(value="starts_with")
    # number editor: between + second bound input
    assert html =~ ~s(value="between")
    assert html =~ ~s(name="value2")
    # select editor: checkboxes, current picks checked
    assert html =~ ~s(name="values[]")
    assert html =~ ~s(value="pending" checked)
    refute html =~ ~s(value="refunded" checked)
    # active trigger reads the predicate; its clear button posts removal
    assert html =~ "Status is any of Pending, Paid"
    assert html =~ ~s(aria-label="Clear Status filter")
    # event mode carries the op grammar in hidden inputs; the hook mounts
    # only to close top-layer popovers - no URL wiring
    assert html =~ ~s(name="op" value="filter")
    assert html =~ ~s(phx-hook="PetalDataTable")
    # in-page menu anatomy: trigger and panel are siblings under a
    # relatively positioned wrapper, so the page carries them together
    assert html =~ ~s(data-pc-menu-trigger="t-filter-email")
    assert html =~ ~s(<div class="pc-popover">)
    assert html =~ ~s(hidden data-pc-menu)
    refute html =~ ~s(popover="auto")
    refute html =~ "data-nav-template"
    refute html =~ "data-filters="
  end

  test "filterable link mode: hook + :filters placeholder + JSON stamp + clear URL" do
    assigns =
      base(%{
        state: %State{total: 74, filters: [%{field: :email, op: :contains, value: "d"}]}
      })

    html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} path={@path}>
        <:col :let={row} field={:email} filterable="text">{row.email}</:col>
      </.data_table>
      """)

    assert html =~ ~s(phx-hook="PetalDataTable")
    assert html =~ "data-pc-dt-filter"
    assert html =~ ~s(data-field="email")
    assert html =~ ~s(data-nav-template="/orders?:filters")
    assert html =~ ~s(data-filters=)
    assert html =~ "contains"
    # the clear affordance patches to a filterless URL
    assert html =~ ~s(aria-label="Clear Email filter")
    refute html =~ ~s(href="/orders?filters)
  end

  test "selectable renders the checkbox column with tri-state header and morphing toolbar" do
    assigns =
      base(%{
        rows: [
          %{id: 1, name: "Amy"},
          %{id: 2, name: "Bea"}
        ],
        selected: ["1"]
      })

    html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} on_change="table" selectable selected={@selected}>
        <:col :let={row} field={:name}>{row.name}</:col>
        <:bulk_action :let={ids}>
          <button type="button">Archive {length(ids)}</button>
        </:bulk_action>
      </.data_table>
      """)

    # header checkbox: some-but-not-all selected -> indeterminate stamp
    assert html =~ ~s(phx-value-op="select_all")
    assert html =~ ~s(data-pc-dt-indeterminate="true")
    # row checkboxes: selected row checked, keyed by row id
    assert html =~ ~s(phx-value-op="select")
    assert html =~ ~s(phx-value-id="1")
    assert html =~ ~s(phx-value-id="2")
    # toolbar morphs: count + bulk action + clear, search hidden
    assert html =~ "1 selected"
    assert html =~ "Archive 1"
    assert html =~ ~s(phx-value-op="clear_selection")
    # hook mounts for the indeterminate sync
    assert html =~ ~s(phx-hook="PetalDataTable")
  end

  test "selectable: all page rows selected checks the header; none leaves the normal toolbar" do
    assigns =
      base(%{
        rows: [%{id: 1, name: "Amy"}, %{id: 2, name: "Bea"}],
        all: [1, 2]
      })

    all_html =
      rendered_to_string(~H"""
      <.data_table
        id="t"
        rows={@rows}
        state={@state}
        on_change="table"
        selectable
        selected={@all}
        searchable
      >
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)

    assert all_html =~ ~s(data-pc-dt-indeterminate="false")
    refute all_html =~ "pc-data-table__search"

    none_html =
      rendered_to_string(~H"""
      <.data_table
        id="t"
        rows={@rows}
        state={@state}
        on_change="table"
        selectable
        selected={[]}
        searchable
      >
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)

    assert none_html =~ "pc-data-table__search"
    refute none_html =~ "clear_selection"
  end

  test "selectable supports a row_id function and requires a ui event in link mode" do
    assigns =
      base(%{
        rows: [%{email: "amy@x.com", name: "Amy"}],
        key: fn row -> row.email end
      })

    html =
      rendered_to_string(~H"""
      <.data_table
        id="t"
        rows={@rows}
        state={@state}
        path={@path}
        on_ui="table_ui"
        selectable
        selected={["amy@x.com"]}
        row_id={@key}
      >
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)

    assert html =~ ~s(phx-value-id="amy@x.com")
    assert html =~ ~s(phx-click="table_ui")

    assert_raise ArgumentError, ~r/on_ui/, fn ->
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} path={@path} selectable>
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)
    end
  end

  test "selection identity edges: nil keys disable, duplicates raise, loading disables select-all" do
    assigns = base(%{rows: [%{id: 1, name: "Amy"}, %{id: nil, name: "Bea"}]})

    html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} on_change="table" selectable selected={[]}>
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)

    # the keyless row renders an inert checkbox and stays out of select-all math
    assert Regex.match?(~r/<input[^>]*disabled[^>]*phx-value-id=""/, html)

    assigns = base(%{dupes: [%{id: 1, name: "Amy"}, %{id: 1, name: "Bea"}]})

    assert_raise ArgumentError, ~r/duplicate row ids/, fn ->
      rendered_to_string(~H"""
      <.data_table id="t" rows={@dupes} state={@state} on_change="table" selectable selected={[]}>
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)
    end

    assigns = base(%{rows: [%{id: 1, name: "Amy"}]})

    loading_html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} on_change="table" selectable selected={[]} loading>
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)

    assert loading_html =~ ~s(phx-value-op="select_all")
    assert Regex.match?(~r/phx-value-op="select_all"[^>]*>/, loading_html)
    assert loading_html =~ ~s(disabled data-pc-dt-indeterminate)
  end

  test "toolbar count and bulk ids come from the normalized selection" do
    assigns =
      base(%{
        rows: [%{id: 1, name: "Amy"}, %{id: 2, name: "Bea"}],
        messy: ["1", "1", nil, "", 1]
      })

    html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} on_change="table" selectable selected={@messy}>
        <:col :let={row} field={:name}>{row.name}</:col>
        <:bulk_action :let={ids}>
          <span>ids:{Enum.join(ids, ",")}</span>
        </:bulk_action>
      </.data_table>
      """)

    # dupes/nils/blanks collapse: one real id -> count 1, slot gets ["1"]
    assert html =~ "1 selected"
    assert html =~ "ids:1<"
  end

  test "column_toggle renders the dropdown, hides columns, and guards the last one" do
    assigns = base(%{hidden: [:email]})

    html =
      rendered_to_string(~H"""
      <.data_table
        id="t"
        rows={@rows}
        state={@state}
        on_change="table"
        column_toggle
        hidden_columns={@hidden}
      >
        <:col :let={row} field={:name}>{row.name}</:col>
        <:col :let={row} field={:email}>{row.email}</:col>
      </.data_table>
      """)

    # the hidden column leaves the table but stays listed in the dropdown
    refute html =~ "amy@x.com"
    assert html =~ ~s(phx-value-op="toggle_column")
    assert html =~ ~s(phx-value-field="email")
    # the last visible column's checkbox is disabled - a table needs one
    assert Regex.match?(~r/<input[^>]*checked[^>]*disabled[^>]*phx-value-field="name"/, html) or
             Regex.match?(~r/<input[^>]*disabled[^>]*phx-value-field="name"/, html)

    assert_raise ArgumentError, ~r/column_toggle/, fn ->
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} path="/orders" column_toggle>
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)
    end
  end

  test "column_toggle invariants: all-hidden clamps to the first column; fragment labels render" do
    assigns = %{}
    em = ~H"<em>Nome</em>"
    assigns = base(%{hidden: [:name, :email], em: em})

    html =
      rendered_to_string(~H"""
      <.data_table
        id="t"
        rows={@rows}
        state={@state}
        on_change="table"
        column_toggle
        hidden_columns={@hidden}
      >
        <:col :let={row} field={:name} label={@em}>{row.name}</:col>
        <:col :let={row} field={:email}>{row.email}</:col>
      </.data_table>
      """)

    # a hand-built all-hidden state keeps the first declared column
    assert html =~ "Amy"
    refute html =~ "amy@x.com"
    # its checkbox reads visible (and disabled, being the last one standing)
    assert Regex.match?(~r/<input[^>]*checked[^>]*disabled[^>]*phx-value-field="name"/, html)
    # the dropdown renders the fragment label, same identity as the header
    assert length(String.split(html, "<em>Nome</em>")) - 1 == 2
  end

  test "a map-shaped between range renders instead of crashing" do
    assigns =
      base(%{
        state: %State{
          total: 74,
          filters: [%{field: :amount, op: :between, value: %{"min" => "10", "max" => "90"}}]
        }
      })

    html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} on_change="table">
        <:col :let={row} field={:amount} filterable="number">{row.amount}</:col>
      </.data_table>
      """)

    assert html =~ "Amount between 10–90"
    assert html =~ ~s(name="value" value="10")
    assert html =~ ~s(name="value2" value="90")
  end

  test "reset filters button appears only while filters are active" do
    filtered = %State{total: 74, filters: [%{field: :name, op: :contains, value: "a"}]}
    assigns = base(%{filtered: filtered})

    clean_html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} path={@path}>
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)

    refute clean_html =~ "Reset filters"

    link_html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@filtered} path={@path}>
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)

    assert link_html =~ "Reset filters"
    assert link_html =~ ~s(href="/orders")

    event_html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@filtered} on_change="table">
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)

    assert event_html =~ "Reset filters"
    assert event_html =~ ~s(phx-value-op="clear_filters")
  end

  test "renders rows through col slots with explicit and humanized labels" do
    assigns = base()

    html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} path={@path}>
        <:col :let={row} field={:name} label="Person">{row.name}</:col>
        <:col :let={row} field={:email}>{row.email}</:col>
      </.data_table>
      """)

    assert html =~ "Person"
    assert html =~ "Email"
    assert html =~ "amy@x.com"
    assert html =~ "Bea"
  end

  test "link mode: sortable headers patch toggled sort URLs; current sort carries aria-sort" do
    assigns = base(%{state: %State{total: 74, order_by: [name: :asc]}})

    html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} path={@path}>
        <:col :let={row} field={:name} sortable>{row.name}</:col>
      </.data_table>
      """)

    # toggling an asc sort patches to desc
    assert html =~ "order_by=name%3Adesc" or html =~ "order_by=name:desc"
    assert html =~ ~s|aria-sort="ascending"|
  end

  test "event mode: sort pushes the op grammar through on_change" do
    assigns = base(%{path: nil})

    html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} on_change="table">
        <:col :let={row} field={:name} sortable>{row.name}</:col>
      </.data_table>
      """)

    assert html =~ "phx-click"
    assert html =~ "table"
    assert html =~ "sort"
    assert html =~ "name"
  end

  test "footer range and numbered pagination when total is known" do
    assigns = base(%{state: %State{total: 74, page: 2}})

    html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} path={@path}>
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)

    assert html =~ "11–20 of 74"
    assert html =~ "pc-pagination__inner"
    # the page template keeps the rest of the query
    assert html =~ "page=:page" or html =~ "/orders?page="
  end

  test "cursor mode (nil total) renders the page word and the simple pagination" do
    assigns = base(%{state: %State{total: nil, page: 3}})

    html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} path={@path}>
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)

    assert html =~ "Page 3"
    assert html =~ "pc-pagination__simple"
  end

  test "loading renders skeleton rows instead of data" do
    assigns = base(%{state: %State{total: 74, page_size: 3}})

    html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} path={@path} loading>
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)

    refute html =~ "Amy"
    assert length(String.split(html, "pc-data-table__skeleton")) - 1 >= 3
  end

  test "empty default is filters-aware: plain text bare, clear affordance when filtered" do
    assigns = base(%{rows: [], state: %State{total: 0}})

    plain =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} path={@path}>
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)

    assert plain =~ "No results"
    refute plain =~ "Clear filters"

    assigns =
      base(%{
        rows: [],
        state: %State{total: 0, filters: [%{field: :name, op: :contains, value: "zz"}]}
      })

    filtered =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} path={@path}>
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)

    assert filtered =~ "No results for these filters"
    assert filtered =~ "Clear filters"
    # the clear link drops the filters from the query
    refute filtered =~ ~s|href="/orders?filters|
  end

  test "filters flatten into indexed query params the State can read back" do
    state = %State{total: 74, filters: [%{field: :name, op: :contains, value: "am"}]}
    assigns = base(%{state: state})

    html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} path={@path}>
        <:col :let={row} field={:name} sortable>{row.name}</:col>
      </.data_table>
      """)

    assert html =~ "filters%5B0%5D%5Bfield%5D=name" or html =~ "filters[0][field]=name"
  end

  test "a base path already carrying a query joins with & not ?" do
    assigns = base(%{path: "/orders?tab=all"})

    html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} path={@path}>
        <:col :let={row} field={:name} sortable>{row.name}</:col>
      </.data_table>
      """)

    assert html =~ "/orders?tab=all&amp;" or html =~ "/orders?tab=all&"
    refute html =~ "tab=all?"
  end

  test "action slot renders a trailing column" do
    assigns = base()

    html =
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state} path={@path}>
        <:col :let={row} field={:name}>{row.name}</:col>
        <:action :let={row}><button type="button">Edit {row.name}</button></:action>
      </.data_table>
      """)

    assert html =~ "Edit Amy"
    assert html =~ "pc-data-table__actions"
  end

  test "raises without either wiring mode" do
    assigns = base(%{path: nil})

    assert_raise ArgumentError, ~r/path.*on_change/, fn ->
      rendered_to_string(~H"""
      <.data_table id="t" rows={@rows} state={@state}>
        <:col :let={row} field={:name}>{row.name}</:col>
      </.data_table>
      """)
    end
  end
end
