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
    assert html =~ ~s(data-search-template="/orders?search=:term&amp;order_by=name%3Adesc")
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
    assert link_html =~ ~s(data-page-size-template="/orders?page_size=:page_size")
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
