defmodule ComponentCase do
  use ExUnit.CaseTemplate

  setup do
    # This will run before each test that uses this case
    :ok
  end

  using do
    quote do
      import Phoenix.Component
      import Phoenix.LiveViewTest

      import Plug.HTML, only: [html_escape: 1]

      defp count_substring(string, substring) do
        string |> String.split(substring) |> Enum.count() |> Kernel.-(1)
      end

      defp find_icon(html) when is_binary(html) do
        LazyHTML.from_fragment(html)
        |> LazyHTML.query("span[class^=hero]")
        |> Enum.any?()
      end

      defp find_icon(html) do
        html
        |> LazyHTML.query("span[class^=hero]")
        |> Enum.any?()
      end

      defp find_icon(html, class) when is_binary(html) do
        LazyHTML.from_fragment(html)
        |> LazyHTML.query("span.#{class}")
        |> Enum.any?()
      end

      defp find_icon(html, class) do
        html
        |> LazyHTML.query("span.#{class}")
        |> Enum.any?()
      end
    end
  end
end
