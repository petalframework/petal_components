defmodule PetalComponents.Showcase.ColorSchemeSwitch do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.ColorSchemeSwitch,
    title: "Color scheme switch"

  example :three_faces, "Three faces",
    description:
      "The same no-flash contract in three forms: toggle flips light/dark with the rotating sun and moon, dropdown offers Light / Dark / System, segmented keeps every state visible. All three need <.color_scheme_script /> once in the layout head. These are live - try them." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-8">
      <.color_scheme_switch id="scheme-toggle" />
      <.color_scheme_switch id="scheme-dropdown" variant="dropdown" labels />
      <.color_scheme_switch id="scheme-segmented" variant="segmented" />
    </div>
    """
  end
end
