defmodule PetalComponents.Showcase.Badge do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Badge, title: "Badge"

  example :variants, "Variants",
    description:
      "A small label for counts, statuses and categories. light stays light in both colour schemes, soft adapts to dark mode, dark is maximum emphasis, outline stays quiet on any surface." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-3">
      <.badge label="Light" />
      <.badge variant="soft" label="Soft" />
      <.badge variant="dark" label="Dark" />
      <.badge variant="outline" label="Outline" />
    </div>
    """
  end

  example :semantic_colors, "Semantic colours",
    description:
      "The full colour range in the soft variant - primary and secondary follow your theme dials, the semantic four carry meaning, gray labels without shouting." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-3">
      <.badge
        :for={c <- ~w(primary secondary info success warning danger gray)}
        color={c}
        variant="soft"
        label={c}
      />
    </div>
    """
  end

  example :sizes, "Sizes",
    description:
      "Five sizes on the shared scale; with_icon tightens the padding for a leading glyph." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-3">
      <.badge :for={z <- ~w(xs sm md lg xl)} size={z} label={z} />
    </div>
    """
  end
end
