defmodule PetalComponents.AlertDialogTest do
  use ComponentCase

  import PetalComponents.AlertDialog
  import PetalComponents.Icon

  alias Phoenix.LiveView.JS

  defp doc(html), do: LazyHTML.from_fragment(html)

  defp attr_of(html, selector, attribute) do
    html
    |> doc()
    |> LazyHTML.query(selector)
    |> LazyHTML.attribute(attribute)
    |> List.first()
  end

  describe "alert_dialog/1 - ARIA" do
    test "renders a native dialog with the alertdialog role and aria-modal" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Delete this project?" />
        """)

      assert attr_of(html, "dialog#confirm", "role") == "alertdialog"
      assert attr_of(html, "dialog#confirm", "aria-modal") == "true"
    end

    test "aria-labelledby resolves to the rendered title id, and the title text renders" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Delete this project?" />
        """)

      labelledby = attr_of(html, "dialog#confirm", "aria-labelledby")
      assert labelledby == "confirm-title"

      title = html |> doc() |> LazyHTML.query("##{labelledby}")
      assert LazyHTML.text(title) =~ "Delete this project?"
      assert attr_of(html, "##{labelledby}", "class") =~ "pc-alert-dialog__title"
    end

    test "aria-describedby resolves to the description id when description is set" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Delete?" description="This cannot be undone." />
        """)

      describedby = attr_of(html, "dialog#confirm", "aria-describedby")
      assert describedby == "confirm-description"

      description = html |> doc() |> LazyHTML.query("##{describedby}")
      assert LazyHTML.text(description) =~ "This cannot be undone."
    end

    test "aria-describedby is absent when no description is given" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Delete?" />
        """)

      assert attr_of(html, "dialog#confirm", "aria-describedby") == nil
      refute_attribute(html, "aria-describedby")
      assert html |> doc() |> LazyHTML.query(".pc-alert-dialog__description") |> Enum.empty?()
    end

    test "the decorative media chip is hidden from assistive tech" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" variant="destructive" title="Delete?" />
        """)

      assert attr_of(html, ".pc-alert-dialog__media", "aria-hidden") == "true"
    end
  end

  describe "alert_dialog/1 - variants" do
    test "default variant renders the primary confirm treatment" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Continue?" />
        """)

      assert attr_of(html, ".pc-alert-dialog__confirm", "class") =~ "pc-button--primary"
      refute_has_class(html, "pc-alert-dialog--destructive")
    end

    test "destructive variant renders the danger confirm and the modifier class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" variant="destructive" title="Delete?" />
        """)

      assert_has_class(html, "pc-alert-dialog--destructive")
      assert attr_of(html, ".pc-alert-dialog__confirm", "class") =~ "pc-button--danger"
    end

    test "destructive variant supplies a default danger glyph in the media chip" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" variant="destructive" title="Delete?" />
        """)

      assert has_icon?(html, "hero-exclamation-triangle")
      assert attr_of(html, ".pc-alert-dialog__media-icon", "class") =~ "hero-exclamation-triangle"
    end

    test "default variant renders no media chip without the media slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Continue?" />
        """)

      assert html |> doc() |> LazyHTML.query(".pc-alert-dialog__media") |> Enum.empty?()
      refute has_icon?(html)
    end

    test "the calm default: nothing on the danger ramp unless destructive is asked for" do
      # The pin for "destructive is an explicit variant, never the ambient
      # default". If a future edit leans the base treatment towards danger -
      # the confirm button, the modifier class, the media chip's wash - this
      # is the test that says no.
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Publish these changes?" confirm_label="Publish" />
        """)

      refute html =~ "danger"
      refute html =~ "destructive"
      assert attr_of(html, ".pc-alert-dialog__confirm", "class") =~ "pc-button--primary"
      assert html |> doc() |> LazyHTML.query(".pc-alert-dialog__media") |> Enum.empty?()
    end

    test "the cancel button always rides the neutral ramp, in both variants" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="a" title="Continue?" />
        <.alert_dialog id="b" variant="destructive" title="Delete?" />
        """)

      classes =
        html |> doc() |> LazyHTML.query(".pc-alert-dialog__cancel") |> LazyHTML.attribute("class")

      assert length(classes) == 2
      assert Enum.all?(classes, &(&1 =~ "pc-button--gray-outline"))
    end
  end

  describe "alert_dialog/1 - slots" do
    test "the media slot overrides the destructive variant's default glyph" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" variant="destructive" title="Delete?">
          <:media>
            <.icon name="hero-fire" class="pc-alert-dialog__media-icon" />
          </:media>
        </.alert_dialog>
        """)

      assert has_icon?(html, "hero-fire")
      refute has_icon?(html, "hero-exclamation-triangle")
    end

    test "the media slot renders a chip on the default variant too" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Sign out?">
          <:media>
            <.icon name="hero-key" class="pc-alert-dialog__media-icon" />
          </:media>
        </.alert_dialog>
        """)

      assert has_icon?(html, "hero-key")
      refute html |> doc() |> LazyHTML.query(".pc-alert-dialog__media") |> Enum.empty?()
    end

    test "the media slot takes an image, not only an icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Remove this member?">
          <:media>
            <img src="/images/ada.jpg" alt="" />
          </:media>
        </.alert_dialog>
        """)

      img = html |> doc() |> LazyHTML.query(".pc-alert-dialog__media > img")
      assert Enum.count(img) == 1
      assert img |> LazyHTML.attribute("src") == ["/images/ada.jpg"]
    end

    test "the media chip sits beside the title, in the header, above the body" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Sign out?">
          <:media>
            <.icon name="hero-key" class="pc-alert-dialog__media-icon" />
          </:media>
        </.alert_dialog>
        """)

      header = html |> doc() |> LazyHTML.query(".pc-alert-dialog__header")

      assert header
             |> LazyHTML.query(".pc-alert-dialog__media + .pc-alert-dialog__title")
             |> Enum.count() == 1
    end

    test "inner_block content renders inside the body, below the description" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Delete invoices?" description="14 selected.">
          <p class="my-body">You are about to delete 14 invoices.</p>
        </.alert_dialog>
        """)

      body = html |> doc() |> LazyHTML.query(".pc-alert-dialog__body .pc-alert-dialog__content")
      assert LazyHTML.text(body) =~ "You are about to delete 14 invoices."

      assert html |> doc() |> LazyHTML.query(".pc-alert-dialog__body .my-body") |> Enum.count() ==
               1
    end

    test "no content wrapper renders without an inner_block" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Delete?" />
        """)

      assert html |> doc() |> LazyHTML.query(".pc-alert-dialog__content") |> Enum.empty?()
    end

    test "the trigger slot renders and is wired to open the dialog" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="revoke-key" title="Revoke this key?">
          <:trigger>
            <button type="button" class="my-trigger">Revoke</button>
          </:trigger>
        </.alert_dialog>
        """)

      assert attr_of(html, "#revoke-key-trigger", "phx-hook") == "PetalAlertDialogTrigger"
      assert attr_of(html, "#revoke-key-trigger", "data-dialog") == "revoke-key"

      assert html |> doc() |> LazyHTML.query("#revoke-key-trigger .my-trigger") |> Enum.count() ==
               1
    end

    test "no trigger wrapper renders without the trigger slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="revoke-key" title="Revoke this key?" />
        """)

      assert html |> doc() |> LazyHTML.query(".pc-alert-dialog__trigger") |> Enum.empty?()
      refute html =~ "PetalAlertDialogTrigger"
    end
  end

  describe "alert_dialog/1 - labels" do
    test "confirm_label and cancel_label default to Continue and Cancel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Continue?" />
        """)

      assert html |> doc() |> LazyHTML.query(".pc-alert-dialog__confirm") |> LazyHTML.text() =~
               "Continue"

      assert html |> doc() |> LazyHTML.query(".pc-alert-dialog__cancel") |> LazyHTML.text() =~
               "Cancel"
    end

    test "confirm_label and cancel_label overrides render" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog
          id="confirm"
          title="Discard unsaved changes?"
          confirm_label="Discard"
          cancel_label="Keep editing"
        />
        """)

      assert html |> doc() |> LazyHTML.query(".pc-alert-dialog__confirm") |> LazyHTML.text() =~
               "Discard"

      assert html |> doc() |> LazyHTML.query(".pc-alert-dialog__cancel") |> LazyHTML.text() =~
               "Keep editing"

      refute html |> doc() |> LazyHTML.query(".pc-alert-dialog__cancel") |> LazyHTML.text() =~
               "Cancel"
    end
  end

  describe "alert_dialog/1 - JS wiring" do
    test "on_confirm is attached to the confirm button, on_cancel to the cancel button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog
          id="confirm"
          title="Delete?"
          on_confirm={JS.push("delete_account")}
          on_cancel={JS.push("keep_account")}
        />
        """)

      confirm = attr_of(html, ".pc-alert-dialog__confirm", "phx-click")
      cancel = attr_of(html, ".pc-alert-dialog__cancel", "phx-click")

      assert confirm == ~s|[["push",{"event":"delete_account"}]]|
      assert cancel == ~s|[["push",{"event":"keep_account"}]]|
    end

    test "both actions carry the close marker the hook closes the dialog on" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Delete?" />
        """)

      assert html
             |> doc()
             |> LazyHTML.query("[data-pc-alert-dialog-close]")
             |> Enum.count() == 2

      assert html
             |> doc()
             |> LazyHTML.query(".pc-alert-dialog__cancel[data-pc-alert-dialog-cancel]")
             |> Enum.count() == 1

      assert html
             |> doc()
             |> LazyHTML.query(".pc-alert-dialog__confirm[data-pc-alert-dialog-confirm]")
             |> Enum.count() == 1
    end

    test "initial focus is pinned to the cancel button, the least destructive action" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" variant="destructive" title="Delete?" />
        """)

      # showModal() honours [autofocus]; the hook also focuses this button
      # explicitly. Either way it must be cancel, never confirm.
      assert html
             |> doc()
             |> LazyHTML.query(".pc-alert-dialog__cancel[autofocus]")
             |> Enum.count() == 1

      assert html
             |> doc()
             |> LazyHTML.query(".pc-alert-dialog__confirm[autofocus]")
             |> Enum.empty?()
    end

    test "the dialog mounts the PetalAlertDialog hook that owns Escape and closing" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Delete?" />
        """)

      assert attr_of(html, "dialog#confirm", "phx-hook") == "PetalAlertDialog"
    end

    test "no light-dismiss wiring exists - click-away must not close the dialog" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Delete?" description="Careful." />
        """)

      # A native modal <dialog> ignores backdrop clicks; nothing here may add
      # it back. No phx-click-away, and no closedby="any" opt-in either.
      refute html =~ "phx-click-away"
      refute html =~ "click_away"
      refute html =~ ~s|closedby="any"|
      assert html |> doc() |> LazyHTML.query("[phx-click-away]") |> Enum.empty?()
    end

    test "no overlay div is rendered - the native ::backdrop does that job" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Delete?" />
        """)

      refute html =~ "pc-modal__overlay"
      assert html |> doc() |> LazyHTML.query("dialog") |> Enum.count() == 1
    end

    test "open_alert_dialog/2 dispatches the open event at the dialog" do
      assert [["dispatch", opts]] = open_alert_dialog("delete-account").ops
      assert opts.event == "pc:alert-dialog-open"
      assert opts.to == "#delete-account"
    end

    test "open_alert_dialog/2 composes onto an existing JS chain" do
      js = JS.push("track") |> open_alert_dialog("delete-account")

      assert [["push", %{event: "track"}], ["dispatch", opts]] = js.ops
      assert opts.event == "pc:alert-dialog-open"
      assert opts.to == "#delete-account"
    end

    test "close_alert_dialog/2 dispatches the close event at the dialog" do
      # A programmatic close is an event the hook handles, not a direct
      # .close() - that is what keeps it inside the exit-animation funnel.
      assert [["dispatch", opts]] = close_alert_dialog("delete-account").ops
      assert opts.event == "pc:alert-dialog-close"
      assert opts.to == "#delete-account"
    end

    test "close_alert_dialog/2 composes onto an existing JS chain" do
      js = JS.push("track") |> close_alert_dialog("delete-account")

      assert [["push", %{event: "track"}], ["dispatch", opts]] = js.ops
      assert opts.event == "pc:alert-dialog-close"
      assert opts.to == "#delete-account"
    end
  end

  describe "alert_dialog/1 - pass-through" do
    test "class is appended to the dialog element's classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Delete?" class="max-w-xs my-custom" />
        """)

      class = attr_of(html, "dialog#confirm", "class")
      assert class =~ "pc-alert-dialog"
      assert class =~ "max-w-xs"
      assert class =~ "my-custom"
    end

    test "rest attributes land on the dialog element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Delete?" data-testid="danger-zone" data-role="gate" />
        """)

      assert attr_of(html, "dialog#confirm", "data-testid") == "danger-zone"
      assert attr_of(html, "dialog#confirm", "data-role") == "gate"
    end

    test "ids are namespaced per dialog so two can coexist" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="one" title="First?" description="One." />
        <.alert_dialog id="two" title="Second?" description="Two." />
        """)

      assert attr_of(html, "dialog#one", "aria-labelledby") == "one-title"
      assert attr_of(html, "dialog#two", "aria-labelledby") == "two-title"
      assert attr_of(html, "dialog#one", "aria-describedby") == "one-description"
      assert attr_of(html, "dialog#two", "aria-describedby") == "two-description"
    end
  end

  describe "alert_dialog/1 - structure" do
    test "the panel keeps the header and footer band outside the scrolling body" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" variant="destructive" title="Delete?" description="Careful." />
        """)

      d = doc(html)

      assert d
             |> LazyHTML.query(".pc-alert-dialog__panel > .pc-alert-dialog__header")
             |> Enum.count() ==
               1

      assert d
             |> LazyHTML.query(".pc-alert-dialog__panel > .pc-alert-dialog__body")
             |> Enum.count() ==
               1

      assert d
             |> LazyHTML.query(".pc-alert-dialog__panel > .pc-alert-dialog__footer")
             |> Enum.count() == 1

      assert d
             |> LazyHTML.query(".pc-alert-dialog__header > .pc-alert-dialog__media")
             |> Enum.count() == 1

      assert d
             |> LazyHTML.query(".pc-alert-dialog__header > .pc-alert-dialog__title")
             |> Enum.count() == 1
    end

    test "cancel is rendered before confirm so Tab order reaches the safe action first" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Delete?" />
        """)

      classes =
        html
        |> doc()
        |> LazyHTML.query(".pc-alert-dialog__footer button")
        |> LazyHTML.attribute("class")

      assert [cancel, confirm] = classes
      assert cancel =~ "pc-alert-dialog__cancel"
      assert confirm =~ "pc-alert-dialog__confirm"
    end

    test "the footer band is the last child of the panel, after the scrolling body" do
      # The band's border-t and wash only read as a footer if it sits at the
      # bottom edge of the panel with nothing after it.
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Delete?" description="Careful." />
        """)

      assert html
             |> doc()
             |> LazyHTML.query(".pc-alert-dialog__body + .pc-alert-dialog__footer:last-child")
             |> Enum.count() == 1
    end

    test "both actions are type=button so they never submit a surrounding form" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="confirm" title="Delete?" />
        """)

      types =
        html
        |> doc()
        |> LazyHTML.query(".pc-alert-dialog__footer button")
        |> LazyHTML.attribute("type")

      assert types == ["button", "button"]
    end
  end
end
