defmodule PetalComponents.Showcase.DataTable do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.DataTable,
    title: "Data table"

  alias PetalComponents.DataTable.Engine
  alias PetalComponents.DataTable.State

  def sample_rows do
    people = ~w(Amy Bea Cal Dan Dee Eli Fay Gus Ida Joy Kim Lou Mia Ned Ola Pax Quin Rae Sol Tia)

    for {name, i} <- Enum.with_index(people, 1) do
      %{
        id: i,
        name: name,
        email: String.downcase(name) <> "@example.com",
        amount: rem(i * 137, 400) + 20,
        status: Enum.at(~w(paid pending refunded), rem(i, 3))
      }
    end
  end

  example :basic, "Sorted, paged, engine-run",
    description:
      "The whole surface from one State struct: sortable headers (aria-sort included), the range summary, and pagination that picks numbered mode because total is known. This static example runs the free in-memory engine over 20 rows at render time - zero setup, no database. In your app the same State drives handle_params (link mode) or a single op-grammar event (event mode)." do
    ~H"""
    <% state = %State{order_by: [amount: :desc], page: 1, page_size: 5} %>
    <% {rows, state} = Engine.List.run(PetalComponents.Showcase.DataTable.sample_rows(), state) %>
    <.data_table id="sx-dt-basic" rows={rows} state={state} path="#">
      <:col :let={row} field={:name} sortable>{row.name}</:col>
      <:col :let={row} field={:email}>{row.email}</:col>
      <:col :let={row} field={:amount} sortable align="right">${row.amount}</:col>
    </.data_table>
    """
  end

  example :toolbar, "The full toolbar: search, typed filters, per-page",
    inert: true,
    description:
      "searchable sweeps string fields case-insensitively before filters (totals stay honest); filterable columns get buttons that open typed popover editors - operator + value for text/number/date (between reveals its second bound, no JS), a checkbox list for select - and read their predicate while active, with an inline clear. page_size_options adds the per-page select; Reset filters appears while any filter is active. Event mode posts one op-grammar event for all of it (State.handle_op/3 is the whole handler); link mode patches curl-able URLs." do
    ~H"""
    <% state = %State{
      search: "i",
      filters: [%{field: :status, op: :in, value: ["pending", "refunded"]}],
      page_size: 5
    } %>
    <% {rows, state} = Engine.List.run(PetalComponents.Showcase.DataTable.sample_rows(), state) %>
    <.data_table
      id="sx-dt-toolbar"
      rows={rows}
      state={state}
      on_change="table"
      searchable
      page_size_options={[5, 10, 20]}
    >
      <:col :let={row} field={:name} sortable>{row.name}</:col>
      <:col :let={row} field={:email} filterable="text">{row.email}</:col>
      <:col
        :let={row}
        field={:status}
        filterable="select"
        options={[{"Paid", "paid"}, {"Pending", "pending"}, {"Refunded", "refunded"}]}
      >
        <.badge
          size="sm"
          variant="soft"
          color={
            case row.status do
              "paid" -> "success"
              "pending" -> "warning"
              _ -> "danger"
            end
          }
          label={row.status}
        />
      </:col>
      <:col :let={row} field={:amount} sortable align="right" filterable="number">
        ${row.amount}
      </:col>
    </.data_table>
    """
  end

  example :selection, "Row selection with a morphing toolbar",
    inert: true,
    description:
      "selectable adds a checkbox column keyed by row_id (a field or a function - it must uniquely identify records across ALL pages). The header checkbox is tri-state; while rows are selected the toolbar morphs into the count, your :bulk_action slot (:let receives the ids) and a clear button. Selection is UI state: it rides the on_ui event (defaulting to on_change) with select / select_all / clear_selection ops and never touches URLs - a MapSet plus three clauses is the whole backend." do
    ~H"""
    <% state = %State{page_size: 4} %>
    <% {rows, state} = Engine.List.run(PetalComponents.Showcase.DataTable.sample_rows(), state) %>
    <.data_table
      id="sx-dt-selection"
      rows={rows}
      state={state}
      on_change="table"
      selectable
      selected={["1", "3"]}
    >
      <:col :let={row} field={:name} sortable>{row.name}</:col>
      <:col :let={row} field={:email}>{row.email}</:col>
      <:col :let={row} field={:amount} align="right">${row.amount}</:col>
      <:bulk_action :let={ids}>
        <.button size="sm" variant="soft" color="danger">Archive {length(ids)}</.button>
      </:bulk_action>
    </.data_table>
    """
  end

  example :columns, "Columns visibility and order",
    inert: true,
    description:
      "column_toggle renders a Columns dropdown - every declared column with a checkbox, toggling immediately (the panel stays open for multi-toggling). reorderable adds move controls posting a field + dir delta; DataTable.move_column/4 applies it to your current order in one line, race-free under rapid clicks. Both are presentation state on the on_ui event, never in URLs; the last visible column can't be hidden." do
    ~H"""
    <% state = %State{page_size: 4} %>
    <% {rows, state} = Engine.List.run(PetalComponents.Showcase.DataTable.sample_rows(), state) %>
    <.data_table
      id="sx-dt-columns"
      rows={rows}
      state={state}
      on_change="table"
      column_toggle
      reorderable
      hidden_columns={["email"]}
    >
      <:col :let={row} field={:name} sortable>{row.name}</:col>
      <:col :let={row} field={:email}>{row.email}</:col>
      <:col :let={row} field={:amount} align="right">${row.amount}</:col>
    </.data_table>
    """
  end

  example :loading, "Loading skeletons",
    description:
      "loading swaps the page for skeleton rows - one per page_size row, respecting column count and alignment. Flip it off when the query resolves." do
    ~H"""
    <% state = %State{total: 74, page_size: 4} %>
    <.data_table id="sx-dt-loading" rows={[]} state={state} path="#" loading>
      <:col :let={row} field={:name}>{row}</:col>
      <:col :let={row} field={:email}>{row}</:col>
      <:col :let={row} field={:amount} align="right">{row}</:col>
    </.data_table>
    """
  end

  example :empty, "The filters-aware empty state",
    description:
      "An empty result set with active filters says so and offers the way out - a clear-filters patch link in link mode, the op-grammar event in event mode. Without filters it is a plain no-results line. Override either with the :empty slot." do
    ~H"""
    <% state = %State{total: 0, filters: [%{field: :name, op: :contains, value: "zz"}]} %>
    <.data_table id="sx-dt-empty" rows={[]} state={state} path="#">
      <:col :let={row} field={:name}>{row}</:col>
      <:col :let={row} field={:email}>{row}</:col>
    </.data_table>
    """
  end
end
