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
end
