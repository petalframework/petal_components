defmodule PetalComponents.Card do
  use Phoenix.Component

  # prop class, :string
  # prop variant, :string
  # slot default
  def card(assigns) do
    assigns = assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:variant, fn -> "basic" end)

    ~H"""
    <div class={Enum.join([
      "flex flex-wrap overflow-hidden",
      get_variant_classes(@variant),
      @class
    ], " ")}>
      <div class="flex flex-col w-full max-w-full bg-white dark:bg-gray-800">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  # prop class, :string
  # prop aspect_ratio_class, :string
  # prop src, :string
  def card_media(assigns) do
    assigns = assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:aspect_ratio_class, fn -> "aspect-video" end)
      |> assign_new(:src, fn -> nil end)

    ~H"""
    <div class={Enum.join([
      "flex-shrink-0",
      @aspect_ratio_class,
      @class
    ], " ")}>
      <%= if @src do %>
        <img src={@src} class="object-cover w-full" />
      <% else %>
        <div class="h-full bg-gray-300"></div>
      <% end %>
    </div>
    """
  end

  # prop class, :string
  # prop heading, :string
  # prop category, :string
  # slot default
  def card_content(assigns) do
    assigns = assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:inner_block, fn -> nil end)
      |> assign_new(:category, fn -> nil end)
      |> assign_new(:heading, fn -> nil end)

    ~H"""
    <div class={Enum.join([
      "p-6 gap-2", @class
    ], " ")}>
      <%= if @category do %>
        <div class="mb-3 text-sm font-medium text-primary-600">
          <%= @category %>
        </div>
      <% end %>

      <%= if @heading do %>
        <div class="mb-2 text-xl font-medium text-gray-900 dark:text-gray-300">
          <%= @heading %>
        </div>
      <% end %>

      <%= if @inner_block do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </div>
    """
  end

  defp get_variant_classes(variant) do
    case variant do
      "basic" ->
        "rounded-lg shadow-lg dark:shadow-2xl"

      "outline" ->
        "rounded-lg border border-gray-300 dark:border-gray-600"
    end
  end
end
