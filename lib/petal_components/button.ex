defmodule PetalComponents.Button do
  use Phoenix.Component

  alias PetalComponents.Loading
  alias PetalComponents.Link
  alias PetalComponents.Icon

  import PetalComponents.Helpers
  require Logger

  attr(:size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"], doc: "button sizes")

  attr(:variant, :string,
    default: "solid",
    values: ["solid", "outline", "inverted", "shadow"],
    doc: "button variant"
  )

  attr(:color, :string,
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
      "light"
    ],
    doc: "button color"
  )

  attr(:to, :string, default: nil, doc: "link path")
  attr(:loading, :boolean, default: false, doc: "indicates a loading state")
  attr(:disabled, :boolean, default: false, doc: "indicates a disabled state")
  attr(:icon, :atom, default: nil, doc: "name of a Heroicon at the front of the button")
  attr(:with_icon, :boolean, default: false, doc: "adds some icon base classes")

  attr(:link_type, :string,
    default: "button",
    values: ["a", "live_patch", "live_redirect", "button"]
  )

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:label, :string, default: nil, doc: "labels your button")

  attr(:rest, :global,
    include: ~w(method download hreflang ping referrerpolicy rel target type value name form)
  )

  slot(:inner_block, required: false)

  def button(assigns) do
    assigns =
      assigns
      |> assign(:classes, button_classes(assigns))

    ~H"""
    <Link.a to={@to} link_type={@link_type} class={@classes} disabled={@disabled} {@rest}>
      <%= if @loading do %>
        <Loading.spinner show={true} size_class={get_spinner_size_classes(@size)} />
      <% else %>
        <%= if @icon do %>
          <Icon.icon name={@icon} mini class={get_spinner_size_classes(@size)} />
        <% end %>
      <% end %>

      <%= render_slot(@inner_block) || @label %>
    </Link.a>
    """
  end

  attr(:size, :string, default: "sm", values: ["xs", "sm", "md", "lg", "xl"])

  attr(:color, :string,
    default: "gray",
    values: ["primary", "secondary", "info", "success", "warning", "danger", "gray"]
  )

  attr(:to, :string, default: nil, doc: "link path")
  attr(:loading, :boolean, default: false, doc: "indicates a loading state")
  attr(:disabled, :boolean, default: false, doc: "indicates a disabled state")
  attr(:with_icon, :boolean, default: false, doc: "adds some icon base classes")

  attr(:link_type, :string,
    default: "button",
    values: ["a", "live_patch", "live_redirect", "button"]
  )

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:tooltip, :string, default: nil, doc: "tooltip text")

  attr(:rest, :global,
    include: ~w(method download hreflang ping referrerpolicy rel target type value name form)
  )

  slot(:inner_block, required: false)

  def icon_button(assigns) do
    ~H"""
    <Link.a
      to={@to}
      link_type={@link_type}
      class={
        build_class([
          "pc-icon-button",
          get_disabled_classes(@disabled),
          get_icon_button_background_color_classes(@color),
          get_icon_button_color_classes(@color),
          get_icon_button_size_classes(@size),
          @class
        ])
      }
      disabled={@disabled}
      {@rest}
    >
      <div class={@tooltip && "relative group/pc-icon-button flex flex-col items-center"}>
        <%= if @loading do %>
          <Loading.spinner show={true} size_class={get_icon_button_spinner_size_classes(@size)} />
        <% else %>
          <%= render_slot(@inner_block) %>

          <div :if={@tooltip} role="tooltip" class="pc-icon-button__tooltip">
            <span class="pc-icon-button__tooltip__text">
              <%= @tooltip %>
            </span>
            <div class="pc-icon-button__tooltip__arrow"></div>
          </div>
        <% end %>
      </div>
    </Link.a>
    """
  end

  defp button_classes(opts) do
    opts = %{
      size: opts[:size] || "md",
      variant: opts[:variant] || "solid",
      color: opts[:color] || "primary",
      loading: opts[:loading] || false,
      disabled: opts[:disabled] || false,
      with_icon: opts[:with_icon] || opts[:icon] || false,
      user_added_classes: opts[:class] || ""
    }

    color_css = get_color_classes(opts)

    size_css = "pc-button--#{opts.size}"

    loading_css = if opts[:loading], do: "pc-button--loading", else: ""

    icon_css = if opts[:with_icon], do: "pc-button--with-icon", else: ""

    [
      color_css,
      size_css,
      loading_css,
      get_disabled_classes(opts[:disabled]),
      icon_css,
      "pc-button",
      opts.user_added_classes
    ]
    |> build_class()
  end

  defp get_color_classes(%{color: "primary", variant: variant}) do
    case variant do
      "outline" ->
        "pc-button--primary-outline"

      "inverted" ->
        "pc-button--primary-inverted"

      "shadow" ->
        "pc-button--primary-shadow"

      _ ->
        "pc-button--primary"
    end
  end

  defp get_color_classes(%{color: "secondary", variant: variant}) do
    case variant do
      "outline" ->
        "pc-button--secondary-outline"

      "inverted" ->
        "pc-button--secondary-inverted"

      "shadow" ->
        "pc-button--secondary-shadow"

      _ ->
        "pc-button--secondary"
    end
  end

  defp get_color_classes(%{color: "white", variant: variant}) do
    case variant do
      "outline" ->
        "pc-button--white-outline"

      "inverted" ->
        "pc-button--white-inverted"

      "shadow" ->
        "pc-button--white-shadow"

      _ ->
        "pc-button--white"
    end
  end

  defp get_color_classes(%{color: "pure_white", variant: variant}) do
    case variant do
      _ ->
        "pc-button--pure-white"
    end
  end

  defp get_color_classes(%{color: "info", variant: variant}) do
    case variant do
      "outline" ->
        "pc-button--info-outline"

      "inverted" ->
        "pc-button--info-inverted"

      "shadow" ->
        "pc-button--info-shadow"

      _ ->
        "pc-button--info"
    end
  end

  defp get_color_classes(%{color: "success", variant: variant}) do
    case variant do
      "outline" ->
        "pc-button--success-outline"

      "inverted" ->
        "pc-button--success-inverted"

      "shadow" ->
        "pc-button--success-shadow"

      _ ->
        "pc-button--success"
    end
  end

  defp get_color_classes(%{color: "warning", variant: variant}) do
    case variant do
      "outline" ->
        "pc-button--warning-outline"

      "inverted" ->
        "pc-button--warning-inverted"

      "shadow" ->
        "pc-button--warning-shadow"

      _ ->
        "pc-button--warning"
    end
  end

  defp get_color_classes(%{color: "danger", variant: variant}) do
    case variant do
      "outline" ->
        "pc-button--danger-outline"

      "inverted" ->
        "pc-button--danger-inverted"

      "shadow" ->
        "pc-button--danger-shadow"

      _ ->
        "pc-button--danger"
    end
  end

  defp get_color_classes(%{color: "gray", variant: variant}) do
    case variant do
      "outline" ->
        "pc-button--gray-outline"

      "inverted" ->
        "pc-button--gray-inverted"

      "shadow" ->
        "pc-button--gray-shadow"

      _ ->
        "pc-button--gray"
    end
  end

  defp get_color_classes(%{color: "light", variant: variant}) do
    case variant do
      "outline" ->
        "pc-button--light-outline"

      "inverted" ->
        "pc-button--light-inverted"

      "shadow" ->
        "pc-button--light-shadow"

      _ ->
        "pc-button--light"
    end
  end

  defp get_spinner_size_classes("xs"), do: "pc-button__spinner-icon--xs"
  defp get_spinner_size_classes("sm"), do: "pc-button__spinner-icon--sm"
  defp get_spinner_size_classes("md"), do: "pc-button__spinner-icon--md"
  defp get_spinner_size_classes("lg"), do: "pc-button__spinner-icon--lg"
  defp get_spinner_size_classes("xl"), do: "pc-button__spinner-icon--xl"

  def get_icon_button_size_classes("xs"), do: "pc-icon-button--xs"
  def get_icon_button_size_classes("sm"), do: "pc-icon-button--sm"
  def get_icon_button_size_classes("md"), do: "pc-icon-button--md"
  def get_icon_button_size_classes("lg"), do: "pc-icon-button--lg"
  def get_icon_button_size_classes("xl"), do: "pc-icon-button--xl"

  def get_icon_button_spinner_size_classes("xs"), do: "pc-icon-button-spinner--xs"
  def get_icon_button_spinner_size_classes("sm"), do: "pc-icon-button-spinner--sm"
  def get_icon_button_spinner_size_classes("md"), do: "pc-icon-button-spinner--md"
  def get_icon_button_spinner_size_classes("lg"), do: "pc-icon-button-spinner--lg"
  def get_icon_button_spinner_size_classes("xl"), do: "pc-icon-button-spinner--xl"

  defp get_icon_button_color_classes("primary"), do: "pc-icon-button--primary"

  defp get_icon_button_color_classes("secondary"),
    do: "pc-icon-button--secondary"

  defp get_icon_button_color_classes("gray"), do: "pc-icon-button--gray"
  defp get_icon_button_color_classes("info"), do: "pc-icon-button--info"
  defp get_icon_button_color_classes("success"), do: "pc-icon-button--success"
  defp get_icon_button_color_classes("warning"), do: "pc-icon-button--warning"
  defp get_icon_button_color_classes("danger"), do: "pc-icon-button--danger"

  defp get_icon_button_background_color_classes("primary"),
    do: "pc-icon-button-bg--primary"

  defp get_icon_button_background_color_classes("secondary"),
    do: "pc-icon-button-bg--secondary"

  defp get_icon_button_background_color_classes("gray"),
    do: "pc-icon-button-bg--gray"

  defp get_icon_button_background_color_classes("info"),
    do: "pc-icon-button-bg--info"

  defp get_icon_button_background_color_classes("success"),
    do: "pc-icon-button-bg--success"

  defp get_icon_button_background_color_classes("warning"),
    do: "pc-icon-button-bg--warning"

  defp get_icon_button_background_color_classes("danger"),
    do: "pc-icon-button-bg--danger"

  defp get_disabled_classes(true), do: "pc-button--disabled"
  defp get_disabled_classes(false), do: ""
end
