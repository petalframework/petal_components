defmodule PetalComponents.Check.Rules.FocusRing do
  @moduledoc false
  # Guide section 6. The house ring is focus-visible, with no offset, and
  # outline-none never stands alone. Three cases under one id, each its own
  # finding:
  #
  #   a. a ring with a plain focus: variant (shows on mouse clicks too)
  #   b. a ring offset width other than 0
  #   c. outline-none with no focus-state replacement in the same string
  #
  # A warning: some text inputs use focus: on purpose.

  @behaviour PetalComponents.Check.Rule

  alias PetalComponents.Check.Classes
  alias PetalComponents.Check.Rule
  alias PetalComponents.Check.Unit

  import Rule, only: [cls: 1]

  @focus_family ~w(focus focus-visible focus-within peer-focus peer-focus-visible
                   peer-focus-within group-focus group-focus-visible group-focus-within)

  @impl true
  def rule do
    %Rule{
      id: "focus-ring",
      severity: :warning,
      section: "6",
      row_keyword: "focus",
      scope: :class_unit,
      why:
        "the house ring is focus-visible with no offset; focus: rings show on mouse clicks, and outline-none alone removes focus",
      examples: [
        {:bad, ~s(<a class="focus:outline-none focus:ring-2 focus:ring-offset-2">)},
        {:good, ~s(<a class="#{house()}">)}
      ],
      exemptions: [
        "focus:ring-0 and ring-offset-0, which reset a ring",
        "outline-none next to any focus-state replacement in the same string: a ring, an outline, a border, a background, a shadow, an underline or a text colour",
        "ring-offset colours with no width"
      ]
    }
  end

  @doc false
  def house do
    "focus:outline-hidden focus-visible:ring-2 focus-visible:" <>
      cls(["ring", "primary", "500/50"])
  end

  @impl true
  def check(%Unit{} = unit, _ctx) do
    parsed =
      for tok <- unit.tokens, %{} = p <- [Classes.parse(tok.text)], do: {tok, p}

    replaced? = Enum.any?(parsed, fn {_t, p} -> replacement?(p) end)

    Enum.flat_map(parsed, fn {tok, p} -> cases(unit, tok, p, replaced?) end)
  end

  defp cases(unit, tok, p, replaced?) do
    u = p.utility

    cond do
      offset_width?(u) ->
        [
          finding(
            unit,
            tok,
            "#{tok.text} is a ring offset, which the house ring does not use",
            "",
            "remove #{tok.text}"
          )
        ]

      ring?(u) and "focus" in p.variants and not reset?(u) ->
        variants = Enum.map(p.variants, &if(&1 == "focus", do: "focus-visible", else: &1))
        replacement = rebuild_variants(p, variants)

        [
          finding(
            unit,
            tok,
            "#{tok.text} shows the ring on mouse clicks too",
            replacement,
            "replace #{tok.text} with #{replacement}"
          )
        ]

      u == "outline-none" and not replaced? ->
        [
          finding(
            unit,
            tok,
            "#{tok.text} removes the focus outline with no visible replacement",
            house(),
            "replace #{tok.text} with #{house()}"
          )
        ]

      true ->
        []
    end
  end

  defp ring?(u), do: u == "ring" or (String.starts_with?(u, "ring-") and not offset?(u))
  defp offset?(u), do: String.starts_with?(u, "ring-offset-")
  defp reset?(u), do: u in ["ring-0", "ring-transparent"]

  defp offset_width?(u) do
    case Regex.run(~r/^ring-offset-(\d+|\[[^\]]+\])$/, u) do
      [_, "0"] -> false
      [_, "[0]"] -> false
      [_, "[0px]"] -> false
      [_, _] -> true
      nil -> false
    end
  end

  # A visible focus-state style in the same string replaces the outline.
  defp replacement?(%{variants: variants, utility: u}) do
    Enum.any?(variants, &(&1 in @focus_family)) and
      Regex.match?(
        ~r/^(ring|outline|border|bg|shadow|underline|decoration|text|inset-ring)(-|$)/,
        u
      ) and
      not reset?(u) and u not in ["outline-none", "outline-hidden", "outline-0", "shadow-none"]
  end

  defp rebuild_variants(p, variants) do
    lead = if p.important == :leading, do: "!", else: ""
    lead <> Enum.map_join(variants, "", &(&1 <> ":")) <> p.inner <> p.utility <> p.suffix
  end

  defp finding(unit, tok, message, replacement, fix) do
    {line, column} = Unit.position(unit, tok)

    Rule.finding(rule(),
      line: line,
      column: column,
      subject: tok.text,
      message: message,
      replacement: replacement,
      fix: fix,
      tag_line: unit.tag && unit.tag.line
    )
  end
end
