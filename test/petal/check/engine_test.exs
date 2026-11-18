defmodule PetalComponents.Check.EngineTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check
  alias PetalComponents.Check.Rule
  alias PetalComponents.Check.Rules.ComboboxVariant
  alias PetalComponents.Check.Rules.LiteralNeutral
  alias PetalComponents.Check.Rules.RampComplete

  defp t, do: Enum.join(["bg", "zinc", "100"], "-")
  @both [LiteralNeutral, ComboboxVariant]

  defmodule Raises do
    @behaviour Rule
    def rule,
      do: %Rule{
        id: "raises",
        severity: :error,
        section: "11.1",
        row_keyword: "x",
        why: "x",
        scope: :class_unit
      }

    def check(_unit, _ctx), do: raise("boom")
  end

  defmodule RaisesProject do
    @behaviour Rule
    def rule,
      do: %Rule{
        id: "raises-project",
        severity: :error,
        section: "9",
        row_keyword: "x",
        why: "x",
        scope: :project
      }

    def collect(_source, _ctx), do: :ok
    def finish(_collected, _ctx), do: raise("boom")
  end

  defmodule Ramp do
    # A fake project rule: one finding per CSS file that defines --x-a,
    # but only when some file (anywhere under the roots) defines --x-b.
    @behaviour Rule
    def rule,
      do: %Rule{
        id: "ramp",
        severity: :error,
        section: "9",
        row_keyword: "x",
        why: "x",
        scope: :project
      }

    def collect(source, _ctx) do
      texts = Enum.map(source.statements, & &1.text)

      {source.path, Enum.any?(texts, &String.starts_with?(&1, "--x-a")),
       Enum.any?(texts, &String.starts_with?(&1, "--x-b"))}
    end

    def finish(collected, _ctx) do
      if Enum.any?(collected, &elem(&1, 2)) do
        []
      else
        for {path, true, _} <- collected,
            do:
              Rule.finding(rule(),
                path: path,
                line: 1,
                column: 1,
                subject: "x",
                message: "m",
                fix: "f"
              )
      end
    end
  end

  test "an .ex file with a syntax error is unchecked, never clean" do
    src =
      "defmodule Broken do\n  def r(assigns), do: ~H|<.dropdown placement=\"left\">x</.dropdown>|\n  def x( do\nend\n"

    r = run_files(%{"lib/broken.ex" => src}, rules: @both, strict: true)
    assert [%{kind: :parse, path: "lib/broken.ex", reason: reason}] = r.unchecked
    assert reason =~ "could not be read as Elixir"
    assert r.exit_status == 2
  end

  test "invalid UTF-8 is unchecked" do
    r = run_files(%{"lib/a.html.heex" => <<"<p>", 0xFF, "</p>">>}, rules: @both)
    assert [%{kind: :read}] = r.unchecked
  end

  test "a .heex file whose module beside it is not valid UTF-8 is still checked, no crash" do
    mod =
      <<"defmodule Comp do\n  use PetalComponents\n  embed_templates \"*\"\n  def x, do: \"",
        0xFF, "\"\nend\n">>

    src = ~s(<p class="#{t()}"></p>\n)

    r =
      run_files(%{"lib/adv/comp.ex" => mod, "lib/adv/comp.html.heex" => src},
        rules: @both,
        strict: true
      )

    assert [%{kind: :read, path: "lib/adv/comp.ex"}] = r.unchecked
    assert [%{rule: "literal-neutral", path: "lib/adv/comp.html.heex"}] = r.findings
    assert r.exit_status == 1
  end

  test "an exception outside the rules makes the file unchecked, never a crash" do
    # a petal_names that is not a MapSet breaks the scope step, before any rule
    src = "defmodule A do\n  use PetalComponents\nend\n"
    r = run_files(%{"lib/a.ex" => src}, rules: @both, petal_names: :not_a_set, strict: true)

    assert [%{kind: :internal, reason: "internal error while checking this file" <> _}] =
             r.unchecked

    assert r.exit_status == 2
  end

  test "a rule that raises makes the file unchecked, the others still run, advisory stays 0" do
    src = ~s(<p class="#{t()}"></p>\n)
    r = run_files(%{"lib/a.html.heex" => src}, rules: [Raises, LiteralNeutral])
    assert [%{kind: :internal, reason: reason}] = r.unchecked
    assert reason =~ "internal error in rule raises (please report): boom"
    assert [%{rule: "literal-neutral"}] = r.findings
    assert r.exit_status == 0

    assert run_files(%{"lib/a.html.heex" => ~s(<p class="a"></p>\n)},
             rules: [Raises],
             strict: true
           ).exit_status == 2
  end

  describe "exit codes" do
    @err ~s(<p class="#{Enum.join(["bg", "zinc", "100"], "-")}"></p>\n)
    @bad "defmodule B do\n  def x( do\nend\n"

    test "advisory runs are 0 whatever they find" do
      assert run_files(%{"lib/a.html.heex" => @err, "lib/b.ex" => @bad}, rules: @both).exit_status ==
               0
    end

    test "strict: nothing new 0, new errors 1, unchecked 2, both 1" do
      assert run_files(%{"lib/a.html.heex" => "<p></p>\n"}, rules: @both, strict: true).exit_status ==
               0

      assert run_files(%{"lib/a.html.heex" => @err}, rules: @both, strict: true).exit_status == 1
      assert run_files(%{"lib/b.ex" => @bad}, rules: @both, strict: true).exit_status == 2

      assert run_files(%{"lib/a.html.heex" => @err, "lib/b.ex" => @bad},
               rules: @both,
               strict: true
             ).exit_status == 1
    end

    test "strict: only warnings is 0" do
      heex = "<%!-- petal-check:ignore literal-neutral --%>\n" <> @err
      r = run_files(%{"lib/a.html.heex" => heex}, rules: @both, strict: true)
      assert [_ | _] = Enum.filter(r.findings, & &1.meta)
      assert r.exit_status == 0
    end

    test "strict: an update is 0" do
      root = tmp_root()
      write_files(root, %{"lib/a.html.heex" => @err})
      bl = Path.join(root, "b.json")

      {:ok, r} =
        Check.run(root: root, rules: @both, strict: true, baseline: bl, update_baseline: true)

      assert r.exit_status == 0
      File.rm_rf!(root)
    end
  end

  test "--only and --except" do
    files =
      with_modules(%{
        "lib/a.html.heex" =>
          ~s(<p class="#{t()}"></p>\n<.field type="combobox" variant="input" />\n)
      })

    assert [%{rule: "combobox-variant"}] =
             run_files(files, rules: @both, only: ["combobox-variant"]).findings

    assert [%{rule: "literal-neutral"}] =
             run_files(files, rules: @both, except: ["combobox-variant"]).findings
  end

  describe "project rules" do
    setup do
      root = tmp_root()
      on_exit(fn -> File.rm_rf!(root) end)

      write_files(root, %{
        "assets/css/a.css" => "@theme {\n  --x-a: 1;\n}\n",
        "assets/css/b.css" => "@theme {\n  --x-b: 1;\n}\n"
      })

      %{root: root}
    end

    test "collect from every default CSS root even when the run is given one file", %{root: root} do
      {:ok, r} = Check.run(root: root, rules: [Ramp], paths: ["assets/css/a.css"])
      assert r.findings == []
    end

    test "a finding is reported only in a file this run checks", %{root: root} do
      File.write!(Path.join(root, "assets/css/b.css"), ".y { color: red; }\n")
      {:ok, r} = Check.run(root: root, rules: [Ramp], paths: ["assets/css/b.css"])
      assert r.findings == []
      {:ok, r} = Check.run(root: root, rules: [Ramp], paths: ["assets/css/a.css"])
      assert [%{path: "assets/css/a.css"}] = r.findings
    end

    test "an unreadable input means no project findings", %{root: root} do
      File.write!(Path.join(root, "assets/css/b.css"), ".y { color: red;\n")
      {:ok, r} = Check.run(root: root, rules: [Ramp], paths: ["assets/css/a.css"])
      assert r.findings == []
    end

    test "a project rule that raises is named as not run, and --strict exits 2", %{root: root} do
      {:ok, r} = Check.run(root: root, rules: [RaisesProject], strict: true)
      assert r.rules_not_run == [{"raises-project", "internal error (please report): boom"}]
      assert r.exit_status == 2
      text = Enum.join(PetalComponents.Check.Format.text(r), "\n")
      assert text =~ "petal.check --strict failed: a rule could not run"
    end

    test "an unreadable .heex file does not stop the project rules", %{root: root} do
      partial = "@theme {\n  --color-primary-500: red;\n  --color-primary-600: red;\n}\n"
      File.write!(Path.join(root, "assets/css/a.css"), partial)
      write_files(root, %{"lib/unclosed.html.heex" => "<div>\n"})
      {:ok, r} = Check.run(root: root, rules: [RampComplete], no_baseline: true)
      assert [%{rule: "ramp-complete", path: "assets/css/a.css"}] = r.findings
      assert r.rules_not_run == []
    end

    test "a rule that did not run is named, fails --strict and leaves no unused suppression",
         %{root: root} do
      partial =
        "@theme {\n  /* petal-check:ignore ramp-complete: a demo */\n  --color-primary-500: red;\n}\n"

      File.write!(Path.join(root, "assets/css/a.css"), partial)
      File.write!(Path.join(root, "assets/css/b.css"), ".y { color: red;\n")

      {:ok, r} = Check.run(root: root, rules: [RampComplete], no_baseline: true, strict: true)
      assert r.findings == []
      assert r.rules_not_run == [{"ramp-complete", "assets/css/b.css could not be read"}]
      assert r.exit_status == 2

      text = Enum.join(PetalComponents.Check.Format.text(r), "\n")
      assert text =~ "ramp-complete not run: assets/css/b.css could not be read."

      json = r |> PetalComponents.Check.Format.json() |> Jason.decode!()

      assert json["rules_not_run"] == [
               %{"rule" => "ramp-complete", "reason" => "assets/css/b.css could not be read"}
             ]
    end
  end
end
