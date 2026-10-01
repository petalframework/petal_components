defmodule PetalComponents.Showcase.Highlight do
  @moduledoc """
  Server-side syntax highlighting for `PetalComponents.Showcase.Frame.code_block/1`.

  Tokens come out as classes (`<span class="l-string">`), not inline colours, so
  the palette lives in CSS (`.pc-code` in `default.css`): it follows light and
  dark mode and the gray dial, and no theme name can go missing between lumis
  versions (a bare `:html_inline` stopped defaulting to a theme in lumis 0.7,
  which rendered petal.build's examples colourless).

  Highlighting needs the optional `:lumis` dependency. Without it, or for a
  language lumis rejects, `to_html/2` returns nil and the code block renders
  plain, escaped code in the same chrome.
  """

  # :lumis is optional - apps without it must still compile this module quietly.
  @compile {:no_warn_undefined, Lumis}

  @doc """
  Highlights `code` as `language` and returns `{:safe, html}` (a `<pre>` of
  `.l-line` rows), or nil when highlighting is unavailable.
  """
  @spec to_html(String.t(), String.t()) :: {:safe, String.t()} | nil
  def to_html(code, language) when is_binary(code) and is_binary(language) do
    if Code.ensure_loaded?(Lumis) do
      # Never let a highlighter problem (unknown language, NIF mismatch) take
      # down a page - the caller falls back to plain code.
      try do
        case Lumis.highlight(code, formatter: {:html_linked, language: language}) do
          {:ok, html} when is_binary(html) -> {:safe, html}
          _ -> nil
        end
      rescue
        _ -> nil
      end
    end
  end

  def to_html(_code, _language), do: nil
end
