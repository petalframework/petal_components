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

  # Attrs that hold a code sample to show, not classes to apply.
  @sample_attrs ~w(code source snippet example)

  # Words that never are a class but are common in a sentence.
  @prose_words ~w(an and are for in instead is it of or the this to use with you your)

  @doc """
  True when a unit is a code sample or a sentence, not a class list. No
  class rule reads such a unit:

    * it holds markup (`<div`, `<.button`), as a code sample does
    * it is the value of a `code`, `source`, `snippet` or `example` attr
    * it reads as prose: a capitalised word, a word ending in punctuation,
      or a common English word such as "with" or "your"
  """
  def sample?(%__MODULE__{} = unit) do
    Enum.any?(unit.parts, &(&1.text =~ ~r/<[a-z.:]/)) or
      (unit.origin == :heex_attr and unit.attr in @sample_attrs) or
      Enum.any?(unit.tokens, &prose_word?(&1.text))
  end

  # A trailing ! is also Tailwind v4's important (hidden!, block!), so a word
  # ending in ! is prose only when it is not a class.
  defp prose_word?(text) do
    text in @prose_words or text =~ ~r/^[A-Z][a-z]+[.,;:!?)]*$/ or text =~ ~r/^[a-z]+[.,;?]$/ or
      (text =~ ~r/^[a-z]+!$/ and Classes.parse(text) == :error)
  end

  @doc "The file {line, column} of a token."
  def position(%__MODULE__{parts: parts}, %Token{part: i, offset: off}) do
    part = Enum.at(parts, i)
    part.locate.(off)
  end
end
