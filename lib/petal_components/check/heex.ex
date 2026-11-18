defmodule PetalComponents.Check.Heex do
  @moduledoc false
  # HEEx fragments: picks LiveView's tokenizer for the installed version,
  # proves it still returns the token shapes this code reads, and turns one
  # fragment into tags, string units and comments, all in file positions.

  alias PetalComponents.Check.ElixirAst
  alias PetalComponents.Check.Pos
  alias PetalComponents.Check.Unit
  alias PetalComponents.Check.Unit.Part

  defmodule Tag do
    @moduledoc false
    # kind: :tag | :local_component | :remote_component | :slot
    defstruct [:kind, :name, :line, :column, attrs: []]
  end

  defmodule Attr do
    @moduledoc false
    # value: {:string, text} | {:expr, code} | nil (a boolean attr)
    # source: the attr as written, for a subject and a replacement span
    defstruct [:name, :value, :line, :column, :source]
  end

  @tag_kinds [:tag, :local_component, :remote_component, :slot]

  # -- tokenizer pick and guard ------------------------------------------------

  @canary ~s(<.dropdown placement="left" class={["a"]}><:item class="x"/></.dropdown>)

  @doc """
  `{:ok, module}` or `{:error, reason}`. The module is called through a
  variable, never by name, so this file compiles without warnings on
  LiveView 1.1 (Phoenix.LiveView.Tokenizer) and 1.2 (TagEngine.Tokenizer).
  """
  def tokenizer do
    mod =
      Enum.find(
        [Phoenix.LiveView.TagEngine.Tokenizer, Phoenix.LiveView.Tokenizer],
        &Code.ensure_loaded?/1
      )

    cond do
      is_nil(mod) ->
        {:error, "no HEEx tokenizer module found"}

      not (function_exported?(mod, :init, 4) and function_exported?(mod, :tokenize, 5) and
               function_exported?(mod, :finalize, 4) and Code.ensure_loaded?(engine())) ->
        {:error, "#{inspect(mod)} no longer has the functions this check calls"}

      true ->
        case canary(mod) do
          :ok -> {:ok, mod}
          {:error, why} -> {:error, "#{inspect(mod)} returned unexpected tokens (#{why})"}
        end
    end
  end

  @doc "The installed phoenix_live_view version, or nil."
  def live_view_version do
    _ = Application.load(:phoenix_live_view)

    case Application.spec(:phoenix_live_view, :vsn) do
      nil -> nil
      vsn -> to_string(vsn)
    end
  end

  defp engine, do: Phoenix.LiveView.HTMLEngine

  defp canary(mod) do
    case raw_tokens(@canary, mod) do
      {:ok, tokens, _extras} ->
        ok? =
          match?(
            [
              {:local_component, "dropdown",
               [
                 {"placement", {:string, "left", %{delimiter: ?"}}, %{line: 1, column: 12}},
                 {"class", {:expr, ~s(["a"]), %{line: 1, column: 36}}, %{line: 1, column: 29}}
               ], %{line: 1, column: 1}},
              {:slot, "item", [{"class", {:string, "x", %{delimiter: ?"}}, %{line: 1, column: 50}}],
               %{line: 1, column: 43}},
              {:close, :local_component, "dropdown", %{line: 1}}
            ],
            tokens
          )

        if ok?, do: :ok, else: {:error, "the canary fragment did not match"}

      {:error, _pos, msg} ->
        {:error, msg}
    end
  rescue
    e -> {:error, Exception.message(e) |> first_line()}
  end

  # -- one fragment -------------------------------------------------------------

  @doc """
  Reads one fragment. `map` turns a fragment {line, column} into a file one.
  Returns `{:ok, %{tags, units, comments, misplaced}}` or
  `{:unchecked, {line, column}, reason}`.
  """
  def fragment(content, map, tok) do
    lines = Pos.lines(content)

    case raw_tokens(content, tok) do
      {:ok, tokens, extras} ->
        try do
          {:ok, build(tokens, extras, content, lines, map)}
        catch
          {:shape, token} ->
            {:unchecked, map.({1, 1}),
             "the HEEx tokenizer returned a token shape this check does not know: " <>
               (inspect(token, limit: 5) |> String.slice(0, 80))}
        end

      {:error, pos, msg} ->
        {:unchecked, map.(pos), "this HEEx could not be read: " <> msg}
    end
  end

  # EEx first (it owns <% %> and <%!-- --%>), then LiveView's tokenizer on
  # each text piece, exactly as the HEEx engine does.
  defp raw_tokens(content, tok) do
    case EEx.tokenize(content) do
      {:ok, eex} ->
        try do
          {toks, cont, extras} =
            Enum.reduce(eex, {[], {:text, :enabled}, []}, fn
              {:text, chars, meta}, {t, c, x} ->
                state = tok.init(0, "nofile", content, engine())
                text = List.to_string(chars)
                {t, c} = tok.tokenize(text, [line: meta.line, column: meta.column], t, c, state)
                {t, c, x}

              {:expr, marker, code, meta}, {t, c, x} ->
                {t, c, [{:eex_expr, List.to_string(marker), List.to_string(code), meta} | x]}

              {:comment, chars, meta}, {t, c, x} ->
                {t, c, [{:comment, List.to_string(chars), meta} | x]}

              # start/middle/end exprs (`<%= if @a do %>`) never parse on
              # their own; skipped by design.
              _, acc ->
                acc
            end)

          {:ok, tok.finalize(toks, "nofile", cont, content), Enum.reverse(extras)}
        rescue
          e -> {:error, error_pos(e), error_text(e)}
        end

      {:error, msg, meta} ->
        {:error, {meta[:line] || 1, meta[:column] || 1}, first_line(to_string(msg))}
    end
  end

  defp error_pos(e) do
    case e do
      %{line: l, column: c} when is_integer(l) and is_integer(c) ->
        {l, c}

      _ ->
        case Regex.run(~r/:(\d+):(\d+):/, Exception.message(e)) do
          [_, l, c] -> {String.to_integer(l), String.to_integer(c)}
          _ -> {1, 1}
        end
    end
  end

  defp error_text(e) do
    case e do
      %{description: d} when is_binary(d) -> first_line(d)
      _ -> e |> Exception.message() |> first_line() |> String.replace(~r/^nofile:\d+:\d+:\s*/, "")
    end
  end

  defp first_line(s), do: s |> String.split("\n") |> hd() |> String.trim()

  defp build(tokens, extras, content, lines, map) do
    {tags, units} =
      Enum.reduce(tokens, {[], []}, fn token, {tags, units} ->
        case token do
          {kind, name, attrs, meta} when kind in @tag_kinds and is_binary(name) and is_list(attrs) ->
            {tag, attr_units} = tag(kind, name, attrs, meta, lines, map)
            {[tag | tags], Enum.reverse(attr_units, units)}

          {:close, _kind, _name, _meta} ->
            {tags, units}

          {:text, text, _meta} when is_binary(text) ->
            {tags, units}

          {:body_expr, code, %{line: l, column: c}} when is_binary(code) ->
            {tags, add(units, expr_unit(code, {l, c + 1}, map, :heex_expr, []))}

          other ->
            throw({:shape, other})
        end
      end)

    eex_units =
      for {:eex_expr, marker, code, meta} <- extras,
          unit = expr_unit(code, {meta.line, meta.column + 2 + String.length(marker)}, map, :heex_expr, []),
          do: unit

    comments =
      for {:comment, text, meta} <- extras do
        {l, c} = map.({meta.line, meta.column})
        before = lines |> Pos.line(meta.line) |> Kernel.||("") |> String.slice(0, meta.column - 1)

        %{
          text: text,
          line: l,
          column: c,
          end_line: l + length(String.split(text, "\n")) - 1,
          trailing?: String.trim(before) != ""
        }
      end

    %{
      tags: Enum.reverse(tags),
      units: Enum.reverse(units) ++ eex_units,
      comments: comments,
      misplaced: misplaced(content, map)
    }
  end

  defp add(units, nil), do: units
  defp add(units, unit), do: [unit | units]

  defp tag(kind, name, attrs, meta, lines, map) do
    {line, column} = map.({meta.line, meta.column})

    parsed =
      Enum.map(attrs, fn
        {n, value, %{line: l, column: c}} when is_binary(n) or n == :root ->
          {n, value, {l, c}, check_value(value)}

        other ->
          throw({:shape, other})
      end)

    attr_structs =
      for {n, value, {l, c}, _} <- parsed, is_binary(n) do
        {fl, fc} = map.({l, c})
        %Attr{name: n, value: plain_value(value), line: fl, column: fc, source: source(n, value)}
      end

    tag = %Tag{kind: kind, name: name, line: line, column: column, attrs: attr_structs}

    units =
      for {n, value, {l, c}, _} <- parsed, is_binary(n), unit = attr_unit(n, value, {l, c}, lines, map, tag),
          do: unit

    {tag, units}
  end

  defp check_value({:string, s, m} = v) when is_binary(s) and is_map(m), do: v
  defp check_value({:expr, code, %{line: _, column: _}} = v) when is_binary(code), do: v
  defp check_value(nil), do: nil
  defp check_value(other), do: throw({:shape, other})

  defp plain_value({:string, s, _}), do: {:string, s}
  defp plain_value({:expr, code, _}), do: {:expr, code}
  defp plain_value(nil), do: nil

  defp source(n, {:string, s, m}) do
    d = <<Map.get(m, :delimiter, ?")::utf8>>
    n <> "=" <> d <> s <> d
  end

  defp source(n, {:expr, code, _}), do: n <> "={" <> code <> "}"
  defp source(n, nil), do: n

  defp attr_unit(n, {:string, s, m}, {l, c}, lines, map, tag) do
    start = string_value_start(n, Map.get(m, :delimiter, ?"), {l, c}, lines)
    locate = fn off -> map.(Pos.advance(start, binary_part(s, 0, off))) end
    unit = Unit.new(:heex_attr, [%Part{text: s, locate: locate}], attr: n, tag: tag)
    if unit.parts == [], do: nil, else: unit
  end

  defp attr_unit(n, {:expr, code, %{line: l, column: c}}, _pos, _lines, map, tag),
    do: expr_unit(code, {l, c}, map, :heex_attr, attr: n, tag: tag)

  defp attr_unit(_n, nil, _pos, _lines, _map, _tag), do: nil

  # The value starts after `name`, optional spaces, `=`, optional spaces and
  # the delimiter. Falls back to the usual `name="` width.
  defp string_value_start(n, delim, {l, c}, lines) do
    rest = lines |> Pos.line(l) |> Kernel.||("") |> String.slice((c - 1 + String.length(n))..-1//1)
    d = <<delim::utf8>>

    case Regex.run(~r/^\s*=\s*#{Regex.escape(d)}/, rest) do
      [m] -> {l, c + String.length(n) + String.length(m)}
      _ -> {l, c + String.length(n) + 2}
    end
  end

  # An expression with no quote and no sigil holds no string literal, so it
  # is not parsed at all (most attrs are `{@x}` or `{@form[:name]}`).
  defp expr_unit(code, pos, map, origin, opts) do
    if String.contains?(code, ["\"", "~"]), do: parse_expr_unit(code, pos, map, origin, opts)
  end

  defp parse_expr_unit(code, {l, c}, map, origin, opts) do
    outer = fn
      {1, cc} -> map.({l, c + cc - 1})
      {ll, cc} -> map.({l + ll - 1, cc})
    end

    ElixirAst.expr_unit(code, outer, origin, opts)
  end

  # An HTML comment that holds a directive is sent to the browser and is not
  # one of the comment forms this check reads.
  defp misplaced(content, map) do
    ~r/<!--(?:(?!-->).)*?petal-check:(?:ignore|disable|enable)/s
    |> Regex.scan(content, return: :index)
    |> Enum.map(fn [{start, _len}] ->
      map.(Pos.advance({1, 1}, binary_part(content, 0, start)))
    end)
  end

  # -- position maps for ~H fragments --------------------------------------------

  @doc """
  The {line, column} map for a ~H fragment from ElixirAst.collect/2. Fast
  path: every content line sits at a fixed shift from its raw line (no
  escapes). Otherwise each position is walked from the sigil's start.
  """
  def mapper(raw, %{content: content, start: {sl, sc}} = frag) do
    clines = String.split(content, "\n")

    case shifts(raw, clines, frag) do
      {:ok, shifts} ->
        shifts = List.to_tuple(shifts)

        fn {l, c} ->
          shift = if l >= 1 and l <= tuple_size(shifts), do: elem(shifts, l - 1), else: 0
          {sl + l - 1, c + shift}
        end

      :walk ->
        starts = line_starts(clines)

        fn {l, c} ->
          case Enum.at(starts, l - 1) do
            nil ->
              frag.open

            {ls, ltext} ->
              off = ls + byte_size(String.slice(ltext, 0, max(c - 1, 0)))

              case Pos.walk(raw, {sl, sc}, binary_part(content, 0, off),
                     mode: frag.mode,
                     indent: frag.indent
                   ) do
                {:ok, pos} -> pos
                :lost -> frag.open
              end
          end
        end
    end
  end

  defp shifts(raw, clines, %{start: {sl, sc}, heredoc?: heredoc?}) do
    clines
    |> Enum.with_index()
    |> Enum.reduce_while([], fn {cl, i}, acc ->
      rl = Pos.line(raw, sl + i) || ""

      shift =
        cond do
          heredoc? ->
            pre = String.length(rl) - String.length(cl)
            if String.ends_with?(rl, cl) and String.trim(String.slice(rl, 0, max(pre, 0))) == "",
              do: pre,
              else: if(cl == "", do: 0, else: nil)

          i == 0 ->
            if String.slice(rl, sc - 1, String.length(cl)) == cl, do: sc - 1, else: nil

          true ->
            if String.starts_with?(rl, cl), do: 0, else: nil
        end

      if shift, do: {:cont, [shift | acc]}, else: {:halt, :walk}
    end)
    |> case do
      :walk -> :walk
      list -> {:ok, Enum.reverse(list)}
    end
  end

  defp line_starts(clines) do
    {starts, _} =
      Enum.map_reduce(clines, 0, fn cl, off -> {{off, cl}, off + byte_size(cl) + 1} end)

    starts
  end
end
