defmodule PetalComponents.Showcase.Command do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Command,
    title: "Command",
    functions: [:command, :command_dialog]

  example :inline_palette, "Inline palette",
    description:
      "A palette panel you drop into a page, sidebar or picker. Type to filter; arrow keys move, Enter runs." do
    ~H"""
    <div class="w-full max-w-md mx-auto">
      <.command
        id="showcase-command"
        loop
        class="border border-gray-200 shadow-xs dark:border-white/15"
      >
        <.command_input placeholder="Type a command or search..." />
        <.command_list>
          <.command_empty>No results found.</.command_empty>
          <.command_group heading="Suggestions">
            <.command_item keywords={["date", "schedule"]}>
              <.icon name="hero-calendar" /> Calendar
            </.command_item>
            <.command_item keywords={["smile"]}>
              <.icon name="hero-face-smile" /> Search emoji
            </.command_item>
            <.command_item disabled>
              <.icon name="hero-calculator" /> Calculator
            </.command_item>
          </.command_group>
          <.command_separator />
          <.command_group heading="Settings">
            <.command_item keywords={["account", "user"]}>
              <.icon name="hero-user" /> Profile
              <.command_shortcut>⌘P</.command_shortcut>
            </.command_item>
            <.command_item keywords={["payment", "card"]}>
              <.icon name="hero-credit-card" /> Billing
              <.command_shortcut>⌘B</.command_shortcut>
            </.command_item>
          </.command_group>
        </.command_list>
      </.command>
    </div>
    """
  end

  example :command_dialog, "The ⌘K dialog",
    description:
      "The same palette in a native <dialog> - top layer, focus trap and Escape for free. Open it from any element." do
    ~H"""
    <div class="flex flex-col items-center gap-3">
      <.button
        color="gray"
        variant="outline"
        phx-click={PetalComponents.Command.open_command("showcase-cmdk")}
      >
        <.icon name="hero-magnifying-glass" class="w-4 h-4 mr-1" /> Open command palette
      </.button>

      <.command_dialog id="showcase-cmdk" shortcut="">
        <.command_input placeholder="Search components and actions..." />
        <.command_list>
          <.command_empty>Nothing matches. Try a component name.</.command_empty>
          <.command_group heading="Navigation">
            <.command_item keywords={["home"]}>
              <.icon name="hero-home" /> Overview
            </.command_item>
            <.command_item keywords={["ui", "components"]}>
              <.icon name="hero-squares-2x2" /> Components
            </.command_item>
            <.command_item keywords={["price", "plans"]}>
              <.icon name="hero-credit-card" /> Pricing
            </.command_item>
          </.command_group>
        </.command_list>
      </.command_dialog>
    </div>
    """
  end
end
