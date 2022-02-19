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

    assert html =~ "bg-blue"

    html =
      rendered_to_string(~H"""
      <.progress color="secondary" value={15} max={100} />
      """)

    assert html =~ "bg-pink"

    html =
      rendered_to_string(~H"""
      <.progress color="info" value={15} max={100} />
      """)

    assert html =~ "bg-blue"

    html =
      rendered_to_string(~H"""
      <.progress color="success" value={15} max={100} />
      """)

    assert html =~ "bg-green"

    html =
      rendered_to_string(~H"""
      <.progress color="warning" value={15} max={100} />
      """)

    assert html =~ "bg-yellow"

    html =
      rendered_to_string(~H"""
      <.progress color="danger" value={15} max={100} />
      """)

    assert html =~ "bg-red"
  end

  test "should include additional assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.progress custom-attrs="123" value={15} max={100} />
      """)

    assert html =~ ~s{custom-attrs="123"}
  end
end
