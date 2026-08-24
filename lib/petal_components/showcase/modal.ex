defmodule PetalComponents.Showcase.Modal do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Modal, title: "Modal"

  example :invite_dialog, "Invite dialog",
    description:
      "The whole wiring in one place: a modal rendered with hide stays out of view until show_modal/1 - a plain LiveView.JS command on any phx-click, no server round-trip - and hide_modal/1 closes it the same way. Escape and click-away close by default (close_on_escape / close_on_click_away), title labels the dialog for screen readers, max_width sizes the box, and the :footer slot puts the actions in the band at the bottom." do
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
      <:footer>
        <.button color="gray" variant="outline" phx-click={hide_modal("showcase-modal")}>
          Cancel
        </.button>
        <.button phx-click={hide_modal("showcase-modal")}>Copy link</.button>
      </:footer>
    </.modal>
    """
  end

  example :form_modal, "A form in a modal",
    description:
      "The most common thing a dialog holds. Fields go in the content inside a form, the submit row goes in the :footer, and the button reaches back into the form with the HTML form attribute - the footer band is outside the form element, and form=\"...\" is how a submit crosses that boundary. On a narrow screen the buttons stack with the primary one on top, under the thumb, and unstack to a right-aligned row from sm up." do
    ~H"""
    <.button color="gray" variant="outline" phx-click={show_modal("showcase-modal-form")}>
      <.icon name="hero-pencil-square" class="w-4 h-4 mr-1" /> Edit profile
    </.button>

    <.modal id="showcase-modal-form" title="Edit profile" hide max_width="md">
      <p class="text-sm text-gray-500 dark:text-gray-400">
        Make changes to your profile here. Nothing saves until you say so.
      </p>
      <form id="showcase-profile-form" phx-submit={hide_modal("showcase-modal-form")}>
        <div class="flex flex-col gap-4 mt-4">
          <.field type="text" name="profile_name" value="Alex Rivera" label="Name" />
          <.field type="text" name="profile_username" value="@alexrivera" label="Username" />
          <.field
            type="textarea"
            name="profile_bio"
            value=""
            label="Bio"
            placeholder="A line about you"
          />
        </div>
      </form>
      <:footer>
        <.button color="gray" variant="outline" phx-click={hide_modal("showcase-modal-form")}>
          Cancel
        </.button>
        <%!-- The footer band sits outside the <form> element, so the submit
        reaches back in with the form attribute - without it this button
        could never submit the fields above it. --%>
        <.button type="submit" form="showcase-profile-form">
          Save changes
        </.button>
      </:footer>
    </.modal>
    """
  end

  example :scrolling_content, "A long body, a footer that stays put",
    description:
      "The box is a column: the header and the footer are fixed bands and the content between them is the only part that scrolls. Give the modal more text than the viewport can hold and the body scrolls under the action row rather than pushing it off the bottom, so the way out is always on screen." do
    ~H"""
    <.button color="gray" variant="outline" phx-click={show_modal("showcase-modal-terms")}>
      Read the terms
    </.button>

    <.modal id="showcase-modal-terms" title="Terms of service" hide max_width="md">
      <div class="flex flex-col gap-4 text-sm text-gray-500 dark:text-gray-400">
        <p :for={n <- 1..12}>
          Section {n}. You agree to use the service in the way a reasonable
          person would, and we agree to keep it running. Neither of us will
          sell the other's data, send unsolicited mail, or pretend a change
          to this document is a feature announcement. Scroll on: the accept
          button is not going anywhere.
        </p>
      </div>
      <:footer>
        <.button color="gray" variant="outline" phx-click={hide_modal("showcase-modal-terms")}>
          Decline
        </.button>
        <.button phx-click={hide_modal("showcase-modal-terms")}>Accept</.button>
      </:footer>
    </.modal>
    """
  end

  example :sizes, "Sizes",
    description:
      "max_width caps the box: sm, md (the default), lg, xl, 2xl and full. The wrapper keeps its own padding either way, so even full stays off the viewport edges on a phone. Pick the smallest one the content reads comfortably in - a two-line confirmation in a 2xl box is mostly empty space." do
    ~H"""
    <div class="flex flex-wrap gap-2">
      <.button
        :for={size <- ~w(sm md lg xl 2xl full)}
        color="gray"
        variant="outline"
        phx-click={show_modal("showcase-modal-size-" <> size)}
      >
        {size}
      </.button>
    </div>

    <.modal
      :for={size <- ~w(sm md lg xl 2xl full)}
      id={"showcase-modal-size-" <> size}
      title={"Size " <> size}
      hide
      max_width={size}
    >
      <p class="text-sm text-gray-500 dark:text-gray-400">
        This box is capped at max_width="{size}". Everything else about it is
        the same dialog.
      </p>
      <:footer>
        <.button
          color="gray"
          variant="outline"
          phx-click={hide_modal("showcase-modal-size-" <> size)}
        >
          Close
        </.button>
      </:footer>
    </.modal>
    """
  end

  example :custom_footer, "A footer with a tertiary action",
    description:
      "The band is a flex row that pushes its children to the end. Want something on the far left instead - a help link, a destructive action, a step counter - put one full-width child in the slot and lay it out yourself. The band, the border and the padding stay the component's job." do
    ~H"""
    <.button color="gray" variant="outline" phx-click={show_modal("showcase-modal-tertiary")}>
      Open API key
    </.button>

    <.modal id="showcase-modal-tertiary" title="Rotate API key" hide max_width="md">
      <p class="text-sm text-gray-500 dark:text-gray-400">
        A new key is issued straight away and the old one keeps working for
        another 24 hours, so you have time to redeploy.
      </p>
      <:footer>
        <div class="flex items-center justify-between w-full gap-4">
          <.button color="gray" variant="ghost" phx-click={hide_modal("showcase-modal-tertiary")}>
            <.icon name="hero-book-open" class="w-4 h-4 mr-1" /> Read the docs
          </.button>
          <div class="flex items-center gap-2">
            <.button
              color="gray"
              variant="outline"
              phx-click={hide_modal("showcase-modal-tertiary")}
            >
              Cancel
            </.button>
            <.button color="danger" phx-click={hide_modal("showcase-modal-tertiary")}>
              Rotate key
            </.button>
          </div>
        </div>
      </:footer>
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
