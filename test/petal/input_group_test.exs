defmodule PetalComponents.InputGroupTest do
  @moduledoc """
  Tests for PetalComponents.InputGroup - the shared-surface wrapper for
  inputs with leading/trailing addons.
  """

  use ComponentCase
  import PetalComponents.InputGroup
  import PetalComponents.Input

  test "renders input with leading text addon" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input_group>
        <:leading>https://</:leading>
        <.input type="text" name="domain" value="" />
      </.input_group>
      """)

    assert html =~ "pc-input-group"
    assert html =~ "pc-input-group__addon--leading"
    assert html =~ "https://"
    assert html =~ "pc-text-input"
    refute html =~ "pc-input-group__addon--trailing"
  end

  test "renders trailing addon" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input_group>
        <.input type="number" name="amount" value="" />
        <:trailing>USD</:trailing>
      </.input_group>
      """)

    assert html =~ "pc-input-group__addon--trailing"
    assert html =~ "USD"
  end

  test "renders both addons and passes through extra attributes" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input_group id="price-group" class="max-w-xs">
        <:leading>$</:leading>
        <.input type="number" name="amount" value="" />
        <:trailing>USD</:trailing>
      </.input_group>
      """)

    assert_attribute(html, "id", "price-group")
    assert_has_class(html, "max-w-xs")
    assert html =~ "$"
    assert html =~ "USD"
  end
end
