defmodule PetalComponents.Check.Rules.LegacyDropdownTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Rules.LegacyDropdown

  defp run(kind, src), do: findings(kind, src, rules: [LegacyDropdown])

  describe "must flag" do
    test "placement=right, with the fix" do
      src = ~s(<.dropdown label="x" placement="right">\n</.dropdown>\n)
      assert [f] = run(:heex, src)
      assert {f.line, f.column} == {1, 22}
      assert f.subject == ~s(placement="right")
      assert f.replacement == ~s(align="start")
      assert f.message == ~s(placement="right" is the legacy dropdown spelling)
      assert f.severity == :warning
      assert_at(src, f)
    end

    test "each value maps to its replacement" do
      for {attr, repl} <- [
            {~s(placement="left"), ~s(align="end")},
            {~s(direction="up"), ~s(side="top")},
            {~s(direction="down"), ~s(side="bottom")},
            {~s(direction="auto"), ""}
          ] do
        assert [f] = run(:heex, ~s(<.dropdown label="x" #{attr} />\n))
        assert f.replacement == repl, attr
      end
    end

    test "a multi-line tag reports the line of the attr" do
      src = in_module(~s(<.dropdown\n  label="Org"\n  placement="left"\n>\n  x\n</.dropdown>))
      assert [f] = run(:ex, src)
      assert {f.line, f.column} == {8, 7}
      assert f.tag_line == 6
      assert_at(src, f)
    end

    test "with the replacement already set, the fix removes the legacy attr" do
      assert [f] = run(:heex, ~s(<.dropdown align="start" placement="left" />\n))
      assert f.replacement == ""
      assert f.fix =~ "align is already set and wins"
    end

    test "both legacy attrs on one tag are two findings" do
      assert [_, _] = run(:heex, ~s(<.dropdown placement="right" direction="up" />\n))
    end
  end

  describe "must not flag" do
    test "placement on other components" do
      assert run(:heex, ~s(<.popover placement="top">x</.popover>\n)) == []
      assert run(:heex, ~s(<div data-tippy-placement="right">x</div>\n)) == []
    end

    test "a passthrough value" do
      assert run(:heex, "<.dropdown placement={@placement} direction={@dir} />\n") == []
    end

    test "side and align" do
      assert run(:heex, ~s(<.dropdown side="top" align="end" />\n)) == []
    end

    test "an app's own dropdown" do
      src = """
      defmodule AppWeb.Menu do
        use Phoenix.Component
        def dropdown(assigns), do: ~H"<div />"
        def x(assigns), do: ~H|<.dropdown placement="left" />|
      end
      """

      assert run(:ex, src) == []
    end
  end

  test "every replacement is pasteable" do
    src = ~s(<.dropdown label="x" placement="right" direction="down">\n</.dropdown>\n)
    found = run(:heex, src)
    assert [_, _] = found
    assert run(:heex, apply_replacements(src, found)) == []
  end
end
