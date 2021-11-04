defmodule PetalComponents.ButtonTest do
  use ComponentCase
  alias PetalComponents.Button

  test "Button.button" do
    html = render_component(Button, :button, %{label: "Press me"})
    assert html =~ "Press me"
  end

  test "Button.button with phx-click" do
    html =
      render_component(Button, :button, %{
        label: "Press me",
        "phx-click": "click_event"
      })

    assert html =~ "Press me"
    assert html =~ "phx-click"
  end

  test "button.a" do
    html = render_component(Button, :a, %{label: "Press me", href: "/"})
    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href"
  end

  test "button_a with phx-click" do
    html =
      render_component(Button, :a, %{
        label: "Press me",
        href: "/",
        "phx-click": "click_event"
      })

    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "phx-click"
  end

  test "button.patch" do
    html = render_component(Button, :patch, %{label: "Press me", href: "/"})
    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href"
  end

  test "button.patch with phx-click" do
    html =
      render_component(Button, :patch, %{
        label: "Press me",
        href: "/",
        "phx-click": "click_event"
      })

    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "phx-click"
  end

  test "button.redirect" do
    html = render_component(Button, :redirect, %{label: "Press me", href: "/"})
    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href"
  end

  test "button.redirect with phx-click" do
    html =
      render_component(Button, :redirect, %{
        label: "Press me",
        href: "/",
        "phx-click": "click_event"
      })

    assert html =~ "Press me"
    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "phx-click"
  end
end
