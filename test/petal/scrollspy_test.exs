defmodule PetalComponents.ScrollspyTest do
  use ComponentCase

  import PetalComponents.Scrollspy

  @items [
    %{label: "Install", target: "install"},
    %{label: "Usage", target: "usage"}
  ]

  @nested [
    %{
      label: "Usage",
      target: "usage",
      children: [
        %{label: "Options", target: "options"},
        %{label: "Events", target: "events"}
      ]
    }
  ]

  defp render_scrollspy(assigns) do
    assigns = Map.new(assigns)

    rendered_to_string(~H"""
    <.scrollspy id={@id} items={@items} {Map.drop(assigns, [:id, :items])} />
    """)
  end

  describe "scrollspy/1" do
    test "renders a hooked nav landmark with the given id" do
      html = render_scrollspy(id: "toc", items: @items)
      nav = html |> parse_html() |> LazyHTML.query("nav#toc")

      assert Enum.count(nav) == 1
      assert LazyHTML.attribute(nav, "phx-hook") == ["PetalScrollspy"]
      assert LazyHTML.attribute(nav, "aria-label") == ["On this page"]
      assert_has_class(html, "pc-scrollspy")
    end

    test "aria_label overrides the default landmark name" do
      html = render_scrollspy(id: "toc", items: @items, aria_label: "Sections")

      assert html |> parse_html() |> LazyHTML.query("nav") |> LazyHTML.attribute("aria-label") ==
               [
                 "Sections"
               ]
    end

    test "every item renders an anchor carrying its href and data target" do
      links = render_scrollspy(id: "toc", items: @items) |> parse_html() |> LazyHTML.query("a")

      assert LazyHTML.attribute(links, "href") == ["#install", "#usage"]
      assert LazyHTML.attribute(links, "data-scrollspy-target") == ["install", "usage"]
      assert LazyHTML.text(links) =~ "Install"
      assert LazyHTML.text(links) =~ "Usage"
    end

    test "the initial render owns no active state - the hook does" do
      html = render_scrollspy(id: "toc", items: @items)

      refute html =~ "aria-current"
      refute_has_class(html, "pc-scrollspy-link--active")
    end

    test "offset lands on the hook element and defaults to 6rem" do
      nav =
        render_scrollspy(id: "toc", items: @items) |> parse_html() |> LazyHTML.query("nav")

      assert LazyHTML.attribute(nav, "data-offset") == ["6rem"]
    end

    test "offset is configurable" do
      nav =
        render_scrollspy(id: "toc", items: @items, offset: "10rem")
        |> parse_html()
        |> LazyHTML.query("nav")

      assert LazyHTML.attribute(nav, "data-offset") == ["10rem"]
    end

    test "threshold is omitted when nil and rendered when given" do
      html = render_scrollspy(id: "toc", items: @items)
      refute html =~ "data-threshold"

      nav =
        render_scrollspy(id: "toc", items: @items, threshold: "-20% 0px -70% 0px")
        |> parse_html()
        |> LazyHTML.query("nav")

      assert LazyHTML.attribute(nav, "data-threshold") == ["-20% 0px -70% 0px"]
    end
  end

  describe "nesting" do
    test "children render one level down with the nested class" do
      html = render_scrollspy(id: "toc", items: @nested)
      doc = parse_html(html)

      assert doc |> LazyHTML.query(".pc-scrollspy__sublist") |> Enum.count() == 1

      nested = LazyHTML.query(doc, ".pc-scrollspy-link--nested")
      assert LazyHTML.attribute(nested, "data-scrollspy-target") == ["options", "events"]

      # The parent is still a plain link, not a nested one
      assert doc
             |> LazyHTML.query(~s|a[data-scrollspy-target="usage"]|)
             |> LazyHTML.attribute("class") == ["pc-scrollspy-link"]
    end

    test "a grandchild key is ignored rather than rendered" do
      items = [
        %{
          label: "Usage",
          target: "usage",
          children: [
            %{label: "Options", target: "options", children: [%{label: "Deep", target: "deep"}]}
          ]
        }
      ]

      html = render_scrollspy(id: "toc", items: items)

      refute html =~ "deep"
      assert html =~ "options"
    end

    test "items without a children key render fine" do
      html = render_scrollspy(id: "toc", items: @items)

      refute html =~ "pc-scrollspy__sublist"
      refute_has_class(html, "pc-scrollspy-link--nested")
    end

    test "an explicit empty children list renders no sublist" do
      html =
        render_scrollspy(id: "toc", items: [%{label: "Install", target: "install", children: []}])

      refute html =~ "pc-scrollspy__sublist"
    end
  end

  describe "indicator" do
    test "bar (the default) renders a decorative indicator and the rail modifier" do
      html = render_scrollspy(id: "toc", items: @items)
      bar = html |> parse_html() |> LazyHTML.query(".pc-scrollspy__indicator")

      assert Enum.count(bar) == 1
      assert LazyHTML.attribute(bar, "aria-hidden") == ["true"]
      assert_has_class(html, "pc-scrollspy--bar")
    end

    test "none omits the indicator entirely" do
      html = render_scrollspy(id: "toc", items: @items, indicator: "none")

      refute html =~ "pc-scrollspy__indicator"
      assert_has_class(html, "pc-scrollspy--none")
    end
  end

  describe "heading" do
    test "renders above the list when given" do
      heading =
        render_scrollspy(id: "toc", items: @items, heading: "On this page")
        |> parse_html()
        |> LazyHTML.query(".pc-scrollspy__heading")

      assert LazyHTML.text(heading) == "On this page"
    end

    test "is absent by default" do
      refute render_scrollspy(id: "toc", items: @items) =~ "pc-scrollspy__heading"
    end
  end

  describe "pass-through" do
    test "class is appended to the nav, not replacing the base class" do
      classes =
        render_scrollspy(id: "toc", items: @items, class: "sticky top-24")
        |> parse_html()
        |> LazyHTML.query("nav")
        |> LazyHTML.attribute("class")
        |> List.first()

      assert classes =~ "pc-scrollspy"
      assert classes =~ "sticky top-24"
    end

    test "global attributes land on the nav" do
      nav =
        render_scrollspy(id: "toc", items: @items, "data-role": "toc")
        |> parse_html()
        |> LazyHTML.query("nav")

      assert LazyHTML.attribute(nav, "data-role") == ["toc"]
    end
  end

  describe "edge cases" do
    test "an empty item list still renders the landmark" do
      html = render_scrollspy(id: "toc", items: [])
      doc = parse_html(html)

      assert doc |> LazyHTML.query("nav#toc") |> Enum.count() == 1
      assert doc |> LazyHTML.query("a") |> Enum.count() == 0
    end

    test "labels are escaped, not injected" do
      html =
        render_scrollspy(id: "toc", items: [%{label: "<b>Install</b>", target: "install"}])

      refute html =~ "<b>Install</b>"
      assert html =~ html_escape("<b>Install</b>")
    end
  end
end
