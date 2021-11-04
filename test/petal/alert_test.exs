defmodule PetalComponents.AlertTest do
  use ComponentCase
  alias PetalComponents.Alert

  @tag :wip
  test "it renders colors and icon correctly" do
    html = render_component(Alert, :alert, %{state: "info", label: "Info alert"})
    assert html =~ "Info alert"
    assert html =~ "<svg"
    assert html =~ "text-blue"

    html = render_component(Alert, :alert, %{state: "warning", label: "Label"})
    assert html =~ "text-yellow"
    html = render_component(Alert, :alert, %{state: "danger", label: "Label"})
    assert html =~ "text-red"
    html = render_component(Alert, :alert, %{state: "success", label: "Label"})
    assert html =~ "text-green"
  end

  test "default state is info" do
    html = render_component(Alert, :alert, %{label: "Label"})
    assert html =~ "text-blue"
  end
end
