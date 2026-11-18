defmodule PetalComponents.Check.Baseline do
  @moduledoc false
  # The baseline records findings that were already in the app, so --strict
  # only fails on new ones. Keyed on {rule, path, subject} with a count, and
  # no line number, so edits above a finding keep it baselined.
  #
  # Matching is by count: for a key stored with count N, the first N findings
  # of that key in line order are :baselined and the rest are :new. So a new
  # copy of an old token added ABOVE the old one marks the old line as new and
  # hides the new one. The total is still right, which is what --strict
  # gates on.

  alias PetalComponents.Check.Finding

  @default ".petal-check-baseline.json"

  def default_path, do: @default

  @doc """
  Loads a baseline. A missing default file is an empty baseline; a missing
  explicit file, or one that does not parse, is a usage error.
  Returns `{:ok, %{key => count}, exists?}` or `{:error, message}`.
  """
  def load(abs, explicit?) do
    case File.read(abs) do
      {:ok, text} ->
        case decode(text) do
          {:ok, entries} ->
            {:ok, entries, true}

          :error ->
            {:error,
             "the baseline file #{abs} is not a petal.check baseline (expected {\"version\": 1, \"entries\": [...]})"}
        end

      {:error, :enoent} when not explicit? ->
        {:ok, %{}, false}

      {:error, reason} ->
        {:error, "the baseline file #{abs} could not be read (#{:file.format_error(reason)})"}
    end
  end

  defp decode(text) do
    with {:ok, %{"version" => 1, "entries" => entries}} when is_list(entries) <-
           Jason.decode(text),
         true <- Enum.all?(entries, &entry?/1) do
      {:ok,
       Enum.reduce(entries, %{}, fn e, acc ->
         Map.update(acc, {e["rule"], e["path"], e["subject"]}, e["count"], &(&1 + e["count"]))
       end)}
    else
      _ -> :error
    end
  end

  defp entry?(%{"rule" => r, "path" => p, "subject" => s, "count" => n})
       when is_binary(r) and is_binary(p) and is_binary(s) and is_integer(n) and n > 0,
       do: true

  defp entry?(_), do: false

  @doc "Marks baselined findings. Only :new, non-meta findings are candidates."
  def mark(findings, entries) when entries == %{}, do: findings

  def mark(findings, entries) do
    {marked, _} =
      findings
      |> Enum.with_index()
      |> Enum.sort_by(fn {f, i} -> {f.path, f.line, f.column, i} end)
      |> Enum.map_reduce(entries, fn {f, i}, left ->
        key = Finding.key(f)

        case Map.get(left, key, 0) do
          n when n > 0 and f.status == :new and not f.meta ->
            {{%{f | status: :baselined}, i}, Map.put(left, key, n - 1)}

          _ ->
            {{f, i}, left}
        end
      end)

    marked |> Enum.sort_by(&elem(&1, 1)) |> Enum.map(&elem(&1, 0))
  end

  @doc """
  Entries whose stored count is above what this run found. Only keys whose
  rule ran and whose file was fully checked this run count.
  """
  def stale(entries, findings, ran_rules, checked_paths) do
    found = counts(findings)

    Enum.reduce(entries, 0, fn {{rule, path, _} = key, n}, acc ->
      if rule in ran_rules and MapSet.member?(checked_paths, path) and Map.get(found, key, 0) < n,
        do: acc + 1,
        else: acc
    end)
  end

  @doc "Counts per key for the findings a baseline records (not meta, not suppressed)."
  def counts(findings) do
    findings
    |> Enum.filter(&recordable?/1)
    |> Enum.frequencies_by(&Finding.key/1)
  end

  def recordable?(%Finding{meta: false, status: s}) when s in [:new, :baselined], do: true
  def recordable?(_), do: false

  @doc """
  The entries --update-baseline writes: this run's counts, plus the old
  entries of files that could not be checked (their findings are unknown, so
  dropping them would make every old finding new once the file parses again).
  """
  def updated(entries, findings, unchecked_paths) do
    kept =
      for {{_, path, _} = k, n} <- entries,
          MapSet.member?(unchecked_paths, path),
          into: %{},
          do: {k, n}

    Map.merge(counts(findings), kept)
  end

  @doc "The entries --prune-baseline writes: never adds a key or raises a count."
  def pruned(entries, findings, unchecked_paths) do
    found = counts(findings)

    for {{_, path, _} = k, n} <- entries,
        keep =
          if(MapSet.member?(unchecked_paths, path), do: n, else: min(n, Map.get(found, k, 0))),
        keep > 0,
        into: %{},
        do: {k, keep}
  end

  @doc "What changed between two entry maps: `%{added: [{key, n}], removed: count, kept: count}`."
  def diff(old, new) do
    keys = MapSet.union(MapSet.new(Map.keys(old)), MapSet.new(Map.keys(new)))

    Enum.reduce(keys, %{added: [], added_count: 0, removed: 0, kept: 0}, fn k, acc ->
      o = Map.get(old, k, 0)
      n = Map.get(new, k, 0)

      acc = %{acc | kept: acc.kept + min(o, n), removed: acc.removed + max(o - n, 0)}

      if n > o,
        do: %{acc | added: [{k, n - o} | acc.added], added_count: acc.added_count + n - o},
        else: acc
    end)
    |> Map.update!(:added, &Enum.sort/1)
  end

  @doc """
  The file text. Written by hand for a stable key order and small diffs;
  every scalar goes through Jason, so quotes and backslashes stay valid.
  """
  def encode(entries) do
    lines =
      entries
      |> Enum.sort_by(fn {{rule, path, subject}, _} -> {path, rule, subject} end)
      |> Enum.map(fn {{rule, path, subject}, n} ->
        "    {\"rule\": #{j(rule)}, \"path\": #{j(path)}, \"subject\": #{j(subject)}, " <>
          "\"count\": #{n}, \"fingerprint\": #{j(Finding.fingerprint(rule, path, subject))}}"
      end)

    body =
      if lines == [],
        do: "  \"entries\": []\n",
        else: "  \"entries\": [\n" <> Enum.join(lines, ",\n") <> "\n  ]\n"

    "{\n  \"version\": 1,\n" <> body <> "}\n"
  end

  defp j(v), do: Jason.encode!(v)
end
