defmodule PetalComponents.HoverCardTest do
  use ComponentCase
  import PetalComponents.HoverCard

  @placements ~w(top top-start top-end bottom bottom-start bottom-end left left-start left-end right right-start right-end)

  test "renders wrapper, trigger and panel with the default bottom placement" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.hover_card id="hc-basic">
        <:trigger>@jane</:trigger>
        Jane Doe
      </.hover_card>
      """)

    assert html =~ "@jane"
    assert html =~ "Jane Doe"
    assert_has_class(html, "pc-hover-card")
    assert_has_class(html, "pc-hover-card__trigger")
    assert_has_class(html, "pc-hover-card__panel")
    assert_has_class(html, "pc-hover-card__panel--bottom")
    # the group name the CSS reveal hangs off
    assert_has_class(html, "group/pc-hover-card")
  end

  test "the panel is a child of the wrapper, so hovering it keeps the card open" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.hover_card id="hc-nesting">
        <:trigger>@jane</:trigger>
        Card body
      </.hover_card>
      """)

    panel =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(".pc-hover-card > .pc-hover-card__panel")

    assert Enum.count(panel) == 1

    trigger =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(".pc-hover-card > .pc-hover-card__trigger")

    assert Enum.count(trigger) == 1
  end

  test "generates a panel id when not given" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.hover_card>
        <:trigger>@jane</:trigger>
        Card
      </.hover_card>
      """)

    assert html =~ ~s(id="hover_card_)
  end

  test "respects an explicit id" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.hover_card id="hc-explicit">
        <:trigger>@jane</:trigger>
        Card
      </.hover_card>
      """)

    assert_attribute(html, "id", "hc-explicit")
    refute html =~ "hover_card_"
  end

  test "every placement emits its modifier class" do
    for placement <- @placements do
      assigns = %{placement: placement}

      html =
        rendered_to_string(~H"""
        <.hover_card placement={@placement}>
          <:trigger>@jane</:trigger>
          Card
        </.hover_card>
        """)

      assert_has_class(html, "pc-hover-card__panel--#{placement}")
    end
  end

  test "placement is constrained to the twelve values the CSS knows about" do
    %{attrs: attrs} =
      PetalComponents.HoverCard.__components__() |> Map.fetch!(:hover_card)

    placement = Enum.find(attrs, &(&1.name == :placement))

    assert placement.opts[:values] == @placements
    assert placement.opts[:default] == "bottom"
  end

  test "every attr is documented" do
    %{attrs: attrs} =
      PetalComponents.HoverCard.__components__() |> Map.fetch!(:hover_card)

    undocumented =
      attrs
      |> Enum.reject(&(&1.name == :rest))
      |> Enum.filter(&(&1.doc in [nil, ""]))
      |> Enum.map(& &1.name)

    assert undocumented == []
  end

  test "delays default to 350ms open and 150ms close" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.hover_card>
        <:trigger>@jane</:trigger>
        Card
      </.hover_card>
      """)

    assert html =~ "--pc-hover-card-open-delay: 350ms;"
    assert html =~ "--pc-hover-card-close-delay: 150ms;"
  end

  test "custom delays land in the custom properties" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.hover_card open_delay={0} close_delay={500}>
        <:trigger>@jane</:trigger>
        Card
      </.hover_card>
      """)

    assert html =~ "--pc-hover-card-open-delay: 0ms;"
    assert html =~ "--pc-hover-card-close-delay: 500ms;"
  end

  test "a caller style is merged after ours rather than emitted twice" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.hover_card style="--pc-radius: 0px;">
        <:trigger>@jane</:trigger>
        Card
      </.hover_card>
      """)

    assert count_substring(html, "style=") == 1
    assert html =~ "--pc-hover-card-open-delay: 350ms;"
    assert html =~ "--pc-radius: 0px;"
  end

  test "class, trigger_class and card_class land on their own elements" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.hover_card class="wrapper-custom" trigger_class="trigger-custom" card_class="card-custom">
        <:trigger>@jane</:trigger>
        Card
      </.hover_card>
      """)

    doc = LazyHTML.from_fragment(html)

    assert Enum.count(LazyHTML.query(doc, ".pc-hover-card.wrapper-custom")) == 1
    assert Enum.count(LazyHTML.query(doc, ".pc-hover-card__trigger.trigger-custom")) == 1
    assert Enum.count(LazyHTML.query(doc, ".pc-hover-card__panel.card-custom")) == 1
  end

  test "rest attributes pass through to the wrapper" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.hover_card id="hc-rest" data-role="preview" aria-label="Jane Doe preview">
        <:trigger>@jane</:trigger>
        Card
      </.hover_card>
      """)

    wrapper =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(".pc-hover-card")
      |> LazyHTML.attribute("data-role")

    assert wrapper == ["preview"]
    assert_attribute(html, "aria-label", "Jane Doe preview")
  end

  test "interactive content renders inside the panel" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.hover_card id="hc-interactive">
        <:trigger>
          <a href="/users/jane">@jane</a>
        </:trigger>
        <a href="/users/jane/follow">Follow</a>
        <button type="button">Message</button>
      </.hover_card>
      """)

    doc = LazyHTML.from_fragment(html)

    assert Enum.count(LazyHTML.query(doc, ".pc-hover-card__panel a")) == 1
    assert Enum.count(LazyHTML.query(doc, ".pc-hover-card__panel button")) == 1
    assert Enum.count(LazyHTML.query(doc, ".pc-hover-card__trigger a")) == 1
  end

  test "the panel carries no tooltip or dialog role" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.hover_card id="hc-roles">
        <:trigger>@jane</:trigger>
        Card
      </.hover_card>
      """)

    refute html =~ ~s(role="tooltip")
    refute html =~ ~s(role="dialog")
    refute html =~ "role="
  end

  test "the reveal rides the group, so the panel needs no open state in markup" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.hover_card id="hc-rest-state">
        <:trigger>@jane</:trigger>
        Card
      </.hover_card>
      """)

    # the wrapper names the group that default.css hangs the hover and
    # focus-within reveal off; there is no open/closed attribute to keep in sync
    assert_has_class(html, "group/pc-hover-card")
    refute html =~ "aria-expanded"
    refute html =~ ~s(style="display: none;")
  end

  test "no JavaScript hook or client bindings are emitted" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.hover_card id="hc-css-only">
        <:trigger>@jane</:trigger>
        Card
      </.hover_card>
      """)

    refute html =~ "phx-hook"
    refute html =~ "phx-click"
    refute html =~ "phx-keydown"
    refute html =~ "x-data"
  end
end
