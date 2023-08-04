defmodule PetalComponents.InputTest do
  use ComponentCase
  import PetalComponents.Input

  test "field standard inputs" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.input field={@form[:name]} type="text" />
        <.input field={@form[:name]} type="color" />
        <.input field={@form[:name]} type="date" />
        <.input field={@form[:name]} type="datetime-local" />
        <.input field={@form[:name]} type="email" />
        <.input field={@form[:name]} type="file" />
        <.input field={@form[:name]} type="hidden" />
        <.input field={@form[:name]} type="month" />
        <.input field={@form[:name]} type="number" />
        <.input field={@form[:name]} type="password" />
        <.input field={@form[:name]} type="range" />
        <.input field={@form[:name]} type="search" />
        <.input field={@form[:name]} type="tel" />
        <.input field={@form[:name]} type="text" />
        <.input field={@form[:name]} type="time" />
        <.input field={@form[:name]} type="url" />
        <.input field={@form[:name]} type="week" />
      </.form>
      """)

    assert html =~ "input"
    assert html =~ ~s|type="text"|
    assert html =~ ~s|type="color"|
    assert html =~ ~s|type="date"|
    assert html =~ ~s|type="datetime-local"|
    assert html =~ ~s|type="email"|
    assert html =~ ~s|type="file"|
    assert html =~ ~s|type="hidden"|
    assert html =~ ~s|type="month"|
    assert html =~ ~s|type="number"|
    assert html =~ ~s|type="password"|
    assert html =~ ~s|type="range"|
    assert html =~ ~s|type="search"|
    assert html =~ ~s|type="tel"|
    assert html =~ ~s|type="text"|
    assert html =~ ~s|type="time"|
    assert html =~ ~s|type="url"|
    assert html =~ ~s|type="week"|
  end

  test "input can be passed a class attribute" do
    assigns = %{form: to_form(%{}, as: :user)}

    html =
      rendered_to_string(~H"""
      <.form for={@form}>
        <.input field={@form[:name]} class="rounted-r-none" type="text" />
      </.form>
      """)

    assert html =~ "rounted-r-none"
  end
end
