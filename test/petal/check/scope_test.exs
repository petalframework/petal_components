defmodule PetalComponents.Check.ScopeTest do
  # A local call is only petal's when the file brings PetalComponents in.
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Rules.BangUtility
  alias PetalComponents.Check.Rules.ComboboxVariant
  alias PetalComponents.Check.Rules.PcFunctionPrefix

  @rules [BangUtility, ComboboxVariant, PcFunctionPrefix]

  @core """
  defmodule AppWeb.Core do
    use Phoenix.Component
    def button(assigns), do: ~H"<button class={@class} />"
    def field(assigns), do: ~H"<input type={@type} />"
    def pc_badge(assigns), do: ~H"<span />"
  end
  """

  @web """
  defmodule AppWeb do
    def html do
      quote do
        use Phoenix.Component
        unquote(html_helpers())
      end
    end

    defp html_helpers do
      quote do
        use PetalComponents
      end
    end

    defmacro __using__(which) when is_atom(which), do: apply(__MODULE__, which, [])
  end
  """

  @calls """
      <.button class="!px-0">x</.button>
      <.field type="combobox" variant="outline" field={@f} />
      <.pc_badge />
  """

  defp page(head) do
    """
    defmodule AppWeb.Page do
    #{head}
      def render(assigns) do
        ~H\"\"\"
    #{@calls}    \"\"\"
      end
    end
    """
  end

  defp rules_hit(files) do
    run_files(files, rules: @rules).findings |> Enum.reject(& &1.meta) |> Enum.map(& &1.rule)
  end

  test "the app's own module, imported with no PetalComponents in scope, is not petal's" do
    files = %{
      "lib/app_web/core.ex" => @core,
      "lib/app_web/page.ex" => page("  import AppWeb.Core")
    }

    assert rules_hit(files) == []
  end

  test "the same calls through use AppWeb, :html, whose helpers use PetalComponents, are" do
    files = %{"lib/app_web.ex" => @web, "lib/app_web/page.ex" => page("  use AppWeb, :html")}

    assert Enum.sort(rules_hit(files)) == [
             "bang-utility",
             "combobox-variant",
             "pc-function-prefix"
           ]
  end

  test "a web module whose helpers import the app's own core components" do
    web = String.replace(@web, "use PetalComponents", "import AppWeb.Core")
    files = %{"lib/app_web.ex" => web, "lib/app_web/core.ex" => @core}
    files = Map.put(files, "lib/app_web/page.ex", page("  use AppWeb, :html"))
    assert rules_hit(files) == []
  end

  test "pc_badge imported from an app module beside PetalComponents is the app's" do
    files = %{
      "lib/app_web.ex" => @web,
      "lib/app_web/core.ex" => "defmodule AppWeb.Core do\n  def pc_badge(a), do: a\nend\n",
      "lib/app_web/page.ex" => page("  use AppWeb, :html\n  import AppWeb.Core")
    }

    assert Enum.sort(rules_hit(files)) == ["bang-utility", "combobox-variant"]
  end

  test "an app import with except: leaves the excepted names to PetalComponents" do
    web =
      String.replace(
        @web,
        "use PetalComponents",
        "use PetalComponents\n        import AppWeb.Core, except: [button: 1, pc_badge: 1]"
      )

    files = %{"lib/app_web.ex" => web, "lib/app_web/core.ex" => @core}
    files = Map.put(files, "lib/app_web/page.ex", page("  use AppWeb, :html"))
    assert Enum.sort(rules_hit(files)) == ["bang-utility", "pc-function-prefix"]
  end

  # `mix format` moves a long option list to the next line. The documented
  # CoreComponents import is 86 characters for MyAppWeb, so it wraps for a
  # web module name of 21 characters or more, or a couple more excepted
  # names. Read as "no list", every CoreComponents name would count as the
  # app's own and <.button> would never be checked.
  test "an except: list that mix format wrapped onto the next line is still read" do
    for wrapped <- [
          "import AppWeb.Core,\n          except: [button: 1, pc_badge: 1]",
          "import AppWeb.Core,\n          except: [\n            button: 1,\n            pc_badge: 1\n          ]"
        ] do
      web =
        String.replace(@web, "use PetalComponents", "use PetalComponents\n        " <> wrapped)

      files = %{"lib/app_web.ex" => web, "lib/app_web/core.ex" => @core}
      files = Map.put(files, "lib/app_web/page.ex", page("  use AppWeb, :html"))
      assert Enum.sort(rules_hit(files)) == ["bang-utility", "pc-function-prefix"]
    end
  end

  test "an only: list wrapped onto the next line limits what the app import shadows" do
    web =
      String.replace(
        @web,
        "use PetalComponents",
        "use PetalComponents\n        import AppWeb.Core,\n          only: [pc_badge: 1]"
      )

    files = %{"lib/app_web.ex" => web, "lib/app_web/core.ex" => @core}
    files = Map.put(files, "lib/app_web/page.ex", page("  use AppWeb, :html"))
    assert Enum.sort(rules_hit(files)) == ["bang-utility", "combobox-variant"]
  end

  test "import PetalComponents.{Button, Field} brings in both modules" do
    files = %{"lib/app_web/page.ex" => page("  import PetalComponents.{Button, Field}")}
    assert Enum.sort(rules_hit(files)) == ["bang-utility", "combobox-variant"]
  end

  test "import PetalComponents.X of a module that does not exist brings in nothing" do
    files = %{"lib/app_web/page.ex" => page("  import PetalComponents.NoSuchModule")}
    assert rules_hit(files) == []
  end

  test "import PetalComponents.Button brings in button, not field" do
    files = %{"lib/app_web/page.ex" => page("  import PetalComponents.Button")}
    assert rules_hit(files) == ["bang-utility"]
  end

  test "a .heex file takes the scope of the module beside it" do
    heex = String.replace(@calls, "    <", "<")

    own = %{
      "lib/app_web/core.ex" => @core,
      "lib/app_web/page.ex" => "defmodule AppWeb.Page do\n  import AppWeb.Core\nend\n",
      "lib/app_web/page.html.heex" => heex
    }

    assert rules_hit(own) == []

    petal =
      Map.put(
        own,
        "lib/app_web/page.ex",
        "defmodule AppWeb.Page do\n  use PetalComponents\nend\n"
      )

    assert Enum.sort(rules_hit(petal)) == [
             "bang-utility",
             "combobox-variant",
             "pc-function-prefix"
           ]
  end

  test "a Phoenix.View template takes the scope of its view module" do
    files = %{
      "lib/app_web/views/page_view.ex" =>
        "defmodule AppWeb.PageView do\n  use PetalComponents\nend\n",
      "lib/app_web/templates/page/index.html.heex" => ~s(<.button class="!px-0" />\n)
    }

    assert rules_hit(files) == ["bang-utility"]
  end

  test "a .heex file with no module beside it is not checked for local calls" do
    assert rules_hit(%{"lib/app_web/page.html.heex" => ~s(<.button class="!px-0" />\n)}) == []
  end
end
