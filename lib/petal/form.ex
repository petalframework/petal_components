defmodule Petal.Form do
  use Phoenix.Component
  import Phoenix.HTML.Form

  @moduledoc """
  Everything related to forms: inputs, labels etc
  """

  def plain_label(assigns) do
    ~H"""
    <label class={label_classes()}>
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  def form_label(assigns) do
    ~H"""
    <%= label @form, @field, class: label_classes(assigns) do %>
      <%= render_slot(@inner_block) %>
    <% end %>
    """
  end

  def text_input(assigns), do: input(Map.put(assigns, :type, "text"))
  def textarea(assigns), do: input(Map.put(assigns, :type, "textarea"))
  def select(assigns), do: input(Map.put(assigns, :type, "select"))
  def checkbox(assigns), do: input(Map.put(assigns, :type, "checkbox"))
  def radios(assigns), do: input(Map.put(assigns, :type, "radios"))

  defp input(assigns) do
    assigns = assign_new(assigns, :label, fn -> humanize(assigns.field) end)
    assigns = assign_new(assigns, :type, fn -> "text" end)

    assigns =
      assign_new(assigns, :input_attributes, fn ->
        Map.drop(assigns, [
          :label,
          :form,
          :field,
          :type,
          :options,
          :__changed__
        ])
        |> Map.to_list()
      end)

    build_input(assigns)
  end

  defp build_input(%{type: "text"} = assigns) do
    ~H"""
    <div class="mb-6">
      <.form_label form={@form} field={@field} type={@type}>
        <%= @label %>
      </.form_label>

      <%= text_input @form, @field, [class: text_input_classes(assigns)] ++ @input_attributes %>
    </div>
    """
  end

  defp build_input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="mb-6">
      <.form_label form={@form} field={@field} type={@type}>
        <%= @label %>
      </.form_label>

      <%= textarea @form, @field, Keyword.merge([
        class: text_input_classes(assigns),
        rows: "4"
      ], @input_attributes) %>
    </div>
    """
  end

  defp build_input(%{type: "select"} = assigns) do
    ~H"""
    <div class="mb-6">
      <.form_label form={@form} field={@field} type={@type}>
        <%= @label %>
      </.form_label>

      <%= select @form, @field, @options, [class: select_classes(assigns)] ++ @input_attributes %>
    </div>
    """
  end

  defp build_input(%{type: "checkbox"} = assigns) do
    ~H"""
    <div class="flex items-start mb-6">
      <div class="flex items-center h-5 ">
        <%= checkbox @form, @field, [class: checkbox_classes()] ++ @input_attributes %>
      </div>
      <div class="ml-3 text-sm">
        <.form_label form={@form} field={@field} type={@type}>
          <%= @label %>
        </.form_label>
      </div>
    </div>
    """
  end

  defp build_input(%{type: "radios"} = assigns) do
    ~H"""
    <.plain_label><%= @label %></.plain_label>

    <%= for {label, value} <- @options do %>
      <div class="flex items-start mb-1">
        <div class="flex items-center h-5">
          <%= radio_button @form, @field, value, [class: radio_classes()] ++ @input_attributes %>
        </div>
        <div class="ml-3 text-sm">
          <.form_label form={@form} field={@field} type={"radio"}>
            <%= label %>
          </.form_label>
        </div>
      </div>
    <% end %>
    """
  end

  defp label_classes(assigns \\ %{}) do
    type_classes =
      if Enum.member?(["checkbox", "radio"], assigns[:type]) do
        ""
      else
        "mb-2 font-medium"
      end

    "#{type_classes} text-sm text-gray-900 block dark:text-gray-200"
  end

  defp text_input_classes(assigns) do
    "#{assigns[:class] || ""} sm:text-sm block shadow-sm w-full rounded-md border-gray-300 dark:bg-gray-800 dark:text-gray-300 dark:border-gray-600 focus:border-primary-500 dark:focus:border-primary-500 focus:outline-none focus:ring-primary-500 focus:border-primary-500"
  end

  defp select_classes(assigns) do
    "#{assigns[:class] || ""} block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm rounded-md"
  end

  defp checkbox_classes() do
    "border-gray-300 rounded text-primary-700 w-5 h-5 ease-linear transition-all duration-150"
  end

  defp radio_classes() do
    "h-4 w-4 mt-0.5 cursor-pointer text-primary-600 border-gray-300 focus:ring-primary-500"
  end
end
