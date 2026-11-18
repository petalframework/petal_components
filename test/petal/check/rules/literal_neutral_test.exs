defmodule PetalComponents.Check.Rules.LiteralNeutralTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Rules.LiteralNeutral

  defp run(kind, src), do: findings(kind, src, rules: [LiteralNeutral])

  # The rule's subjects, built at runtime so this file adds no CSS to anyone
  # who scans test/ with Tailwind (none should, but it costs nothing).
  defp c(prop, fam, rest), do: Enum.join([prop, fam, rest], "-")

  describe "must flag" do
    test "a HEEx attr, with the exact position, message and fix" do
      src = ~s(<p class="mt-2 #{c("text", "slate", "500")}">hi</p>\n)
      assert [f] = run(:heex, src)
      assert {f.line, f.column} == {1, 16}
      assert f.subject == c("text", "slate", "500")
      assert f.replacement == c("text", "gray", "500")
      assert f.fix == "replace #{f.subject} with #{f.replacement}"
      assert f.message =~ "is a literal neutral palette; use the gray ramp"
      assert f.severity == :error
      assert f.tag_line == 1
    end

    test "variants and alpha are kept in the fix" do
      src = ~s(<div class="dark:hover:#{c("bg", "zinc", "800")}/50"></div>\n)
      assert [f] = run(:heex, src)
      assert f.replacement == "dark:hover:" <> c("bg", "gray", "800") <> "/50"
    end

    test "an Elixir helper function" do
      src = """
      defmodule AppWeb.Helpers do
        defp muted, do: "#{c("border", "stone", "200")}"
      end
      """

      assert [f] = run(:ex, src)
      assert {f.line, f.column} == {2, 20}
    end

    test "@apply in app CSS" do
      src = ".card {\n  @apply p-2 #{c("bg", "neutral", "100")};\n}\n"
      assert [f] = run(:css, src)
      assert {f.line, f.column} == {2, 14}
    end

    test "a literal inside a class expression" do
      src = in_module(~s(<div class={["p-2", @on && "#{c("ring", "zinc", "300")}"]}></div>))
      assert [f] = run(:ex, src)
      assert {f.line, f.column} == {6, 33}
    end

    test "a bang token keeps its bang in the fix" do
      src = ~s(<p class="!#{c("text", "zinc", "500")}"></p>\n)
      assert [f] = run(:heex, src)
      assert f.replacement == "!" <> c("text", "gray", "500")
    end
  end

  describe "must not flag" do
    test "a theme remap in CSS" do
      assert run(:css, "@theme {\n  --color-gray-500: var(--color-#{c("x", "slate", "500") |> String.trim_leading("x-")});\n}\n") == []
    end

    test "a text node" do
      assert run(:heex, "<p>Slate-500 was the old neutral.</p>\n") == []
    end

    test "docs and comments" do
      src = """
      defmodule AppWeb.Doc do
        @doc "Avoid #{c("text", "zinc", "500")}"
        def x, do: 1
        # #{c("text", "zinc", "500")}
        attr :y, :string, doc: "#{c("text", "zinc", "500")}"
      end
      """

      assert run(:ex, src) == []
    end

    test "a HEEx comment" do
      assert run(:heex, ~s(<%!-- <div class="#{c("bg", "zinc", "100")}"> --%>\n)) == []
    end

    test "a palette name with no stop" do
      assert run(:heex, ~s(<div class="bg-zinc-texture"></div>\n)) == []
    end

    test "a string that holds markup (a code sample)" do
      src = """
      defmodule AppWeb.Docs do
        def sample, do: ~s(<p class="#{c("text", "slate", "500")}">)
      end
      """

      assert run(:ex, src) == []
    end
  end

  test "every replacement is pasteable: applied, the rule finds nothing" do
    samples = [
      {:heex, ~s(<p class="mt-2 #{c("text", "slate", "500")} dark:#{c("bg", "zinc", "900")}">x</p>\n)},
      {:ex, in_module(~s(<div class={["a", @x && "#{c("ring", "stone", "300")}/40"]}></div>))},
      {:ex, "defmodule A do\n  def x, do: \"p-1 \\\"q\\\" #{c("border", "slate", "100")}\"\nend\n"},
      {:css, ".x {\n  @apply #{c("text", "neutral", "700")} hover:#{c("bg", "zinc", "50")};\n}\n"}
    ]

    for {kind, src} <- samples do
      found = run(kind, src)
      assert found != [], "expected findings in #{src}"
      fixed = apply_replacements(src, found)
      assert run(kind, fixed) == [], "still flagged after fixing: #{fixed}"
    end
  end
end
