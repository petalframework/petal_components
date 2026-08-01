defmodule PetalComponents.ToggleGroupTest do
  use ComponentCase
  import PetalComponents.ToggleGroup

  test "renders the rail with role, label and every item" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.toggle_group id="density" aria_label="Density" value="cozy" on_change="set_density">
        <:item value="compact">Compact</:item>
        <:item value="cozy">Cozy</:item>
        <:item value="comfortable">Comfortable</:item>
      </.toggle_group>
      """)

    assert html =~ ~s(role="group")
    assert html =~ ~s(aria-label="Density")
    assert html =~ ~s(id="density")
    assert html =~ "pc-toggle-group--md"
    assert html =~ "Compact"
    assert html =~ "Cozy"
    assert html =~ "Comfortable"
  end

  test "exactly the selected item is pressed" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.toggle_group aria_label="Density" value="cozy" on_change="set_density">
        <:item value="compact">Compact</:item>
        <:item value="cozy">Cozy</:item>
      </.toggle_group>
      """)

    doc = LazyHTML.from_fragment(html)
    pressed = LazyHTML.query(doc, ~s([aria-pressed="true"]))
    unpressed = LazyHTML.query(doc, ~s([aria-pressed="false"]))

    assert LazyHTML.text(pressed) =~ "Cozy"
    assert LazyHTML.text(unpressed) =~ "Compact"
  end

  test "pressed comparison survives the phx-value string round-trip" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.toggle_group aria_label="Page size" value={10} on_change="set_size">
        <:item value={6}>6</:item>
        <:item value={10}>10</:item>
      </.toggle_group>
      """)

    doc = LazyHTML.from_fragment(html)
    assert doc |> LazyHTML.query(~s([aria-pressed="true"])) |> LazyHTML.text() =~ "10"

    html_after_round_trip =
      rendered_to_string(~H"""
      <.toggle_group aria_label="Page size" value="10" on_change="set_size">
        <:item value={6}>6</:item>
        <:item value={10}>10</:item>
      </.toggle_group>
      """)

    doc = LazyHTML.from_fragment(html_after_round_trip)
    assert doc |> LazyHTML.query(~s([aria-pressed="true"])) |> LazyHTML.text() =~ "10"
  end

  test "multiple presses every member of the value list and only those" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.toggle_group multiple aria_label="Formatting" value={["bold", "italic"]} on_change="fmt">
        <:item value="bold">B</:item>
        <:item value="italic">I</:item>
        <:item value="underline">U</:item>
      </.toggle_group>
      """)

    doc = LazyHTML.from_fragment(html)
    pressed_text = doc |> LazyHTML.query(~s([aria-pressed="true"])) |> LazyHTML.text()

    assert pressed_text =~ "B"
    assert pressed_text =~ "I"
    refute pressed_text =~ "U"
  end

  test "nothing is pressed when value is nil" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.toggle_group aria_label="Density" on_change="set_density">
        <:item value="compact">Compact</:item>
      </.toggle_group>
      """)

    refute html =~ ~s(aria-pressed="true")
  end

  test "on_change wires phx-click and phx-value-toggle onto every item" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.toggle_group aria_label="Density" value="cozy" on_change="set_density">
        <:item value="compact">Compact</:item>
        <:item value="cozy">Cozy</:item>
      </.toggle_group>
      """)

    assert html =~ ~s(phx-click="set_density")
    assert html =~ ~s(phx-value-toggle="compact")
    assert html =~ ~s(phx-value-toggle="cozy")
  end

  test "items accept their own bindings when on_change is omitted" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.toggle_group aria_label="View" value="grid">
        <:item value="grid" phx-click="custom_event" phx-target="#me">Grid</:item>
      </.toggle_group>
      """)

    assert html =~ ~s(phx-click="custom_event")
    assert html =~ ~s(phx-target="#me")
    refute html =~ ~s(phx-click="")
  end

  test "group disabled disables every item; item disabled only its own" do
    assigns = %{}

    all_disabled =
      rendered_to_string(~H"""
      <.toggle_group disabled aria_label="Density" value="cozy" on_change="noop">
        <:item value="compact">Compact</:item>
        <:item value="cozy">Cozy</:item>
      </.toggle_group>
      """)

    assert all_disabled
           |> LazyHTML.from_fragment()
           |> LazyHTML.query("button[disabled]")
           |> Enum.count() == 2

    one_disabled =
      rendered_to_string(~H"""
      <.toggle_group aria_label="Density" value="cozy" on_change="noop">
        <:item value="compact" disabled>Compact</:item>
        <:item value="cozy">Cozy</:item>
      </.toggle_group>
      """)

    assert one_disabled
           |> LazyHTML.from_fragment()
           |> LazyHTML.query("button[disabled]")
           |> Enum.count() == 1
  end

  test "size and custom classes land on the rail and items" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.toggle_group aria_label="Density" size="sm" class="w-full" value="a" on_change="x">
        <:item value="a" class="font-bold">A</:item>
      </.toggle_group>
      """)

    assert html =~ "pc-toggle-group--sm"
    assert html =~ "w-full"
    assert html =~ "font-bold"
  end

  test "every item is type=button so a surrounding form is never submitted" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.toggle_group aria_label="Density" value="a" on_change="x">
        <:item value="a">A</:item>
        <:item value="b">B</:item>
      </.toggle_group>
      """)

    assert html
           |> LazyHTML.from_fragment()
           |> LazyHTML.query(~s(button[type="button"]))
           |> Enum.count() == 2
  end

  test "generates a unique id when none is passed" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.toggle_group aria_label="Density" value="a" on_change="x">
        <:item value="a">A</:item>
      </.toggle_group>
      """)

    assert html =~ ~s(id="c-toggle-group-)
  end
end
