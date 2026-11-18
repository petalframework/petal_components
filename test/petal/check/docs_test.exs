defmodule PetalComponents.Check.DocsTest do
  # Keeps the checker, the guide and the task docs saying the same thing.
  use PetalComponents.CheckCase, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import PetalComponents.Field

  alias PetalComponents.Check

  @guide File.read!("guides/design.md")

  defp guide_rows do
    [_, section] = String.split(@guide, "## 11. Reviewing a diff by hand", parts: 2)
    [section | _] = String.split(section, "\n## 12.", parts: 2)

    for [_, n, title] <- Regex.scan(~r/^(\d+)\. \*\*(.+?)\*\*/m, section), into: %{} do
      {n, title}
    end
  end

  defp moduledoc do
    {:docs_v1, _, _, _, %{"en" => doc}, _, _} = Code.fetch_docs(Mix.Tasks.Petal.Check)
    doc
  end

  test "every rule names a real guide row whose title has its keyword" do
    rows = guide_rows()
    assert map_size(rows) == 13

    for rule <- Check.rules() do
      case String.split(rule.section, ".") do
        ["11", n] ->
          title = Map.fetch!(rows, n)

          assert String.downcase(title) =~ String.downcase(rule.row_keyword),
                 "#{rule.id}: row #{n} is #{title}"

        [n] ->
          assert @guide =~ ~r/^## #{n}\. /m, "#{rule.id}: no section #{n}"
      end
    end
  end

  test "the not-checked rows exist in the guide" do
    rows = guide_rows()

    for {"11." <> n, _label} <- Check.not_checked() do
      assert Map.has_key?(rows, n)
    end
  end

  test "every rule id and the not-checked list appear in the task docs" do
    doc = moduledoc()
    for id <- Check.rule_ids(), do: assert(doc =~ id, "#{id} missing from the moduledoc")

    labels =
      Check.not_checked() |> Enum.map(&elem(&1, 1)) |> Enum.reject(&(&1 == "unknown attrs"))

    assert String.replace(doc, ~r/\s+/, " ") =~
             "this command (see guides/design.md section 11): " <> Enum.join(labels, ", ")
  end

  test "class names in a rule's good examples are ones the guide or default.css uses" do
    css = File.read!("assets/default.css")

    for rule <- Check.rules(),
        {:good, example} <- rule.examples,
        [_, classes] <- Regex.scan(~r/class="([^"]*)"/, example),
        class <- String.split(classes) do
      assert @guide =~ class or css =~ class,
             "#{rule.id}: #{class} is in neither the guide nor default.css"
    end
  end

  test "the shipped check code holds no literal colour utility or heroicon name" do
    # Tailwind scans deps/petal_components for class names in every app, so a
    # literal one here would add CSS to all of them.
    files =
      Path.wildcard("lib/petal_components/check/**/*.ex") ++
        ["lib/petal_components/check.ex", "lib/mix/tasks/petal.check.ex"]

    assert length(files) > 10

    palette =
      ~w(slate zinc neutral stone gray red green emerald yellow amber sky blue white black primary danger success warning info)

    props =
      ~w(bg text border ring fill stroke outline divide from via to shadow accent caret decoration placeholder)

    utility = ~r/\b(?:#{Enum.join(props, "|")})-(?:#{Enum.join(palette, "|")})(?:-\d+)?\b/
    icon = ~r/\bhero-[a-z]/

    for file <- files,
        {line, n} <- file |> File.read!() |> String.split("\n") |> Enum.with_index(1) do
      refute line =~ utility, "#{file}:#{n} has a literal utility: #{line}"
      refute line =~ icon, "#{file}:#{n} has a literal heroicon name: #{line}"
    end
  end

  defp guide_table do
    [_, block] = String.split(@guide, "### Run the machine checks first", parts: 2)
    [block | _] = String.split(block, "\n### ", parts: 2)

    for [_, id, sev, checks] <-
          Regex.scan(~r/^\| `([a-z0-9-]+)` \| (error|warning) \| (.+) \|$/m, block),
        into: %{} do
      {id, {String.to_atom(sev), checks}}
    end
  end

  test "the guide's rule table lists every rule with its severity and section" do
    table = guide_table()
    assert Enum.sort(Map.keys(table)) == Enum.sort(Check.rule_ids())

    for rule <- Check.rules() do
      {sev, checks} = Map.fetch!(table, rule.id)
      assert sev == rule.severity, "#{rule.id}: the guide says #{sev}, the code #{rule.severity}"

      expected =
        case String.split(rule.section, ".") do
          ["11", row] -> "row #{row}"
          [n] -> "section #{n}"
        end

      assert String.starts_with?(checks, expected), "#{rule.id}: the guide says #{checks}"
    end
  end

  test "the guide names exactly the rows the command leaves to a person" do
    rows = for {"11." <> n, _} <- Check.not_checked(), do: n

    assert @guide =~
             "Rows #{Enum.join(Enum.drop(rows, -1), ", ")} and #{List.last(rows)} need judgment"
  end

  test "--explain names the guide section of every rule" do
    for rule <- Check.rules() do
      text = Enum.join(PetalComponents.Check.Format.explain_text(rule), "\n")
      assert text =~ "Guide: guides/design.md section "
      assert text =~ "#{rule.id} (#{rule.severity})"
    end

    assert PetalComponents.Check.Format.guide_ref("11.10") ==
             "guides/design.md section 11, row 10"

    assert PetalComponents.Check.Format.guide_ref("8") == "guides/design.md section 8"
  end

  test "the usage rules and the skill's review playbook tell your agent to run it" do
    rules = File.read!("usage-rules.md")
    assert rules =~ "Run `mix petal.check --strict --changed` after you change templates or CSS."
    assert File.read!("skills/petal-design/references/review.md") =~ "mix petal.check --strict"
    assert File.read!("README.md") =~ "## Check your markup"
  end

  test "both agent instructions say to run it from an umbrella root" do
    {:docs_v1, _, _, _, %{"en" => doc}, _, _} = Code.fetch_docs(Mix.Tasks.Petal.Check)

    for text <- [doc, File.read!("usage-rules.md")] do
      assert text =~ "run it from the umbrella root"
      assert text =~ "could not compile dependency"
    end
  end

  test "the jason requirement admits no version without Jason.OrderedObject (1.3)" do
    req = Mix.Project.config()[:deps] |> Enum.find(&(elem(&1, 0) == :jason)) |> elem(1)
    refute Version.match?("1.2.4", req)
    assert Version.match?("1.3.0", req)
  end

  describe "behaviour the rules rely on" do
    test "bang-utility: h1 to h5 have the no_margin attr its fix names" do
      for name <- ~w(h1 h2 h3 h4 h5)a do
        attrs = PetalComponents.Typography.__components__()[name].attrs
        assert Enum.any?(attrs, &(&1.name == :no_margin)), "#{name} has no no_margin attr"
      end
    end

    test "legacy-dropdown: its fixes are the ones the dropdown docs give" do
      attrs = PetalComponents.Dropdown.__components__()[:dropdown].attrs
      doc = fn name -> Enum.find(attrs, &(&1.name == name)).doc end

      for {{old, value}, {new, new_value}} <- PetalComponents.Check.Rules.LegacyDropdown.mapping() do
        assert doc.(String.to_atom(old)) =~ ~s("#{value}" is #{new}="#{new_value}"),
               "the #{old} doc no longer says #{value} is #{new}=#{new_value}"
      end
    end

    test "combobox-variant: variant does nothing on <.field type=\"combobox\">" do
      assigns = %{form: Phoenix.Component.to_form(%{"city" => "syd"}, as: :user)}

      with_variant =
        rendered_to_string(~H"""
        <.field type="combobox" field={@form[:city]} options={[{"Sydney", "syd"}]} variant="trigger" />
        """)

      without =
        rendered_to_string(~H"""
        <.field type="combobox" field={@form[:city]} options={[{"Sydney", "syd"}]} />
        """)

      trigger =
        rendered_to_string(~H"""
        <.field
          type="combobox"
          field={@form[:city]}
          options={[{"Sydney", "syd"}]}
          combo_variant="trigger"
        />
        """)

      assert with_variant == without
      refute trigger == without
    end

    test "literal-neutral: gray is a ramp the library defines" do
      css = File.read!("assets/default.css")

      for stop <- ~w(50 100 200 300 400 500 600 700 800 900 950),
          do: assert(css =~ "--color-gray-#{stop}:")
    end
  end
end
