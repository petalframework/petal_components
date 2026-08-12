defmodule PetalComponents.TreeTest do
  use ComponentCase

  import PetalComponents.Tree

  # Four levels deep on purpose: recursion is the whole trick in this component,
  # so every structural assertion below runs against a tree that actually nests.
  defp deep_items do
    [
      %{
        id: "lib",
        label: "lib",
        children: [
          %{
            id: "petal",
            label: "petal",
            children: [
              %{
                id: "components",
                label: "components",
                children: [%{id: "button.ex", label: "button.ex"}]
              }
            ]
          },
          %{id: "petal.ex", label: "petal.ex"}
        ]
      },
      %{id: "mix.exs", label: "mix.exs"},
      %{id: "README.md", label: "README.md"}
    ]
  end

  defp nodes(html), do: html |> parse_html() |> LazyHTML.query("[data-pc-tree-node]")

  defp node_by_id(html, id) do
    html |> parse_html() |> LazyHTML.query(~s|[data-node-id="#{id}"]|)
  end

  defp at(lazy, name), do: lazy |> LazyHTML.attribute(name) |> List.first()

  describe "structure and recursion" do
    test "renders nested items to four levels with DOM nesting matching the data" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" label="Files" items={@items} default_expanded={:all} />
        """)

      assert html =~ ~s|role="tree"|
      assert html =~ ~s|aria-label="Files"|
      assert Enum.count(nodes(html)) == 7

      # the deepest leaf is reachable only through three nested role="group" lists
      deepest =
        html
        |> parse_html()
        |> LazyHTML.query(
          ~s|[data-node-id="lib"] [role="group"] [data-node-id="petal"] [role="group"] | <>
            ~s|[data-node-id="components"] [role="group"] [data-node-id="button.ex"]|
        )

      assert Enum.count(deepest) == 1
    end

    test "renders a single node" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={[%{id: "only", label: "Only"}]} />
        """)

      assert Enum.count(nodes(html)) == 1
      assert html =~ "Only"
    end

    test "an empty children list makes a leaf, not an empty branch" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={[%{id: "a", label: "A", children: []}]} />
        """)

      assert html =~ "pc-tree__chevron--leaf"
      refute html =~ ~s|role="group"|
      refute html =~ "aria-expanded"
    end

    test "groups are role=group and only branches have them" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} default_expanded={:all} />
        """)

      groups = html |> parse_html() |> LazyHTML.query(~s|[role="group"]|)
      assert Enum.count(groups) == 3
    end
  end

  describe "aria-level, aria-setsize and aria-posinset" do
    test "are exact across siblings and depths" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} default_expanded={:all} />
        """)

      # three roots
      assert at(node_by_id(html, "lib"), "aria-level") == "1"
      assert at(node_by_id(html, "lib"), "aria-posinset") == "1"
      assert at(node_by_id(html, "lib"), "aria-setsize") == "3"

      assert at(node_by_id(html, "mix.exs"), "aria-posinset") == "2"
      assert at(node_by_id(html, "README.md"), "aria-posinset") == "3"
      assert at(node_by_id(html, "README.md"), "aria-setsize") == "3"

      # two children under lib
      assert at(node_by_id(html, "petal"), "aria-level") == "2"
      assert at(node_by_id(html, "petal"), "aria-posinset") == "1"
      assert at(node_by_id(html, "petal"), "aria-setsize") == "2"
      assert at(node_by_id(html, "petal.ex"), "aria-posinset") == "2"

      # one child each the rest of the way down
      assert at(node_by_id(html, "components"), "aria-level") == "3"
      assert at(node_by_id(html, "components"), "aria-setsize") == "1"
      assert at(node_by_id(html, "button.ex"), "aria-level") == "4"
      assert at(node_by_id(html, "button.ex"), "aria-posinset") == "1"
      assert at(node_by_id(html, "button.ex"), "aria-setsize") == "1"
    end
  end

  describe "aria-expanded" do
    test "branches carry it, leaves omit it entirely" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} default_expanded={["lib"]} />
        """)

      assert at(node_by_id(html, "lib"), "aria-expanded") == "true"
      assert at(node_by_id(html, "petal"), "aria-expanded") == "false"
      assert at(node_by_id(html, "mix.exs"), "aria-expanded") == nil
      assert at(node_by_id(html, "petal.ex"), "aria-expanded") == nil
    end

    test "default_expanded: :all expands every branch" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} default_expanded={:all} />
        """)

      for id <- ~w(lib petal components) do
        assert at(node_by_id(html, id), "aria-expanded") == "true"
        assert at(node_by_id(html, id), "data-expanded") == "true"
      end
    end

    test "default_expanded: [] leaves everything collapsed" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} />
        """)

      assert at(node_by_id(html, "lib"), "aria-expanded") == "false"
      assert at(node_by_id(html, "petal"), "aria-expanded") == "false"
    end

    test "server-controlled :expanded overrides default_expanded and takes a MapSet" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree
          id="t"
          items={@items}
          default_expanded={:all}
          expanded={MapSet.new(["lib"])}
          on_expand="toggle"
        />
        """)

      assert at(node_by_id(html, "lib"), "aria-expanded") == "true"
      assert at(node_by_id(html, "petal"), "aria-expanded") == "false"
    end
  end

  describe "expansion wiring" do
    test "client-side mode toggles both attributes with LiveView.JS" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} />
        """)

      chevron =
        html |> parse_html() |> LazyHTML.query("[data-pc-tree-chevron]") |> Enum.at(0)

      click = at(chevron, "phx-click")
      assert click =~ "toggle_attr"
      assert click =~ "aria-expanded"
      assert click =~ "data-expanded"
      assert click =~ "#t-node-lib"
    end

    test "server-controlled mode pushes the event name with the node id" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} expanded={["lib"]} on_expand="toggle" target="#panel" />
        """)

      chevron =
        html |> parse_html() |> LazyHTML.query("[data-pc-tree-chevron]") |> Enum.at(0)

      assert at(chevron, "phx-click") == "toggle"
      assert at(chevron, "phx-value-id") == "lib"
      assert at(chevron, "phx-target") == "#panel"
    end
  end

  describe "selection" do
    test "the selected id gets aria-selected=true and the class, others false" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} selected="mix.exs" />
        """)

      assert at(node_by_id(html, "mix.exs"), "aria-selected") == "true"
      assert at(node_by_id(html, "mix.exs"), "class") =~ "pc-tree__item--selected"
      assert at(node_by_id(html, "lib"), "aria-selected") == "false"
      refute at(node_by_id(html, "lib"), "class") =~ "pc-tree__item--selected"
      assert count_substring(html, ~s|aria-selected="true"|) == 1
    end

    test "select_event pushes with the node id in phx-value-id" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} select_event="pick" target="#panel" />
        """)

      label = html |> parse_html() |> LazyHTML.query("[data-pc-tree-select]") |> Enum.at(0)

      assert at(label, "phx-value-id") == "lib"
      assert at(label, "phx-target") == "#panel"

      click = at(label, "phx-click")
      assert click =~ "\"push\""
      assert click =~ "pick"
    end

    test "on_select JS is composed onto the built-in selection behaviour" do
      assigns = %{items: deep_items(), on_select: Phoenix.LiveView.JS.dispatch("my:event")}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} on_select={@on_select} />
        """)

      label = html |> parse_html() |> LazyHTML.query("[data-pc-tree-select]") |> Enum.at(0)
      click = at(label, "phx-click")

      assert click =~ "my:event"
      # the built-in highlight move rides along
      assert click =~ "aria-selected"
      assert click =~ "pc-tree__item--selected"
    end
  end

  describe "guides" do
    test "show_guides renders guide elements, one per ancestor level, aria-hidden" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} default_expanded={:all} show_guides />
        """)

      assert html =~ "pc-tree--guides"

      guide_layers = html |> parse_html() |> LazyHTML.query(".pc-tree__guides")
      # one layer per node below the roots: petal, petal.ex, components, button.ex
      assert Enum.count(guide_layers) == 4
      assert Enum.all?(guide_layers, &(at(&1, "aria-hidden") == "true"))

      # depth 4 node draws three guide columns
      deep_guides =
        html
        |> parse_html()
        |> LazyHTML.query(~s|[data-node-id="button.ex"] > .pc-tree__row > .pc-tree__guides|)
        |> LazyHTML.query(".pc-tree__guide")

      assert Enum.count(deep_guides) == 3
    end

    test "guides are off by default" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} default_expanded={:all} />
        """)

      refute html =~ "pc-tree--guides"
      refute html =~ "pc-tree__guide"
    end
  end

  describe "icons" do
    test "default folder/document icons, flipping open when expanded" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} default_expanded={["lib"]} />
        """)

      assert html =~ "hero-folder-open"
      assert html =~ "hero-document"
      assert html =~ "hero-chevron-right-mini"
    end

    test "a node's :icon key overrides the default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={[%{id: "a", label: "A", icon: "hero-cog-6-tooth"}]} />
        """)

      assert html =~ "hero-cog-6-tooth"
      refute html =~ "hero-document"
    end
  end

  describe "slots" do
    test ":item renders custom content while the ARIA wiring stays intact" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} default_expanded={:all}>
          <:item :let={node}>
            <span class="custom-row">{node.label} custom</span>
          </:item>
        </.tree>
        """)

      assert html =~ "custom-row"
      assert html =~ "lib custom"
      assert html =~ "button.ex custom"
      # the component keeps the chevron, the roles and the level maths
      assert html =~ "pc-tree__chevron"
      assert at(node_by_id(html, "button.ex"), "aria-level") == "4"
      assert at(node_by_id(html, "button.ex"), "role") == "treeitem"
    end

    test ":empty renders when items is empty" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={[]}>
          <:empty>No files here.</:empty>
        </.tree>
        """)

      assert html =~ "No files here."
      assert html =~ "pc-tree__empty"
      assert Enum.empty?(nodes(html))
    end

    test "an empty tree falls back to a default empty row" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={[]} />
        """)

      assert html =~ "pc-tree__empty"
      assert html =~ "Nothing here yet."
    end

    test ":loading renders inside an expanded :lazy branch with no children yet" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tree
          id="t"
          items={[%{id: "remote", label: "remote", lazy: true}]}
          expanded={["remote"]}
          on_expand="toggle"
        >
          <:loading>Fetching...</:loading>
        </.tree>
        """)

      assert html =~ "pc-tree__loading"
      assert html =~ "Fetching..."
      # a lazy node is a branch even with no children loaded
      assert at(node_by_id(html, "remote"), "aria-expanded") == "true"
      assert html =~ ~s|role="group"|
    end

    test "a lazy branch defaults to a spinner row and drops it once children arrive" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tree
          id="t"
          items={[%{id: "remote", label: "remote", lazy: true}]}
          expanded={["remote"]}
          on_expand="toggle"
        />
        """)

      assert html =~ "pc-tree__spinner"

      html =
        rendered_to_string(~H"""
        <.tree
          id="t"
          items={[%{id: "remote", label: "remote", lazy: true, children: [%{id: "x", label: "x"}]}]}
          expanded={["remote"]}
          on_expand="toggle"
        />
        """)

      refute html =~ "pc-tree__loading"
      assert html =~ ~s|data-node-id="x"|
    end
  end

  describe "disabled nodes" do
    test "carry aria-disabled and no selection binding, but stay focusable" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tree
          id="t"
          items={[%{id: "a", label: "A", disabled: true}, %{id: "b", label: "B"}]}
          select_event="pick"
        />
        """)

      disabled = node_by_id(html, "a")
      assert at(disabled, "aria-disabled") == "true"
      assert at(disabled, "class") =~ "pc-tree__item--disabled"
      # still in the roving order per the APG
      assert at(disabled, "tabindex") == "0"

      label_a =
        html |> parse_html() |> LazyHTML.query(~s|#t-label-a|) |> Enum.at(0)

      label_b =
        html |> parse_html() |> LazyHTML.query(~s|#t-label-b|) |> Enum.at(0)

      assert at(label_a, "phx-click") == nil
      assert at(label_b, "phx-click") =~ "pick"
      assert at(node_by_id(html, "b"), "aria-disabled") == nil
    end
  end

  describe "roving tabindex" do
    test "exactly one node has tabindex=0 at render" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} default_expanded={:all} />
        """)

      assert count_substring(html, ~s|tabindex="0"|) == 1
      assert count_substring(html, ~s|tabindex="-1"|) == 6
      # first visible node when nothing is selected
      assert at(node_by_id(html, "lib"), "tabindex") == "0"
    end

    test "the selected node holds the tab stop when it is visible" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} default_expanded={:all} selected="components" />
        """)

      assert count_substring(html, ~s|tabindex="0"|) == 1
      assert at(node_by_id(html, "components"), "tabindex") == "0"
    end

    test "a selected node hidden inside a collapsed branch does not steal the tab stop" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} selected="button.ex" />
        """)

      assert count_substring(html, ~s|tabindex="0"|) == 1
      assert at(node_by_id(html, "lib"), "tabindex") == "0"
      assert at(node_by_id(html, "button.ex"), "tabindex") == "-1"
    end
  end

  describe "container" do
    test "mounts the hook and marks itself for the hook's queries" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} />
        """)

      assert html =~ ~s|phx-hook="PetalTree"|
      assert html =~ "data-pc-tree"
      assert html =~ ~s|id="t"|
    end

    test "class and rest pass through" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} class="my-tree" data-testid="files" aria-describedby="hint" />
        """)

      root = html |> parse_html() |> LazyHTML.query("#t") |> Enum.at(0)

      assert at(root, "class") =~ "my-tree"
      assert at(root, "class") =~ "pc-tree"
      assert at(root, "data-testid") == "files"
      assert at(root, "aria-describedby") == "hint"
    end

    test "each node is labelled by its own row, not the whole subtree" do
      assigns = %{items: deep_items()}

      html =
        rendered_to_string(~H"""
        <.tree id="t" items={@items} default_expanded={:all} />
        """)

      assert at(node_by_id(html, "lib"), "aria-labelledby") == "t-label-lib"
      assert html =~ ~s|id="t-label-lib"|
    end
  end
end
