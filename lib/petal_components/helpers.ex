defmodule PetalComponents.Helpers do
  @moduledoc """
  For any helper functions used across multiple components. Ideally we keep this empty - components should be copy-pastable.
  """

  @doc """
  Generates a unique HTML ID based on the given string.

  ## Parameters

    - string: The input string (e.g., heading or label)
    - prefix: An optional prefix for the ID (default: "c")

  ## Examples

      iex> PetalComponents.Helpers.uniq_id("My Heading")
      "c-my-heading-1234"

      iex> PetalComponents.Helpers.uniq_id("My Label", "custom")
      "custom-my-label-5678"
  """
  def uniq_id(string, prefix \\ "c") do
    slug =
      string
      |> String.downcase()
      |> String.replace(~r/[^\w-]+/, "-")
      # Limit slug length
      |> String.slice(0, 20)

    unique = System.unique_integer([:positive]) |> Integer.to_string(36)
    "#{prefix}-#{slug}-#{unique}"
  end

  @doc """
  Builds a class string from a given input list by joining them together

  This code was taken from Elixirs `Enum.join/2` function and optimized for
  building class name (e.g removing empty strings and joining with " " by default)
  """
  @deprecated "Phoenix handles lists of strings for classes now. No need for this."
  def build_class(list, joiner \\ " ")
  def build_class([], _joiner), do: ""

  def build_class(list, joiner) when is_list(list) do
    join_non_empty_list(list, joiner, [])
    |> :lists.reverse()
    |> IO.iodata_to_binary()
  end

  # Remove joiner (if present), since our last element was empty and isn't added
  defp join_non_empty_list([""], joiner, [joiner | acc]), do: acc
  defp join_non_empty_list([nil], joiner, [joiner | acc]), do: acc
  defp join_non_empty_list([""], _joiner, acc), do: acc
  defp join_non_empty_list([nil], _joiner, acc), do: acc
  defp join_non_empty_list([first], _joiner, acc), do: [entry_to_string(first) | acc]

  # Don't append empty string to our class list
  defp join_non_empty_list(["" | rest], joiner, acc) do
    join_non_empty_list(rest, joiner, acc)
  end

  defp join_non_empty_list([nil | rest], joiner, acc) do
    join_non_empty_list(rest, joiner, acc)
  end

  defp join_non_empty_list([first | rest], joiner, acc) do
    join_non_empty_list(rest, joiner, [joiner, entry_to_string(first) | acc])
  end

  # Trim the input string
  defp entry_to_string(entry) when is_binary(entry), do: String.trim(entry)
  defp entry_to_string(entry), do: String.trim(String.Chars.to_string(entry))
end
