defmodule PetalComponents.EmptyTest do
  use ComponentCase

  import PetalComponents.Button
  import PetalComponents.DataTable
  import PetalComponents.Empty
  import PetalComponents.Icon

  alias PetalComponents.DataTable.State

  test "renders the root with title and description" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.empty title="No results found" description="Try a broader search." />
      """)

    assert_has_class(html, "pc-empty")
    assert html =~ "No results found"
    assert html =~ "Try a broader search."

    doc = LazyHTML.from_fragment(html)
    assert doc |> LazyHTML.query(".pc-empty__title") |> LazyHTML.text() == "No results found"
    assert doc |> LazyHTML.query(".pc-empty__description") |> LazyHTML.text() =~ "broader search"

    # media, title, description in DOM order - the screen reader read
    positions =
      Enum.map(
        ~w(pc-empty__media pc-empty__title pc-empty__description),
        fn class -> html |> :binary.match(class) |> elem(0) end
      )

    assert positions == Enum.sort(positions)
  end

  test "the root is a plain div - no landmark or live region" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.empty title="Nothing here" />
      """)

    root = html |> LazyHTML.from_fragment() |> LazyHTML.query(".pc-empty")

    assert LazyHTML.attribute(root, "role") == []
    assert LazyHTML.attribute(root, "aria-live") == []
    refute html =~ "aria-live"
  end

  for variant <- ~w(default compact card dashed) do
    test "variant #{variant} emits its modifier class" do
      assigns = %{variant: unquote(variant)}

      html =
        rendered_to_string(~H"""
        <.empty variant={@variant} title="Nothing here" />
        """)

      assert_has_class(html, "pc-empty--#{unquote(variant)}")
    end
  end

  for size <- ~w(sm md lg) do
    test "size #{size} emits its modifier class" do
      assigns = %{size: unquote(size)}

      html =
        rendered_to_string(~H"""
        <.empty size={@size} title="Nothing here" />
        """)

      assert_has_class(html, "pc-empty--#{unquote(size)}")
    end
  end

  test "defaults to the default variant at md" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.empty title="Nothing here" />
      """)

    assert_has_class(html, "pc-empty--default")
    assert_has_class(html, "pc-empty--md")
  end

  test "the default media is a decorative icon treatment" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.empty title="Nothing here" />
      """)

    assert_has_class(html, "pc-empty__media--default")
    assert has_icon?(html, "hero-inbox")

    media = html |> LazyHTML.from_fragment() |> LazyHTML.query(".pc-empty__media")
    assert LazyHTML.attribute(media, "aria-hidden") == ["true"]
  end

  test "the icon slot replaces the default media and stays decorative" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.empty title="Nothing here">
        <:icon><.icon name="hero-folder-plus" class="w-8 h-8" /></:icon>
      </.empty>
      """)

    assert has_icon?(html, "hero-folder-plus")
    refute has_icon?(html, "hero-inbox")
    refute_has_class(html, "pc-empty__media--default")

    media = html |> LazyHTML.from_fragment() |> LazyHTML.query(".pc-empty__media")
    assert LazyHTML.attribute(media, "aria-hidden") == ["true"]
  end

  test "actions render inside the actions row" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.empty title="No projects yet">
        <:actions>
          <.button size="sm" label="Create project" />
          <.button size="sm" variant="outline" color="gray" label="Import" />
        </:actions>
      </.empty>
      """)

    actions = html |> LazyHTML.from_fragment() |> LazyHTML.query(".pc-empty__actions")

    assert LazyHTML.text(actions) =~ "Create project"
    assert LazyHTML.text(actions) =~ "Import"
    assert actions |> LazyHTML.query("button") |> Enum.count() == 2
  end

  test "the actions row is absent when the slot is empty" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.empty title="No projects yet" />
      """)

    refute_has_class(html, "pc-empty__actions")
  end

  test "inner_block renders as the trailing footer line" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.empty title="No projects yet">
        <a href="/docs">Learn more</a>
      </.empty>
      """)

    footer = html |> LazyHTML.from_fragment() |> LazyHTML.query(".pc-empty__footer")

    assert LazyHTML.text(footer) =~ "Learn more"
    assert footer |> LazyHTML.query("a") |> LazyHTML.attribute("href") == ["/docs"]
  end

  test "the footer is absent without an inner_block" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.empty title="No projects yet" />
      """)

    refute_has_class(html, "pc-empty__footer")
  end

  test "class merges onto the root and rest passes through" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.empty id="orders-empty" class="my-8 bg-white" title="Nothing here" data-test="empty" />
      """)

    assert_has_class(html, "pc-empty")
    assert_has_class(html, "my-8")
    assert_has_class(html, "bg-white")
    assert_attribute(html, "id", "orders-empty")
    assert_attribute(html, "data-test", "empty")
  end

  test "every part is optional - title only, and nothing at all" do
    assigns = %{}

    title_only =
      rendered_to_string(~H"""
      <.empty title="No results found" />
      """)

    assert title_only =~ "No results found"
    refute_has_class(title_only, "pc-empty__description")
    refute_has_class(title_only, "pc-empty__actions")
    refute_has_class(title_only, "pc-empty__footer")

    bare =
      rendered_to_string(~H"""
      <.empty />
      """)

    assert_has_class(bare, "pc-empty")
    refute_has_class(bare, "pc-empty__title")
    refute_has_class(bare, "pc-empty__description")
  end

  test "composes inside the data table's empty slot" do
    assigns = %{state: %State{total: 0}}

    html =
      rendered_to_string(~H"""
      <.data_table id="orders" rows={[]} state={@state} path="/orders">
        <:col :let={row} field={:name}>{row.name}</:col>
        <:empty>
          <.empty variant="compact" size="sm" title="No orders yet" />
        </:empty>
      </.data_table>
      """)

    assert_has_class(html, "pc-empty--compact")
    assert_has_class(html, "pc-empty--sm")
    assert html =~ "No orders yet"
    # the slot replaces the data table's own default empty line
    refute html =~ "No results for these filters"
  end
end
