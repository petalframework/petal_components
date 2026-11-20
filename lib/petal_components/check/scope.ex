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
  # itself (or, for a .heex file, the module beside it). A name counts as
  # shadowed when a module the file imports defines it: a project module
  # (from its source), a dependency module (from its .beam), or a project
  # module imported through an alias (matched by the end of its name).
  #
  # Known limits. Each of the first two only skips calls:
  #
  #   * `use MyAppWeb, :html` counts everything MyAppWeb's file uses and
  #     imports, whichever function (`html`, `live_view`, `admin`) the atom
  #     names. A function that imports the app's or a dependency's own
  #     `table` therefore stops `<.table>` being checked in every file that
  #     uses the web module.
  #   * A line in a doc, a string or a template that reads like a directive
  #     (`use PetalComponents` in a @moduledoc example) counts as one.
  #   * What is left of the false alarm these could cause: a file that gets
  #     petal's names from one of the two above, and calls a same-named
  #     component it imports from a dependency under a renamed alias
  #     (`alias Dep.Kit, as: K` then `import K`), which nothing here can see.

  @module_re ~r/^\s*defmodule\s+([A-Z][\w.]*)\s+do\b/m

  # One `use` or `import` at the start of a line (also `use(X)`): its module
  # (or `Base.{A, B}`), then, when one follows, its `only:` or `except:` list.
  # A directive after a `;` is not read: `mix format` never leaves one, and
  # looking for it made the scan nine times slower.
  # The gaps cross line ends and whole `#` comments, so a list that
  # `mix format` moved to the next lines is still the directive's own, with
  # or without a note above it: the documented
  # `import MyAppWeb.CoreComponents, except: [...]` wraps for a long app
  # name. Only simple `key: value,` options may sit before the list, and a
  # comment is taken whole or not at all (`*+`), so the match can never run
  # on into the next statement or read options out of a comment. The brace
  # and list bodies are capped (2,000 characters; 40 runs of up to 200
  # characters or whole comments): with no cap, a file of unclosed `{` or `[`
  # (invalid code, but the check must still answer) is rescanned to its end
  # for every directive, 18 s for 50,000 lines.
  @directive_re ~r/^[ \t]*(use|import)(?:[ \t]+|\(\s*)([A-Z][\w.]*)(?:\{([^}]{0,2000})\})?(?:(?:\s|#[^\n]*+)*,(?:(?:\s|#[^\n]*+)*\w+:\s*[\w:.]+\s*,)*(?:\s|#[^\n]*+)*(only|except):\s*\[((?:[^\]#]{1,200}+|#[^\n]*+){0,40})\])?/m

  @def_re ~r/^\s*def(?:macro)?\s+([a-z_]\w*[?!]?)/m

  defstruct names: MapSet.new(), shadow: MapSet.new()

  @doc """
  `%{module => %{directives: [...], defs: MapSet}}` for every module the
  project's .ex files define. A file's directives and defs are given to each
  module it defines. A module one of them imports from a dependency is
  added with the one-argument functions it exports and no directives.
  """
  def index(root, ex_files) do
    project =
      Enum.reduce(ex_files, %{}, fn rel, acc ->
        case read(Path.join(root, rel)) do
          nil ->
            acc

          text ->
            info = %{directives: directives(text), defs: defs(text)}

            for [_, mod] <- Regex.scan(@module_re, text), into: acc, do: {mod, info}
        end
      end)

    outside =
      for {_mod, %{directives: ds}} <- project,
          {:import, mod, _} <- ds,
          not Map.has_key?(project, mod),
          not petal_module?(mod),
          uniq: true,
          do: mod

    beams = if outside == [], do: %{}, else: beam_files()

    for mod <- outside,
        defs = beam_exports(beams, mod),
        into: project,
        do: {mod, %{directives: [], defs: defs}}
  end

  # Every Elixir .beam on the code path, by file name: one directory listing
  # per code path entry. Asking the code server for each module instead
  # (`:code.where_is_file/1`) cost 2 to 3 ms a module, 200 ms on petal.build.
  defp beam_files do
    for dir <- :code.get_path(),
        {:ok, names} <- [:file.list_dir(dir)],
        ~c"Elixir." ++ _ = name <- names,
        reduce: %{} do
      acc -> Map.put_new(acc, name, dir)
    end
  end

  # The one-argument functions a dependency module exports, read from its
  # .beam: nothing is loaded, and no atom is made from a module name found
  # in source text. nil when there is no such file (the dependencies are not
  # compiled, or the name is an alias).
  defp beam_exports(beams, mod) do
    file = String.to_charlist("Elixir.#{mod}.beam")

    with %{^file => dir} <- beams,
         {:ok, {_module, [exports: exports]}} <-
           :beam_lib.chunks(:filename.join(dir, file), [:exports]) do
      for {name, 1} <- exports, into: MapSet.new(), do: Atom.to_string(name)
    else
      _ -> nil
    end
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
      for {:import, mod, filter} <- all, info = find(index, mod), reduce: MapSet.new() do
        acc -> MapSet.union(acc, limit(info.defs, filter))
      end

    %__MODULE__{names: names, shadow: shadow}
  end

  # A module by its full name, else project modules by the end of theirs:
  # `alias AppWeb.Core` then `import Core`. Several matches shadow the names
  # of all of them, which only skips more calls.
  defp find(index, mod) do
    case index do
      %{^mod => info} ->
        info

      _ ->
        suffix = "." <> mod

        case for({name, info} <- index, String.ends_with?(name, suffix), do: info.defs) do
          [] -> nil
          sets -> %{defs: Enum.reduce(sets, &MapSet.union/2)}
        end
    end
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
  # could not read (one built from a module attribute, say) gives nil: for an
  # app import that leaves every name shadowed, which skips calls rather than
  # misreading them.
  defp filter("", _list), do: nil

  defp filter(kind, list) do
    list = Regex.replace(~r/#[^\n]*/, list, "")
    names = for [_, n] <- Regex.scan(~r/(\w+[?!]?)\s*:/, list), into: MapSet.new(), do: n
    {if(kind == "only", do: :only, else: :except), names}
  end

  defp defs(text), do: for([_, n] <- Regex.scan(@def_re, text), into: MapSet.new(), do: n)
end
