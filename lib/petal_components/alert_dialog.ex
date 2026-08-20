defmodule PetalComponents.AlertDialog do
  @moduledoc """
  The confirm/cancel decision dialog: one question, two answers, no way out
  without picking one. "Publish these changes?", "Discard unsaved edits?",
  "Delete this account?".

  ## alert_dialog vs modal

  `PetalComponents.Modal.modal/1` is the light-dismissible general dialog
  (shadcn calls it "Dialog") - close button, click away, Escape, all of them
  cheap; `alert_dialog/1` forces an explicit choice, so backdrop clicks do
  nothing. **Reach for `modal/1` unless abandoning the choice would be
  ambiguous** - unless walking away leaves the user unsure what just happened
  to their data.

  The long version: `modal/1` holds forms, detail panes, anything, and getting
  out of it cheaply is the right behaviour for a container. `alert_dialog/1`
  is the opposite. It asks one question with two answers, and it will not let
  you leave without answering:

    * `role="alertdialog"` rather than `role="dialog"`, so assistive tech
      announces it as an interruption that needs a decision.
    * Initial focus lands on the **cancel** button - the least destructive
      action - not on confirm.
    * Escape cancels.
    * Clicking the backdrop does **nothing**. The friction is the point.

  Reach for `modal/1` when the user needs to fill something in. Reach for
  `alert_dialog/1` when the user needs to choose.

  ## Usage

  Render the dialog anywhere in the template and open it from any element with
  `open_alert_dialog/2`. The default is the calm confirm - primary button, no
  media chip, nothing shouting:

      <.button phx-click={PetalComponents.AlertDialog.open_alert_dialog("discard-changes")}>
        Back to posts
      </.button>

      <.alert_dialog
        id="discard-changes"
        title="Discard unsaved changes?"
        description="Your edits since the last save will be lost."
        confirm_label="Discard"
        cancel_label="Keep editing"
        on_confirm={JS.push("discard")}
      />

  `variant="destructive"` is the explicit opt-in to the danger treatment -
  danger confirm button, danger media chip. Ask for it; never assume it:

      <.alert_dialog
        id="delete-account"
        variant="destructive"
        title="Delete your account?"
        description="This permanently removes your account and every project in it. This cannot be undone."
        confirm_label="Delete account"
        on_confirm={JS.push("delete_account")}
      />

  The `:trigger` slot renders the opener next to the dialog and wires it up for
  you, so you never repeat the id:

      <.alert_dialog id="revoke-key" variant="destructive" title="Revoke this API key?">
        <:trigger>
          <.button color="danger" variant="outline">Revoke</.button>
        </:trigger>
      </.alert_dialog>

  The `:inner_block` composes live data into the body, below the description:

      <.alert_dialog id="bulk-delete" variant="destructive" title="Delete selected invoices?">
        <p>You are about to delete <strong>{@selected_count} invoices</strong>.</p>
      </.alert_dialog>

  The `:media` slot puts an icon or an image in a chip beside the title. Icons
  want the `pc-alert-dialog__media-icon` class so they inherit the chip's
  sizing contract; an `<img>` just fills the chip:

      <.alert_dialog id="sign-out" title="Sign out of every device?">
        <:media>
          <.icon name="hero-arrow-right-start-on-rectangle" class="pc-alert-dialog__media-icon" />
        </:media>
      </.alert_dialog>

  ## Implementation

  Built on the native `<dialog>` element (same approach as
  `PetalComponents.Command.command_dialog/1`). `showModal()` supplies the top
  layer, focus containment, the `::backdrop`, focus restoration to the opener
  on close, and - crucially for this component - **no light dismiss**: a native
  modal dialog ignores backdrop clicks, which is exactly the behaviour the
  WAI-ARIA alertdialog pattern wants.

  Two small hooks carry the parts `Phoenix.LiveView.JS` cannot reach:
  `showModal()`/`close()` are DOM methods with no JS-command equivalent, and
  Escape's native `cancel` event has to be intercepted so it runs `on_cancel`
  instead of silently closing.

  The third thing the hook owns is the **exit**. `dialog.close()` is instant -
  the element leaves the top layer in the same frame, so an out animation is
  impossible to express in CSS alone. Every way out (Escape, the cancel
  button, the confirm button, `close_alert_dialog/2`) therefore funnels
  through one close-intent step: the hook adds a closing class, the CSS plays
  the mirror of the entrance, and only when the animation ends - or a
  watchdog timer fires - does the real `close()` run. Under
  `prefers-reduced-motion: reduce` the hook skips straight to `close()`,
  because no animation would ever fire the event it waits on. Everything else
  - the surface, the animations themselves - is CSS.

  One LiveView detail worth knowing: `showModal()` sets the `open` attribute
  client-side, and the server never renders it. A patch reaching this element
  would therefore merge `open` away and shut the dialog with no `close`
  event. The hook restores its own state across patches, so an open dialog
  stays open (and an in-flight exit keeps playing) no matter what the server
  pushes while it is up.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import PetalComponents.Button
  import PetalComponents.Icon

  attr :id, :string, required: true, doc: "unique id; open the dialog with open_alert_dialog/2"

  attr :title, :string,
    required: true,
    doc: "the question being asked. Becomes the dialog's accessible name via aria-labelledby"

  attr :description, :string,
    default: nil,
    doc:
      "supporting copy explaining the consequence; wired to aria-describedby. Omit it when the inner_block carries the body"

  attr :variant, :string,
    default: "default",
    values: ["default", "destructive"],
    doc:
      "default is the calm confirm - primary button, no media chip unless you pass one. destructive is the explicit opt-in: danger confirm button, and a danger-washed media chip carrying a warning glyph"

  attr :confirm_label, :string, default: "Continue", doc: "confirm button text"
  attr :cancel_label, :string, default: "Cancel", doc: "cancel button text"

  attr :on_confirm, JS,
    default: %JS{},
    doc:
      ~s|JS commands run when the user confirms, e.g. JS.push("delete_account"). The dialog closes afterwards|

  attr :on_cancel, JS,
    default: %JS{},
    doc:
      "JS commands run when the user cancels, via the cancel button or Escape. The dialog closes afterwards"

  attr :class, :any, default: nil, doc: "extra classes for the dialog element"
  attr :rest, :global

  slot :inner_block,
    required: false,
    doc: "custom body content rendered below the description"

  slot :media,
    required: false,
    doc:
      "an icon or image rendered in a chip beside the title. Give icons the pc-alert-dialog__media-icon class; an img fills the chip. The destructive variant supplies a warning glyph when this is empty; the default variant renders no chip unless you pass one"

  slot :trigger,
    required: false,
    doc: "an opener rendered next to the dialog, pre-wired to open it"

  @doc """
  Renders an alert dialog. See the module docs for when to use this over
  `PetalComponents.Modal.modal/1`.
  """
  def alert_dialog(assigns) do
    assigns =
      assign(assigns, :show_media?, assigns.media != [] or assigns.variant == "destructive")

    ~H"""
    <div
      :if={@trigger != []}
      id={"#{@id}-trigger"}
      class="pc-alert-dialog__trigger"
      phx-hook="PetalAlertDialogTrigger"
      data-dialog={@id}
    >
      {render_slot(@trigger)}
    </div>
    <dialog
      id={@id}
      role="alertdialog"
      aria-modal="true"
      aria-labelledby={"#{@id}-title"}
      aria-describedby={@description && "#{@id}-description"}
      phx-hook="PetalAlertDialog"
      class={[
        "pc-alert-dialog",
        @variant == "destructive" && "pc-alert-dialog--destructive",
        @class
      ]}
      {@rest}
    >
      <div class="pc-alert-dialog__panel">
        <div class="pc-alert-dialog__header">
          <div :if={@show_media?} class="pc-alert-dialog__media" aria-hidden="true">
            <%= if @media != [] do %>
              {render_slot(@media)}
            <% else %>
              <.icon name="hero-exclamation-triangle" class="pc-alert-dialog__media-icon" />
            <% end %>
          </div>
          <h2 id={"#{@id}-title"} class="pc-alert-dialog__title">{@title}</h2>
        </div>

        <div class="pc-alert-dialog__body">
          <p :if={@description} id={"#{@id}-description"} class="pc-alert-dialog__description">
            {@description}
          </p>
          <div :if={@inner_block != []} class="pc-alert-dialog__content">
            {render_slot(@inner_block)}
          </div>
        </div>

        <div class="pc-alert-dialog__footer">
          <.button
            type="button"
            color="gray"
            variant="outline"
            autofocus
            phx-click={@on_cancel}
            data-pc-alert-dialog-cancel
            data-pc-alert-dialog-close
            class="pc-alert-dialog__cancel"
          >
            {@cancel_label}
          </.button>
          <.button
            type="button"
            color={confirm_color(@variant)}
            phx-click={@on_confirm}
            data-pc-alert-dialog-confirm
            data-pc-alert-dialog-close
            class="pc-alert-dialog__confirm"
          >
            {@confirm_label}
          </.button>
        </div>
      </div>
    </dialog>
    """
  end

  defp confirm_color("destructive"), do: "danger"
  defp confirm_color(_), do: "primary"

  @doc """
  Returns a `JS` command that opens the alert dialog with the given id.
  Compose it onto any element: `phx-click={open_alert_dialog("delete-account")}`.
  """
  def open_alert_dialog(js \\ %JS{}, id) when is_binary(id) do
    JS.dispatch(js, "pc:alert-dialog-open", to: "##{id}")
  end

  @doc """
  Returns a `JS` command that closes the alert dialog with the given id.

  You rarely need this - both actions close the dialog themselves. It exists
  so a programmatic close (a `push_event` from the server, a parent component
  tidying up) drains through the same close-intent funnel as Escape and the
  buttons, and therefore plays the same exit animation instead of snapping
  the dialog out from under the user.
  """
  def close_alert_dialog(js \\ %JS{}, id) when is_binary(id) do
    JS.dispatch(js, "pc:alert-dialog-close", to: "##{id}")
  end
end
