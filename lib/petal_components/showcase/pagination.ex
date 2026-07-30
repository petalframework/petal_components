defmodule PetalComponents.Showcase.Pagination do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Pagination, title: "Pagination"

  example :link_mode, "Link mode",
    description:
      "path takes a template and each page renders a real link - crawlable, middle-clickable. The current page carries the outline surface (border + wash, the outline-button recipe); everything else is quiet ghost chrome. sibling_count and boundary_count control the windowing around the ellipses. One style by design." do
    ~H"""
    <.pagination path="/users/:page" total_pages={12} current_page={5} />
    """
  end

  example :event_mode, "Event mode",
    description:
      "event mode skips links and fires goto-page with phx-value-page instead - for LiveViews that page in place without URL changes." do
    ~H"""
    <.pagination event total_pages={12} current_page={5} sibling_count={1} boundary_count={1} />
    """
  end
end
