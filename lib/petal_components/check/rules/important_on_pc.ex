defmodule PetalComponents.Check.Rules.ImportantOnPc do
  @moduledoc false
  # Guide section 11 row 2. An app !important on a .pc-* selector fights the
  # component's styling API. Every pc-* rule sits in @layer components, so a
  # plain unlayered app rule already wins, and the !important does nothing
  # but block the next change.
  #
  # The exception is a property the library may set as an inline style from
  # a hook, or pins with its own !important (icon sizes). There an app
  # !important can be the only thing that works, or can never work, and the
  # right fix is the component's attr. Those properties are warnings, and a
  # test keeps the list in step with default.css and petal_components.js.

  @behaviour PetalComponents.Check.Rule

  alias PetalComponents.Check.Css
  alias PetalComponents.Check.Css.Statement
  alias PetalComponents.Check.Pos
  alias PetalComponents.Check.Rule

  # Exact names, plus the families below.
  @warn_exact ~w(width height min-width min-height max-width max-height top right bottom left
                 transform translate scale rotate opacity display visibility position z-index
                 cursor user-select margin)
  @warn_prefix ~w(inset flex transition animation overflow scroll margin-)

  @motion ~w(animation transition scroll-behavior)

  @doc false
  def warn_properties, do: {@warn_exact, @warn_prefix}

  @impl true
  def rule do
    %Rule{
      id: "important-on-pc",
      severity: :error,
      section: "11.2",
      row_keyword: "bang",
      scope: :css,
      why:
        "an app !important on a .pc-* selector fights the component's styling API; a plain rule already wins over @layer components",
      note:
        "sizes, positions, display, opacity and motion are warnings, not errors: the library may set them " <>
          "inline from a hook or pin them, so use the component's attrs there",
      examples: [
        {:bad, ".pc-button { color: var(--color-brand) !important; }"},
        {:good, ".pc-button { color: var(--color-brand); }"}
      ],
      exemptions: [
        ".pc- only inside :not(...) or :has(...), which does not target the component",
        "animation, transition and scroll-behavior inside @media (prefers-reduced-motion: reduce)",
        "selectors with no .pc- class"
      ]
    }
  end

  @impl true
  def check(%Statement{text: text} = st, _ctx) do
    with [bang] <- Regex.run(~r/!\s*important\s*$/i, text),
         [_, prop] <- Regex.run(~r/^([a-zA-Z-]+)\s*:/, text),
         prop = String.downcase(prop),
         selector when is_binary(selector) <- pc_selector(Css.selectors(st)),
         false <- reduced_motion?(st, prop) do
      [finding(st, text, bang, prop, selector)]
    else
      _ -> []
    end
  end

  def check(_st, _ctx), do: []

  # The first selector in the list (split on top-level commas) that still
  # names a .pc- class once :not() and :has() arguments are gone.
  defp pc_selector(preludes) do
    Enum.find_value(preludes, fn p ->
      p
      |> split_list()
      |> Enum.find(&(strip_args(&1) =~ ~r/\.pc-[a-z0-9]/))
    end)
  end

  defp split_list(prelude) do
    {parts, cur, _} =
      prelude
      |> String.graphemes()
      |> Enum.reduce({[], "", 0}, fn
        ",", {parts, cur, 0} -> {[cur | parts], "", 0}
        c, {parts, cur, d} when c in ["(", "["] -> {parts, cur <> c, d + 1}
        c, {parts, cur, d} when c in [")", "]"] -> {parts, cur <> c, max(d - 1, 0)}
        c, {parts, cur, d} -> {parts, cur <> c, d}
      end)

    [cur | parts] |> Enum.reverse() |> Enum.map(&String.trim/1)
  end

  # Deletes the arguments of :not(...) and :has(...), nested parens included.
  defp strip_args(sel) do
    case :binary.match(sel, [":not(", ":has("]) do
      :nomatch ->
        sel

      {start, len} ->
        head = binary_part(sel, 0, start)
        rest = binary_part(sel, start + len, byte_size(sel) - start - len)
        head <> strip_args(drop_paren(rest, 1))
    end
  end

  defp drop_paren(rest, 0), do: rest
  defp drop_paren(<<>>, _), do: <<>>
  defp drop_paren("(" <> r, d), do: drop_paren(r, d + 1)
  defp drop_paren(")" <> r, d), do: drop_paren(r, d - 1)
  defp drop_paren(<<_, r::binary>>, d), do: drop_paren(r, d)

  defp reduced_motion?(st, prop) do
    Enum.any?(Css.at_rules(st), &(&1 =~ ~r/prefers-reduced-motion\s*:\s*reduce/i)) and
      Enum.any?(@motion, &(prop == &1 or String.starts_with?(prop, &1 <> "-")))
  end

  defp warn?(prop) do
    prop in @warn_exact or Enum.any?(@warn_prefix, &String.starts_with?(prop, &1))
  end

  defp finding(st, text, bang, prop, selector) do
    offset = byte_size(text) - byte_size(bang)
    {line, column} = Pos.advance({st.line, st.column}, binary_part(text, 0, offset))
    subject = String.trim_trailing(bang)
    sel = selector |> String.replace(~r/\s+/, " ") |> String.slice(0, 60)

    if warn?(prop) do
      Rule.finding(rule(),
        severity: :warning,
        line: line,
        column: column,
        subject: subject,
        message:
          "!important on #{sel} (#{prop}): the library may set #{prop} inline from a hook or pin it, " <>
            "so this may be needed, or may never work",
        replacement: nil,
        fix:
          "use the component's attrs (size and the like) where they exist; " <>
            "keep !important only when a hook's inline style has to lose"
      )
    else
      Rule.finding(rule(),
        line: line,
        column: column,
        subject: subject,
        message: "!important on #{sel} (#{prop}) fights the component's styling API",
        replacement: "",
        fix:
          "drop !important: petal_components styles sit in @layer components, so a plain rule in your CSS already wins"
      )
    end
  end
end
