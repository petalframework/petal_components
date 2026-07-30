defmodule PetalComponents.Showcase.Breadcrumbs do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Breadcrumbs, title: "Breadcrumbs"

  example :basic, "Links from a plain list",
    description:
      "links take label and/or icon (the first crumb here is a home icon), to, and link_type (a / live_patch / live_redirect / button). The last crumb renders as the current page - strong text plus aria-current - and the nav carries an aria_label. separator=\"slash\" swaps the chevrons." do
    ~H"""
    <.breadcrumbs links={[
      %{icon: "hero-home", to: "#", link_type: "button"},
      %{label: "Projects", to: "#", link_type: "button"},
      %{label: "petal_components", to: "#", link_type: "button"}
    ]} />
    """
  end
end
