defmodule PetalComponents.Marquee do
  use Phoenix.Component

  attr(:pause_on_hover, :boolean,
    default: false,
    doc: "Pause the marquee when the user hovers over the cards"
  )

  attr(:repeat, :integer, default: 4, doc: "Number of times to repeat the content")
  attr(:vertical, :boolean, default: false, doc: "Display the marquee vertically")
  attr(:reverse, :boolean, default: false, doc: "Reverse the direction of the marquee")
  attr(:duration, :string, default: "30s", doc: "Animation duration")
  attr(:gap, :string, default: "1rem", doc: "Gap between items")
  attr(:overlay_gradient, :boolean, default: true, doc: "Add gradient overlay at edges")

  attr(:max_width, :string,
    default: "none",
    values: ["sm", "md", "lg", "xl", "2xl", "none"],
    doc: "Maximum width of the marquee container"
  )

  attr(:max_height, :string,
    default: "none",
    values: ["sm", "md", "lg", "xl", "2xl", "none"],
    doc: "Maximum height of the marquee container"
  )

  attr(:class, :string, default: "", doc: "CSS class for parent div")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def marquee(assigns) do
    ~H"""
    <div class="relative overflow-hidden">
      <div
        :if={@repeat > 0}
        class={[
          "pc-marquee-container group",
          @vertical && "pc-vertical",
          @class
        ]}
        max-width={@max_width}
        max-height={@max_height}
        style={"--duration: #{@duration}; --gap: #{@gap};"}
        {@rest}
      >
        <%= for _ <- 0..(@repeat - 1) do %>
          <div
            class={[
              "pc-marquee-content",
              @vertical && "pc-marquee-vertical",
              !@vertical && "pc-marquee-horizontal",
              @pause_on_hover && "pc-pause-on-hover"
            ]}
            style={@reverse && "animation-direction: reverse;"}
          >
            {render_slot(@inner_block)}
          </div>
        <% end %>
      </div>

      <%= if @overlay_gradient do %>
        <%= if @vertical do %>
          <div class="pc-gradient-overlay-top"></div>
          <div class="pc-gradient-overlay-bottom"></div>
        <% else %>
          <div class="pc-gradient-overlay-left"></div>
          <div class="pc-gradient-overlay-right"></div>
        <% end %>
      <% end %>
    </div>
    """
  end
end
