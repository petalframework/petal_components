defmodule PetalComponents.Check.Rules.TildeESigil do
  @moduledoc false
  # Guide section 11 row 11. HEEx only: ~E is the old EEx sigil, with no
  # HTML-aware engine, and phoenix_html 4 no longer has it. Read from the
  # parsed file, so a ~E named in a comment or a string is never flagged.

  @behaviour PetalComponents.Check.Rule

  alias PetalComponents.Check.Rule

  @impl true
  def rule do
    %Rule{
      id: "tilde-e-sigil",
      severity: :error,
      section: "11.11",
      row_keyword: "sigil",
      scope: :elixir_ast,
      why: "HEEx only: ~E has no HTML-aware engine and phoenix_html 4 no longer has it",
      examples: [
        {:bad, ~s(~E"<p><%= @name %></p>")},
        {:good, ~s(~H"<p>{@name}</p>")}
      ],
      exemptions: [
        "~E named in a comment, a string or a doc",
        "a module that defines its own sigil_E"
      ]
    }
  end

  @impl true
  def check(ast, ctx) do
    if MapSet.member?(ctx.defs, "sigil_E") do
      []
    else
      {_, found} =
        Macro.prewalk(ast, [], fn
          {:sigil_E, meta, [_, _]} = node, acc when is_list(meta) -> {node, [meta | acc]}
          node, acc -> {node, acc}
        end)

      found |> Enum.reverse() |> Enum.map(&finding/1)
    end
  end

  defp finding(meta) do
    Rule.finding(rule(),
      line: meta[:line],
      column: meta[:column],
      subject: "~E",
      message: "~E is the old EEx sigil, with no HTML-aware engine",
      replacement: nil,
      fix:
        "rewrite it as ~H: assigns become {@name}, and ~H needs a variable named assigns in scope"
    )
  end
end
