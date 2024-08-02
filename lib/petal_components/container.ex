defmodule PetalComponents.Container do
  use Phoenix.Component

  attr(:max_width, :string,
    default: "lg",
    values: ["sm", "md", "lg", "xl", "full"],
    doc: "sets container max-width"
  )

  attr(:class, :any, default: nil, doc: "CSS class for container")
  attr(:no_padding_on_mobile, :boolean, default: false, doc: "specify for padding on mobile")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def container(assigns) do
    ~H"""
    <div
      {@rest}
      class={[
        "pc-container pc-container--#{@max_width}",
        !@no_padding_on_mobile && "pc-container--mobile-padded",
        @class
      ]}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
