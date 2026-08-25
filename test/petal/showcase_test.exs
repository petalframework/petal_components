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
      assert html =~ "pc-showcase-code"
      assert html =~ "PetalCopy"
      # the live preview rendered the real component
      assert html =~ "pc-command"
    end

    test "locked hides the copy button and shows the overlay" do
      assigns = %{example: hd(PetalComponents.Showcase.Command.examples())}

      html = rendered_to_string(~H"<.showcase_example example={@example} locked />")

      assert html =~ "pc-showcase-code__lock"
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

    test "the code panel is guarded from LiveView patches (phx-update=ignore + id)" do
      assigns = %{example: hd(PetalComponents.Showcase.Command.examples())}

      html = rendered_to_string(~H"<.showcase_example example={@example} />")

      assert html =~ ~s(id="pcsx-inline_palette-code")
      assert html =~ ~s(phx-update="ignore")
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
