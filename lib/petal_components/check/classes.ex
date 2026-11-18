defmodule PetalComponents.Check.Classes do
  @moduledoc false
  # Splits a string unit into class-shaped tokens and parses one token into
  # variants, bang position and utility.

  # Utilities with no dash that are still real classes, so `!hidden` is a bang
  # and `wrong!` (prose) is not a token at all.
  @bare ~w(flex grid block inline hidden contents table static fixed absolute relative sticky
           visible invisible collapse isolate truncate italic underline overline uppercase
           lowercase capitalize grow shrink border rounded shadow outline ring transition
           container antialiased transform filter resize)

  @doc """
  Splits text on whitespace, quotes and backticks. Returns `[{token, byte_offset}]`.
  """
  def tokens(text) when is_binary(text) do
    ~r/[^\s"'`]+/u
    |> Regex.scan(text, return: :index)
    |> Enum.map(fn [{start, len}] -> {binary_part(text, start, len), start} end)
  end

  @doc """
  Parses one token. Returns `:error` for anything that is not class-shaped,
  else a map with:

    * `:variants` - `["dark", "hover"]`
    * `:important` - `:none | :leading | :inner | :trailing`
    * `:utility` - the utility without any bang, `"bg-white/20"`
    * `:prefix` - the text before the utility (variants, colons, a leading bang)
    * `:inner` - `"!"` for an inner bang, else `""`
    * `:suffix` - `"!"` for a trailing bang, else `""`

  So `token == prefix <> inner <> utility <> suffix`.
  """
  def parse(token) when is_binary(token) do
    with true <- shaped?(token),
         parts when is_list(parts) <- split_top(token),
         {variants_raw, [last]} <- Enum.split(parts, -1),
         false <- last == "" do
      {lead, variants} =
        case variants_raw do
          [] -> {false, []}
          [first | rest] -> strip_lead(first, rest)
        end

      lead = lead or (variants_raw == [] and String.starts_with?(last, "!"))
      {inner, last} = inner_bang(last, variants_raw)
      {suffix, utility} = trailing_bang(last)
      utility = if lead and variants_raw == [], do: String.trim_leading(utility, "!"), else: utility

      important =
        cond do
          lead -> :leading
          inner == "!" -> :inner
          suffix == "!" -> :trailing
          true -> :none
        end

      prefix_len = byte_size(token) - byte_size(inner) - byte_size(utility) - byte_size(suffix)

      parsed = %{
        variants: variants,
        important: important,
        utility: utility,
        prefix: binary_part(token, 0, prefix_len),
        inner: inner,
        suffix: suffix
      }

      if valid_utility?(parsed), do: parsed, else: :error
    else
      _ -> :error
    end
  end

  @doc "Rebuilds a parsed token around a new utility, keeping variants and bangs."
  def rebuild(%{prefix: p, inner: i, suffix: s}, utility), do: p <> i <> utility <> s

  defp strip_lead("!" <> first, rest), do: {true, [first | rest]}
  defp strip_lead(first, rest), do: {false, [first | rest]}

  defp inner_bang("!" <> util, [_ | _]), do: {"!", util}
  defp inner_bang(util, _), do: {"", util}

  defp trailing_bang(util) do
    if String.ends_with?(util, "!") and depth_zero_at_end?(util) do
      {"!", binary_part(util, 0, byte_size(util) - 1)}
    else
      {"", util}
    end
  end

  defp valid_utility?(%{utility: u, important: imp}) do
    cond do
      u == "" -> false
      String.contains?(u, "!") and not String.contains?(u, "[") -> false
      imp != :none and not (String.contains?(u, "-") or String.contains?(u, "[") or u in @bare) -> false
      true -> true
    end
  end

  # A class is lower-case-led and, outside brackets, holds only class characters.
  defp shaped?(token) do
    token =~ ~r/^!?-?[a-z0-9\[\(@*&_]/ and token != "!" and not String.ends_with?(token, ":") and
      chars_ok?(String.to_charlist(token), 0)
  end

  defp chars_ok?([], depth), do: depth == 0

  defp chars_ok?([c | t], depth) when c in [?[, ?(], do: chars_ok?(t, depth + 1)
  defp chars_ok?([c | t], depth) when c in [?], ?)] and depth > 0, do: chars_ok?(t, depth - 1)
  defp chars_ok?([_ | t], depth) when depth > 0, do: chars_ok?(t, depth)

  defp chars_ok?([c | t], 0)
       when c in ?a..?z or c in ?A..?Z or c in ?0..?9 or c in [?-, ?_, ?:, ?/, ?., ?!, ?%, ?#, ?@, ?*, ?&],
       do: chars_ok?(t, 0)

  defp chars_ok?(_, _), do: false

  # Splits on ":" outside [...] and (...).
  defp split_top(token) do
    {parts, cur, depth} =
      token
      |> String.to_charlist()
      |> Enum.reduce({[], [], 0}, fn
        ?:, {parts, cur, 0} -> {[cur | parts], [], 0}
        c, {parts, cur, d} when c in [?[, ?(] -> {parts, [c | cur], d + 1}
        c, {parts, cur, d} when c in [?], ?)] -> {parts, [c | cur], max(d - 1, 0)}
        c, {parts, cur, d} -> {parts, [c | cur], d}
      end)

    if depth == 0 do
      [cur | parts] |> Enum.reverse() |> Enum.map(&(&1 |> Enum.reverse() |> List.to_string()))
    else
      :error
    end
  end

  defp depth_zero_at_end?(util) do
    util
    |> String.to_charlist()
    |> Enum.reduce(0, fn
      c, d when c in [?[, ?(] -> d + 1
      c, d when c in [?], ?)] -> d - 1
      _, d -> d
    end)
    |> Kernel.==(0)
  end
end
