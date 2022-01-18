defmodule PetalComponents.ModalTest do
  use ComponentCase
  import PetalComponents.Modal
  import PetalComponents.Button
  import PetalComponents.Form

  test "modal" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <.button label="sm" link_type="live_patch" to="/live" />

      <.modal max_width="sm" title="Modal">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.Modal.hide_modal()} />
          </div>
        </div>
      </.modal>
      """
    )
    assert html =~ "data-phx-link"
    assert html =~ "phx-click"
    assert html =~ "max-w-sm"

    # Test size options
    html = rendered_to_string(
      ~H"""
      <.button label="md" link_type="live_patch" to="/" />

      <.modal max_width="md" title="Modal">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.Modal.hide_modal()} />
          </div>
        </div>
      </.modal>
      """
    )
    assert html =~ "data-phx-link"
    assert html =~ "phx-click"
    assert html =~ "max-w-xl"

    html = rendered_to_string(
      ~H"""
      <.button label="lg" link_type="live_patch" to="/live" />

      <.modal max_width="lg" title="Modal">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.Modal.hide_modal()} />
          </div>
        </div>
      </.modal>
      """
    )
    assert html =~ "data-phx-link"
    assert html =~ "phx-click"
    assert html =~ "max-w-3xl"

    html = rendered_to_string(
      ~H"""
      <.button label="xl" link_type="live_patch" to="/live" />

      <.modal max_width="xl" title="Modal">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.Modal.hide_modal()} />
          </div>
        </div>
      </.modal>
      """
    )
    assert html =~ "data-phx-link"
    assert html =~ "phx-click"
    assert html =~ "max-w-5xl"

    html = rendered_to_string(
      ~H"""
      <.button label="2xl" link_type="live_patch" to="/live" />

      <.modal max_width="2xl" title="Modal">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.Modal.hide_modal()} />
          </div>
        </div>
      </.modal>
      """
    )
    assert html =~ "data-phx-link"
    assert html =~ "phx-click"
    assert html =~ "max-w-7xl"

    html = rendered_to_string(
      ~H"""
      <.button label="full" link_type="live_patch" to="/live" />

      <.modal max_width="full" title="Modal">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.Modal.hide_modal()} />
          </div>
        </div>
      </.modal>
      """
    )
    assert html =~ "data-phx-link"
    assert html =~ "phx-click"
    assert html =~ "max-w-full"
  end

  test "dark mode" do
    assigns = %{}
    html = rendered_to_string(
      ~H"""
      <.button label="sm" link_type="live_patch" to="/live" />

      <.modal max_width="sm" title="Modal">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.Modal.hide_modal()} />
          </div>
        </div>
      </.modal>
      """
    )
    assert html =~ "data-phx-link"
    assert html =~ "phx-click"
    assert html =~ "max-w-sm"
    assert html =~ "dark:"
  end
end
