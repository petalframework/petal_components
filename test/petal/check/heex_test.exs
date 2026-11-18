defmodule PetalComponents.Check.HeexTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Heex
  alias PetalComponents.Check.Rules.ComboboxVariant
  alias PetalComponents.Check.Rules.LiteralNeutral

  defmodule OddTokenizer do
    # Same API as LiveView's tokenizer, but returns a token shape nobody knows.
    def init(_, _, _, _), do: nil
    def tokenize(_text, _meta, acc, cont, _state), do: {acc, cont}
    def finalize(_acc, _file, _cont, _src), do: [{:weird, "x"}]
  end

  test "picks the tokenizer module that matches the installed LiveView" do
    {:ok, mod} = Heex.tokenizer()

    [major, minor | _] =
      Heex.live_view_version() |> String.split(".") |> Enum.map(&String.to_integer/1)

    if {major, minor} >= {1, 2},
      do: assert(mod == Phoenix.LiveView.TagEngine.Tokenizer),
      else: assert(mod == Phoenix.LiveView.Tokenizer)
  end

  test "the live view version is known (the app spec is loaded first)" do
    assert Heex.live_view_version() =~ ~r/^\d+\.\d+\.\d+/
  end

  test "a tokenizer that returns unknown token shapes makes the fragment unchecked" do
    r =
      run_files(%{"lib/a.html.heex" => "<p>x</p>\n"},
        tokenizer: {:ok, OddTokenizer},
        rules: [LiteralNeutral]
      )

    assert [%{kind: :parse, reason: reason}] = r.unchecked
    assert reason =~ "token shape this check does not know"
  end

  test "a failed guard: every HEEx file is unchecked as [tokenizer], strict exits 4" do
    files = %{
      "lib/a.html.heex" => "<p>x</p>\n",
      "lib/b.ex" => in_module("<p>y</p>"),
      "lib/c.ex" => "defmodule C do\n  def x, do: 1\nend\n"
    }

    r =
      run_files(files,
        tokenizer: {:error, "the canary did not match"},
        strict: true,
        rules: [ComboboxVariant]
      )

    assert r.tokenizer_error == "the canary did not match"
    assert r.unchecked |> Enum.map(& &1.path) |> Enum.sort() == ["lib/a.html.heex", "lib/b.ex"]
    assert Enum.all?(r.unchecked, &(&1.kind == :tokenizer))
    assert r.exit_status == 4

    text = Enum.join(PetalComponents.Check.Format.text(r), "\n")

    assert text =~
             "unchecked [tokenizer] HEEx in 2 files not checked: the canary did not match. fix: this petal_components cannot read HEEx with phoenix_live_view "

    assert text =~ "run mix deps.update petal_components, or pin phoenix_live_view below "

    assert text =~
             "petal.check --strict failed: HEEx could not be read with this phoenix_live_view"

    refute text =~ "lib/a.html.heex:1:1: unchecked"
  end

  test "string units in Elixir and CSS still run when the guard fails" do
    t = Enum.join(["bg", "zinc", "100"], "-")
    files = %{"lib/c.ex" => "defmodule C do\n  def x, do: \"#{t}\"\nend\n"}
    r = run_files(files, tokenizer: {:error, "nope"}, strict: true, rules: [LiteralNeutral])
    assert [%{rule: "literal-neutral"}] = r.findings
    assert r.exit_status == 1
  end

  test "an unterminated attr quote in one fragment leaves the others checked" do
    src = """
    defmodule A do
      use Phoenix.Component
      def a(assigns), do: ~H|<div class="oops>x</div>|
      def b(assigns), do: ~H|<.field type="combobox" variant="input" />|
    end
    """

    r = run_files(%{"lib/a.ex" => src}, rules: [ComboboxVariant])
    assert [%{kind: :parse, line: 3}] = r.unchecked
    assert [%{rule: "combobox-variant", line: 4}] = r.findings
  end

  test "an EEx error is unchecked at its position" do
    r = run_files(%{"lib/a.html.heex" => "<p>\n<%= if @a\n</p>\n"}, rules: [ComboboxVariant])
    assert [%{kind: :parse, line: 2}] = r.unchecked
  end

  describe "tags that do not balance are unchecked, as the HEEx engine rejects them" do
    test "a closing tag that does not match, and strict exits 2" do
      r =
        run_files(%{"lib/a.html.heex" => "<div class=\"p-4\">\n  <span>hi</div>\n</span>\n"},
          rules: [ComboboxVariant],
          strict: true
        )

      assert [%{kind: :parse, line: 2, column: 11, reason: reason}] = r.unchecked

      assert reason ==
               "this HEEx could not be read: unmatched closing tag </div>, expected </span>"

      assert r.exit_status == 2
    end

    test "an open tag never closed, in a ~H fragment" do
      src = in_module("<div class=\"p-4\"\n  <p>broken")
      r = run_files(%{"lib/a.ex" => src}, rules: [ComboboxVariant])
      assert [%{kind: :parse, reason: reason}] = r.unchecked
      assert reason =~ "the template ends without a closing tag for <div"
    end

    test "a stray closing tag and a component left open" do
      r = run_files(%{"lib/a.html.heex" => "<p>x</p>\n</div>\n"}, rules: [ComboboxVariant])

      assert [
               %{
                 line: 2,
                 reason: "this HEEx could not be read: closing tag </div> has no opening tag"
               }
             ] =
               r.unchecked

      r = run_files(%{"lib/a.html.heex" => "<.card>\n  <p>x</p>\n"}, rules: [ComboboxVariant])
      assert [%{line: 1, reason: reason}] = r.unchecked
      assert reason =~ "<.card>"
    end

    test "valid templates stay checked: void, self-closing, slots, remote calls, EEx blocks, script" do
      src = """
      <div>
        <br><input type="text"><img src="x"/>
        <.card><:header>Hi</:header></.card>
        <.icon name="hero-x-mark" />
        <AppWeb.Layouts.app flash={@flash}><p>x</p></AppWeb.Layouts.app>
        <%= if @a do %>
          <p>a</p>
        <% else %>
          <span>b</span>
        <% end %>
        <script>if (a < b) { x() }</script>
        <!-- <div> -->
      </div>
      """

      assert run_files(%{"lib/a.html.heex" => src}, rules: [ComboboxVariant]).unchecked == []
    end
  end
end
