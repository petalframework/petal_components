defmodule PetalComponents.Check.Rules.TailwindV4Gate do
  @moduledoc false
  # Guide section 11 row 12. @tailwind base/components/variants/screens are
  # Tailwind v3 directives: an app that has them is on v3, and none of
  # petal_components 4.x's tokens load.
  #
  # `@tailwind utilities` alone is still valid in v4, after a split import
  # (`@import "tailwindcss/theme.css" layer(theme);`), so it is flagged only
  # when the same file also has one of the v3-only words. A file that already
  # has `@import "tailwindcss"` and a leftover directive is told to delete it.

  @behaviour PetalComponents.Check.Rule

  alias PetalComponents.Check.Css.Statement
  alias PetalComponents.Check.Rule

  @v3_only ~w(base components variants screens)

  @impl true
  def rule do
    %Rule{
      id: "tailwind-v4-gate",
      severity: :error,
      section: "11.12",
      row_keyword: "tailwind",
      scope: :css,
      why:
        "v3 directives mean the app is on Tailwind v3, and none of petal_components 4.x's tokens load",
      examples: [
        {:bad, "@tailwind base;\n@tailwind components;\n@tailwind utilities;"},
        {:good, ~s(@import "tailwindcss";)}
      ],
      exemptions: [
        ~s|@tailwind utilities on its own, after @import "tailwindcss/theme.css" layer(theme); (valid v4)|,
        "a directive inside a comment"
      ]
    }
  end

  @impl true
  def check(%Statement{text: text} = st, ctx) do
    with [subject, word] <- Regex.run(re(), text),
         words = directives(ctx.source.statements),
         true <- word in @v3_only or Enum.any?(words, &(&1 in @v3_only)) do
      [finding(st, subject, word, v4_import?(ctx.source.statements))]
    else
      _ -> []
    end
  end

  def check(_st, _ctx), do: []

  defp re, do: ~r/^@tailwind\s+(base|components|utilities|variants|screens)\b/

  defp directives(statements) do
    for %Statement{text: t} <- statements, [_, w] <- [Regex.run(re(), t)], do: w
  end

  defp v4_import?(statements) do
    Enum.any?(statements, &(&1.text =~ ~r/^@import\s+(?:url\(\s*)?["']tailwindcss["']/))
  end

  defp finding(st, subject, word, leftover?) do
    {message, fix} =
      if leftover? do
        {"@tailwind #{word} is a Tailwind v3 directive left beside the v4 import",
         "delete this line"}
      else
        {"@tailwind #{word} is a Tailwind v3 directive; petal_components 4.x needs Tailwind v4",
         ~s|replace the @tailwind lines with one @import "tailwindcss"; line (see deps/petal_components/usage-rules.md step 3)|}
      end

    Rule.finding(rule(),
      line: st.line,
      column: st.column,
      subject: subject,
      message: message,
      replacement: nil,
      fix: fix
    )
  end
end
