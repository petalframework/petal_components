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

  example :headerless_confirmation, "Headerless confirmation",
    description:
      "Confirmation dialogs often center their heading in the content instead of a header bar. hide_header hides the bar visually but keeps it in the DOM, so the title you pass still names the dialog for screen readers via aria-labelledby. It also drops the corner close button, so give the content its own way out (here a button, plus escape and click-away)." do
    ~H"""
    <.button color="gray" variant="outline" phx-click={show_modal("showcase-modal-headerless")}>
      Open confirmation
    </.button>

    <.modal
      id="showcase-modal-headerless"
      title="Unsubscribed successfully"
      hide
      hide_header
      max_width="sm"
    >
      <div class="text-center">
        <div class="flex items-center justify-center w-12 h-12 mx-auto rounded-full bg-success-100 dark:bg-success-500/15">
          <.icon name="hero-check" class="w-6 h-6 text-success-600 dark:text-success-400" />
        </div>
        <h3 class="mt-3 text-lg font-semibold text-gray-800 dark:text-gray-200">
          Unsubscribed successfully
        </h3>
        <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
          You won't get marketing emails from us anymore. You can resubscribe
          any time from your notification settings.
        </p>
        <.button
          class="mt-6"
          color="gray"
          variant="outline"
          phx-click={hide_modal("showcase-modal-headerless")}
        >
          Back to settings
        </.button>
      </div>
    </.modal>
    """
  end
end
