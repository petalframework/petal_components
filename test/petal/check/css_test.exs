defmodule PetalComponents.Check.CssTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Css
  alias PetalComponents.Check.Rules.LiteralNeutral

  defp t, do: Enum.join(["bg", "zinc", "100"], "-")

  test "statements carry their block stack" do
    {:ok, %{statements: st}} =
      Css.parse("@media (x) {\n  .a .b { color: red; }\n}\n@import \"tailwindcss\";\n")

    [decl, import] = st
    assert decl.text == "color: red"
    assert {decl.line, decl.column} == {2, 11}
    assert Css.selectors(decl) == [".a .b"]
    assert Css.at_rules(decl) == ["@media (x)"]
    assert import.text == ~s(@import "tailwindcss")
  end

  test "a /* inside a string is not a comment, so what follows is still read" do
    src = "@source \"../lib/*.ex\";\n.x {\n  @apply #{t()};\n}\n"
    assert [f] = findings(:css, src, rules: [LiteralNeutral])
    assert {f.line, f.column} == {3, 10}
  end

  test "comments are blanked and recorded, positions stay exact" do
    {:ok, %{statements: [s], comments: [c]}} = Css.parse(".x { /* a\nb */ color: red; }")
    assert s.text == "color: red"
    assert {s.line, s.column} == {2, 6}
    assert c.text == " a\nb "
    assert {c.line, c.end_line} == {1, 2}
  end

  test "a semicolon and braces inside url() and strings are not structure" do
    {:ok, %{statements: st}} =
      Css.parse(".x { background: url(data:image/svg+xml;utf8,<svg>{}</svg>); content: \"};\"; }")

    assert Enum.map(st, & &1.text) == [
             "background: url(data:image/svg+xml;utf8,<svg>{}</svg>)",
             ~s(content: "};")
           ]
  end

  test "an unterminated comment makes the file unchecked" do
    r = run_files(%{"assets/css/app.css" => ".x { color: red; }\n/* never closed\n"})
    assert [%{kind: :parse, line: 2, reason: reason}] = r.unchecked
    assert reason =~ "never closed"
  end

  test "an unterminated string makes the file unchecked" do
    r = run_files(%{"assets/css/app.css" => ".x { content: \"oops; }\n"})
    assert [%{kind: :parse, line: 1}] = r.unchecked
  end

  test "unbalanced braces make the file unchecked" do
    assert [%{reason: r1}] = run_files(%{"assets/css/app.css" => ".x { color: red;\n"}).unchecked
    assert r1 =~ "never closed"
    assert [%{reason: r2}] = run_files(%{"assets/css/app.css" => ".x { }\n}\n"}).unchecked
    assert r2 =~ "closes no block"
  end
end
