defmodule PetalComponents.Check.Rules.PcFunctionPrefixTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Rules.PcFunctionPrefix

  defp run(kind, src), do: findings(kind, src, rules: [PcFunctionPrefix])

  describe "must flag" do
    test "a local call, once, on the opening tag" do
      src = "<.pc_button>Save</.pc_button>\n"
      assert [f] = run(:heex, src)
      assert {f.line, f.column} == {1, 1}
      assert f.subject == "<.pc_button"
      assert f.replacement == "<.button"
      assert f.message == "<.pc_button> does not exist: component functions have no pc_ prefix"
      assert f.fix == "rename <.pc_button> to <.button>, and its closing tag if it has one"
      assert f.severity == :error
      assert f.section == "11.4"
    end

    test "a self-closing call" do
      assert [f] = run(:heex, ~s(<p>x</p>\n  <.pc_modal title="Edit" />\n))
      assert {f.line, f.column} == {2, 3}
      assert f.replacement == "<.modal"
    end

    test "a remote call to a PetalComponents module" do
      src = ~s(<PetalComponents.Button.pc_button label="x" />\n)
      assert [f] = run(:heex, src)
      assert f.subject == "<PetalComponents.Button.pc_button"
      assert f.replacement == "<PetalComponents.Button.button"
    end

    test "a multi-line tag inside a ~H heredoc is reported at its <" do
      src = in_module(~s(<div>\n  <.pc_card\n    class="p-4"\n  >\n    x\n  </.pc_card>\n</div>))
      assert [f] = run(:ex, src)
      assert {f.line, f.column} == {7, 7}
      assert_at(src, f)
    end
  end

  describe "must not flag" do
    test "the pc- CSS class prefix" do
      assert run(:heex, ~s(<.button class="pc-button pc-button--primary">x</.button>\n)) == []
      assert run(:heex, ~s(<div class="pc-card">x</div>\n)) == []
    end

    test "a HEEx comment" do
      assert run(:heex, "<%!-- <.pc_button> --%>\n") == []
    end

    test "an Elixir string in a helper" do
      src = "defmodule A do\n  def sample, do: \"<.pc_button>\"\nend\n"
      assert run(:ex, src) == []
    end

    test "an app component whose name starts with pc" do
      assert run(:heex, "<.pcard />\n") == []
    end

    test "a pc_ name that is not a petal function" do
      assert run(:heex, "<.pc_whatever />\n") == []
    end

    test "a module that defines its own pc_card" do
      src = """
      defmodule AppWeb.Cards do
        use Phoenix.Component
        def pc_card(assigns), do: ~H"<div>{render_slot(@inner_block)}</div>"
        def page(assigns), do: ~H"<.pc_card>x</.pc_card>"
      end
      """

      assert run(:ex, src) == []
    end

    test "a remote call to an app module" do
      assert run(:heex, "<AppWeb.Button.pc_button />\n") == []
    end
  end

  test "every replacement is pasteable" do
    for {kind, src} <- [
          {:heex, "<.pc_button>Save</.pc_button>\n"},
          {:ex, in_module("<PetalComponents.Card.pc_card class=\"p-2\" />")}
        ] do
      found = run(kind, src)
      assert [_] = found
      assert run(kind, apply_replacements(src, found)) == []
    end
  end
end
