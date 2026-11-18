defmodule Mix.Tasks.Petal.Check do
  @shortdoc "Checks templates and CSS against the petal_components design rules"

  @moduledoc """
  Reads your app's `.ex`, `.heex` and `.css` files and reports the design
  mistakes a machine can find: one line per problem, with the file, the line,
  the rule and the exact text to write instead. It never compiles or starts
  your app.

      mix petal.check                 # report only, exit 0
      mix petal.check --strict        # exit non-zero on new errors (CI)
      mix petal.check --strict --changed
      mix petal.check --strict --format json --output petal-check.json

  ## For your agent

  Run `mix petal.check --strict --changed` after you change templates or CSS.
  `--changed` checks the files that differ from git HEAD, plus new files
  git does not track yet.

    * Exit 0: done.
    * Exit 1: fix each error on lines you wrote, then run it again. If it
      reports errors in files you did not change, do not fix them unasked:
      list them for the user.
    * Exit 2: a file could not be read. Fix its syntax.
    * Exit 3: the command line is wrong. The message says why.
    * Exit 4: this petal_components cannot read HEEx with the installed
      phoenix_live_view. Tell the user; the line printed says what to update.

  Warnings never change the exit code. Fix the ones on lines you wrote if the
  suggestion fits. The baseline flags, `--exclude`, `--except` and
  `petal-check` comments are for the app's owner: do not use them unless the
  user asks.

  For JSON, write it to a file with `--output`: Mix prints its own compile
  lines on stdout the first time after `mix deps.get`, which would break a
  JSON parser reading stdout. Act on findings with `"status": "new"` and
  `"severity": "error"`; the `summary.errors` count is those. When a finding
  has a `replacement`, it is the exact text that replaces `subject` at its
  line and column (`""` means delete it); `fix` says the same in words.

  ## Options

      --strict              exit 1 on new errors, 2 on a file that could not be read,
                            4 when HEEx cannot be read with this LiveView
      --changed             check only files changed against HEAD, plus untracked ones
      --since REF           the same, against REF (a branch or commit)
      --format text|json    default text
      --output PATH         write the report to PATH instead of stdout
      --only RULE[,RULE]    run only these rules (repeatable)
      --show-baselined      also print baselined findings
      --show-suppressed     also print suppressed findings
      --rules               list every rule
      --explain RULE        explain one rule, with an example
      --color, --no-color   override terminal detection (NO_COLOR is honoured)
      --help                print this page

  Owner only (your agent should not use these unless asked):

      --except RULE[,RULE]  skip these rules (repeatable)
      --exclude GLOB        skip matching files (repeatable; ** any depth, * one segment)
      --include-excluded    check explicit paths under test/, priv/ or deps/ too
      --baseline PATH       default .petal-check-baseline.json
      --no-baseline         ignore the baseline
      --update-baseline     record every current finding in the baseline
      --prune-baseline      drop baseline entries that no longer match; never adds

  Anything that narrows a run (`--only`, `--except`, `--exclude`, path
  arguments, `--changed`) is named in the summary, and under `--strict` the
  last line prints the suppressed and excluded counts.

  ## Exit codes

  | situation                                     | plain | --strict |
  |-----------------------------------------------|-------|----------|
  | nothing new                                   | 0     | 0        |
  | new errors                                    | 0     | 1        |
  | a file could not be read (and no new errors)  | 0     | 2        |
  | wrong flags, unknown rule, missing path       | 3     | 3        |
  | HEEx unreadable with this LiveView            | 0     | 4        |
  | --update-baseline or --prune-baseline         | 0     | 0        |

  ## What is read

  With no path arguments: `lib/**/*.ex`, `lib/**/*.heex` and
  `assets/**/*.css`, or the same under each child app at an umbrella root.
  Never `deps/`, `_build/`, `node_modules/`, `assets/vendor/`, `test/` or
  `priv/`, or petal_components' own source. Path arguments replace the
  default roots; an explicit path under `test/`, `priv/` or `deps/` is
  skipped with a note unless `--include-excluded` is given.

  Class rules read string literals and attr values only, through the
  Elixir parser and LiveView's HEEx tokenizer, so comments, docs and prose
  are never flagged. A file that cannot be parsed is reported as unchecked,
  never as clean.

  ## Rules

  Run `mix petal.check --rules` for the list and `--explain RULE` for one.
  Errors: combobox-variant, literal-neutral.

  Not checked by this command (see guides/design.md section 11): overlays,
  keyframes, raw HTML, dark pairs. For unknown attrs run
  `mix compile --warnings-as-errors`.

  ## Exceptions

  For one case, put a comment on the line before (or at the end of the line):

      # petal-check:ignore literal-neutral: a deliberate before/after demo
      <%!-- petal-check:ignore combobox-variant: why this is fine --%>
      /* petal-check:ignore literal-neutral: why */

  A comment above a multi-line tag covers every attr of that tag. For a range,
  use `petal-check:disable RULE` and `petal-check:enable RULE`. Every comment
  must name its rules and give a reason after a colon. Suppressed findings are
  still counted, and a comment that matches nothing, has no reason, or is
  never closed is reported as a warning.

  ## Baseline

  An app with existing findings can record them once:
  `mix petal.check --update-baseline` writes `.petal-check-baseline.json`
  (commit it). After that only new findings fail `--strict`. Entries are keyed
  on rule, file and the text matched, not the line, so edits above a finding
  keep it recorded. `--prune-baseline` drops entries that were fixed. A
  baseline belongs to the directory it was made from (an umbrella root and a
  child app see different paths).
  """

  use Mix.Task

  alias PetalComponents.Check
  alias PetalComponents.Check.Baseline
  alias PetalComponents.Check.Format
  alias PetalComponents.Check.Options
  alias PetalComponents.Check.Report

  @impl Mix.Task
  def run(argv) do
    opts =
      case Options.parse(argv, Check.rule_ids()) do
        {:ok, opts} -> opts
        {:error, message} -> Mix.raise(message, exit_status: 3)
      end

    case opts.action do
      :help ->
        Mix.shell().info(@moduledoc)

      :rules ->
        Enum.each(Format.rules_text(Check.rules()), &Mix.shell().info/1)

      :explain ->
        Enum.each(Format.explain_text(Check.rule!(opts.explain)), &Mix.shell().info/1)

      :check ->
        check(opts)
    end
  end

  defp check(%Options{} = opts) do
    Mix.Task.run("loadpaths")
    root = File.cwd!()

    changed =
      case opts.changed do
        nil -> nil
        ref -> git_changed(root, ref)
      end

    if changed == [] do
      Mix.shell().info(
        "petal.check: no changed .ex, .heex or .css files under lib/ or assets/ against #{opts.changed}."
      )
    else
      report(opts, root, changed)
    end
  end

  defp report(opts, root, changed) do
    engine_opts = [
      root: root,
      apps: apps(root),
      library_dirs: library_dirs(),
      paths: opts.paths,
      changed: changed,
      changed_ref: opts.changed,
      exclude: opts.exclude,
      include_excluded: opts.include_excluded,
      only: opts.only,
      except: opts.except,
      no_baseline: opts.no_baseline,
      baseline: Path.expand(opts.baseline || Baseline.default_path(), root),
      baseline_explicit: opts.baseline != nil,
      update_baseline: opts.update_baseline,
      prune_baseline: opts.prune_baseline,
      strict: opts.strict
    ]

    case Check.run(engine_opts) do
      {:error, message} ->
        Mix.raise(message, exit_status: 3)

      {:ok, %Report{} = report} ->
        output(report, opts)

        case report.exit_status do
          0 -> :ok
          n -> exit({:shutdown, n})
        end
    end
  end

  defp output(report, %Options{format: format, output: path} = opts) do
    text =
      case format do
        :json ->
          Format.json(report)

        :text ->
          report
          |> Format.text(
            color: color?(opts),
            show_baselined: opts.show_baselined,
            show_suppressed: opts.show_suppressed
          )
          |> Enum.join("\n")
      end

    if path do
      File.write!(path, text <> "\n")
      errors = length(Report.new_errors(report))
      unchecked = report.unchecked |> Enum.map(& &1.path) |> Enum.uniq() |> length()

      Mix.shell().info(
        "petal.check: report written to #{path} (#{errors} new errors, #{unchecked} unchecked, exit #{report.exit_status})"
      )
    else
      Mix.shell().info(text)
    end
  end

  defp color?(%Options{color: c}) when is_boolean(c), do: c

  defp color?(%Options{format: :text, output: nil}) do
    IO.ANSI.enabled?() and System.get_env("NO_COLOR") in [nil, ""]
  end

  defp color?(_), do: false

  # Child apps at an umbrella root, relative to the root; "." otherwise.
  defp apps(root) do
    if Mix.Project.umbrella?() do
      Mix.Project.apps_paths()
      |> Map.values()
      |> Enum.map(&Path.relative_to(&1, root))
      |> Enum.sort()
    else
      ["."]
    end
  end

  # petal_components' own source, wherever it sits: as a dependency, as an
  # umbrella child, or as the current project. Its raw tags and internal
  # !important rules are the implementation, not app code.
  defp library_dirs do
    self =
      if Mix.Project.config()[:app] == :petal_components,
        do: [Path.dirname(Mix.Project.project_file())],
        else: []

    roots =
      [
        Mix.Project.deps_paths()[:petal_components],
        if(Mix.Project.umbrella?(), do: Mix.Project.apps_paths()[:petal_components])
      ] ++ self

    for dir <- roots, dir != nil, sub <- ["lib", "assets"], do: Path.join(dir, sub)
  end

  # Files changed against `ref` plus untracked ones, relative to the root.
  defp git_changed(root, ref) do
    diff = git(root, ["diff", "--name-only", "--relative", "--diff-filter=d", ref])
    untracked = git(root, ["ls-files", "--others", "--exclude-standard"])
    Enum.uniq(diff ++ untracked)
  end

  defp git(root, args) do
    case System.cmd("git", args, cd: root, stderr_to_stdout: true) do
      {out, 0} ->
        String.split(out, "\n", trim: true)

      {out, _} ->
        Mix.raise("--changed needs git: git #{Enum.join(args, " ")} failed: #{String.trim(out)}",
          exit_status: 3
        )
    end
  rescue
    e in ErlangError ->
      Mix.raise("--changed needs git, which could not be run (#{inspect(e.original)})",
        exit_status: 3
      )
  end
end
