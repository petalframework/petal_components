defmodule PetalComponents.ToggleGroupTest do
  use ComponentCase
  import PetalComponents.ToggleGroup

  test "single select renders a radiogroup of label-wrapped native radios" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.toggle_group id="density" aria_label="Density" value="cozy" on_change="set_density">
        <:item value="compact">Compact</:item>
        <:item value="cozy">Cozy</:item>
        <:item value="comfortable">Comfortable</:item>
      </.toggle_group>
      """)

    assert html =~ ~s(role="radiogroup")
    assert html =~ ~s(aria-label="Density")
    assert html =~ ~s(id="density")
    assert html =~ "pc-toggle-group--md"
    assert html =~ "Compact"
    assert html =~ "Cozy"
    assert html =~ "Comfortable"

    doc = LazyHTML.from_fragment(html)

    assert doc |> LazyHTML.query(~s(input[type="radio"][name="density-toggle"])) |> Enum.count() ==
             3

    assert doc |> LazyHTML.query("label.pc-toggle-group__item") |> Enum.count() == 3
  end

  test "exactly the selected radio is checked" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.toggle_group aria_label="Density" value="cozy" on_change="set_density">
        <:item value="compact">Compact</:item>
        <:item value="cozy">Cozy</:item>
      </.toggle_group>
      """)

    doc = LazyHTML.from_fragment(html)
    assert doc |> LazyHTML.query("input[checked]") |> Enum.count() == 1
    assert doc |> LazyHTML.query(~s(input[checked][value="cozy"])) |> Enum.count() == 1
  end

  test "checked comparison survives the phx-value string round-trip" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.toggle_group aria_label="Page size" value={10} on_change="set_size">
        <:item value={6}>6</:item>
        <:item value={10}>10</:item>
      </.toggle_group>
      """)

    assert html
           |> LazyHTML.from_fragment()
           |> LazyHTML.query(~s(input[checked][value="10"]))
           |> Enum.count() ==
             1

    html_after_round_trip =
      rendered_to_string(~H"""
      <.toggle_group aria_label="Page size" value="10" on_change="set_size">
        <:item value={6}>6</:item>
        <:item value={10}>10</:item>
      </.toggle_group>
      """)

    assert html_after_round_trip
           |> LazyHTML.from_fragment()
           |> LazyHTML.query(~s(input[checked][value="10"]))
           |> Enum.count() == 1
  end

  test "single-select radios detach from surrounding forms" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.toggle_group id="density" aria_label="Density" value="cozy" on_change="x">
        <:item value="compact">Compact</:item>
        <:item value="cozy">Cozy</:item>
      </.toggle_group>
      """)

    assert html
           |> LazyHTML.from_fragment()
           |> LazyHTML.query(~s(input[form="density-no-form"]))
           |> Enum.count() == 2
  end

  test "multiple renders aria-pressed buttons and presses every member of the value list" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.toggle_group multiple aria_label="Formatting" value={["bold", "italic"]} on_change="fmt">
        <:item value="bold">B</:item>
        <:item value="italic">I</:item>
        <:item value="underline">U</:item>
      </.toggle_group>
      """)

    assert html =~ ~s(role="group")
    refute html =~ ~s(type="radio")

    doc = LazyHTML.from_fragment(html)
    pressed_text = doc |> LazyHTML.query(~s([aria-pressed="true"])) |> LazyHTML.text()

    assert pressed_text =~ "B"
    assert pressed_text =~ "I"
    refute pressed_text =~ "U"

    assert doc |> LazyHTML.query(~s(button[type="button"])) |> Enum.count() == 3
  end

  test "nothing is selected when value is nil" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.toggle_group aria_label="Density" on_change="set_density">
        <:item value="compact">Compact</:item>
      </.toggle_group>
      """)

    refute html =~ "checked"
  end

  test "on_change wires phx-click and phx-value-toggle onto every option in both modes" do
    assigns = %{}

    single =
      rendered_to_string(~H"""
      <.toggle_group aria_label="Density" value="cozy" on_change="set_density">
        <:item value="compact">Compact</:item>
        <:item value="cozy">Cozy</:item>
      </.toggle_group>
      """)

    assert single
           |> LazyHTML.from_fragment()
           |> LazyHTML.query(~s(input[phx-click="set_density"][phx-value-toggle]))
           |> Enum.count() == 2

    multi =
      rendered_to_string(~H"""
      <.toggle_group multiple aria_label="Formatting" value={[]} on_change="fmt">
        <:item value="bold">B</:item>
      </.toggle_group>
      """)

    assert multi =~ ~s(phx-click="fmt")
    assert multi =~ ~s(phx-value-toggle="bold")
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

  test "group disabled disables every option; item disabled only its own" do
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
           |> LazyHTML.query("input[disabled]")
           |> Enum.count() == 2

    one_disabled =
      rendered_to_string(~H"""
      <.toggle_group multiple aria_label="Fmt" value={[]} on_change="noop">
        <:item value="bold" disabled>B</:item>
        <:item value="italic">I</:item>
      </.toggle_group>
      """)

    assert one_disabled
           |> LazyHTML.from_fragment()
           |> LazyHTML.query("button[disabled]")
           |> Enum.count() == 1
  end

  test "size, variant and custom classes land on the rail and items" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.toggle_group
        aria_label="Density"
        size="sm"
        variant="outline"
        class="w-full"
        value="a"
        on_change="x"
      >
        <:item value="a" class="font-bold">A</:item>
      </.toggle_group>
      """)

    assert html =~ "pc-toggle-group--sm"
    assert html =~ "pc-toggle-group--outline"
    assert html =~ "w-full"
    assert html =~ "font-bold"
  end

  test "each variant lands its own modifier, solid stays unmodified" do
    assigns = %{}

    for {variant, expected} <- [
          {"solid", nil},
          {"outline", "pc-toggle-group--outline"},
          {"accent", "pc-toggle-group--accent"}
        ] do
      assigns = Map.put(assigns, :variant, variant)

      html =
        rendered_to_string(~H"""
        <.toggle_group variant={@variant} aria_label="V" value="a" on_change="x">
          <:item value="a">A</:item>
        </.toggle_group>
        """)

      if expected do
        assert html =~ expected
      else
        refute html =~ "pc-toggle-group--outline"
        refute html =~ "pc-toggle-group--accent"
      end
    end
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
