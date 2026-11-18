defmodule PetalComponents.Check.Rules.TailwindV4GateTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Rules.TailwindV4Gate

  defp run(src), do: findings(:css, src, rules: [TailwindV4Gate])

  describe "must flag" do
    test "a v3 file: each directive is its own finding" do
      src = "@tailwind base;\n@tailwind components;\n  @tailwind utilities;\n"
      assert [a, b, c] = run(src)
      assert Enum.map([a, b, c], &{&1.line, &1.column}) == [{1, 1}, {2, 1}, {3, 3}]
      assert a.subject == "@tailwind base"

      assert a.message ==
               "@tailwind base is a Tailwind v3 directive; petal_components 4.x needs Tailwind v4"

      assert a.fix =~ ~s(one @import "tailwindcss"; line)
      assert a.severity == :error
      Enum.each([a, b, c], &assert_at(src, &1))
    end

    test "a leftover directive beside the v4 import" do
      src = ~s(@import "tailwindcss";\n@tailwind base;\n)
      assert [f] = run(src)
      assert f.message =~ "left beside the v4 import"
      assert f.fix == "delete this line"
    end

    test "variants and screens" do
      assert [_, _] = run("@tailwind variants;\n@tailwind screens;\n")
    end
  end

  describe "must not flag" do
    test "the v4 import and plugins" do
      assert run(~s(@import "tailwindcss";\n@plugin "@tailwindcss/forms";\n)) == []
    end

    test "a commented directive" do
      assert run("/* @tailwind base; */\n@import \"tailwindcss\";\n") == []
    end

    test "@tailwind utilities alone, after a split v4 import" do
      src = ~s|@import "tailwindcss/theme.css" layer(theme);\n@tailwind utilities;\n|
      assert run(src) == []
    end
  end
end
