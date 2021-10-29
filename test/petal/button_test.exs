defmodule Petal.ButtonTest do
  use ComponentCase

  test "button" do
    html =
      Petal.Button.render(%{
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
      Petal.Button.render(%{
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
