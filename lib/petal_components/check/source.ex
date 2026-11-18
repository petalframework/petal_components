defmodule PetalComponents.Check.Source do
  @moduledoc false
  # One file, read once. Everything a rule needs (tags, units, CSS
  # statements, the AST) comes from here, so a file is parsed once for all
  # rules. A part that cannot be read is recorded in `unchecked`, never
  # skipped quietly.

  alias PetalComponents.Check.Css
  alias PetalComponents.Check.ElixirAst
  alias PetalComponents.Check.Heex
  alias PetalComponents.Check.Pos

  defstruct [
    :path,
    :abs,
    :kind,
    :ast,
    # the file's lines (Pos.lines/1), for rules that read the text around a finding
    :lines,
    tags: [],
    units: [],
    statements: [],
    # %{text, line, column, end_line, trailing?} for every real comment
    comments: [],
    # {line, column} of HTML comments that hold a directive
    misplaced: [],
    # %{line, column, reason, kind: :read | :parse | :tokenizer | :internal}
    unchecked: [],
    defs: MapSet.new(),
    aliases: %{},
    excepts: MapSet.new(),
    heex?: false
  ]

  @doc "Reads `abs` (shown as `path`). `tok` is `{:ok, module}` or `{:error, reason}`."
  def read(abs, path, tok) do
    kind = kind(path)
    source = %__MODULE__{path: path, abs: abs, kind: kind}

    case File.read(abs) do
      {:ok, src} ->
        from_string(source, src, tok)

      {:error, reason} ->
        unchecked(
          source,
          {1, 1},
          "this file could not be read (#{:file.format_error(reason)})",
          :read
        )
    end
  rescue
    e ->
      unchecked(
        %__MODULE__{path: path, abs: abs, kind: kind(path)},
        {1, 1},
        "internal error while reading this file (please report): " <>
          first_line(Exception.message(e)),
        :internal
      )
  end

  @doc "Reads source text that is already in memory."
  def from_string(%__MODULE__{} = source, src, tok) do
    if String.valid?(src),
      do: parse(%{source | lines: Pos.lines(src)}, src, tok),
      else: unchecked(source, {1, 1}, "this file is not valid UTF-8", :read)
  end

  def kind(path) do
    case Path.extname(path) do
      ".ex" -> :ex
      ".heex" -> :heex
      ".css" -> :css
    end
  end

  @doc "Records a part of the file that was not checked."
  def unchecked(%__MODULE__{} = s, {l, c}, reason, kind) do
    %{s | unchecked: s.unchecked ++ [%{line: l, column: c, reason: reason, kind: kind}]}
  end

  defp parse(%{kind: :ex} = s, src, tok) do
    case ElixirAst.parse(src, s.path) do
      {:ok, ast, comments} ->
        raw = Pos.lines(src)
        info = ElixirAst.collect(ast, raw)

        s = %{
          s
          | ast: ast,
            units: info.units,
            defs: info.defs,
            aliases: info.aliases,
            excepts: info.excepts,
            comments: Enum.map(comments, &elixir_comment(&1, raw)),
            heex?: info.heex != []
        }

        Enum.reduce(info.heex, s, fn frag, s ->
          fragment(s, frag.content, Heex.mapper(raw, frag), tok)
        end)

      {:error, pos, msg} ->
        unchecked(s, pos, "this file could not be read as Elixir: " <> msg, :parse)
    end
  end

  defp parse(%{kind: :heex} = s, src, tok) do
    fragment(%{s | heex?: true}, src, &Function.identity/1, tok)
  end

  defp parse(%{kind: :css} = s, src, _tok) do
    case Css.parse(src) do
      {:ok, %{statements: st, comments: comments, units: units}} ->
        %{s | statements: st, comments: comments, units: units}

      {:error, pos, reason} ->
        unchecked(s, pos, "this CSS could not be read: " <> reason, :parse)
    end
  end

  defp fragment(s, content, map, {:ok, tok}) do
    case Heex.fragment(content, map, tok) do
      {:ok, %{tags: tags, units: units, comments: comments, misplaced: misplaced}} ->
        %{
          s
          | tags: s.tags ++ tags,
            units: s.units ++ units,
            comments: s.comments ++ comments,
            misplaced: s.misplaced ++ misplaced
        }

      {:unchecked, pos, reason} ->
        unchecked(s, pos, reason, :parse)
    end
  end

  defp fragment(s, _content, map, {:error, reason}) do
    if Enum.any?(s.unchecked, &(&1.kind == :tokenizer)),
      do: s,
      else: unchecked(s, map.({1, 1}), reason, :tokenizer)
  end

  defp elixir_comment(%{line: l, column: c, text: text}, raw) do
    before = raw |> Pos.line(l) |> Kernel.||("") |> String.slice(0, c - 1)
    %{text: text, line: l, column: c, end_line: l, trailing?: String.trim(before) != ""}
  end

  defp first_line(s), do: s |> String.split("\n") |> hd()
end
