defmodule PetalComponents.Filters do
  @moduledoc """
  A schema-driven filter bar: the active filters as removable chips, plus an
  "Add filter" popover that walks field -> operator -> value.

  It speaks `PetalComponents.DataTable.State`, the same struct `<.data_table>`
  is driven by, so it drops in next to a table sharing one state - or stands
  alone above any list, card grid or custom query UI. The operator vocabulary
  is `State.ops/0`; this component only ever selects subsets of it, and every
  mutation goes through `State.put_filter/4` or `State.handle_op/3`.

  Two wiring modes, inferred from which attr you pass (passing neither raises,
  exactly like `data_table/1`):

    * **link mode** (`path`) - every change is a `patch` URL built from
      `State.to_params/1`. `handle_params` plus `State.from_params/2` is the
      whole backend, and the URL is the state store:

          def handle_params(params, _uri, socket) do
            state = State.from_params(params, fields: [:name, :category, :price])
            {rows, state} = Engine.List.run(all_products(), state)
            {:noreply, assign(socket, rows: rows, table: state)}
          end

          <.filters id="f" state={@table} path={~p"/products"}>
            <:field field={:name} label="Name" type="text" />
            <:field field={:category} type="select" options={["tools", "toys"]} />
            <:field field={:price} label="Price" type="number_range" />
          </.filters>

    * **event mode** (`on_change`) - chip removal, apply and clear-all push the
      op-shaped payloads `State.handle_op/3` already parses, so a LiveView
      already wired for an event-mode `data_table` gains a filter bar without a
      single new handler clause:

          def handle_event("table", params, socket) do
            state = State.handle_op(socket.assigns.table, params, fields: [:name, :category])
            {rows, state} = Engine.List.run(all_products(), state)
            {:noreply, assign(socket, rows: rows, table: state)}
          end

          <.filters id="f" state={@table} on_change="table">
            <:field field={:name} label="Name" type="text" />
            <:field field={:category} type="select" options={["tools", "toys"]} />
          </.filters>

  ## Sharing one State with a data table

  Point both at the same struct and the same event (or the same path) and they
  compose with no glue: filter from the bar and the table updates, filter from
  a column header and a chip appears.

      <.filters id="products-filters" state={@table} on_change="table">
        <:field field={:category} type="select" options={["tools", "toys"]} />
        <:field field={:in_stock} label="In stock" type="boolean" />
      </.filters>

      <.data_table id="products" rows={@rows} state={@table} on_change="table">
        <:col :let={p} field={:name} sortable>{p.name}</:col>
        <:col :let={p} field={:category} filterable="select" options={["tools", "toys"]}>
          {p.category}
        </:col>
      </.data_table>

  ## Field types

  The `:field` slot is the registry. `type` picks the operator subset (always a
  subset of `State.ops/0`) and the value editor:

  | type | operators | editor |
  |---|---|---|
  | `text` | `contains`, `not_contains`, `eq`, `neq`, `starts_with`, `is_empty`, `is_not_empty` | text input |
  | `select` | `eq`, `neq`, `is_empty`, `is_not_empty` | single select from `options` |
  | `multi` | `in` | checkbox list from `options` |
  | `number_range` | `eq`, `neq`, `gt`, `gte`, `lt`, `lte`, `between`, `is_empty`, `is_not_empty` | number input, two for `between` |
  | `date_range` | `before`, `on`, `after`, `between`, `is_empty`, `is_not_empty` | date input, two for `between` |
  | `boolean` | `eq` | yes/no select, no operator picker |

  Valueless operators (`is_empty`, `is_not_empty`) render no value input, per
  `State.valueless_op?/1`.
  """
  use Phoenix.Component

  import PetalComponents.Button
  import PetalComponents.Icon

  alias PetalComponents.DataTable.FilterEditor
  alias PetalComponents.DataTable.State
  alias Phoenix.LiveView.JS

  # {editor shape, operator subset, preselected operator}. Every atom here is
  # a member of State.ops/0 - a test asserts it, so a vocabulary change fails
  # loudly rather than rendering an operator no engine can execute.
  @types %{
    "text" =>
      {"text", ~w(contains not_contains eq neq starts_with is_empty is_not_empty)a, :contains},
    "select" => {"choice", ~w(eq neq is_empty is_not_empty)a, :eq},
    "multi" => {"options", ~w(in)a, :in},
    "number_range" => {"number", ~w(eq neq gt gte lt lte between is_empty is_not_empty)a, :eq},
    "date_range" => {"date", ~w(before on after between is_empty is_not_empty)a, :on},
    "boolean" => {"boolean", ~w(eq)a, :eq}
  }

  @doc """
  The operator subset offered per registry type, as `%{type => [op]}`.

  Exposed so an app (and this library's own test suite) can assert the
  vocabulary against `State.ops/0` rather than trusting a hand-copied list.
  """
  @spec type_operators() :: %{String.t() => [atom()]}
  def type_operators, do: Map.new(@types, fn {type, {_shape, ops, _default}} -> {type, ops} end)

  attr :id, :string, required: true, doc: "DOM id; every panel and chip id is derived from it"

  attr :state, State,
    required: true,
    doc: "the state whose `filters` this bar renders and edits"

  attr :path, :string,
    default: nil,
    doc: """
    link mode: the base path filter changes patch to, with the state encoded
    via `State.to_params/1`. Required unless `on_change` is set.
    """

  attr :on_change, :string,
    default: nil,
    doc: """
    event mode: the event filter edits push, with the same op-shaped payloads
    `State.handle_op/3` already accepts (`filter` / `clear_filters`).
    """

  attr :target, :any, default: nil, doc: "event mode: the phx-target (e.g. @myself)"

  attr :add_filter_label, :string,
    default: "Add filter",
    doc: "the add trigger's label and its panel's accessible name, localizable"

  attr :clear_filters_label, :string,
    default: "Clear filters",
    doc: "the clear-all affordance's label, localizable"

  attr :apply_label, :string,
    default: "Apply",
    doc: "the value editor's submit label, localizable"

  attr :remove_filter_label, :string,
    default: "Remove filter",
    doc: "prefix for a chip's remove button accessible name, localizable"

  attr :active_filters_label, :string,
    default: "Active filters",
    doc: "the chip group's accessible name, localizable"

  attr :no_filters_label, :string,
    default: "No filters applied",
    doc: "announced by the status region when nothing is filtered, localizable"

  attr :all_fields_used_label, :string,
    default: "Every field is already filtered",
    doc: "shown in the add panel when no field is left to add, localizable"

  attr :filter_op_labels, :map,
    default: %{},
    doc:
      ~S|overrides for operator display names, e.g. %{contains: "enthält"} - same attr name and shape as data_table|

  attr :filter_options_placeholder, :string,
    default: "Filter options…",
    doc: "the multi editor's option-filter placeholder (shown from 8 options up), localizable"

  attr :class, :any, default: nil, doc: "extra classes on the bar's root element"

  slot :field, required: true, doc: "the filterable field registry, one entry per field" do
    attr :field, :atom, required: true, doc: "the state field this entry filters"
    attr :label, :string, doc: "human name; defaults to the humanized field"

    attr :type, :string,
      values: ["text", "select", "multi", "date_range", "boolean", "number_range"],
      doc: "picks the operator subset and the value editor; defaults to \"text\""

    attr :options, :list,
      doc:
        ~S|select/multi: the pickable values, as strings or {label, value} tuples - same shape as data_table's :col options|
  end

  @doc """
  Renders the filter bar for `state`, with one `:field` entry per filterable
  field. Pass `path` for link mode or `on_change` for event mode.
  """
  def filters(assigns) do
    if is_nil(assigns.path) and is_nil(assigns.on_change) do
      raise ArgumentError, "filters needs either path (link mode) or on_change (event mode)"
    end

    link_mode? = is_nil(assigns.on_change)
    op_labels = Map.merge(FilterEditor.default_op_labels(), assigns.filter_op_labels)
    registry = Enum.map(assigns.field, &entry(&1, assigns.id))

    active =
      Enum.flat_map(assigns.state.filters, fn filter ->
        case Enum.find(registry, &(&1.field == filter.field)) do
          nil -> []
          entry -> [Map.put(entry, :filter, filter)]
        end
      end)

    available =
      Enum.reject(registry, fn entry -> Enum.any?(active, &(&1.field == entry.field)) end)

    assigns =
      assigns
      |> assign(:link_mode?, link_mode?)
      |> assign(:op_labels, op_labels)
      |> assign(:chips, chips(active, assigns.id))
      |> assign(:available, Enum.map(available, &Map.put(&1, :filter, nil)))
      |> assign(:status_text, status_text(active, op_labels, assigns))
      |> assign(:add_trigger_id, "#{assigns.id}-add-trigger")
      |> assign(:nav_template, link_mode? && nav_template(assigns.path, assigns.state))
      |> assign(:filters_json, link_mode? && Jason.encode!(assigns.state.filters))
      |> assign(
        :clear_url,
        assigns.path && FilterEditor.url_for(assigns.path, State.clear_filters(assigns.state))
      )

    ~H"""
    <div
      id={@id}
      class={["pc-filters", @class]}
      phx-hook="PetalDataTable"
      data-nav-template={@nav_template || nil}
      data-filters={@filters_json || nil}
    >
      <a :if={@link_mode?} data-pc-dt-nav data-phx-link="patch" data-phx-link-state="push" hidden></a>
      <p class="sr-only" role="status" aria-atomic="true">{@status_text}</p>

      <div
        :if={@chips != []}
        class="pc-filters__chips"
        role="group"
        aria-label={@active_filters_label}
      >
        <div :for={chip <- @chips} class="pc-filters__chip pc-popover">
          <button
            type="button"
            id={chip.trigger_id}
            data-pc-menu-trigger={chip.editor_id}
            aria-haspopup="dialog"
            aria-expanded="false"
            aria-controls={chip.editor_id}
            class="pc-popover__trigger pc-filters__chip-body"
          >
            <span class="pc-filters__chip-field">{chip.label}</span>
            <span class="pc-filters__chip-op">{FilterEditor.op_label(@op_labels, chip.filter.op)}</span>
            <span :if={not State.valueless_op?(chip.filter.op)} class="pc-filters__chip-value">
              {FilterEditor.display_value(chip.filter, chip.options)}
            </span>
          </button>
          <.link
            :if={@link_mode?}
            patch={FilterEditor.url_for(@path, State.put_filter(@state, chip.field, :eq, ""))}
            phx-click={JS.focus(to: "##{chip.next_focus_id}")}
            class="pc-filters__chip-remove"
            aria-label={remove_label(assigns, chip)}
          >
            <.icon name="hero-x-mark" class="pc-filters__chip-remove-icon" aria-hidden="true" />
          </.link>
          <button
            :if={!@link_mode?}
            type="button"
            class="pc-filters__chip-remove"
            phx-click={remove_js(assigns, chip)}
            aria-label={remove_label(assigns, chip)}
          >
            <.icon name="hero-x-mark" class="pc-filters__chip-remove-icon" aria-hidden="true" />
          </button>
          <div
            id={chip.editor_id}
            hidden
            data-pc-menu
            class="pc-popover__panel pc-popover__panel--bottom-start pc-filters__editor"
          >
            <.editor_form
              entry={chip}
              link_mode?={@link_mode?}
              on_change={@on_change}
              target={@target}
              op_labels={@op_labels}
              apply_label={@apply_label}
              filter_options_placeholder={@filter_options_placeholder}
            />
          </div>
        </div>
      </div>

      <div class="pc-popover pc-filters__add">
        <button
          type="button"
          id={@add_trigger_id}
          data-pc-menu-trigger={"#{@id}-add"}
          phx-click={reset_steps(@id)}
          aria-haspopup="dialog"
          aria-expanded="false"
          aria-controls={"#{@id}-add"}
          class="pc-popover__trigger pc-button pc-button--sm pc-button--gray-outline"
        >
          <.icon name="hero-plus-small" class="pc-filters__add-icon" aria-hidden="true" />
          <span>{@add_filter_label}</span>
        </button>
        <div
          id={"#{@id}-add"}
          hidden
          data-pc-menu
          class="pc-popover__panel pc-popover__panel--bottom-start pc-filters__panel"
        >
          <div
            id={"#{@id}-add-list"}
            class="pc-filters__fields"
            role="group"
            aria-label={@add_filter_label}
          >
            <button
              :for={entry <- @available}
              type="button"
              id={entry.field_button_id}
              phx-click={show_step(@id, entry)}
              class="pc-filters__field"
            >
              {entry.label}
            </button>
            <p :if={@available == []} class="pc-filters__none">{@all_fields_used_label}</p>
          </div>
          <div
            :for={entry <- @available}
            id={entry.step_id}
            data-pc-step
            class="pc-filters__step"
          >
            <button type="button" phx-click={reset_steps(@id, entry)} class="pc-filters__back">
              <.icon name="hero-chevron-left" class="pc-filters__back-icon" aria-hidden="true" />
              <span>{@add_filter_label}</span>
            </button>
            <p class="pc-filters__step-title">{entry.label}</p>
            <.editor_form
              entry={entry}
              link_mode?={@link_mode?}
              on_change={@on_change}
              target={@target}
              op_labels={@op_labels}
              apply_label={@apply_label}
              filter_options_placeholder={@filter_options_placeholder}
            />
          </div>
        </div>
      </div>

      <%= if @chips != [] do %>
        <.link
          :if={@link_mode?}
          patch={@clear_url}
          phx-click={JS.focus(to: "##{@add_trigger_id}")}
          class="pc-filters__clear"
        >
          {@clear_filters_label}
        </.link>
        <button
          :if={!@link_mode?}
          type="button"
          class="pc-filters__clear"
          phx-click={clear_js(assigns)}
        >
          {@clear_filters_label}
        </button>
      <% end %>
    </div>
    """
  end

  # -- the value editor form -------------------------------------------------

  attr :entry, :map, required: true
  attr :link_mode?, :boolean, required: true
  attr :on_change, :string, default: nil
  attr :target, :any, default: nil
  attr :op_labels, :map, required: true
  attr :apply_label, :string, required: true
  attr :filter_options_placeholder, :string, required: true

  # The same markup the data table's column editors post, so the PetalDataTable
  # hook reads it back in link mode and State.handle_op/3 parses it in event
  # mode. No new grammar on either side.
  defp editor_form(assigns) do
    ~H"""
    <form
      id={@entry.form_id}
      class="pc-data-table__filter-form pc-filters__form"
      phx-submit={@on_change && submit_js(@on_change, @target)}
      data-pc-dt-filter={@link_mode? || nil}
      data-field={@entry.field_str}
    >
      <input :if={!@link_mode?} type="hidden" name="op" value="filter" />
      <input :if={!@link_mode?} type="hidden" name="field" value={@entry.field_str} />
      <FilterEditor.filter_editor
        type={@entry.shape}
        ops={@entry.ops}
        default_op={@entry.default_op}
        filter={@entry.filter}
        options={@entry.options}
        op_labels={@op_labels}
        label={@entry.label}
        filter_options_placeholder={@filter_options_placeholder}
      />
      <.button size="sm" type="submit" class="pc-data-table__filter-apply">{@apply_label}</.button>
    </form>
    """
  end

  defp submit_js(event, nil), do: JS.push(event)
  defp submit_js(event, target), do: JS.push(event, target: target)

  # -- registry --------------------------------------------------------------

  defp entry(slot, id) do
    field = slot.field
    field_str = to_string(field)
    type = slot[:type] || "text"
    {shape, ops, default_op} = Map.fetch!(@types, type)

    %{
      field: field,
      field_str: field_str,
      label: slot[:label] || FilterEditor.humanize(field),
      type: type,
      shape: shape,
      ops: ops,
      default_op: default_op,
      options: FilterEditor.normalize_options(slot[:options] || []),
      filter: nil,
      editor_id: "#{id}-editor-#{field_str}",
      trigger_id: "#{id}-chip-#{field_str}",
      form_id: "#{id}-form-#{field_str}",
      step_id: "#{id}-add-step-#{field_str}",
      field_button_id: "#{id}-add-field-#{field_str}"
    }
  end

  # Removing a chip removes the element focus is sitting on, and LiveView's
  # patch would leave it on <body>. Each chip therefore knows where focus
  # should land: the next chip, else the add trigger - which is always
  # rendered, so this target can never be missing.
  defp chips(active, id) do
    trailing = active |> Enum.drop(1) |> Enum.map(& &1.trigger_id)
    next_ids = trailing ++ ["#{id}-add-trigger"]

    active
    |> Enum.zip(next_ids)
    |> Enum.map(fn {entry, next} -> Map.put(entry, :next_focus_id, next) end)
  end

  # -- wiring ----------------------------------------------------------------

  # `filter` with no filter_op is exactly how the data table's inline clear
  # removes a filter, so this needs no new server grammar.
  defp remove_js(assigns, chip) do
    assigns.on_change
    |> push(assigns.target, %{"op" => "filter", "field" => chip.field_str})
    |> JS.focus(to: "##{chip.next_focus_id}")
  end

  defp clear_js(assigns) do
    assigns.on_change
    |> push(assigns.target, %{"op" => "clear_filters"})
    |> JS.focus(to: "##{assigns.add_trigger_id}")
  end

  defp push(event, nil, value), do: JS.push(event, value: value)
  defp push(event, target, value), do: JS.push(event, value: value, target: target)

  defp remove_label(assigns, chip) do
    predicate =
      FilterEditor.predicate_text(chip.label, chip.filter, assigns.op_labels, chip.options)

    "#{assigns.remove_filter_label}: #{predicate}"
  end

  # Progressive disclosure with no hook and no server round trip: the panel
  # holds the field list and every field's editor, and these commands swap
  # which one is visible. CSS owns the display, so there is a complete rest
  # state and nothing to animate.
  defp show_step(id, entry) do
    %JS{}
    |> JS.add_class("pc-filters__fields--closed", to: "##{id}-add-list")
    |> JS.remove_class("pc-filters__step--open", to: "##{id}-add [data-pc-step]")
    |> JS.add_class("pc-filters__step--open", to: "##{entry.step_id}")
    |> JS.focus_first(to: "##{entry.form_id}")
  end

  defp reset_steps(id, entry \\ nil) do
    js =
      %JS{}
      |> JS.remove_class("pc-filters__fields--closed", to: "##{id}-add-list")
      |> JS.remove_class("pc-filters__step--open", to: "##{id}-add [data-pc-step]")

    if entry, do: JS.focus(js, to: "##{entry.field_button_id}"), else: js
  end

  # Link mode's Apply is the one interaction with no server-rendered href: the
  # values only exist in the DOM. The PetalDataTable hook fills :filters in
  # from the form and patches - the same template mechanism the data table's
  # own column editors use.
  defp nav_template(path, %State{} = state) do
    rest =
      %{state | filters: [], page: 1}
      |> State.to_params()
      |> FilterEditor.flatten_params()
      |> URI.encode_query()

    query = Enum.join([":filters"] ++ if(rest == "", do: [], else: [rest]), "&")
    FilterEditor.join_query(path, query)
  end

  # Read by a live region, so removing a chip announces what is left rather
  # than leaving the change silent.
  defp status_text([], _op_labels, assigns), do: assigns.no_filters_label

  defp status_text(active, op_labels, assigns) do
    predicates =
      Enum.map_join(active, ", ", fn entry ->
        FilterEditor.predicate_text(entry.label, entry.filter, op_labels, entry.options)
      end)

    "#{assigns.active_filters_label}: #{predicates}"
  end
end
