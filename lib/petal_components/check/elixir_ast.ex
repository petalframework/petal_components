defmodule PetalComponents.Check.ElixirAst do
  @moduledoc false
  # Reads Elixir source with the real parser. Collects ~H fragments, string
  # units, function names the file defines, its aliases and any
  # `import PetalComponents.X, except: [...]`.

  alias PetalComponents.Check.Pos
  alias PetalComponents.Check.Unit
  alias PetalComponents.Check.Unit.Part

  @doc_attrs [:moduledoc, :doc, :typedoc, :shortdoc]
  @escaping_sigils [:sigil_s, :sigil_w]
  @verbatim_sigils [:sigil_S, :sigil_W]
  @defs [:def, :defp, :defmacro, :defmacrop]

  def quoted_opts(file) do
    [
      columns: true,
      token_metadata: true,
      emit_warnings: false,
      file: file,
      literal_encoder: &{:ok, {:__lit__, &2, [&1]}}
    ]
  end

  @doc """
  Parses a whole file. Returns `{:ok, ast, comments}` or
  `{:error, {line, column}, message}`.
  """
  def parse(src, file) do
    # Comments are only needed for directives, and collecting them costs a
    # third more parse time, so skip them when no directive can be present.
    result =
      if String.contains?(src, "petal-check:") do
        Code.string_to_quoted_with_comments(src, quoted_opts(file))
      else
        with {:ok, ast} <- Code.string_to_quoted(src, quoted_opts(file)), do: {:ok, ast, []}
      end

    case result do
      {:ok, ast, comments} -> {:ok, ast, comments}
      {:error, {meta, msg, token}} -> {:error, error_pos(meta), error_message(msg, token)}
    end
  end

  defp error_pos(meta) when is_list(meta), do: {meta[:line] || 1, meta[:column] || 1}
  defp error_pos(line) when is_integer(line), do: {line, 1}
  defp error_pos(_), do: {1, 1}

  defp error_message({prefix, suffix}, token) when is_binary(prefix) and is_binary(suffix),
    do: first_line(prefix <> to_string(token) <> suffix)

  defp error_message(msg, token) when is_binary(msg), do: first_line(msg <> to_string(token))
  defp error_message(msg, token), do: first_line(inspect(msg) <> to_string(token))

  defp first_line(s), do: s |> String.split("\n") |> hd() |> String.trim()

  @doc """
  Walks a parsed file. `raw` is `Pos.lines(src)`. Returns a map:

    * `:units` - one `%Unit{}` per string literal (docs and ~H excluded)
    * `:heex` - `[%{content, start, mode, indent, open}]`, one per ~H sigil
    * `:defs` - names of functions and macros the file defines
    * `:aliases` - `%{"Chat" => "PetalComponents.Chat"}`
    * `:excepts` - names excluded from a `PetalComponents.*` import
  """
  def collect(ast, raw) do
    init = %{units: [], heex: [], defs: MapSet.new(), aliases: %{}, excepts: MapSet.new()}

    {_, acc} =
      Macro.prewalk(ast, init, fn node, acc -> visit(node, acc, raw, &Function.identity/1) end)

    %{acc | units: Enum.reverse(acc.units), heex: Enum.reverse(acc.heex)}
  end

  @doc """
  The literals of one expression (a HEEx attr value or `{...}`), as a single
  unit. `outer` maps a {line, column} inside `code` to the file. An expression
  that does not parse gives nil: it cannot compile anyway.
  """
  def expr_unit(code, outer, origin, opts \\ []) do
    case Code.string_to_quoted(code, Keyword.delete(quoted_opts("nofile"), :file)) do
      {:ok, ast} ->
        raw = Pos.lines(code)
        init = %{units: [], heex: [], defs: MapSet.new(), aliases: %{}, excepts: MapSet.new()}
        {_, acc} = Macro.prewalk(ast, init, fn node, acc -> visit(node, acc, raw, outer) end)

        case acc.units |> Enum.reverse() |> Enum.flat_map(& &1.parts) do
          [] -> nil
          parts -> Unit.new(origin, parts, opts)
        end

      _ ->
        nil
    end
  end

  # -- the walk ---------------------------------------------------------------

  defp visit({:@, _, [{name, _, _}]}, acc, _raw, _outer) when name in @doc_attrs,
    do: {:__skip__, acc}

  defp visit({{:__lit__, _, [:doc]}, _value}, acc, _raw, _outer), do: {:__skip__, acc}

  defp visit({:sigil_H, meta, [{:<<>>, m2, [content]}, _mods]}, acc, raw, _outer)
       when is_binary(content) do
    {start, indent} = sigil_start(raw, :sigil_H, meta, m2)
    open = {meta[:line], meta[:column]}

    frag = %{
      content: content,
      start: start,
      indent: indent,
      heredoc?: heredoc?(meta[:delimiter]),
      mode: {:sigil, closing(meta[:delimiter])},
      open: open
    }

    {:__skip__, %{acc | heex: [frag | acc.heex]}}
  end

  defp visit({sigil, meta, [{:<<>>, m2, parts}, _mods]} = node, acc, raw, outer)
       when sigil in @escaping_sigils or sigil in @verbatim_sigils do
    {start, indent} = sigil_start(raw, sigil, meta, m2)
    mode = if sigil in @escaping_sigils, do: :string, else: {:sigil, closing(meta[:delimiter])}
    fallback = outer.({meta[:line], meta[:column]})
    unit = Unit.new(:elixir, string_parts(parts, start, mode, indent, raw, outer, fallback))
    {node, %{acc | units: [unit | acc.units]}}
  end

  # Any other sigil (~r, ~D, ~E, a custom one) is not class text.
  defp visit({sigil, _meta, [{:<<>>, _, _}, mods]} = node, acc, _raw, _outer)
       when is_atom(sigil) and is_list(mods) do
    if String.starts_with?(Atom.to_string(sigil), "sigil_"),
      do: {:__skip__, acc},
      else: {node, acc}
  end

  defp visit({:__lit__, meta, [bin]}, acc, raw, outer) when is_binary(bin) do
    {start, indent} = string_start(raw, meta)
    fallback = outer.({meta[:line], meta[:column]})
    unit = Unit.new(:elixir, string_parts([bin], start, :string, indent, raw, outer, fallback))
    {:__skip__, %{acc | units: [unit | acc.units]}}
  end

  defp visit({:<<>>, meta, parts} = node, acc, raw, outer) when is_list(parts) do
    if Keyword.has_key?(meta, :delimiter) do
      {start, indent} = string_start(raw, meta)
      fallback = outer.({meta[:line], meta[:column]})
      unit = Unit.new(:elixir, string_parts(parts, start, :string, indent, raw, outer, fallback))
      {node, %{acc | units: [unit | acc.units]}}
    else
      {node, acc}
    end
  end

  defp visit({d, _, [head | _]} = node, acc, _raw, _outer) when d in @defs do
    case def_name(head) do
      nil -> {node, acc}
      name -> {node, %{acc | defs: MapSet.put(acc.defs, name)}}
    end
  end

  defp visit({:alias, _, [target | rest]} = node, acc, _raw, _outer) do
    {node, %{acc | aliases: Map.merge(acc.aliases, aliases(target, rest))}}
  end

  defp visit({:import, _, [{:__aliases__, _, [:PetalComponents | _]}, opts]} = node, acc, _, _) do
    names =
      case unlit(opts) do
        kw when is_list(kw) ->
          case Keyword.get(kw, :except) do
            list when is_list(list) -> for {n, _} <- list, is_atom(n), do: Atom.to_string(n)
            _ -> []
          end

        _ ->
          []
      end

    {node, %{acc | excepts: Enum.into(names, acc.excepts)}}
  end

  defp visit(node, acc, _raw, _outer), do: {node, acc}

  # -- helpers ----------------------------------------------------------------

  defp def_name({:when, _, [head | _]}), do: def_name(head)
  defp def_name({name, _, args}) when is_atom(name) and (is_list(args) or is_nil(args)),
    do: Atom.to_string(name)

  defp def_name(_), do: nil

  defp aliases({:__aliases__, _, segs}, rest) when is_list(segs) do
    if Enum.all?(segs, &is_atom/1) do
      as =
        case unlit(rest) do
          [kw] when is_list(kw) ->
            case Keyword.get(kw, :as) do
              {:__aliases__, _, [a]} -> Atom.to_string(a)
              _ -> nil
            end

          _ ->
            nil
        end

      full = Enum.map_join(segs, ".", &Atom.to_string/1)
      %{(as || Atom.to_string(List.last(segs))) => full}
    else
      %{}
    end
  end

  defp aliases({{:., _, [{:__aliases__, _, base}, :{}]}, _, children}, _rest) do
    for {:__aliases__, _, segs} <- children, Enum.all?(base ++ segs, &is_atom/1), into: %{} do
      {Atom.to_string(List.last(segs)), Enum.map_join(base ++ segs, ".", &Atom.to_string/1)}
    end
  end

  defp aliases(_, _), do: %{}

  @doc false
  def unlit({:__lit__, _, [v]}), do: unlit(v)
  def unlit(list) when is_list(list), do: Enum.map(list, &unlit/1)
  def unlit({a, b}), do: {unlit(a), unlit(b)}
  def unlit(other), do: other

  defp heredoc?(d), do: d in [~s("""), ~s(''')]

  defp closing("("), do: ")"
  defp closing("["), do: "]"
  defp closing("{"), do: "}"
  defp closing("<"), do: ">"
  defp closing(~s(""")), do: ~s(")
  defp closing(~s(''')), do: "'"
  defp closing(d) when is_binary(d), do: d
  defp closing(_), do: ~s(")

  defp string_start(raw, meta) do
    d = meta[:delimiter] || ~s(")
    indent = meta[:indentation] || 0

    if heredoc?(d),
      do: {Pos.heredoc_start(raw, meta[:line], indent), indent},
      else: {{meta[:line], meta[:column] + String.length(d)}, 0}
  end

  defp sigil_start(raw, sigil, meta, m2) do
    d = meta[:delimiter] || ~s(")
    indent = m2[:indentation] || meta[:indentation] || 0
    letters = sigil |> Atom.to_string() |> String.replace_prefix("sigil_", "")

    if heredoc?(d),
      do: {Pos.heredoc_start(raw, meta[:line], indent), indent},
      else: {{meta[:line], meta[:column] + 1 + String.length(letters) + String.length(d)}, 0}
  end

  # Builds the parts of a (possibly interpolated) string. Each binary piece is
  # a part; the piece after an interpolation starts after its closing brace.
  defp string_parts(pieces, start, mode, indent, raw, outer, fallback) do
    n = length(pieces)

    {parts, _} =
      pieces
      |> Enum.with_index()
      |> Enum.reduce({[], start}, fn
        {bin, i}, {acc, cur} when is_binary(bin) ->
          part = %Part{
            text: bin,
            locate: locator(raw, cur, bin, mode, indent, outer, fallback),
            open_left: i > 0 and not is_binary(Enum.at(pieces, i - 1)),
            open_right: i < n - 1 and not is_binary(Enum.at(pieces, i + 1))
          }

          {[part | acc], :lost}

        {interp, _i}, {acc, _cur} ->
          {acc, after_interpolation(interp)}
      end)

    Enum.reverse(parts)
  end

  defp after_interpolation({:"::", _, [{{:., _, [Kernel, :to_string]}, im, _}, _]}) do
    case im[:closing] do
      [line: l, column: c] -> {l, c + 1}
      kw when is_list(kw) -> if kw[:line], do: {kw[:line], kw[:column] + 1}, else: :lost
      _ -> :lost
    end
  end

  defp after_interpolation(_), do: :lost

  defp locator(_raw, :lost, _bin, _mode, _indent, _outer, fallback), do: fn _ -> fallback end

  defp locator(raw, start, bin, mode, indent, outer, fallback) do
    fn off ->
      case Pos.walk(raw, start, binary_part(bin, 0, off), mode: mode, indent: indent) do
        {:ok, pos} -> outer.(pos)
        :lost -> fallback
      end
    end
  end
end
