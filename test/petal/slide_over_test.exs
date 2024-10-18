defmodule PetalComponents.SlideOverTest do
  use ComponentCase
  import PetalComponents.SlideOver
  import PetalComponents.Button
  import PetalComponents.Form

  test "slide_over" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button label="left" link_type="live_patch" to="/live" />

      <.slide_over title="SlideOver" origin="left">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.SlideOver.hide_slide_over("left")} />
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
      <.button label="right" link_type="live_patch" to="/" />

      <.slide_over origin="right" title="SlideOver">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.SlideOver.hide_slide_over("right")} />
          </div>
        </div>
      </.slide_over>
      """)

    assert html =~ "data-phx-link"
    assert html =~ "phx-click"
    assert html =~ "fixed right-0 inset-y-0"

    html =
      rendered_to_string(~H"""
      <.button label="top" link_type="live_patch" to="/live" />

      <.slide_over origin="top" title="SlideOver">
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
    assert html =~ "fixed inset-x-0 top-0"

    html =
      rendered_to_string(~H"""
      <.button label="bottom" link_type="live_patch" to="/live" />

      <.slide_over origin="bottom" title="SlideOver">
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
    assert html =~ "fixed inset-x-0 bottom-0"
  end

  test "dark mode" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button label="left" link_type="live_patch" to="/live" />

      <.slide_over origin="left" title="SlideOver">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.SlideOver.hide_slide_over("left")} />
          </div>
        </div>
      </.slide_over>
      """)

    assert html =~ "data-phx-link"
    assert html =~ "phx-click"
    assert html =~ "translate-x-0"
    assert html =~ "pc-slideover__overlay"
  end

  test "should include additional assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.slide_over custom-attrs="123" title="SlideOver"></.slide_over>
      """)

    assert html =~ ~s{custom-attrs="123"}
  end

  test "close_on_click_away" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.slide_over></.slide_over>
      """)

    assert html =~ ~s{phx-click-away}

    html =
      rendered_to_string(~H"""
      <.slide_over close_on_click_away={false}></.slide_over>
      """)

    refute html =~ ~s{phx-click-away}
  end

  test "close_on_escape" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.slide_over></.slide_over>
      """)

    assert html =~ ~s{phx-window-keydown}

    html =
      rendered_to_string(~H"""
      <.slide_over close_on_escape={false}></.slide_over>
      """)

    refute html =~ ~s{phx-window-keydown}
  end
end
