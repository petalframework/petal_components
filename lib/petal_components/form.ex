defmodule PetalComponents.Form do
  use Phoenix.Component
  import Phoenix.HTML.Form

  @moduledoc """
  Everything related to forms: inputs, labels etc
  """

  # prop form, :any
  # prop field, :any
  # prop label, :string
  # prop type, :string
  # prop class, :css_class
  # slot default
  def form_label(assigns) do
    assigns = assigns
      |> assign_new(:classes, fn -> label_classes(assigns) end)
      |> assign_new(:form, fn -> nil end)
      |> assign_new(:field, fn -> nil end)
      |> assign_new(:type, fn -> nil end)
      |> assign_new(:inner_block, fn -> nil end)
      |> assign_new(:label, fn ->
        if assigns[:field] do
          humanize(assigns[:field])
        else
          nil
        end
      end)
      |> assign_new(:label_opts, fn ->
        Map.drop(assigns, [
          :classes,
          :form,
          :field,
          :inner_block,
          :label,
          :type,
          :__changed__
        ])
      end)

    ~H"""
    <%= if @form && @field do %>
      <%= label @form, @field, [class: @classes] ++ Map.to_list(@label_opts) do %>
        <%= if @inner_block do %>
          <%= render_slot(@inner_block) %>
        <% else %>
          <%= @label %>
        <% end %>
      <% end %>
    <% else %>
      <label class={@classes} {@label_opts}>
        <%= if @inner_block do %>
          <%= render_slot(@inner_block) %>
        <% else %>
          <%= @label %>
        <% end %>
      </label>
    <% end %>
    """
  end

  @doc "Use this when you want to include the label and some margin. Supported types: textinput, textarea, select"
  def form_field(assigns) do
    assigns = assigns
    |> assign_new(:input_opts, fn ->
      Map.drop(assigns, [:form, :field, :label, :type])
    end)
    |> assign_new(:label, fn ->
      if assigns[:field] do
        humanize(assigns[:field])
      else
        nil
      end
    end)

    ~H"""
    <div class="mb-6">
      <.form_label form={@form} field={@field} label={@label} />
      <%= case @type do %>
        <% "text_input" -> %>
          <.text_input form={@form} field={@field} {@input_opts} />
        <% "textarea" -> %>
          <.textarea form={@form} field={@field} {@input_opts} />
        <% "select" -> %>
          <.select form={@form} field={@field} {@input_opts} />
      <% end %>
    </div>
    """
  end

  def text_input(assigns) do
    assigns = assign_defaults(assigns, text_input_classes())

    ~H"""
    <%= text_input @form, @field, [class: @classes] ++ @input_attributes %>
    """
  end

  def textarea(assigns) do
    assigns = assign_defaults(assigns, text_input_classes())

    ~H"""
    <%= textarea @form, @field, [class: @classes] ++ Keyword.merge([rows: "4"], @input_attributes) %>
    """
  end

  def select(assigns) do
    assigns = assign_defaults(assigns, select_classes())

    ~H"""
    <%= select @form, @field, @options, [class: @classes] ++ @input_attributes %>
    """
  end

  def checkbox(assigns) do
    assigns = assign_defaults(assigns, checkbox_classes())

    ~H"""
    <label class="inline-flex items-center block gap-3 mb-6 text-sm text-gray-900 dark:text-gray-200">
      <%= checkbox @form, @field, [class: @classes] ++ @input_attributes %>

      <div>
        <%= @label %>
      </div>
    </label>
    """
  end

  def radios(assigns) do
    assigns = assign_defaults(assigns, radio_classes())

    ~H"""
    <div class="flex flex-col gap-1">
      <%= for {label, value} <- @options do %>
        <label class="inline-flex items-center block gap-3 text-sm text-gray-900 dark:text-gray-200">
          <%= radio_button @form, @field, value, [class: @classes] ++ @input_attributes %>

          <div>
            <%= label %>
          </div>
        </label>
      <% end %>
    </div>
    """
  end

  defp assign_defaults(assigns, base_classes) do
    assigns
    |> assign_new(:type, fn -> "text" end)
    |> assign_new(:input_attributes, fn ->
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
    |> assign_new(:classes, fn ->
      [
        base_classes,
        assigns[:class] || ""
      ]
      |> Enum.join(" ")
    end)
  end

  defp label_classes(assigns) do
    type_classes =
      if Enum.member?(["checkbox", "radio"], assigns[:type]) do
        ""
      else
        "mb-2 font-medium"
      end

    "#{type_classes} text-sm text-gray-900 block dark:text-gray-200"
  end

  defp text_input_classes() do
    "sm:text-sm block shadow-sm w-full rounded-md border-gray-300 dark:bg-gray-800 dark:text-gray-300 dark:border-gray-600 dark:focus:border-primary-500 focus:outline-none focus:ring-primary-500 focus:border-primary-500"
  end

  defp select_classes() do
    "block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm rounded-md"
  end

  defp checkbox_classes() do
    "border-gray-300 rounded text-primary-700 w-5 h-5 ease-linear transition-all duration-150"
  end

  defp radio_classes() do
    "h-4 w-4 cursor-pointer text-primary-600 border-gray-300 focus:ring-primary-500"
  end
end
