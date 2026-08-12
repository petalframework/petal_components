defmodule PetalComponents.Showcase.AlertDialog do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.AlertDialog,
    title: "Alert dialog",
    functions: [:alert_dialog]

  example :delete_account, "Delete account",
    description:
      "The destructive variant: danger icon, danger confirm button, and a description that spells out what is about to be lost. Focus lands on Cancel when it opens, Escape cancels, and clicking the backdrop does nothing." do
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

  example :unsaved_changes, "Unsaved changes",
    description:
      "The default variant: no icon, primary confirm. Relabel both buttons so each one names its outcome - Keep editing and Discard beat OK and Cancel every time." do
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

  example :bulk_delete, "Bulk delete with a summary",
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

  example :custom_icon, "Your own icon",
    description:
      "The destructive variant ships a danger icon; the icon slot replaces it, and it works on the default variant too when the question wants a visual anchor." do
    ~H"""
    <.alert_dialog
      id="showcase-custom-icon"
      title="Sign out of every device?"
      description="You will need to sign in again on your phone, your tablet and any browser you have used this month."
      confirm_label="Sign out everywhere"
    >
      <:icon>
        <.icon name="hero-arrow-right-start-on-rectangle" class="pc-alert-dialog__icon-svg" />
      </:icon>
      <:trigger>
        <.button color="gray" variant="outline">Sign out everywhere</.button>
      </:trigger>
    </.alert_dialog>
    """
  end
end
