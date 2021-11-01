defmodule PetalComponents.ButtonTest do
  use ComponentCase

  test "button" do
    html =
      PetalComponents.Button.render(%{
        __changed__: "",
        type: "a",
        label: "Press me",
        href: "/"
      })
      |> heex_to_string()

    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href"
  end

  test "button with phx-click" do
    html =
      PetalComponents.Button.render(%{
        __changed__: "",
        type: "a",
        label: "Press me",
        href: "/",
        "phx-click": "click_event"
      })
      |> heex_to_string()

    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "phx-click"
  end
end
