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

    # The title is deliberately a <p>, not a heading: an empty state must
    # not inject itself into the page's h1-h6 outline (the issue's call).
    assert doc |> LazyHTML.query("p.pc-empty__title") |> Enum.count() == 1
    assert doc |> LazyHTML.query("h1, h2, h3, h4, h5, h6") |> Enum.count() == 0
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

  # An open and close call always has an inner block, even when it holds only
  # named slots and the whitespace between them, so the footer has to test
  # what the block renders.
  describe "the footer and a blank inner block" do
    defp footer_count(html),
      do: html |> LazyHTML.from_fragment() |> LazyHTML.query(".pc-empty__footer") |> Enum.count()

    defp learn_more(assigns) do
      ~H"""
      <a :if={@href} href={@href}>Learn more</a>
      """
    end

    test "a call with only :icon and :actions renders no footer" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.empty title="No projects yet">
          <:icon><.icon name="hero-folder-plus" class="w-6 h-6" /></:icon>
          <:actions>
            <.button size="sm">Create project</.button>
          </:actions>
        </.empty>
        """)

      assert_has_class(html, "pc-empty__actions")
      assert footer_count(html) == 0
    end

    for size <- ["sm", "lg"] do
      test "size #{size} with only :icon and :actions renders no footer" do
        assigns = %{size: unquote(size)}

        html =
          rendered_to_string(~H"""
          <.empty title="No projects yet" size={@size}>
            <:icon><.icon name="hero-folder-plus" class="w-6 h-6" /></:icon>
            <:actions><.button size="sm">Create project</.button></:actions>
          </.empty>
          """)

        assert_has_class(html, "pc-empty--#{@size}")
        assert footer_count(html) == 0
      end
    end

    test "whitespace, nil, an empty string, raw whitespace and a false if render no footer" do
      assigns = %{link: nil, show?: false}

      html =
        rendered_to_string(~H"""
        <.empty title="No projects yet">
          <:actions><.button size="sm">Create</.button></:actions>
          {@link}
          {""}
          {Phoenix.HTML.raw("   ")}
          <%= if false do %>
            <p>hidden</p>
          <% end %>
          <a :if={@show?} href="/docs">Learn more</a>
        </.empty>
        """)

      assert footer_count(html) == 0
    end

    test "a nested component that renders nothing gives no footer; with a link it does" do
      assigns = %{}

      none =
        rendered_to_string(~H"""
        <.empty title="No projects yet">
          <.learn_more href={nil} />
        </.empty>
        """)

      some =
        rendered_to_string(~H"""
        <.empty title="No projects yet">
          <.learn_more href="/docs" />
        </.empty>
        """)

      assert footer_count(none) == 0
      assert footer_count(some) == 1
    end

    test "a text-only footer and a component-only footer still render" do
      assigns = %{}

      text =
        rendered_to_string(~H"""
        <.empty title="No projects yet">
          <:actions><.button size="sm">Create</.button></:actions>
          Updated hourly
        </.empty>
        """)

      assert text
             |> LazyHTML.from_fragment()
             |> LazyHTML.query(".pc-empty__footer")
             |> LazyHTML.text() =~ "Updated hourly"

      component =
        rendered_to_string(~H"""
        <.empty title="No projects yet">
          <.button size="sm" variant="link">Learn more</.button>
        </.empty>
        """)

      assert component
             |> LazyHTML.from_fragment()
             |> LazyHTML.query(".pc-empty__footer .pc-button")
             |> Enum.count() == 1
    end

    test "{0} renders a footer" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.empty title="No projects yet">{0}</.empty>
        """)

      assert footer_count(html) == 1
    end

    # Deliberate: a comprehension counts as content without being looked into.
    test "a :for over an empty list keeps the footer" do
      assigns = %{links: []}

      html =
        rendered_to_string(~H"""
        <.empty title="No projects yet">
          <a :for={link <- @links} href={link}>{link}</a>
        </.empty>
        """)

      assert footer_count(html) == 1
    end

    test "a self-closing call has no footer" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.empty title="No projects yet" />
        """)

      assert footer_count(html) == 0
    end

    defp tracked_page(assigns) do
      ~H"""
      <.empty title={"Projects #{@other}"}>
        <:actions><.button size="sm">Create</.button></:actions>
        <a :if={@link} href={@link}>Learn more</a>
      </.empty>
      """
    end

    # Renders the way a LiveView does: a diff against the last render's
    # fingerprints, merged into what the client holds.
    defp tracked_render(assigns, {client, prints, components}) do
      {diff, prints, components} =
        Phoenix.LiveView.Diff.render(
          %Phoenix.LiveView.Socket{},
          tracked_page(assigns),
          prints,
          components
        )

      client = Phoenix.LiveViewTest.Diff.merge_diff(client, diff)
      html = client |> Phoenix.LiveView.Diff.to_iodata() |> IO.iodata_to_binary()
      {html, {client, prints, components}}
    end

    test "the footer follows the block through LiveView change tracking" do
      state =
        {%{}, Phoenix.LiveView.Diff.new_fingerprints(), Phoenix.LiveView.Diff.new_components()}

      {html, state} = tracked_render(%{link: nil, other: 1, __changed__: nil}, state)
      assert footer_count(html) == 0

      {html, state} =
        tracked_render(%{link: "/docs", other: 1, __changed__: %{link: true}}, state)

      assert footer_count(html) == 1
      assert html =~ ~s(href="/docs")

      {html, state} =
        tracked_render(%{link: "/docs", other: 2, __changed__: %{other: true}}, state)

      assert footer_count(html) == 1
      assert html =~ ~s(href="/docs")
      assert html =~ "Projects 2"

      {html, _state} = tracked_render(%{link: nil, other: 2, __changed__: %{link: true}}, state)
      assert footer_count(html) == 0
    end
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
