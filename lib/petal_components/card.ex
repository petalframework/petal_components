defmodule PetalComponents.Card do
  use Phoenix.Component

  import PetalComponents.Class

  # prop class, :string
  # prop variant, :string
  # slot default
  def card(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:variant, fn -> "basic" end)
      |> assign_new(:extra_assigns, fn ->
        assigns_to_attributes(assigns, ~w(
          class
          variant
        )a)
      end)

    ~H"""
    <div {@extra_assigns} class={build_class([
      "flex flex-wrap overflow-hidden",
      get_variant_classes(@variant),
      @class
    ])}>
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
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:aspect_ratio_class, fn -> "aspect-video" end)
      |> assign_new(:src, fn -> nil end)
      |> assign_new(:extra_assigns, fn ->
        assigns_to_attributes(assigns, ~w(
          class
          aspect_ratio_class
          src
        )a)
      end)

    ~H"""
    <%= if @src do %>
      <img {@extra_assigns} src={@src} class={build_class([
        "flex-shrink-0 w-full object-cover",
        @aspect_ratio_class,
        @class
      ], " ")} />
    <% else %>
      <div {@extra_assigns} class={build_class([
        "flex-shrink-0 w-full bg-gray-300 dark:bg-gray-700",
        @aspect_ratio_class,
        @class
      ])}></div>
    <% end %>
    """
  end

  # prop class, :string
  # prop heading, :string
  # prop category, :string
  # prop category_color_class, :string
  # slot default
  def card_content(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:category_color_class, fn -> "text-primary-600 dark:text-primary-400" end)
      |> assign_new(:inner_block, fn -> nil end)
      |> assign_new(:category, fn -> nil end)
      |> assign_new(:heading, fn -> nil end)
      |> assign_new(:extra_assigns, fn ->
        assigns_to_attributes(assigns, ~w(
          class
          category_color_class
          inner_block
          category
          heading
        )a)
      end)

    ~H"""
    <div {@extra_assigns} class={build_class([
      "p-6 flex-1 font-light text-gray-500 dark:text-gray-400 text-md",
      @class
    ])}>
      <%= if @category do %>
        <div class={"mb-3 text-sm font-medium #{@category_color_class}"}>
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

  def card_footer(assigns) do
    assigns =
      assigns
      |> assign_new(:extra_assigns, fn ->
        assigns_to_attributes(assigns, ~w(class)a)
      end)

    ~H"""
    <div {@extra_assigns} class="px-6 pb-6">
      <%= render_slot(@inner_block) %>
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
