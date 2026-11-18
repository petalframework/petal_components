defmodule PetalComponents.Check.Rule do
  @moduledoc false
  # The contract every rule module implements, and the metadata --rules,
  # --explain, the docs and the drift tests read.
  #
  # scope decides what the engine hands to check/2:
  #   :component  -> %Heex.Tag{} (every opening tag in every HEEx fragment)
  #   :class_unit -> %Unit{} (every string unit: Elixir literals, HEEx attr
  #                  values and expressions, CSS @apply arguments)
  #   :css        -> %Css.Statement{} (every CSS statement)
  #   :elixir_ast -> the whole quoted file, for .ex files
  #   :project    -> collect/2 once per source (every default-root CSS file,
  #                  even on a run given paths), then finish/2 once; findings
  #                  are kept only for the files this run checks
  #
  # ctx is a map: :path, :kind (:ex | :heex | :css), :petal? (fn tag -> bool),
  # :source (the %Source{}).

  alias PetalComponents.Check.Finding

  @enforce_keys [:id, :severity, :section, :row_keyword, :why, :scope]
  defstruct [
    :id,
    :severity,
    # "11.9" = guide section 11 row 9; "8" = section 8
    :section,
    # a word the guide row's bold title contains, pinned by a drift test
    :row_keyword,
    :why,
    :scope,
    :module,
    # printed once per run under the findings of this rule, not on every line
    :note,
    examples: [],
    exemptions: []
  ]

  @type t :: %__MODULE__{}

  @callback rule() :: t()
  @callback check(term(), map()) :: [Finding.t()]
  @callback collect(term(), map()) :: term()
  @callback finish([term()], map()) :: [Finding.t()]
  @optional_callbacks check: 2, collect: 2, finish: 2

  @doc """
  Joins class name pieces with dashes. Rule modules build every class name
  they print this way: Tailwind scans deps/petal_components for class
  names, so a literal one in a rule would add CSS to every app.
  """
  def cls(parts) when is_list(parts), do: Enum.join(parts, "-")

  @doc "A finding for this rule. `fields` sets line, column, subject, message and the fix."
  def finding(%__MODULE__{} = rule, fields) do
    struct!(Finding, [rule: rule.id, severity: rule.severity, section: rule.section] ++ fields)
  end
end
