defmodule PetalComponents.Card do
  use Phoenix.Component

  import PetalComponents.Helpers

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:variant, :string, default: "basic", values: ["basic", "outline"])
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def card(assigns) do
    ~H"""
    <div
      {@rest}
      class={
        build_class([
          "flex flex-wrap overflow-hidden bg-white dark:bg-gray-800",
          get_variant_classes(@variant),
          @class
        ])
      }
    >
      <div class="flex flex-col w-full max-w-full">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr(:aspect_ratio_class, :string, default: "aspect-video", doc: "aspect ratio class")
  attr(:src, :string, default: nil, doc: "hosted image URL")
  attr(:class, :string, default: "", doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def card_media(assigns) do
    ~H"""
    <%= if @src do %>
      <img
        {@rest}
        src={@src}
        class={
          build_class(
            [
              "flex-shrink-0 w-full object-cover",
              @aspect_ratio_class,
              @class
            ],
            " "
          )
        }
      />
    <% else %>
      <div
        {@rest}
        class={
          build_class([
            "flex-shrink-0 w-full bg-gray-300 dark:bg-gray-700",
            @aspect_ratio_class,
            @class
          ])
        }
      >
      </div>
    <% end %>
    """
  end

  attr(:heading, :string, default: nil, doc: "creates a heading")
  attr(:category, :string, default: nil, doc: "creates a category")

  attr(:category_color_class, :string,
    default: "text-primary-600 dark:text-primary-400",
    doc: "sets a category color class"
  )

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def card_content(assigns) do
    ~H"""
    <div
      {@rest}
      class={
        build_class([
          "p-6 flex-1 font-light text-gray-500 dark:text-gray-400 text-md",
          @class
        ])
      }
    >
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

      <%= render_slot(@inner_block) || @label %>
    </div>
    """
  end

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def card_footer(assigns) do
    ~H"""
    <div {@rest} class="px-6 pb-6">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp get_variant_classes(variant) do
    case variant do
      "basic" ->
        "rounded-lg shadow-lg dark:shadow-2xl border border-gray-200 dark:border-none"

      "outline" ->
        "rounded-lg border border-gray-300 dark:border-gray-600"
    end
  end
end
