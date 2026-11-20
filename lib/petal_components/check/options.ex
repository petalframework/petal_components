defmodule PetalComponents.Check.Options do
  @moduledoc false
  # argv -> options. Every problem here is a usage error (exit 3) whose
  # message lists the valid values.

  @switches [
    strict: :boolean,
    format: :string,
    output: :string,
    changed: :boolean,
    since: :string,
    only: :keep,
    except: :keep,
    exclude: :keep,
    include_excluded: :boolean,
    baseline: :string,
    no_baseline: :boolean,
    update_baseline: :boolean,
    prune_baseline: :boolean,
    show_baselined: :boolean,
    show_suppressed: :boolean,
    rules: :boolean,
    explain: :string,
    color: :boolean,
    help: :boolean
  ]

  defstruct strict: false,
            format: :text,
            output: nil,
            changed: nil,
            only: [],
            except: [],
            exclude: [],
            include_excluded: false,
            baseline: nil,
            no_baseline: false,
            update_baseline: false,
            prune_baseline: false,
            show_baselined: false,
            show_suppressed: false,
            action: :check,
            explain: nil,
            color: nil,
            paths: []

  @doc "`{:ok, %Options{}}` or `{:error, message}`. `rule_ids` are the valid ids."
  def parse(argv, rule_ids) do
    {opts, paths, invalid} = OptionParser.parse(argv, strict: @switches)

    with :ok <- no_invalid(invalid),
         {:ok, format} <- format(opts[:format]),
         {:ok, only} <- ids(opts, :only, rule_ids),
         {:ok, except} <- ids(opts, :except, rule_ids),
         :ok <- disjoint(only, except),
         {:ok, explain} <- explain(opts[:explain], rule_ids),
         :ok <- since(opts[:since]) do
      o = %__MODULE__{
        strict: !!opts[:strict],
        format: format,
        output: opts[:output],
        changed: changed(opts),
        only: only,
        except: except,
        exclude: Keyword.get_values(opts, :exclude),
        include_excluded: !!opts[:include_excluded],
        baseline: opts[:baseline],
        no_baseline: !!opts[:no_baseline],
        update_baseline: !!opts[:update_baseline],
        prune_baseline: !!opts[:prune_baseline],
        show_baselined: !!opts[:show_baselined],
        show_suppressed: !!opts[:show_suppressed],
        explain: explain,
        color: opts[:color],
        paths: paths,
        action:
          cond do
            opts[:help] -> :help
            opts[:rules] -> :rules
            explain -> :explain
            true -> :check
          end
      }

      validate(o)
    end
  end

  defp no_invalid([]), do: :ok

  # `--since --strict`: OptionParser will not take a dash-led value, so the
  # flag arrives here with no value.
  defp no_invalid([{"--since", nil} | _]),
    do: {:error, "--since needs a git ref (a branch or commit), for example --since main"}

  defp no_invalid([{flag, _} | _]),
    do: {:error, "unknown option #{flag}. Run mix help petal.check for the options."}

  defp format(nil), do: {:ok, :text}
  defp format("text"), do: {:ok, :text}
  defp format("json"), do: {:ok, :json}
  defp format(other), do: {:error, "--format #{other} is not known; use text or json"}

  defp ids(opts, key, known) do
    given =
      opts
      |> Keyword.get_values(key)
      |> Enum.flat_map(&String.split(&1, ","))
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    case Enum.reject(given, &(&1 in known)) do
      [] ->
        {:ok, Enum.uniq(given)}

      bad ->
        {:error,
         "--#{key}: #{Enum.join(bad, ", ")} is not a rule. Rules: #{Enum.join(known, ", ")}"}
    end
  end

  defp disjoint(only, except) do
    case Enum.filter(only, &(&1 in except)) do
      [] -> :ok
      both -> {:error, "#{Enum.join(both, ", ")} is in both --only and --except"}
    end
  end

  defp explain(nil, _), do: {:ok, nil}

  defp explain(id, known) do
    if id in known,
      do: {:ok, id},
      else: {:error, "--explain #{id}: not a rule. Rules: #{Enum.join(known, ", ")}"}
  end

  # The ref goes to git as an argument; one that starts with a dash would be
  # read as a git option (--output=FILE writes a file).
  defp since("-" <> _ = ref),
    do: {:error, "--since #{ref}: a git ref (a branch or commit) cannot start with -"}

  defp since(_), do: :ok

  defp changed(opts) do
    cond do
      opts[:since] -> opts[:since]
      opts[:changed] -> "HEAD"
      true -> nil
    end
  end

  defp validate(%{update_baseline: true, prune_baseline: true}),
    do: {:error, "use --update-baseline or --prune-baseline, not both"}

  defp validate(%{no_baseline: true, baseline: b}) when is_binary(b),
    do: {:error, "use --baseline PATH or --no-baseline, not both"}

  defp validate(%{} = o) when o.update_baseline or o.prune_baseline do
    flag = if o.update_baseline, do: "--update-baseline", else: "--prune-baseline"

    narrowed =
      [
        o.paths != [] && "path arguments",
        o.only != [] && "--only",
        o.except != [] && "--except",
        o.exclude != [] && "--exclude",
        o.changed && "--changed",
        o.no_baseline && "--no-baseline"
      ]
      |> Enum.filter(& &1)

    if narrowed == [],
      do: {:ok, o},
      else:
        {:error,
         "#{flag} rewrites the whole baseline, so it runs on the whole app: drop #{Enum.join(narrowed, ", ")}"}
  end

  defp validate(%{changed: ref, paths: [_ | _]}) when is_binary(ref),
    do: {:error, "use --changed or path arguments, not both"}

  defp validate(o), do: {:ok, o}
end
