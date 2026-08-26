defmodule PetalComponents.SkillSnapshotTest do
  use ExUnit.Case, async: true

  # The petal-design skill ships a schema snapshot and a generated component
  # inventory. Both are regenerated at release time alongside the MCP schema
  # sync. These tests make a stale snapshot fail the release commit's CI
  # instead of shipping doctrine for the wrong version.

  @skill Path.expand("../../skills/petal-design", __DIR__)
  @version Mix.Project.config()[:version]

  test "the bundled schema snapshot matches the package version" do
    %{"version" => v} = @skill |> Path.join("data/schemas.json") |> File.read!() |> Jason.decode!()

    assert v == @version,
           "skills/petal-design/data/schemas.json is v#{v} but the package is v#{@version} - regenerate it (see the release runbook)"
  end

  test "SKILL.md frontmatter and the generated inventory carry the package version" do
    skill_md = @skill |> Path.join("SKILL.md") |> File.read!()
    assert skill_md =~ "petal_components_version: #{@version}"

    inventory = @skill |> Path.join("references/components.md") |> File.read!()
    assert inventory =~ "petal_components v#{@version}"
  end

  test "every reference file SKILL.md names exists" do
    skill_md = @skill |> Path.join("SKILL.md") |> File.read!()

    for ref <- Regex.scan(~r/`(references\/[a-z_-]+\.md|data\/[a-z_.]+\.json)`/, skill_md, capture: :all_but_first),
        [path] = ref do
      assert File.exists?(Path.join(@skill, path)), "SKILL.md references missing file: #{path}"
    end
  end
end
