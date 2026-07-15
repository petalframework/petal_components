defmodule PetalComponents.Showcase.Accordion do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Accordion, title: "Accordion"

  example :basic_accordion, "Basic",
    description: "Collapsible sections with proper button semantics and keyboard toggling." do
    ~H"""
    <.accordion class="w-full max-w-xl mx-auto">
      <:item heading="Is it accessible?">
        Yes - proper button semantics, aria-expanded, and keyboard toggling out of the box.
      </:item>
      <:item heading="Can several be open at once?">
        Not by default. Pass the multiple attr to allow more than one open section.
      </:item>
      <:item heading="Does it follow the theme?">
        Borders, radius and text tiers all come from the design tokens.
      </:item>
    </.accordion>
    """
  end

  example :bordered_accordion, "Bordered",
    description: "The bordered variant wraps each row in the panel surface." do
    ~H"""
    <.accordion variant="bordered" class="w-full max-w-xl mx-auto">
      <:item heading="What's included?">
        Auth, billing, orgs, admin and an AI-ready component library.
      </:item>
      <:item heading="Is it a subscription?">
        One purchase, unlimited projects. No recurring fee.
      </:item>
    </.accordion>
    """
  end

  example :ghost_accordion, "Ghost",
    description: "The minimal variant - hairline dividers, no surrounding box." do
    ~H"""
    <.accordion variant="ghost" class="w-full max-w-xl mx-auto">
      <:item heading="How do I install it?">
        Add the Hex dep, run mix deps.get, and point Tailwind at the source.
      </:item>
      <:item heading="Does it need JavaScript?">
        Interactivity is LiveView.JS only - no Alpine as of v4.
      </:item>
    </.accordion>
    """
  end

  example :dynamic_accordion, "Dynamic",
    description:
      "Data-driven - pass a list of entries and render each with the item slot. Handy for FAQ or CMS content." do
    ~H"""
    <.accordion
      class="w-full max-w-xl mx-auto"
      entries={[
        %{heading: "Where do the entries come from?", content: "A plain list of maps you pass in."},
        %{
          heading: "How is each row rendered?",
          content: "The item slot receives the entry via :let."
        },
        %{heading: "Can the content be anything?", content: "Yes - it's a slot, so any markup works."}
      ]}
    >
      <:item :let={entry}>{entry.content}</:item>
    </.accordion>
    """
  end
end
