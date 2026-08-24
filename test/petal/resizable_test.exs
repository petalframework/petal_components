defmodule PetalComponents.ResizableTest do
  @moduledoc """
  Tests for PetalComponents.Resizable - the split-pane layout group.

  The live behaviour (drag, clamping, collapse, keyboard) belongs to the
  PetalResizable hook and is covered in test/js/resizable.test.js. What matters
  here is the contract the hook and assistive tech read off the markup: the
  hook root, the panel data-* constraints, and the separator's ARIA.
  """

  use ComponentCase
  import PetalComponents.Resizable

  describe "resizable_group/1" do
    test "renders the hook root, the orientation class and data-orientation" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.resizable_group id="g">
          <.resizable_panel>a</.resizable_panel>
          <.resizable_handle />
          <.resizable_panel>b</.resizable_panel>
        </.resizable_group>
        """)

      assert html =~ ~s(phx-hook="PetalResizable")
      assert html =~ ~s(data-orientation="horizontal")
      assert html =~ "pc-resizable"
      refute html =~ "pc-resizable--vertical"
    end

    test "vertical orientation adds the modifier class and flips data-orientation" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.resizable_group id="g" orientation="vertical">
          <.resizable_panel>a</.resizable_panel>
        </.resizable_group>
        """)

      assert html =~ "pc-resizable--vertical"
      assert html =~ ~s(data-orientation="vertical")
    end

    test "generates an id when none is given" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.resizable_group>
          <.resizable_panel>a</.resizable_panel>
        </.resizable_group>
        """)

      assert html =~ ~s(id="pc-resizable-)
    end

    test "on_resize rides along as data-on-resize for the hook to push" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.resizable_group id="g" on_resize="split_changed">
          <.resizable_panel>a</.resizable_panel>
        </.resizable_group>
        """)

      assert html =~ ~s(data-on-resize="split_changed")
    end

    test "class and rest pass through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.resizable_group id="g" class="h-80" data-test="group">
          <.resizable_panel>a</.resizable_panel>
        </.resizable_group>
        """)

      assert html =~ "h-80"
      assert html =~ ~s(data-test="group")
    end
  end

  describe "resizable_panel/1" do
    test "default_size becomes the flex-grow share plus the data-* constraints" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.resizable_panel id="p" default_size={25} min_size={15} max_size={60}>
          Nav
        </.resizable_panel>
        """)

      assert html =~ ~s(style="flex: 25 1 0px")
      assert html =~ "data-pc-resizable-panel"
      assert html =~ ~s(data-min="15")
      assert html =~ ~s(data-max="60")
      assert html =~ ~s(data-default="25")
      assert html =~ ~s(data-collapsed-size="0")
      refute html =~ "data-collapsible"
    end

    test "unsized panels get the equal-share default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.resizable_group id="g">
          <.resizable_panel>a</.resizable_panel>
          <.resizable_handle />
          <.resizable_panel>b</.resizable_panel>
        </.resizable_group>
        """)

      assert count_substring(html, ~s(style="flex: 1 1 0px")) == 2
      refute html =~ "data-default="
    end

    test "collapsible surfaces both collapse attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.resizable_panel collapsible collapsed_size={4}>Nav</.resizable_panel>
        """)

      assert html =~ ~s(data-collapsible="true")
      assert html =~ ~s(data-collapsed-size="4")
    end

    test "class and rest pass through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.resizable_panel class="bg-white" data-test="panel">a</.resizable_panel>
        """)

      assert html =~ "pc-resizable__panel"
      assert html =~ "bg-white"
      assert html =~ ~s(data-test="panel")
    end
  end

  describe "resizable_handle/1" do
    test "the separator contract: role, tab stop, ARIA values and aria-controls" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.resizable_handle controls="nav" value_now={25} value_min={15} value_max={60} />
        """)

      assert html =~ ~s(role="separator")
      assert html =~ ~s(tabindex="0")
      assert html =~ ~s(aria-controls="nav")
      assert html =~ ~s(aria-valuenow="25")
      assert html =~ ~s(aria-valuemin="15")
      assert html =~ ~s(aria-valuemax="60")
      assert html =~ ~s(aria-label="Resize panels")
      assert html =~ "data-pc-resizable-handle"
    end

    test "aria-orientation is the inverse of the group's orientation" do
      assigns = %{}

      horizontal =
        rendered_to_string(~H"""
        <.resizable_handle orientation="horizontal" />
        """)

      vertical =
        rendered_to_string(~H"""
        <.resizable_handle orientation="vertical" />
        """)

      # side-by-side panels are divided by a VERTICAL separator
      assert horizontal =~ ~s(aria-orientation="vertical")
      assert vertical =~ ~s(aria-orientation="horizontal")
    end

    test "with_handle adds the grip modifier and the grip element" do
      assigns = %{}

      bare =
        rendered_to_string(~H"""
        <.resizable_handle />
        """)

      gripped =
        rendered_to_string(~H"""
        <.resizable_handle with_handle />
        """)

      refute bare =~ "pc-resizable__handle--with-handle"
      refute bare =~ "pc-resizable__grip"
      assert gripped =~ "pc-resizable__handle--with-handle"
      assert gripped =~ "pc-resizable__grip"
      assert gripped =~ ~s(aria-hidden="true")
    end

    test "label overrides the accessible name; class and rest pass through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.resizable_handle label="Resize navigation" class="opacity-50" data-test="handle" />
        """)

      assert html =~ ~s(aria-label="Resize navigation")
      assert html =~ "opacity-50"
      assert html =~ ~s(data-test="handle")
    end
  end

  describe "nesting" do
    test "a nested group renders two independent hook roots, each owning its own panels" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.resizable_group id="outer" orientation="vertical">
          <.resizable_panel default_size={70}>
            <.resizable_group id="inner">
              <.resizable_panel id="inner-a" default_size={30}>files</.resizable_panel>
              <.resizable_handle controls="inner-a" />
              <.resizable_panel default_size={70}>editor</.resizable_panel>
            </.resizable_group>
          </.resizable_panel>
          <.resizable_handle orientation="vertical" />
          <.resizable_panel default_size={30}>terminal</.resizable_panel>
        </.resizable_group>
        """)

      assert count_substring(html, ~s(phx-hook="PetalResizable")) == 2
      assert html =~ ~s(id="outer")
      assert html =~ ~s(id="inner")

      doc = parse_html(html)

      # :scope > … is what the hook uses; assert the DOM actually gives each
      # group its own direct-child panels, three inside and two outside.
      outer_panels =
        doc |> LazyHTML.query("#outer > [data-pc-resizable-panel]") |> Enum.count()

      inner_panels =
        doc |> LazyHTML.query("#inner > [data-pc-resizable-panel]") |> Enum.count()

      assert outer_panels == 2
      assert inner_panels == 2

      assert doc |> LazyHTML.query("#outer > [data-pc-resizable-handle]") |> Enum.count() == 1
      assert doc |> LazyHTML.query("#inner > [data-pc-resizable-handle]") |> Enum.count() == 1
    end
  end
end
