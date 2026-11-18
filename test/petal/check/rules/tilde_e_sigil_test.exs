defmodule PetalComponents.Check.Rules.TildeESigilTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Rules.TildeESigil

  defp run(src), do: findings(:ex, src, rules: [TildeESigil])

  describe "must flag" do
    test "a one-line ~E, at the tilde" do
      src = "defmodule A do\n  def x(assigns), do: ~E\"<p><%= @x %></p>\"\nend\n"
      assert [f] = run(src)
      assert {f.line, f.column} == {2, 23}
      assert f.subject == "~E"
      assert f.replacement == nil
      assert f.message == "~E is the old EEx sigil, with no HTML-aware engine"
      assert f.fix =~ "rewrite it as ~H"
      assert f.severity == :error
      assert_at(src, f)
    end

    test "a ~E heredoc" do
      src = """
      defmodule A do
        def x(assigns) do
          ~E\"\"\"
          <p><%= @x %></p>
          \"\"\"
        end
      end
      """

      assert [f] = run(src)
      assert {f.line, f.column} == {3, 5}
    end

    test "other delimiters, and two in one file" do
      src = "defmodule A do\n  def a, do: ~E|<b>x</b>|\n  def b, do: ~E[<i>y</i>]\nend\n"
      assert [a, b] = run(src)
      assert {a.line, b.line} == {2, 3}
      Enum.each([a, b], &assert_at(src, &1))
    end
  end

  describe "must not flag" do
    test "~H" do
      assert run("defmodule A do\n  def x(assigns), do: ~H\"<p>{@x}</p>\"\nend\n") == []
    end

    test "a comment, a string and a doc" do
      src = """
      defmodule A do
        @moduledoc "~E is gone"
        # ~E"old"
        def x, do: "use ~E\\" here"
      end
      """

      assert run(src) == []
    end

    test "a module that defines its own sigil_E" do
      src = """
      defmodule A do
        def sigil_E(s, _), do: s
        def x, do: ~E"fine"
      end
      """

      assert run(src) == []
    end

    test ".heex and .css files are not Elixir" do
      assert findings(:heex, "<p>~E\"x\"</p>\n", rules: [TildeESigil]) == []
    end
  end
end
