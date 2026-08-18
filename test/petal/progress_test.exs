defmodule PetalComponents.ProgressTest do
  use ComponentCase
  import PetalComponents.Progress

  test "it renders the progress bar correctly" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.progress size="xl" value={10} max={100} label="15%" />
      """)

    assert html =~ "style="
    assert html =~ "width:"

    html =
      rendered_to_string(~H"""
      <.progress color="primary" value={15} max={100} />
      """)

    assert html =~ "pc-progress--primary"

    html =
      rendered_to_string(~H"""
      <.progress color="secondary" value={15} max={100} />
      """)

    assert html =~ "pc-progress--secondary"

    html =
      rendered_to_string(~H"""
      <.progress color="info" value={15} max={100} />
      """)

    assert html =~ "pc-progress--info"

    html =
      rendered_to_string(~H"""
      <.progress color="success" value={15} max={100} />
      """)

    assert html =~ "pc-progress--success"

    html =
      rendered_to_string(~H"""
      <.progress color="warning" value={15} max={100} />
      """)

    assert html =~ "pc-progress--warning"

    html =
      rendered_to_string(~H"""
      <.progress color="danger" value={15} max={100} />
      """)

    assert html =~ "pc-progress--danger"

    html =
      rendered_to_string(~H"""
      <.progress color="gray" value={15} max={100} />
      """)

    assert html =~ "pc-progress--gray"
  end

  test "should include additional assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.progress custom-attrs="123" value={15} max={100} />
      """)

    assert html =~ ~s{custom-attrs="123"}
  end

  test "should round width to 2 decimal places" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.progress value={50} max={100} />
      """)

    assert html =~ "width: 50.0%"

    html =
      rendered_to_string(~H"""
      <.progress value={2} max={3} />
      """)

    assert html =~ "width: 66.67%"
  end

  test "label_position top renders a header row with the percentage" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.progress value={56} label="Upload progress" label_position="top" />
      """)

    assert html =~ "pc-progress__header"
    assert html =~ "Upload progress"
    assert html =~ "56%"
    assert html =~ ~s(aria-valuetext="56%")
  end

  test "status renders a live-announced line under the bar" do
    assigns = %{}

    with_header =
      rendered_to_string(~H"""
      <.progress value={40} label="Upload" label_position="top" status="Downloading assets..." />
      """)

    assert with_header =~ "pc-progress__status"
    assert with_header =~ "Downloading assets..."
    assert with_header =~ ~s(aria-live="polite")

    # without a top label the status still gets a wrapper to live in
    bare =
      rendered_to_string(~H"""
      <.progress value={40} status="Downloading assets..." />
      """)

    assert bare =~ "pc-progress-wrapper"
    assert bare =~ "pc-progress__status"

    # and no status means no wrapper - the bare bar is unchanged
    plain =
      rendered_to_string(~H"""
      <.progress value={40} />
      """)

    refute plain =~ "pc-progress-wrapper"
    refute plain =~ "pc-progress__status"
  end

  test "no value renders an empty, indeterminate bar instead of raising" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.progress />
      """)

    assert html =~ "width: 0.0%"
    refute html =~ "aria-valuenow"
  end

  describe "progress_ring/1" do
    test "renders a track circle and a value arc" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress_ring value={40} />
        """)

      assert html =~ "pc-progress-ring"
      assert html =~ "pc-progress-ring__svg"
      assert html =~ "pc-progress-ring__track"
      assert html =~ "pc-progress-ring__arc"
      # two circles: the track and the arc, on the same geometry
      assert length(Regex.scan(~r/<circle/, html)) == 2
      assert html =~ ~s(stroke="currentColor")
    end

    test "the arc starts at 12 o'clock with round caps" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress_ring value={40} />
        """)

      assert html =~ ~s|transform="rotate(-90 20.0 20.0)"|
      assert html =~ ~s(stroke-linecap="round")
    end

    # md is r=18, so the circumference is 2 * pi * 18 = 113.0973... and the
    # offset is the unfilled slice of it. These three pin the arc maths.
    test "dashoffset walks the circumference from full to zero" do
      assigns = %{}

      empty =
        rendered_to_string(~H"""
        <.progress_ring value={0} />
        """)

      assert empty =~ ~s(stroke-dasharray="113.1")
      assert empty =~ ~s(stroke-dashoffset="113.1")

      partial =
        rendered_to_string(~H"""
        <.progress_ring value={53} />
        """)

      # 113.0973 * (1 - 0.53) = 53.1557
      assert partial =~ ~s(stroke-dasharray="113.1")
      assert partial =~ ~s(stroke-dashoffset="53.16")

      full =
        rendered_to_string(~H"""
        <.progress_ring value={100} />
        """)

      assert full =~ ~s(stroke-dasharray="113.1")
      assert full =~ ~s(stroke-dashoffset="0.0")
    end

    test "max scales the arc the same way it scales the bar" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress_ring value={15} max={30} />
        """)

      # half way, so half the circumference is still hidden
      assert html =~ ~s(stroke-dashoffset="56.55")
      assert html =~ ~s(aria-valuetext="50%")
    end

    test "geometry over 100% clamps so the dash pattern can't wrap" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress_ring value={150} />
        """)

      assert html =~ ~s(stroke-dashoffset="0.0")
      # but the ARIA values still report what was passed
      assert html =~ ~s(aria-valuenow="150")
    end

    test "size sets the viewBox, radius and stroke together" do
      for {size, view_box, radius, stroke} <- [
            {"xs", "0 0 16 16", "6.75", "2.5"},
            {"sm", "0 0 24 24", "10.5", "3"},
            {"md", "0 0 40 40", "18.0", "4"},
            {"lg", "0 0 64 64", "29.0", "6"},
            {"xl", "0 0 96 96", "44.0", "8"}
          ] do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <.progress_ring value={50} size={@size} />
          """)

        assert html =~ ~s(viewBox="#{view_box}")
        assert html =~ ~s(r="#{radius}")
        assert html =~ ~s(stroke-width="#{stroke}")
        assert html =~ "pc-progress-ring--#{size}"
      end
    end

    test "color uses the same vocabulary as the bar" do
      for color <- ~w(primary secondary info success warning danger gray) do
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <.progress_ring value={50} color={@color} />
          """)

        assert html =~ "pc-progress-ring--#{color}"
      end
    end

    test "carries the same ARIA contract as the bar" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress_ring value={53} max={100} label="Storage used" />
        """)

      assert html =~ ~s(role="progressbar")
      assert html =~ ~s(aria-valuemin="0")
      assert html =~ ~s(aria-valuemax="100")
      assert html =~ ~s(aria-valuenow="53")
      assert html =~ ~s(aria-valuetext="53%")
      assert html =~ ~s(aria-label="Storage used")
      # the drawing is decorative, the role on the wrapper does the talking
      assert html =~ ~s(aria-hidden="true")

      unlabelled =
        rendered_to_string(~H"""
        <.progress_ring value={53} />
        """)

      assert unlabelled =~ ~s(aria-label="Progress")
    end

    test "no value renders an empty, indeterminate ring" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress_ring />
        """)

      assert html =~ ~s(stroke-dashoffset="113.1")
      refute html =~ "aria-valuenow"
    end

    test "show_value draws the rounded percentage in the middle" do
      assigns = %{}

      bare =
        rendered_to_string(~H"""
        <.progress_ring value={53} />
        """)

      refute bare =~ "pc-progress-ring__label"

      with_value =
        rendered_to_string(~H"""
        <.progress_ring value={2} max={3} size="lg" show_value />
        """)

      assert with_value =~ "pc-progress-ring__label"
      assert with_value =~ "pc-progress-ring__label--lg"
      assert with_value =~ "67%"
    end

    test "show_value is size-gated: nothing drawn below lg" do
      for size <- ~w(xs sm md) do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <.progress_ring value={53} size={@size} show_value />
          """)

        refute html =~ "pc-progress-ring__label",
               "show_value drew a readout at #{size}, where the hole is too small to read it"

        refute html =~ ">53%<"
        # the percentage still reaches assistive tech, it just isn't drawn
        assert html =~ ~s(aria-valuetext="53%")
      end

      for size <- ~w(lg xl) do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <.progress_ring value={53} size={@size} show_value />
          """)

        assert html =~ "pc-progress-ring__label--#{size}"
        assert html =~ "53%"
      end
    end

    test "the slot is not size-gated - custom middles are the consumer's call" do
      for size <- ~w(xs sm md lg xl) do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <.progress_ring value={12} max={30} size={@size}>
            <span>12/30</span>
          </.progress_ring>
          """)

        assert html =~ "pc-progress-ring__label--#{size}",
               "the slot stopped rendering at #{size}"

        assert html =~ "12/30"
      end
    end

    test "the slot takes over the middle from show_value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress_ring value={12} max={30} show_value>
          <span>12/30</span>
        </.progress_ring>
        """)

      assert html =~ "pc-progress-ring__label"
      assert html =~ "12/30"
      # the percentage stays in aria-valuetext but is not drawn
      refute html =~ "<span>40%</span>"
    end

    test "class merges and extra attrs pass through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress_ring value={50} class="text-emerald-500" custom-attrs="123" />
        """)

      assert html =~ "pc-progress-ring"
      assert html =~ "text-emerald-500"
      assert html =~ ~s{custom-attrs="123"}
    end
  end

  test "a value-less ring is indeterminate: no valuetext, no 0% readout" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.progress_ring show_value />
      """)

    refute html =~ "aria-valuenow"
    refute html =~ "aria-valuetext"
    refute html =~ "0%"

    # the bar's shared renderer had the same leak
    html =
      rendered_to_string(~H"""
      <.progress />
      """)

    refute html =~ "aria-valuetext"
  end
end
