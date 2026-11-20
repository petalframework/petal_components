defmodule PetalComponents.Check.Pos do
  @moduledoc false
  # Maps an offset inside decoded text (a string literal's value, a sigil's
  # content) back to the {line, column} in the raw text it was read from.
  # Columns count codepoints and are 1-based, like the Elixir parser's.
  #
  # The walk consumes the decoded prefix one codepoint at a time against the
  # raw source. Escapes (`\"`, `\n`, `\x41`, `\u{...}`) consume several raw
  # codepoints for one decoded one, and heredoc indentation is skipped at the
  # start of each line. If the two ever disagree the walk returns :lost and
  # the caller falls back to the literal's own start, so a position is never
  # invented.

  @type raw :: tuple()

  @doc "Splits text into a tuple of lines (1-based access through line/2)."
  def lines(text) when is_binary(text), do: text |> String.split("\n") |> List.to_tuple()

  def line(raw, l) when l >= 1 and l <= tuple_size(raw), do: elem(raw, l - 1)
  def line(_raw, _l), do: nil

  @doc """
  Where the content of a heredoc that opens on `open_line` starts: the next
  line, after up to `indent` leading spaces or tabs.
  """
  def heredoc_start(raw, open_line, indent) do
    l = open_line + 1
    {l, 1 + skip_indent(String.codepoints(line(raw, l) || ""), indent)}
  end

  @doc """
  Walks `prefix` (decoded text) from `start` in `raw`. Options:

    * `:mode` - `:verbatim` (no escapes, the default), `:string` (Elixir
      string escapes) or `{:sigil, closing}` (only `\\` before the closing
      delimiter is an escape, as in `~H` and `~S`)
    * `:indent` - heredoc indentation to skip after each newline
  """
  def walk(raw, {l, c}, prefix, opts \\ []) do
    mode = Keyword.get(opts, :mode, :verbatim)
    indent = Keyword.get(opts, :indent, 0)

    case line(raw, l) do
      nil ->
        :lost

      text ->
        rest = text |> String.codepoints() |> Enum.drop(c - 1)
        do_walk(String.codepoints(prefix), raw, l, c, rest, mode, indent)
    end
  end

  # A string line that ends in a backslash continues on the next line, so a
  # token right after it starts there.
  defp do_walk([], raw, l, c, ["\\"], :string, _indent) do
    if line(raw, l + 1), do: {:ok, {l + 1, 1}}, else: {:ok, {l, c}}
  end

  defp do_walk([], _raw, l, c, _rest, _mode, _indent), do: {:ok, {l, c}}

  defp do_walk([ch | t] = all, raw, l, c, rest, mode, indent) do
    case rest do
      ["\\" | r2] when mode != :verbatim ->
        case escape(r2, mode) do
          {:consumed, n, r3} -> do_walk(t, raw, l, c + 1 + n, r3, mode, indent)
          :continuation -> next_line(all, raw, l, mode, 0)
          :literal -> plain(ch, t, all, raw, l, c, rest, mode, indent)
        end

      _ ->
        plain(ch, t, all, raw, l, c, rest, mode, indent)
    end
  end

  defp plain(ch, t, _all, raw, l, c, rest, mode, indent) do
    case rest do
      [^ch | r2] -> do_walk(t, raw, l, c + 1, r2, mode, indent)
      [] when ch == "\n" -> next_line(t, raw, l, mode, indent)
      _ -> :lost
    end
  end

  defp next_line(chars, raw, l, mode, indent) do
    case line(raw, l + 1) do
      nil ->
        :lost

      text ->
        cps = String.codepoints(text)
        skipped = skip_indent(cps, indent)
        do_walk(chars, raw, l + 1, 1 + skipped, Enum.drop(cps, skipped), mode, indent)
    end
  end

  defp skip_indent(cps, indent) do
    cps |> Enum.take(indent) |> Enum.take_while(&(&1 in [" ", "\t"])) |> length()
  end

  # In a string, every backslash starts an escape.
  defp escape([], :string), do: :continuation
  defp escape(["x" | r], :string), do: hex(r, 2, 1)

  defp escape(["u", "{" | r], :string) do
    {inside, after_brace} = Enum.split_while(r, &(&1 != "}"))

    case after_brace do
      ["}" | r3] -> {:consumed, 3 + length(inside), r3}
      _ -> {:consumed, 1, ["{" | r]}
    end
  end

  defp escape(["u" | r], :string), do: hex(r, 4, 1)
  defp escape([_ | r], :string), do: {:consumed, 1, r}

  # In an upper-case sigil only the closing delimiter is escaped.
  defp escape([closing | r], {:sigil, closing}), do: {:consumed, 1, r}
  defp escape(_, {:sigil, _}), do: :literal

  defp hex(r, max, used) do
    {digits, rest} = Enum.split_while(r, &(&1 =~ ~r/^[0-9a-fA-F]$/))
    {taken, back} = Enum.split(digits, max)
    {:consumed, used + length(taken), back ++ rest}
  end

  @doc "Advances {line, col} over plain text with no escapes (an attr value, CSS)."
  def advance({l, c}, text) do
    case String.split(text, "\n") do
      [one] -> {l, c + String.length(one)}
      parts -> {l + length(parts) - 1, String.length(List.last(parts)) + 1}
    end
  end
end
