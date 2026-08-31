defmodule PetalComponents.SkillSnapshotTest do
  use ExUnit.Case, async: true

  # The petal-design skill ships a schema snapshot and a generated component
  # inventory. Both are regenerated at release time alongside the MCP schema
  # sync. These tests make a stale snapshot fail the release commit's CI
  # instead of shipping doctrine for the wrong version.

  @skill Path.expand("../../skills/petal-design", __DIR__)
  @version Mix.Project.config()[:version]

  test "the bundled schema snapshot matches the package version" do
    %{"version" => v} =
      @skill |> Path.join("data/schemas.json") |> File.read!() |> Jason.decode!()

    assert v == @version,
           "skills/petal-design/data/schemas.json is v#{v} but the package is v#{@version} - regenerate it (see the release runbook)"
  end

  test "SKILL.md frontmatter and the generated inventory carry the package version" do
    skill_md = @skill |> Path.join("SKILL.md") |> File.read!()
    assert skill_md =~ "petal_components_version: #{@version}"

    inventory = @skill |> Path.join("references/components.md") |> File.read!()
    assert inventory =~ "petal_components v#{@version}"
  end

  test "the snapshot's attrs and slots match the live modules" do
    # Version labels alone can lie: the file can carry the right version while
    # its content drifted from the code. Introspect every component the
    # snapshot claims and diff attr/slot name sets against __components__/0.
    %{"components" => components} =
      @skill |> Path.join("data/schemas.json") |> File.read!() |> Jason.decode!()

    for %{"module" => mod_string, "name" => name} = snap <- components do
      module = Module.concat([mod_string])

      case Enum.find(module.__components__(), fn {key, _} -> to_string(key) == name end) do
        nil ->
          # A few components are plain wrapper functions with no attr/slot
          # declarations of their own (<.icon> wraps the declared :heroicon).
          # Those have no introspectable schema to diff - but the function
          # itself disappearing means the snapshot ships a dead component.
          assert function_exported?(module, String.to_atom(name), 1),
                 "#{mod_string}.#{name} no longer exists - snapshot drifted, regenerate it"

        {_key, live} ->
          # Names alone are not the contract: a type, enum, default, or
          # required flag can change under an unchanged name and the snapshot
          # would still advertise the obsolete schema. Compare the full shape
          # the extractor serializes (type/default via inspect, values
          # normalized to strings). Doc text is deliberately not compared.
          live_attrs = Map.new(live.attrs, &{to_string(&1.name), &1})
          snap_attrs = Map.new(snap["attrs"] || [], &{&1["name"], &1})

          assert Enum.sort(Map.keys(live_attrs)) == Enum.sort(Map.keys(snap_attrs)),
                 "#{mod_string}.#{name} attr names drifted from data/schemas.json - regenerate. " <>
                   "live-only: #{inspect(Map.keys(live_attrs) -- Map.keys(snap_attrs))}, " <>
                   "snapshot-only: #{inspect(Map.keys(snap_attrs) -- Map.keys(live_attrs))}"

          for {attr_name, la} <- live_attrs do
            sa = snap_attrs[attr_name]
            where = "#{mod_string}.#{name} attr #{attr_name}"

            assert inspect(la.type) == sa["type"],
                   "#{where} type drifted (live #{inspect(la.type)}, snapshot #{sa["type"]}) - regenerate the snapshot"

            assert la.required == (sa["required"] || false),
                   "#{where} required flag drifted - regenerate the snapshot"

            # the extractor serializes an explicit nil default as JSON null,
            # indistinguishable from no default - mirror that here
            live_default =
              if Keyword.has_key?(la.opts, :default) and la.opts[:default] != nil,
                do: inspect(la.opts[:default])

            assert live_default == sa["default"],
                   "#{where} default drifted (live #{inspect(live_default)}, snapshot #{inspect(sa["default"])}) - regenerate the snapshot"

            live_values = la.opts[:values] && Enum.map(la.opts[:values], &to_string/1)
            snap_values = sa["values"] && Enum.map(sa["values"], &to_string/1)

            assert live_values == snap_values,
                   "#{where} values enum drifted (live #{inspect(live_values)}, snapshot #{inspect(snap_values)}) - regenerate the snapshot"
          end

          live_slots = Map.new(live.slots, &{to_string(&1.name), &1})
          snap_slots = Map.new(snap["slots"] || [], &{&1["name"], &1})

          assert Enum.sort(Map.keys(live_slots)) == Enum.sort(Map.keys(snap_slots)),
                 "#{mod_string}.#{name} slot names drifted from data/schemas.json - regenerate the snapshot"

          for {slot_name, ls} <- live_slots do
            ss = snap_slots[slot_name]
            where = "#{mod_string}.#{name} slot #{slot_name}"

            assert (ls[:required] || false) == (ss["required"] || false),
                   "#{where} required flag drifted - regenerate the snapshot"

            live_slot_attrs =
              ls |> Map.get(:attrs, []) |> Enum.map(&to_string(&1.name)) |> Enum.sort()

            snap_slot_attrs = (ss["attrs"] || []) |> Enum.map(& &1["name"]) |> Enum.sort()

            assert live_slot_attrs == snap_slot_attrs,
                   "#{where} nested attrs drifted (live #{inspect(live_slot_attrs)}, snapshot #{inspect(snap_slot_attrs)}) - regenerate the snapshot"
          end
      end
    end
  end

  test "chat-family calls are namespaced in the inventory and snapshot examples" do
    # The Chat family is NOT imported by `use PetalComponents` - an agent that
    # copies a bare `<.conversation>` from the inventory or an example ships
    # code that does not compile. Regeneration must keep these namespaced.
    %{"components" => components} =
      @skill |> Path.join("data/schemas.json") |> File.read!() |> Jason.decode!()

    chat = Enum.filter(components, &String.ends_with?(&1["module"], ".Chat"))
    assert chat != [], "no Chat components in the snapshot - did the module move?"

    bare = ~r/<\.(#{Enum.map_join(chat, "|", & &1["name"])})\b/

    inventory = @skill |> Path.join("references/components.md") |> File.read!()
    [chat_section] = Regex.run(~r/^## Chat\n.*?(?=\n## )/ms, inventory)

    refute chat_section =~ bare,
           "components.md lists bare chat calls - render them as <Chat.name>"

    assert chat_section =~ "<Chat.", "components.md chat section lost its namespacing"

    for %{"module" => mod, "name" => name, "examples" => examples} <- chat,
        %{"code" => code} <- examples || [] do
      refute code =~ bare,
             "#{mod}.#{name} example uses a bare chat call - namespace it as <Chat....>"
    end
  end

  test "every reference file SKILL.md names exists" do
    skill_md = @skill |> Path.join("SKILL.md") |> File.read!()

    for ref <-
          Regex.scan(~r/`(references\/[a-z_-]+\.md|data\/[a-z_.]+\.json)`/, skill_md,
            capture: :all_but_first
          ),
        [path] = ref do
      assert File.exists?(Path.join(@skill, path)), "SKILL.md references missing file: #{path}"
    end
  end
end
