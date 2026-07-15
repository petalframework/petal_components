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
        ids =
          mod.examples()
          |> Enum.flat_map(fn ex ->
            Regex.scan(~r/id="([^"]+)"/, ex.code, capture: :all_but_first)
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
