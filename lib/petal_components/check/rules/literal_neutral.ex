defmodule PetalComponents.Check.Rules.LiteralNeutral do
  @moduledoc false
  # Guide section 11 row 1. A slate, zinc, neutral or stone utility forks the
  # palette and ignores the app's gray remap.
  #
  # Class names in this file are built at runtime on purpose: Tailwind scans
  # deps/petal_components for class names, and a literal one here would add
  # CSS to every app.

  @behaviour PetalComponents.Check.Rule

  alias PetalComponents.Check.Classes
  alias PetalComponents.Check.Rule
  alias PetalComponents.Check.Unit

  @impl true
  def rule do
    %Rule{
      id: "literal-neutral",
      severity: :error,
      section: "11.1",
      row_keyword: "neutral",
      scope: :class_unit,
      why:
        "gray is the neutral dial; slate, zinc, neutral and stone fork the palette and ignore the app's gray remap",
      note:
        "the default gray ramp is zinc, so the swap looks the same until the app remaps gray in @theme " <>
          "(guides/design.md section 1)",
      examples: [
        {:bad, ~s(<p class="#{cls("text", "slate", "500")}">)},
        {:good, ~s(<p class="#{cls("text", "gray", "500")}">)}
      ],
      exemptions: [
        "a theme remap in CSS (#{"--color-gray-500: var(--color-" <> "slate-500)"}): it is not a class",
        "prose, comments, docs and HEEx text nodes: only string literals and attr values are read",
        "a palette name with no stop (#{"bg-" <> "zinc-texture"})",
        "a string that holds markup, such as a code sample"
      ]
    }
  end

  defp cls(prop, family, stop), do: Enum.join([prop, family, stop], "-")

  defp utility_re do
    ~r/^(-?(?:bg|text|border(?:-(?:x|y|t|r|b|s|e))?|ring|ring-offset|divide|outline|fill|stroke|from|via|to|placeholder|accent|caret|decoration|shadow|inset-shadow|inset-ring|drop-shadow))-(slate|zinc|neutral|stone)-(50|100|200|300|400|500|600|700|800|900|950)((?:\/\d+|\/\[[^\]]+\])?)$/
  end

  @impl true
  def check(%Unit{} = unit, _ctx) do
    for tok <- unit.tokens,
        %{} = parsed <- [Classes.parse(tok.text)],
        [_, prop, _family, stop, alpha] <- [Regex.run(utility_re(), parsed.utility)] do
      replacement = Classes.rebuild(parsed, "#{prop}-gray-#{stop}#{alpha}")
      {line, column} = Unit.position(unit, tok)

      Rule.finding(rule(),
        line: line,
        column: column,
        subject: tok.text,
        message:
          "#{tok.text} is a literal neutral palette; use the gray ramp, which the app remaps in @theme",
        replacement: replacement,
        fix: "replace #{tok.text} with #{replacement}",
        tag_line: unit.tag && unit.tag.line
      )
    end
  end
end
