defmodule PetalComponents.DataTable do
  @moduledoc """
  A full data table composed around `PetalComponents.Table`: sortable
  columns, paging, loading and empty states - driven entirely by a
  `PetalComponents.DataTable.State`.

  Two wiring modes, like pagination:

    * **link mode** (default, pass `path`): every sort and page change is
      a `patch` URL built via `State.to_params/1`. State is shareable,
      the back button works, and `handle_params` + `State.from_params/2`
      is the whole backend:

          def handle_params(params, _uri, socket) do
            state = State.from_params(params, fields: [:name, :email])
            {rows, state} = Engine.List.run(all_rows(), state)
            {:noreply, assign(socket, rows: rows, table: state)}
          end

    * **event mode** (pass `on_change`): one event, one grammar. Sorts
      arrive as `%{"op" => "sort", "field" => f}`, page changes as
      `%{"op" => "page", "page" => n}`, filter clears as
      `%{"op" => "clear_filters"}`.

  Rows can be any enumerable of maps/structs; pair with
  `PetalComponents.DataTable.Engine.List` for zero-setup in-memory
  data, or run the state against your own query layer.
  """
  use Phoenix.Component

  import PetalComponents.Pagination
  import PetalComponents.Skeleton
  import PetalComponents.Table

  alias PetalComponents.DataTable.State
  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :rows, :list, default: []
  attr :state, State, required: true

  attr :path, :string,
    default: nil,
    doc: """
    link mode: the base path sort and page changes patch to, with the
    state encoded as query params. Required unless `on_change` is set.
    """

  attr :on_change, :string,
    default: nil,
    doc: """
    event mode: the event every table interaction pushes, with an
    op-shaped payload (`op` of "sort" | "page" | "clear_filters").
    """

  attr :target, :any, default: nil, doc: "event mode: the phx-target (e.g. @myself)"
  attr :loading, :boolean, default: false, doc: "render skeleton rows instead of data"
  attr :density, :string, default: "comfortable", values: ["comfortable", "compact"]
  attr :striped, :boolean, default: false
  attr :sticky_header, :boolean, default: false
  attr :variant, :string, default: "basic", values: ["ghost", "basic"]
  attr :of_label, :string, default: "of", doc: "the range summary's connective, localizable"
  attr :page_label, :string, default: "Page", doc: "cursor mode's page word, localizable"

  attr :no_results_text, :string, default: "No results"

  attr :no_filtered_results_text, :string,
    default: "No results for these filters",
    doc: "the empty message while filters are active"

  attr :clear_filters_label, :string, default: "Clear filters"
  attr :class, :any, default: nil

  slot :col, required: true do
    attr :field, :atom, required: true
    attr :label, :string
    attr :sortable, :boolean
    attr :align, :string, values: ["left", "center", "right"]
    attr :class, :any
  end

  slot :action, doc: "trailing actions column, `:let` receives the row"
  slot :toolbar, doc: "custom toolbar content rendered above the table"
  slot :empty, doc: "custom empty state; a filters-aware default renders otherwise"

  def data_table(assigns) do
    if is_nil(assigns.path) and is_nil(assigns.on_change) do
      raise ArgumentError, "data_table needs either path (link mode) or on_change (event mode)"
    end

    {sort_by, sort_dir} =
      case assigns.state.order_by do
        [{field, dir} | _] -> {to_string(field), to_string(dir)}
        [] -> {nil, "asc"}
      end

    fields = Map.new(assigns.col, fn col -> {to_string(col.field), col.field} end)

    assigns =
      assigns
      |> assign(:sort_by, sort_by)
      |> assign(:sort_dir, sort_dir)
      |> assign(:on_sort, sort_handler(assigns, fields))
      |> assign(:skeleton_rows, List.duplicate(%{}, min(assigns.state.page_size, 10)))

    ~H"""
    <div id={@id} class={["pc-data-table", @class]}>
      <div :if={@toolbar != []} class="pc-data-table__toolbar">
        {render_slot(@toolbar)}
      </div>

      <div class="pc-data-table__scroll">
        <.table
          id={"#{@id}-table"}
          rows={if @loading, do: @skeleton_rows, else: @rows}
          density={@density}
          striped={@striped}
          sticky_header={@sticky_header}
          variant={@variant}
          sort_by={@sort_by}
          sort_dir={@sort_dir}
          on_sort={@on_sort}
        >
          <:col
            :let={row}
            :for={col <- @col}
            label={col[:label] || humanize(col.field)}
            sortable={col[:sortable] || false}
            sort_key={to_string(col.field)}
            class={[col[:class], align_class(col[:align])]}
            row_class={align_class(col[:align])}
          >
            <%= if @loading do %>
              <.skeleton variant="text" class="pc-data-table__skeleton" />
            <% else %>
              {render_slot(col, row)}
            <% end %>
          </:col>
          <:col :let={row} :if={@action != []} label="" class="pc-data-table__actions-th">
            <span :if={!@loading} class="pc-data-table__actions">
              {render_slot(@action, row)}
            </span>
          </:col>
          <:empty_state :if={!@loading}>
            <%= if @empty != [] do %>
              {render_slot(@empty)}
            <% else %>
              <div class="pc-data-table__empty">
                <%= if @state.filters == [] do %>
                  {@no_results_text}
                <% else %>
                  <span>{@no_filtered_results_text}</span>
                  <.link
                    :if={@path}
                    patch={url_for(@path, State.clear_filters(@state))}
                    class="pc-data-table__clear-filters"
                  >
                    {@clear_filters_label}
                  </.link>
                  <button
                    :if={@on_change}
                    type="button"
                    class="pc-data-table__clear-filters"
                    phx-click={@on_change}
                    phx-target={@target}
                    phx-value-op="clear_filters"
                  >
                    {@clear_filters_label}
                  </button>
                <% end %>
              </div>
            <% end %>
          </:empty_state>
        </.table>
      </div>

      <div class="pc-data-table__footer">
        <span class="pc-data-table__range">{range_text(@state, @of_label, @page_label)}</span>
        <.pagination
          :if={show_pagination?(@state)}
          variant={if @state.total, do: "numbered", else: "simple"}
          total_pages={State.total_pages(@state) || cursor_total(@state)}
          current_page={@state.page}
          path={@path && page_path_template(@path, @state)}
          link_type="live_patch"
          event={@on_change || false}
          event_values={%{"op" => "page"}}
          target={@target}
        />
      </div>
    </div>
    """
  end

  # -- wiring ----------------------------------------------------------------

  # link mode patches per-column sort URLs; event mode pushes the op
  # grammar. Both ride the table's function-valued on_sort.
  defp sort_handler(%{on_change: nil} = assigns, fields) do
    %{path: path, state: state} = assigns

    fn key ->
      case Map.fetch(fields, key) do
        {:ok, field} -> JS.patch(url_for(path, State.toggle_sort(state, field)))
        :error -> nil
      end
    end
  end

  defp sort_handler(%{on_change: event, target: target}, _fields) do
    opts = [value: %{"op" => "sort"}] ++ if(target, do: [target: target], else: [])

    fn key ->
      JS.push(event, Keyword.put(opts, :value, %{"op" => "sort", "field" => key}))
    end
  end

  defp url_for(path, %State{} = state) do
    query = state |> State.to_params() |> flatten_params() |> URI.encode_query()
    if query == "", do: path, else: path <> "?" <> query
  end

  # pagination's :page placeholder must survive URL encoding, so the
  # template is assembled around the already-encoded rest of the query
  defp page_path_template(path, %State{} = state) do
    query =
      state
      |> State.to_params()
      |> Map.delete("page")
      |> flatten_params()
      |> URI.encode_query()

    if query == "" do
      path <> "?page=:page"
    else
      path <> "?page=:page&" <> query
    end
  end

  # filters encode as a list of maps - flatten to Phoenix-style indexed
  # params so encode_query can carry them and from_params reads them back
  defp flatten_params(params) do
    case Map.pop(params, "filters") do
      {nil, rest} ->
        rest

      {filters, rest} ->
        filters
        |> Enum.with_index()
        |> Enum.reduce(rest, fn {filter, i}, acc ->
          Enum.reduce(filter, acc, fn {k, v}, acc2 ->
            Map.put(acc2, "filters[#{i}][#{k}]", v)
          end)
        end)
    end
  end

  defp range_text(%State{total: nil} = state, _of_label, page_label),
    do: "#{page_label} #{state.page}"

  defp range_text(%State{total: 0}, _of_label, _page_label), do: nil

  defp range_text(%State{} = state, of_label, _page_label) do
    first = (state.page - 1) * state.page_size + 1
    last = min(state.page * state.page_size, state.total)
    "#{first}–#{last} #{of_label} #{state.total}"
  end

  defp show_pagination?(%State{total: nil}), do: true
  defp show_pagination?(%State{} = state), do: State.total_pages(state) > 1

  # simple variant in cursor mode: enable Next unconditionally by
  # reporting one page more than the current
  defp cursor_total(%State{page: page}), do: page + 1

  defp align_class("right"), do: "pc-data-table__cell--right"
  defp align_class("center"), do: "pc-data-table__cell--center"
  defp align_class(_), do: nil

  defp humanize(field) do
    field |> to_string() |> String.replace("_", " ") |> String.capitalize()
  end
end
