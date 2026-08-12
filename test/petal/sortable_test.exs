defmodule PetalComponents.SortableTest do
  @moduledoc """
  Tests for PetalComponents.Sortable - the drag-to-reorder list and grid.

  The rendered contract here is what the PetalSortable hook reads at runtime
  (test/js/sortable.test.js pins the other half), so a change to a data
  attribute or a class name has to be made in both places on purpose.
  """

  use ComponentCase
  import PetalComponents.Sortable

  defp list(assigns \\ %{}) do
    assigns = Map.merge(%{disabled: false, handle: false, orientation: "vertical"}, assigns)

    rendered_to_string(~H"""
    <.sortable
      id="stages"
      on_reorder="reorder"
      handle={@handle}
      disabled={@disabled}
      orientation={@orientation}
    >
      <:item id="a" label="Discovery">Discovery</:item>
      <:item id="b" label="Demo">Demo</:item>
      <:item id="c" label="Proposal" disabled>Proposal</:item>
    </.sortable>
    """)
  end

  defp items(html), do: html |> parse_html() |> LazyHTML.query(".pc-sortable__item")

  defp attrs(nodes, name), do: LazyHTML.attribute(nodes, name)

  describe "container" do
    test "renders the hook and the attributes it reads" do
      html = list()
      root = html |> parse_html() |> LazyHTML.query("#stages")

      assert_has_class(html, "pc-sortable")
      assert attrs(root, "phx-hook") == ["PetalSortable"]
      assert attrs(root, "data-on-reorder") == ["reorder"]
      assert attrs(root, "data-orientation") == ["vertical"]
      assert attrs(root, "role") == ["list"]
      # not in handle or disabled mode, so neither flag is stamped
      assert attrs(root, "data-handle") == []
      assert attrs(root, "data-disabled") == []
    end

    test "grid orientation adds the modifier and the data attr" do
      html = list(%{orientation: "grid"})
      root = html |> parse_html() |> LazyHTML.query("#stages")

      assert_has_class(html, "pc-sortable--grid")
      assert attrs(root, "data-orientation") == ["grid"]
    end

    test "class merges onto the container rather than replacing it" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sortable id="s" on_reorder="reorder" class="mt-6 max-w-md">
          <:item id="a">A</:item>
        </.sortable>
        """)

      root = html |> parse_html() |> LazyHTML.query("#s")
      [classes] = attrs(root, "class")

      assert classes =~ "pc-sortable"
      assert classes =~ "mt-6"
      assert classes =~ "max-w-md"
    end

    test "rest passes through to the container, including phx-update" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sortable id="s" on_reorder="reorder" phx-update="stream" data-testid="board">
          <:item id="a">A</:item>
        </.sortable>
        """)

      root = html |> parse_html() |> LazyHTML.query("#s")

      assert attrs(root, "phx-update") == ["stream"]
      assert attrs(root, "data-testid") == ["board"]
    end

    test "target renders as phx-target so a live component can own the event" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sortable id="s" on_reorder="reorder" target="#board">
          <:item id="a">A</:item>
        </.sortable>
        """)

      assert html |> parse_html() |> LazyHTML.query("#s") |> attrs("phx-target") == ["#board"]
    end
  end

  describe "items" do
    test "each item carries its sortable id and the a11y attributes" do
      html = list()
      nodes = items(html)

      assert Enum.count(nodes) == 3
      assert attrs(nodes, "data-sortable-id") == ["a", "b", "c"]
      assert attrs(nodes, "role") == ["listitem", "listitem", "listitem"]

      assert attrs(nodes, "aria-roledescription") == [
               "sortable",
               "sortable",
               "sortable"
             ]

      assert attrs(nodes, "aria-describedby") == [
               "stages-instructions",
               "stages-instructions",
               "stages-instructions"
             ]
    end

    test "the element id defaults to the sortable id and dom_id overrides it" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sortable id="s" on_reorder="reorder">
          <:item id="42" dom_id="todos-42">Buy milk</:item>
          <:item id="43">Walk dog</:item>
        </.sortable>
        """)

      nodes = items(html)

      # streams need the stream dom id on the element, while the server still
      # wants the record id in the event payload - hence two ids, not one
      assert attrs(nodes, "id") == ["todos-42", "43"]
      assert attrs(nodes, "data-sortable-id") == ["42", "43"]
    end

    test "the label rides along for announcements" do
      assert attrs(items(list()), "data-sortable-label") == ["Discovery", "Demo", "Proposal"]
    end

    test "items are in the tab order, and disabled ones are not" do
      nodes = items(list())

      # a and b are focusable; c is disabled so it has no tabindex at all
      assert attrs(nodes, "tabindex") == ["0", "0"]
      assert attrs(nodes, "data-disabled") == ["true"]
      assert Enum.count(LazyHTML.query(nodes, ".pc-sortable__item--disabled")) == 1
    end
  end

  describe "handle mode" do
    test "renders a grip button with an accessible name, and moves the tab stop to it" do
      html = list(%{handle: true})
      handles = html |> parse_html() |> LazyHTML.query(".pc-sortable__handle")

      assert Enum.count(handles) == 3

      assert attrs(handles, "aria-label") == [
               "Reorder Discovery",
               "Reorder Demo",
               "Reorder Proposal"
             ]

      assert attrs(handles, "data-sortable-handle") == ["", "", ""]
      assert attrs(handles, "type") == ["button", "button", "button"]

      # the grip is the tab stop now, so no row carries a tabindex
      assert attrs(items(html), "tabindex") == []

      # and the disabled row's grip leaves the tab order
      assert attrs(handles, "aria-disabled") == ["true"]
      assert attrs(handles, "tabindex") == ["-1"]
    end

    test "no handle without the attr" do
      refute_has_class(list(), "pc-sortable__handle")
      assert list() |> parse_html() |> LazyHTML.query(".pc-sortable__handle") |> Enum.empty?()
    end
  end

  describe "disabled container" do
    test "stamps the flag, the modifier, and empties the tab order" do
      html = list(%{disabled: true})
      root = html |> parse_html() |> LazyHTML.query("#stages")
      nodes = items(html)

      assert attrs(root, "data-disabled") == ["true"]
      assert_has_class(html, "pc-sortable--disabled")
      assert attrs(nodes, "tabindex") == []
      assert attrs(nodes, "data-disabled") == ["true", "true", "true"]
    end
  end

  describe "announcements" do
    test "renders one polite live region and the keyboard instructions" do
      html = list()
      doc = parse_html(html)

      live = LazyHTML.query(doc, "#stages-live")
      assert attrs(live, "aria-live") == ["polite"]
      assert attrs(live, "role") == ["status"]
      assert attrs(live, "aria-atomic") == ["true"]

      # the hook writes the announcement into an element the server renders
      # empty, so the patch caused by the drop would otherwise wipe it
      assert attrs(live, "phx-update") == ["ignore"]

      instructions = LazyHTML.query(doc, "#stages-instructions")
      assert Enum.count(instructions) == 1
      assert LazyHTML.text(instructions) =~ "Press Space to lift"
      assert LazyHTML.text(instructions) =~ "Escape to cancel"
    end

    test "the live region and instructions sit outside the list container" do
      # phx-update="stream" requires the container's children to be exactly
      # the stream items, so neither may be nested inside it
      html = list()
      inside = html |> parse_html() |> LazyHTML.query("#stages .pc-sortable__sr")

      assert Enum.empty?(inside)
      assert html |> parse_html() |> LazyHTML.query(".pc-sortable__sr") |> Enum.count() == 2
    end
  end

  describe "stream-backed rendering" do
    # Reconciliation is by data-sortable-id, never by index: a stream that
    # re-renders in a new order must keep every id, with no duplication and
    # no dependence on the position an item happened to hold before.
    defp stream_html(entries) do
      assigns = %{entries: entries}

      rendered_to_string(~H"""
      <.sortable id="todos" on_reorder="reorder" phx-update="stream">
        <:item :for={{dom_id, todo} <- @entries} id={todo.id} dom_id={dom_id} label={todo.title}>
          {todo.title}
        </:item>
      </.sortable>
      """)
    end

    test "a reordered stream renders the same ids in the new order, once each" do
      todos = [
        %{id: "1", title: "Ship it"},
        %{id: "2", title: "Write it up"},
        %{id: "3", title: "Sleep"}
      ]

      entries = Enum.map(todos, &{"todos-#{&1.id}", &1})
      first = stream_html(entries)

      assert attrs(items(first), "data-sortable-id") == ["1", "2", "3"]
      assert attrs(items(first), "id") == ["todos-1", "todos-2", "todos-3"]

      # the server applies the {"id" => "3", "from" => 2, "to" => 0} it was
      # sent and re-renders; the dom ids travel with their records
      reordered = [Enum.at(entries, 2) | Enum.take(entries, 2)]
      second = stream_html(reordered)

      ids = attrs(items(second), "data-sortable-id")
      assert ids == ["3", "1", "2"]
      assert ids == Enum.uniq(ids)
      assert attrs(items(second), "id") == ["todos-3", "todos-1", "todos-2"]

      # identity, not position: every dom id survives the move intact
      assert Enum.sort(attrs(items(first), "id")) == Enum.sort(attrs(items(second), "id"))
    end
  end
end
