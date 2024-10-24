defmodule PetalComponents.Helpers do
  @moduledoc """
  For any helper functions used across multiple components. Ideally we keep this empty - components should be copy-pastable.
  """

  @doc """
  Generates a unique HTML ID based on the given string or iodata.

  ## Parameters

    - input: The input string or iodata (e.g., heading or label)
    - prefix: An optional prefix for the ID (default: "c")

  ## Examples

      iex> PetalComponents.Helpers.uniq_id("My Heading")
      "c-my-heading-1234"

      iex> PetalComponents.Helpers.uniq_id(["My ", {:safe, "<a>Link</a>"}, " Label"], "custom")
      "custom-my-link-label-5678"
  """
  def uniq_id(input, prefix \\ "c")

  def uniq_id(input, prefix) when is_list(input) do
    # Convert iodata to string, handling both plain lists and lists with safe HTML
    string =
      input
      |> Enum.map(fn
        {:safe, html} ->
          html
          |> IO.iodata_to_binary()
          |> strip_html_and_entities()

        x when is_binary(x) ->
          x

        x ->
          to_string(x)
      end)
      |> Enum.join("")

    create_slug(string, prefix)
  end

  def uniq_id(string, prefix) when is_binary(string) do
    create_slug(string, prefix)
  end

  def uniq_id(other, prefix) do
    create_slug(to_string(other), prefix)
  end

  defp create_slug(string, prefix) do
    slug =
      string
      |> String.downcase()
      |> String.replace(~r/[^\w-]+/, "-")
      |> String.slice(0, 20)

    unique = System.unique_integer([:positive]) |> Integer.to_string(36)
    "#{prefix}-#{slug}-#{unique}"
  end

  defp strip_html_and_entities(string) do
    string
    # Strip HTML tags
    |> String.replace(~r/<[^>]*>/, " ")
    |> String.replace("&nbsp;", " ")
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
    # Normalize whitespace
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
