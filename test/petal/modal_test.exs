defmodule PetalComponents.ModalTest do
  use ComponentCase
  import PetalComponents.Modal
  import PetalComponents.Button
  import PetalComponents.Form

  test "modal" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button label="sm" link_type="live_patch" to="/live" />

      <.modal max_width="sm" title="Modal">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.Modal.hide_modal()} />
          </div>
        </div>
      </.modal>
      """)

    assert html =~ "data-phx-link"
    assert html =~ "phx-click"

    # Test size options
    html =
      rendered_to_string(~H"""
      <.button label="md" link_type="live_patch" to="/" />

      <.modal max_width="md" title="Modal">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.Modal.hide_modal()} />
          </div>
        </div>
      </.modal>
      """)

    assert html =~ "data-phx-link"
    assert html =~ "phx-click"
    assert html =~ "pc-modal__box--md"
  end

  test "should include additional assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.modal custom-attrs="123" title="Modal"></.modal>
      """)

    assert html =~ ~s{custom-attrs="123"}
  end

  test "close_on_click_away" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.modal></.modal>
      """)

    assert html =~ ~s{phx-click-away}

    html =
      rendered_to_string(~H"""
      <.modal close_on_click_away={false}></.modal>
      """)

    refute html =~ ~s{phx-click-away}
  end

  test "close_on_escape" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.modal></.modal>
      """)

    assert html =~ ~s{phx-window-keydown}

    html =
      rendered_to_string(~H"""
      <.modal close_on_escape={false}></.modal>
      """)

    refute html =~ ~s{phx-window-keydown}
  end

  test "hide_close_button" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.modal></.modal>
      """)

    assert find_icon(html)

    html =
      rendered_to_string(~H"""
      <.modal hide_close_button></.modal>
      """)

    refute find_icon(html)
  end

  test "class" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.modal class="h-full"></.modal>
      """)

    assert html =~ "\"pc-modal__box--md pc-modal__box h-full\""

    html =
      rendered_to_string(~H"""
      <.modal></.modal>
      """)

    assert html =~ "\"pc-modal__box--md pc-modal__box \""
  end
end
