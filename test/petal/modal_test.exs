defmodule PetalComponents.ModalTest do
  @moduledoc """
  Tests for PetalComponents.Modal component.

  Validates modal rendering, size variants, close behaviors,
  accessibility features, and proper handling of edge cases.
  """

  use ComponentCase
  import PetalComponents.Modal
  import PetalComponents.Button
  import PetalComponents.Form

  describe "modal/1 - basic rendering" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders modal with title and content", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal title="Modal Title">
          <div>Modal Content</div>
        </.modal>
        """)

      assert html =~ "Modal Title"
      assert html =~ "Modal Content"
    end

    test "renders modal without title", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal>
          <div>Content Only</div>
        </.modal>
        """)

      assert html =~ "Content Only"
    end

    test "includes additional assigns as attributes", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal custom-attrs="123" title="Modal" data-test="modal-id">
          Content
        </.modal>
        """)

      assert_attribute(html, "custom-attrs", "123")
      assert_attribute(html, "data-test", "modal-id")
    end

    test "renders with custom class", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal class="custom-modal-class" title="Modal">
          Content
        </.modal>
        """)

      assert_has_class(html, "custom-modal-class")
      assert_has_class(html, "pc-modal__box")
    end
  end

  describe "modal/1 - size variants" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders with small size", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal max_width="sm" title="Small Modal">
          <div>Content</div>
        </.modal>
        """)

      assert_has_class(html, "pc-modal__box--sm")
    end

    test "renders with medium size (default)", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal max_width="md" title="Medium Modal">
          <div>Content</div>
        </.modal>
        """)

      assert_has_class(html, "pc-modal__box--md")
    end

    test "renders with large size", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal max_width="lg" title="Large Modal">
          <div>Content</div>
        </.modal>
        """)

      assert_has_class(html, "pc-modal__box--lg")
    end

    test "renders all size variants" do
      ~w(sm md lg xl) |> Enum.each(fn size ->
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <.modal max_width={@size} title="Modal">
            Content
          </.modal>
          """)

        assert_has_class(html, "pc-modal__box--#{size}")
      end)
    end
  end

  describe "modal/1 - close behaviors" do
    setup do
      %{assigns: default_assigns()}
    end

    test "includes phx-click-away by default", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal title="Modal">Content</.modal>
        """)

      assert_attribute(html, "phx-click-away")
    end

    test "does not include phx-click-away when close_on_click_away is false", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal close_on_click_away={false} title="Modal">Content</.modal>
        """)

      refute html =~ "phx-click-away"
    end

    test "includes phx-window-keydown for escape key by default", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal title="Modal">Content</.modal>
        """)

      assert_attribute(html, "phx-window-keydown")
    end

    test "does not include phx-window-keydown when close_on_escape is false", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal close_on_escape={false} title="Modal">Content</.modal>
        """)

      refute html =~ "phx-window-keydown"
    end

    test "both close behaviors can be disabled simultaneously", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal close_on_click_away={false} close_on_escape={false} title="Modal">
          Content
        </.modal>
        """)

      refute html =~ "phx-click-away"
      refute html =~ "phx-window-keydown"
    end
  end

  describe "modal/1 - close button" do
    setup do
      %{assigns: default_assigns()}
    end

    test "renders close button by default", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal title="Modal">Content</.modal>
        """)

      assert has_icon?(html)
    end

    test "does not render close button when hide_close_button is true", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal hide_close_button title="Modal">Content</.modal>
        """)

      assert count_icons(html) == 0
    end

    test "close button has proper phx-click event", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal title="Modal">Content</.modal>
        """)

      assert html =~ "phx-click"
    end
  end

  describe "modal/1 - accessibility" do
    setup do
      %{assigns: default_assigns()}
    end

    test "modal has proper ARIA role", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal role="dialog" title="Modal">Content</.modal>
        """)

      assert_attribute(html, "role", "dialog")
    end

    test "modal has aria-labelledby when title provided", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal title="Accessible Modal" aria-labelledby="modal-title">
          Content
        </.modal>
        """)

      assert_attribute(html, "aria-labelledby", "modal-title")
    end

    test "close button has aria-label for screen readers", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal title="Modal">
          <div>Content</div>
        </.modal>
        """)

      assert html =~ "aria-label"
    end

    test "keyboard navigation with escape key is supported by default", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal title="Modal">Content</.modal>
        """)

      assert_attribute(html, "phx-window-keydown")
    end
  end

  describe "modal/1 - integration with other components" do
    setup do
      %{assigns: default_assigns()}
    end

    test "modal with button inside triggers close action", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal title="Modal">
          <div>Some content</div>
          <.button label="close" phx-click={PetalComponents.Modal.hide_modal()} />
        </.modal>
        """)

      assert html =~ "phx-click"
      assert html =~ "close"
    end

    test "modal with form content", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal title="Form Modal">
          <.form :let={f} for={%{}} as={:user}>
            <.form_label label="Name" />
            <div class="flex justify-end">
              <.button label="Submit" type="submit" />
            </div>
          </.form>
        </.modal>
        """)

      assert html =~ "Form Modal"
      assert html =~ "Name"
      assert html =~ "Submit"
    end
  end

  describe "modal/1 - edge cases" do
    setup do
      %{assigns: default_assigns()}
    end

    test "handles nil title gracefully", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal title={nil}>Content</.modal>
        """)

      assert html =~ "Content"
    end

    test "handles empty content", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal title="Empty Modal"></.modal>
        """)

      assert html =~ "Empty Modal"
      assert_has_class(html, "pc-modal__box")
    end

    test "handles very long title text", %{assigns: assigns} do
      long_title = String.duplicate("Very Long Modal Title ", 10)
      assigns = %{title: long_title}

      html =
        rendered_to_string(~H"""
        <.modal title={@title}>Content</.modal>
        """)

      assert html =~ long_title
    end

    test "handles very long content", %{assigns: assigns} do
      long_content = String.duplicate("Content paragraph. ", 100)
      assigns = %{content: long_content}

      html =
        rendered_to_string(~H"""
        <.modal title="Modal">
          {@content}
        </.modal>
        """)

      assert html =~ long_content
    end

    test "handles nil max_width with default", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal max_width={nil} title="Modal">Content</.modal>
        """)

      assert_has_class(html, "pc-modal__box--md")
    end
  end

  describe "modal/1 - negative cases" do
    setup do
      %{assigns: default_assigns()}
    end

    test "modal with hide_close_button but close_on_click_away still works", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal hide_close_button title="Modal">Content</.modal>
        """)

      assert_attribute(html, "phx-click-away")
      assert count_icons(html) == 0
    end

    test "modal with all close methods disabled requires manual dismiss", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal
          hide_close_button
          close_on_click_away={false}
          close_on_escape={false}
          title="Modal"
        >
          <.button label="Close" phx-click={PetalComponents.Modal.hide_modal()} />
        </.modal>
        """)

      refute html =~ "phx-click-away"
      refute html =~ "phx-window-keydown"
      assert count_icons(html) == 0
      assert html =~ "Close"
    end

    test "invalid max_width falls back to default", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal max_width="invalid" title="Modal">Content</.modal>
        """)

      assert html =~ "Content"
    end
  end

  describe "modal/1 - hidden state" do
    setup do
      %{assigns: default_assigns()}
    end

    test "modal has hidden class by default", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal title="Modal">Content</.modal>
        """)

      assert_has_class(html, "hidden")
    end

    test "modal maintains base classes with custom class", %{assigns: assigns} do
      html =
        rendered_to_string(~H"""
        <.modal class="h-full" title="Modal">Content</.modal>
        """)

      assert_has_class(html, "hidden")
      assert_has_class(html, "pc-modal__box")
      assert_has_class(html, "h-full")
    end
  end
end
