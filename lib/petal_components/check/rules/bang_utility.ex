defmodule PetalComponents.Check.Rules.BangUtility do
  @moduledoc false
  # Guide section 11 row 2. pc-* classes are the component's styling API; a
  # ! utility on a component's class attr fights it and breaks on the next
  # release. Only the class attr of a petal_components call is read: a bang
  # on a raw element or on the app's own component is not this contract.
  # Elixir negation (`!@open`) never reaches a class rule, since units hold
  # only the insides of string literals.

  @behaviour PetalComponents.Check.Rule

  alias PetalComponents.Check.Classes
  alias PetalComponents.Check.Components
  alias PetalComponents.Check.Heex.Tag
  alias PetalComponents.Check.Rule
  alias PetalComponents.Check.Unit

  import Rule, only: [cls: 1]

  @headings ~w(h1 h2 h3 h4 h5)

  @impl true
  def rule do
    %Rule{
      id: "bang-utility",
      severity: :error,
      section: "11.2",
      row_keyword: "bang",
      scope: :class_unit,
      why:
        "pc-* classes are the component's styling API; a ! utility on a component call fights it and breaks on the next release",
      note:
        "petal_components styles sit in @layer components, so try the plain utility first; " <>
          "if it does not apply (the library pins some sizes), use the component's attr instead",
      examples: [
        {:bad, ~s(<.button class="!#{cls(["px", "0"])}" label="Save" />)},
        {:good, ~s(<.button class="#{cls(["px", "0"])}" label="Save" />)}
      ],
      exemptions: [
        ~s(a ! on a raw element, <div class="!#{cls(["mb", "0"])}">, or on the app's own component),
        ~s(Elixir negation in a class expression: class={if !@open, do: "hidden"}),
        ~s(a ! inside brackets: #{cls(["content", "['!']"])}),
        "a call to carousel, filters or toast_group: their library styles are not in " <>
          "@layer components yet, so a plain utility can lose to them and a ! can be the only way",
        "class attrs other than class (*_class) and slot class attrs (wave 2)"
      ]
    }
  end

  @impl true
  def check(%Unit{attr: "class", tag: %Tag{} = tag} = unit, ctx) do
    if ctx.petal?.(tag) and not MapSet.member?(ctx.unlayered, Components.function_name(tag)) do
      for tok <- unit.tokens,
          %{important: imp} = parsed when imp != :none <- [Classes.parse(tok.text)],
          do: finding(unit, tok, parsed, tag)
    else
      []
    end
  end

  def check(_unit, _ctx), do: []

  defp finding(unit, tok, parsed, tag) do
    {line, column} = Unit.position(unit, tok)
    name = Components.function_name(tag)
    shown = if tag.kind == :remote_component, do: "<#{tag.name}>", else: "<.#{tag.name}>"

    plain = String.replace_prefix(parsed.prefix, "!", "") <> parsed.utility

    fields =
      if name in @headings and parsed.utility == cls(["mb", "0"]) and parsed.variants == [] do
        [
          replacement: "",
          add_attr: "no_margin",
          fix: "remove #{tok.text} from class and add the no_margin attr"
        ]
      else
        [replacement: plain, fix: "replace #{tok.text} with #{plain}"]
      end

    Rule.finding(
      rule(),
      [
        line: line,
        column: column,
        subject: tok.text,
        message: "#{tok.text} on #{shown} forces a utility over the component's own styles",
        tag_line: tag.line
      ] ++ fields
    )
  end
end
