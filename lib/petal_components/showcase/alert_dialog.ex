defmodule PetalComponents.Showcase.AlertDialog do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.AlertDialog,
    title: "Alert dialog",
    functions: [:alert_dialog]

  example :unsaved_changes, "Confirm a choice",
    description:
      "The default, and the one you reach for most: no media chip, primary confirm, nothing raising its voice. Focus lands on Cancel when it opens, Escape cancels, and clicking the backdrop does nothing. Relabel both buttons so each one names its outcome - Keep editing and Discard beat OK and Cancel every time." do
    ~H"""
    <.alert_dialog
      id="showcase-unsaved-changes"
      title="Discard unsaved changes?"
      description="Your edits since the last save will be lost."
      confirm_label="Discard"
      cancel_label="Keep editing"
    >
      <:trigger>
        <.button color="gray" variant="outline">
          <.icon name="hero-arrow-left" class="w-4 h-4 mr-1" /> Back to posts
        </.button>
      </:trigger>
    </.alert_dialog>
    """
  end

  example :with_media, "A media chip beside the title",
    description:
      "The media slot puts a 40px chip next to the question - an icon, an avatar, a thumbnail of the thing you are about to act on. Give icons the pc-alert-dialog__media-icon class so they inherit the chip's sizing; an img fills the chip on its own." do
    ~H"""
    <.alert_dialog
      id="showcase-media"
      title="Sign out of every device?"
      description="You will need to sign in again on your phone, your tablet and any browser you have used this month."
      confirm_label="Sign out everywhere"
    >
      <:media>
        <.icon name="hero-arrow-right-start-on-rectangle" class="pc-alert-dialog__media-icon" />
      </:media>
      <:trigger>
        <.button color="gray" variant="outline">Sign out everywhere</.button>
      </:trigger>
    </.alert_dialog>
    """
  end

  example :delete_account, "Destructive",
    description:
      "variant=\"destructive\" is the explicit opt-in, never the default: the chip takes the danger wash and a warning glyph, the confirm button moves to the danger ramp, and the description spells out exactly what is about to be lost." do
    ~H"""
    <.alert_dialog
      id="showcase-delete-account"
      variant="destructive"
      title="Delete your account?"
      description="This permanently removes your account, your projects and every deployment attached to them. This cannot be undone."
      confirm_label="Delete account"
    >
      <:trigger>
        <.button color="danger">Delete account</.button>
      </:trigger>
    </.alert_dialog>
    """
  end

  example :bulk_delete, "Destructive with a summary",
    description:
      "The body slot composes anything under the description - here a count and the invoice list, so the user can see exactly what the confirm button is going to take." do
    ~H"""
    <.alert_dialog
      id="showcase-bulk-delete"
      variant="destructive"
      title="Delete 14 invoices?"
      description="These invoices leave your records immediately. Paid invoices stay in your Stripe account."
      confirm_label="Delete 14 invoices"
    >
      <:trigger>
        <.button color="danger" variant="outline">
          <.icon name="hero-trash" class="w-4 h-4 mr-1" /> Delete selected
        </.button>
      </:trigger>
      <ul class="pl-4 mt-1 space-y-1 list-disc marker:text-gray-400">
        <li>INV-2041 through INV-2054</li>
        <li>3 are already marked paid</li>
        <li>Total value $18,420.00</li>
      </ul>
    </.alert_dialog>
    """
  end

  example :custom_media, "Your own glyph on the destructive variant",
    description:
      "The destructive variant ships a warning triangle; the media slot replaces it while keeping the danger wash, so the chip can name the thing rather than the severity." do
    ~H"""
    <.alert_dialog
      id="showcase-custom-media"
      variant="destructive"
      title="Revoke this API key?"
      description="Any service still using this key stops working the moment you revoke it."
      confirm_label="Revoke key"
    >
      <:media>
        <.icon name="hero-key" class="pc-alert-dialog__media-icon" />
      </:media>
      <:trigger>
        <.button color="danger" variant="outline">Revoke key</.button>
      </:trigger>
    </.alert_dialog>
    """
  end
end
