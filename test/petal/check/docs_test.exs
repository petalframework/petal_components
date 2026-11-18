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

  describe "behaviour the rules rely on" do
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
