defmodule Petal.Typography do
  use Phoenix.Component

  @moduledoc """
  Everything related to text. Headings, paragraphs and links
  """

  def h1(assigns) do
    ~H"""
    <div class={get_heading_classes("text-4xl font-extrabold text-gray-900 leading-10 dark:text-white sm:text-5xl sm:tracking-tight lg:text-6xl", assigns)}>
      <%= if assigns[:label] do %>
        <%= @label %>
      <% else %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </div>
    """
  end

  def h2(assigns) do
    ~H"""
    <div class={get_heading_classes("text-2xl sm:text-3xl font-extrabold leading-10 text-gray-900 dark:text-white", assigns)}>
      <%= if assigns[:label] do %>
        <%= @label %>
      <% else %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </div>
    """
  end

  def h3(assigns) do
    ~H"""
    <div class={get_heading_classes("text-xl sm:text-2xl font-bold leading-7 text-gray-900 dark:text-white", assigns)}>
      <%= if assigns[:label] do %>
        <%= @label %>
      <% else %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </div>
    """
  end

  def h4(assigns) do
    ~H"""
    <div class={get_heading_classes("text-lg font-bold leading-6 text-gray-900 dark:text-white", assigns)}>
      <%= if assigns[:label] do %>
        <%= @label %>
      <% else %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </div>
    """
  end

  def h5(assigns) do
    ~H"""
    <div class={get_heading_classes("text-lg font-medium leading-6 text-gray-900 dark:text-white", assigns)}>
      <%= if assigns[:label] do %>
        <%= @label %>
      <% else %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </div>
    """
  end

  defp get_heading_classes(base_classes, assigns) do
    custom_classes = assigns[:class] || ""
    underline_classes = if assigns[:underline], do: " border-b border-gray-200 pb-2", else: ""
    margin_classes = if assigns[:no_margin], do: "", else: "mb-3"

    [base_classes, custom_classes, underline_classes, margin_classes]
    |> Enum.join(" ")
  end

  def p(assigns) do
    ~H"""
    <p class={"mb-2 text-sm leading-5 text-gray-600 dark:text-gray-400 #{if assigns[:class], do: @class, else: ""}"}>
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  def link(assigns) do
    assigns = assign_new(assigns, :variant, fn -> "primary" end)

    ~H"""
    <a href={@to} class={"link link-#{@variant} #{if assigns[:class], do: @class, else: ""}"}>
      <%= render_slot(@inner_block) %>
    </a>
    """
  end
end
