defmodule PetalComponents.Typography do
  use Phoenix.Component

  import PetalComponents.Helpers

  @moduledoc """
  Everything related to text. Headings, paragraphs and links
  """

  # <.h1>Heading</.h1>
  # <.h1 label="Heading" />
  # <.h1 label="Heading" class="mb-10" color_class="text-blue-500" />

  # prop label, :string
  # prop class, :string
  # slot default
  def h1(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:rest, fn -> drop_heading_props(assigns) end)

    ~H"""
    <h1 class={get_heading_classes("text-4xl font-extrabold leading-10 sm:text-5xl sm:tracking-tight lg:text-6xl", assigns)} {@rest}>
      <%= if assigns[:label] do %>
        <%= @label %>
      <% else %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </h1>
    """
  end

  def h2(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:rest, fn -> drop_heading_props(assigns) end)

    ~H"""
    <h2 class={get_heading_classes("text-2xl sm:text-3xl font-extrabold leading-10", assigns)} {@rest}>
      <%= if assigns[:label] do %>
        <%= @label %>
      <% else %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </h2>
    """
  end

  def h3(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:rest, fn -> drop_heading_props(assigns) end)

    ~H"""
    <h3 class={get_heading_classes("text-xl sm:text-2xl font-bold leading-7", assigns)} {@rest}>
      <%= if assigns[:label] do %>
        <%= @label %>
      <% else %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </h3>
    """
  end

  def h4(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:rest, fn -> drop_heading_props(assigns) end)

    ~H"""
    <h4 class={get_heading_classes("text-lg font-bold leading-6", assigns)} {@rest}>
      <%= if assigns[:label] do %>
        <%= @label %>
      <% else %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </h4>
    """
  end

  def h5(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:rest, fn -> drop_heading_props(assigns) end)

    ~H"""
    <h5 class={get_heading_classes("text-lg font-medium leading-6", assigns)} {@rest}>
      <%= if assigns[:label] do %>
        <%= @label %>
      <% else %>
        <%= render_slot(@inner_block) %>
      <% end %>
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

  defp drop_heading_props(assigns) do
    assigns_to_attributes(assigns, ~w(class label color_class underline no_margin)a)
  end

  def p(assigns) do
    assigns =
      assign_new(assigns, :class, fn -> "" end)
      |> assign_new(:rest, fn ->
        assigns_to_attributes(assigns, ~w(class)a)
      end)

    ~H"""
    <p class={build_class([text_base_class(), "mb-2", @class])} {@rest}>
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  defp text_base_class(), do: "leading-5 text-gray-600 dark:text-gray-400"

  def prose(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:rest, fn ->
        assigns_to_attributes(assigns, ~w(class)a)
      end)

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
  def ul(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:rest, fn ->
        assigns_to_attributes(assigns, ~w(class)a)
      end)

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
  def ol(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_rest(~w(class)a)

    ~H"""
    <ol class={build_class([text_base_class(), "list-decimal list-inside", @class])} {@rest}>
      <%= render_slot(@inner_block) %>
    </ol>
    """
  end
end
