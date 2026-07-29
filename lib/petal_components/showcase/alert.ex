defmodule PetalComponents.Showcase.Alert do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Alert, title: "Alert"

  example :semantic_colors, "Semantic colours",
    description:
      "A prominent message tied to state. Danger and warning announce as role=\"alert\" (assertive); info, success and gray as polite status - the same kind split the toast uses. with_icon adds the matching glyph." do
    ~H"""
    <div class="w-full space-y-3">
      <.alert color="info" with_icon>A new version of this page is available.</.alert>
      <.alert color="success" with_icon>Your changes were saved.</.alert>
      <.alert color="warning" with_icon>Your trial ends in 3 days.</.alert>
      <.alert color="danger" with_icon>Payment failed. Check your card details.</.alert>
    </div>
    """
  end

  example :variants, "Variants",
    description:
      "The classic variants paint the surface in the semantic colour: light stays light in both modes, soft adapts to dark, dark is maximum emphasis, outline suits calm surfaces. callout follows the toast's principle instead - a neutral panel with colour as accent, a left bar and a solid icon (tinted surfaces take outline icons, neutral surfaces take solid ones)." do
    ~H"""
    <div class="w-full space-y-3">
      <.alert color="gray" variant="light" with_icon>
        Light, the default. Stays light even in dark mode.
      </.alert>
      <.alert color="gray" variant="soft" with_icon>Soft adapts to dark mode.</.alert>
      <.alert color="gray" variant="dark" with_icon>Dark, maximum emphasis.</.alert>
      <.alert color="gray" variant="outline" with_icon>Outline, for calm surfaces.</.alert>
      <.alert color="success" variant="callout" with_icon heading="Callout, the toast-cohesive form">
        Neutral panel, colour as accent - a left bar and a solid icon.
      </.alert>
    </div>
    """
  end

  example :actions_and_icons, "Actions and custom icons",
    description:
      "The :actions slot renders buttons or links under the message, indented with the text column; icon=\"hero-...\" swaps the kind icon for any Heroicon." do
    ~H"""
    <div class="w-full space-y-4">
      <.alert color="info" variant="callout" with_icon heading="Update available">
        Version 4.8 is ready to install.
        <:actions>
          <.button size="sm" variant="soft">View notes</.button>
          <.button size="sm" variant="ghost" color="gray">Later</.button>
        </:actions>
      </.alert>
      <.alert color="warning" variant="soft" icon="hero-lock-closed" heading="Password expiring">
        Your password expires in 3 days - a custom icon via icon="hero-lock-closed".
      </.alert>
    </div>
    """
  end

  example :dismissible, "Dismissible",
    description:
      "close_button_properties adds the cross - pass phx-click bindings in the list to tell your LiveView, or leave it empty for a purely client-side hide." do
    ~H"""
    <div class="w-full">
      <.alert color="success" with_icon heading="Invite sent" close_button_properties={[]}>
        We emailed Ana a link to join your workspace.
      </.alert>
    </div>
    """
  end
end
