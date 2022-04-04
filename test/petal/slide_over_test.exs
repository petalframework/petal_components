defmodule PetalComponents.SlideOverTest do
  use ComponentCase
  import PetalComponents.SlideOver
  import PetalComponents.Button
  import PetalComponents.Form

  test "slide_over" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button label="start" link_type="live_patch" to="/live" />

      <.slide_over title="SlideOver" slide_over="start">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.SlideOver.hide_slide_over("start")} />
          </div>
        </div>
      </.slide_over>
      """)

    assert html =~ "data-phx-link"
    assert html =~ "phx-click"
    assert html =~ "translate-x-0"

    # Test origin options
    html =
      rendered_to_string(~H"""
      <.button label="end" link_type="live_patch" to="/" />

      <.slide_over slide_over="end" title="SlideOver">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.SlideOver.hide_slide_over("end")} />
          </div>
        </div>
      </.slide_over>
      """)

    assert html =~ "data-phx-link"
    assert html =~ "phx-click"
    assert html =~ "absolute right-0 inset-y-0"

    html =
      rendered_to_string(~H"""
      <.button label="top" link_type="live_patch" to="/live" />

      <.slide_over slide_over="top" title="SlideOver">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.SlideOver.hide_slide_over("top")} />
          </div>
        </div>
      </.slide_over>
      """)

    assert html =~ "data-phx-link"
    assert html =~ "phx-click"
    assert html =~ "translate-y-0 absolute inset-x-0"

    html =
      rendered_to_string(~H"""
      <.button label="bottom" link_type="live_patch" to="/live" />

      <.slide_over slide_over="bottom" title="SlideOver">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.SlideOver.hide_slide_over("bottom")} />
          </div>
        </div>
      </.slide_over>
      """)

    assert html =~ "data-phx-link"
    assert html =~ "phx-click"
    assert html =~ "translate-y-0 absolute inset-x-0 bottom-0"
  end

  test "dark mode" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button label="start" link_type="live_patch" to="/live" />

      <.slide_over slide_over="start" title="SlideOver">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.SlideOver.hide_slide_over("start")} />
          </div>
        </div>
      </.slide_over>
      """)

    assert html =~ "data-phx-link"
    assert html =~ "phx-click"
    assert html =~ "translate-x-0"
    assert html =~ "dark:"
  end

  test "should include additional assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""

      <.slide_over custom-attrs="123" title="SlideOver"></.slide_over>
      """)

    assert html =~ ~s{custom-attrs="123"}
  end
end
