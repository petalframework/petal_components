defmodule PetalComponents.Check do
  @moduledoc false
  # The engine behind `mix petal.check`. No Mix calls: the task resolves the
  # project layout and passes it in, so tests call run/1 directly.

  alias PetalComponents.Check.Baseline
  alias PetalComponents.Check.Components
  alias PetalComponents.Check.ElixirAst
  alias PetalComponents.Check.Files
  alias PetalComponents.Check.Finding
  alias PetalComponents.Check.Heex
  alias PetalComponents.Check.Report
  alias PetalComponents.Check.Rule
  alias PetalComponents.Check.Rules
  alias PetalComponents.Check.Source
  alias PetalComponents.Check.Suppressions

  # In the order of the guide's checks.
  @rules [
    Rules.ComboboxVariant,
    Rules.LiteralNeutral
  ]

  # Section 11 rows this command does not check; the reader checks them by hand.
  @not_checked [
    {"11.3", "overlays"},
    {"11.6", "keyframes"},
    {"11.7", "raw HTML"},
    {"11.8", "dark pairs"},
    {"11.13", "unknown attrs"}
  ]

  @doc "Every rule, as `%Rule{}` with `:module` set."
  def rules(modules \\ @rules), do: Enum.map(modules, &%{&1.rule() | module: &1})

  def rule_ids(modules \\ @rules), do: Enum.map(rules(modules), & &1.id)

  def rule!(id, modules \\ @rules),
    do: Enum.find(rules(modules), &(&1.id == id)) || raise(ArgumentError, "no rule #{id}")

  def not_checked, do: @not_checked

  @doc """
  Runs a check. Options (all but `:root` optional):

    * `:root`, `:apps`, `:library_dirs`, `:paths`, `:changed`, `:exclude`,
      `:include_excluded` - see `PetalComponents.Check.Files`
    * `:changed_ref` - the git ref `:changed` was computed against (for the summary)
    * `:only`, `:except` - rule ids
    * `:baseline` - absolute path; `:baseline_explicit` - it was given with --baseline
    * `:no_baseline`, `:update_baseline`, `:prune_baseline`, `:strict`
    * `:rules` - rule modules (tests); `:tokenizer` - `{:ok, mod} | {:error, why}` (tests);
      `:petal_names` - a MapSet (tests)

  Returns `{:ok, %Report{}}` or `{:error, usage_message}`.
  """
  def run(opts) do
    modules = Keyword.get(opts, :rules, @rules)
    all = rules(modules)
    only = Keyword.get(opts, :only, [])
    except = Keyword.get(opts, :except, [])

    enabled =
      Enum.filter(all, fn r -> (only == [] or r.id in only) and r.id not in except end)

    with {:ok, files} <- Files.discover(opts),
         {:ok, entries, exists?} <- load_baseline(opts) do
      {:ok, execute(opts, all, enabled, files, entries, exists?)}
    end
  end

  defp load_baseline(opts) do
    cond do
      opts[:no_baseline] -> {:ok, %{}, false}
      path = opts[:baseline] -> Baseline.load(path, !!opts[:baseline_explicit])
      true -> {:ok, %{}, false}
    end
  end

  defp execute(opts, all, enabled, files, entries, exists?) do
    root = Keyword.fetch!(opts, :root)
    tok = Keyword.get_lazy(opts, :tokenizer, &Heex.tokenizer/0)
    names = Keyword.get_lazy(opts, :petal_names, &Components.petal_names/0)

    excepts =
      project_excepts(
        root,
        Enum.uniq(files.project_ex ++ Enum.filter(files.checked, &String.ends_with?(&1, ".ex")))
      )

    per_source = Enum.reject(enabled, &(&1.scope == :project))

    # Each file is read and checked in its own process. Only findings and a
    # slim source (no units or tags, whose position closures hold the whole
    # file) come back, so nothing large is copied between processes.
    {sources, findings} =
      files.checked
      |> Task.async_stream(
        fn rel ->
          source = Source.read(Path.join(root, rel), rel, tok)
          info = %{names: names, excepts: excepts, defs: source.defs, aliases: source.aliases}
          info = with_colocated(info, source, root)
          {source, found} = run_source(source, per_source, info)
          {%{source | units: [], tags: [], ast: nil}, found}
        end,
        ordered: true,
        timeout: :infinity,
        max_concurrency: System.schedulers_online()
      )
      |> Enum.map(fn {:ok, result} -> result end)
      |> Enum.unzip()

    findings = List.flatten(findings)

    {sources, project_found} = run_project(enabled, sources, files, root, tok)
    findings = findings ++ project_found

    known = Enum.map(all, & &1.id)
    ran = Enum.map(enabled, & &1.id)

    {findings, meta} =
      Enum.reduce(sources, {[], []}, fn source, {fs, meta} ->
        mine = Enum.filter(findings, &(&1.path == source.path))
        {mine, m} = Suppressions.apply(source, mine, known, ran)
        {fs ++ mine, meta ++ m}
      end)

    mode =
      cond do
        opts[:update_baseline] -> :update
        opts[:prune_baseline] -> :prune
        true -> :check
      end

    unchecked_paths = for s <- sources, s.unchecked != [], into: MapSet.new(), do: s.path
    checked_paths = for s <- sources, s.unchecked == [], into: MapSet.new(), do: s.path

    {entries, change} =
      case mode do
        :check ->
          {entries, nil}

        :update ->
          new = Baseline.updated(entries, findings, unchecked_paths)
          {new, Baseline.diff(entries, new)}

        :prune ->
          new = Baseline.pruned(entries, findings, unchecked_paths)
          {new, Baseline.diff(entries, new)}
      end

    if mode != :check, do: File.write!(opts[:baseline], Baseline.encode(entries))

    findings = Baseline.mark(findings, entries)

    stale = if mode == :check, do: Baseline.stale(entries, findings, ran, checked_paths), else: 0

    %Report{
      files: length(sources),
      heex_files: Enum.count(sources, & &1.heex?),
      findings: Enum.map(findings ++ meta, &with_fingerprint/1),
      unchecked: for(s <- sources, u <- s.unchecked, do: Map.put(u, :path, s.path)),
      skipped: files.skipped,
      excluded: files.excluded,
      stale: stale,
      baseline_exists: exists? or mode != :check,
      baseline_path: opts[:baseline],
      baseline_change: change,
      tokenizer: tok_module(tok),
      tokenizer_error: tok_error(tok),
      live_view: Heex.live_view_version(),
      petal_components: version(),
      rules_run: ran,
      narrowing: %{
        only: Keyword.get(opts, :only, []),
        except: Keyword.get(opts, :except, []),
        excluded: files.excluded,
        paths: length(Keyword.get(opts, :paths) || []),
        changed: if(is_list(opts[:changed]), do: opts[:changed_ref] || "HEAD")
      },
      strict: !!opts[:strict],
      mode: mode
    }
    |> Report.finalize()
  end

  defp tok_module({:ok, mod}), do: mod
  defp tok_module(_), do: nil
  defp tok_error({:error, why}), do: why
  defp tok_error(_), do: nil

  defp with_fingerprint(%Finding{} = f),
    do: %{f | fingerprint: Finding.fingerprint(f.rule, f.path, f.subject)}

  defp version do
    _ = Application.load(:petal_components)

    case Application.spec(:petal_components, :vsn) do
      nil -> nil
      v -> to_string(v)
    end
  end

  # -- per source -----------------------------------------------------------------

  defp run_source(source, rules, info) do
    ctx = %{
      path: source.path,
      kind: source.kind,
      source: source,
      petal?: &Components.petal?(&1, info)
    }

    Enum.reduce(rules, {source, []}, fn rule, {source, acc} ->
      try do
        found =
          rule
          |> items(source)
          |> Enum.flat_map(&rule.module.check(&1, ctx))
          |> Enum.map(&%{&1 | path: source.path})

        {source, acc ++ found}
      rescue
        e ->
          reason =
            "internal error in rule #{rule.id} (please report): " <>
              first_line(Exception.message(e))

          {Source.unchecked(source, {1, 1}, reason, :internal), acc}
      end
    end)
  end

  defp items(%Rule{scope: :component}, s), do: s.tags
  defp items(%Rule{scope: :class_unit}, s), do: s.units
  defp items(%Rule{scope: :css}, s), do: if(s.kind == :css, do: s.statements, else: [])
  defp items(%Rule{scope: :elixir_ast}, s), do: if(s.ast, do: [s.ast], else: [])

  # Project rules (a ramp split across CSS files) always read every CSS file
  # under the default roots, whatever paths the run was given, and report
  # only in the files this run checks. If any input could not be read, they
  # report nothing: a partial picture is how a false alarm happens.
  defp run_project(enabled, sources, files, root, tok) do
    project = Enum.filter(enabled, &(&1.scope == :project))

    if project == [] do
      {sources, []}
    else
      checked = MapSet.new(Enum.map(sources, & &1.path))

      extra =
        for rel <- files.project_css,
            not MapSet.member?(checked, rel),
            do: Source.read(Path.join(root, rel), rel, tok)

      inputs = sources ++ extra

      found =
        if Enum.any?(inputs, &(&1.unchecked != [])) do
          []
        else
          Enum.flat_map(project, fn rule ->
            ctx = %{root: root}

            try do
              collected = Enum.map(inputs, &rule.module.collect(&1, Map.put(ctx, :path, &1.path)))
              rule.module.finish(collected, ctx)
            rescue
              _ -> []
            end
          end)
        end

      {sources, Enum.filter(found, &MapSet.member?(checked, &1.path))}
    end
  end

  # -- what the app shadows ---------------------------------------------------------

  # `import PetalComponents.X, except: [name: 1]` anywhere in the app means
  # the app has its own `name`. Read from every .ex under the default roots,
  # so a run on one changed file still knows.
  defp project_excepts(root, ex_files) do
    Enum.reduce(ex_files, MapSet.new(), fn rel, acc ->
      case File.read(Path.join(root, rel)) do
        {:ok, text} -> MapSet.union(acc, scan_excepts(text))
        _ -> acc
      end
    end)
  end

  @doc false
  def scan_excepts(text) do
    ~r/import\s+PetalComponents\.[\w.]+\s*,\s*except:\s*\[([^\]]*)\]/
    |> Regex.scan(text)
    |> Enum.flat_map(fn [_, list] -> Regex.scan(~r/(\w+[?!]?)\s*:/, list) end)
    |> Enum.map(fn [_, name] -> name end)
    |> MapSet.new()
  end

  # A .heex file's functions and aliases are its module's: `foo_live.ex`
  # beside `foo_live.html.heex`, or `layouts.ex` for `layouts/*.html.heex`.
  defp with_colocated(info, %Source{kind: :heex, path: path}, root) do
    dir = Path.dirname(path)
    base = path |> Path.basename() |> String.replace(~r/(\.html)?\.heex$/, "")
    candidates = [Path.join(dir, base <> ".ex"), dir <> ".ex"]

    Enum.reduce(candidates, info, fn rel, info ->
      case colocated(rel, root) do
        nil ->
          info

        %{defs: d, aliases: a} ->
          %{info | defs: MapSet.union(info.defs, d), aliases: Map.merge(a, info.aliases)}
      end
    end)
  end

  defp with_colocated(info, _source, _root), do: info

  defp colocated(rel, root) do
    with {:ok, src} <- File.read(Path.join(root, rel)),
         {:ok, ast, _} <- ElixirAst.parse(src, rel) do
      info = ElixirAst.collect(ast, PetalComponents.Check.Pos.lines(src))
      %{defs: info.defs, aliases: info.aliases}
    else
      _ -> nil
    end
  end

  defp first_line(s), do: s |> String.split("\n") |> hd()
end
