defmodule PetalComponents.Check.Files do
  @moduledoc false
  # Which files a run checks. No Mix calls here: the task passes in the
  # project root, the app dirs (one pair for a plain app, one per child app
  # in an umbrella) and the petal_components source dirs to leave out.
  #
  # Options:
  #   :root            absolute project root
  #   :apps            ["."] or ["apps/a", "apps/b"] (relative to root)
  #   :library_dirs    absolute dirs that hold petal_components' own source
  #   :paths           explicit path arguments (nil = default roots)
  #   :changed         a list of changed files (relative), or nil
  #   :exclude         globs
  #   :include_excluded check explicit paths under test/, priv/, deps/, ...

  @always ~w(deps _build node_modules .git .elixir_ls)
  @zones ~w(test priv)
  @exts ~w(.ex .heex .css)

  @doc """
  Returns `{:ok, map}` or `{:error, message}`. The map:

    * `:checked` - relative paths to check, sorted
    * `:skipped` - `[{path, why}]` explicit paths left out, with the reason
    * `:excluded` - how many files --exclude removed
    * `:project_css` - every CSS file under the default roots (for project rules)
    * `:project_ex` - every .ex file under the default roots
  """
  def discover(opts) do
    root = Keyword.fetch!(opts, :root)
    apps = Keyword.get(opts, :apps, ["."])
    lib_dirs = opts |> Keyword.get(:library_dirs, []) |> Enum.map(&Path.expand/1)
    ctx = %{root: root, lib_dirs: lib_dirs}

    default = default_files(ctx, apps)

    picked =
      cond do
        is_list(opts[:changed]) ->
          {:ok, changed(ctx, apps, opts[:changed]), []}

        is_list(opts[:paths]) and opts[:paths] != [] ->
          explicit(ctx, opts[:paths], !!opts[:include_excluded])

        true ->
          {:ok, default.lib ++ default.css, []}
      end

    with {:ok, files, skipped} <- picked do
      globs = Keyword.get(opts, :exclude, [])
      {excluded, kept} = Enum.split_with(Enum.uniq(files), &excluded?(&1, globs))

      {:ok,
       %{
         checked: Enum.sort(kept),
         skipped: skipped,
         excluded: length(excluded),
         project_css: Enum.sort(default.css),
         project_ex: default.lib |> Enum.filter(&String.ends_with?(&1, ".ex")) |> Enum.sort()
       }}
    end
  end

  defp default_files(ctx, apps) do
    Enum.reduce(apps, %{lib: [], css: []}, fn app, acc ->
      lib = rel_join(app, "lib")
      assets = rel_join(app, "assets")

      %{
        lib: acc.lib ++ walk(ctx, lib, [".ex", ".heex"]),
        css: acc.css ++ walk(ctx, assets, [".css"])
      }
    end)
  end

  defp rel_join(".", dir), do: dir
  defp rel_join(app, dir), do: Path.join(app, dir)

  defp changed(ctx, apps, list) do
    default = MapSet.new(default_files(ctx, apps) |> then(&(&1.lib ++ &1.css)))

    list
    |> Enum.map(&normalise/1)
    |> Enum.filter(&MapSet.member?(default, &1))
  end

  defp explicit(ctx, paths, include?) do
    Enum.reduce_while(paths, {:ok, [], []}, fn arg, {:ok, files, skipped} ->
      rel = normalise(Path.relative_to(Path.expand(arg, ctx.root), ctx.root))
      abs = Path.join(ctx.root, rel)
      zone = zone(ctx, rel, abs)

      cond do
        not File.exists?(abs) ->
          {:halt, {:error, "#{arg} does not exist"}}

        zone != nil and not include? ->
          {:cont, {:ok, files, skipped ++ [{rel, zone}]}}

        File.dir?(abs) ->
          {:cont, {:ok, files ++ walk(ctx, rel, @exts), skipped}}

        Path.extname(rel) in @exts ->
          {:cont, {:ok, files ++ [rel], skipped}}

        true ->
          {:halt, {:error, "#{arg} is not a .ex, .heex or .css file"}}
      end
    end)
  end

  # Why an explicit path is outside what a run checks, or nil.
  defp zone(ctx, rel, abs) do
    segs = Path.split(rel)
    after_app = if match?(["apps", _ | _], segs), do: Enum.drop(segs, 2), else: segs

    cond do
      Enum.any?(ctx.lib_dirs, &inside?(abs, &1)) ->
        "it is petal_components' own source"

      Enum.any?(segs, &(&1 in @always)) ->
        "files under #{Enum.find(segs, &(&1 in @always))}/ are not checked"

      match?([z | _] when z in @zones, after_app) ->
        "files under #{hd(after_app)}/ are not checked"

      true ->
        nil
    end
  end

  defp inside?(abs, dir), do: abs == dir or String.starts_with?(abs, dir <> "/")

  # Walks a relative dir. Prunes the always-excluded dirs, assets/vendor,
  # petal_components' own source, and symlinked dirs (no loops).
  defp walk(ctx, rel, exts) do
    abs = Path.join(ctx.root, rel)
    in_library? = Enum.any?(ctx.lib_dirs, &inside?(abs, &1))

    case if(in_library?, do: :skip, else: File.ls(abs)) do
      {:ok, names} ->
        names
        |> Enum.sort()
        |> Enum.flat_map(fn name ->
          child_rel = normalise(Path.join(rel, name))
          child_abs = Path.join(abs, name)

          case File.lstat(child_abs) do
            {:ok, %{type: :directory}} ->
              if prune?(ctx, child_rel, child_abs, name), do: [], else: walk(ctx, child_rel, exts)

            {:ok, %{type: :regular}} ->
              if Path.extname(name) in exts, do: [child_rel], else: []

            {:ok, %{type: :symlink}} ->
              if File.regular?(child_abs) and Path.extname(name) in exts,
                do: [child_rel],
                else: []

            _ ->
              []
          end
        end)

      _ ->
        []
    end
  end

  defp prune?(ctx, rel, abs, name) do
    name in @always or String.starts_with?(name, ".") or
      Regex.match?(~r{(^|/)assets/vendor$}, rel) or
      Enum.any?(ctx.lib_dirs, &inside?(abs, &1))
  end

  defp normalise(path), do: path |> String.replace("\\", "/") |> String.trim_leading("./")

  @doc """
  Does a relative path match one of the globs? `**` is any depth, `*` stays
  inside one segment, `?` is one character. A glob with no wildcard also
  matches everything under that directory.
  """
  def excluded?(path, globs), do: Enum.any?(globs, &glob_match?(path, &1))

  def glob_match?(path, glob) do
    glob = normalise(glob) |> String.trim_trailing("/")

    if String.contains?(glob, ["*", "?"]) do
      Regex.match?(glob_regex(glob), path)
    else
      path == glob or String.starts_with?(path, glob <> "/")
    end
  end

  defp glob_regex(glob) do
    body =
      ~r/\*\*\/|\*\*|\*|\?|[^*?]+/
      |> Regex.scan(glob)
      |> Enum.map_join(fn
        ["**/"] -> "(?:.*/)?"
        ["**"] -> ".*"
        ["*"] -> "[^/]*"
        ["?"] -> "[^/]"
        [lit] -> Regex.escape(lit)
      end)

    Regex.compile!("^" <> body <> "$")
  end
end
