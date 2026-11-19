defmodule PetalComponents.Check.Components do
  @moduledoc false
  # Which component calls belong to petal_components.

  alias PetalComponents.Check.Heex.Tag

  # Components that declare no attrs or slots, which `__components__/0` leaves
  # out. `<.icon>` declares none when the heroicons dependency is installed
  # (icon.ex), as it is in every Phoenix app, so without this list the most
  # called component would only count as petal's in an app with no heroicons.
  # A test fails when an imported module gains a one-argument function that
  # is neither a declared component, nor here, nor a known helper.
  @undeclared [:icon, :color_scheme_script]

  @doc false
  def undeclared, do: @undeclared

  @doc """
  The names of the components that declare no `class` attr. A class passed
  to one of them is rejected by the compiler, or travels through `:global`,
  where it can come out as a second class attribute that the browser drops
  (`<.toast_group>` does this). bang-utility leaves those calls alone:
  "drop the !" would be advice about a class that may never reach the page.
  Read from the components' own attr declarations.
  """
  def classless_names do
    for mod <- PetalComponents.imported_modules(),
        Code.ensure_loaded?(mod) and function_exported?(mod, :__components__, 0),
        {name, %{attrs: attrs}} <- mod.__components__(),
        function_exported?(mod, name, 1),
        not Enum.any?(attrs, &(&1.name == :class)),
        into: MapSet.new(),
        do: Atom.to_string(name)
  end

  @doc """
  The names `use PetalComponents` brings into scope. Built from the same
  module list as `__using__`, so the Chat family and Showcase (which it does
  not import) never count as local petal components.
  """
  def petal_names do
    for mod <- PetalComponents.imported_modules(), reduce: MapSet.new() do
      acc -> MapSet.union(acc, module_names(mod))
    end
  end

  @doc "The component names one PetalComponents module exports."
  def module_names(mod) do
    if Code.ensure_loaded?(mod) and function_exported?(mod, :__components__, 0) do
      # `__components__/0` lists `defp` components too (Progress has a private
      # `bar`, Calendar a private `day`). No caller can reach those, so an
      # app's `<.bar>` is another library's and must not count as petal's.
      declared =
        for {name, _} <- mod.__components__(),
            function_exported?(mod, name, 1),
            into: MapSet.new(),
            do: Atom.to_string(name)

      for name <- @undeclared,
          function_exported?(mod, name, 1),
          into: declared,
          do: Atom.to_string(name)
    else
      MapSet.new()
    end
  end

  @doc "The function name a tag calls: `field` for `<.field>` and `<PetalComponents.Field.field>`."
  def function_name(%Tag{kind: :local_component, name: name}), do: name

  def function_name(%Tag{kind: :remote_component, name: name}),
    do: name |> String.split(".") |> List.last()

  def function_name(_), do: nil

  @doc """
  Is this tag a petal_components call? `info` holds `:names` (petal_names/0),
  `:defs` (function names the file, or the module a .heex belongs to,
  defines), `:excepts` (names some host file imports `except:`) and
  `:aliases` (`%{"Chat" => "PetalComponents.Chat"}`).

  A local call is petal when the file brings that name in from
  PetalComponents (`:scope`, see `PetalComponents.Check.Scope`) and nothing
  in the app shadows it. A remote call is petal when its module resolves, through the
  file's aliases, to `PetalComponents.*`.
  """
  def petal?(%Tag{kind: :local_component, name: name}, info) do
    MapSet.member?(info.scope.names, name) and not MapSet.member?(info.scope.shadow, name) and
      not MapSet.member?(info.defs, name) and not MapSet.member?(info.excepts, name)
  end

  def petal?(%Tag{kind: :remote_component, name: name}, info) do
    segs = String.split(name, ".")

    case Enum.drop(segs, -1) do
      [] ->
        false

      [first | rest] ->
        full = Map.get(info.aliases, first, first)
        Enum.join([full | rest], ".") |> String.starts_with?("PetalComponents.")
    end
  end

  def petal?(_tag, _info), do: false
end
