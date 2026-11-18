defmodule PetalComponents.Check.ComponentsTest do
  # Which names count as petal_components calls.
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Components
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
