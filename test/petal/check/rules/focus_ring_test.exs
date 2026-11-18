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

    test "case b: ring offsets on a focus ring, with or without a variant" do
      assert [f] = run(:heex, ~s(<a class="focus-visible:ring-2 ring-offset-2">x</a>\n))
      assert f.subject == "ring-offset-2"
      assert f.replacement == ""
      assert f.message == "ring-offset-2 is a ring offset, which the house ring does not use"

      # focus:ring-offset-2 is case b only, never case a as well
      assert [g] = run(:heex, ~s(<a class="focus:ring-offset-2">x</a>\n))
      assert g.fix == "remove focus:ring-offset-2"
    end

    test "case c: outline-none with no replacement on an element that takes focus" do
      assert [f] = run(:heex, ~s(<button class="focus:outline-none">x</button>\n))
      assert f.replacement == @house

      assert f.message ==
               "focus:outline-none removes the focus outline with no visible replacement"

      for tag <- [~s(a href="#"), "select", "textarea", "summary", ~s(div tabindex="0")] do
        name = tag |> String.split() |> hd()
        assert [_] = run(:heex, ~s(<#{tag} class="outline-none">x</#{name}>\n)), tag
      end

      assert [_] = run(:heex, ~s(<input type="text" class="outline-none" />\n))

      assert [_] = run(:heex, ~s(<.button class="focus-visible:outline-none">x</.button>\n))
    end

    test "case a: a ring colour on a text input still flags" do
      assert [_] = run(:heex, ~s(<input type="text" class="focus:ring-primary-500" />\n))
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
    test "outline-none on an element that does not take keyboard focus" do
      for src <- [
            ~s(<div class="focus:outline-none">x</div>\n),
            ~s(<div role="menu" class="ring-1 ring-black/5 focus:outline-none">x</div>\n),
            ~s(<main class="flex-1 overflow-y-auto focus:outline-none">x</main>\n),
            ~s(<div tabindex="-1" class="focus:outline-none">x</div>\n),
            ~s(<.dropdown><:trigger_element><div class="w-full focus:outline-none">x</div></:trigger_element></.dropdown>\n)
          ] do
        assert run(:heex, src) == [], src
      end
    end

    test "outline-none under another variant, such as focus-within:" do
      assert run(:heex, ~s(<button class="focus-within:outline-none">x</button>\n)) == []
      assert run(:heex, ~s(<button class="hover:outline-none">x</button>\n)) == []
    end

    test "a ring offset with no focus ring, such as a selected swatch" do
      src =
        ~s(<button class={["size-6 ring-offset-2 ring-offset-white", @on && "ring-2 ring-gray-900"]}>x</button>\n)

      assert run(:heex, src) == []
    end

    test "a focus ring on a checkbox or radio, which the forms plugin draws on :focus" do
      for type <- ["checkbox", "radio"] do
        src = ~s(<input type="#{type}" class="rounded focus:ring-primary-500 focus:ring-2" />\n)
        assert run(:heex, src) == [], type

        assert run(:heex, ~s(<.field type="#{type}" field={@f} class="focus:ring-blue-500" />\n)) ==
                 []
      end
    end

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
