defmodule PetalComponents.Check.Rules.WhiteAlphaGhostTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Rules.WhiteAlphaGhost

  defp run(kind, src), do: findings(kind, src, rules: [WhiteAlphaGhost])

  describe "must flag" do
    test "a dark fill, with position, message and fix" do
      src = ~s(<div class="p-2 dark:bg-white/10">x</div>\n)
      assert [f] = run(:heex, src)
      assert {f.line, f.column} == {1, 17}
      assert f.subject == "dark:bg-white/10"
      assert f.replacement == "dark:bg-gray-400/8"

      assert f.message ==
               "dark:bg-white/10 is a white-alpha ghost; dark chrome uses gray-400 alpha"

      assert f.fix == "replace dark:bg-white/10 with dark:bg-gray-400/8"
      assert f.severity == :error
    end

    test "hover and active fills get their own step" do
      assert [h, a] =
               run(:heex, ~s(<a class="dark:hover:bg-white/30 dark:active:bg-white/20">x</a>\n))

      assert h.replacement == "dark:hover:bg-gray-400/17"
      assert a.replacement == "dark:active:bg-gray-400/25"
    end

    test "borders flag at any alpha, sides included, with the input-border note" do
      assert [b, t] =
               run(:heex, ~s(<div class="dark:border-white/10 dark:border-t-white/5">x</div>\n))

      assert b.replacement == "dark:border-gray-400/17"
      assert t.replacement == "dark:border-t-gray-400/17"
      assert b.note =~ "/25"
    end

    test "a left border, like every other side" do
      assert [f] = run(:heex, ~s(<div class="dark:border-l-white/10">x</div>\n))
      assert f.replacement == "dark:border-l-gray-400/17"
    end

    test "bracket alphas above the muted range" do
      assert [_, _] =
               run(:heex, ~s(<div class="dark:bg-white/[0.1] dark:bg-white/[10%]">x</div>\n))
    end

    test "a helper function that builds the class string" do
      src = """
      defmodule AppWeb.Pill do
        def pill_class(active?) do
          if active?, do: "bg-gray-100 dark:bg-white/20", else: "bg-transparent"
        end
      end
      """

      assert [f] = run(:ex, src)
      assert_at(src, f)
    end

    test "a conditional class list in a multi-line tag" do
      src =
        in_module(
          ~s(<button\n  type="button"\n  class={[\n    "px-2",\n    @on && "dark:bg-white/15"\n  ]}\n>x</button>)
        )

      assert [f] = run(:ex, src)
      assert f.line == 10
      assert f.tag_line == 6
      assert_at(src, f)
    end
  end

  describe "must not flag" do
    test "the blessed muted fill" do
      src =
        ~s(<tr class="dark:bg-white/[0.03] dark:hover:bg-white/[0.06] dark:bg-white/5">x</tr>\n)

      assert run(:heex, src) == []
    end

    test "white alpha with no dark variant" do
      assert run(:heex, ~s(<div class="bg-white/20 border-white/30">x</div>\n)) == []
    end

    test "text, ring and opaque white" do
      assert run(
               :heex,
               ~s(<p class="dark:text-white/70 dark:ring-white/10 dark:bg-white">x</p>\n)
             ) ==
               []
    end

    test "comments and prose" do
      src = """
      <%!-- <div class="dark:bg-white/10"> --%>
      <p>Never write dark:bg-white/10 in chrome.</p>
      """

      assert run(:heex, src) == []
    end

    test "a bracket value that is not a number" do
      assert run(:heex, ~s|<div class="dark:bg-white/[calc(var(--a))]">x</div>\n|) == []
    end
  end

  test "every replacement is pasteable" do
    for {kind, src} <- [
          {:heex,
           ~s(<div class="dark:bg-white/10 dark:hover:bg-white/30 dark:border-x-white/20">x</div>\n)},
          {:css, ".x {\n  @apply dark:bg-white/[0.2];\n}\n"}
        ] do
      found = run(kind, src)
      assert found != []
      assert run(kind, apply_replacements(src, found)) == []
    end
  end
end
