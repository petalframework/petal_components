defmodule PetalComponents.Check.Rules.SemanticHue do
  @moduledoc false
  # Guide section 1. A literal red, green, emerald, yellow, amber or sky does
  # not follow the theme when a semantic role for the same meaning exists.
  # A suggestion only: a categorical colour (a chart series, a tag, a heart)
  # is fine as it is, so this is a warning.
  #
  # Most literal hues in real apps are categorical (nav icons, stat tiles,
  # chart bars), so a hue is reported only when the text around it says
  # what the role says: an error word near a red, a success word near a
  # green, and so on. That text is the line above, the tag's lines and the
  # two lines below the token. Skip beats a false alarm.

  @behaviour PetalComponents.Check.Rule

  alias PetalComponents.Check.Classes
  alias PetalComponents.Check.Pos
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

  # Words that mean each role. Matched as whole words, any case, and also
  # inside an icon name such as shield-exclamation, or an atom such as :error.
  @signals %{
    "danger" =>
      ~w(error errors fail failed failure failing invalid danger dangerous destroy destructive
         delete deleted remove revoke revoked ban banned suspend suspended denied reject rejected
         critical wrong overdue unpaid exclamation x-circle),
    "success" => ~w(success successful succeeded saved complete completed done valid verified paid
         approved confirmed check check-circle published),
    "warning" => ~w(warning warn caution pending expiring expires trial attention exclamation
         exclamation-triangle unverified deprecated),
    "info" => ~w(info information notice tip hint note information-circle)
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
        "a hue with no word for its role nearby (error, success, warning, info and their kin): a categorical colour",
        "gradient stops, shadows and fills (from-, via-, to-, shadow-, fill-)",
        "blue, indigo, purple, orange and the other hues: often categorical, and blue is the default primary",
        "a theme remap in CSS: it is not a class",
        "prose, comments and docs"
      ]
    }
  end

  defp utility_re do
    ~r/^(-?(?:bg|text|border(?:-(?:x|y|t|r|b|l|s|e))?|ring|stroke|divide|outline|decoration|placeholder|accent|caret))-(red|green|emerald|yellow|amber|sky)-(50|100|200|300|400|500|600|700|800|900|950)((?:\/\d+|\/\[[^\]]+\])?)$/
  end

  @impl true
  def check(%Unit{} = unit, ctx) do
    for tok <- unit.tokens,
        %{} = parsed <- [Classes.parse(tok.text)],
        [_, prop, hue, stop, alpha] <- [Regex.run(utility_re(), parsed.utility)],
        role = Map.fetch!(@roles, hue),
        {line, column} = Unit.position(unit, tok),
        signal?(role, around(ctx, unit, line)) do
      replacement = Classes.rebuild(parsed, "#{prop}-#{role}-#{stop}#{alpha}")

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

  # The line above the tag (or the token), the tag's lines and the two lines below.
  defp around(%{source: %{lines: lines}}, unit, line) when is_tuple(lines) do
    from = max(min((unit.tag && unit.tag.line) || line, line) - 1, 1)
    Enum.map_join(from..(line + 2)//1, "\n", &(Pos.line(lines, &1) || ""))
  end

  defp around(_ctx, _unit, _line), do: ""

  @doc false
  def signal?(role, text) do
    words = Map.fetch!(@signals, role) |> Enum.map_join("|", &Regex.escape/1)
    Regex.match?(~r/(?<![a-z])(#{words})(?![a-z])/i, text)
  end
end
