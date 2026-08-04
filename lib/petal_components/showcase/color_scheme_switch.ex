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

  example :labels_i18n, "Labelled, in any language",
    description:
      "labels puts text next to the icons, and the three label attrs are plain strings - hand them to gettext and the switch speaks your locale. Dropdown and segmented shown here in German." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-8">
      <.color_scheme_switch
        id="scheme-dropdown-de"
        variant="dropdown"
        labels
        light_label="Hell"
        dark_label="Dunkel"
        system_label="System"
      />
      <.color_scheme_switch
        id="scheme-segmented-de"
        variant="segmented"
        labels
        light_label="Hell"
        dark_label="Dunkel"
        system_label="System"
      />
    </div>
    """
  end

  example :custom_icons, "Your icons, same contract",
    description:
      "The icon slots replace the sun, moon and monitor with anything - an svg, an emoji, a brand glyph - sized to fill. The no-flash behaviour and persistence don't change." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-8">
      <.color_scheme_switch id="scheme-emoji-toggle">
        <:light_icon><span class="text-base leading-none">🌞</span></:light_icon>
        <:dark_icon><span class="text-base leading-none">🌚</span></:dark_icon>
      </.color_scheme_switch>
      <.color_scheme_switch id="scheme-emoji-segmented" variant="segmented">
        <:light_icon><span class="text-sm leading-none">🌞</span></:light_icon>
        <:dark_icon><span class="text-sm leading-none">🌚</span></:dark_icon>
        <:system_icon><span class="text-sm leading-none">🖥️</span></:system_icon>
      </.color_scheme_switch>
    </div>
    """
  end
end
