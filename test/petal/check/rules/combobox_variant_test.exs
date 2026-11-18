defmodule PetalComponents.Check.Rules.ComboboxVariantTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Rules.ComboboxVariant

  defp run(kind, src), do: findings(kind, src, rules: [ComboboxVariant])
  defp run_files_(files), do: run_files(files, rules: [ComboboxVariant]).findings

  describe "must flag" do
    test "a string variant, with the fix" do
      src = ~s(<.field type="combobox" variant="trigger" field={@f[:a]} options={[]} />\n)
      assert [f] = run(:heex, src)
      assert {f.line, f.column} == {1, 25}
      assert f.subject == ~s(variant="trigger")
      assert f.replacement == ~s(combo_variant="trigger")
      assert f.message =~ ~s(variant does nothing on <.field type="combobox">)
      assert f.severity == :error
    end

    test "a multi-line tag reports the variant line" do
      src = in_module("<.field\n  field={@f[:owner]}\n  type=\"combobox\"\n  variant={@v}\n/>")
      assert [f] = run(:ex, src)
      assert {f.line, f.column} == {9, 7}
      assert f.subject == "variant={@v}"
      assert f.replacement == nil
      assert f.fix =~ "combo_variant"
      assert f.tag_line == 6
    end

    test "a remote call" do
      src = ~s(<PetalComponents.Field.field type="combobox" variant="input" />\n)
      assert [f] = run(:heex, src)
      assert f.replacement == ~s(combo_variant="input")
    end

    test "an aliased remote call" do
      src = """
      defmodule AppWeb.X do
        use Phoenix.Component
        alias PetalComponents.Field, as: F
        def render(assigns), do: ~H|<F.field type="combobox" variant="input" />|
      end
      """

      assert [f] = run(:ex, src)
      assert {f.line, f.column} == {4, 56}
    end

    test "single quotes are kept in the replacement" do
      assert [f] = run(:heex, "<.field type=\"combobox\" variant='trigger' />\n")
      assert f.replacement == "combo_variant='trigger'"
    end

    test "an unknown string value has no mechanical fix" do
      assert [f] = run(:heex, ~s(<.field type="combobox" variant="outline" />\n))
      assert f.replacement == nil
      assert f.fix =~ ~s(combo_variant="input")
    end
  end

  describe "must not flag" do
    test "combo_box takes variant itself" do
      assert run(:heex, ~s(<.combo_box variant="trigger" id="c" name="c" />\n)) == []
    end

    test "radio-card variant" do
      assert run(:heex, ~s(<.field type="radio-card" variant="outline" field={@f[:plan]} />\n)) ==
               []
    end

    test "a type that is not a literal" do
      assert run(:heex, ~s(<.field type={@type} variant="trigger" />\n)) == []
    end

    test "combo_variant" do
      assert run(:heex, ~s(<.field type="combobox" combo_variant="trigger" />\n)) == []
    end

    test "a module that defines its own field/1" do
      src = """
      defmodule AppWeb.CoreComponents do
        use Phoenix.Component
        def field(assigns), do: ~H"<input />"
        def form(assigns), do: ~H|<.field type="combobox" variant="trigger" />|
      end
      """

      assert run(:ex, src) == []
    end

    test "an app that imports petal's Field except field/1" do
      files = %{
        "lib/app_web/components.ex" => """
        defmodule AppWeb.Components do
          defmacro __using__(_) do
            quote do
              import PetalComponents.Field, except: [field: 1]
            end
          end
        end
        """,
        "lib/app_web/page.html.heex" => ~s(<.field type="combobox" variant="trigger" />\n)
      }

      assert run_files_(files) == []
    end

    test "the except import is found even when only the template is checked" do
      files = %{
        "lib/app_web/components.ex" =>
          "defmodule C do\n  import PetalComponents.Field, except: [field: 1]\nend\n",
        "lib/app_web/page.html.heex" => ~s(<.field type="combobox" variant="trigger" />\n)
      }

      assert run_files(files, rules: [ComboboxVariant], paths: ["lib/app_web/page.html.heex"]).findings ==
               []
    end

    test "a .heex template whose module defines field/1" do
      files = %{
        "lib/app_web/live/page_live.ex" =>
          "defmodule P do\n  def field(assigns), do: assigns\nend\n",
        "lib/app_web/live/page_live.html.heex" =>
          ~s(<.field type="combobox" variant="trigger" />\n)
      }

      assert run_files_(files) == []
    end

    test "a remote call to an app module" do
      assert run(:heex, ~s(<AppWeb.Field.field type="combobox" variant="trigger" />\n)) == []
    end
  end

  test "every replacement is pasteable" do
    for src <- [
          ~s(<.field type="combobox" variant="trigger" />\n),
          in_module("<.field\n  type=\"combobox\"\n  variant=\"input\"\n/>")
        ] do
      kind = if String.starts_with?(src, "<"), do: :heex, else: :ex
      found = run(kind, src)
      assert [_] = found
      assert run(kind, apply_replacements(src, found)) == []
    end
  end
end
