defmodule PetalComponents.Showcase.ToggleGroup do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.ToggleGroup,
    title: "Toggle group"

  example :single, "Single select",
    description:
      "One rail, one pressed option. Pass the current value and an on_change event; in your app you assign the value the event hands back and the pressed chip follows. This preview renders a fixed value - registry examples are static by design. Where button_group fires actions, toggle_group holds a selection." do
    ~H"""
    <.toggle_group aria_label="Density" value="cozy" on_change="set_density">
      <:item value="compact">Compact</:item>
      <:item value="cozy">Cozy</:item>
      <:item value="comfortable">Comfortable</:item>
    </.toggle_group>
    """
  end

  example :multiple, "Multiple select",
    description:
      "With multiple, value is a list and every member renders pressed. The server owns the toggle logic: add the option if it is missing, drop it if it is there. Icon-only items carry an aria-label so the option still reads out." do
    ~H"""
    <.toggle_group
      multiple
      aria_label="Formatting"
      value={["bold", "italic"]}
      on_change="toggle_format"
    >
      <:item value="bold" aria-label="Bold"><.icon name="hero-bold" /></:item>
      <:item value="italic" aria-label="Italic"><.icon name="hero-italic" /></:item>
      <:item value="underline" aria-label="Underline"><.icon name="hero-underline" /></:item>
    </.toggle_group>
    """
  end

  example :icons_with_labels, "Icons with labels",
    description:
      "Items take any content: icon plus text reads fastest for view switchers. The pressed chip and the wash come from the rail, so mixed content stays aligned without extra classes." do
    ~H"""
    <.toggle_group aria_label="View" value="grid" on_change="set_view">
      <:item value="list"><.icon name="hero-list-bullet" /> List</:item>
      <:item value="grid"><.icon name="hero-squares-2x2" /> Grid</:item>
      <:item value="board"><.icon name="hero-view-columns" /> Board</:item>
    </.toggle_group>
    """
  end

  example :sizes, "Sizes",
    description:
      "Three sizes share the same radii math as the rest of the rail family, so a sm toggle group next to a scheme switch reads as kin. Disabled works per item or for the whole rail." do
    ~H"""
    <div class="flex flex-col items-start gap-4">
      <.toggle_group aria_label="Page size small" size="sm" value="10" on_change="set_page_size">
        <:item value="6">6</:item>
        <:item value="10">10</:item>
        <:item value="14">14</:item>
        <:item value="full" disabled>Full</:item>
      </.toggle_group>
      <.toggle_group aria_label="Page size medium" size="md" value="10" on_change="set_page_size">
        <:item value="6">6</:item>
        <:item value="10">10</:item>
        <:item value="14">14</:item>
      </.toggle_group>
      <.toggle_group aria_label="Page size large" size="lg" value="10" on_change="set_page_size">
        <:item value="6">6</:item>
        <:item value="10">10</:item>
        <:item value="14">14</:item>
      </.toggle_group>
    </div>
    """
  end
end
