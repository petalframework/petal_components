defmodule PetalComponents.Showcase.Sortable do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Sortable, title: "Sortable"

  example :basic, "Drag to reorder",
    description:
      "Grab any row and drag it. On drop the component pushes one on_reorder event with the item id and its old and new index, and your handler persists the order. Tab to a row and press Space to do the same thing without a mouse. Needs the PetalSortable hook from the bundle." do
    ~H"""
    <.sortable id="showcase-stages" on_reorder="reorder_stages">
      <:item id="discovery" label="Discovery call">Discovery call</:item>
      <:item id="demo" label="Product demo">Product demo</:item>
      <:item id="proposal" label="Proposal sent">Proposal sent</:item>
      <:item id="closed" label="Closed won">Closed won</:item>
    </.sortable>
    """
  end

  example :handle, "Handle only",
    description:
      "handle puts a grip on each row and only the grip starts a drag, so everything else in the row stays clickable. The grip is also the tab stop, with its own accessible name." do
    ~H"""
    <.sortable id="showcase-todos" on_reorder="reorder_todos" handle>
      <:item id="deploy" label="Ship the release build">
        <span>Ship the release build</span>
      </:item>
      <:item id="changelog" label="Write the changelog">
        <span>Write the changelog</span>
      </:item>
      <:item id="invoices" label="Send the invoices" disabled>
        <span>Send the invoices</span>
        <span class="ml-auto text-xs text-gray-500 dark:text-gray-400">locked</span>
      </:item>
    </.sortable>
    """
  end

  example :grid, "Grid",
    description:
      "orientation=\"grid\" wraps items into a grid and teaches the arrow keys to move in two dimensions. The column count is read from the live layout, so a responsive grid steps correctly at every breakpoint." do
    ~H"""
    <.sortable id="showcase-gallery" on_reorder="reorder_photos" orientation="grid">
      <:item id="harbour" label="Harbour at dawn">
        <span class="text-sm">Harbour at dawn</span>
      </:item>
      <:item id="ridge" label="Ridge line">
        <span class="text-sm">Ridge line</span>
      </:item>
      <:item id="salt" label="Salt flats">
        <span class="text-sm">Salt flats</span>
      </:item>
      <:item id="pines" label="Pines in fog">
        <span class="text-sm">Pines in fog</span>
      </:item>
    </.sortable>
    """
  end

  example :disabled, "Disabled",
    description:
      "disabled on the container turns the whole list inert: no drag, no keyboard lift, and the items leave the tab order. Use it while an order is saving, or when the viewer has read-only access." do
    ~H"""
    <.sortable id="showcase-locked" on_reorder="reorder_locked" handle disabled>
      <:item id="one" label="First">First</:item>
      <:item id="two" label="Second">Second</:item>
      <:item id="three" label="Third">Third</:item>
    </.sortable>
    """
  end
end
