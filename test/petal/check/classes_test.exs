defmodule PetalComponents.Check.ClassesTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Classes

  test "tokens keep byte offsets and split on quotes and backticks" do
    assert Classes.tokens(~s(a  b"c`d)) == [{"a", 0}, {"b", 3}, {"c", 5}, {"d", 7}]
    assert Classes.tokens("é x") == [{"é", 0}, {"x", 3}]
  end

  test "bang positions" do
    assert %{important: :leading, variants: [], utility: "bg-x", prefix: "!"} =
             Classes.parse("!bg-x")

    assert %{important: :leading, variants: ["dark"], utility: "bg-x"} =
             Classes.parse("!dark:bg-x")

    assert %{important: :inner, variants: ["hover"], utility: "bg-x", inner: "!"} =
             Classes.parse("hover:!bg-x")

    assert %{important: :trailing, utility: "w-4", suffix: "!"} = Classes.parse("w-4!")
    assert %{important: :none} = Classes.parse("content-['!']")
    assert %{important: :none, variants: ["after"]} = Classes.parse("after:content-['!']")
    assert %{important: :leading, utility: "hidden"} = Classes.parse("!hidden")
  end

  test "variants split only at bracket depth 0" do
    assert %{variants: ["[&:hover]"], utility: "bg-x"} = Classes.parse("[&:hover]:bg-x")

    assert %{variants: ["data-[state=open]", "sm"], utility: "p-2"} =
             Classes.parse("data-[state=open]:sm:p-2")

    assert %{utility: "bg-(--brand)"} = Classes.parse("bg-(--brand)")
  end

  test "rebuild keeps everything but the utility" do
    for t <- ["!dark:bg-x", "hover:!bg-x", "md:bg-x!", "bg-x"] do
      parsed = Classes.parse(t)
      assert Classes.rebuild(parsed, parsed.utility) == t
    end
  end

  test "rejects tokens that are not class-shaped" do
    for t <- ["!", "wrong!", "Wrong", "hover:", "{@x}", "a;b", "=", "foo(", "!!x", ""] do
      assert Classes.parse(t) == :error, "#{inspect(t)} parsed"
    end
  end
end
