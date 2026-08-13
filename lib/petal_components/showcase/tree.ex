defmodule PetalComponents.Showcase.Tree do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Tree,
    title: "Tree"

  example :basic, "A project tree",
    description:
      "Nested maps in, arbitrary depth out. Branches get a chevron and folder icons, leaves get a document icon and the reserved chevron column so labels stay aligned. default_expanded seeds which branches open at first render; the chevron toggles the rest client-side, no round-trip." do
    ~H"""
    <.tree
      id="sx-tree-basic"
      label="Project files"
      default_expanded={["lib", "petal_components"]}
      items={[
        %{
          id: "lib",
          label: "lib",
          children: [
            %{
              id: "petal_components",
              label: "petal_components",
              children: [
                %{id: "button.ex", label: "button.ex"},
                %{id: "tree.ex", label: "tree.ex"}
              ]
            },
            %{id: "petal_components.ex", label: "petal_components.ex"}
          ]
        },
        %{
          id: "assets",
          label: "assets",
          children: [%{id: "default.css", label: "default.css"}]
        },
        %{id: "mix.exs", label: "mix.exs"},
        %{id: "README.md", label: "README.md"}
      ]}
    />
    """
  end

  example :guides, "Indent guides and a selected node",
    description:
      "show_guides draws a hairline down each open branch so a deep tree still reads as a hierarchy. The guides are a decorative aria-hidden layer, so screen readers never meet them. selected marks one node with aria-selected and the soft primary fill; selection is single-select and the server owns which id is current." do
    ~H"""
    <.tree
      id="sx-tree-guides"
      label="Explorer"
      show_guides
      selected="checkout.ex"
      default_expanded={:all}
      items={[
        %{
          id: "accounts",
          label: "accounts",
          children: [
            %{id: "user.ex", label: "user.ex"},
            %{
              id: "billing",
              label: "billing",
              children: [
                %{id: "checkout.ex", label: "checkout.ex"},
                %{id: "invoice.ex", label: "invoice.ex"}
              ]
            }
          ]
        },
        %{id: "application.ex", label: "application.ex"},
        %{id: "_build", label: "_build", disabled: true}
      ]}
    />
    """
  end

  example :icons, "Custom icons and a lazy branch",
    description:
      "Any node can name its own heroicon with :icon. A node marked :lazy is a branch before its children exist: expand it and the tree shows the loading row until the server hands over the children. Lazy branches need the server-controlled expansion model, so this one passes :expanded and an :on_expand event." do
    ~H"""
    <.tree
      id="sx-tree-icons"
      label="Settings"
      show_guides
      expanded={["workspace", "integrations"]}
      on_expand="toggle_branch"
      select_event="open_setting"
      selected="members"
      items={[
        %{
          id: "workspace",
          label: "Workspace",
          icon: "hero-building-office-2",
          children: [
            %{id: "general", label: "General", icon: "hero-cog-6-tooth"},
            %{id: "members", label: "Members", icon: "hero-users"},
            %{id: "billing-plan", label: "Billing", icon: "hero-credit-card"}
          ]
        },
        %{
          id: "integrations",
          label: "Integrations",
          icon: "hero-puzzle-piece",
          lazy: true
        },
        %{id: "danger", label: "Danger zone", icon: "hero-exclamation-triangle"}
      ]}
    />
    """
  end

  example :slot, "Custom rows with the :item slot",
    description:
      "The :item slot replaces the icon and label content of every row and receives the whole node map, so extra keys on your data are yours to render. The chevron, the indent, the guides and every ARIA attribute stay owned by the component - you are styling a row, not rebuilding a tree." do
    ~H"""
    <.tree
      id="sx-tree-slot"
      label="Reporting lines"
      show_guides
      default_expanded={:all}
      items={[
        %{
          id: "dana",
          label: "Dana Okafor",
          title: "VP Engineering",
          children: [
            %{
              id: "sam",
              label: "Sam Reyes",
              title: "Platform lead",
              children: [
                %{id: "kit", label: "Kit Alvarez", title: "Senior engineer"},
                %{id: "noor", label: "Noor Haddad", title: "Engineer"}
              ]
            },
            %{id: "wren", label: "Wren Costa", title: "Design lead"}
          ]
        }
      ]}
    >
      <:item :let={person}>
        <span class="flex items-center justify-center w-5 h-5 text-[10px] font-semibold rounded-full shrink-0 bg-primary-100 text-primary-700 dark:bg-primary-500/15 dark:text-primary-300">
          {String.first(person.label)}
        </span>
        <span class="font-medium">{person.label}</span>
        <span class="text-xs text-gray-500 dark:text-gray-400">{person.title}</span>
      </:item>
    </.tree>
    """
  end

  example :empty, "The empty state",
    description:
      "Nothing to show gets its own row rather than a blank box. Override the wording with the :empty slot." do
    ~H"""
    <.tree id="sx-tree-empty" label="Archived files" items={[]}>
      <:empty>No archived files. Anything you archive shows up here.</:empty>
    </.tree>
    """
  end
end
