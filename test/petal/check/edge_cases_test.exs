defmodule PetalComponents.Check.EdgeCasesTest do
  # Paths the rule tests do not reach: other sigil delimiters, guards and
  # alias groups, boolean attrs, CSS strings, option conflicts and the JSON
  # shape of unchecked files and baseline changes.
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check
  alias PetalComponents.Check.Format
  alias PetalComponents.Check.Options
  alias PetalComponents.Check.Rules.FocusRing
  alias PetalComponents.Check.Rules.LiteralNeutral

  defp t, do: Enum.join(["text", "zinc", "500"], "-")

  describe "Elixir strings" do
    test "sigils with [ ], { } and < > delimiters are read at the right column" do
      src = """
      defmodule AppWeb.Sigils do
        def a, do: ~s[p-2 #{t()}]
        def b, do: ~s{p-2 #{t()}}
        def c, do: ~s<p-2 #{t()}>
        def d, do: ~S[p-2 #{t()}]
        def e, do: ~S{p-2 #{t()}}
        def f, do: ~S<p-2 #{t()}>
      end
      """

      found = findings(:ex, src, rules: [LiteralNeutral])
      assert Enum.map(found, & &1.line) == [2, 3, 4, 5, 6, 7]
      Enum.each(found, &assert_at(src, &1))
    end

    test "a line continuation in a string and a backslash in ~S keep the column" do
      src = """
      defmodule AppWeb.Continued do
        def a, do: "p-2 \\
      #{t()}"
        def b, do: ~S(a\\b #{t()})
      end
      """

      found = findings(:ex, src, rules: [LiteralNeutral])
      assert Enum.map(found, & &1.line) == [3, 4]
      Enum.each(found, &assert_at(src, &1))
    end

    test "a function with a guard and an alias group are known to the file" do
      src = """
      defmodule AppWeb.Guarded do
        alias AppWeb.{Card, Badge}
        def label(x) when is_binary(x), do: "p-2 #{t()}"
      end
      """

      assert [f] = findings(:ex, src, rules: [LiteralNeutral])
      assert f.line == 3
      assert_at(src, f)
    end

    test "escapes and line continuations before a token keep the column" do
      src = """
      defmodule AppWeb.Escapes do
        def a, do: "\\u00e9 \\x41 \\\\ p-2 #{t()}"
      end
      """

      assert [f] = findings(:ex, src, rules: [LiteralNeutral])
      assert_at(src, f)
    end
  end

  describe "HEEx" do
    test "boolean attrs and a slot are read; a dynamic tabindex counts as focusable" do
      src = """
      <input type="text" disabled class="focus:outline-none" />
      <div tabindex={@tab} class="focus:outline-none">x</div>
      <.card><:header class="focus:outline-none">x</:header></.card>
      """

      found = findings(:heex, src, rules: [FocusRing])
      assert Enum.map(found, & &1.line) == [1, 2]
    end

    test "a trailing bang after a bracket value on a component call" do
      alias PetalComponents.Check.Rules.BangUtility
      src = ~s(<.button class="w-[10px]! p-2">x</.button>\n)
      assert [f] = findings(:heex, src, rules: [BangUtility])
      assert f.subject == "w-[10px]!"
      assert f.replacement == "w-[10px]"
    end

    test "a ring offset of [0] or [0px] is a reset" do
      src = ~s(<a class="focus-visible:ring-2 ring-offset-[0] focus:ring-offset-[0px]">x</a>\n)
      assert findings(:heex, src, rules: [FocusRing]) == []
    end

    test "an unmatched closing slot names it with its colon" do
      r =
        run_files(%{"lib/a.html.heex" => "<.card><:header>x</.card>\n"}, rules: [LiteralNeutral])

      assert [%{reason: reason}] = r.unchecked
      assert reason =~ "unmatched closing tag </.card>, expected </:header>"
    end
  end

  describe "unreadable input" do
    test "Elixir that does not parse is unchecked with the parser's message" do
      files = %{
        "lib/a.ex" => "defmodule A do\n  def f(, do: 1\nend\n",
        "lib/b.ex" => "defmodule B do\n  def f, do: \"x\nend\n"
      }

      r = run_files(files, rules: [LiteralNeutral], strict: true)
      assert [a, b] = Enum.sort_by(r.unchecked, & &1.path)
      # Elixir 1.15 places this error a line later than 1.17 does
      assert {a.path, a.kind} == {"lib/a.ex", :parse}
      assert a.line in 2..3
      assert a.reason =~ "this file could not be read as Elixir: "
      assert {b.path, b.kind} == {"lib/b.ex", :parse}
      assert r.exit_status == 2
    end

    test "a file that cannot be opened is unchecked, never clean" do
      root = tmp_root()
      on_exit(fn -> File.rm_rf!(root) end)
      write_files(root, %{"lib/locked.html.heex" => "<p>x</p>\n"})
      path = Path.join(root, "lib/locked.html.heex")
      File.chmod!(path, 0o000)

      # Root can read any file, so there is nothing to prove there.
      if File.read(path) == {:error, :eacces} do
        {:ok, r} = Check.run(root: root, no_baseline: true, rules: [LiteralNeutral], strict: true)
        File.chmod!(path, 0o644)
        assert [%{kind: :read, reason: reason}] = r.unchecked
        assert reason =~ "this file could not be read (permission denied)"
        assert r.exit_status == 2
      else
        File.chmod!(path, 0o644)
      end
    end

    test "a failed tokenizer guard records one entry for a file with two ~H fragments" do
      src = """
      defmodule AppWeb.Two do
        use Phoenix.Component
        def a(assigns), do: ~H"<p>a</p>"
        def b(assigns), do: ~H"<p>b</p>"
      end
      """

      r = run_files(%{"lib/two.ex" => src}, tokenizer: {:error, "x"}, rules: [LiteralNeutral])
      assert [%{kind: :tokenizer}] = r.unchecked
    end

    test "a component helper and a class parser corner" do
      alias PetalComponents.Check.Classes
      alias PetalComponents.Check.Components
      alias PetalComponents.Check.Heex.Tag

      assert Components.function_name(%Tag{kind: :tag, name: "div"}) == nil
      assert Classes.parse("hover:!") == :error
    end
  end

  describe "CSS" do
    test "escaped quotes and comments inside a rule do not end it early" do
      css = """
      .a { content: "a \\" b"; /* @apply #{t()} */ }
      .b { @apply p-2 #{t()}; }
      """

      assert [f] = findings(:css, css, rules: [LiteralNeutral])
      assert f.line == 2
      assert_at(css, f)
    end

    test "url() values, quoted or not, are skipped over" do
      css = """
      .a { background: url("a).png") no-repeat; }
      .b { background: url(data:image/png;base64,AAA=); @apply #{t()}; }
      """

      assert [f] = findings(:css, css, rules: [LiteralNeutral])
      assert f.line == 2
      assert_at(css, f)
    end

    test "a string still open at the end of the file makes it unchecked" do
      r = run_files(%{"assets/css/app.css" => ".a { content: \"x"}, rules: [LiteralNeutral])
      assert [%{kind: :parse}] = r.unchecked
    end

    test "a string that never closes makes the file unchecked" do
      r = run_files(%{"assets/css/app.css" => ".a { content: \"x; }\n"}, rules: [LiteralNeutral])
      assert [%{kind: :parse, reason: reason}] = r.unchecked
      assert reason =~ "a string that starts here is never closed"
    end
  end

  describe "suppressions" do
    test "an enable with no disable before it is reported" do
      src = "<%!-- petal-check:enable literal-neutral --%>\n<p class=\"#{t()}\"></p>\n"
      found = run_files(%{"lib/a.html.heex" => src}, rules: [LiteralNeutral]).findings
      meta = Enum.filter(found, & &1.meta)

      assert [
               %{
                 message:
                   "petal-check:enable literal-neutral has no petal-check:disable before it"
               }
             ] =
               meta
    end
  end

  describe "options" do
    defp parse(argv), do: Options.parse(argv, Check.rule_ids())

    test "--format text is the default spelled out" do
      assert {:ok, %{format: :text}} = parse(["--format", "text"])
    end

    test "conflicting flags are usage errors" do
      assert {:error, "use --update-baseline or --prune-baseline, not both"} =
               parse(["--update-baseline", "--prune-baseline"])

      assert {:error, "use --baseline PATH or --no-baseline, not both"} =
               parse(["--baseline", "x.json", "--no-baseline"])

      assert {:error, "--explain nope: not a rule." <> _} = parse(["--explain", "nope"])
    end

    test "--since sets the ref" do
      assert {:ok, opts} = parse(["--since", "main"])
      assert opts.changed == "main"
    end

    test "--since refuses a ref that git would read as an option, and a missing ref" do
      assert {:error, "--since --output=x.ex: a git ref (a branch or commit) cannot start with -"} =
               parse(["--since=--output=x.ex"])

      assert {:error, "--since needs a git ref" <> _} = parse(["--since", "--strict"])
    end
  end

  describe "JSON" do
    test "an unchecked file and a baseline change are in the report" do
      root = tmp_root()
      on_exit(fn -> File.rm_rf!(root) end)

      write_files(root, %{
        "lib/a.html.heex" => ~s(<p class="#{t()}"></p>\n),
        "lib/b.html.heex" => "<div>\n"
      })

      bl = Path.join(root, ".petal-check-baseline.json")

      {:ok, r} =
        Check.run(root: root, rules: [LiteralNeutral], baseline: bl, update_baseline: true)

      json = r |> Format.json() |> Jason.decode!()

      assert [%{"file" => "lib/b.html.heex", "kind" => "parse", "fix" => fix}] = json["unchecked"]
      assert fix =~ "fix the syntax error"

      assert %{"added" => 1, "removed" => 0, "kept" => 0, "added_entries" => [entry]} =
               json["baseline_change"]

      assert entry == %{
               "rule" => "literal-neutral",
               "path" => "lib/a.html.heex",
               "subject" => t(),
               "count" => 1
             }
    end
  end
end
