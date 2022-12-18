defmodule PetalComponents.Typography do
  use Phoenix.Component

  import PetalComponents.Helpers

  @moduledoc """
  Everything related to text. Headings, paragraphs and links
  """

  # <.h1>Heading</.h1>
  # <.h1 label="Heading" />
  # <.h1 label="Heading" class="mb-10" color_class="text-blue-500" />

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:label, :string, default: nil, doc: "label your heading")
  attr(:no_margin, :boolean, default: nil, doc: "removes margin from headings")
  attr(:underline, :boolean, default: false, doc: "underlines a heading")
  attr(:color_class, :string, default: nil, doc: "adds a color class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def h1(assigns) do
    ~H"""
    <h1
      class={
        get_heading_classes(
          "text-4xl font-extrabold leading-10 sm:text-5xl sm:tracking-tight lg:text-6xl",
          assigns
        )
      }
      {@rest}
    >
      <%= render_slot(@inner_block) || @label %>
    </h1>
    """
  end

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:label, :string, default: nil, doc: "label your heading")
  attr(:no_margin, :boolean, default: nil, doc: "removes margin from headings")
  attr(:underline, :boolean, default: false, doc: "underlines a heading")
  attr(:color_class, :string, default: nil, doc: "adds a color class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def h2(assigns) do
    ~H"""
    <h2 class={get_heading_classes("text-2xl sm:text-3xl font-extrabold leading-10", assigns)} {@rest}>
      <%= render_slot(@inner_block) || @label %>
    </h2>
    """
  end

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:label, :string, default: nil, doc: "label your heading")
  attr(:no_margin, :boolean, default: nil, doc: "removes margin from headings")
  attr(:underline, :boolean, default: false, doc: "underlines a heading")
  attr(:color_class, :string, default: nil, doc: "adds a color class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def h3(assigns) do
    ~H"""
    <h3 class={get_heading_classes("text-xl sm:text-2xl font-bold leading-7", assigns)} {@rest}>
      <%= render_slot(@inner_block) || @label %>
    </h3>
    """
  end

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:label, :string, default: nil, doc: "label your heading")
  attr(:no_margin, :boolean, default: nil, doc: "removes margin from headings")
  attr(:underline, :boolean, default: false, doc: "underlines a heading")
  attr(:color_class, :string, default: nil, doc: "adds a color class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def h4(assigns) do
    ~H"""
    <h4 class={get_heading_classes("text-lg font-bold leading-6", assigns)} {@rest}>
      <%= render_slot(@inner_block) || @label %>
    </h4>
    """
  end

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:label, :string, default: nil, doc: "label your heading")
  attr(:no_margin, :boolean, default: nil, doc: "removes margin from headings")
  attr(:underline, :boolean, default: false, doc: "underlines a heading")
  attr(:color_class, :string, default: nil, doc: "adds a color class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def h5(assigns) do
    ~H"""
    <h5 class={get_heading_classes("text-lg font-medium leading-6", assigns)} {@rest}>
      <%= render_slot(@inner_block) || @label %>
    </h5>
    """
  end

  defp get_heading_classes(base_classes, assigns) do
    custom_classes = assigns[:class]
    color_classes = assigns[:color_class] || "text-gray-900 dark:text-white"
    underline_classes = if assigns[:underline], do: " border-b border-gray-200 pb-2", else: ""
    margin_classes = if assigns[:no_margin], do: "", else: "mb-3"

    build_class([base_classes, custom_classes, color_classes, underline_classes, margin_classes])
  end

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def p(assigns) do
    ~H"""
    <p class={build_class([text_base_class(), "mb-2", @class])} {@rest}>
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  defp text_base_class(), do: "leading-5 text-gray-600 dark:text-gray-400"

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def prose(assigns) do
    ~H"""
    <div class={build_class(["prose dark:prose-invert", @class])} {@rest}>
      <%= render_slot(@inner_block) %>
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

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def ul(assigns) do
    ~H"""
    <ul class={build_class([text_base_class(), "list-disc list-inside", @class])} {@rest}>
      <%= render_slot(@inner_block) %>
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

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def ol(assigns) do
    ~H"""
    <ol class={build_class([text_base_class(), "list-decimal list-inside", @class])} {@rest}>
      <%= render_slot(@inner_block) %>
    </ol>
    """
  end
end
