defmodule PetalComponents.Check.Unit do
  @moduledoc false
  # A string unit: the inside of one string literal, one attr value, or all
  # the literals of one HEEx expression, plus where each piece came from.
  # Class rules only ever see units, so comments, docs, prose in text nodes
  # and Elixir negation (`!@open`) never reach them.

  alias PetalComponents.Check.Classes

  defmodule Part do
    @moduledoc false
    # text: the decoded literal text. locate: byte offset -> {line, col} in the file.
    # open_left / open_right: an interpolation touches that edge, so a token
    # touching it is only part of a class and is dropped.
    defstruct [:text, :locate, open_left: false, open_right: false]
  end

  defmodule Token do
    @moduledoc false
    defstruct [:text, :part, :offset]
  end

  # origin: :elixir | :heex_attr | :heex_expr | :css_apply
  # attr: the attr name for :heex_attr units ("class", ...), else nil
  # tag: the %Heex.Tag{} the attr belongs to, else nil
  defstruct [:origin, :attr, :tag, parts: [], tokens: []]

  def new(origin, parts, opts \\ []) do
    parts = Enum.reject(parts, &(&1.text == ""))

    tokens =
      parts
      |> Enum.with_index()
      |> Enum.flat_map(fn {part, i} ->
        toks = Classes.tokens(part.text)
        size = byte_size(part.text)

        Enum.reject(toks, fn {t, off} ->
          (part.open_left and off == 0) or (part.open_right and off + byte_size(t) == size)
        end)
        |> Enum.map(fn {t, off} -> %Token{text: t, part: i, offset: off} end)
      end)

    %__MODULE__{
      origin: origin,
      attr: Keyword.get(opts, :attr),
      tag: Keyword.get(opts, :tag),
      parts: parts,
      tokens: tokens
    }
  end

  @doc "The file {line, column} of a token."
  def position(%__MODULE__{parts: parts}, %Token{part: i, offset: off}) do
    part = Enum.at(parts, i)
    part.locate.(off)
  end
end
