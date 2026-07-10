defmodule PetalComponents.CommandTest do
  use ComponentCase

  import PetalComponents.Command

  test "command renders the hook root with loop data" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.command id="cmd" loop>
        <.command_input />
        <.command_list>
          <.command_item>Calendar</.command_item>
        </.command_list>
      </.command>
      """)

    assert html =~ ~s(id="cmd")
    assert html =~ ~s(phx-hook="PetalCommand")
    assert html =~ ~s(data-loop="true")
    assert html =~ "pc-command"
  end

  test "command_input carries the combobox pattern" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.command_input placeholder="Search..." />
      """)

    assert html =~ ~s(role="combobox")
    assert html =~ ~s(aria-expanded="true")
    assert html =~ ~s(aria-autocomplete="list")
    assert html =~ ~s(autocomplete="off")
    assert html =~ ~s(placeholder="Search...")
    assert html =~ "pc-command__input"
  end

  test "command_list is a labelled listbox" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.command_list label="Actions">hi</.command_list>
      """)

    assert html =~ ~s(role="listbox")
    assert html =~ ~s(aria-label="Actions")
  end

  test "command_empty starts hidden" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.command_empty>No results found.</.command_empty>
      """)

    assert html =~ "data-pc-command-empty"
    assert html =~ "hidden"
    assert html =~ "No results found."
  end

  test "command_group renders a heading" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.command_group heading="Suggestions">items</.command_group>
      """)

    assert html =~ ~s(role="group")
    assert html =~ "data-pc-command-group"
    assert html =~ "Suggestions"
    assert html =~ "pc-command__group-heading"
  end

  test "command_item renders a button by default with value and keywords" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.command_item value="calendar" keywords={["date", "schedule"]}>Calendar</.command_item>
      """)

    assert html =~ "<button"
    assert html =~ ~s(type="button")
    assert html =~ ~s(role="option")
    assert html =~ ~s(aria-selected="false")
    assert html =~ ~s(data-value="calendar")
    assert html =~ ~s(data-keywords="date schedule")
    assert html =~ ~s(tabindex="-1")
  end

  test "command_item with navigate renders a link" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.command_item navigate="/settings">Settings</.command_item>
      """)

    assert html =~ "<a"
    assert html =~ ~s(href="/settings")
    assert html =~ ~s(data-phx-link="redirect")
    refute html =~ "<button"
  end

  test "disabled command_item is marked for the hook and assistive tech" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.command_item disabled>New team</.command_item>
      """)

    assert html =~ ~s(data-disabled="true")
    assert html =~ "disabled"
  end

  test "command_item forwards phx bindings" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.command_item phx-click="run" phx-value-id="7">Run</.command_item>
      """)

    assert html =~ ~s(phx-click="run")
    assert html =~ ~s(phx-value-id="7")
  end

  test "command_separator and command_shortcut render their roles" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <div>
        <.command_separator />
        <.command_shortcut>⌘K</.command_shortcut>
      </div>
      """)

    assert html =~ ~s(role="separator")
    assert html =~ "data-pc-command-separator"
    assert html =~ "pc-command__shortcut"
    assert html =~ "⌘K"
  end

  test "command_dialog wraps the palette in a native dialog with shortcut wiring" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.command_dialog id="cmdk" shortcut="k">
        <.command_input />
        <.command_list>
          <.command_item>Home</.command_item>
        </.command_list>
      </.command_dialog>
      """)

    assert html =~ "<dialog"
    assert html =~ ~s(id="cmdk")
    assert html =~ ~s(phx-hook="PetalCommandDialog")
    assert html =~ ~s(data-shortcut="k")
    assert html =~ ~s(data-reset-on-close="true")
    assert html =~ ~s(id="cmdk-palette")
    assert html =~ "pc-command-dialog"
    # the inner palette must carry the filtering hook - regression guard
    assert html =~ ~s(phx-hook="PetalCommand")
  end

  test "open_command returns a dispatch to the dialog" do
    js = PetalComponents.Command.open_command("cmdk")
    assert js.ops == [["dispatch", %{event: "pc:command-open", to: "#cmdk"}]]
  end
end
