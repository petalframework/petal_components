defmodule PetalComponents.Check.Scope do
  @moduledoc false
  # Which component names a file can call as `<.name>` from petal_components,
  # and which names an app module it imports provides instead.
  #
  # A local call `<.button>` is only petal's when the file brings
  # PetalComponents in: `use PetalComponents`, `import PetalComponents[.X]`,
  # or `use MyAppWeb, :html` whose module (in this project) does one of
  # those, directly or through another module it uses. A file that only
  # imports its own `Core` module calls Core's button, so it is not petal's.
  #
  # Read with line-anchored regexes over the text, like the except scan: a
  # project index of every .ex file under the default roots, and the file
  # itself (or, for a .heex file, the module beside it).

  @module_re ~r/^\s*defmodule\s+([A-Z][\w.]*)\s+do\b/m
  @directive_re ~r/^\s*(use|import)\s+([A-Z][\w.]*)([^\n]*)/m
  @def_re ~r/^\s*def(?:macro)?\s+([a-z_]\w*[?!]?)/m

  defstruct names: MapSet.new(), shadow: MapSet.new()

  @doc """
  `%{module => %{directives: [...], defs: MapSet}}` for every module the
  project's .ex files define. A file's directives and defs are given to each
  module it defines.
  """
  def index(root, ex_files) do
    Enum.reduce(ex_files, %{}, fn rel, acc ->
      case read(Path.join(root, rel)) do
        nil ->
          acc

        text ->
          info = %{directives: directives(text), defs: defs(text)}

          for [_, mod] <- Regex.scan(@module_re, text), into: acc, do: {mod, info}
      end
    end)
  end

  @doc """
  The scope of one file, from its text (or the texts of the modules a
  .heex file belongs to). `petal` maps a PetalComponents module name to its
  component names: `petal.("PetalComponents")` is every name `use
  PetalComponents` brings in.
  """
  def of(texts, index, petal) do
    start = Enum.flat_map(texts, &directives/1)
    all = expand(start, index, MapSet.new(), [])

    names =
      for {_kind, mod, filter} <- all, petal_module?(mod), reduce: MapSet.new() do
        acc -> MapSet.union(acc, limit(petal.(mod), filter))
      end

    shadow =
      for {:import, mod, filter} <- all, info = index[mod], reduce: MapSet.new() do
        acc -> MapSet.union(acc, limit(info.defs, filter))
      end

    %__MODULE__{names: names, shadow: shadow}
  end

  @doc "Reads a file as text, or nil when it is missing or not valid UTF-8."
  def read(abs) do
    case File.read(abs) do
      {:ok, text} -> if String.valid?(text), do: text
      _ -> nil
    end
  end

  # `use X` where X is in the project pulls in what X's file uses and imports
  # (its __using__ quote blocks live there). An import is not transitive.
  defp expand([], _index, _seen, acc), do: acc

  defp expand([{:use, mod, _} = d | rest], index, seen, acc) do
    cond do
      MapSet.member?(seen, mod) ->
        expand(rest, index, seen, [d | acc])

      info = index[mod] ->
        expand(info.directives ++ rest, index, MapSet.put(seen, mod), [d | acc])

      true ->
        expand(rest, index, seen, [d | acc])
    end
  end

  defp expand([d | rest], index, seen, acc), do: expand(rest, index, seen, [d | acc])

  defp petal_module?(mod),
    do: mod == "PetalComponents" or String.starts_with?(mod, "PetalComponents.")

  defp limit(names, {:only, only}), do: MapSet.intersection(names, only)
  defp limit(names, {:except, except}), do: MapSet.difference(names, except)
  defp limit(names, nil), do: names

  defp directives(text) do
    for [_, kind, mod, rest] <- Regex.scan(@directive_re, text) do
      {if(kind == "use", do: :use, else: :import), mod, filter(rest)}
    end
  end

  # `only: [...]` or `except: [...]` on the directive's own line. A list
  # spread over several lines is not read: for an app import that leaves
  # every name shadowed, which skips calls rather than misreading them.
  defp filter(rest) do
    case Regex.run(~r/\b(only|except):\s*\[([^\]]*)\]/, rest) do
      [_, kind, list] ->
        names = for [_, n] <- Regex.scan(~r/(\w+[?!]?)\s*:/, list), into: MapSet.new(), do: n
        {if(kind == "only", do: :only, else: :except), names}

      _ ->
        nil
    end
  end

  defp defs(text), do: for([_, n] <- Regex.scan(@def_re, text), into: MapSet.new(), do: n)
end
