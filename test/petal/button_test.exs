defmodule Petal.ButtonTest do
  use ComponentCase

  test "button" do
    html =
      Petal.Button.render(%{type: "a", label: "Press me", href: "/"})
      |> heex_to_string()

    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href"
  end
end
