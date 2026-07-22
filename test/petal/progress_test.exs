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
end
