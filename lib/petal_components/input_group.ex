defmodule PetalComponents.InputGroup do
  use Phoenix.Component

  @doc """
  Groups an input with addons - text prefixes and suffixes, icons, buttons or
  keyboard hints - on a single shared field surface.

  The group carries the border, radius and focus ring; any petal input placed
  inside is automatically stripped of its own surface, so `<.input>` works
  unchanged.

  Inline addons sit beside the input via `:leading` and `:trailing`. Block
  addons render as full-width rows above/below via `:block_start` and
  `:block_end` - useful for toolbars and character counters, especially with
  textareas.

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
        <.input type="textarea" name="bio" />
        <:block_end class="justify-end text-xs">120/280</:block_end>
      </.input_group>
  """
  attr :class, :any, default: nil, doc: "CSS classes for the group container"
  attr :rest, :global

  slot :leading, doc: "content rendered before the input (text, icon, button, kbd)"
  slot :trailing, doc: "content rendered after the input (text, icon, button, kbd)"

  slot :block_start, doc: "full-width row above the input" do
    attr :class, :any
  end

  slot :block_end, doc: "full-width row below the input (e.g. a character counter)" do
    attr :class, :any
  end

  slot :inner_block, required: true, doc: "the input itself"

  def input_group(assigns) do
    ~H"""
    <div class={["pc-input-group", @class]} {@rest}>
      <div :for={block <- @block_start} class={["pc-input-group__block", block[:class]]}>
        {render_slot(block)}
      </div>
      <div class="pc-input-group__row">
        <div :if={@leading != []} class="pc-input-group__addon pc-input-group__addon--leading">
          {render_slot(@leading)}
        </div>
        {render_slot(@inner_block)}
        <div :if={@trailing != []} class="pc-input-group__addon pc-input-group__addon--trailing">
          {render_slot(@trailing)}
        </div>
      </div>
      <div :for={block <- @block_end} class={["pc-input-group__block", block[:class]]}>
        {render_slot(block)}
      </div>
    </div>
    """
  end
end
