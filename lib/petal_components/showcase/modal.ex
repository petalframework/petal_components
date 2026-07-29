defmodule PetalComponents.Showcase.Modal do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Modal, title: "Modal"

  example :invite_dialog, "Invite dialog",
    description:
      "The whole wiring in one place: a modal rendered with hide stays out of view until show_modal/1 - a plain LiveView.JS command on any phx-click, no server round-trip - and hide_modal/1 closes it the same way. Escape and click-away close by default (close_on_escape / close_on_click_away), title labels the dialog for screen readers, and max_width sizes the box." do
    ~H"""
    <.button color="gray" variant="outline" phx-click={show_modal("showcase-modal")}>
      Open modal
    </.button>

    <.modal id="showcase-modal" title="Invite your team" hide max_width="sm">
      <p class="text-sm text-gray-500 dark:text-gray-400">
        Share this link with your teammates and they'll join the workspace
        with member access.
      </p>
      <div class="mt-4">
        <.input_group>
          <.input type="text" name="invite_url" value="https://example.com/join/x1y2z3" readonly />
          <:trailing><kbd><span>⌘</span>C</kbd></:trailing>
        </.input_group>
      </div>
      <div class="flex justify-end gap-2 mt-6">
        <.button color="gray" variant="outline" phx-click={hide_modal("showcase-modal")}>
          Cancel
        </.button>
        <.button phx-click={hide_modal("showcase-modal")}>Copy link</.button>
      </div>
    </.modal>
    """
  end
end
