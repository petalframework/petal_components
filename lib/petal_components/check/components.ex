defmodule PetalComponents.Check.Components do
  @moduledoc false
  # Which component calls belong to petal_components.

  alias PetalComponents.Check.Heex.Tag

  @doc """
  The names `use PetalComponents` brings into scope. Built from the same
  module list as `__using__`, so the Chat family and Showcase (which it does
  not import) never count as local petal components.
  """
  def petal_names do
    for mod <- PetalComponents.imported_modules(),
        Code.ensure_loaded?(mod),
        function_exported?(mod, :__components__, 0),
        {name, _} <- mod.__components__(),
        into: MapSet.new(),
        do: Atom.to_string(name)
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
