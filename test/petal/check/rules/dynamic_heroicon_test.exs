defmodule PetalComponents.Check.Rules.DynamicHeroiconTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Rules.DynamicHeroicon

  defp run(kind, src), do: findings(kind, src, rules: [DynamicHeroicon])

  describe "must flag" do
    test "interpolation, at the name attr" do
      src = ~s(<.icon name={"hero-\#{@icon}"} />\n)
      assert [f] = run(:heex, src)
      assert {f.line, f.column} == {1, 8}
      assert f.subject == ~s(name={"hero-\#{@icon}"})
      assert f.replacement == nil

      assert f.message =~
               ~s(icon name {"hero-\#{@icon}"} is built at runtime and can render blank)

      assert f.fix =~ "write each full name as a literal"
      assert f.severity == :error
      assert_at(src, f)
    end

    test "interpolation in the middle, beside a class attr" do
      assert [_] = run(:heex, ~s(<.icon name={"hero-\#{@name}-micro"} class="w-4 h-4" />\n))
    end

    test "concatenation with <>" do
      assert [_] = run(:heex, ~s(<.icon name={"hero-" <> @name} />\n))
    end

    test "a remote call and a function on the right" do
      src = ~s|<PetalComponents.Icon.icon name={"hero-" <> to_string(@kind)} />\n|
      assert [_] = run(:heex, src)
    end

    test "a ~s sigil, in a multi-line tag inside ~H" do
      src = in_module(~s(<.icon\n  class="w-5"\n  name={~s"hero-\#{@x}"}\n/>))
      assert [f] = run(:ex, src)
      assert {f.line, f.column} == {8, 7}
      assert_at(src, f)
    end

    test "an app's own CoreComponents icon has the same failure" do
      src = """
      defmodule AppWeb.CoreComponents do
        use Phoenix.Component
        def icon(assigns), do: ~H"<span class={@name} />"
        def x(assigns), do: ~H|<.icon name={"hero-" <> @n} />|
      end
      """

      assert [_] = run(:ex, src)
    end
  end

  describe "must not flag" do
    test "a literal name" do
      assert run(:heex, ~s(<.icon name="hero-check" />\n)) == []
    end

    test "a passthrough" do
      assert run(:heex, "<.icon name={@icon} />\n") == []
    end

    test "a choice between full literals" do
      src = ~s(<.icon name={if @ok, do: "hero-check", else: "hero-x-mark"} />\n)
      assert run(:heex, src) == []
    end

    test "a function call" do
      assert run(:heex, "<.icon name={icon_for(@status)} />\n") == []
    end

    test "a hero section id is not an icon" do
      assert run(:heex, ~s(<div id={"hero-\#{@id}"}>x</div>\n)) == []
      assert run(:heex, ~s(<.icon id={"hero-\#{@id}"} name="hero-check" />\n)) == []
    end

    test "an app that lists icons with @source inline" do
      files = %{
        "lib/app_web/page.html.heex" => ~s(<.icon name={"hero-\#{@icon}"} />\n),
        "assets/css/app.css" =>
          ~s|@import "tailwindcss";\n@source inline("hero-{check,x-mark}");\n|
      }

      assert run_files(files, rules: [DynamicHeroicon]).findings == []
    end

    test "@source not inline does not count as a list" do
      files = %{
        "lib/app_web/page.html.heex" => ~s(<.icon name={"hero-\#{@icon}"} />\n),
        "assets/css/app.css" => ~s|@source not inline("hero-check");\n|
      }

      assert [_] = run_files(files, rules: [DynamicHeroicon]).findings
    end
  end
end
