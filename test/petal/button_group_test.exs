defmodule PetalComponents.ButtonGroupTest do
  use ComponentCase
  import PetalComponents.ButtonGroup

  test "button_group buttons with inner_block" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button_group id="hello-group" aria_label="My options">
        <:button phx-click="change_size" phx-value-size="md">MD</:button>
        <:button disabled phx-click="change_size" phx-value-size="lg">LG</:button>
        <:button phx-click="change_size" phx-value-size="xl">XL</:button>
      </.button_group>
      """)

    assert html =~ ~s{<div aria-label="My options" role="group" id="hello-group"}
    assert html =~ ~s{phx-click="change_size" phx-value-size="md">}
    assert html =~ "MD"
    assert html =~ ~s{<button disabled aria-disabled}
    assert html =~ "LG"
    assert html =~ ~s{phx-click="change_size" phx-value-size="xl">}
    assert html =~ "XL"
    assert html =~ "</div>"
  end

  test "button_group buttons with labels only" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button_group aria_label="a11y is good">
        <:button label="MD" phx-click="change_size" phx-value-size="md" />
        <:button label="LG" disabled phx-click="change_size" phx-value-size="lg" />
        <:button label="XL" phx-click="change_size" phx-value-size="xl" />
      </.button_group>
      """)

    assert html =~ ~s{<div aria-label="a11y is good" role="group" id=}
    assert html =~ ~s{phx-click="change_size" phx-value-size="md">}
    assert html =~ "MD"
    assert html =~ ~s{<button disabled aria-disabled}
    assert html =~ "LG"
    assert html =~ ~s{phx-click="change_size" phx-value-size="xl">}
    assert html =~ "XL"
    assert html =~ "</div>"
  end

  test "button_group links with inner_block" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button_group aria_label="links up in here">
        <:button kind="link" href="/path-one">One</:button>
        <:button kind="link" patch="/path-two">Two</:button>
        <:button kind="link" navigate="/path-three">Three</:button>
        <:button kind="link" disabled navigate="/path-disabled">Disabled as button</:button>
      </.button_group>
      """)

    assert html =~ ~s{<div aria-label="links up in here" role="group"}
    assert html =~ ~s{<a href="/path-one" class=}
    assert html =~ "One"
    assert html =~ ~s{<a href="/path-two" data-phx-link="patch" data-phx-link-state="push"}
    assert html =~ "Two"
    assert html =~ ~s{<a href="/path-three" data-phx-link="redirect" data-phx-link-state="push"}
    assert html =~ "Three"

    refute html =~
             ~s{<a href="/path-disabled" data-phx-link="redirect" data-phx-link-state="push"}

    assert html =~ ~s{<button disabled aria-disabled}
    assert html =~ "Disabled as button"
    assert html =~ "</div>"
  end

  test "button_group links with labels only" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button_group aria_label="links up in here">
        <:button label="One" kind="link" href="/path-one" />
        <:button label="Two" kind="link" patch="/path-two" />
        <:button label="Three" kind="link" navigate="/path-three" />
        <:button label="Disabled as button" kind="link" disabled navigate="/path-disabled" />
      </.button_group>
      """)

    assert html =~ ~s{<div aria-label="links up in here" role="group"}
    assert html =~ ~s{<a href="/path-one" class=}
    assert html =~ "One"
    assert html =~ ~s{<a href="/path-two" data-phx-link="patch" data-phx-link-state="push"}
    assert html =~ "Two"
    assert html =~ ~s{<a href="/path-three" data-phx-link="redirect" data-phx-link-state="push"}
    assert html =~ "Three"

    refute html =~
             ~s{<a href="/path-disabled" data-phx-link="redirect" data-phx-link-state="push"}

    assert html =~ ~s{<button disabled aria-disabled}
    assert html =~ "Disabled as button"
    assert html =~ "</div>"
  end
end
