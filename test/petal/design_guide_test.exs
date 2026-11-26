defmodule PetalComponents.DesignGuideTest do
  @moduledoc """
  Drift detector between the agent skill's styling doctrine
  (`skills/petal-design/references/tokens.md`) and the human guide
  (`guides/design.md`). The two are the same doctrine in two voices; this
  test fails when a token, ramp or dark-ghost stop named in the skill copy
  is missing from the guide, so whoever edits one remembers the other.
  """
  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)
  @tokens_md Path.join(@root, "skills/petal-design/references/tokens.md")
  @guide_md Path.join(@root, "guides/design.md")
  @default_css Path.join(@root, "assets/default.css")

  @ramps ~w(primary secondary info success warning danger gray)
  @ghost_stops ~w(dark:bg-gray-400/8 dark:hover:bg-gray-400/17 dark:border-gray-400/17 dark:border-gray-400/25)

  setup_all do
    %{tokens: File.read!(@tokens_md), guide: File.read!(@guide_md), css: File.read!(@default_css)}
  end

  test "every custom property named in tokens.md appears in the guide", %{
    tokens: tokens,
    guide: guide
  } do
    # `--color-primary-{50..950}` is a family; its name is `--color-primary`.
    names =
      ~r/--[a-z][a-z0-9-]*[a-z0-9]/
      |> Regex.scan(tokens)
      |> List.flatten()
      |> Enum.map(&String.replace_suffix(&1, "-", ""))
      |> Enum.uniq()
      |> Enum.sort()

    assert names != [], "tokens.md names no custom properties - did the file move?"

    missing = Enum.reject(names, &String.contains?(guide, &1))

    assert missing == [],
           "tokens.md names custom properties the guide does not mention: #{inspect(missing)}"
  end

  test "the seven ramps and the dark ghost ladder appear in both copies", %{
    tokens: tokens,
    guide: guide
  } do
    for ramp <- @ramps do
      assert tokens =~ "--color-#{ramp}-", "tokens.md lost the #{ramp} ramp"
      assert guide =~ "--color-#{ramp}-", "guides/design.md lost the #{ramp} ramp"
    end

    for stop <- @ghost_stops do
      assert tokens =~ stop, "tokens.md lost #{stop}"
      assert guide =~ stop, "guides/design.md lost #{stop}"
    end
  end

  test "the border grammar sentence is the same in both copies", %{
    tokens: tokens,
    guide: guide
  } do
    line = fn text ->
      text |> String.split("\n") |> Enum.filter(&String.starts_with?(&1, "Border grammar:"))
    end

    assert [sentence] = line.(tokens), "tokens.md should hold one 'Border grammar:' line"
    assert line.(guide) == [sentence], "the 'Border grammar:' lines differ; change both"
  end

  test "the values both copies quote are the ones default.css ships", %{css: css} do
    for stop <- @ghost_stops, do: assert(css =~ stop, "default.css no longer uses #{stop}")

    for formula <- [
          "var(--pc-radius, 0.625rem)",
          "min(var(--pc-radius, 0.625rem), 1rem)",
          "max(calc(var(--pc-radius, 0.625rem) - 0.25rem), 0.25rem)",
          "min(calc(var(--pc-radius, 0.625rem) * 1.2), 1.25rem)",
          "var(--pc-button-solid-fg, #fff)",
          "var(--pc-font-heading, var(--pc-font-body, inherit))",
          "var(--pc-font-body, inherit)"
        ] do
      assert css =~ formula, "default.css no longer contains #{formula}"
    end
  end

  test "every code fence in the guide names a language", %{guide: guide} do
    # ex_doc treats a bare ``` as Elixir and runs Makeup over it, so the ramp
    # listing and the Tailwind class string came out coloured as atoms and
    # module aliases on hexdocs. `text` renders without a lexer.
    bare =
      guide
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.filter(fn {line, _} -> String.starts_with?(line, "```") end)
      |> Enum.chunk_every(2)
      |> Enum.map(fn [{opening, line_no} | _] -> {String.trim_leading(opening, "`"), line_no} end)
      |> Enum.filter(fn {lang, _} -> lang == "" end)
      |> Enum.map(fn {_, line_no} -> line_no end)

    assert bare == [],
           "guides/design.md has language-less code fences (ex_doc highlights them as Elixir) at lines #{Enum.join(bare, ", ")}"
  end

  describe "the Design section of usage-rules.md" do
    # usage-rules.md is what `mix usage_rules.sync` copies into a project's
    # CLAUDE.md or AGENTS.md, so its Design section is often the only design
    # copy an agent reads. Every value it quotes must be one the guide quotes.
    setup do
      section =
        @root
        |> Path.join("usage-rules.md")
        |> File.read!()
        |> String.split(~r/^## /m)
        |> Enum.find(&String.starts_with?(&1, "Design\n"))

      assert section, "usage-rules.md has no \"## Design\" section"
      %{section: section}
    end

    test "quotes only values the guide quotes", %{section: section, guide: guide} do
      pointer = "deps/petal_components/guides/design.md"

      quoted =
        ~r/`([^`]+)`/
        |> Regex.scan(section, capture: :all_but_first)
        |> List.flatten()
        |> Enum.reject(&(&1 == pointer))
        |> Enum.uniq()

      assert length(quoted) >= 25, "the Design section quotes almost nothing - was it cut?"

      missing = Enum.reject(quoted, &String.contains?(guide, &1))

      assert missing == [],
             "usage-rules.md's Design section quotes values guides/design.md does not: #{inspect(missing)}"
    end

    test "points at the shipped guide and its review section", %{section: section, guide: guide} do
      assert section =~ "`deps/petal_components/guides/design.md`"
      assert section =~ ~s(section 11, "Reviewing a diff by hand")
      assert guide =~ "## 11. Reviewing a diff by hand"

      assert "guides" in Mix.Project.config()[:package][:files],
             "guides/ no longer ships in the Hex package, so the pointer is dead"
    end
  end

  test "each copy points at the other" do
    assert File.read!(@guide_md) =~ "skills/petal-design/"

    for ref <- ~w(tokens.md patterns.md review.md) do
      assert File.read!(Path.join(@root, "skills/petal-design/references/#{ref}")) =~
               "guides/design.md",
             "#{ref} does not point at guides/design.md"
    end
  end
end
