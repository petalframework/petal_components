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
        ".pc- only on an ancestor, .pc-modal .app-footer: the rule styles the app's element",
        ~s(.pc- inside a quoted string or an attribute selector, a[href$=".pc-file"]),
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

  # The first selector, with nesting resolved (`&` is the parent; no `&`
  # means a descendant of it), whose subject (its last compound selector,
  # the element the rule styles) names a .pc- class once quoted strings,
  # attribute selectors and :not()/:has() arguments are gone. A .pc- class
  # only on an ancestor (`.pc-modal .app-footer`) styles the app's element.
  defp pc_selector(preludes) do
    preludes
    |> resolve()
    |> Enum.find(&(&1 |> subject() |> String.match?(~r/\.pc-[a-z0-9]/)))
  end

  defp resolve(preludes) do
    Enum.reduce(preludes, [""], fn prelude, parents ->
      for parent <- parents, child <- split_list(prelude) do
        cond do
          parent == "" -> child
          String.contains?(child, "&") -> String.replace(child, "&", parent)
          true -> parent <> " " <> child
        end
      end
    end)
  end

  defp subject(sel) do
    sel
    |> String.replace(~r/"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'/, "")
    |> strip_brackets()
    |> strip_args()
    |> last_compound()
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

  # Drops [attr...] selectors, nested brackets included.
  defp strip_brackets(sel) do
    {out, _} =
      sel
      |> String.graphemes()
      |> Enum.reduce({"", 0}, fn
        "[", {out, d} -> {out, d + 1}
        "]", {out, d} when d > 0 -> {out, d - 1}
        c, {out, 0} -> {out <> c, 0}
        _c, {out, d} -> {out, d}
      end)

    out
  end

  # The text after the last top-level combinator (space, >, +, ~).
  defp last_compound(sel) do
    {_, cur} =
      sel
      |> String.trim()
      |> String.graphemes()
      |> Enum.reduce({0, ""}, fn
        c, {0, _cur} when c in [" ", ">", "+", "~", "\n", "\t"] -> {0, ""}
        "(", {d, cur} -> {d + 1, cur <> "("}
        ")", {d, cur} -> {max(d - 1, 0), cur <> ")"}
        c, {d, cur} -> {d, cur <> c}
      end)

    cur
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
    sel = selector |> String.replace(~r/\s+/, " ") |> String.slice(0, 80)

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
