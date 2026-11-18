defmodule PetalComponents.Check.Rules.PcFunctionPrefix do
  @moduledoc false
  # Guide section 11 row 4. petal_components functions have no pc_ prefix;
  # pc- (with a dash) is only the CSS class prefix. `<.pc_button>` is a
  # function that does not exist.

  @behaviour PetalComponents.Check.Rule

  alias PetalComponents.Check.Components
  alias PetalComponents.Check.Heex.Tag
  alias PetalComponents.Check.Rule

  @impl true
  def rule do
    %Rule{
      id: "pc-function-prefix",
      severity: :error,
      section: "11.4",
      row_keyword: "prefix",
      scope: :component,
      why: "petal_components functions have no pc_ prefix; pc- is only the CSS class prefix",
      examples: [
        {:bad, ~s(<.pc_button label="Save" />)},
        {:good, ~s(<.button label="Save" />)}
      ],
      exemptions: [
        ~s(class="pc-button": the CSS class prefix is pc- with a dash, and is fine),
        "a component the app defines itself with a pc_ name (def pc_card(assigns))",
        "<.pc_x> where x is not a petal_components function",
        "markup quoted inside a string or a comment"
      ]
    }
  end

  @impl true
  def check(%Tag{kind: :local_component, name: "pc_" <> bare = name} = tag, ctx) do
    if MapSet.member?(ctx.names, bare) and not MapSet.member?(ctx.defs, name),
      do: [finding(tag, "<." <> name, "<." <> bare)],
      else: []
  end

  def check(%Tag{kind: :remote_component, name: name} = tag, ctx) do
    with "pc_" <> bare <- Components.function_name(tag),
         true <- MapSet.member?(ctx.names, bare),
         true <- ctx.petal?.(tag) do
      module = name |> String.split(".") |> Enum.drop(-1) |> Enum.join(".")
      [finding(tag, "<" <> name, "<" <> module <> "." <> bare)]
    else
      _ -> []
    end
  end

  def check(_tag, _ctx), do: []

  defp finding(tag, subject, replacement) do
    Rule.finding(rule(),
      line: tag.line,
      column: tag.column,
      subject: subject,
      message: "#{subject}> does not exist: component functions have no pc_ prefix",
      replacement: replacement,
      fix: "rename #{subject}> to #{replacement}>, and its closing tag if it has one",
      tag_line: tag.line
    )
  end
end
