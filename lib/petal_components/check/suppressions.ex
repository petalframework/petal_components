defmodule PetalComponents.Check.Suppressions do
  @moduledoc false
  # petal-check:ignore / disable / enable comments.
  #
  # Directives are read only from real comments: `#` comments in Elixir
  # (from the parser, so a string that quotes a directive is not one),
  # `<%!-- --%>` in HEEx and `/* */` in CSS. A directive in an HTML
  # `<!-- -->` comment is reported as misplaced.
  #
  #   ignore   covers the next line, and every finding from a tag whose `<`
  #            is on the next line (so a comment above a multi-line tag
  #            covers its attrs). With code before it on the same line, it
  #            covers its own line instead.
  #   disable  covers every later line until a matching enable, or the end
  #            of the file (which is itself reported as unclosed-disable).
  #
  # Every directive must name rule ids; there is no ignore-everything form.
  # Suppressed findings stay in the report with status :suppressed.

  alias PetalComponents.Check.Finding

  @meta_rules ~w(unused-suppression unknown-rule unclosed-disable suppression-without-reason misplaced-suppression invalid-suppression)

  def meta_rules, do: @meta_rules

  @doc """
  Parses one comment's text. Returns nil (not a directive), `{:invalid, why}`
  or `%{kind, rules, reason}`.
  """
  def directive(text) do
    case Regex.run(~r/petal-check:([a-z-]*)(.*)$/s, text) do
      nil ->
        nil

      [_, kind, rest] when kind in ["ignore", "disable", "enable"] ->
        rest = rest |> String.replace(~r/\s*(--%>|\*\/|-->)\s*$/, "") |> String.trim_trailing()

        case Regex.run(~r/^\s+([a-z0-9-]+(?:\s*,\s*[a-z0-9-]+)*)\s*(?::(.*))?$/s, rest) do
          [_, ids | reason] ->
            reason = reason |> List.first() |> Kernel.||("") |> String.trim()
            rules = ids |> String.split(",") |> Enum.map(&String.trim/1)

            %{
              kind: String.to_atom(kind),
              rules: rules,
              reason: if(reason == "", do: nil, else: reason)
            }

          _ ->
            {:invalid,
             "petal-check:#{kind} needs one or more rule ids, for example petal-check:#{kind} literal-neutral: why"}
        end

      [_, kind, _] ->
        {:invalid, "petal-check:#{kind} is not a directive; use ignore, disable or enable"}
    end
  end

  @doc """
  Applies a source's directives to its findings. `known` is every rule id,
  `ran` the ids that ran this time. Returns `{findings, meta_findings}`.
  """
  def apply(source, findings, known, ran) do
    parsed =
      for c <- source.comments, d = directive(c.text), d != nil do
        {c, d}
      end

    {invalid, dirs} = Enum.split_with(parsed, fn {_c, d} -> match?({:invalid, _}, d) end)

    meta =
      Enum.map(invalid, fn {c, {:invalid, why}} ->
        meta(source, c, "invalid-suppression", why, "write petal-check:ignore RULE: reason")
      end) ++
        Enum.map(source.misplaced, fn {l, col} ->
          meta(
            source,
            %{line: l, column: col},
            "misplaced-suppression",
            "a petal-check directive in an HTML comment is not read",
            "use a HEEx comment: <%!-- petal-check:ignore RULE: reason --%>"
          )
        end)

    {dirs, unknown_meta} = known_only(source, dirs, known)

    reason_meta =
      for {c, %{kind: k, reason: nil, rules: rules}} <- dirs, k in [:ignore, :disable] do
        meta(
          source,
          c,
          "suppression-without-reason",
          "petal-check:#{k} #{Enum.join(rules, ",")} gives no reason",
          "add one after a colon: petal-check:#{k} #{Enum.join(rules, ",")}: why this is fine"
        )
      end

    {ranges, range_meta} = ranges(source, dirs)
    ignores = for {c, %{kind: :ignore} = d} <- dirs, do: {c, d, target_line(c)}

    {findings, used} =
      Enum.map_reduce(findings, MapSet.new(), fn f, used ->
        cond do
          f.meta ->
            {f, used}

          hit =
              Enum.find(ignores, fn {_c, d, t} ->
                f.rule in d.rules and t in [f.line, f.tag_line]
              end) ->
            {c, _, _} = hit
            {%{f | status: :suppressed}, MapSet.put(used, {c.line, c.column})}

          hit =
              Enum.find(ranges, fn {_c, rule, from, to} ->
                f.rule == rule and f.line >= from and f.line <= to
              end) ->
            {c, _, _, _} = hit
            {%{f | status: :suppressed}, MapSet.put(used, {c.line, c.column})}

          true ->
            {f, used}
        end
      end)

    unused_meta =
      if source.unchecked == [] do
        for {c, %{kind: k, rules: rules}} <- dirs,
            k in [:ignore, :disable],
            rules != [],
            Enum.all?(rules, &(&1 in ran)),
            not MapSet.member?(used, {c.line, c.column}) do
          meta(
            source,
            c,
            "unused-suppression",
            "petal-check:#{k} #{Enum.join(rules, ",")} on line #{c.line} matched nothing",
            "delete the comment"
          )
        end
      else
        []
      end

    {findings, meta ++ unknown_meta ++ reason_meta ++ range_meta ++ unused_meta}
  end

  defp target_line(%{trailing?: true, line: l}), do: l
  defp target_line(%{end_line: e}), do: e + 1

  defp known_only(source, dirs, known) do
    Enum.map_reduce(dirs, [], fn {c, d}, acc ->
      {ok, bad} = Enum.split_with(d.rules, &(&1 in known))

      acc =
        if bad == [],
          do: acc,
          else:
            acc ++
              [
                meta(
                  source,
                  c,
                  "unknown-rule",
                  "petal-check:#{d.kind} names #{Enum.join(bad, ", ")}, which is not a rule",
                  "use one of: " <> Enum.join(known, ", ")
                )
              ]

      {{c, %{d | rules: ok}}, acc}
    end)
  end

  # disable/enable pairs per rule -> [{comment, rule, from_line, to_line}]
  defp ranges(source, dirs) do
    sorted = Enum.sort_by(dirs, fn {c, _} -> {c.line, c.column} end)

    {open, closed, meta} =
      Enum.reduce(sorted, {%{}, [], []}, fn
        {c, %{kind: :disable, rules: rules}}, {open, closed, meta} ->
          from = if c.trailing?, do: c.line, else: c.end_line + 1
          {Enum.reduce(rules, open, &Map.put_new(&2, &1, {c, from})), closed, meta}

        {c, %{kind: :enable, rules: rules}}, {open, closed, meta} ->
          Enum.reduce(rules, {open, closed, meta}, fn rule, {open, closed, meta} ->
            case Map.pop(open, rule) do
              {nil, open} ->
                m =
                  meta(
                    source,
                    c,
                    "invalid-suppression",
                    "petal-check:enable #{rule} has no petal-check:disable before it",
                    "delete the comment"
                  )

                {open, closed, [m | meta]}

              {{dc, from}, open} ->
                {open, [{dc, rule, from, c.line} | closed], meta}
            end
          end)

        _, acc ->
          acc
      end)

    unclosed =
      for {rule, {dc, from}} <- open do
        {{dc, rule, from, :infinity},
         meta(
           source,
           dc,
           "unclosed-disable",
           "petal-check:disable #{rule} on line #{dc.line} has no petal-check:enable #{rule}, so it lasts to the end of the file",
           "add petal-check:enable #{rule} where the exception ends"
         )}
      end

    {closed ++ Enum.map(unclosed, &elem(&1, 0)),
     Enum.reverse(meta) ++ Enum.map(unclosed, &elem(&1, 1))}
  end

  defp meta(source, c, rule, message, fix) do
    %Finding{
      rule: rule,
      severity: :warning,
      section: nil,
      path: source.path,
      line: c.line,
      column: c.column,
      subject: "#{rule}@#{c.line}",
      message: message,
      fix: fix,
      meta: true
    }
  end
end
