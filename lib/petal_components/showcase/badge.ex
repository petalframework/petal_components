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

  example :status_dots, "Status dots",
    description:
      "dot puts a filled circle in front of the label, the convention every status table already uses. It takes the badge's own colour, so the row scans on colour alone from across the desk. The dot is decorative - screen readers get the word, not the circle - so keep the label carrying the meaning." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-3">
      <.badge dot color="success" variant="soft" label="Active" />
      <.badge dot color="warning" variant="soft" label="Pending" />
      <.badge dot color="danger" variant="soft" label="Failed" />
      <.badge dot color="gray" variant="outline" label="Archived" />
    </div>
    """
  end

  example :neutral_status_dots, "Neutral chips, semantic dots",
    description:
      "dot_color unpins the dot from the badge, so the chip stays quiet and the circle carries the state. Reach for the neutral chip when the label is what varies and the same few states repeat behind it; reach for the coloured chip above when the state is the message and the label is only naming it." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-3">
      <.badge color="gray" variant="outline" dot dot_color="success">Production</.badge>
      <.badge color="gray" variant="outline" dot dot_color="warning">Staging</.badge>
      <.badge color="gray" variant="outline" dot dot_color="danger">Preview</.badge>
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
