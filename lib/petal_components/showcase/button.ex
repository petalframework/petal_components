defmodule PetalComponents.Showcase.Button do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Button,
    title: "Button",
    functions: [:button, :icon_button]

  example :variants, "Variants",
    description:
      "Five fill styles, one per action weight: solid carries the primary action, soft and light tint the surface (soft adapts its tint to dark mode, light stays light in both), outline and ghost recede to chrome. inverted and shadow still render but are legacy - prefer outline." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-3">
      <.button>Solid</.button>
      <.button variant="soft">Soft</.button>
      <.button variant="light">Light</.button>
      <.button variant="outline">Outline</.button>
      <.button variant="ghost">Ghost</.button>
    </div>
    """
  end

  example :semantic_colors, "Semantic colours",
    description:
      "For actions that carry meaning: info, success, warning and danger tint every variant - solid shown here; soften the signal with variant=\"soft\" or \"outline\". primary, secondary and gray cover everything else." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-3">
      <.button color="info">Info</.button>
      <.button color="success">Success</.button>
      <.button color="warning">Warning</.button>
      <.button color="danger">Danger</.button>
    </div>
    """
  end

  example :sizes, "Sizes",
    description:
      "Five sizes, xs to xl, md the default. Padding, type and icon scale together, so a size change never needs a class override." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-3">
      <.button size="xs">Extra small</.button>
      <.button size="sm">Small</.button>
      <.button size="md">Medium</.button>
      <.button size="lg">Large</.button>
      <.button size="xl">Extra large</.button>
    </div>
    """
  end

  example :states, "States",
    description:
      "icon renders a Heroicon beside the label; icon_placement=\"right\" moves it after, for arrows and continues. loading swaps the icon's side for a spinner so the button never reflows mid-submit, and disabled mutes the button and blocks the click." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-3">
      <.button>Default</.button>
      <.button icon="hero-rocket-launch">With icon</.button>
      <.button icon="hero-arrow-right" icon_placement="right">Continue</.button>
      <.button loading>Loading</.button>
      <.button disabled>Disabled</.button>
    </div>
    """
  end

  example :icon_button, "Icon button",
    description:
      "size=\"icon\" renders a square, md-height button for a lone glyph - toolbars, composers, close affordances. A glyph is not a name, so pair it with an aria-label. Every variant and colour applies." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-3">
      <.button size="icon" aria-label="Submit">
        <.icon name="hero-arrow-up" class="w-5 h-5" />
      </.button>
      <.button variant="outline" size="icon" aria-label="Add">
        <.icon name="hero-plus" class="w-5 h-5" />
      </.button>
      <.button variant="ghost" size="icon" aria-label="Settings">
        <.icon name="hero-cog-6-tooth" class="w-5 h-5" />
      </.button>
    </div>
    """
  end
end
