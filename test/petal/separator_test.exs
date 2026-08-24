defmodule PetalComponents.SeparatorTest do
  use ComponentCase
  import PetalComponents.Separator

  test "defaults to a decorative horizontal hairline" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.separator />
      """)

    assert_has_class(html, "pc-separator")
    assert_has_class(html, "pc-separator--horizontal")
    refute_has_class(html, "pc-separator--vertical")
    assert_attribute(html, "aria-hidden", "true")
    refute html =~ ~s(role="separator")
  end

  test "vertical swaps the orientation class" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.separator orientation="vertical" />
      """)

    assert_has_class(html, "pc-separator--vertical")
    refute_has_class(html, "pc-separator--horizontal")
  end

  test "class and rest pass through" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.separator class="my-6 h-6" data-role="rule" />
      """)

    assert_has_class(html, "my-6 h-6")
    assert_attribute(html, "data-role", "rule")
  end

  test "decorative={false} swaps aria-hidden for role=separator" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.separator decorative={false} />
      """)

    assert_attribute(html, "role", "separator")
    refute html =~ ~s(aria-hidden="true")
    # horizontal is the ARIA default, so aria-orientation is left off
    refute html =~ "aria-orientation"
  end

  test "a semantic vertical separator declares its orientation" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.separator orientation="vertical" decorative={false} />
      """)

    assert_attribute(html, "role", "separator")
    assert_attribute(html, "aria-orientation", "vertical")
  end

  test "the label attr renders a labelled row with two flanking lines" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.separator label="OR" />
      """)

    doc = LazyHTML.from_fragment(html)

    assert_has_class(html, "pc-separator--labelled")
    assert_has_class(html, "pc-separator--horizontal")
    assert doc |> LazyHTML.query(".pc-separator__line") |> Enum.count() == 2

    assert doc |> LazyHTML.query(".pc-separator__label") |> LazyHTML.text() |> String.trim() ==
             "OR"
  end

  test "the flanking lines are always hidden from assistive tech" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.separator label="OR" decorative={false} />
      """)

    lines =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(".pc-separator__line")

    assert lines |> LazyHTML.attribute("aria-hidden") |> Enum.uniq() == ["true"]
    assert_attribute(html, "role", "separator")
  end

  test "slot content wins over the label attr" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.separator label="OR"><span class="badge">12 August</span></.separator>
      """)

    label =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(".pc-separator__label")
      |> LazyHTML.text()
      |> String.trim()

    assert label == "12 August"
    refute label =~ "OR"
    assert html =~ ~s(class="badge")
  end

  test "each label position emits its own class" do
    assigns = %{}

    for position <- ~w(start center end) do
      assigns = Map.put(assigns, :position, position)

      html =
        rendered_to_string(~H"""
        <.separator label="OR" label_position={@position} />
        """)

      assert_has_class(html, "pc-separator--label-#{position}")
    end
  end

  test "center is the default label position" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.separator label="OR" />
      """)

    assert_has_class(html, "pc-separator--label-center")
  end

  test "an empty label falls back to the plain rule" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.separator label="" />
      """)

    refute_has_class(html, "pc-separator--labelled")
    assert_has_class(html, "pc-separator--horizontal")
  end

  test "a vertical separator ignores a label rather than rendering a broken row" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.separator orientation="vertical" label="OR" />
      """)

    refute_has_class(html, "pc-separator--labelled")
    assert_has_class(html, "pc-separator--vertical")
    refute html =~ "OR"
  end

  test "a decorative labelled separator keeps its label readable" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.separator label="OR" />
      """)

    doc = LazyHTML.from_fragment(html)
    # the container must NOT be aria-hidden - the label is real content;
    # only the flank lines hide
    root = doc |> LazyHTML.query(".pc-separator--labelled") |> Enum.at(0)
    assert LazyHTML.attribute(root, "aria-hidden") == []
    assert doc |> LazyHTML.query(".pc-separator__line[aria-hidden]") |> Enum.count() == 2
  end

  test "a semantic labelled separator carries the label in aria-label" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.separator label="Today" decorative={false} />
      """)

    doc = LazyHTML.from_fragment(html)
    root = doc |> LazyHTML.query(".pc-separator--labelled") |> Enum.at(0)
    # role="separator" has presentational children - without aria-label the
    # inner text is swallowed
    assert LazyHTML.attribute(root, "role") == ["separator"]
    assert LazyHTML.attribute(root, "aria-label") == ["Today"]
  end

  test "slot-only content labels the separator without the label attr" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.separator>March 2026</.separator>
      """)

    assert_has_class(html, "pc-separator--labelled")
    assert html =~ "March 2026"
  end
end
