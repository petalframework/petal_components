defmodule PetalComponents.Check.Rules.BangUtilityTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Rules.BangUtility

  defp run(kind, src), do: findings(kind, src, rules: [BangUtility])

  describe "must flag" do
    test "a heading margin, whose fix is the no_margin attr" do
      src = ~s(<.h3 class="!mb-0">Plan</.h3>\n)
      assert [f] = run(:heex, src)
      assert {f.line, f.column} == {1, 13}
      assert f.subject == "!mb-0"
      assert f.replacement == ""
      assert f.add_attr == "no_margin"
      assert f.fix == "remove !mb-0 from class and add the no_margin attr"
      assert f.message == "!mb-0 on <.h3> forces a utility over the component's own styles"
      assert f.severity == :error
    end

    test "a trailing bang (the Tailwind v4 spelling)" do
      assert [f] = run(:heex, ~s(<.button class="w-4!" label="x" />\n))
      assert f.replacement == "w-4"
    end

    test "a leading bang and a mid-variant bang are two findings" do
      src = ~s(<.button class="!bg-white hover:!bg-gray-100" label="x" />\n)
      assert [a, b] = run(:heex, src)
      assert {a.replacement, b.replacement} == {"bg-white", "hover:bg-gray-100"}
      assert {a.column, b.column} == {17, 27}
    end

    test "a bang before a variant" do
      src = ~s(<.icon_button class="!text-indigo-600 !dark:text-indigo-300" />\n)
      assert [_, f] = run(:heex, src)
      assert f.replacement == "dark:text-indigo-300"
    end

    test "a class list expression" do
      src = in_module(~s(<.alert class={["self-start", "!w-auto"]} color="warning">x</.alert>))
      assert [f] = run(:ex, src)
      assert f.replacement == "w-auto"
      assert_at(src, f)
    end

    # Their styles sat outside @layer components until the layer fix, where
    # a plain utility lost and a ! could be the only way, so bang-utility
    # left them alone. Now a plain utility wins on them too.
    test "carousel and filters, like any other component" do
      src =
        ~s(<.carousel id="c" class="!h-64" slides={[]} />\n<.filters class="!gap-4" />\n) <>
          ~s(<.button class="!px-1" />\n)

      assert [c, f, b] = run(:heex, src)
      assert c.message == "!h-64 on <.carousel> forces a utility over the component's own styles"
      assert {c.replacement, f.replacement} == {"h-64", "gap-4"}
      assert f.message =~ "<.filters>"
      assert b.message =~ "<.button>"

      remote = ~s(<PetalComponents.Carousel.carousel id="c" class="!h-64" slides={[]} />)
      assert [r] = run(:ex, in_module(remote))
      assert r.replacement == "h-64"
    end

    test "a remote call and a multi-line tag" do
      src = in_module(~s(<PetalComponents.Button.button\n  label="x"\n  class="!px-0"\n/>))
      assert [f] = run(:ex, src)
      assert f.message =~ "on <PetalComponents.Button.button>"
      assert f.tag_line == 6
      assert f.line == 8
      assert_at(src, f)
    end
  end

  describe "must not flag" do
    # toast_group declares no class attr: the class goes through :global and
    # comes out as a second class attribute, which the browser drops.
    # vertical_menu has no :global either, so the compiler rejects it. "Drop
    # the !" would be advice about a class that never reaches the page.
    test "a component that takes no class" do
      src =
        ~s(<.toast_group class="!w-80" flash={@flash} />\n<.vertical_menu class="!w-80" />\n) <>
          ~s(<PetalComponents.Toast.toast_group class="!w-80" flash={@flash} />\n)

      assert run(:heex, src) == []
    end

    test "Elixir negation in a class expression" do
      src = in_module(~s(<.button class={if !@open, do: "hidden"} label="x" />))
      assert run(:ex, src) == []
    end

    test "a raw element" do
      assert run(:heex, ~s(<div class="!mb-0">x</div>\n)) == []
    end

    test "the app's own component" do
      assert run(:heex, ~s(<.page_header class="!mb-0" />\n)) == []

      src = """
      defmodule AppWeb.Ui do
        use Phoenix.Component
        def button(assigns), do: ~H"<button />"
        def x(assigns), do: ~H|<.button class="!px-0" />|
      end
      """

      assert run(:ex, src) == []
    end

    test "a bang inside brackets" do
      assert run(:heex, ~s(<.button class="content-['!'] after:content-['!']" />\n)) == []
    end

    test "plain utilities and other attrs" do
      assert run(:heex, ~s(<.button class="mb-0" label="!important" />\n)) == []
    end

    test "a slot's class attr (wave 2)" do
      assert run(:heex, ~s(<.dropdown><:item class="!p-0">x</:item></.dropdown>\n)) == []
    end
  end

  test "every replacement is pasteable" do
    src = ~s(<.button class="!bg-white hover:!bg-gray-100 w-4! !dark:text-x" label="x" />\n)
    found = run(:heex, src)
    assert length(found) == 4
    assert run(:heex, apply_replacements(src, found)) == []
  end
end
