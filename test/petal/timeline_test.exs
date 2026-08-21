defmodule PetalComponents.TimelineTest do
  use ComponentCase

  import PetalComponents.Timeline

  describe "structure" do
    test "renders an ordered list with one item per entry" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="Placed" />
          <:item title="Packed" />
          <:item title="Delivered" />
        </.timeline>
        """)

      doc = LazyHTML.from_fragment(html)

      assert doc |> LazyHTML.query("ol.pc-timeline") |> Enum.count() == 1
      assert doc |> LazyHTML.query("ol.pc-timeline > li.pc-timeline__item") |> Enum.count() == 3
      assert html =~ "Placed"
      assert html =~ "Delivered"
    end

    test "renders time, title and description" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item time="9:41am" title="Order placed" description="Payment authorised." />
        </.timeline>
        """)

      doc = LazyHTML.from_fragment(html)

      assert doc |> LazyHTML.query(".pc-timeline__time") |> LazyHTML.text() =~ "9:41am"
      assert doc |> LazyHTML.query("h3.pc-timeline__title") |> LazyHTML.text() =~ "Order placed"

      assert doc |> LazyHTML.query("p.pc-timeline__description") |> LazyHTML.text() =~
               "Payment authorised."
    end

    test "omits the optional parts when they aren't given" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="Just a title" />
        </.timeline>
        """)

      refute html =~ "pc-timeline__time"
      refute html =~ "pc-timeline__description"
      refute html =~ "pc-timeline__body"
    end

    test "the last entry drops its connector and its trailing space" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="One" />
          <:item title="Two" />
          <:item title="Three" />
        </.timeline>
        """)

      doc = LazyHTML.from_fragment(html)

      assert doc |> LazyHTML.query(".pc-timeline__connector") |> Enum.count() == 2
      assert doc |> LazyHTML.query("li.pc-timeline__item--last") |> Enum.count() == 1
    end

    test "class and rest pass through to the root" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline class="my-timeline" id="deploys" data-testid="tl">
          <:item title="One" />
        </.timeline>
        """)

      root = html |> LazyHTML.from_fragment() |> LazyHTML.query("ol")

      assert_has_class(html, "my-timeline")
      assert LazyHTML.attribute(root, "id") == ["deploys"]
      assert LazyHTML.attribute(root, "data-testid") == ["tl"]
    end

    test "an entry takes its own class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="One" class="entry-one" />
        </.timeline>
        """)

      assert html |> LazyHTML.from_fragment() |> LazyHTML.query("li.entry-one") |> Enum.count() ==
               1
    end
  end

  describe "variants and orientation" do
    test "defaults to a vertical default-variant list" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="One" />
        </.timeline>
        """)

      assert_has_class(html, "pc-timeline--vertical")
      assert_has_class(html, "pc-timeline--default")
      refute_has_class(html, "pc-timeline--horizontal")
    end

    test "each variant emits its modifier class" do
      for variant <- ~w(default alternating compact) do
        assigns = %{variant: variant}

        html =
          rendered_to_string(~H"""
          <.timeline variant={@variant}>
            <:item title="One" />
          </.timeline>
          """)

        assert_has_class(html, "pc-timeline--#{variant}")
      end
    end

    test "alternating sides alternate by entry index" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline variant="alternating">
          <:item title="One" />
          <:item title="Two" />
          <:item title="Three" />
        </.timeline>
        """)

      doc = LazyHTML.from_fragment(html)

      assert doc |> LazyHTML.query("li.pc-timeline__item--start") |> Enum.count() == 2
      assert doc |> LazyHTML.query("li.pc-timeline__item--end") |> Enum.count() == 1
    end

    test "sides exist only for the alternating variant" do
      assigns = %{}

      for attrs <- [%{}, %{variant: "compact"}, %{orientation: "horizontal"}] do
        assigns = Map.put(assigns, :attrs, attrs)

        html =
          rendered_to_string(~H"""
          <.timeline {@attrs}>
            <:item title="One" />
            <:item title="Two" />
          </.timeline>
          """)

        refute_has_class(html, "pc-timeline__item--start")
        refute_has_class(html, "pc-timeline__item--end")
      end
    end

    test "horizontal drops the variant class and takes keyboard focus" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline orientation="horizontal" variant="compact">
          <:item title="One" />
        </.timeline>
        """)

      assert_has_class(html, "pc-timeline--horizontal")
      refute_has_class(html, "pc-timeline--compact")
      assert_attribute(html, "tabindex", "0")
    end

    test "vertical timelines aren't focus targets" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="One" />
        </.timeline>
        """)

      refute_attribute(html, "tabindex")
    end
  end

  describe "connector" do
    test "solid is the default and emits no modifier" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="One" />
          <:item title="Two" />
        </.timeline>
        """)

      refute_has_class(html, "pc-timeline--dashed")
    end

    test "dashed emits the modifier class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline connector="dashed">
          <:item title="One" />
          <:item title="Two" />
        </.timeline>
        """)

      assert_has_class(html, "pc-timeline--dashed")
    end

    test "the connector running into an upcoming entry is de-emphasised" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="One" />
          <:item title="Two" state="upcoming" />
          <:item title="Three" state="upcoming" />
        </.timeline>
        """)

      doc = LazyHTML.from_fragment(html)

      assert doc |> LazyHTML.query(".pc-timeline__connector--upcoming") |> Enum.count() == 2
    end
  end

  describe "markers" do
    test "dot is the default marker, in primary" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="One" />
        </.timeline>
        """)

      assert_has_class(html, "pc-timeline__marker--dot")
      assert_has_class(html, "pc-timeline__marker--primary")
    end

    test "every semantic colour renders its modifier" do
      for color <- ~w(primary secondary gray info success warning danger) do
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <.timeline>
            <:item title="One" color={@color} />
          </.timeline>
          """)

        assert_has_class(html, "pc-timeline__marker--#{color}")
      end
    end

    test "an unknown colour or marker falls back to the default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="One" color="chartreuse" marker="hologram" />
        </.timeline>
        """)

      assert_has_class(html, "pc-timeline__marker--primary")
      assert_has_class(html, "pc-timeline__marker--dot")
      refute_has_class(html, "pc-timeline__marker--chartreuse")
      refute_has_class(html, "pc-timeline__marker--hologram")
    end

    test "icon markers render the heroicon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="Out for delivery" marker="icon" icon="hero-truck" color="info" />
        </.timeline>
        """)

      assert has_icon?(html, "hero-truck")
      assert_has_class(html, "pc-timeline__marker--icon")
    end

    test "icon markers without an icon fall back to hero-check (the documented default)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="Done" marker="icon" />
        </.timeline>
        """)

      assert has_icon?(html, "hero-check")
    end

    test "number markers count from one" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="One" marker="number" />
          <:item title="Two" marker="number" />
          <:item title="Three" marker="number" />
        </.timeline>
        """)

      numbers =
        html
        |> LazyHTML.from_fragment()
        |> LazyHTML.query(".pc-timeline__number")
        |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

      assert numbers == ["1", "2", "3"]
    end

    test "avatar markers render an image, and fall back to initials" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline variant="compact">
          <:item title="Alex pushed" marker="avatar" src="/images/alex.jpg" name="Alex Chen" />
          <:item title="Sam approved" marker="avatar" name="Sam Rivera" />
        </.timeline>
        """)

      doc = LazyHTML.from_fragment(html)
      img = LazyHTML.query(doc, ".pc-timeline__marker--avatar img")

      assert LazyHTML.attribute(img, "src") == ["/images/alex.jpg"]
      assert LazyHTML.attribute(img, "alt") == ["Alex Chen"]
      assert html =~ "SR"
    end
  end

  describe "states" do
    test "entries default to complete" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="One" />
        </.timeline>
        """)

      assert_has_class(html, "pc-timeline__item--complete")
      assert_has_class(html, "pc-timeline__marker--complete")
    end

    test "each state emits its modifier on the item and the marker" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="One" state="complete" />
          <:item title="Two" state="current" />
          <:item title="Three" state="upcoming" />
        </.timeline>
        """)

      doc = LazyHTML.from_fragment(html)

      for state <- ~w(complete current upcoming) do
        assert doc |> LazyHTML.query("li.pc-timeline__item--#{state}") |> Enum.count() == 1
        assert doc |> LazyHTML.query(".pc-timeline__marker--#{state}") |> Enum.count() == 1
      end
    end

    test "loading spins the shared spinner inside the marker" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="Built" />
          <:item title="Deploying" state="loading" />
        </.timeline>
        """)

      doc = LazyHTML.from_fragment(html)
      spinner = LazyHTML.query(doc, ".pc-timeline__marker--loading svg.pc-timeline__spinner")

      assert Enum.count(spinner) == 1
      assert doc |> LazyHTML.query("li.pc-timeline__item--loading") |> Enum.count() == 1

      # the button's spinner, not a second one grown here
      assert_has_class(html, "pc-button__spinner-icon")
      refute_has_class(html, "pc-spinner--sm")
    end

    test "the spinner takes the marker's place, whatever the marker was" do
      for {marker, glyph} <- [
            {"icon", ".pc-timeline__icon"},
            {"number", ".pc-timeline__number"},
            {"avatar", ".pc-timeline__avatar"}
          ] do
        assigns = %{marker: marker}

        html =
          rendered_to_string(~H"""
          <.timeline>
            <:item title="One" marker={@marker} icon="hero-truck" name="Sam Rivera" state="loading" />
          </.timeline>
          """)

        doc = LazyHTML.from_fragment(html)

        assert doc |> LazyHTML.query(".pc-timeline__spinner") |> Enum.count() == 1
        assert doc |> LazyHTML.query(glyph) |> Enum.empty?()
      end
    end
  end

  describe "accessibility" do
    test "aria-current is on the current entry and nowhere else" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="One" />
          <:item title="Two" state="current" />
          <:item title="Three" state="upcoming" />
        </.timeline>
        """)

      doc = LazyHTML.from_fragment(html)
      current = LazyHTML.query(doc, "li[aria-current]")

      assert Enum.count(current) == 1
      assert LazyHTML.attribute(current, "aria-current") == ["step"]
      assert current |> LazyHTML.text() =~ "Two"
    end

    test "the rail is hidden from assistive tech" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="One" marker="icon" icon="hero-truck" />
          <:item title="Two" />
        </.timeline>
        """)

      doc = LazyHTML.from_fragment(html)
      rails = LazyHTML.query(doc, ".pc-timeline__rail")

      assert Enum.count(rails) == 2
      assert LazyHTML.attribute(rails, "aria-hidden") == ["true", "true"]

      assert doc
             |> LazyHTML.query(".pc-timeline__rail[aria-hidden] .pc-timeline__marker")
             |> Enum.count() == 2
    end

    test "state is carried by text, not colour alone" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="One" />
          <:item title="Two" state="current" />
          <:item title="Three" state="upcoming" />
        </.timeline>
        """)

      labels =
        html
        |> LazyHTML.from_fragment()
        |> LazyHTML.query(".pc-timeline__state-label")
        |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

      assert labels == ["Current", "Upcoming"]
    end

    test "aria-busy is on the loading entry and nowhere else" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="One" />
          <:item title="Two" state="loading" />
          <:item title="Three" state="current" />
        </.timeline>
        """)

      doc = LazyHTML.from_fragment(html)
      busy = LazyHTML.query(doc, "li[aria-busy]")

      assert Enum.count(busy) == 1
      assert LazyHTML.attribute(busy, "aria-busy") == ["true"]
      assert busy |> LazyHTML.text() =~ "Two"

      # and it announces in words as well, like the other states
      assert busy |> LazyHTML.query(".pc-timeline__state-label") |> LazyHTML.text() =~
               "In progress"
    end

    test "no role overrides are invented on the list" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="One" />
        </.timeline>
        """)

      refute html =~ ~s(role="list")
      refute html =~ ~s(role="listitem")
      refute html =~ "<button"
    end

    test "label names the list" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline label="Order history">
          <:item title="One" />
        </.timeline>
        """)

      assert_attribute(html, "aria-label", "Order history")
    end
  end

  describe "inner block" do
    test "renders rich content inside the entry body" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.timeline>
          <:item title="Deployed" description="v4.2.0">
            <p class="release-notes">Rolled out to all regions.</p>
          </:item>
          <:item title="Nothing extra" />
        </.timeline>
        """)

      doc = LazyHTML.from_fragment(html)

      assert doc |> LazyHTML.query(".pc-timeline__body") |> Enum.count() == 1

      assert doc
             |> LazyHTML.query(".pc-timeline__content .pc-timeline__body p.release-notes")
             |> LazyHTML.text() =~
               "Rolled out to all regions."
    end
  end
end
