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
          "pc-card",
          get_variant_classes(@variant),
          @class
        ])
      }
    >
      <div class="pc-card__inner">
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
              "pc-card__image",
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
            "pc-card__image-placeholder",
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
    default: "pc-card__category--primary",
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
          "pc-card__content",
          @class
        ])
      }
    >
      <%= if @category do %>
        <div class={"pc-card__category #{@category_color_class}"}>
          <%= @category %>
        </div>
      <% end %>

      <%= if @heading do %>
        <div class="pc-card__heading">
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
    <div {@rest} class={build_class(["pc-card__footer", @class])}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp get_variant_classes(variant) do
    case variant do
      "basic" ->
        "pc-card--basic"

      "outline" ->
        "pc-card--outline"
    end
  end
end
