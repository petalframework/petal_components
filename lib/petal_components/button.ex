defmodule PetalComponents.Button do
  use Phoenix.Component

  alias PetalComponents.Loading
  alias PetalComponents.Link
  import PetalComponents.Icon

  attr :size, :string,
    default: "md",
    values: ["xs", "sm", "md", "lg", "xl", "icon"],
    doc: "button sizes; icon renders a square, md-height icon button (pair with an aria-label)"

  attr :radius, :string,
    default: nil,
    values: [nil, "none", "sm", "md", "lg", "xl", "full"],
    doc: "button border radius; when unset the --pc-radius theme token applies"

  attr :variant, :string,
    default: "solid",
    values: ["solid", "soft", "light", "outline", "inverted", "shadow", "ghost"],
    doc:
      "button variant. solid/soft/light/outline/ghost are the supported fill styles (soft adapts its tint to dark mode; light stays light in both modes). inverted and shadow are legacy, slated for removal in a future major - prefer outline, and compose effects (border_beam / shine_border) for flourish"

  attr :color, :string,
    default: "primary",
    values: [
      "primary",
      "secondary",
      "info",
      "success",
      "warning",
      "danger",
      "gray",
      "pure_white",
      "white",
      "light",
      "dark"
    ],
    doc: "button color"

  attr :to, :string, default: nil, doc: "link path"
  attr :loading, :boolean, default: false, doc: "indicates a loading state"
  attr :disabled, :boolean, default: false, doc: "indicates a disabled state"
  attr :icon, :any, default: nil, doc: "name of a Heroicon at the front of the button"
  attr :with_icon, :boolean, default: false, doc: "adds some icon base classes"

  attr :link_type, :string,
    default: "button",
    values: ["a", "live_patch", "live_redirect", "button"]

  attr :class, :any, default: nil, doc: "CSS class"
  attr :label, :string, default: nil, doc: "labels your button"

  attr :rest, :global,
    include: ~w(method download hreflang ping referrerpolicy rel target type value name form)

  slot :inner_block, required: false

  def button(assigns) do
    assigns =
      assigns
      |> assign(:classes, button_classes(assigns))

    ~H"""
    <Link.a to={@to} link_type={@link_type} class={@classes} disabled={@disabled} {@rest}>
      <%= if @loading do %>
        <Loading.spinner show={true} size_class={"pc-button__spinner-icon--#{@size}"} />
      <% else %>
        <%= if @icon do %>
          <.icon name={@icon} class={"pc-button__spinner-icon--#{@size}"} />
        <% end %>
      <% end %>

      {render_slot(@inner_block) || @label}
    </Link.a>
    """
  end

  attr :size, :string, default: "sm", values: ["xs", "sm", "md", "lg", "xl"]

  attr :color, :string,
    default: "gray",
    values: [
      "primary",
      "secondary",
      "info",
      "success",
      "warning",
      "danger",
      "gray"
    ]

  attr :radius, :string,
    default: "full",
    values: ["none", "sm", "md", "lg", "xl", "full"],
    doc: "button radius"

  attr :to, :string, default: nil, doc: "link path"
  attr :loading, :boolean, default: false, doc: "indicates a loading state"
  attr :disabled, :boolean, default: false, doc: "indicates a disabled state"
  attr :with_icon, :boolean, default: false, doc: "adds some icon base classes"

  attr :link_type, :string,
    default: "button",
    values: ["a", "live_patch", "live_redirect", "button"]

  attr :class, :any, default: nil, doc: "CSS class"
  attr :tooltip, :string, default: nil, doc: "tooltip text"

  attr :rest, :global,
    include: ~w(method download hreflang ping referrerpolicy rel target type value name form)

  slot :inner_block, required: false

  def icon_button(assigns) do
    ~H"""
    <Link.a
      to={@to}
      link_type={@link_type}
      class={[
        "pc-icon-button",
        "pc-icon-button--radius-#{@radius}",
        @disabled && "pc-button--disabled",
        "pc-icon-button-bg--#{@color}",
        "pc-icon-button--#{@color}",
        "pc-icon-button--#{@size}",
        @class
      ]}
      disabled={@disabled}
      {@rest}
    >
      <span class={[
        "pc-icon-button__inner",
        @tooltip && "group/pc-icon-button pc-icon-button__inner--tooltip"
      ]}>
        <%= if @loading do %>
          <Loading.spinner show={true} size_class={"pc-icon-button-spinner--#{@size}"} />
        <% else %>
          {render_slot(@inner_block)}

          <div :if={@tooltip} role="tooltip" class="pc-icon-button__tooltip">
            <span class="pc-icon-button__tooltip__text">
              {@tooltip}
            </span>
            <div class="pc-icon-button__tooltip__arrow"></div>
          </div>
        <% end %>
      </span>
    </Link.a>
    """
  end

  defp button_classes(assigns) do
    size = assigns[:size] || "md"
    radius = assigns[:radius]
    variant = assigns[:variant] || "solid"
    color = assigns[:color] || "primary"
    loading = assigns[:loading] || false
    disabled = assigns[:disabled] || false
    with_icon = assigns[:with_icon] || assigns[:icon] || false
    user_classes = assigns[:class] || ""

    color_class = "pc-button--#{String.replace(color, "_", "-")}"
    variant_suffix = if variant == "solid", do: "", else: "-#{variant}"

    [
      "pc-button",
      "#{color_class}#{variant_suffix}",
      "pc-button--#{size}",
      radius && "pc-button--radius-#{radius}",
      user_classes,
      loading && "pc-button--loading",
      disabled && "pc-button--disabled",
      with_icon && "pc-button--with-icon"
    ]
  end
end
