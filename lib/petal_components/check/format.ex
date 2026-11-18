defmodule PetalComponents.Check.Format do
  @moduledoc false
  # Text and JSON output for a %Report{}, and the --rules / --explain pages.

  alias Jason.OrderedObject
  alias PetalComponents.Check
  alias PetalComponents.Check.Report

  @guide "guides/design.md section 11"

  # -- text ---------------------------------------------------------------------

  @doc "The text report as a list of lines. Options: :color, :show_baselined, :show_suppressed."
  def text(%Report{} = r, opts \\ []) do
    shown =
      r.findings
      |> Enum.filter(fn f ->
        case f.status do
          :new -> true
          :baselined -> !!opts[:show_baselined]
          :suppressed -> !!opts[:show_suppressed]
        end
      end)

    {errors, warnings} = Enum.split_with(shown, &(&1.severity == :error))
    color = !!opts[:color]

    lines =
      Enum.map(sort(errors), &finding_line(&1, color)) ++
        unchecked_lines(r, color) ++
        Enum.map(sort(warnings), &finding_line(&1, color)) ++
        note_lines(shown)

    body = if lines == [], do: [], else: lines ++ [""]
    body ++ summary_lines(r)
  end

  defp sort(fs), do: Enum.sort_by(fs, &{&1.path, &1.line, &1.column, &1.rule})

  defp finding_line(f, color) do
    status = if f.status == :new, do: "", else: " (#{f.status})"
    fix = if f.replacement in [nil, ""], do: f.fix, else: f.replacement
    note = if f.note, do: ". note: " <> trim_dot(f.note), else: ""

    "#{f.path}:#{f.line}:#{f.column}: #{paint(Atom.to_string(f.severity), f.severity, color)}#{status} " <>
      "[#{f.rule}] #{trim_dot(f.message)}. fix: #{trim_dot(fix)}#{note}"
  end

  defp unchecked_lines(r, color) do
    word = paint("unchecked", :unchecked, color)

    plain =
      for u <- Enum.sort_by(Report.unreadable(r), &{&1.path, &1.line}) do
        "#{u.path}:#{u.line}:#{u.column}: #{word} [#{u.kind}] #{trim_dot(u.reason)}. fix: #{unchecked_fix(u)}"
      end

    tok =
      case Report.tokenizer_unchecked(r) do
        [] ->
          []

        list ->
          n = list |> Enum.map(& &1.path) |> Enum.uniq() |> length()

          [
            "#{word} [tokenizer] HEEx in #{n} #{plural(n, "file")} not checked: #{trim_dot(r.tokenizer_error)}. fix: #{tokenizer_fix(r)}"
          ]
      end

    plain ++ tok
  end

  @doc false
  def unchecked_fix(%{kind: :parse, path: path}) do
    if String.ends_with?(path, ".css"),
      do: "fix the CSS syntax there, then run mix petal.check again",
      else: "fix the syntax error (mix compile shows it), then run mix petal.check again"
  end

  def unchecked_fix(%{kind: :read}),
    do: "save the file as UTF-8 text, then run mix petal.check again"

  def unchecked_fix(%{kind: :internal}),
    do:
      "report it at https://github.com/petalframework/petal_components/issues; the other rules still checked this file"

  def unchecked_fix(%{kind: :tokenizer}), do: "see the tokenizer line"

  @doc false
  def tokenizer_fix(%Report{live_view: lv}) do
    v = minor(lv)

    "this petal_components cannot read HEEx with phoenix_live_view #{v}; run mix deps.update petal_components, " <>
      "or pin phoenix_live_view below #{v}"
  end

  defp minor(nil), do: "(unknown version)"

  defp minor(v) do
    case String.split(v, ".") do
      [a, b | _] -> a <> "." <> b
      _ -> v
    end
  end

  defp note_lines(shown) do
    shown
    |> Enum.map(& &1.rule)
    |> Enum.uniq()
    |> Enum.flat_map(fn id ->
      case Enum.find(Check.rules(), &(&1.id == id)) do
        %{note: note} when is_binary(note) -> ["note [#{id}] #{note}"]
        _ -> []
      end
    end)
  end

  defp summary_lines(%Report{} = r) do
    unchecked_files = r.unchecked |> Enum.map(& &1.path) |> Enum.uniq() |> length()
    errors = length(Report.new_errors(r))
    warnings = length(Report.new_warnings(r))

    [
      "petal.check: #{r.files} #{plural(r.files, "file")} (#{r.heex_files} with HEEx), #{unchecked_files} unchecked. " <>
        "#{errors} new #{plural(errors, "error")}, #{warnings} new #{plural(warnings, "warning")}, " <>
        "#{Report.count(r, :baselined)} baselined, #{Report.count(r, :suppressed)} suppressed."
    ] ++
      narrowing_line(r) ++
      Enum.map(r.skipped, fn {path, why} ->
        "Skipped #{path}: #{why} (pass --include-excluded to check it)."
      end) ++
      stale_line(r) ++
      baseline_hint(r, errors) ++
      change_lines(r) ++
      [not_checked_line()] ++
      strict_line(r, errors, unchecked_files)
  end

  defp narrowing_line(%Report{narrowing: n}) do
    parts =
      [
        n[:only] != [] && n[:only] && "only #{Enum.join(n.only, ", ")} (--only)",
        n[:except] != [] && n[:except] &&
          "rules skipped: #{Enum.join(n.except, ", ")} (--except)",
        (n[:excluded] || 0) > 0 &&
          "#{n.excluded} #{plural(n.excluded, "file")} excluded (--exclude)",
        (n[:paths] || 0) > 0 && "#{n.paths} #{plural(n.paths, "path")} given",
        n[:changed] && "changed files against #{n.changed} (--changed)"
      ]
      |> Enum.filter(&is_binary/1)

    if parts == [], do: [], else: ["Narrowed: " <> Enum.join(parts, "; ") <> "."]
  end

  defp stale_line(%Report{stale: 0}), do: []

  defp stale_line(%Report{stale: n}),
    do: [
      "#{n} baseline #{plural(n, "entry", "entries")} no longer #{if n == 1, do: "matches", else: "match"} " <>
        "(run mix petal.check --prune-baseline to drop #{if n == 1, do: "it", else: "them"})."
    ]

  defp baseline_hint(%Report{mode: :check, baseline_exists: false} = r, errors) when errors > 0 do
    files = r |> Report.new_errors() |> Enum.map(& &1.path) |> Enum.uniq() |> length()

    if files > 1,
      do: [
        "No baseline file. If these findings were already in the app, the app's owner can record them " <>
          "with mix petal.check --update-baseline; your agent should not."
      ],
      else: []
  end

  defp baseline_hint(_r, _errors), do: []

  defp change_lines(%Report{baseline_change: nil}), do: []

  defp change_lines(%Report{baseline_change: c, baseline_path: path, mode: mode}) do
    verb = if mode == :update, do: "updated", else: "pruned"

    [
      "Baseline #{verb} (#{Path.basename(path || "")}): #{c.added_count} added, #{c.removed} removed, #{c.kept} kept."
    ] ++
      for {{rule, p, subject}, n} <- c.added do
        "  added: #{p} [#{rule}] #{subject}" <> if(n > 1, do: " (x#{n})", else: "")
      end
  end

  defp not_checked_line do
    rows = Check.not_checked() |> Enum.map(&elem(&1, 1)) |> Enum.reject(&(&1 == "unknown attrs"))

    "Not checked by this command: #{Enum.join(rows, ", ")} (see #{@guide}). " <>
      "For unknown attrs run mix compile --warnings-as-errors."
  end

  defp strict_line(%Report{strict: false}, _e, _u), do: []
  defp strict_line(%Report{mode: m}, _e, _u) when m != :check, do: []

  defp strict_line(%Report{} = r, errors, _u) do
    counts = "(#{Report.count(r, :suppressed)} suppressed, #{r.excluded} excluded)"
    unreadable = r |> Report.unreadable() |> Enum.map(& &1.path) |> Enum.uniq() |> length()

    case r.exit_status do
      0 ->
        ["petal.check --strict passed #{counts}."]

      1 ->
        ["petal.check --strict failed: #{errors} new #{plural(errors, "error")} #{counts}."]

      2 ->
        [
          "petal.check --strict failed: #{unreadable} #{plural(unreadable, "file")} could not be checked #{counts}."
        ]

      4 ->
        [
          "petal.check --strict failed: HEEx could not be read with this phoenix_live_view #{counts}."
        ]
    end
  end

  defp plural(n, word, many \\ nil)
  defp plural(1, word, _), do: word
  defp plural(_, word, nil), do: word <> "s"
  defp plural(_, _word, many), do: many

  defp trim_dot(nil), do: ""
  defp trim_dot(s), do: String.trim_trailing(s, ".")

  defp paint(word, sev, true) do
    color =
      case sev do
        :error -> IO.ANSI.red()
        :warning -> IO.ANSI.yellow()
        :unchecked -> IO.ANSI.magenta()
      end

    color <> word <> IO.ANSI.reset()
  end

  defp paint(word, _sev, _), do: word

  # -- json ---------------------------------------------------------------------

  @doc """
  One JSON document. `findings` lists every status; your agent acts on
  `status == "new"` with `severity == "error"` (also counted in
  summary.errors). `options` records anything that narrowed the run.
  """
  def json(%Report{} = r) do
    errors = Report.new_errors(r)

    OrderedObject.new([
      {"version", 1},
      {"petal_components", r.petal_components},
      {"phoenix_live_view", r.live_view},
      {"tokenizer", r.tokenizer && inspect(r.tokenizer)},
      {"tokenizer_error", r.tokenizer_error},
      {"options",
       OrderedObject.new([
         {"strict", r.strict},
         {"only", r.narrowing[:only] || []},
         {"except", r.narrowing[:except] || []},
         {"paths_given", r.narrowing[:paths] || 0},
         {"changed_against", r.narrowing[:changed]},
         {"excluded", r.excluded},
         {"baseline", r.baseline_path && Path.basename(r.baseline_path)},
         {"baseline_exists", r.baseline_exists}
       ])},
      {"summary",
       OrderedObject.new([
         {"files", r.files},
         {"heex_files", r.heex_files},
         {"unchecked", r.unchecked |> Enum.map(& &1.path) |> Enum.uniq() |> length()},
         {"errors", length(errors)},
         {"warnings", length(Report.new_warnings(r))},
         {"baselined", Report.count(r, :baselined)},
         {"suppressed", Report.count(r, :suppressed)},
         {"stale_baseline_entries", r.stale}
       ])},
      {"findings", r.findings |> sort_all() |> Enum.map(&finding_json/1)},
      {"unchecked",
       Enum.map(r.unchecked, fn u ->
         OrderedObject.new([
           {"file", u.path},
           {"line", u.line},
           {"column", u.column},
           {"kind", Atom.to_string(u.kind)},
           {"reason", u.reason},
           {"fix", if(u.kind == :tokenizer, do: tokenizer_fix(r), else: unchecked_fix(u))}
         ])
       end)},
      {"skipped",
       Enum.map(r.skipped, fn {p, why} -> OrderedObject.new([{"file", p}, {"reason", why}]) end)},
      {"baseline_change", change_json(r.baseline_change)},
      {"not_checked", Enum.map(Check.not_checked(), fn {row, label} -> "#{row} #{label}" end)},
      {"exit_status", r.exit_status}
    ])
    |> Jason.encode!(pretty: true)
  end

  defp sort_all(fs) do
    Enum.sort_by(
      fs,
      &{if(&1.severity == :error, do: 0, else: 1), &1.path, &1.line, &1.column, &1.rule}
    )
  end

  defp finding_json(f) do
    OrderedObject.new([
      {"file", f.path},
      {"line", f.line},
      {"column", f.column},
      {"rule", f.rule},
      {"severity", Atom.to_string(f.severity)},
      {"status", Atom.to_string(f.status)},
      {"section", f.section},
      {"message", f.message},
      {"subject", f.subject},
      {"replacement", f.replacement},
      {"fix", f.fix},
      {"note", f.note},
      {"add_attr", f.add_attr && OrderedObject.new([{"name", f.add_attr}])},
      {"fingerprint", f.fingerprint}
    ])
  end

  defp change_json(nil), do: nil

  defp change_json(c) do
    OrderedObject.new([
      {"added", c.added_count},
      {"removed", c.removed},
      {"kept", c.kept},
      {"added_entries",
       for {{rule, p, s}, n} <- c.added do
         OrderedObject.new([{"rule", rule}, {"path", p}, {"subject", s}, {"count", n}])
       end}
    ])
  end

  # -- --rules and --explain -------------------------------------------------------

  def rules_text(rules) do
    width = rules |> Enum.map(&String.length(&1.id)) |> Enum.max(fn -> 10 end)

    Enum.map(rules, fn r ->
      "#{String.pad_trailing(r.id, width)}  #{String.pad_trailing(Atom.to_string(r.severity), 7)}  " <>
        "section #{String.pad_trailing(r.section, 5)}  #{r.why}"
    end) ++
      [
        "",
        "About the suppression comments themselves (warnings, never baselined): " <>
          Enum.join(PetalComponents.Check.Suppressions.meta_rules(), ", ") <> ".",
        not_checked_line()
      ]
  end

  def explain_text(r) do
    ["#{r.id} (#{r.severity})", "", r.why, "", "Guide: " <> guide_ref(r.section)] ++
      if(r.note, do: ["", r.note], else: []) ++
      if(r.exemptions == [],
        do: [],
        else: ["", "Not flagged:" | Enum.map(r.exemptions, &("  - " <> &1))]
      ) ++
      if(r.examples == [],
        do: [],
        else: [
          "",
          "Examples:"
          | Enum.map(r.examples, fn {kind, text} ->
              "  #{if kind == :bad, do: "flags:     ", else: "fine:      "}#{text}"
            end)
        ]
      ) ++ ["", "Suppress one case with a comment: petal-check:ignore #{r.id}: why this is fine"]
  end

  @doc "Where a rule's section lives: `11.10` is row 10 of section 11."
  def guide_ref(section) do
    case String.split(section, ".") do
      ["11", row] -> "guides/design.md section 11, row #{row}"
      [n] -> "guides/design.md section #{n}"
      _ -> "guides/design.md section #{section}"
    end
  end
end
