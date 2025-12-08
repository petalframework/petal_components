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

      defp find_icon(html) do
        parsed = Floki.parse_document!(html)
        Floki.find(parsed, "span[class^=hero]") != []
      end

      defp find_icon(html, class) do
        parsed = Floki.parse_document!(html)
        Floki.find(parsed, "span.#{class}") != []
      end
    end
  end
end
