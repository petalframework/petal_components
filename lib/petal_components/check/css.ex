defmodule PetalComponents.Check.Css do
  @moduledoc false
  # Reads app CSS. One string-aware pass blanks comments (keeping newlines,
  # so every position stays exact) and records them; a second pass walks the
  # blocks and emits each statement with the stack of preludes around it.
  # An unterminated string or comment, or unbalanced braces, makes the file
  # unchecked: a silent clean result would be wrong.

  alias PetalComponents.Check.Pos
  alias PetalComponents.Check.Unit
  alias PetalComponents.Check.Unit.Part

  defmodule Statement do
    @moduledoc false
    # text: the statement with comments blanked and leading space trimmed,
    #       without the closing `;`
    # stack: enclosing blocks, outermost first: [{:at | :style, prelude, line}]
    defstruct [:text, :line, :column, stack: []]
  end

  @doc """
  `{:ok, %{statements, comments, units}}` or `{:error, {line, col}, reason}`.
  """
  def parse(text) when is_binary(text) do
    with {:ok, masked, comments} <- mask(text),
         {:ok, statements} <- walk(masked) do
      {:ok, %{statements: statements, comments: comments, units: apply_units(statements)}}
    end
  end

  @doc "The style preludes (selectors) around a statement, outermost first."
  def selectors(%Statement{stack: stack}), do: for({:style, p, _} <- stack, do: p)

  @doc "The at-rule preludes around a statement, outermost first."
  def at_rules(%Statement{stack: stack}), do: for({:at, p, _} <- stack, do: p)

  # -- pass 1: blank comments, string-aware ------------------------------------

  def mask(text), do: mask(text, 1, 1, [], [])

  defp mask(<<>>, _l, _c, out, comments),
    do: {:ok, out |> Enum.reverse() |> IO.iodata_to_binary(), Enum.reverse(comments)}

  defp mask("/*" <> rest, l, c, out, comments) do
    case comment(rest, l, c + 2, ["  "], []) do
      {:ok, rest, l2, c2, blank, body} ->
        entry = %{text: body, line: l, column: c, end_line: l2, trailing?: trailing?(out)}
        mask(rest, l2, c2, [blank | out], [entry | comments])

      :eof ->
        {:error, {l, c}, "a /* comment is never closed"}
    end
  end

  defp mask(<<q, rest::binary>>, l, c, out, comments) when q in [?", ?'] do
    case string(rest, q, l, c + 1, [<<q>>]) do
      {:ok, rest, l2, c2, chunk} -> mask(rest, l2, c2, [chunk | out], comments)
      :unterminated -> {:error, {l, c}, "a string that starts here is never closed"}
    end
  end

  defp mask(<<u, r, l_, "(", rest::binary>>, l, c, out, comments)
       when u in [?u, ?U] and r in [?r, ?R] and l_ in [?l, ?L] do
    head = <<u, r, l_, "(">>

    if String.trim_leading(rest) |> String.starts_with?(["\"", "'"]) do
      mask(rest, l, c + 4, [head | out], comments)
    else
      {inside, after_} = take_until_paren(rest, [])
      {l2, c2} = Pos.advance({l, c + 4}, inside)
      mask(after_, l2, c2, [inside, head | out], comments)
    end
  end

  defp mask("\n" <> rest, l, _c, out, comments), do: mask(rest, l + 1, 1, ["\n" | out], comments)

  defp mask(<<ch::utf8, rest::binary>>, l, c, out, comments),
    do: mask(rest, l, c + 1, [<<ch::utf8>> | out], comments)

  defp mask(<<byte, rest::binary>>, l, c, out, comments),
    do: mask(rest, l, c + 1, [<<byte>> | out], comments)

  defp comment("*/" <> rest, l, c, blank, body),
    do:
      {:ok, rest, l, c + 2, Enum.reverse(["  " | blank]),
       body |> Enum.reverse() |> IO.iodata_to_binary()}

  defp comment("\n" <> rest, l, _c, blank, body),
    do: comment(rest, l + 1, 1, ["\n" | blank], ["\n" | body])

  defp comment(<<ch::utf8, rest::binary>>, l, c, blank, body),
    do: comment(rest, l, c + 1, [" " | blank], [<<ch::utf8>> | body])

  defp comment(<<_byte, rest::binary>>, l, c, blank, body),
    do: comment(rest, l, c + 1, [" " | blank], body)

  defp comment(<<>>, _l, _c, _blank, _body), do: :eof

  defp string(<<q, rest::binary>>, q, l, c, acc),
    do: {:ok, rest, l, c + 1, [<<q>> | acc] |> Enum.reverse() |> IO.iodata_to_binary()}

  defp string("\\\n" <> rest, q, l, _c, acc), do: string(rest, q, l + 1, 1, ["\\\n" | acc])

  defp string(<<"\\", ch::utf8, rest::binary>>, q, l, c, acc),
    do: string(rest, q, l, c + 2, [<<"\\", ch::utf8>> | acc])

  defp string("\n" <> _rest, _q, _l, _c, _acc), do: :unterminated
  defp string(<<>>, _q, _l, _c, _acc), do: :unterminated

  defp string(<<ch::utf8, rest::binary>>, q, l, c, acc),
    do: string(rest, q, l, c + 1, [<<ch::utf8>> | acc])

  defp string(<<byte, rest::binary>>, q, l, c, acc),
    do: string(rest, q, l, c + 1, [<<byte>> | acc])

  defp take_until_paren(")" <> _ = rest, acc),
    do: {acc |> Enum.reverse() |> IO.iodata_to_binary(), rest}

  defp take_until_paren(<<>>, acc), do: {acc |> Enum.reverse() |> IO.iodata_to_binary(), <<>>}

  defp take_until_paren(<<ch::utf8, rest::binary>>, acc),
    do: take_until_paren(rest, [<<ch::utf8>> | acc])

  defp take_until_paren(<<b, rest::binary>>, acc), do: take_until_paren(rest, [<<b>> | acc])

  # Code before a comment on the same line (`color: red; /* note */`).
  defp trailing?(out) do
    out
    |> Enum.reduce_while([], fn chunk, acc ->
      chunk = IO.iodata_to_binary(chunk)

      case :binary.split(chunk, "\n", [:global]) do
        [_one] -> {:cont, [chunk | acc]}
        parts -> {:halt, [List.last(parts) | acc]}
      end
    end)
    |> IO.iodata_to_binary()
    |> String.trim()
    |> Kernel.!=("")
  end

  # -- pass 2: blocks and statements ------------------------------------------

  defp walk(masked) do
    state = %{stack: [], buf: [], start: nil, out: [], paren: 0}

    case step(masked, 1, 1, state) do
      {:ok, %{stack: []} = st} ->
        {:ok, Enum.reverse(st.out)}

      {:ok, %{stack: [{_, _, line} | _]}} ->
        {:error, {line, 1}, "unbalanced braces: the block opened on line #{line} is never closed"}

      {:error, _, _} = err ->
        err
    end
  end

  defp step(<<>>, _l, _c, st), do: {:ok, flush(st)}

  defp step(<<q, rest::binary>>, l, c, st) when q in [?", ?'] do
    case string(rest, q, l, c + 1, [<<q>>]) do
      {:ok, rest2, l2, c2, chunk} -> step(rest2, l2, c2, push(st, chunk, {l, c}))
      :unterminated -> {:error, {l, c}, "a string that starts here is never closed"}
    end
  end

  defp step("(" <> rest, l, c, st),
    do: step(rest, l, c + 1, %{push(st, "(", {l, c}) | paren: st.paren + 1})

  defp step(")" <> rest, l, c, st),
    do: step(rest, l, c + 1, %{push(st, ")", {l, c}) | paren: max(st.paren - 1, 0)})

  defp step("{" <> rest, l, c, %{paren: 0} = st) do
    prelude = st.buf |> Enum.reverse() |> IO.iodata_to_binary() |> String.trim()
    kind = if String.starts_with?(prelude, "@"), do: :at, else: :style
    line = if st.start, do: elem(st.start, 0), else: l
    step(rest, l, c + 1, %{st | stack: [{kind, prelude, line} | st.stack], buf: [], start: nil})
  end

  defp step(";" <> rest, l, c, %{paren: 0} = st), do: step(rest, l, c + 1, flush(st))

  defp step("}" <> rest, l, c, %{paren: 0} = st) do
    st = flush(st)

    case st.stack do
      [] -> {:error, {l, c}, "unbalanced braces: a } on line #{l} closes no block"}
      [_ | outer] -> step(rest, l, c + 1, %{st | stack: outer})
    end
  end

  defp step("\n" <> rest, l, _c, st), do: step(rest, l + 1, 1, push(st, "\n", nil))

  defp step(<<ch::utf8, rest::binary>>, l, c, st) do
    s = <<ch::utf8>>
    pos = if String.trim(s) == "", do: nil, else: {l, c}
    step(rest, l, c + 1, push(st, s, pos))
  end

  defp step(<<b, rest::binary>>, l, c, st), do: step(rest, l, c + 1, push(st, <<b>>, {l, c}))

  # The statement starts at its first non-blank character.
  defp push(%{start: nil, buf: []} = st, _chunk, nil), do: st
  defp push(%{start: nil} = st, chunk, pos), do: %{st | buf: [chunk | st.buf], start: pos}
  defp push(st, chunk, _pos), do: %{st | buf: [chunk | st.buf]}

  defp flush(%{start: nil} = st), do: %{st | buf: [], paren: 0}

  defp flush(%{start: {l, c}} = st) do
    text = st.buf |> Enum.reverse() |> IO.iodata_to_binary() |> String.trim()

    stmt = %Statement{text: text, line: l, column: c, stack: Enum.reverse(st.stack)}
    %{st | out: [stmt | st.out], buf: [], start: nil, paren: 0}
  end

  # -- @apply units ---------------------------------------------------------------

  defp apply_units(statements) do
    for %Statement{text: "@apply" <> _ = text, line: l, column: c} <- statements,
        [lead] <- [Regex.run(~r/^@apply\s+/, text)] do
      args = binary_part(text, byte_size(lead), byte_size(text) - byte_size(lead))
      start = Pos.advance({l, c}, lead)

      Unit.new(:css_apply, [
        %Part{text: args, locate: &Pos.advance(start, binary_part(args, 0, &1))}
      ])
    end
  end
end
