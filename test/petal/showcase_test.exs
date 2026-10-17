defmodule PetalComponents.ShowcaseTest do
  use ComponentCase

  import PetalComponents.Showcase.Frame

  alias PetalComponents.Showcase.Registry

  # Every module that `use PetalComponents.Showcase` (i.e. exposes examples/0),
  # discovered from the compiled app - so the completeness test can't be fooled.
  defp example_modules do
    {:ok, mods} = :application.get_key(:petal_components, :modules)

    Enum.filter(mods, fn m ->
      match?(["PetalComponents", "Showcase" | _], Module.split(m)) and
        Code.ensure_loaded?(m) and function_exported?(m, :examples, 0)
    end)
  end

  describe "registry" do
    test "lists every showcase module (no module silently unregistered)" do
      assert Enum.sort(example_modules()) == Enum.sort(Registry.all())
    end

    test "resolves modules by slug" do
      assert Registry.get("border-beam") == PetalComponents.Showcase.BorderBeam
      assert Registry.get("command") == PetalComponents.Showcase.Command
      assert Registry.get("nope") == nil
    end

    test "slugs are unique across the registry" do
      slugs = Enum.map(Registry.all(), & &1.showcase_slug())
      assert slugs == Enum.uniq(slugs)
    end
  end

  describe "examples" do
    test "every example has non-empty code" do
      for mod <- Registry.all(), ex <- mod.examples() do
        assert is_binary(ex.code) and ex.code != "",
               "#{inspect(mod)} example #{ex.id} has empty code"
      end
    end

    test "every example's highlighted is {:safe, _} or nil" do
      for mod <- Registry.all(), ex <- mod.examples() do
        assert match?({:safe, _}, ex.highlighted) or is_nil(ex.highlighted),
               "#{inspect(mod)} example #{ex.id} has a bad :highlighted value"
      end
    end

    test "every example renders without raising" do
      for mod <- Registry.all(), ex <- mod.examples() do
        html = rendered_to_string(ex.render.(%{__changed__: nil}))
        assert is_binary(html) and html != ""
      end
    end

    test "example ids are unique within a module" do
      for mod <- Registry.all() do
        ids = Enum.map(mod.examples(), & &1.id)
        assert ids == Enum.uniq(ids), "#{inspect(mod)} has duplicate example ids"
      end
    end

    test "example DOM ids are unique within a module (a page renders each once)" do
      for mod <- Registry.all() do
        # The lookbehind keeps reference attrs like dialog_id= out of the scan -
        # several triggers naming the same dialog is correct, two elements
        # carrying the same actual id= is the bug this guards against.
        ids =
          mod.examples()
          |> Enum.flat_map(fn ex ->
            Regex.scan(~r/(?<![\w-])id="([^"]+)"/, ex.code, capture: :all_but_first)
          end)
          |> List.flatten()

        assert ids == Enum.uniq(ids), "#{inspect(mod)} repeats a DOM id across examples"
      end
    end
  end

  describe "showcase_example/1" do
    test "renders the preview, the code panel and the copy button" do
      assigns = %{example: hd(PetalComponents.Showcase.Command.examples())}

      html = rendered_to_string(~H"<.showcase_example example={@example} />")

      assert html =~ "pc-showcase"
      assert html =~ "pc-code"
      assert html =~ "PetalCopy"
      # the live preview rendered the real component
      assert html =~ "pc-command"
    end

    test "locked hides the copy button and shows the overlay" do
      assigns = %{example: hd(PetalComponents.Showcase.Command.examples())}

      html = rendered_to_string(~H"<.showcase_example example={@example} locked />")

      assert html =~ "pc-code__lock"
      refute html =~ "PetalCopy"
    end

    test "inert examples render a non-interactive preview; live ones don't" do
      inert_ex = Enum.find(PetalComponents.Showcase.ToggleGroup.examples(), &(&1.id == :single))
      assert inert_ex.inert

      assigns = %{example: inert_ex}
      html = rendered_to_string(~H"<.showcase_example example={@example} />")

      assert html
             |> LazyHTML.from_fragment()
             |> LazyHTML.query(".pc-showcase__preview[inert]")
             |> Enum.count() == 1

      live_ex = hd(PetalComponents.Showcase.Command.examples())
      refute live_ex.inert

      assigns = %{example: live_ex}
      html = rendered_to_string(~H"<.showcase_example example={@example} />")

      assert html
             |> LazyHTML.from_fragment()
             |> LazyHTML.query(".pc-showcase__preview[inert]")
             |> Enum.count() == 0
    end

    test "inert examples carry the static-preview badge; live ones don't" do
      inert_ex = Enum.find(PetalComponents.Showcase.ToggleGroup.examples(), &(&1.id == :single))
      assigns = %{example: inert_ex}
      html = rendered_to_string(~H"<.showcase_example example={@example} />")

      assert html =~ "Static preview"

      assert html
             |> LazyHTML.from_fragment()
             |> LazyHTML.query(".pc-showcase__static")
             |> Enum.count() == 1

      live_ex = hd(PetalComponents.Showcase.Command.examples())
      assigns = %{example: live_ex}
      html = rendered_to_string(~H"<.showcase_example example={@example} />")

      refute html =~ "Static preview"
    end

    # The badge exists for people who cannot discover a dead button by clicking
    # it, and `inert` removes its whole subtree from the accessibility tree.
    # Nesting the badge inside the preview would therefore hide it from exactly
    # that audience - so assert it is a sibling, not a descendant.
    test "the static-preview badge sits outside the inert subtree" do
      inert_ex = Enum.find(PetalComponents.Showcase.ToggleGroup.examples(), &(&1.id == :single))
      assigns = %{example: inert_ex}

      doc =
        rendered_to_string(~H"<.showcase_example example={@example} />")
        |> LazyHTML.from_fragment()

      assert doc |> LazyHTML.query(".pc-showcase > .pc-showcase__static") |> Enum.count() == 1
      assert doc |> LazyHTML.query(".pc-showcase__preview .pc-showcase__static") |> Enum.empty?()
    end

    test "frame ids are deterministic across renders (stable under LV patches)" do
      assigns = %{example: hd(PetalComponents.Showcase.Command.examples())}

      a = rendered_to_string(~H"<.showcase_example example={@example} />")
      b = rendered_to_string(~H"<.showcase_example example={@example} />")

      assert a == b
      assert a =~ ~s(id="pcsx-inline_palette")
    end

    test "the code block's toggle state is guarded from LiveView patches, the code is not" do
      assigns = %{example: hd(PetalComponents.Showcase.Command.examples())}

      doc =
        rendered_to_string(~H"<.showcase_example example={@example} />")
        |> LazyHTML.from_fragment()

      assert doc |> LazyHTML.query("#pcsx-inline_palette-code") |> Enum.count() == 1

      assert doc
             |> LazyHTML.query(
               ~s(#pcsx-inline_palette-code-state[phx-update="ignore"] .pc-code__expand)
             )
             |> Enum.count() == 1

      # the block itself must keep patching - the playground heroes rewrite
      # their code live as the dials turn
      assert doc
             |> LazyHTML.query(~s(#pcsx-inline_palette-code[phx-update="ignore"]))
             |> Enum.empty?()
    end

    test "precompiled example highlighting is classed tokens, never inline colours" do
      # A theme baked into inline styles went missing between lumis versions
      # and shipped petal.build colourless; classes keep the palette in CSS.
      for mod <- Registry.all(), ex <- mod.examples(), match?({:safe, _}, ex.highlighted) do
        {:safe, html} = ex.highlighted
        html = IO.iodata_to_binary(html)

        assert html =~ ~s(class="l-), "#{inspect(mod)} example #{ex.id} is not classed"
        refute html =~ "style=", "#{inspect(mod)} example #{ex.id} carries inline styles"
      end
    end
  end

  describe "code_block/1" do
    @long Enum.map_join(1..8, "\n", &"<.button>Line #{&1}</.button>")

    defp doc(html), do: LazyHTML.from_fragment(html)
    defp count(doc, selector), do: doc |> LazyHTML.query(selector) |> Enum.count()

    test "a bare snippet has no header and copies from the corner" do
      assigns = %{}
      html = rendered_to_string(~H|<.code_block id="snip" code="<.button>Save</.button>" />|)
      d = doc(html)

      assert count(d, "#snip.pc-code") == 1
      assert count(d, ".pc-code__header") == 0
      assert count(d, ~s(#snip-copy-0.pc-code__copy--floating[phx-hook="PetalCopy"])) == 1
      assert html =~ ~s(data-copy-text="&lt;.button&gt;Save&lt;/.button&gt;")
      # five lines or fewer: nothing to fold
      assert count(d, ".pc-code__expand") == 0
    end

    test "a named snippet gets a quiet label header, with copy in the header" do
      assigns = %{}

      d =
        rendered_to_string(~H|<.code_block id="named" filename="app.css" code="@import 'x';" />|)
        |> doc()

      assert count(d, ".pc-code__header .pc-code__label") == 1
      # a single file is a label, not a tab: tabs exist only when there is a choice
      assert count(d, ".pc-code__tab") == 0
      assert count(d, ".pc-code__header #named-copy-0") == 1
      assert count(d, ".pc-code__copy--floating") == 0
      # the language follows the extension
      assert count(d, "code.language-css") == 1
    end

    test "files render one tab, one pane and one copy button per file" do
      assigns = %{
        files: [
          %{name: "lib/app_web/live/chat_live.ex", code: "defmodule ChatLive do\nend"},
          %{name: "assets/js/hooks/chat.js", code: "export default {}"}
        ]
      }

      d = rendered_to_string(~H|<.code_block id="multi" files={@files} />|) |> doc()

      assert count(d, "#multi.pc-code--multi") == 1
      assert count(d, ~s(#multi-tabs[phx-update="ignore"] .pc-code__radio)) == 2
      assert count(d, ~s(#multi-file-0[data-i="0"][checked])) == 1
      assert count(d, ~s(label[for="multi-file-1"].pc-code__tab)) == 1
      assert count(d, ~s(.pc-code__pane[data-i="1"])) == 1

      assert count(d, ~s(.pc-code__copy[data-i="1"][aria-label="Copy assets/js/hooks/chat.js"])) ==
               1

      assert count(d, "code.language-elixir") == 1
      assert count(d, "code.language-javascript") == 1
    end

    test "more files than the tabs can show raises instead of hiding some" do
      assigns = %{files: Enum.map(1..13, &%{name: "f#{&1}.ex", code: "x"})}

      assert_raise ArgumentError, ~r/at most 12/, fn ->
        rendered_to_string(~H|<.code_block id="many" files={@files} />|)
      end
    end

    test "long code folds by default, behind a guarded toggle" do
      assigns = %{code: @long}
      d = rendered_to_string(~H|<.code_block id="long" code={@code} />|) |> doc()

      assert count(d, "#long.pc-code--collapsible") == 1
      assert count(d, ~s(#long-state[phx-update="ignore"] #long-expand)) == 1
      assert count(d, ~s(label.pc-code__peek[for="long-expand"] .pc-code__peek-btn)) == 1
      # open code is capped and scrolls, so there is no fold-back control
      assert count(d, ".pc-code__hide") == 0
    end

    test "collapsible overrides the five-line rule both ways" do
      assigns = %{code: @long}

      never = rendered_to_string(~H|<.code_block id="n" code={@code} collapsible={false} />|)
      always = rendered_to_string(~H|<.code_block id="a" code="x" collapsible />|)

      refute never =~ "pc-code--collapsible"
      assert always =~ "pc-code--collapsible"
    end

    test "locked hides copy and the toggles and shows the overlay" do
      assigns = %{code: @long}

      d = rendered_to_string(~H|<.code_block id="lk" code={@code} locked />|) |> doc()

      assert count(d, ".pc-code__lock") == 1
      assert count(d, ".pc-code__copy") == 0
      assert count(d, ".pc-code__expand") == 0
      assert count(d, ".pc-code__peek") == 0

      custom =
        rendered_to_string(~H"""
        <.code_block id="lk2" code="x" locked>
          <:locked_overlay><a href="/sign-in">Sign in to read</a></:locked_overlay>
        </.code_block>
        """)

      assert custom =~ "Sign in to read"
      refute custom =~ "Log in to view"
    end

    test "attached sits flush under a preview" do
      assigns = %{}
      html = rendered_to_string(~H|<.code_block id="att" code="x" attached />|)
      assert html =~ "pc-code--attached"
    end

    test "a file's own language beats its extension" do
      assigns = %{
        files: [
          %{name: "notes.txt", code: "<.button>Hi</.button>", language: "heex"},
          %{name: "b.css", code: "a {}"}
        ]
      }

      d = rendered_to_string(~H|<.code_block id="lang" files={@files} />|) |> doc()

      assert count(d, "code.language-heex") == 1
      assert count(d, "code.language-css") == 1
    end

    test "without a highlighter the code renders plain and escaped in the same chrome" do
      assert {:safe, html} =
               PetalComponents.Showcase.Highlight.plain_html(~s(<.button a="1">), ~s(he ex"><))

      assert html =~ ~s(<pre class="pc-code__plain"><code class="language-heex">)
      assert html =~ "&lt;.button a=&quot;1&quot;&gt;"
      assert PetalComponents.Showcase.Highlight.to_html(nil, "heex") == nil
    end

    test "highlighting emits classed tokens" do
      assert {:safe, html} =
               PetalComponents.Showcase.Highlight.to_html(
                 ~s(<.button variant="soft">Hi</.button>),
                 "heex"
               )

      assert html =~ ~s(class="l-function")
      assert html =~ ~s(class="l-tag-attribute")
      refute html =~ "style="
    end
  end

  describe "showcase_props/1" do
    test "every module's showcase_functions resolve to real component functions" do
      # The default derives the function from the module name (Toast -> :toast),
      # which silently renders an EMPTY props table when the component's real
      # function is named differently (toast_group) - caught live on petal.build.
      for mod <- Registry.all(), component = mod.showcase_component(), component do
        defs = component.__components__()

        for f <- mod.showcase_functions() do
          info = Map.get(defs, f)

          assert info != nil and (info.attrs != [] or info.slots != []),
                 "#{inspect(mod)} documents #{inspect(component)}.#{f} but it has no attrs or slots " <>
                   "(real functions: #{inspect(Map.keys(defs))}) - set functions: on the showcase module"
        end
      end
    end

    test "renders a props table per documented function for each component" do
      for mod <- Registry.all(), component = mod.showcase_component(), component do
        assigns = %{component: component, functions: mod.showcase_functions()}

        html =
          rendered_to_string(
            ~H"<.showcase_props component={@component} functions={@functions} />"
          )

        assert html =~ "pc-showcase-props"
        assert html =~ "Attribute"
      end
    end

    test "a multi-function component renders a labelled table per function" do
      assigns = %{
        component: PetalComponents.Chat,
        functions: [:conversation, :chat_message, :marker]
      }

      html =
        rendered_to_string(~H"<.showcase_props component={@component} functions={@functions} />")

      assert html =~ "conversation"
      assert html =~ "chat_message"
      assert count_substring(html, "pc-showcase-props__table") == 3
    end
  end
end
