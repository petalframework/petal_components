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
  #
  # Known limit: `use MyAppWeb, :html` counts everything MyAppWeb's file uses
  # and imports, whichever function (`html`, `live_view`, `admin`) the atom
  # names. For the app's own modules that only skips more calls. A false
  # alarm needs a web module where one function uses PetalComponents and
  # another imports a same-named component from a dependency (whose
  # functions this index cannot see), and a file that uses the second.

  @module_re ~r/^\s*defmodule\s+([A-Z][\w.]*)\s+do\b/m

  # One `use` or `import`: its module (or `Base.{A, B}`), then, when one
  # follows, its `only:` or `except:` list. `\s` crosses line ends, so a list
  # that `mix format` moved to the next lines is still the directive's own:
  # the documented `import MyAppWeb.CoreComponents, except: [...]` wraps for
  # a long app name. Only simple `key: value,` options may sit before the
  # list, so the match can never run on into the next statement. The brace
  # and list bodies are capped: with no cap, a file of unclosed `{` or `[`
  # (invalid code, but the check must still answer) is rescanned to its end
  # for every directive, 18 s for 50,000 lines.
  @directive_re ~r/^[ \t]*(use|import)\s+([A-Z][\w.]*)(?:\{([^}]{0,2000})\})?(?:\s*,(?:\s*\w+:\s*[\w:.]+\s*,)*\s*(only|except):\s*\[([^\]]{0,4000})\])?/m

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
    for [_, kind, base | rest] <- Regex.scan(@directive_re, text),
        # Regex.scan leaves out trailing groups that did not match.
        [braces, filter_kind, list] = Enum.take(rest ++ ["", "", ""], 3),
        mod <- modules(base, braces) do
      {if(kind == "use", do: :use, else: :import), mod, filter(filter_kind, list)}
    end
  end

  # `import PetalComponents.{Button, Card}` is one directive per name.
  defp modules(base, ""), do: [base]

  defp modules(base, braces) do
    for name <- String.split(braces, ","),
        name = String.trim(name),
        name =~ ~r/^[A-Z][\w.]*$/,
        do: base <> name
  end

  # The names of an `only: [...]` or `except: [...]` list. A list the regex
  # could not read (a comment inside the directive, say) gives nil: for an app
  # import that leaves every name shadowed, which skips calls rather than
  # misreading them.
  defp filter("", _list), do: nil

  defp filter(kind, list) do
    names = for [_, n] <- Regex.scan(~r/(\w+[?!]?)\s*:/, list), into: MapSet.new(), do: n
    {if(kind == "only", do: :only, else: :except), names}
  end

  defp defs(text), do: for([_, n] <- Regex.scan(@def_re, text), into: MapSet.new(), do: n)
end
