defmodule PetalComponents.Card do
  use Phoenix.Component
  import PetalComponents.Avatar
  import PetalComponents.Typography

  attr(:class, :any, default: nil, doc: "CSS class")

  attr(:variant, :string,
    default: "basic",
    values: ["basic", "outline", "muted"],
    doc:
      "basic is THE card (bordered panel); muted is the tinted well for de-emphasised content. outline is a legacy alias of basic (identical look) slated for removal in a future major"
  )

  attr(:rest, :global)
  slot(:inner_block, required: false)

  def card(assigns) do
    ~H"""
    <div {@rest} class={["pc-card", "pc-card--#{@variant}", @class]}>
      <div class="pc-card__inner">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr(:aspect_ratio_class, :any, default: "aspect-video", doc: "aspect ratio class")
  attr(:src, :string, default: nil, doc: "hosted image URL")
  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def card_media(assigns) do
    ~H"""
    <%= if @src do %>
      <img {@rest} src={@src} class={["pc-card__image", @aspect_ratio_class, @class]} />
    <% else %>
      <div {@rest} class={["pc-card__image-placeholder", @aspect_ratio_class, @class]}></div>
    <% end %>
    """
  end

  attr(:title, :string, default: nil, doc: "the card title")
  attr(:description, :string, default: nil, doc: "a muted line under the title")
  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:rest, :global)

  slot(:action, required: false, doc: "top-right header content - a button, link or menu")
  slot(:inner_block, required: false)

  @doc """
  The card header: title + description on the left, an optional action on
  the right.

      <.card_header title="Login to your account" description="Enter your email below">
        <:action><.button color="gray" variant="ghost" size="sm">Sign up</.button></:action>
      </.card_header>
  """
  def card_header(assigns) do
    ~H"""
    <div class={["pc-card__header", @class]} {@rest}>
      <div class="pc-card__header-titles">
        <div :if={@title} class="pc-card__title">{@title}</div>
        <div :if={@description} class="pc-card__description">{@description}</div>
        {render_slot(@inner_block)}
      </div>
      <div :if={@action != []} class="pc-card__header-action">
        {render_slot(@action)}
      </div>
    </div>
    """
  end

  attr(:heading, :string, default: nil, doc: "creates a heading")
  attr(:category, :string, default: nil, doc: "creates a category")

  attr(:category_color_class, :any,
    default: "pc-card__category--primary",
    doc: "sets a category color class"
  )

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def card_content(assigns) do
    ~H"""
    <div {@rest} class={["pc-card__content", @class]}>
      <div :if={@category} class={["pc-card__category", @category_color_class]}>
        {@category}
      </div>

      <div :if={@heading} class="pc-card__heading">
        {@heading}
      </div>

      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def card_footer(assigns) do
    ~H"""
    <div {@rest} class={["pc-card__footer", @class]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:name, :string, required: true, doc: "The reviewer's name")
  attr(:username, :string, required: true, doc: "The reviewer's username")
  attr(:img, :string, required: true, doc: "URL of the reviewer's avatar")
  attr(:body, :string, required: true, doc: "The review text content")
  attr(:class, :string, default: "", doc: "Additional classes")
  attr(:rest, :global)

  def review_card(assigns) do
    ~H"""
    <figure class={["pc-review-card", @class]} {@rest}>
      <div class="pc-review-header">
        <.avatar src={@img} alt={@name} size="md" />
        <div class="pc-review-meta">
          <figcaption>
            <.p no_margin class="text-sm pc-review-name">{@name}</.p>
          </figcaption>
          <p class="pc-review-username">{@username}</p>
        </div>
      </div>
      <blockquote class="pc-review-body">
        <.p class="text-sm" no_margin>{@body}</.p>
      </blockquote>
    </figure>
    """
  end
end
