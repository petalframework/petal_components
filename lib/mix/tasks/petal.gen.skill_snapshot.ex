defmodule Mix.Tasks.Petal.Gen.SkillSnapshot do
  @shortdoc "Regenerates the petal-design skill's schema snapshot and component inventory"

  @moduledoc """
  Regenerates the GENERATED files bundled with the petal-design skill from the
  compiled modules' `Phoenix.Component.__components__/0` metadata:

    * `skills/petal-design/data/schemas.json` - the full schema snapshot, the
      same shape and sorted-key encoding as the MCP extractor's output
    * `skills/petal-design/references/components.md` - the one-line-per-component
      inventory derived from those schemas

  It also stamps `petal_components_version:` in the skill's SKILL.md
  frontmatter, so one run refreshes every version marker the snapshot tests
  pin (`test/petal/skill_snapshot_test.exs`).

  Run from this repo at release time, right after bumping `@version` in
  mix.exs and alongside the MCP schema sync:

      mix petal.gen.skill_snapshot

  Output is deterministic apart from `generated_at`: JSON keys are sorted
  (Jason.OrderedObject) and components sort by name, so a regeneration diff
  shows real schema changes only.
  """

  use Mix.Task

  @skill_dir "skills/petal-design"

  # Icon packs and internal helpers - huge and not useful for AI component
  # suggestion. Mirrors the skip list in petal-components-mcp/scripts/extract.
  @skip_modules [
    PetalComponents.HeroiconsV1.Outline,
    PetalComponents.HeroiconsV1.Solid,
    PetalComponents.Svg,
    PetalComponents.Helpers,
    PetalComponents.PaginationInternal
  ]

  @chat_note "\nNOT imported by `use PetalComponents` - `alias PetalComponents.Chat`, then call\n" <>
               "namespaced exactly as listed below. Bare dot-calls without the namespace will not compile.\n"

  @impl Mix.Task
  def run(_argv) do
    if Mix.Project.config()[:app] != :petal_components do
      Mix.raise(
        "petal.gen.skill_snapshot regenerates petal_components' own bundled skill snapshot - " <>
          "run it from the petal_components repo, not a consuming app"
      )
    end

    Mix.Task.run("compile")
    {:ok, _} = Application.ensure_all_started(:petal_components)

    version = to_string(Mix.Project.config()[:version])
    components = extract_components()

    write_schemas(components, version)
    write_inventory(components, version)
    stamp_skill_md(version)
  end

  # ---------------------------------------------------------------------------
  # Extraction - a port of petal-components-mcp/scripts/extract, run against
  # this repo's compiled modules instead of the published Hex package.
  # ---------------------------------------------------------------------------

  defp extract_components do
    {:ok, modules} = :application.get_key(:petal_components, :modules)

    candidates =
      modules
      |> Enum.filter(&petal_module?/1)
      |> Enum.reject(&(&1 in @skip_modules))

    Enum.each(candidates, &Code.ensure_loaded/1)

    examples = showcase_examples()

    candidates
    |> Enum.flat_map(&module_components(&1, examples))
    |> Enum.sort_by(&{&1.name, &1.module})
  end

  @doc """
  Every {module, component} pair the snapshot must cover, as inspect/string
  pairs. Shared with test/petal/skill_snapshot_test.exs so the completeness
  guard and the generator can never disagree about what "all components" means.
  """
  def live_component_names do
    {:ok, modules} = :application.get_key(:petal_components, :modules)

    for module <- modules,
        petal_module?(module),
        module not in @skip_modules,
        # ensure_loaded first: function_exported?/3 is false for compiled but
        # not-yet-loaded modules, which would silently shrink the live set
        Code.ensure_loaded?(module),
        function_exported?(module, :__components__, 0),
        {name, _meta} <- Map.new(module.__components__(), &published_entry(module, &1)),
        into: MapSet.new() do
      {inspect(module), to_string(name)}
    end
  end

  defp petal_module?(module) do
    case Module.split(module) do
      # The Showcase namespace is docs tooling (the example gallery + its
      # frame), not app vocabulary - keep it out of the catalogue so an
      # assistant never suggests <.showcase_example> inside a user's app.
      ["PetalComponents", "Showcase" | _] -> false
      ["PetalComponents" | _] -> true
      _ -> false
    end
  end

  defp module_components(module, examples) do
    if Code.ensure_loaded?(module) and function_exported?(module, :__components__, 0) do
      components = Map.new(module.__components__(), &published_entry(module, &1))
      siblings = Map.keys(components)

      Enum.map(components, fn {name, meta} ->
        build_component(module, name, meta, examples, siblings)
      end)
    else
      []
    end
  end

  # PetalComponents.Icon compiles two ways. Published to Hex (no heroicons
  # dep) the attrs are declared straight on `def icon`; in this repo the same
  # attrs live on `defp heroicon` and `def icon` is a generated per-icon
  # dispatcher, so `icon` never appears in __components__/0. The snapshot
  # documents the public API, so rewrite the dev-only heroicon entry to the
  # icon component it backs.
  defp published_entry(PetalComponents.Icon, {:heroicon, meta}),
    do: {:icon, Map.put(meta, :kind, :def)}

  defp published_entry(_module, entry), do: entry

  defp build_component(module, name, meta, examples, siblings) do
    %{
      name: to_string(name),
      module: inspect(module),
      kind: meta[:kind] || :def,
      attrs: Enum.map(meta[:attrs] || [], &build_attr/1),
      slots: Enum.map(meta[:slots] || [], &build_slot/1),
      examples: component_examples(examples, module, name, siblings)
    }
  end

  # An example belongs to a component only when its code actually renders that
  # component's tag (`<.name` or `<Alias.name`). Matching on the showcase
  # module alone would copy the full example set onto every sibling function
  # of multi-component modules like chat and command.
  #
  # Compositions that use a component in passing are kept - seeing a part in a
  # realistic whole is how these components are meant to be learned - but
  # ordered last: the fewer sibling components an example touches, the more
  # focused it is on the one being asked about, so it sorts first (stable, so
  # author order breaks ties).
  defp component_examples(examples, module, name, siblings) do
    examples
    |> Map.get(inspect(module), [])
    |> Enum.filter(&example_uses?(&1, name))
    |> Enum.sort_by(&focus_score(&1, siblings))
    |> Enum.map(&namespace_chat_calls(&1, module, siblings))
  end

  # The Chat family is not imported by `use PetalComponents` - callers need
  # `alias PetalComponents.Chat` and `<Chat.name>` tags. The showcase sources
  # call siblings bare (those modules import the family directly), so a copied
  # example would not compile in a normal web module. Rewrite sibling tags to
  # the namespaced form; imported components used in passing (<.icon>, ...)
  # keep their bare calls.
  defp namespace_chat_calls(example, module, siblings) do
    if List.last(Module.split(module)) == "Chat" do
      names = Enum.map_join(siblings, "|", &Regex.escape(to_string(&1)))
      %{example | code: Regex.replace(~r{<(/?)\.(#{names})\b}, example.code, "<\\1Chat.\\2")}
    else
      example
    end
  end

  defp focus_score(example, siblings) do
    Enum.count(siblings, &example_uses?(example, &1))
  end

  defp example_uses?(%{code: code}, name) do
    Regex.match?(~r/<(?:[A-Z][\w.]*\.|\.)#{Regex.escape(to_string(name))}[\s\/>]/, code)
  end

  defp build_attr(attr) do
    %{
      name: to_string(attr.name),
      type: inspect(attr.type),
      required: attr.required || false,
      default: inspect_safe(attr[:opts][:default]),
      values: attr[:opts][:values],
      doc: attr.doc
    }
  end

  defp build_slot(slot) do
    %{
      name: to_string(slot.name),
      required: slot.required || false,
      doc: slot.doc,
      attrs: Enum.map(slot[:attrs] || [], &build_attr/1)
    }
  end

  # The Showcase registry holds curated, compile-checked examples - the same
  # blocks the playground and petal.build render, so they can't drift from the
  # real components. The showcase modules themselves stay out of the catalogue
  # (see petal_module?/1), but their source is exactly what an assistant should
  # copy, so we attach it to the component each module documents.
  defp showcase_examples do
    registry = PetalComponents.Showcase.Registry

    if Code.ensure_loaded?(registry) and function_exported?(registry, :all, 0) do
      Enum.reduce(registry.all(), %{}, &add_showcase_examples/2)
    else
      %{}
    end
  end

  defp add_showcase_examples(module, acc) do
    Code.ensure_loaded(module)
    target = showcase_target(module)
    examples = build_examples(module)

    if target && examples != [] do
      Map.update(acc, target, examples, &(&1 ++ examples))
    else
      acc
    end
  end

  defp showcase_target(module) do
    if function_exported?(module, :showcase_component, 0) do
      case module.showcase_component() do
        nil -> nil
        component -> inspect(component)
      end
    end
  end

  defp build_examples(module) do
    if function_exported?(module, :examples, 0) do
      Enum.map(module.examples(), fn ex ->
        %{title: ex.title, description: ex.description, code: ex.code}
      end)
    else
      []
    end
  end

  defp inspect_safe(nil), do: nil
  defp inspect_safe(value), do: inspect(value)

  # ---------------------------------------------------------------------------
  # data/schemas.json
  # ---------------------------------------------------------------------------

  defp write_schemas(components, version) do
    output = %{
      version: version,
      generated_at: DateTime.to_iso8601(DateTime.utc_now()),
      components: components
    }

    path = Path.join(@skill_dir, "data/schemas.json")
    File.write!(path, Jason.encode!(deterministic(output), pretty: true))
    Mix.shell().info("Wrote #{length(components)} components to #{path}")
  end

  # Atom-keyed map iteration follows the atom table, which shifts with OTP
  # version and module load order - so regenerating on a different toolchain
  # would rewrite every line of schemas.json and bury the real changes.
  # Sorting keys makes the emitted JSON byte-stable across environments.
  defp deterministic(%{} = map) when not is_struct(map) do
    map
    |> Enum.map(fn {key, value} -> {to_string(key), deterministic(value)} end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Jason.OrderedObject.new()
  end

  defp deterministic(list) when is_list(list), do: Enum.map(list, &deterministic/1)
  defp deterministic(other), do: other

  # ---------------------------------------------------------------------------
  # references/components.md
  # ---------------------------------------------------------------------------

  defp write_inventory(components, version) do
    path = Path.join(@skill_dir, "references/components.md")
    File.write!(path, inventory_markdown(components, version))
    Mix.shell().info("Wrote component inventory to #{path}")
  end

  defp inventory_markdown(components, version) do
    header = """
    # Component inventory - petal_components v#{version}

    GENERATED from data/schemas.json - do not hand-edit. Regenerated each release
    by `mix petal.gen.skill_snapshot`, alongside the MCP schema sync.

    One line per public function component, grouped by module - use this to PICK a
    component. To USE one, resolve its full schema via the MCP ladder in SKILL.md
    (MCP -> data/schemas.json -> deps source); never write attrs from memory.
    Function names have NO pc_ prefix; pc- is the CSS class prefix only.
    """

    sections =
      components
      |> Enum.filter(&(&1.kind == :def))
      |> Enum.group_by(&String.replace_prefix(&1.module, "PetalComponents.", ""))
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map_join(fn {group, comps} -> section(group, comps) end)

    header <> sections
  end

  # The inventory renders Chat calls namespaced so a copied tag compiles as-is
  # (skill_snapshot_test pins this).
  defp section("Chat", comps), do: "\n## Chat\n" <> @chat_note <> lines(comps, "Chat.")
  defp section(group, comps), do: "\n## #{group}\n" <> lines(comps, ".")

  defp lines(comps, prefix) do
    comps
    |> Enum.sort_by(& &1.name)
    |> Enum.map_join(&(line(&1, prefix) <> "\n"))
  end

  defp line(comp, prefix) do
    "- `<#{prefix}#{comp.name}>` - #{length(comp.attrs)} attrs, #{length(comp.slots)} slots" <>
      required_suffix("required", comp.attrs) <>
      required_suffix("required slots", comp.slots)
  end

  defp required_suffix(label, entries) do
    case entries |> Enum.filter(& &1.required) |> Enum.map(& &1.name) |> Enum.sort() do
      [] -> ""
      names -> " · #{label}: " <> Enum.join(names, ", ")
    end
  end

  # ---------------------------------------------------------------------------
  # SKILL.md frontmatter
  # ---------------------------------------------------------------------------

  # SKILL.md is hand-authored, but its frontmatter pins the version the
  # bundled snapshot was generated from - stamp it so a release bump can't
  # leave it behind.
  defp stamp_skill_md(version) do
    path = Path.join(@skill_dir, "SKILL.md")

    stamped =
      Regex.replace(
        ~r/^petal_components_version: .*$/m,
        File.read!(path),
        "petal_components_version: #{version}"
      )

    File.write!(path, stamped)
    Mix.shell().info("Stamped petal_components_version: #{version} in #{path}")
  end
end
