defmodule PetalComponents.Check.Rules.RampComplete do
  @moduledoc false
  # Guide section 9. An app @theme block that remaps some stops of one of the
  # seven ramps, but not all eleven, leaves the rest on the library default,
  # so hover and active ladders mix two colours. The stops are unioned across
  # every CSS file under the default roots, so a ramp split over two @theme
  # blocks or two files never false-alarms.
  #
  # Only @theme blocks count: a `:root { --color-primary-500: ... }` runtime
  # variable (a scoped retheme) is not a ramp remap.

  @behaviour PetalComponents.Check.Rule

  alias PetalComponents.Check.Css
  alias PetalComponents.Check.Css.Statement
  alias PetalComponents.Check.Rule

  @ramps ~w(primary secondary info success warning danger gray)
  @stops ~w(50 100 200 300 400 500 600 700 800 900 950)

  @doc false
  def ramps, do: @ramps
  @doc false
  def stops, do: @stops

  @impl true
  def rule do
    %Rule{
      id: "ramp-complete",
      severity: :error,
      section: "9",
      row_keyword: "theming",
      scope: :project,
      why:
        "a partial ramp remap leaves the unmapped stops on the library default, so hover and active ladders mix two colours",
      examples: [
        {:bad, "@theme { --color-primary-500: #7c3aed; }"},
        {:good,
         "@theme inline { --color-primary-50: var(--color-violet-50); /* ...every stop to 950 */ }"}
      ],
      exemptions: [
        "all eleven stops, even split across @theme blocks or files",
        ":root or other runtime variables outside @theme",
        "ramps other than the seven semantic ones, and non-standard stops such as 25"
      ]
    }
  end

  @impl true
  def collect(source, _ctx) do
    for %Statement{} = st <- source.statements,
        in_theme?(st),
        [_, ramp, stop, value] <-
          [Regex.run(~r/^--color-([a-z]+)-(\d+|\*)\s*:\s*(.*)$/s, st.text)],
        ramp in @ramps,
        stop in @stops or stop == "*" do
      %{
        path: source.path,
        ramp: ramp,
        stop: stop,
        value: String.trim(value),
        line: st.line,
        column: st.column,
        subject: st.text |> String.split(":", parts: 2) |> hd() |> String.trim()
      }
    end
  end

  defp in_theme?(st), do: Enum.any?(Css.at_rules(st), &(&1 =~ ~r/^@theme\b/))

  @impl true
  def finish(collected, _ctx) do
    defs = List.flatten(collected)

    for ramp <- @ramps,
        mine = defs |> Enum.filter(&(&1.ramp == ramp)) |> Enum.sort_by(&{&1.path, &1.line}),
        have = mine |> Enum.map(& &1.stop) |> Enum.filter(&(&1 in @stops)) |> Enum.uniq(),
        n = length(have),
        n >= 1 and n < 11 do
      first = mine |> Enum.reject(&(&1.stop == "*")) |> hd()
      missing = Enum.reject(@stops, &(&1 in have))
      wiped? = Enum.any?(mine, &(&1.stop == "*"))
      finding(ramp, n, missing, first, wiped?, mine)
    end
  end

  defp finding(ramp, n, missing, first, wiped?, mine) do
    list = Enum.join(missing, ", ")

    message =
      if wiped?,
        do:
          "@theme remaps #{n} of 11 #{ramp} stops after clearing the ramp; the missing stops (#{list}) do not exist",
        else:
          "@theme remaps #{n} of 11 #{ramp} stops; the missing stops (#{list}) stay on the library default"

    Rule.finding(rule(),
      path: first.path,
      line: first.line,
      column: first.column,
      subject: ramp,
      message: message,
      replacement: nil,
      fix: fix(ramp, missing, mine)
    )
  end

  # When every stop points at the same stop of one palette, the missing
  # lines are known exactly.
  defp fix(ramp, missing, mine) do
    palettes =
      mine
      |> Enum.reject(&(&1.stop == "*"))
      |> Enum.map(fn d ->
        case Regex.run(~r/^var\(\s*--color-([a-z]+)-(\d+)\s*\)$/, d.value) do
          [_, p, s] when s == d.stop -> p
          _ -> nil
        end
      end)
      |> Enum.uniq()

    case palettes do
      [p] when is_binary(p) ->
        lines = Enum.map_join(missing, " ", &"--color-#{ramp}-#{&1}: var(--color-#{p}-#{&1});")
        "add these lines in the same @theme block: #{lines}"

      _ ->
        "add --color-#{ramp}-#{hd(missing)} (and every other missing stop) in the same @theme block"
    end
  end
end
