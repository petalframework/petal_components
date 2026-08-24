defmodule PetalComponents.Showcase.Empty do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Empty,
    title: "Empty"

  alias PetalComponents.DataTable.State

  example :search, "No search results",
    description:
      "The most common empty state in any product: a search that found nothing. compact keeps it inside the result frame instead of taking over the page, and the secondary action is the way back out - never leave someone staring at a dead end." do
    ~H"""
    <.empty
      variant="compact"
      title="No results for “quaterly report”"
      description="Check the spelling, or drop a filter to widen the search."
    >
      <:icon><.icon name="hero-magnifying-glass" class="w-6 h-6 text-gray-400" /></:icon>
      <:actions>
        <.button size="sm" variant="outline" color="gray" label="Clear filters" />
      </:actions>
    </.empty>
    """
  end

  example :first_run, "First run, with a way in",
    description:
      "The first-run state earns a card: it is the whole page, so give it the panel surface, a primary CTA that creates the missing thing, and a trailing docs line for people who want to read before they click." do
    ~H"""
    <.empty
      variant="card"
      size="lg"
      title="No projects yet"
      description="Projects hold your environments, deploys and team access. Create one to get started."
    >
      <:icon>
        <div class="flex items-center justify-center bg-primary-50 rounded-full size-16 dark:bg-primary-500/10">
          <.icon name="hero-folder-plus" class="w-8 h-8 text-primary-600 dark:text-primary-400" />
        </div>
      </:icon>
      <:actions>
        <.button size="sm" label="Create your first project" />
        <.button size="sm" variant="outline" color="gray" label="Import from Git" />
      </:actions>
      <.a to="#" class="text-sm">Learn more about projects</.a>
    </.empty>
    """
  end

  example :variants, "Four treatments",
    description:
      "default is the bare centred column, compact tightens it for lists and tables, card wraps it in the panel surface, and dashed is the drop-target look - a visual treatment only, no drag and drop attached." do
    ~H"""
    <div class="grid w-full gap-4 sm:grid-cols-2">
      <.empty variant="default" size="sm" title="default" description="Centred, no border." />
      <.empty variant="compact" size="sm" title="compact" description="Tighter, for lists." />
      <.empty variant="card" size="sm" title="card" description="The panel surface." />
      <.empty variant="dashed" size="sm" title="dashed" description="The drop-target look." />
    </div>
    """
  end

  example :in_table, "Inside a data table",
    description:
      "The data table takes an :empty slot, so a table's empty state is the same component as a page's. compact plus sm sits inside the table frame without blowing it open." do
    ~H"""
    <% state = %State{total: 0} %>
    <.data_table id="sx-empty-dt" rows={[]} state={state} path="#">
      <:col :let={row} field={:name}>{row.name}</:col>
      <:col :let={row} field={:email}>{row.email}</:col>
      <:empty>
        <.empty
          variant="compact"
          size="sm"
          title="No orders yet"
          description="Orders show up here the moment your first customer checks out."
        />
      </:empty>
    </.data_table>
    """
  end
end
