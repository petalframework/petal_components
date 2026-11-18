defmodule PetalComponents.Check.SamplesTest do
  # A code sample or a sentence held in a string is not a class list, so no
  # class rule reads it. Every class rule runs here, so a new one is covered
  # too.
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check

  defp class_rules,
    do: for(r <- Check.rules(), r.scope == :class_unit, do: r.module)

  defp run(kind, src), do: findings(kind, src, rules: class_rules())

  defp zinc, do: Enum.join(["text", "zinc", "500"], "-")
  defp slate, do: Enum.join(["text", "slate", "500"], "-")
  defp ghost, do: "dark:border-white/10"

  describe "must not flag" do
    test "a heredoc that holds a markup snippet" do
      src = """
      defmodule AppWeb.Docs do
        def snippet do
          \"\"\"
          ```html
          <div class="#{slate()} dark:bg-white/10 focus:outline-none">
            <p class="text-red-600">x</p>
          </div>
          ```
          \"\"\"
        end
      end
      """

      assert run(:ex, src) == []
    end

    test "a code attr that holds markup" do
      src = ~s|<.code_block code={~S(<div class="#{zinc()} #{ghost()}">x</div>)} />\n|
      assert run(:heex, src) == []
    end

    test "a code, source, snippet or example attr that holds bare classes" do
      for attr <- ~w(code source snippet example) do
        src = ~s(<.code_block #{attr}="#{zinc()} #{ghost()} text-red-500" />\n)
        assert run(:heex, src) == [], attr
      end
    end

    test "a sentence that names classes" do
      src = """
      defmodule AppWeb.Hint do
        def message, do: "Replace #{zinc()} with text-gray-500 in your templates"
        def other, do: "use #{ghost()} instead of the old border."
      end
      """

      assert run(:ex, src) == []
    end
  end

  describe "must flag" do
    test "the same classes on a real element" do
      src = ~s(<div class="#{zinc()} #{ghost()} text-red-500">Payment failed</div>\n)
      rules = run(:heex, src) |> Enum.map(& &1.rule) |> Enum.sort()
      assert rules == ["literal-neutral", "semantic-hue", "white-alpha-ghost"]
    end

    test "a class attr next to a code attr on the same call" do
      src = ~s(<.code_block code="x" class="#{zinc()}" />\n)
      assert [%{rule: "literal-neutral"}] = run(:heex, src)
    end

    test "a class string in Elixir with a custom class word" do
      src = """
      defmodule AppWeb.Card do
        def card_class, do: "card #{zinc()} p-4"
      end
      """

      assert [%{rule: "literal-neutral"}] = run(:ex, src)
    end
  end
end
