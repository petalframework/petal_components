defmodule PetalComponents.Showcase.Filters do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Filters,
    title: "Filters"

  alias PetalComponents.DataTable.Engine
  alias PetalComponents.DataTable.State

  def products do
    names = ~w(Anvil Bellows Chisel Drawknife Eyelet Forge Gouge Hammer Ingot Jointer Kiln Lathe)
    categories = ~w(hand power finishing)

    for {name, i} <- Enum.with_index(names, 1) do
      %{
        id: i,
        name: name,
        category: Enum.at(categories, rem(i, 3)),
        price: rem(i * 47, 300) + 15,
        in_stock: rem(i, 4) != 0,
        added_on: Date.add(~D[2026-01-01], i * 9)
      }
    end
  end

  example :empty, "Nothing filtered yet",
    inert: true,
    description:
      "With no active filters the bar is one trigger. Open it and you get the field list, pick a field and the same panel swaps to that field's operator and value editor - no round trip, no hook, and Escape backs out with focus returned to the trigger." do
    ~H"""
    <.filters id="sx-filters-empty" state={%State{}} on_change="table">
      <:field field={:name} label="Name" type="text" />
      <:field
        field={:category}
        type="select"
        options={[{"Hand tools", "hand"}, {"Power tools", "power"}, {"Finishing", "finishing"}]}
      />
      <:field field={:price} label="Price" type="number_range" />
      <:field field={:in_stock} label="In stock" type="boolean" />
      <:field field={:added_on} label="Added" type="date_range" />
    </.filters>
    """
  end

  example :chips, "Active filters as chips",
    inert: true,
    description:
      "Every filter in the state renders as a chip: field, humanised operator, formatted value. between shows both bounds, in shows a truncated list, and a valueless op like is_empty shows no value at all. Click the chip body to reopen its editor pre-filled; the x removes it and moves focus to the next chip." do
    ~H"""
    <.filters
      id="sx-filters-chips"
      state={
        %State{
          filters: [
            %{field: :category, op: :eq, value: "power"},
            %{field: :price, op: :between, value: ["50", "150"]},
            %{field: :name, op: :is_not_empty, value: true}
          ]
        }
      }
      on_change="table"
    >
      <:field field={:name} label="Name" type="text" />
      <:field
        field={:category}
        type="select"
        options={[{"Hand tools", "hand"}, {"Power tools", "power"}, {"Finishing", "finishing"}]}
      />
      <:field field={:price} label="Price" type="number_range" />
      <:field field={:in_stock} label="In stock" type="boolean" />
    </.filters>
    """
  end

  example :shared_state, "One State, bar and table",
    description:
      "The composition proof. Both components read and write the same State struct, so filtering from the bar updates the table and filtering from a column header adds a chip. This example runs the free in-memory engine at render time in link mode - the whole backend is handle_params plus State.from_params/2." do
    ~H"""
    <% state = %State{
      filters: [%{field: :category, op: :eq, value: "hand"}],
      page_size: 5
    } %>
    <% {rows, state} =
      Engine.List.run(PetalComponents.Showcase.Filters.products(), state) %>
    <div class="flex flex-col gap-4">
      <.filters id="sx-filters-shared" state={state} path="#">
        <:field field={:name} label="Name" type="text" />
        <:field
          field={:category}
          type="select"
          options={[{"Hand tools", "hand"}, {"Power tools", "power"}, {"Finishing", "finishing"}]}
        />
        <:field field={:price} label="Price" type="number_range" />
        <:field field={:in_stock} label="In stock" type="boolean" />
      </.filters>
      <.data_table id="sx-filters-table" rows={rows} state={state} path="#">
        <:col :let={p} field={:name} sortable>{p.name}</:col>
        <:col :let={p} field={:category} filterable="text">{p.category}</:col>
        <:col :let={p} field={:price} sortable align="right">${p.price}</:col>
      </.data_table>
    </div>
    """
  end
end
