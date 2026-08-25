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

    assert html =~ "id=\"slide-over\""
    assert html =~ "slide-over-overlay"
    assert html =~ "slide-over-content"

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

  test "slide_over with default id" do
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

    assert html =~ "id=\"slide-over\""
    assert html =~ "slide-over-overlay"
    assert html =~ "slide-over-content"
  end

  test "slide_over with custom id" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button label="left" link_type="live_patch" to="/live" />

      <.slide_over id="bert" title="SlideOver" origin="left">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.SlideOver.hide_slide_over("left")} />
          </div>
        </div>
      </.slide_over>
      """)

    assert html =~ "id=\"bert\""
    assert html =~ "bert-overlay"
    assert html =~ "bert-content"
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

  test "description and footer slot render with aria wiring" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.slide_over id="profile" title="Edit profile" description="Changes save when you submit.">
        Body
        <:footer>
          <button>Save</button>
        </:footer>
      </.slide_over>
      """)

    assert html =~ "Changes save when you submit."
    assert html =~ "pc-slideover__description"
    assert html =~ ~s(aria-labelledby="profile-title")
    assert html =~ ~s(aria-describedby="profile-description")
    assert html =~ "pc-slideover__footer"
    assert html =~ "Save"
  end

  describe "bottom-sheet drawer mode" do
    test "origin=bottom shows the grab handle by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slide_over id="sheet" origin="bottom" title="Filters">Body</.slide_over>
        """)

      assert html =~ "pc-slideover__handle"
      assert html =~ "pc-slideover__handle__pill"
      assert html =~ "data-pc-drawer-handle"
    end

    test "the handle is decorative - aria-hidden and carrying the handle class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slide_over id="sheet" origin="bottom" title="Filters">Body</.slide_over>
        """)

      handle =
        html
        |> LazyHTML.from_fragment()
        |> LazyHTML.query(".pc-slideover__handle")

      assert Enum.count(handle) == 1
      assert LazyHTML.attribute(handle, "aria-hidden") == ["true"]
    end

    test "handle={false} removes the handle from a bottom sheet" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slide_over id="sheet" origin="bottom" handle={false} title="Filters">Body</.slide_over>
        """)

      refute html =~ "pc-slideover__handle"
    end

    test "an explicit handle={true} wins on a side sheet" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slide_over id="sheet" origin="right" handle title="Filters">Body</.slide_over>
        """)

      assert html =~ "pc-slideover__handle"
    end

    test "side and top origins get no handle by default" do
      assigns = %{}

      for origin <- ~w(left right top) do
        assigns = Map.put(assigns, :origin, origin)

        html =
          rendered_to_string(~H"""
          <.slide_over id="sheet" origin={@origin} title="Filters">Body</.slide_over>
          """)

        refute html =~ "pc-slideover__handle"
      end
    end

    test "only the bottom origin gets the drawer box modifier" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slide_over id="sheet" origin="bottom" title="Filters">Body</.slide_over>
        """)

      assert html =~ "pc-slideover__box--drawer"

      for origin <- ~w(left right top) do
        assigns = Map.put(assigns, :origin, origin)

        html =
          rendered_to_string(~H"""
          <.slide_over id="sheet" origin={@origin} title="Filters">Body</.slide_over>
          """)

        refute html =~ "pc-slideover__box--drawer"
      end
    end

    test "a draggable bottom sheet attaches the hook and its dismiss command" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slide_over id="sheet" origin="bottom" title="Filters">Body</.slide_over>
        """)

      content = html |> LazyHTML.from_fragment() |> LazyHTML.query("#sheet-content")

      assert LazyHTML.attribute(content, "phx-hook") == ["PetalDrawer"]
      assert LazyHTML.attribute(content, "data-drag-dismiss") == ["true"]
      # dragging closes through the same command as escape and the close button
      assert [command] = LazyHTML.attribute(content, "data-pc-drawer-hide")
      assert command =~ "close_slide_over"
    end

    test "the drag dismiss command carries close_slide_over_target" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slide_over id="sheet" origin="bottom" close_slide_over_target="#lc" title="Filters">
          Body
        </.slide_over>
        """)

      content = html |> LazyHTML.from_fragment() |> LazyHTML.query("#sheet-content")
      assert [command] = LazyHTML.attribute(content, "data-pc-drawer-hide")
      assert command =~ "#lc"
    end

    test "snap_points and initial_snap emit the hook config" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slide_over id="sheet" origin="bottom" snap_points={[0.4, 0.9]} initial_snap={0.4}>
          Body
        </.slide_over>
        """)

      content = html |> LazyHTML.from_fragment() |> LazyHTML.query("#sheet-content")

      assert LazyHTML.attribute(content, "phx-hook") == ["PetalDrawer"]
      assert LazyHTML.attribute(content, "data-snap-points") == ["0.4,0.9"]
      assert LazyHTML.attribute(content, "data-initial-snap") == ["0.4"]
      # the sheet is sized to its tallest snap so the hook only ever translates
      assert LazyHTML.attribute(content, "style") == ["height: 90dvh"]
    end

    test "a fractional tallest snap keeps its decimals in the height" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slide_over id="sheet" origin="bottom" snap_points={[0.25, 0.755]}>Body</.slide_over>
        """)

      content = html |> LazyHTML.from_fragment() |> LazyHTML.query("#sheet-content")

      assert LazyHTML.attribute(content, "style") == ["height: 75.5dvh"]
    end

    test "snap points are sorted and initial_snap defaults to the lowest" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slide_over id="sheet" origin="bottom" snap_points={[0.9, 0.35]}>Body</.slide_over>
        """)

      content = html |> LazyHTML.from_fragment() |> LazyHTML.query("#sheet-content")

      assert LazyHTML.attribute(content, "data-snap-points") == ["0.35,0.9"]
      assert LazyHTML.attribute(content, "data-initial-snap") == ["0.35"]
    end

    test "an initial_snap outside snap_points falls back to the lowest point" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slide_over id="sheet" origin="bottom" snap_points={[0.4, 0.9]} initial_snap={0.7}>
          Body
        </.slide_over>
        """)

      content = html |> LazyHTML.from_fragment() |> LazyHTML.query("#sheet-content")
      assert LazyHTML.attribute(content, "data-initial-snap") == ["0.4"]
    end

    test "a plain bottom sheet with nothing pointer-driven attaches no hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slide_over id="sheet" origin="bottom" drag_to_dismiss={false} title="Filters">
          Body
        </.slide_over>
        """)

      content = html |> LazyHTML.from_fragment() |> LazyHTML.query("#sheet-content")

      assert LazyHTML.attribute(content, "phx-hook") == []
      assert LazyHTML.attribute(content, "data-drag-dismiss") == []
      assert LazyHTML.attribute(content, "data-pc-drawer-hide") == []
      # it is still a drawer visually - just not a draggable one
      assert html =~ "pc-slideover__box--drawer"
      assert html =~ "pc-slideover__handle"
    end

    test "snap points alone attach the hook even with drag_to_dismiss off" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slide_over id="sheet" origin="bottom" drag_to_dismiss={false} snap_points={[0.4, 0.9]}>
          Body
        </.slide_over>
        """)

      content = html |> LazyHTML.from_fragment() |> LazyHTML.query("#sheet-content")

      assert LazyHTML.attribute(content, "phx-hook") == ["PetalDrawer"]
      assert LazyHTML.attribute(content, "data-drag-dismiss") == []
    end

    test "scale_background opts in through a data attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slide_over id="sheet" origin="bottom" scale_background title="Share">Body</.slide_over>
        """)

      content = html |> LazyHTML.from_fragment() |> LazyHTML.query("#sheet-content")

      assert LazyHTML.attribute(content, "data-scale-background") == ["true"]
      assert LazyHTML.attribute(content, "phx-hook") == ["PetalDrawer"]
    end

    test "scale_background is off by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slide_over id="sheet" origin="bottom" title="Share">Body</.slide_over>
        """)

      content = html |> LazyHTML.from_fragment() |> LazyHTML.query("#sheet-content")
      assert LazyHTML.attribute(content, "data-scale-background") == []
    end

    test "side origins never attach the hook, whatever the drawer attrs say" do
      assigns = %{}

      for origin <- ~w(left right top) do
        assigns = Map.put(assigns, :origin, origin)

        html =
          rendered_to_string(~H"""
          <.slide_over
            id="sheet"
            origin={@origin}
            snap_points={[0.4, 0.9]}
            initial_snap={0.4}
            scale_background
          >
            Body
          </.slide_over>
          """)

        content = html |> LazyHTML.from_fragment() |> LazyHTML.query("#sheet-content")

        assert LazyHTML.attribute(content, "phx-hook") == []
        assert LazyHTML.attribute(content, "data-snap-points") == []
        assert LazyHTML.attribute(content, "data-initial-snap") == []
        assert LazyHTML.attribute(content, "data-scale-background") == []
        assert LazyHTML.attribute(content, "data-drag-dismiss") == []
      end
    end

    test "the drawer leaves the dialog semantics exactly as they were" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slide_over id="sheet" origin="bottom" title="Filters" description="Narrow the list">
          Body
          <:footer>
            <button>Apply</button>
          </:footer>
        </.slide_over>
        """)

      dialog = html |> LazyHTML.from_fragment() |> LazyHTML.query("[role=dialog]")

      assert LazyHTML.attribute(dialog, "aria-modal") == ["true"]
      assert LazyHTML.attribute(dialog, "aria-labelledby") == ["sheet-title"]
      assert LazyHTML.attribute(dialog, "aria-describedby") == ["sheet-description"]
      assert html =~ "phx-window-keydown"
      assert html =~ "phx-click-away"
      assert html =~ "pc-slideover__footer"
    end
  end

  describe "unknown origin fallback" do
    # The attr values: check only covers literal origins, so a runtime
    # value sails through - these pin that it degrades to the default
    # direction (right) instead of raising CaseClauseError.
    test "a runtime origin outside the known values renders as the default" do
      assigns = %{origin: "sideways"}

      html =
        rendered_to_string(~H"""
        <.slide_over origin={@origin} title="SlideOver">
          Body
        </.slide_over>
        """)

      assert html =~ "fixed right-0 inset-y-0"
      assert html =~ "ml-10"
      assert html =~ "pc-slideover-anim-in-right"
      refute html =~ "sideways"
    end

    test "an explicit nil origin renders as the default" do
      assigns = %{origin: nil}

      html =
        rendered_to_string(~H"""
        <.slide_over origin={@origin} title="SlideOver">
          Body
        </.slide_over>
        """)

      assert html =~ "fixed right-0 inset-y-0"
    end

    test "an unknown origin never opts into drawer mode" do
      assigns = %{origin: "bototm"}

      html =
        rendered_to_string(~H"""
        <.slide_over origin={@origin} title="SlideOver" snap_points={[0.4, 0.9]}>
          Body
        </.slide_over>
        """)

      refute html =~ "pc-slideover__handle"
      refute html =~ "phx-hook"
    end

    test "show_slide_over and hide_slide_over accept unknown origins" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button label="toggle" phx-click={PetalComponents.SlideOver.show_slide_over("diagonal")} />
        <.button label="close" phx-click={PetalComponents.SlideOver.hide_slide_over("diagonal")} />
        """)

      assert html =~ "pc-slideover-anim-in-right"
      assert html =~ "pc-slideover-anim-out-right"
      assert html =~ "translate-x-full"
    end
  end
end
