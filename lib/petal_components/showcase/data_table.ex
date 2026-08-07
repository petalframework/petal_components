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
