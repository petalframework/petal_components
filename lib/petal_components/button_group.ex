defmodule PetalComponents.ButtonGroup do
  use Phoenix.Component

  alias PetalComponents.Helpers

  @doc """
  Fuses its children into one segmented control: shared border, collapsed
  inner radii, a single outer radius. Put real petal components inside -
  `<.button>` with any color/variant/size, `<.input>`, a text segment - and
  the group does the joining.

  ## Examples

  ### Buttons (outline buttons carry their own dividers)

      <.button_group aria_label="Change view">
        <.button color="gray" variant="outline">Day</.button>
        <.button color="gray" variant="outline">Week</.button>
        <.button color="gray" variant="outline">Month</.button>
      </.button_group>

  ### Split button (solid buttons need the separator)

      <.button_group aria_label="Merge options">
        <.button>Merge pull request</.button>
        <.button_group_separator />
        <.button aria-label="More merge options">
          <.icon name="hero-chevron-down" class="w-4 h-4" />
        </.button>
      </.button_group>

  ### Mixed rail - text prefix, input and button

      <.button_group aria_label="Site address" class="w-full max-w-sm">
        <.button_group_text>https://</.button_group_text>
        <.input type="text" name="domain" value="" placeholder="example.com" />
        <.button color="gray" variant="outline">Visit</.button>
      </.button_group>

  Nest groups to split one rail into gapped clusters:

      <.button_group aria_label="Editor toolbar">
        <.button_group aria_label="History">...</.button_group>
        <.button_group aria_label="Formatting">...</.button_group>
      </.button_group>

  ## Legacy slot API

  The `:button` slot API from earlier releases still renders (it styles its
  own plain buttons). New code should compose `<.button>` children instead.

      <.button_group aria_label="My actions" size="md">
        <:button phx-click="beep">Action 1</:button>
        <:button label="Action 2" phx-click="boop" />
      </.button_group>
  """

  attr :id, :string, default: nil
  attr :aria_label, :string, required: true, doc: "the ARIA label for the button group"

  attr :orientation, :string,
    default: "horizontal",
    values: ["horizontal", "vertical"],
    doc: "stack direction - vertical fuses top-to-bottom"

  attr :class, :any, default: nil, doc: "CSS classes for the group container"

  attr :size, :string,
    default: "md",
    values: ["xs", "sm", "md", "lg", "xl"],
    doc: "legacy slot API only - composed children carry their own size"

  attr :container_class, :string,
    default: "pc-button-group",
    doc: "legacy slot API only - class to apply to the group container"

  attr :font_weight_class, :string,
    default: "font-medium",
    doc: "legacy slot API only - the font weight class to apply to all buttons"

  attr :button_bg_class, :string,
    default: nil,
    doc: "legacy slot API only - class to customize the button background colors"

  attr :button_border_class, :string,
    default: nil,
    doc: "legacy slot API only - class to customize the button border styles"

  # We mark validate_attrs false so passing phx-click etc. does not emit warnings
  slot :button, validate_attrs: false, doc: "legacy API - self-styled buttons or links"

  slot :inner_block,
    doc: "petal components to fuse - buttons, inputs, separators, text segments"

  def button_group(%{button: [_ | _]} = assigns) do
    ~H"""
    <div
      aria-label={@aria_label}
      role="group"
      id={@id || Helpers.uniq_id("button-group")}
      class={legacy_container_class(@container_class)}
    >
      <.group_button
        :for={{group_btn_assigns, idx} <- Enum.with_index(@button)}
        idx={idx}
        last_idx={length(@button) - 1}
        size={@size}
        font_weight_class={@font_weight_class}
        button_bg_class={@button_bg_class}
        button_border_class={@button_border_class}
        {group_btn_assigns}
      >
        <%= if group_btn_assigns[:inner_block] do %>
          {render_slot(group_btn_assigns)}
        <% else %>
          {group_btn_assigns.label}
        <% end %>
      </.group_button>
    </div>
    """
  end

  def button_group(assigns) do
    ~H"""
    <div
      aria-label={@aria_label}
      role="group"
      id={@id}
      class={[
        "pc-button-group",
        @orientation == "vertical" && "pc-button-group--vertical",
        @class
      ]}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # The legacy look (self-styled overlapping buttons) rides on a modifier so
  # the composition fuse rules can exclude it. Custom container classes pass
  # through untouched, exactly as before.
  defp legacy_container_class("pc-button-group"), do: "pc-button-group pc-button-group--legacy"
  defp legacy_container_class(custom), do: custom

  @doc """
  A hairline divider between fused children. Solid buttons need it (their
  borders are transparent); outline buttons and inputs don't - they carry
  their own borders. The default matches the border colour; between primary
  solids it tints from `--pc-button-solid-fg` instead, so it stays visible
  on the solid in both modes.
  """
  attr :class, :any, default: nil, doc: "CSS class"

  def button_group_separator(assigns) do
    ~H"""
    <div class={["pc-button-group__separator", @class]} aria-hidden="true"></div>
    """
  end

  @doc """
  A non-interactive segment on the rail - a prefix like `https://`, a unit,
  a keyboard hint. Styled as a muted well that fuses like any other child.
  """
  attr :class, :any, default: nil, doc: "CSS class"
  attr :rest, :global
  slot :inner_block, required: true

  def button_group_text(assigns) do
    ~H"""
    <div class={["pc-button-group__text", @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: ""
  attr :label, :string
  attr :kind, :string, default: "button", values: ["button", "link"]
  attr :disabled, :boolean, default: false
  attr :font_weight_class, :string, required: true
  attr :size, :string, required: true, values: ["xs", "sm", "md", "lg", "xl"]
  attr :idx, :integer, required: true
  attr :last_idx, :integer, required: true
  attr :button_bg_class, :string, default: nil
  attr :button_border_class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(patch navigate method download hreflang ping referrerpolicy rel target type value name form)

  slot :inner_block, doc: "The inner block of the button.", required: true

  defp group_button(%{kind: "button"} = assigns) do
    ~H"""
    <button
      disabled={@disabled}
      aria-disabled={@disabled}
      class={[@class | group_btn_class(assigns)]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  # Anchor tags can't be disabled - renders a disabled button
  defp group_button(%{kind: "link", disabled: true} = assigns) do
    assigns = update_in(assigns.rest, &Map.drop(&1, [:"phx-click"]))

    ~H"""
    <button disabled aria-disabled class={[@class | group_btn_class(assigns)]} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp group_button(%{kind: "link"} = assigns) do
    ~H"""
    <.link class={[@class | group_btn_class(assigns)]} {@rest}>
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp group_btn_class(assigns) do
    base_classes = [
      "pc-button-group__button",
      size_class(assigns.size),
      font_weight_class(assigns.font_weight_class),
      "pc-button-group__button--default-styles",
      background_class(nil),
      border_class(nil)
    ]

    custom_classes = [
      background_class(assigns.button_bg_class),
      border_class(assigns.button_border_class)
    ]

    position_class = position_class(assigns.idx, assigns.last_idx)

    # Assemble classes in order: base, custom, position
    base_classes ++ custom_classes ++ [position_class]
  end

  defp position_class(idx, last_idx) do
    cond do
      idx == 0 and idx == last_idx -> "pc-button-group__button--rounded"
      idx == 0 -> "pc-button-group__button--rounded-r-none"
      idx == last_idx -> "pc-button-group__button--rounded-l-none"
      true -> "pc-button-group__button--rounded-none"
    end
  end

  defp size_class(size), do: "pc-button-group__button--#{size}"

  defp font_weight_class("font-normal"), do: "pc-button-group__button--font-normal"
  defp font_weight_class("font-medium"), do: "pc-button-group__button--font-medium"
  defp font_weight_class("font-semibold"), do: "pc-button-group__button--font-semibold"
  defp font_weight_class("font-bold"), do: "pc-button-group__button--font-bold"
  defp font_weight_class(custom_class), do: custom_class

  defp background_class(nil), do: "pc-button-group__button--bg-default"
  defp background_class(custom_class), do: custom_class

  defp border_class(nil), do: "pc-button-group__button--border-default"
  defp border_class(custom_class), do: custom_class
end
