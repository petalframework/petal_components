defmodule PetalComponents.Check.Rules.SemanticHueTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Rules.SemanticHue

  defp run(kind, src), do: findings(kind, src, rules: [SemanticHue])

  describe "must flag" do
    test "a literal red, as a warning with a role fix" do
      src = ~s(<p class="mt-1 text-red-500">Failed</p>\n)
      assert [f] = run(:heex, src)
      assert {f.line, f.column} == {1, 16}
      assert f.replacement == "text-danger-500"
      assert f.message == "text-red-500 is a literal hue; the danger ramp follows the theme"
      assert f.fix == "replace text-red-500 with text-danger-500 if the colour means danger"
      assert f.severity == :warning
    end

    test "each hue maps to its role, keeping variants and alpha" do
      src = ~s(<p class="dark:text-green-400 bg-amber-50 border-sky-200 bg-yellow-100/50">x</p>\n)

      assert run(:heex, src) |> Enum.map(& &1.replacement) ==
               ~w(dark:text-success-400 bg-warning-50 border-info-200 bg-warning-100/50)
    end

    test "a helper function clause" do
      src = """
      defmodule AppWeb.Status do
        defp status_class(:ok), do: "text-emerald-600"
        defp status_class(_), do: "text-gray-500"
      end
      """

      assert [f] = run(:ex, src)
      assert f.replacement == "text-success-600"
      assert_at(src, f)
    end
  end

  describe "must not flag" do
    test "semantic roles and other hues" do
      assert run(:heex, ~s(<p class="text-danger-600 bg-blue-600 text-orange-500">x</p>\n)) == []
    end

    test "a theme remap in CSS" do
      assert run(:css, "@theme inline {\n  --color-success-500: var(--color-green-500);\n}\n") ==
               []
    end

    test "a HEEx comment" do
      assert run(:heex, ~s(<%!-- <p class="text-red-500"> --%>\n)) == []
    end

    test "not a utility" do
      assert run(:heex, ~s(<p class="bg-redwood text-red">x</p>\n)) == []
    end
  end

  test "every replacement is pasteable" do
    src = ~s(<p class="text-red-500 hover:bg-sky-100">x</p>\n)
    found = run(:heex, src)
    assert [_, _] = found
    assert run(:heex, apply_replacements(src, found)) == []
  end
end
