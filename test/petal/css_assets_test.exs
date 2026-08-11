defmodule PetalComponents.CssAssetsTest do
  use ExUnit.Case, async: true

  # The shipped stylesheets are consumed by strict downstream parsers
  # (Lightning CSS via Tailwind v4's --minify). These guards keep selector
  # mistakes that plain `mix test` can't see from reaching users' builds.

  @app_root Path.expand("../..", __DIR__)
  @css_assets ["assets/default.css", "assets/tailwind-gray.css"]

  for path <- @css_assets do
    test "#{path} contains no escaped-colon class selectors" do
      css = File.read!(Path.join(@app_root, unquote(path)))

      # pc-* semantic classes never contain colons, so a backslash-escaped
      # colon in this file means a Tailwind utility name (peer-checked:*,
      # dark:*, ...) leaked in as a selector. Those never match anything the
      # components render, and the double-backslash form (`\\:`) additionally
      # trips Lightning CSS with "not a valid pseudo-class" warnings on every
      # consumer asset build (issue #582).
      refute css =~ ~r/\\+:/,
             "#{unquote(path)} contains a backslash-escaped colon selector: " <>
               inspect(Regex.run(~r/^.*\\+:.*$/m, css))
    end
  end
end
