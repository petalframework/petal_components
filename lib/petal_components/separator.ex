defmodule PetalComponents.Separator do
  @moduledoc """
  A hairline divider for app UI, with an optional inline label.

      <.separator />
      <.separator label="OR" />
      <.separator label="Today" label_position="start" />
      <.separator orientation="vertical" class="h-6" />
      <.separator decorative={false} />

  ## Spacing

  A separator carries no vertical margin. App layouts already control their own
  rhythm with gap and space utilities, and a component that quietly adds `my-8`
  is a component you spend the afternoon overriding. Add the spacing you want at
  the call site.

  ## Vertical

  A vertical separator is a `w-px` rule that stretches to its flex parent
  (`self-stretch`). If the parent does not give it a height, set one yourself:
  `class="h-6"`. Labelled vertical separators are deliberately not supported.

  ## Decorative vs semantic

  `decorative` defaults to `true`, matching Radix: most dividers are paint, and
  announcing them is noise. The element gets `aria-hidden="true"` and no role.

  Set `decorative={false}` when the rule genuinely divides content that assistive
  tech should hear as separate, e.g. between groups in a menu. That renders
  `role="separator"`, plus `aria-orientation="vertical"` when vertical
  (horizontal is the ARIA default, so it is left off).

  ## Related

  `PetalComponents.Typography.hr/1` is the prose rule. It renders a real `<hr>`
  with `my-8` for article and long-form content, and it is not going anywhere.
  Reach for `<.separator>` in application chrome, where you want the hairline
  without the opinion about spacing, plus labels, vertical mode and the ARIA
  switch.
  """
  use Phoenix.Component

  attr :class, :any, default: nil, doc: "CSS class"

  attr :orientation, :string,
    default: "horizontal",
    values: ["horizontal", "vertical"],
    doc: "vertical is a w-px rule that stretches to its flex parent"

  attr :label, :string,
    default: nil,
    doc: ~s|optional inline label, e.g. "OR" or a date. Horizontal only|

  attr :label_position, :string,
    default: "center",
    values: ["start", "center", "end"],
    doc: "where the label sits along the rule"

  attr :decorative, :boolean,
    default: true,
    doc:
      ~s|true renders aria-hidden (purely visual); false renders role="separator" with aria-orientation for semantically meaningful dividers|

  attr :rest, :global, doc: "any extra HTML attributes for the rendered div"

  slot :inner_block, required: false, doc: "rich label content; wins over the label attr"

  @doc """
  A hairline divider, optionally labelled.

      <.separator />
      <.separator label="OR" />
  """
  def separator(assigns) do
    assigns = assign(assigns, :labelled?, labelled?(assigns))

    ~H"""
    <%!-- The labelled branch's ARIA differs from the bare rule's: the label
          is REAL content, so a decorative labelled separator must not hide
          the whole container (the flank lines are already hidden) - and a
          semantic one carries aria-label because role="separator" has
          presentational children, swallowing the inner text. --%>
    <div
      :if={@labelled?}
      class={[
        "pc-separator pc-separator--horizontal pc-separator--labelled",
        "pc-separator--label-#{@label_position}",
        @class
      ]}
      {labelled_aria(@decorative, @label)}
      {@rest}
    >
      <span class="pc-separator__line" aria-hidden="true"></span>
      <span class="pc-separator__label">
        {if @inner_block == [], do: @label, else: render_slot(@inner_block)}
      </span>
      <span class="pc-separator__line" aria-hidden="true"></span>
    </div>
    <div
      :if={!@labelled?}
      class={["pc-separator", "pc-separator--#{@orientation}", @class]}
      {aria(@decorative, @orientation)}
      {@rest}
    >
    </div>
    """
  end

  # A label only makes sense horizontally; a vertical separator ignores it
  # rather than rendering a broken row.
  defp labelled?(%{orientation: "vertical"}), do: false
  defp labelled?(%{inner_block: [_ | _]}), do: true
  defp labelled?(%{label: label}) when is_binary(label) and label != "", do: true
  defp labelled?(_), do: false

  defp aria(true, _orientation), do: %{"aria-hidden": "true"}
  defp aria(false, "vertical"), do: %{role: "separator", "aria-orientation": "vertical"}
  defp aria(false, _horizontal), do: %{role: "separator"}

  # Decorative + labelled: no aria at all - the lines are hidden, the label
  # reads as plain text. Semantic + labelled: the aria-label carries the text
  # role="separator" swallows; rich slot content should pass the label attr
  # alongside for this reason.
  defp labelled_aria(true, _label), do: %{}
  defp labelled_aria(false, label), do: %{role: "separator", "aria-label": label}
end
