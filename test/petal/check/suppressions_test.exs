defmodule PetalComponents.Check.SuppressionsTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Rules.ComboboxVariant
  alias PetalComponents.Check.Rules.LiteralNeutral
  alias PetalComponents.Check.Suppressions

  @rules [LiteralNeutral, ComboboxVariant]

  defp t, do: Enum.join(["bg", "zinc", "100"], "-")

  defp run(files, opts \\ []),
    do: run_files(files, Keyword.put_new(opts, :rules, @rules)).findings

  defp statuses(fs),
    do: fs |> Enum.reject(& &1.meta) |> Enum.map(&{&1.rule, &1.line, &1.status}) |> Enum.sort()

  defp meta(fs), do: fs |> Enum.filter(& &1.meta) |> Enum.map(&{&1.rule, &1.line}) |> Enum.sort()

  test "directive grammar" do
    assert %{kind: :ignore, rules: ["a", "b-c"], reason: "why"} =
             Suppressions.directive("# petal-check:ignore a, b-c: why")

    assert %{kind: :disable, rules: ["a"], reason: nil} =
             Suppressions.directive(" petal-check:disable a ")

    assert {:invalid, _} = Suppressions.directive("# petal-check:ignore")
    assert {:invalid, _} = Suppressions.directive("# petal-check:skip a")
    assert Suppressions.directive("# nothing here") == nil
  end

  test "an Elixir ignore covers the next line only" do
    src =
      "defmodule A do\n  # petal-check:ignore literal-neutral: demo\n  def a, do: \"#{t()}\"\n  def b, do: \"#{t()}\"\nend\n"

    fs = run(%{"lib/a.ex" => src})
    assert statuses(fs) == [{"literal-neutral", 3, :suppressed}, {"literal-neutral", 4, :new}]
    assert meta(fs) == []
  end

  test "a trailing ignore covers its own line" do
    src =
      "defmodule A do\n  def a, do: \"#{t()}\" # petal-check:ignore literal-neutral: demo\n  def b, do: \"#{t()}\"\nend\n"

    assert statuses(run(%{"lib/a.ex" => src})) == [
             {"literal-neutral", 2, :suppressed},
             {"literal-neutral", 3, :new}
           ]
  end

  test "a HEEx ignore above a multi-line tag covers an attr on its last line" do
    heex = """
    <%!-- petal-check:ignore literal-neutral: a deliberate demo --%>
    <.button
      phx-click="go"
      size="sm"
      class="#{t()}"
    >
      Go
    </.button>
    <p class="#{t()}"></p>
    """

    fs = run(%{"lib/a.html.heex" => heex})
    assert statuses(fs) == [{"literal-neutral", 5, :suppressed}, {"literal-neutral", 9, :new}]
  end

  test "the same, for a component rule, inside a ~H heredoc" do
    src =
      in_module(
        "<%!-- petal-check:ignore combobox-variant: legacy form --%>\n<.field\n  type=\"combobox\"\n  variant=\"input\"\n/>"
      )

    assert [{"combobox-variant", 9, :suppressed}] = statuses(run(%{"lib/a.ex" => src}))
  end

  test "a CSS ignore" do
    css = ".x {\n  /* petal-check:ignore literal-neutral: brand panel */\n  @apply #{t()};\n}\n"
    assert statuses(run(%{"assets/css/app.css" => css})) == [{"literal-neutral", 3, :suppressed}]
  end

  test "disable and enable make a range" do
    heex =
      "<%!-- petal-check:disable literal-neutral: before/after demo --%>\n<p class=\"#{t()}\"></p>\n<p class=\"#{t()}\"></p>\n<%!-- petal-check:enable literal-neutral --%>\n<p class=\"#{t()}\"></p>\n"

    fs = run(%{"lib/a.html.heex" => heex})

    assert statuses(fs) == [
             {"literal-neutral", 2, :suppressed},
             {"literal-neutral", 3, :suppressed},
             {"literal-neutral", 5, :new}
           ]

    assert meta(fs) == []
  end

  test "a disable with no enable lasts to the end of the file and is reported" do
    heex = "<%!-- petal-check:disable literal-neutral: demo --%>\n<p class=\"#{t()}\"></p>\n"
    fs = run(%{"lib/a.html.heex" => heex})
    assert statuses(fs) == [{"literal-neutral", 2, :suppressed}]
    assert meta(fs) == [{"unclosed-disable", 1}]
  end

  test "an ignore with no reason still works and is reported" do
    heex = "<%!-- petal-check:ignore literal-neutral --%>\n<p class=\"#{t()}\"></p>\n"
    fs = run(%{"lib/a.html.heex" => heex})
    assert statuses(fs) == [{"literal-neutral", 2, :suppressed}]
    assert meta(fs) == [{"suppression-without-reason", 1}]
  end

  test "unused, unknown, invalid and misplaced directives are warnings" do
    heex = """
    <%!-- petal-check:ignore literal-neutral: nothing below --%>
    <p class="p-2"></p>
    <%!-- petal-check:ignore no-such-rule: x --%>
    <%!-- petal-check:ignore --%>
    <!-- petal-check:ignore literal-neutral: in html -->
    <p class="#{t()}"></p>
    """

    fs = run(%{"lib/a.html.heex" => heex})

    assert meta(fs) == [
             {"invalid-suppression", 4},
             {"misplaced-suppression", 5},
             {"unknown-rule", 3},
             {"unused-suppression", 1}
           ]

    assert statuses(fs) == [{"literal-neutral", 6, :new}]
    assert Enum.all?(Enum.filter(fs, & &1.meta), &(&1.severity == :warning))
  end

  test "a directive quoted in a string is not a directive" do
    src =
      "defmodule A do\n  def doc, do: \"# petal-check:ignore literal-neutral: x\"\n  def a, do: \"#{t()}\"\nend\n"

    fs = run(%{"lib/a.ex" => src})
    assert statuses(fs) == [{"literal-neutral", 3, :new}]
    assert meta(fs) == []
  end

  test "a rule that did not run never makes its suppression unused" do
    heex = "<%!-- petal-check:ignore literal-neutral: demo --%>\n<p class=\"#{t()}\"></p>\n"
    fs = run(%{"lib/a.html.heex" => heex}, only: ["combobox-variant"])
    assert fs == []
  end

  test "suppressed findings are counted in the summary" do
    heex = "<%!-- petal-check:ignore literal-neutral: demo --%>\n<p class=\"#{t()}\"></p>\n"
    r = run_files(%{"lib/a.html.heex" => heex}, rules: @rules, strict: true)
    assert r.exit_status == 0

    assert Enum.join(PetalComponents.Check.Format.text(r), "\n") =~
             "0 new errors, 0 new warnings, 0 baselined, 1 suppressed"
  end
end
