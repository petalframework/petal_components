defmodule PetalComponents.Check.Rules.FocusRingTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Rules.FocusRing

  defp run(kind, src), do: findings(kind, src, rules: [FocusRing])

  @house "focus:outline-hidden focus-visible:ring-2 focus-visible:ring-primary-500/50"

  describe "must flag" do
    test "case a: focus rings, one finding per token" do
      src = ~s(<a class="focus:ring-2 focus:ring-primary-500">x</a>\n)
      assert [a, b] = run(:heex, src)
      assert {a.column, b.column} == {11, 24}
      assert a.replacement == "focus-visible:ring-2"
      assert b.replacement == "focus-visible:ring-primary-500"
      assert a.message == "focus:ring-2 shows the ring on mouse clicks too"
      assert a.severity == :warning
    end

    test "case b: ring offsets, with or without a variant" do
      assert [f] = run(:heex, ~s(<a class="ring-offset-2">x</a>\n))
      assert f.replacement == ""
      assert f.message == "ring-offset-2 is a ring offset, which the house ring does not use"

      # focus:ring-offset-2 is case b only, never case a as well
      assert [g] = run(:heex, ~s(<a class="focus:ring-offset-2">x</a>\n))
      assert g.fix == "remove focus:ring-offset-2"
    end

    test "case c: outline-none with no replacement" do
      assert [f] = run(:heex, ~s(<div class="focus:outline-none">x</div>\n))
      assert f.replacement == @house

      assert f.message ==
               "focus:outline-none removes the focus outline with no visible replacement"

      assert [_] = run(:heex, ~s(<div class="focus-within:outline-none">x</div>\n))
    end

    test "case c: a plain border ring is not a focus replacement" do
      src = """
      defmodule AppWeb.Menu do
        def panel_class,
          do: "absolute z-50 w-52 rounded-lg bg-white ring-1 ring-gray-200 focus:outline-none"
      end
      """

      assert [f] = run(:ex, src)
      assert f.subject == "focus:outline-none"
      assert_at(src, f)
    end
  end

  describe "must not flag" do
    test "the house ring" do
      assert run(:heex, ~s(<a class="#{@house}">x</a>\n)) == []
    end

    test "resets" do
      assert run(:heex, ~s(<a class="focus:ring-0 ring-offset-0 focus:ring-transparent">x</a>\n)) ==
               []
    end

    test "outline-none with a focus ring, a border or a background in the same string" do
      for cls <- [
            "focus:outline-none focus-visible:ring-2",
            "focus:outline-none focus:border-gray-300",
            "outline-none focus:bg-gray-100",
            "focus:outline-none peer-focus-visible:ring-2"
          ] do
        assert run(:heex, ~s(<a class="#{cls}">x</a>\n)) == [], cls
      end
    end

    test "a class list: case c passes on the ring, case a still flags it" do
      src = in_module(~s(<input class={["outline-none", "focus:ring-2"]} />))
      assert [f] = run(:ex, src)
      assert f.subject == "focus:ring-2"
    end

    test "an offset colour with no width" do
      assert run(:heex, ~s(<a class="dark:ring-offset-gray-900">x</a>\n)) == []
    end
  end

  test "every replacement is pasteable" do
    src = ~s(<a class="focus:outline-none focus:ring-2 ring-offset-2">x</a>\n)
    found = run(:heex, src)
    assert [_, _] = found
    assert run(:heex, apply_replacements(src, found)) == []

    src = ~s(<div class="p-2 focus:outline-none">x</div>\n)
    assert run(:heex, apply_replacements(src, run(:heex, src))) == []
  end
end
