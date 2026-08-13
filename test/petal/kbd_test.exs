defmodule PetalComponents.KbdTest do
  use ComponentCase
  import PetalComponents.Kbd

  test "renders a semantic kbd element with the shared chip class" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kbd>K</.kbd>
      """)

    assert html =~ "<kbd"
    assert html =~ "</kbd>"
    assert_has_class(html, "pc-kbd")
    assert html =~ "K"
  end

  test "defaults to the md size and emits a class for both sizes" do
    assigns = %{}

    default =
      rendered_to_string(~H"""
      <.kbd>K</.kbd>
      """)

    small =
      rendered_to_string(~H"""
      <.kbd size="sm">K</.kbd>
      """)

    assert_has_class(default, "pc-kbd--md")
    refute_has_class(default, "pc-kbd--sm")
    assert_has_class(small, "pc-kbd--sm")
    refute_has_class(small, "pc-kbd--md")
  end

  test "class and rest pass through to the chip" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kbd class="ml-auto" data-role="hint" title="Shortcut">K</.kbd>
      """)

    assert_has_class(html, "pc-kbd")
    assert_has_class(html, "ml-auto")
    assert_attribute(html, "data-role", "hint")
    assert_attribute(html, "title", "Shortcut")
  end

  test "keys renders one kbd per key inside a group" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kbd keys={["cmd", "shift", "P"]} />
      """)

    doc = LazyHTML.from_fragment(html)

    assert doc |> LazyHTML.query(".pc-kbd-group") |> Enum.count() == 1
    assert doc |> LazyHTML.query("kbd.pc-kbd") |> Enum.count() == 3
  end

  test "separators sit between keys only, and are hidden from assistive tech" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kbd keys={["cmd", "shift", "P"]} />
      """)

    separators =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(".pc-kbd-group__separator")

    # three keys, two separators - never a leading or trailing one
    assert Enum.count(separators) == 2

    assert separators |> LazyHTML.attribute("aria-hidden") |> Enum.uniq() == ["true"]
    assert separators |> LazyHTML.text() |> String.trim() == "++"
  end

  test "a single-element keys list renders no separator" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kbd keys={["K"]} />
      """)

    doc = LazyHTML.from_fragment(html)

    assert doc |> LazyHTML.query("kbd.pc-kbd") |> Enum.count() == 1
    assert doc |> LazyHTML.query(".pc-kbd-group__separator") |> Enum.empty?()
  end

  test "known key names fold to their symbol, case-insensitively" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kbd keys={["cmd", "Shift", "ALT", "ctrl", "enter", "tab", "backspace", "up", "esc"]} />
      """)

    keys =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("kbd")
      |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

    assert keys == ["⌘", "⇧", "⌥", "⌃", "↵", "⇥", "⌫", "↑", "Esc"]
  end

  test "unknown key names render verbatim" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kbd keys={["cmd", "K", "F5", "/"]} />
      """)

    keys =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("kbd")
      |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

    assert keys == ["⌘", "K", "F5", "/"]
  end

  test "a custom separator glyph replaces the default plus" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kbd keys={["G", "I"]} separator="then" />
      """)

    assert html =~ "then"
    refute html =~ ~s(aria-hidden="true">+)
  end

  test "the size applies to every chip in a sequence, and class/rest land on the group" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kbd keys={["cmd", "K"]} size="sm" class="ml-auto" data-role="hint" />
      """)

    doc = LazyHTML.from_fragment(html)
    group = LazyHTML.query(doc, ".pc-kbd-group")

    assert doc |> LazyHTML.query("kbd.pc-kbd--sm") |> Enum.count() == 2
    assert group |> LazyHTML.attribute("class") |> hd() =~ "ml-auto"
    assert LazyHTML.attribute(group, "data-role") == ["hint"]
  end

  test "an empty keys list renders the group and nothing else" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kbd keys={[]} />
      """)

    doc = LazyHTML.from_fragment(html)

    assert doc |> LazyHTML.query(".pc-kbd-group") |> Enum.count() == 1
    assert doc |> LazyHTML.query("kbd") |> Enum.empty?()
  end

  test "symbol-mapped keys speak their canonical names" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kbd keys={["cmd", "shift", "K"]} />
      """)

    doc = LazyHTML.from_fragment(html)
    kbds = doc |> LazyHTML.query("kbd") |> Enum.to_list()

    # glyph screen-reader handling is inconsistent, so the map's names ride
    # aria-label; a verbatim key needs none
    assert LazyHTML.attribute(Enum.at(kbds, 0), "aria-label") == ["Command"]
    assert LazyHTML.attribute(Enum.at(kbds, 1), "aria-label") == ["Shift"]
    assert LazyHTML.attribute(Enum.at(kbds, 2), "aria-label") == []
  end

  test "separator={nil} renders the keys with no separator span at all" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kbd keys={["cmd", "K"]} separator={nil} />
      """)

    doc = LazyHTML.from_fragment(html)
    assert doc |> LazyHTML.query("kbd") |> Enum.count() == 2
    assert doc |> LazyHTML.query(".pc-kbd-group__separator") |> Enum.empty?()
  end
end
