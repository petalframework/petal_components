defmodule PetalComponents.Check.Rules.SemanticHue do
  @moduledoc false
  # Guide section 1. A literal red, green, emerald, yellow, amber or sky does
  # not follow the theme when a semantic role for the same meaning exists.
  # A suggestion only: a categorical colour (a chart series, a tag, a heart)
  # is fine as it is, so this is a warning.

  @behaviour PetalComponents.Check.Rule

  alias PetalComponents.Check.Classes
  alias PetalComponents.Check.Rule
  alias PetalComponents.Check.Unit

  import Rule, only: [cls: 1]

  @roles %{
    "red" => "danger",
    "green" => "success",
    "emerald" => "success",
    "yellow" => "warning",
    "amber" => "warning",
    "sky" => "info"
  }

  @impl true
  def rule do
    %Rule{
      id: "semantic-hue",
      severity: :warning,
      section: "1",
      row_keyword: "token",
      scope: :class_unit,
      why:
        "a literal hue does not follow the theme when a semantic role for the same meaning exists",
      note:
        "change it only when the colour means that role (an error, a success, a warning, info); " <>
          "a categorical colour such as a chart series or a tag can stay",
      examples: [
        {:bad, ~s(<p class="#{cls(["text", "red", "600"])}">Payment failed</p>)},
        {:good, ~s(<p class="#{cls(["text", "danger", "600"])}">Payment failed</p>)}
      ],
      exemptions: [
        "blue, indigo, purple, orange and the other hues: often categorical, and blue is the default primary",
        "a theme remap in CSS: it is not a class",
        "prose, comments and docs"
      ]
    }
  end

  defp utility_re do
    ~r/^(-?(?:bg|text|border(?:-(?:x|y|t|r|b|s|e))?|ring|fill|stroke|divide|outline|from|via|to|decoration|placeholder|accent|caret|shadow))-(red|green|emerald|yellow|amber|sky)-(50|100|200|300|400|500|600|700|800|900|950)((?:\/\d+|\/\[[^\]]+\])?)$/
  end

  @impl true
  def check(%Unit{} = unit, _ctx) do
    for tok <- unit.tokens,
        %{} = parsed <- [Classes.parse(tok.text)],
        [_, prop, hue, stop, alpha] <- [Regex.run(utility_re(), parsed.utility)] do
      role = Map.fetch!(@roles, hue)
      replacement = Classes.rebuild(parsed, "#{prop}-#{role}-#{stop}#{alpha}")
      {line, column} = Unit.position(unit, tok)

      Rule.finding(rule(),
        line: line,
        column: column,
        subject: tok.text,
        message: "#{tok.text} is a literal hue; the #{role} ramp follows the theme",
        replacement: replacement,
        fix: "replace #{tok.text} with #{replacement} if the colour means #{role}",
        tag_line: unit.tag && unit.tag.line
      )
    end
  end
end
