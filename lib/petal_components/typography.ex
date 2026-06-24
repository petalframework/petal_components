defmodule PetalComponents.Typography do
  use Phoenix.Component

  @moduledoc """
  Everything related to text. Headings, paragraphs and links
  """

  # <.h1>Heading</.h1>
  # <.h1 label="Heading" />
  # <.h1 label="Heading" class="mb-10" color_class="text-blue-500" />

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:label, :string, default: nil, doc: "label your heading")
  attr(:no_margin, :boolean, default: nil, doc: "removes margin from headings")
  attr(:underline, :boolean, default: false, doc: "underlines a heading")
  attr(:color_class, :any, default: nil, doc: "adds a color class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def h1(assigns) do
    ~H"""
    <h1 class={get_heading_classes("pc-h1", @class, @color_class, @underline, @no_margin)} {@rest}>
      {render_slot(@inner_block) || @label}
    </h1>
    """
  end

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:label, :string, default: nil, doc: "label your heading")
  attr(:no_margin, :boolean, default: nil, doc: "removes margin from headings")
  attr(:underline, :boolean, default: false, doc: "underlines a heading")
  attr(:color_class, :any, default: nil, doc: "adds a color class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def h2(assigns) do
    ~H"""
    <h2 class={get_heading_classes("pc-h2", @class, @color_class, @underline, @no_margin)} {@rest}>
      {render_slot(@inner_block) || @label}
    </h2>
    """
  end

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:label, :string, default: nil, doc: "label your heading")
  attr(:no_margin, :boolean, default: nil, doc: "removes margin from headings")
  attr(:underline, :boolean, default: false, doc: "underlines a heading")
  attr(:color_class, :any, default: nil, doc: "adds a color class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def h3(assigns) do
    ~H"""
    <h3 class={get_heading_classes("pc-h3", @class, @color_class, @underline, @no_margin)} {@rest}>
      {render_slot(@inner_block) || @label}
    </h3>
    """
  end

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:label, :string, default: nil, doc: "label your heading")
  attr(:no_margin, :boolean, default: nil, doc: "removes margin from headings")
  attr(:underline, :boolean, default: false, doc: "underlines a heading")
  attr(:color_class, :any, default: nil, doc: "adds a color class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def h4(assigns) do
    ~H"""
    <h4 class={get_heading_classes("pc-h4", @class, @color_class, @underline, @no_margin)} {@rest}>
      {render_slot(@inner_block) || @label}
    </h4>
    """
  end

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:label, :string, default: nil, doc: "label your heading")
  attr(:no_margin, :boolean, default: nil, doc: "removes margin from headings")
  attr(:underline, :boolean, default: false, doc: "underlines a heading")
  attr(:color_class, :any, default: nil, doc: "adds a color class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def h5(assigns) do
    ~H"""
    <h5 class={get_heading_classes("pc-h5", @class, @color_class, @underline, @no_margin)} {@rest}>
      {render_slot(@inner_block) || @label}
    </h5>
    """
  end

  defp get_heading_classes(base_classes, custom_classes, color_class, underline, no_margin) do
    [
      base_classes,
      custom_classes,
      color_class || "pc-heading--color",
      underline && "pc-heading--underline",
      !no_margin && "pc-heading--margin"
    ]
  end

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:no_margin, :boolean, default: nil, doc: "removes margin from paragraph")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def p(assigns) do
    ~H"""
    <p
      class={[
        "pc-text",
        !@no_margin && "pc-p--margin",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def prose(assigns) do
    ~H"""
    <div class={["prose dark:prose-invert", @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Usage:
      <.ul>
        <li>Item 1</li>
        <li>Item 2</li>
      </.ul>
  """

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def ul(assigns) do
    ~H"""
    <ul class={["pc-text", "list-disc list-inside", @class]} {@rest}>
      {render_slot(@inner_block)}
    </ul>
    """
  end

  @doc """
  Usage:
      <.ol>
        <li>Item 1</li>
        <li>Item 2</li>
      </.ol>
  """

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def ol(assigns) do
    ~H"""
    <ol class={["pc-text", "list-decimal list-inside", @class]} {@rest}>
      {render_slot(@inner_block)}
    </ol>
    """
  end

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  @doc """
  A larger, muted introductory paragraph for the top of a page or section.

      <.lead>Petal Components is a set of HEEx components for Phoenix.</.lead>
  """
  def lead(assigns) do
    ~H"""
    <p class={["pc-lead", @class]} {@rest}>{render_slot(@inner_block)}</p>
    """
  end

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  @doc """
  A styled blockquote with a left border.

      <.blockquote>"This library shipped our marketing site in a weekend."</.blockquote>
  """
  def blockquote(assigns) do
    ~H"""
    <blockquote class={["pc-blockquote", @class]} {@rest}>{render_slot(@inner_block)}</blockquote>
    """
  end

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  @doc """
  Inline code styling for snippets within a sentence.

      Run <.inline_code>mix deps.get</.inline_code> to install.
  """
  def inline_code(assigns) do
    ~H"""
    <code class={["pc-inline-code", @class]} {@rest}>{render_slot(@inner_block)}</code>
    """
  end

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  @doc "Muted secondary text, e.g. a caption or helper line."
  def text_muted(assigns) do
    ~H"""
    <p class={["pc-text-muted", @class]} {@rest}>{render_slot(@inner_block)}</p>
    """
  end

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  @doc "Slightly larger, emphasised body text."
  def text_large(assigns) do
    ~H"""
    <div class={["pc-text-large", @class]} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  @doc "Small, tight label text."
  def text_small(assigns) do
    ~H"""
    <small class={["pc-text-small", @class]} {@rest}>{render_slot(@inner_block)}</small>
    """
  end

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:rest, :global)

  @doc "A horizontal rule with sensible vertical spacing."
  def hr(assigns) do
    ~H"""
    <hr class={["pc-hr", @class]} {@rest} />
    """
  end
end
