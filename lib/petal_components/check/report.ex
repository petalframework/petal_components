defmodule PetalComponents.Check.Report do
  @moduledoc false
  # The result of one run. The engine fills it in and never exits; the Mix
  # task prints it and turns exit_status into the process status.

  defstruct files: 0,
            heex_files: 0,
            findings: [],
            unchecked: [],
            skipped: [],
            excluded: 0,
            stale: 0,
            baseline_exists: false,
            baseline_path: nil,
            baseline_change: nil,
            tokenizer: nil,
            tokenizer_error: nil,
            live_view: nil,
            petal_components: nil,
            rules_run: [],
            narrowing: %{},
            strict: false,
            mode: :check,
            exit_status: 0

  @type t :: %__MODULE__{}

  def new_errors(%__MODULE__{findings: fs}),
    do: Enum.filter(fs, &(&1.status == :new and &1.severity == :error))

  def new_warnings(%__MODULE__{findings: fs}),
    do: Enum.filter(fs, &(&1.status == :new and &1.severity == :warning))

  def count(%__MODULE__{findings: fs}, status), do: Enum.count(fs, &(&1.status == status))

  @doc "Files that could not be read (not the tokenizer case)."
  def unreadable(%__MODULE__{unchecked: u}), do: Enum.reject(u, &(&1.kind == :tokenizer))

  def tokenizer_unchecked(%__MODULE__{unchecked: u}), do: Enum.filter(u, &(&1.kind == :tokenizer))

  @doc """
  Exit status. Advisory runs and baseline updates are always 0. Under
  --strict: 1 new errors, 2 a file could not be read, 4 the HEEx tokenizer
  of this LiveView is not one this petal_components knows (so CI can choose
  to tolerate it). 3 (usage) never reaches a report.
  """
  def finalize(%__MODULE__{} = r) do
    status =
      cond do
        r.mode != :check -> 0
        not r.strict -> 0
        new_errors(r) != [] -> 1
        unreadable(r) != [] -> 2
        tokenizer_unchecked(r) != [] -> 4
        true -> 0
      end

    %{r | exit_status: status}
  end
end
