defmodule PetalComponents.Showcase.HoverCard do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.HoverCard,
    title: "Hover card"

  example :basic, "The profile preview",
    description:
      "Rest on the handle and the card fades in after 350ms. It stays up while you read it, and the button inside is a real button - the panel is a child of the wrapper, so hovering the card keeps it open. Tab to the link and it opens the same way, then tab again to reach Follow." do
    ~H"""
    <.hover_card>
      <:trigger>
        <a href="#" class="font-medium text-primary-600 dark:text-primary-400 hover:underline">
          @jane
        </a>
      </:trigger>
      <div class="w-64">
        <div class="flex items-start gap-3">
          <.avatar name="Jane Doe" size="md" />
          <div class="min-w-0">
            <div class="text-sm font-semibold">Jane Doe</div>
            <div class="text-xs text-gray-500 dark:text-gray-400">@jane</div>
          </div>
        </div>
        <p class="mt-3 text-sm text-gray-600 dark:text-gray-300">
          Ships Phoenix apps for a living. Maintains three things she meant to archive.
        </p>
        <div class="flex items-center gap-4 mt-3 text-xs text-gray-500 dark:text-gray-400">
          <span><span class="font-semibold text-gray-900 dark:text-white">1,204</span> followers</span>
          <span><span class="font-semibold text-gray-900 dark:text-white">183</span> following</span>
        </div>
        <.button size="sm" color="primary" class="w-full mt-3" label="Follow" />
      </div>
    </.hover_card>
    """
  end

  example :link_preview, "A link preview in prose",
    description:
      "The same component on an inline link inside a sentence. A shorter open delay suits reading flow, since the pointer is already tracking the text. The trigger still goes to the page on click, on tap, and for anyone who never hovers at all." do
    ~H"""
    <%!-- a div, not a p: the card content below is block-level, and the HTML
          parser closes an open <p> the moment it meets a <div> --%>
    <div class="max-w-md text-sm text-gray-600 dark:text-gray-300">
      We rebuilt the settings screen on
      <.hover_card placement="top" open_delay={200}>
        <:trigger>
          <a href="#" class="font-medium text-primary-600 dark:text-primary-400 hover:underline">
            LiveView streams
          </a>
        </:trigger>
        <div class="w-72">
          <div class="flex items-center gap-2">
            <.icon name="hero-document-text" class="w-4 h-4 text-gray-400" />
            <span class="text-sm font-semibold">LiveView streams</span>
          </div>
          <p class="mt-2 text-sm text-gray-600 dark:text-gray-300">
            Hold large collections on the client without keeping them in socket
            assigns. Append, prepend, delete and reset, all without a full re-render.
          </p>
          <div class="mt-2 text-xs text-gray-400">hexdocs.pm/phoenix_live_view</div>
        </div>
      </.hover_card>
      and cut the memory per connection by about half.
    </div>
    """
  end

  example :placement, "Placement and timing",
    description:
      "Twelve placements, the same geometry the popover panel uses. open_delay and close_delay are milliseconds; 0 opens on contact, which is worth trying before you decide the default is too slow." do
    ~H"""
    <%!-- justify-between and a narrower card below sm: these placements are
          static, and on a phone a right-start card hung off a mid-row trigger
          runs off the side of the pane --%>
    <div class="flex w-full sm:w-auto items-center justify-between sm:justify-center gap-6 sm:gap-10 py-8">
      <.hover_card placement="right-start" open_delay={0} close_delay={500}>
        <:trigger>
          <a href="#" class="text-sm font-medium underline">opens instantly</a>
        </:trigger>
        <div class="w-44 sm:w-56 text-sm">
          Zero open delay and a 500ms close - forgiving of a wandering pointer.
        </div>
      </.hover_card>
      <.hover_card placement="top-end" open_delay={700}>
        <:trigger>
          <a href="#" class="text-sm font-medium underline">waits 700ms</a>
        </:trigger>
        <div class="w-44 sm:w-56 text-sm">
          A 700ms open delay - deliberate rest only, nothing fires in passing.
        </div>
      </.hover_card>
    </div>
    """
  end
end
