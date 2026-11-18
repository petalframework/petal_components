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
      src = """
      <div class="dark:text-green-400">Saved</div>
      <div class="bg-amber-50">Your trial ends soon</div>
      <div class="border-sky-200">Tip: press / to search</div>
      <div class="bg-yellow-100/50">Warning</div>
      """

      assert run(:heex, src) |> Enum.map(& &1.replacement) ==
               ~w(dark:text-success-400 bg-warning-50 border-info-200 bg-warning-100/50)
    end

    test "a helper function clause" do
      src = """
      defmodule AppWeb.Status do
        defp status_class(:success), do: "text-emerald-600"
        defp status_class(_), do: "text-gray-500"
      end
      """

      assert [f] = run(:ex, src)
      assert f.replacement == "text-success-600"
      assert_at(src, f)
    end
  end

  describe "must flag, with a role word nearby" do
    test "an icon name, an atom, a word on the line below" do
      src = """
      <.icon name="hero-exclamation-triangle" class="text-amber-500" />
      <.icon name="hero-check-circle" class="text-green-600" />
      <span class={["rounded", "bg-red-50"]}>
        Something went wrong
      </span>
      """

      assert run(:heex, src) |> Enum.map(& &1.subject) ==
               ~w(text-amber-500 text-green-600 bg-red-50)
    end

    test "a CSS @apply under a role selector" do
      css = ".alert-error {\n  @apply bg-red-50 text-red-700;\n}\n"
      assert [_, _] = run(:css, css)
    end
  end

  describe "must not flag" do
    test "a categorical hue with no role word nearby" do
      src = """
      <.heart_icon class="text-red-500 group-hover:text-red-500" />
      <div class="rounded-lg bg-green-100 p-2"><.icon name="hero-calendar" class="text-green-600" /></div>
      <.icon name="hero-megaphone" class="text-emerald-500" />
      <span class="size-3 rounded-full bg-red-400"></span>
      <span class="size-3 rounded-full bg-yellow-400"></span>
      """

      assert run(:heex, src) == []
    end

    test "gradient stops, shadows and fills" do
      src =
        ~s(<div class="from-red-500 via-amber-400 to-green-500 shadow-red-500/20 fill-red-500">Error</div>\n)

      assert run(:heex, src) == []
    end

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
    src = ~s(<p class="text-red-500 hover:bg-red-100">Payment failed</p>\n)
    found = run(:heex, src)
    assert [_, _] = found
    assert run(:heex, apply_replacements(src, found)) == []
  end
end
