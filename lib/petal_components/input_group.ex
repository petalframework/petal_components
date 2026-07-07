defmodule PetalComponents.InputGroup do
  use Phoenix.Component

  @doc """
  Groups an input with leading/trailing addons - text prefixes and suffixes,
  icons, buttons or keyboard hints - on a single shared field surface.

  The group carries the border, radius and focus ring; any petal input placed
  inside is automatically stripped of its own surface, so `<.input>` works
  unchanged.

  ## Examples

      <.input_group>
        <:leading>https://</:leading>
        <.input type="text" name="domain" placeholder="example.com" />
      </.input_group>

      <.input_group>
        <:leading>$</:leading>
        <.input type="number" name="amount" placeholder="0.00" />
        <:trailing>USD</:trailing>
      </.input_group>

      <.input_group>
        <.input type="search" name="q" placeholder="Search..." />
        <:trailing>
          <.icon name="hero-magnifying-glass" class="w-4 h-4" />
        </:trailing>
      </.input_group>
  """
  attr :class, :any, default: nil, doc: "CSS classes for the group container"
  attr :rest, :global

  slot :leading, doc: "content rendered before the input (text, icon, button)"
  slot :trailing, doc: "content rendered after the input (text, icon, button)"
  slot :inner_block, required: true, doc: "the input itself"

  def input_group(assigns) do
    ~H"""
    <div class={["pc-input-group", @class]} {@rest}>
      <div :if={@leading != []} class="pc-input-group__addon pc-input-group__addon--leading">
        {render_slot(@leading)}
      </div>
      {render_slot(@inner_block)}
      <div :if={@trailing != []} class="pc-input-group__addon pc-input-group__addon--trailing">
        {render_slot(@trailing)}
      </div>
    </div>
    """
  end
end
