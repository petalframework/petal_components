defmodule PetalComponents.Check.Finding do
  @moduledoc false
  # One problem at one place.
  #
  #   subject     - the text as written at line:column (a class token, an attr);
  #                 it feeds the fingerprint, so it never holds a line number
  #   replacement - the exact text that replaces `subject` there: "" means
  #                 delete it, nil means there is no mechanical fix
  #   fix         - the instruction for a person, always set
  #   note        - optional extra context, printed after the fix
  #   add_attr    - optional attr name to add to the tag (with replacement "")
  #   tag_line    - the line of the `<` of the tag the finding came from, so an
  #                 ignore comment above a multi-line tag covers it
  #   meta        - true for findings about suppressions themselves; never
  #                 suppressed or baselined

  defstruct [
    :rule,
    :severity,
    :section,
    :path,
    :line,
    :column,
    :subject,
    :message,
    :replacement,
    :fix,
    :note,
    :add_attr,
    :tag_line,
    :fingerprint,
    status: :new,
    meta: false
  ]

  @type t :: %__MODULE__{}

  @doc "16 hex characters from rule, path and subject. No line number, so edits above keep it."
  def fingerprint(rule, path, subject) do
    "#{rule}\n#{path}\n#{subject}"
    |> :erlang.md5()
    |> Base.encode16(case: :lower)
    |> binary_part(0, 16)
  end

  def key(%__MODULE__{rule: r, path: p, subject: s}), do: {r, p, s}
end
