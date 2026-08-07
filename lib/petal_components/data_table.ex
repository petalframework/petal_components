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
      `%{"op" => "page", "page" => n}`, quick-search as
      `%{"op" => "search", "term" => t}`, page-size changes as
      `%{"op" => "page_size", "page_size" => n}`, filter edits as
      `%{"op" => "filter", "field" => f, ...editor inputs}`, filter
      clears as `%{"op" => "clear_filters"}`. `State.handle_op/3`
      speaks the whole grammar, so the handler is a one-liner.

  In link mode the quick-search input and rows-per-page select are wired
  by the `PetalDataTable` hook (patch URLs built from templates the
  component renders); event mode needs no JS.

  Selection (`selectable`) is UI state, not query state - it rides an
  event in BOTH wiring modes (`on_ui`, defaulting to `on_change`) and
  never touches URLs. Its ops sit outside `State`: `select` (id),
  `select_all`, `clear_selection` - a MapSet plus three clauses is the
  whole backend. Selection is keyed by `row_id`, which must uniquely
  identify a record across the whole dataset, not just the current
  page (primary keys qualify, display fields do not) - a selection
  retained while paging is only as sound as this key. Same-page
  duplicates raise; cross-page uniqueness is the caller's contract,
  exactly as with LiveView stream ids.

  Rows can be any enumerable of maps/structs; pair with
  `PetalComponents.DataTable.Engine.List` for zero-setup in-memory
  data, or run the state against your own query layer.
  """
  use Phoenix.Component

  import PetalComponents.Button
  import PetalComponents.Icon
  import PetalComponents.Pagination
  import PetalComponents.Popover
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

  attr :searchable, :boolean,
    default: false,
    doc: "render the quick-search input in the toolbar (drives `state.search`)"

  attr :search_placeholder, :string, default: "Search…"

  attr :search_debounce, :integer,
    default: 300,
    doc: "quick-search debounce in ms, both wiring modes"

  attr :page_size_options, :list,
    default: [],
    doc: "when non-empty, render a rows-per-page select in the footer"

  attr :per_page_label, :string, default: "Per page", doc: "the rows-per-page label, localizable"
  attr :reset_filters_label, :string, default: "Reset filters"

  attr :apply_label, :string,
    default: "Apply",
    doc: "the filter editors' submit label, localizable"

  attr :selectable, :boolean, default: false, doc: "render a leading checkbox column"

  attr :selected, :list,
    default: [],
    doc: "the currently selected row ids (any terms; compared as strings)"

  attr :row_id, :any,
    default: :id,
    doc: """
    row identity for selection: a field (atom) or a 1-arity function of
    the row. The key must uniquely identify a record across ALL pages,
    not just the visible one - a selection retained while paging is only
    as sound as this key. Same-page duplicates raise.
    """

  attr :on_ui, :string,
    default: nil,
    doc: """
    the event UI-state ops (selection) push, both wiring modes. Defaults
    to `on_change`; required alongside `selectable` in link mode.
    """

  attr :selected_label, :string,
    default: "selected",
    doc: "the selection count's word, localizable"

  attr :clear_selection_label, :string, default: "Clear selection"

  attr :select_all_label, :string,
    default: "Select all rows",
    doc: "the header checkbox's aria-label"

  attr :column_toggle, :boolean,
    default: false,
    doc: "render a columns-visibility dropdown in the toolbar (rides the `on_ui` event)"

  attr :hidden_columns, :list,
    default: [],
    doc: "fields currently hidden (atoms or strings) - presentation state, never in URLs"

  attr :column_toggle_label, :string, default: "Columns"

  attr :filter_op_labels, :map,
    default: %{},
    doc: "overrides for the operator display names, e.g. %{contains: \"enthält\"}"

  attr :class, :any, default: nil

  slot :col, required: true do
    attr :field, :atom, required: true
    attr :label, :string
    attr :sortable, :boolean

    attr :filterable, :string,
      values: ["text", "number", "select", "date"],
      doc: "render a typed filter button + popover editor for this column"

    attr :options, :list,
      doc: "select filters: the pickable values, as strings or {label, value} tuples"

    attr :align, :string, values: ["left", "center", "right"]
    attr :class, :any
  end

  slot :action, doc: "trailing actions column, `:let` receives the row"

  slot :bulk_action,
    doc: "toolbar content while rows are selected; `:let` receives the selected ids"

  slot :toolbar, doc: "custom toolbar content rendered above the table"
  slot :empty, doc: "custom empty state; a filters-aware default renders otherwise"

  def data_table(assigns) do
    if is_nil(assigns.path) and is_nil(assigns.on_change) do
      raise ArgumentError, "data_table needs either path (link mode) or on_change (event mode)"
    end

    ui_event = assigns.on_ui || assigns.on_change

    if assigns.selectable and is_nil(ui_event) do
      raise ArgumentError,
            "selectable needs an event for selection ops - pass on_ui (link mode) or on_change"
    end

    if assigns.column_toggle and is_nil(ui_event) do
      raise ArgumentError,
            "column_toggle needs an event for its ops - pass on_ui (link mode) or on_change"
    end

    {sort_by, sort_dir} =
      case assigns.state.order_by do
        [{field, dir} | _] -> {to_string(field), to_string(dir)}
        [] -> {nil, "asc"}
      end

    fields = Map.new(assigns.col, fn col -> {to_string(col.field), col.field} end)

    hidden = Enum.map(assigns.hidden_columns, &to_string/1)
    visible_cols = Enum.reject(assigns.col, &(to_string(&1.field) in hidden))

    # the UI can't reach all-hidden (the last checkbox disables), but a
    # hand-built hidden_columns can - enforce the invariant here too by
    # keeping the first declared column
    {visible_cols, hidden} =
      case {visible_cols, assigns.col} do
        {[], [first | _]} -> {[first], hidden -- [to_string(first.field)]}
        _ -> {visible_cols, hidden}
      end

    filter_cols = Enum.filter(assigns.col, & &1[:filterable])

    link_mode? = is_nil(assigns.on_change)

    # link mode: URL wiring. Either mode: filter popovers are native
    # top-layer popovers the hook closes after an Apply, and selection's
    # tri-state header checkbox needs its indeterminate property set.
    hooked? =
      (link_mode? and (assigns.searchable or assigns.page_size_options != [])) or
        filter_cols != [] or assigns.selectable

    assigns =
      assigns
      |> assign(:sort_by, sort_by)
      |> assign(:sort_dir, sort_dir)
      |> assign(:on_sort, sort_handler(assigns, fields))
      |> assign(:skeleton_rows, List.duplicate(%{}, min(assigns.state.page_size, 10)))
      |> assign(:filter_cols, filter_cols)
      |> assign(:visible_cols, visible_cols)
      |> assign(:hidden, hidden)
      |> assign(:op_labels, Map.merge(default_op_labels(), assigns.filter_op_labels))
      |> assign(:ui_event, ui_event)
      |> selection_assigns()
      |> assign(:hooked?, hooked?)
      |> assign(
        :nav_template,
        link_mode? && hooked? && nav_template(assigns.path, assigns.state, assigns, filter_cols)
      )
      |> assign(
        :filters_json,
        link_mode? && filter_cols != [] && Jason.encode!(assigns.state.filters)
      )

    ~H"""
    <div
      id={@id}
      class={["pc-data-table", @class]}
      phx-hook={@hooked? && "PetalDataTable"}
      data-debounce={@hooked? && @search_debounce}
      data-nav-template={@nav_template || nil}
      data-filters={@filters_json || nil}
    >
      <a :if={@hooked?} data-pc-dt-nav data-phx-link="patch" data-phx-link-state="push" hidden></a>
      <div
        :if={
          @toolbar != [] or @searchable or @filter_cols != [] or @state.filters != [] or
            @selected_ids != [] or @column_toggle
        }
        class="pc-data-table__toolbar"
      >
        <%= if @selected_ids != [] do %>
          <span class="pc-data-table__selection-count">
            {length(@selected_ids)} {@selected_label}
          </span>
          {render_slot(@bulk_action, @selected_ids)}
          <.button
            type="button"
            size="sm"
            variant="ghost"
            color="gray"
            class="pc-data-table__reset"
            phx-click={@ui_event}
            phx-target={@target}
            phx-value-op="clear_selection"
          >
            {@clear_selection_label}
          </.button>
        <% else %>
          <div :if={@searchable} class="pc-data-table__search">
            <.icon name="hero-magnifying-glass" class="pc-data-table__search-icon" />
            <%= if @on_change do %>
              <form phx-change={@on_change} phx-submit={@on_change} phx-target={@target}>
                <input type="hidden" name="op" value="search" />
                <input
                  type="text"
                  name="term"
                  value={@state.search}
                  placeholder={@search_placeholder}
                  phx-debounce={@search_debounce}
                  autocomplete="off"
                  class="pc-text-input pc-data-table__search-input"
                />
              </form>
            <% else %>
              <input
                type="text"
                value={@state.search}
                placeholder={@search_placeholder}
                autocomplete="off"
                data-pc-dt-search
                class="pc-text-input pc-data-table__search-input"
              />
            <% end %>
          </div>
          <.filter_button
            :for={col <- @filter_cols}
            col={col}
            table_id={@id}
            state={@state}
            path={@path}
            on_change={@on_change}
            target={@target}
            op_labels={@op_labels}
            apply_label={@apply_label}
          />
          {render_slot(@toolbar)}
          <.popover
            :if={@column_toggle}
            id={"#{@id}-columns"}
            top_layer
            placement="bottom-end"
            class="pc-data-table__columns"
            trigger_class="pc-button pc-button--sm pc-button--gray-outline"
          >
            <:trigger>
              <.icon name="hero-view-columns" class="pc-data-table__filter-icon" />
              <span>{@column_toggle_label}</span>
            </:trigger>
            <div class="pc-data-table__filter-options" role="group" aria-label={@column_toggle_label}>
              <label :for={col <- @col} class="pc-data-table__filter-option">
                <input
                  type="checkbox"
                  class="pc-checkbox"
                  checked={to_string(col.field) not in @hidden}
                  disabled={length(@visible_cols) == 1 and to_string(col.field) not in @hidden}
                  phx-click={@ui_event}
                  phx-target={@target}
                  phx-value-op="toggle_column"
                  phx-value-field={col.field}
                />
                <span>{col[:label] || humanize(col.field)}</span>
              </label>
            </div>
          </.popover>
          <%= if @state.filters != [] do %>
            <.button
              :if={@on_change}
              type="button"
              size="sm"
              variant="ghost"
              color="gray"
              class="pc-data-table__reset"
              phx-click={@on_change}
              phx-target={@target}
              phx-value-op="clear_filters"
            >
              {@reset_filters_label}
            </.button>
            <.button
              :if={@path}
              link_type="live_patch"
              to={url_for(@path, State.clear_filters(@state))}
              size="sm"
              variant="ghost"
              color="gray"
              class="pc-data-table__reset"
            >
              {@reset_filters_label}
            </.button>
          <% end %>
        <% end %>
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
            :if={@selectable}
            label={header_checkbox(assigns)}
            class="pc-data-table__select-col"
            row_class="pc-data-table__select-col"
          >
            <input
              :if={!@loading}
              type="checkbox"
              class="pc-checkbox"
              checked={row_key(row, @row_id) in @selected_set}
              disabled={row_key(row, @row_id) == ""}
              phx-click={@ui_event}
              phx-target={@target}
              phx-value-op="select"
              phx-value-id={row_key(row, @row_id)}
              aria-label={"Select row #{row_key(row, @row_id)}"}
            />
          </:col>
          <:col
            :let={row}
            :for={col <- @visible_cols}
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
        <div :if={@page_size_options != []} class="pc-data-table__page-size">
          <label for={"#{@id}-page-size"} class="pc-data-table__page-size-label">
            {@per_page_label}
          </label>
          <%= if @on_change do %>
            <form phx-change={@on_change} phx-target={@target}>
              <input type="hidden" name="op" value="page_size" />
              <select
                id={"#{@id}-page-size"}
                name="page_size"
                class="pc-select pc-data-table__page-size-select"
              >
                <option :for={n <- @page_size_options} value={n} selected={n == @state.page_size}>
                  {n}
                </option>
              </select>
            </form>
          <% else %>
            <select
              id={"#{@id}-page-size"}
              data-pc-dt-page-size
              class="pc-select pc-data-table__page-size-select"
            >
              <option :for={n <- @page_size_options} value={n} selected={n == @state.page_size}>
                {n}
              </option>
            </select>
          <% end %>
        </div>
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
    join_query(path, query)
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

    join_query(path, if(query == "", do: "page=:page", else: "page=:page&" <> query))
  end

  # One template, both placeholders: the hook fills :term / :page_size
  # from the live DOM at patch time, so an uncommitted search term and a
  # fresh page-size pick can never revert each other. Placeholders are
  # assembled around the already-encoded rest of the query (the
  # pagination :page trick); a control the table doesn't render keeps
  # its committed value in the rest instead of a placeholder.
  defp nav_template(path, state, assigns, filter_cols) do
    state = %{state | page: 1}
    state = if assigns.searchable, do: State.put_search(state, ""), else: state
    state = if filter_cols != [], do: %{state | filters: []}, else: state

    params = State.to_params(state)

    params =
      if assigns.page_size_options != [], do: Map.delete(params, "page_size"), else: params

    placeholders =
      Enum.filter(
        [
          assigns.searchable && "search=:term",
          assigns.page_size_options != [] && "page_size=:page_size",
          filter_cols != [] && ":filters"
        ],
        & &1
      )

    rest = params |> flatten_params() |> URI.encode_query()
    query = Enum.join(placeholders ++ if(rest == "", do: [], else: [rest]), "&")
    join_query(path, query)
  end

  # a base path may already carry a query string - join accordingly
  defp join_query(path, ""), do: path

  defp join_query(path, query) do
    joiner = if String.contains?(path, "?"), do: "&", else: "?"
    path <> joiner <> query
  end

  # filters encode as a list of maps - flatten to Phoenix-style indexed
  # params so encode_query can carry them and from_params reads them
  # back. Returns pairs, not a map: a list value (the :in op) needs the
  # same key repeated ("...[value][]"), which a map cannot hold.
  defp flatten_params(params) do
    {filters, rest} = Map.pop(params, "filters")

    Enum.sort(rest) ++
      (filters
       |> List.wrap()
       |> Enum.with_index()
       |> Enum.flat_map(fn {filter, i} ->
         Enum.flat_map(filter, fn {k, v} -> filter_pairs("filters[#{i}][#{k}]", v) end)
       end))
  end

  defp filter_pairs(key, values) when is_list(values),
    do: Enum.map(values, &{"#{key}[]", &1})

  defp filter_pairs(key, %{} = map),
    do: Enum.map(map, fn {k, v} -> {"#{key}[#{k}]", v} end)

  defp filter_pairs(key, value), do: [{key, value}]

  # -- selection -------------------------------------------------------------

  defp selection_assigns(%{selectable: false} = assigns) do
    assign(assigns,
      selected_ids: [],
      selected_set: MapSet.new(),
      all_selected?: false,
      some_selected?: false
    )
  end

  defp selection_assigns(assigns) do
    # normalize ONCE and use everywhere - checkboxes, the toolbar count
    # and the :bulk_action ids must never disagree about what is selected
    selected_ids =
      assigns.selected |> Enum.map(&to_string/1) |> Enum.reject(&(&1 == "")) |> Enum.uniq()

    selected_set = MapSet.new(selected_ids)

    page_keys =
      if assigns.loading,
        do: [],
        else: assigns.rows |> Enum.map(&row_key(&1, assigns.row_id)) |> Enum.reject(&(&1 == ""))

    # two rows sharing a key means one checkbox would select both - that
    # is a misconfigured row_id, not a state to render through
    if length(Enum.uniq(page_keys)) != length(page_keys) do
      raise ArgumentError,
            "data_table selection found duplicate row ids on this page - " <>
              "pass a row_id (field or function) that uniquely identifies each row"
    end

    picked = Enum.count(page_keys, &MapSet.member?(selected_set, &1))

    assign(assigns,
      selected_ids: selected_ids,
      selected_set: selected_set,
      all_selected?: page_keys != [] and picked == length(page_keys),
      some_selected?: picked > 0
    )
  end

  # rendered as the checkbox column's header via the table's label
  # (which accepts any rendered fragment). indeterminate is a DOM
  # property, not an attribute - the hook mirrors the data attr onto it.
  defp header_checkbox(assigns) do
    ~H"""
    <input
      type="checkbox"
      class="pc-checkbox"
      checked={@all_selected?}
      disabled={@loading}
      data-pc-dt-indeterminate={to_string(@some_selected? and not @all_selected?)}
      phx-click={@ui_event}
      phx-target={@target}
      phx-value-op="select_all"
      aria-label={@select_all_label}
    />
    """
  end

  defp row_key(row, fun) when is_function(fun, 1), do: to_string(fun.(row))
  defp row_key(row, field) when is_atom(field), do: to_string(Map.get(row, field))

  # -- filters ---------------------------------------------------------------

  @text_ops ~w(contains eq starts_with)a
  @number_ops ~w(eq neq gt lt between)a
  @date_ops ~w(before on after)a

  defp default_op_labels do
    %{
      contains: "contains",
      eq: "is",
      starts_with: "starts with",
      neq: "is not",
      gt: ">",
      lt: "<",
      between: "between",
      in: "is any of",
      before: "before",
      on: "on",
      after: "after"
    }
  end

  defp filter_button(assigns) do
    col = assigns.col
    field_str = to_string(col.field)
    label = col[:label] || humanize(col.field)
    filter = Enum.find(assigns.state.filters, &(&1.field == col.field))
    options = normalize_options(col[:options] || [])
    pop_id = "#{assigns.table_id}-filter-#{field_str}"

    assigns =
      assigns
      |> assign(:field_str, field_str)
      |> assign(:label, label)
      |> assign(:filter, filter)
      |> assign(:options, options)
      |> assign(:pop_id, pop_id)
      |> assign(:type, col[:filterable])
      |> assign(:submit_js, filter_submit_js(assigns.on_change, assigns.target, pop_id))
      |> assign(
        :clear_url,
        assigns.path && url_for(assigns.path, State.put_filter(assigns.state, col.field, :eq, ""))
      )

    ~H"""
    <div class="pc-data-table__filter">
      <.popover
        id={@pop_id}
        top_layer
        placement="bottom-start"
        class="pc-data-table__filter-popover"
        trigger_class={[
          "pc-button pc-button--sm",
          (@filter && "pc-button--primary-soft pc-data-table__filter-trigger--active") ||
            "pc-button--gray-outline"
        ]}
      >
        <:trigger>
          <.icon :if={!@filter} name="hero-funnel" class="pc-data-table__filter-icon" />
          <span>{(@filter && predicate_text(@label, @filter, @op_labels, @options)) || @label}</span>
        </:trigger>
        <form
          class={["pc-data-table__filter-form", "pc-data-table__filter-form--#{@type}"]}
          phx-submit={@submit_js}
          data-pc-dt-filter={is_nil(@on_change) || nil}
          data-field={@field_str}
        >
          <input :if={@on_change} type="hidden" name="op" value="filter" />
          <input :if={@on_change} type="hidden" name="field" value={@field_str} />
          <.filter_editor
            type={@type}
            filter={@filter}
            options={@options}
            op_labels={@op_labels}
            label={@label}
          />
          <.button size="sm" type="submit" class="pc-data-table__filter-apply">
            {@apply_label}
          </.button>
        </form>
      </.popover>
      <%= if @filter do %>
        <.link
          :if={@path}
          patch={@clear_url}
          class="pc-data-table__filter-clear"
          aria-label={"Clear #{@label} filter"}
        >
          <.icon name="hero-x-mark" class="pc-data-table__filter-clear-icon" />
        </.link>
        <button
          :if={@on_change}
          type="button"
          class="pc-data-table__filter-clear"
          phx-click={@on_change}
          phx-target={@target}
          phx-value-op="filter"
          phx-value-field={@field_str}
          aria-label={"Clear #{@label} filter"}
        >
          <.icon name="hero-x-mark" class="pc-data-table__filter-clear-icon" />
        </button>
      <% end %>
    </div>
    """
  end

  defp filter_editor(%{type: "select"} = assigns) do
    current = assigns.filter |> current_values() |> Enum.map(&to_string/1)
    assigns = assign(assigns, :current, current)

    ~H"""
    <div class="pc-data-table__filter-options" role="group" aria-label={"#{@label} options"}>
      <label :for={{label, value} <- @options} class="pc-data-table__filter-option">
        <input
          type="checkbox"
          name="values[]"
          value={value}
          checked={to_string(value) in @current}
          class="pc-checkbox"
        />
        <span>{label}</span>
      </label>
    </div>
    """
  end

  defp filter_editor(%{type: "number"} = assigns) do
    {value, value2} = current_pair(assigns.filter)

    assigns =
      assigns
      |> assign(:ops, @number_ops)
      |> assign(:current_op, (assigns.filter && assigns.filter.op) || :eq)
      |> assign(:value, value)
      |> assign(:value2, value2)

    ~H"""
    <.filter_op_select ops={@ops} current_op={@current_op} op_labels={@op_labels} label={@label} />
    <input
      type="number"
      step="any"
      name="value"
      value={@value}
      class="pc-text-input pc-data-table__filter-value"
    />
    <input
      type="number"
      step="any"
      name="value2"
      value={@value2}
      class="pc-text-input pc-data-table__filter-value pc-data-table__filter-value2"
      aria-label={"#{@label} upper bound"}
    />
    """
  end

  defp filter_editor(%{type: "date"} = assigns) do
    assigns =
      assigns
      |> assign(:ops, @date_ops)
      |> assign(:current_op, (assigns.filter && assigns.filter.op) || :on)
      |> assign(:value, (assigns.filter && to_string(assigns.filter.value)) || nil)

    ~H"""
    <.filter_op_select ops={@ops} current_op={@current_op} op_labels={@op_labels} label={@label} />
    <input
      type="date"
      name="value"
      value={@value}
      class="pc-text-input pc-data-table__filter-value"
    />
    """
  end

  defp filter_editor(assigns) do
    assigns =
      assigns
      |> assign(:ops, @text_ops)
      |> assign(:current_op, (assigns.filter && assigns.filter.op) || :contains)
      |> assign(:value, (assigns.filter && to_string(assigns.filter.value)) || nil)

    ~H"""
    <.filter_op_select ops={@ops} current_op={@current_op} op_labels={@op_labels} label={@label} />
    <input
      type="text"
      name="value"
      value={@value}
      class="pc-text-input pc-data-table__filter-value"
    />
    """
  end

  defp filter_op_select(assigns) do
    ~H"""
    <select
      name="filter_op"
      class="pc-select pc-data-table__filter-op"
      aria-label={"#{@label} operator"}
    >
      <option :for={op <- @ops} value={op} selected={op == @current_op}>
        {Map.fetch!(@op_labels, op)}
      </option>
    </select>
    """
  end

  # event mode pushes the form; the hook closes the native popover on
  # submit (a top-layer panel needs hidePopover(), not a display toggle)
  defp filter_submit_js(nil, _target, _pop_id), do: nil

  defp filter_submit_js(event, target, _pop_id) do
    if target, do: JS.push(event, target: target), else: JS.push(event)
  end

  defp normalize_options(options) do
    Enum.map(options, fn
      {label, value} -> {label, value}
      value -> {humanize(value), value}
    end)
  end

  defp current_values(nil), do: []
  defp current_values(%{value: value}), do: List.wrap(value)

  # the engine accepts both range shapes, so both must render
  defp current_pair(%{op: :between, value: [min, max]}), do: {min, max}
  defp current_pair(%{op: :between, value: %{"min" => min, "max" => max}}), do: {min, max}
  defp current_pair(%{op: :between}), do: {nil, nil}
  defp current_pair(%{value: value}) when not is_list(value), do: {value, nil}
  defp current_pair(_other), do: {nil, nil}

  defp predicate_text(label, filter, op_labels, options) do
    "#{label} #{Map.fetch!(op_labels, filter.op)} #{display_value(filter, options)}"
  end

  defp display_value(%{op: :in, value: values}, options) do
    labels = Map.new(options, fn {label, value} -> {to_string(value), label} end)
    shown = values |> List.wrap() |> Enum.map(&Map.get(labels, to_string(&1), to_string(&1)))

    case Enum.split(shown, 2) do
      {first_two, []} -> Enum.join(first_two, ", ")
      {first_two, rest} -> Enum.join(first_two, ", ") <> " +#{length(rest)}"
    end
  end

  defp display_value(%{op: :between, value: [min, max]}, _options), do: "#{min}\u2013#{max}"

  defp display_value(%{op: :between, value: %{"min" => min, "max" => max}}, _options),
    do: "#{min}\u2013#{max}"

  # hand-built states can carry shapes no editor produces - never crash
  # the toolbar over one
  defp display_value(%{value: value}, _options) when is_list(value),
    do: Enum.map_join(value, ", ", &to_string/1)

  defp display_value(%{value: %{} = value}, _options), do: inspect(value)
  defp display_value(%{value: value}, _options), do: to_string(value)

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
