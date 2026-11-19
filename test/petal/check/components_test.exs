defmodule PetalComponents.Check.ComponentsTest do
  # Which names count as petal_components calls.
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Components
  alias PetalComponents.Check.Css
  alias PetalComponents.Check.Rules.BangUtility
  alias PetalComponents.Check.Rules.PcFunctionPrefix

  # `<.icon>` declares no attrs when the heroicons dependency is installed
  # (as it is in a Phoenix app and in this repo), so `__components__/0` does
  # not list it. It is still the most called component there is.
  test "icon is a petal component whether or not heroicons is installed" do
    assert "icon" in Components.petal_names()

    src =
      in_module(~s(<.icon name="hero-x-mark" class="!w-4" />\n<.pc_icon name="hero-x-mark" />))

    assert findings(:ex, src, rules: [BangUtility, PcFunctionPrefix]) |> Enum.map(& &1.rule) == [
             "bang-utility",
             "pc-function-prefix"
           ]
  end

  # A `defp` component with attrs is in `__components__/0` too, but no caller
  # can reach it: `<.bar>` in an app is some other library's `bar`, and
  # reporting it as petal's would be a false alarm.
  test "private components are not petal names" do
    names = Components.petal_names()

    for name <- ~w(bar day heroicon sort_icon spin_button editor_form) do
      refute MapSet.member?(names, name), "#{name} is a private component"
    end

    for name <- names do
      assert Enum.any?(PetalComponents.imported_modules(), fn mod ->
               Code.ensure_loaded?(mod) and
                 function_exported?(mod, String.to_existing_atom(name), 1)
             end),
             "#{name} is in petal_names but no imported module exports #{name}/1"
    end

    src = in_module(~s(<.bar class="!h-4" />\n<.day class="!p-0" />\n<.pc_bar />))
    assert findings(:ex, src, rules: [BangUtility, PcFunctionPrefix]) == []
  end

  # bang-utility says "drop the !", which is only true where the library's
  # styles sit in @layer components: an unlayered rule beats every utility,
  # so there a ! can be the only way. This reads default.css and keeps
  # Components.unlayered_modules/0 equal to the components whose rules sit
  # outside every at-rule. Every component is layered now, so both sides are
  # empty: a pc-* rule appended after the last layer closes fails here, and
  # the fix is to move it into the layer (or, if it truly must stay out, to
  # name its module in the list so bang-utility stops telling people to drop
  # a ! that is needed).
  test "unlayered_modules/0 names exactly the components styled outside @layer components" do
    {:ok, %{statements: statements}} = Css.parse(File.read!("assets/default.css"))

    roots =
      for st <- statements,
          Css.at_rules(st) == [],
          sel <- Css.selectors(st),
          [_, root] <- Regex.scan(~r/\.pc-([a-z0-9]+)/, sel),
          uniq: true,
          do: root

    expected =
      for mod <- Components.unlayered_modules(),
          do: mod |> Module.split() |> List.last() |> Macro.underscore()

    assert roots == [], "pc-* rules outside every at-rule: #{Enum.join(roots, ", ")}"
    assert Enum.sort(roots) == Enum.sort(expected)
    assert Components.unlayered_names() == MapSet.new()
  end

  test "a PetalComponents module that defines no components brings in no names" do
    assert Components.module_names(PetalComponents.Check) == MapSet.new()
    assert Components.module_names(PetalComponents.NoSuchModule) == MapSet.new()
    assert "icon" in Components.module_names(PetalComponents.Icon)
    refute "icon" in Components.module_names(PetalComponents.Button)
  end

  # Every public one-argument function `use PetalComponents` imports is either
  # a component (declared attrs, or named in undeclared/0) or a helper named
  # here. A new one fails this test until it is put in one list or the other,
  # so a component with no attrs can never be missed quietly again.
  test "every imported one-argument function is a known component or a known helper" do
    helpers = ~w(close_alert_dialog open_alert_dialog toggle_collapsible close open open_command
                 hide_modal show_modal ensure_encoder! hide_slide_over show_slide_over
                 hide_sidebar show_sidebar toggle_sidebar)

    names = Components.petal_names()

    unknown =
      for mod <- PetalComponents.imported_modules(),
          Code.ensure_loaded?(mod),
          {fun, 1} <- mod.__info__(:functions),
          name = Atom.to_string(fun),
          not String.starts_with?(name, "__"),
          not MapSet.member?(names, name),
          name not in helpers,
          do: {mod, fun}

    assert unknown == []

    for name <- Components.undeclared() do
      assert Enum.any?(PetalComponents.imported_modules(), fn mod ->
               Code.ensure_loaded?(mod) and function_exported?(mod, name, 1)
             end),
             "#{name} is in Components.undeclared/0 but no imported module exports it"
    end

    assert Enum.all?(helpers, &(not MapSet.member?(names, &1)))
  end
end
