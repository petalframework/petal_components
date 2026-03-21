defmodule ComponentCase do
  @moduledoc """
  Shared test case for Petal Component tests.
  """

  use ExUnit.CaseTemplate

  setup do
    :ok
  end

  using do
    quote do
      import Phoenix.Component
      import Phoenix.LiveViewTest
      import Plug.HTML, only: [html_escape: 1]
      import PetalComponents.TestConstants

      defp default_assigns, do: %{}

      defp count_substring(string, substring) do
        string |> String.split(substring) |> Enum.count() |> Kernel.-(1)
      end

      # Icon helpers

      defp has_icon?(html, class \\ nil) do
        count_icons(html, class) > 0
      end

      defp count_icons(html, class \\ nil) do
        html
        |> parse_html()
        |> LazyHTML.query(icon_selector(class))
        |> Enum.count()
      end

      defp icon_selector(nil), do: "span[class*=hero]"
      defp icon_selector(class), do: "span.#{class}"

      defp parse_html(html) when is_binary(html), do: LazyHTML.from_fragment(html)
      defp parse_html(html), do: html

      # Class assertions

      defp assert_has_class(html, class) do
        assert html =~ class, "Expected HTML to contain class '#{class}'"
      end

      defp refute_has_class(html, class) do
        refute html =~ class, "Expected HTML to not contain class '#{class}'"
      end

      # Attribute assertions

      defp assert_attribute(html, attribute, value \\ nil) do
        if value do
          assert html =~ ~s{#{attribute}="#{value}"},
                 "Expected HTML to contain #{attribute}=\"#{value}\""
        else
          assert html =~ " #{attribute}",
                 "Expected HTML to contain attribute '#{attribute}'"
        end
      end

      defp refute_attribute(html, attribute) do
        refute html =~ " #{attribute}",
               "Expected HTML to not contain attribute '#{attribute}'"
      end
    end
  end
end
