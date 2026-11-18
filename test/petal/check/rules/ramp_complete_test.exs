defmodule PetalComponents.Check.Rules.RampCompleteTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Rules.RampComplete

  @stops ~w(50 100 200 300 400 500 600 700 800 900 950)

  defp run_css(files, opts \\ []) do
    run_files(files, Keyword.merge([rules: [RampComplete]], opts)).findings
    |> Enum.reject(& &1.meta)
  end

  defp ramp(name, stops, palette \\ "violet") do
    Enum.map_join(stops, "\n", &"  --color-#{name}-#{&1}: var(--color-#{palette}-#{&1});")
  end

  describe "must flag" do
    test "primary 50 to 900 with no 950, at the first definition, with the exact lines" do
      css =
        "@import \"tailwindcss\";\n@theme inline {\n#{ramp("primary", @stops -- ["950"])}\n}\n"

      assert [f] = run_css(%{"assets/css/colors.css" => css})
      assert {f.path, f.line, f.column} == {"assets/css/colors.css", 3, 3}
      assert f.subject == "primary"

      assert f.message ==
               "@theme remaps 10 of 11 primary stops; the missing stops (950) stay on the library default"

      assert f.fix ==
               "add these lines in the same @theme block: --color-primary-950: var(--color-violet-950);"

      assert f.severity == :error
    end

    test "one stop alone, with literal values" do
      assert [f] =
               run_css(%{"assets/css/app.css" => "@theme {\n  --color-primary-500: #7c3aed;\n}\n"})

      assert f.message =~ "1 of 11"
      assert f.fix =~ "add --color-primary-50 (and every other missing stop)"
    end

    test "gray with 7 stops in @theme inline, nested in another block" do
      css =
        "@layer base {\n  @theme inline {\n#{ramp("gray", Enum.take(@stops, 7), "slate")}\n  }\n}\n"

      assert [f] = run_css(%{"assets/css/app.css" => css})
      assert f.message =~ "7 of 11 gray stops"
      assert f.message =~ "(700, 800, 900, 950)"
    end

    test "a cleared ramp with some stops says the rest do not exist" do
      css = "@theme {\n  --color-primary-*: initial;\n#{ramp("primary", ["500", "600"])}\n}\n"
      assert [f] = run_css(%{"assets/css/app.css" => css})
      assert f.message =~ "do not exist"
      assert f.line == 3
    end
  end

  describe "must not flag" do
    test "all 11 stops split across two blocks in two files" do
      {a, b} = Enum.split(@stops, 5)

      files = %{
        "assets/css/a.css" => "@theme inline {\n#{ramp("primary", a)}\n}\n",
        "assets/css/b.css" => "@theme inline {\n#{ramp("primary", b)}\n}\n"
      }

      assert run_css(files) == []
    end

    test "a run given only one of the two files still sees both" do
      {a, b} = Enum.split(@stops, 5)

      files = %{
        "assets/css/a.css" => "@theme inline {\n#{ramp("primary", a)}\n}\n",
        "assets/css/b.css" => "@theme inline {\n#{ramp("primary", b)}\n}\n"
      }

      assert run_css(files, paths: ["assets/css/a.css"]) == []
    end

    test "runtime variables outside @theme" do
      css =
        ":root {\n  --color-primary-500: #7c3aed;\n}\n.brand {\n  --color-primary-600: red;\n}\n"

      assert run_css(%{"assets/css/app.css" => css}) == []
    end

    test "other ramps, a bare clear, and non-standard stops" do
      css =
        "@theme {\n  --color-brand-500: red;\n  --color-primary-*: initial;\n  --color-gray-25: #fff;\n}\n"

      assert run_css(%{"assets/css/app.css" => css}) == []
    end

    test "a commented definition" do
      assert run_css(%{"assets/css/app.css" => "/* @theme { --color-primary-500: red; } */\n"}) ==
               []
    end
  end

  test "the seven ramps and eleven stops are the ones default.css defines" do
    css = File.read!("assets/default.css")

    for r <- RampComplete.ramps(), s <- RampComplete.stops() do
      assert css =~ "--color-#{r}-#{s}:", "default.css has no --color-#{r}-#{s}"
    end

    defined =
      for [_, r] <- Regex.scan(~r/--color-([a-z]+)-500:/, css), uniq: true, do: r

    assert Enum.sort(defined) == Enum.sort(RampComplete.ramps())
  end
end
