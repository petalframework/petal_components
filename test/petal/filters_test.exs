defmodule PetalComponents.FiltersTest do
  use ComponentCase

  import PetalComponents.Filters

  alias PetalComponents.DataTable.State

  @fields [:name, :category, :price, :in_stock, :added_on]

  defp options, do: [{"Hand tools", "hand"}, {"Power tools", "power"}, {"Finishing", "finishing"}]

  defp bar(assigns) do
    assigns = Map.merge(%{state: %State{}, path: nil, on_change: nil, extra: %{}}, assigns)

    rendered_to_string(~H"""
    <.filters
      id="f"
      state={@state}
      path={@path}
      on_change={@on_change}
      filter_op_labels={Map.get(@extra, :filter_op_labels, %{})}
      target={Map.get(@extra, :target)}
    >
      <:field field={:name} label="Name" type="text" />
      <:field field={:category} type="select" options={options()} />
      <:field field={:price} label="Price" type="number_range" />
      <:field field={:in_stock} label="In stock" type="boolean" />
      <:field field={:added_on} label="Added" type="date_range" />
    </.filters>
    """)
  end

  # Rebuilds an event-mode payload from the DOM the way a browser would, so
  # the round-trip below proves the rendered names, not names we hoped for.
  defp form_payload(html, form_id, overrides) do
    form = html |> parse_html() |> LazyHTML.query("##{form_id}")

    named =
      for el <- LazyHTML.query(form, "input[name], select[name]"),
          [name] <- [LazyHTML.attribute(el, "name")],
          name != "",
          into: %{} do
        value = el |> LazyHTML.attribute("value") |> List.first()
        {name, value || ""}
      end

    Map.merge(named, overrides)
  end

  defp query(url),
    do: url |> URI.parse() |> Map.get(:query) |> Kernel.||("") |> Plug.Conn.Query.decode()

  defp text(doc, selector),
    do: doc |> LazyHTML.query(selector) |> LazyHTML.text() |> String.trim()

  defp href(html, selector) do
    html |> parse_html() |> LazyHTML.query(selector) |> LazyHTML.attribute("href") |> List.first()
  end

  describe "wiring modes" do
    test "raises when neither path nor on_change is given" do
      assigns = %{}

      assert_raise ArgumentError, ~r/either path \(link mode\) or on_change \(event mode\)/, fn ->
        rendered_to_string(~H"""
        <.filters id="f" state={%State{}}>
          <:field field={:name} type="text" />
        </.filters>
        """)
      end
    end

    test "link mode mounts the hook with a :filters nav template and a patch anchor" do
      html = bar(%{path: "/products", state: %State{order_by: [name: :desc]}})

      assert html =~ ~s(phx-hook="PetalDataTable")
      assert html =~ ~s(data-nav-template="/products?:filters&amp;order_by=name%3Adesc")
      assert html =~ "data-pc-dt-nav"
      # the editors post to the hook, not to the server
      assert html =~ "data-pc-dt-filter"
      refute html =~ "phx-submit"
    end

    test "link mode publishes the committed filters as JSON for the hook" do
      state = %State{filters: [%{field: :category, op: :eq, value: "hand"}]}
      html = bar(%{path: "/products", state: state})

      assert html =~ "data-filters="
      assert html =~ "&quot;field&quot;:&quot;category&quot;"
      assert html =~ "&quot;op&quot;:&quot;eq&quot;"
    end

    test "event mode needs no nav template, and every editor posts phx-submit" do
      html = bar(%{on_change: "table"})

      assert html =~ ~s(phx-hook="PetalDataTable")
      refute html =~ "data-nav-template"
      refute html =~ "data-pc-dt-filter"
      assert html =~ ~s(name="op" value="filter")
    end
  end

  describe "chips" do
    test "render field label, operator label and formatted value" do
      state = %State{filters: [%{field: :category, op: :eq, value: "power"}]}
      html = bar(%{on_change: "table", state: state})
      doc = parse_html(html)

      assert text(doc, ".pc-filters__chip-field") == "Category"
      assert text(doc, ".pc-filters__chip-op") == "is"
      # the option LABEL, not the posted value
      assert text(doc, ".pc-filters__chip-value") == "Power tools"
    end

    test "a valueless operator renders label and operator only" do
      state = %State{filters: [%{field: :name, op: :is_empty, value: true}]}
      html = bar(%{on_change: "table", state: state})
      doc = parse_html(html)

      assert text(doc, ".pc-filters__chip-op") == "is empty"
      assert doc |> LazyHTML.query(".pc-filters__chip-value") |> Enum.count() == 0
    end

    test "between renders both bounds and in renders a truncated list" do
      state = %State{
        filters: [
          %{field: :price, op: :between, value: ["50", "150"]},
          %{field: :category, op: :in, value: ["hand", "power", "finishing"]}
        ]
      }

      html = bar(%{on_change: "table", state: state})
      values = html |> parse_html() |> LazyHTML.query(".pc-filters__chip-value") |> Enum.to_list()

      assert values |> Enum.at(0) |> LazyHTML.text() |> String.trim() == "50–150"

      assert values |> Enum.at(1) |> LazyHTML.text() |> String.trim() ==
               "Hand tools, Power tools +1"
    end

    test "a filter on an unregistered field renders no chip" do
      state = %State{filters: [%{field: :secret, op: :eq, value: "x"}]}
      html = bar(%{on_change: "table", state: state})

      refute html =~ "pc-filters__chip-field"
    end

    test "the chip body reopens that field's editor, pre-filled" do
      state = %State{filters: [%{field: :name, op: :starts_with, value: "Ham"}]}
      html = bar(%{on_change: "table", state: state})

      assert html =~ ~s(data-pc-menu-trigger="f-editor-name")
      assert html =~ ~s(id="f-editor-name")
      assert html =~ ~s(value="Ham")
      assert html =~ ~s(<option value="starts_with" selected>)
    end
  end

  describe "operator vocabulary" do
    test "every offered operator is a member of State.ops/0" do
      offered = type_operators() |> Map.values() |> List.flatten() |> Enum.uniq()

      assert offered != []

      assert Enum.all?(offered, &(&1 in State.ops())),
             "offered: #{inspect(offered -- State.ops())}"
    end

    test "each type offers exactly its documented subset" do
      assert type_operators() == %{
               "text" => [
                 :contains,
                 :not_contains,
                 :eq,
                 :neq,
                 :starts_with,
                 :is_empty,
                 :is_not_empty
               ],
               "select" => [:eq, :neq, :is_empty, :is_not_empty],
               "multi" => [:in],
               "number_range" => [
                 :eq,
                 :neq,
                 :gt,
                 :gte,
                 :lt,
                 :lte,
                 :between,
                 :is_empty,
                 :is_not_empty
               ],
               "date_range" => [:before, :on, :after, :between, :is_empty, :is_not_empty],
               "boolean" => [:eq]
             }
    end

    test "the rendered operator picker offers exactly the type's subset" do
      html = bar(%{on_change: "table"})
      doc = parse_html(html)

      rendered =
        doc
        |> LazyHTML.query(~s(#f-form-added_on select[name="filter_op"] option))
        |> Enum.map(fn opt -> opt |> LazyHTML.attribute("value") |> List.first() end)

      assert rendered == ~w(before on after between is_empty is_not_empty)
    end

    test "boolean pins the operator to eq and renders no picker" do
      html = bar(%{on_change: "table"})
      doc = parse_html(html)

      assert doc |> LazyHTML.query(~s(#f-form-in_stock select[name="filter_op"])) |> Enum.count() ==
               0

      assert html =~ ~s(<input type="hidden" name="filter_op" value="eq")
    end

    test "multi posts values[] and text/number/date post value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.filters id="f" state={%State{}} on_change="table">
          <:field field={:category} type="multi" options={["hand", "power"]} />
        </.filters>
        """)

      assert html =~ ~s(name="values[]")
      refute html =~ ~s(select[name="filter_op"])
    end

    test "between-capable types render a second bound, date_range included" do
      html = bar(%{on_change: "table"})
      doc = parse_html(html)

      assert doc |> LazyHTML.query(~s(#f-form-price input[name="value2"])) |> Enum.count() == 1
      assert doc |> LazyHTML.query(~s(#f-form-added_on input[name="value2"])) |> Enum.count() == 1
    end
  end

  describe "event mode payloads" do
    test "the apply form round-trips through State.handle_op/3" do
      html = bar(%{on_change: "table"})

      params = form_payload(html, "f-form-name", %{"filter_op" => "contains", "value" => "anvil"})

      assert %State{filters: [%{field: :name, op: :contains, value: "anvil"}]} =
               State.handle_op(%State{}, params, fields: @fields)
    end

    test "a between apply round-trips into a two-bound filter" do
      html = bar(%{on_change: "table"})

      params =
        form_payload(html, "f-form-price", %{
          "filter_op" => "between",
          "value" => "50",
          "value2" => "150"
        })

      assert %State{filters: [%{field: :price, op: :between, value: ["50", "150"]}]} =
               State.handle_op(%State{}, params, fields: @fields)
    end

    test "a valueless apply round-trips without reading as a removal" do
      html = bar(%{on_change: "table"})
      params = form_payload(html, "f-form-name", %{"filter_op" => "is_empty", "value" => ""})

      assert %State{filters: [%{field: :name, op: :is_empty}]} =
               State.handle_op(%State{}, params, fields: @fields)
    end

    test "a multi apply round-trips into an :in filter" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.filters id="f" state={%State{}} on_change="table">
          <:field field={:category} type="multi" options={["hand", "power"]} />
        </.filters>
        """)

      params = form_payload(html, "f-form-category", %{"values" => ["hand", "power"]})

      assert %State{filters: [%{field: :category, op: :in, value: ["hand", "power"]}]} =
               State.handle_op(%State{}, params, fields: @fields)
    end

    test "chip removal pushes a filter op with no operator, which handle_op reads as removal" do
      state = %State{filters: [%{field: :category, op: :eq, value: "hand"}], page: 4}
      html = bar(%{on_change: "table", state: state})

      assert html =~ ~s(&quot;op&quot;:&quot;filter&quot;)
      assert html =~ ~s(&quot;field&quot;:&quot;category&quot;)

      assert %State{filters: [], page: 1} =
               State.handle_op(state, %{"op" => "filter", "field" => "category"}, fields: @fields)
    end

    test "clear all pushes clear_filters and is hidden while nothing is filtered" do
      state = %State{filters: [%{field: :category, op: :eq, value: "hand"}]}
      html = bar(%{on_change: "table", state: state})

      assert html =~ ~s(&quot;op&quot;:&quot;clear_filters&quot;)
      assert html =~ "pc-filters__clear"

      refute bar(%{on_change: "table"}) =~ "pc-filters__clear"
    end

    test "target rides every pushed payload" do
      state = %State{filters: [%{field: :category, op: :eq, value: "hand"}]}
      html = bar(%{on_change: "table", state: state, extra: %{target: "#me"}})

      assert html =~ ~s(&quot;target&quot;:&quot;#me&quot;)
    end
  end

  describe "link mode URLs" do
    test "a chip's remove href decodes back to the state without that filter" do
      state = %State{
        filters: [
          %{field: :category, op: :eq, value: "hand"},
          %{field: :price, op: :gt, value: "100"}
        ]
      }

      html = bar(%{path: "/products", state: state})
      url = href(html, ~s(.pc-filters__chip-remove[aria-label^="Remove filter: Category"]))

      assert %State{filters: [%{field: :price, op: :gt, value: "100"}]} =
               State.from_params(query(url), fields: @fields)
    end

    test "the clear-all href decodes back to an unfiltered state" do
      state = %State{filters: [%{field: :category, op: :eq, value: "hand"}], page: 3}
      html = bar(%{path: "/products", state: state})

      assert %State{filters: [], page: 1} =
               html |> href(".pc-filters__clear") |> query() |> State.from_params(fields: @fields)
    end

    test "defaults stay out of the URL" do
      state = %State{filters: [%{field: :category, op: :eq, value: "hand"}]}
      url = %{path: "/products", state: state} |> bar() |> href(".pc-filters__clear")

      assert url == "/products"
    end

    test "removal and clear-all move focus off the element they delete" do
      state = %State{
        filters: [
          %{field: :category, op: :eq, value: "hand"},
          %{field: :price, op: :gt, value: "100"}
        ]
      }

      html = bar(%{path: "/products", state: state})

      # first chip hands focus to the second, the last to the add trigger
      assert html =~ ~s(&quot;to&quot;:&quot;#f-chip-price&quot;)
      assert html =~ ~s(&quot;to&quot;:&quot;#f-add-trigger&quot;)
    end
  end

  describe "the add-filter panel" do
    test "lists only fields that are not already filtered" do
      state = %State{filters: [%{field: :category, op: :eq, value: "hand"}]}
      html = bar(%{on_change: "table", state: state})
      doc = parse_html(html)

      labels =
        doc |> LazyHTML.query(".pc-filters__field") |> Enum.map(&String.trim(LazyHTML.text(&1)))

      assert labels == ["Name", "Price", "In stock", "Added"]
    end

    test "says so when every field is already filtered" do
      state = %State{
        filters: [
          %{field: :name, op: :is_empty, value: true},
          %{field: :category, op: :eq, value: "hand"},
          %{field: :price, op: :gt, value: "1"},
          %{field: :in_stock, op: :eq, value: "true"},
          %{field: :added_on, op: :on, value: "2026-01-01"}
        ]
      }

      html = bar(%{on_change: "table", state: state})

      assert html =~ "Every field is already filtered"
      refute html =~ "pc-filters__field&quot;"
    end

    test "picking a field swaps the panel to that field's editor and focuses it" do
      html = bar(%{on_change: "table"})

      assert html =~ ~s(&quot;pc-filters__fields--closed&quot;)
      assert html =~ ~s(&quot;#f-add-step-name&quot;)
      assert html =~ ~s(focus_first)
      assert html =~ ~s(id="f-add-step-name")
    end

    test "the trigger is always rendered, so focus always has somewhere to land" do
      assert bar(%{on_change: "table"}) =~ ~s(id="f-add-trigger")
    end
  end

  describe "accessibility" do
    test "the add trigger declares its popup and collapsed state" do
      html = bar(%{on_change: "table"})

      assert html =~ ~s(aria-haspopup="dialog")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(aria-controls="f-add")
    end

    test "the chip list is announced as a labelled group" do
      state = %State{filters: [%{field: :category, op: :eq, value: "hand"}]}
      html = bar(%{on_change: "table", state: state})

      assert html =~ ~s(role="group")
      assert html =~ ~s(aria-label="Active filters")
    end

    test "a remove button names the filter it removes" do
      state = %State{
        filters: [
          %{field: :category, op: :eq, value: "hand"},
          %{field: :name, op: :is_empty, value: true}
        ]
      }

      html = bar(%{on_change: "table", state: state})

      assert html =~ ~s(aria-label="Remove filter: Category is Hand tools")
      assert html =~ ~s(aria-label="Remove filter: Name is empty")
    end

    test "a live region reports the active filters, and says so when there are none" do
      assert bar(%{on_change: "table"}) =~ ~s(role="status")
      assert bar(%{on_change: "table"}) =~ "No filters applied"

      state = %State{filters: [%{field: :category, op: :eq, value: "hand"}]}

      assert bar(%{on_change: "table", state: state}) =~
               "Active filters: Category is Hand tools"
    end

    test "the chip trigger controls its own editor panel" do
      state = %State{filters: [%{field: :price, op: :gt, value: "10"}]}
      html = bar(%{on_change: "table", state: state})

      assert html =~ ~s(id="f-chip-price")
      assert html =~ ~s(aria-controls="f-editor-price")
    end

    test "decorative icons are hidden from assistive tech" do
      state = %State{filters: [%{field: :category, op: :eq, value: "hand"}]}
      html = bar(%{on_change: "table", state: state})

      assert has_icon?(html, "pc-filters__chip-remove-icon")
      assert html =~ ~s(class="hero-x-mark pc-filters__chip-remove-icon" aria-hidden="true")
    end

    test "editor controls carry accessible names" do
      html = bar(%{on_change: "table"})

      assert html =~ ~s(aria-label="Price operator")
      assert html =~ ~s(aria-label="Price lower bound")
      assert html =~ ~s(aria-label="Price upper bound")
      assert html =~ ~s(aria-label="In stock value")
    end
  end

  describe "labels" do
    test "filter_op_labels overrides reach both the chips and the operator picker" do
      state = %State{filters: [%{field: :name, op: :contains, value: "an"}]}

      html =
        bar(%{
          on_change: "table",
          state: state,
          extra: %{filter_op_labels: %{contains: "enthält"}}
        })

      doc = parse_html(html)

      assert text(doc, ".pc-filters__chip-op") == "enthält"

      options =
        doc
        |> LazyHTML.query(~s(#f-form-name select[name="filter_op"] option))
        |> LazyHTML.text()

      assert options =~ "enthält"
    end

    test "every user-facing string is overridable" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.filters
          id="f"
          state={%State{filters: [%{field: :name, op: :eq, value: "x"}]}}
          on_change="table"
          add_filter_label="Filtre"
          clear_filters_label="Effacer"
          apply_label="Appliquer"
          remove_filter_label="Retirer"
          active_filters_label="Filtres actifs"
        >
          <:field field={:name} label="Nom" type="text" />
          <:field field={:price} label="Prix" type="number_range" />
        </.filters>
        """)

      assert html =~ "Filtre"
      assert html =~ "Effacer"
      assert html =~ "Appliquer"
      assert html =~ ~s(aria-label="Retirer: Nom is x")
      assert html =~ ~s(aria-label="Filtres actifs")
    end

    test "a field with no label humanizes its atom" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.filters
          id="f"
          state={%State{filters: [%{field: :added_on, op: :on, value: "2026-01-01"}]}}
          on_change="table"
        >
          <:field field={:added_on} type="date_range" />
        </.filters>
        """)

      assert html =~ "Added on"
    end
  end

  describe "styling hooks" do
    test "class rides the root and the pc-filters section owns the chrome" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.filters id="f" state={%State{}} on_change="table" class="mb-6">
          <:field field={:name} type="text" />
        </.filters>
        """)

      assert html =~ ~s(class="pc-filters mb-6")
      assert html =~ "pc-popover__panel--bottom-start"
      assert html =~ "pc-filters__panel"
    end
  end
end
