defmodule PetalComponents.Showcase.InputGroup do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.InputGroup, title: "Input group"

  example :addons, "Text, icon and kbd addons",
    description:
      "The group carries the border, radius and focus ring; any petal input dropped inside sheds its own surface. Inline addons go in :leading and :trailing - plain text, icons, kbd hints. Focus anything inside and the whole group rings; disable the input and the group fades with it; inside a field wrapper with errors, the group border turns the error colour." do
    ~H"""
    <div class="w-full max-w-sm space-y-6">
      <.input_group>
        <:leading>https://</:leading>
        <.input type="text" name="igp_domain" value="" placeholder="example.com" />
      </.input_group>
      <.input_group>
        <:leading>$</:leading>
        <.input type="number" name="igp_amount" value="" placeholder="0.00" />
        <:trailing>USD</:trailing>
      </.input_group>
      <.input_group>
        <:leading><.icon name="hero-magnifying-glass" class="w-4 h-4" /></:leading>
        <.input type="search" name="igp_q" value="" placeholder="Search components..." />
        <:trailing><kbd><span>⌘</span>K</kbd></:trailing>
      </.input_group>
      <.input_group>
        <:leading>@</:leading>
        <.input type="text" name="igp_handle" value="petalframework" disabled />
      </.input_group>
    </div>
    """
  end

  example :buttons, "Buttons",
    description:
      "Buttons compose as addons too - the subscribe row and the copy-link row without a wrapper div in sight." do
    ~H"""
    <div class="w-full max-w-sm space-y-6">
      <.input_group>
        <.input type="email" name="igp_news" value="" placeholder="you@example.com" />
        <:trailing><.button size="sm">Subscribe</.button></:trailing>
      </.input_group>
      <.input_group>
        <.input type="text" name="igp_link" value="https://petal.build/join/x1y2z3" readonly />
        <:trailing>
          <.button size="sm" color="gray" variant="outline">
            <.icon name="hero-clipboard" class="w-4 h-4" /> Copy
          </.button>
        </:trailing>
      </.input_group>
    </div>
    """
  end

  example :selects, "Selects",
    description:
      "Native selects sit flush in either slot - dial-code pickers and currency suffixes with zero JS. The flags are plain emoji in the option label (Windows renders them as letter pairs, so keep the dial code in the text)." do
    ~H"""
    <div class="w-full max-w-sm space-y-6">
      <.input_group>
        <:leading>
          <select name="igp_country" class="pc-select" aria-label="Country code">
            <option>🇦🇺 +61</option>
            <option>🇺🇸 +1</option>
            <option>🇬🇧 +44</option>
          </select>
        </:leading>
        <.input type="tel" name="igp_phone" value="" placeholder="400 000 000" />
      </.input_group>
      <.input_group>
        <.input type="number" name="igp_price" value="" placeholder="0.00" />
        <:trailing>
          <select name="igp_cur" class="pc-select" aria-label="Currency">
            <option>USD</option>
            <option>EUR</option>
            <option>AUD</option>
          </select>
        </:trailing>
      </.input_group>
    </div>
    """
  end

  example :block_rows, "Block rows",
    description:
      "Full-width rows go in :block_start and :block_end - a formatting toolbar above a textarea, a character counter below. The composer pattern from one component." do
    ~H"""
    <div class="w-full max-w-sm">
      <.input_group>
        <:block_start class="gap-1">
          <.button size="xs" color="gray" variant="ghost" aria-label="Bold">
            <.icon name="hero-bold" class="w-4 h-4" />
          </.button>
          <.button size="xs" color="gray" variant="ghost" aria-label="Italic">
            <.icon name="hero-italic" class="w-4 h-4" />
          </.button>
          <.button size="xs" color="gray" variant="ghost" aria-label="Link">
            <.icon name="hero-link" class="w-4 h-4" />
          </.button>
        </:block_start>
        <.input
          type="textarea"
          name="igp_bio"
          value="Building a component library for Phoenix."
          rows="3"
        />
        <:block_end class="justify-end text-xs text-gray-400">44/280</:block_end>
      </.input_group>
    </div>
    """
  end
end
