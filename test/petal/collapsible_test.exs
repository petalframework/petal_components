defmodule PetalComponents.CollapsibleTest do
  use ComponentCase
  import PetalComponents.Collapsible

  alias Phoenix.LiveView.JS

  defp markup(assigns) do
    rendered_to_string(~H"""
    <.collapsible {assigns}>
      <:trigger>API keys</:trigger>
      <p>pk_live_9f2a</p>
    </.collapsible>
    """)
  end

  test "renders a trigger button and a labelled content region" do
    html = markup(%{id: "ck"})
    doc = LazyHTML.from_fragment(html)

    assert_has_class(html, "pc-collapsible")

    button = LazyHTML.query(doc, "button#ck-trigger")
    assert Enum.count(button) == 1
    assert LazyHTML.attribute(button, "type") == ["button"]

    content = LazyHTML.query(doc, "#ck-content")
    assert LazyHTML.attribute(content, "role") == ["region"]
    assert LazyHTML.attribute(content, "aria-labelledby") == ["ck-trigger"]
  end

  test "aria-controls points at the content region derived from the container id" do
    html = markup(%{id: "ck"})
    doc = LazyHTML.from_fragment(html)

    [controls] = doc |> LazyHTML.query("button") |> LazyHTML.attribute("aria-controls")
    assert controls == "ck-content"
    assert doc |> LazyHTML.query("##{controls}") |> Enum.count() == 1
  end

  test "closed is the default: aria-expanded false, data-state closed, content inert" do
    html = markup(%{id: "ck"})
    doc = LazyHTML.from_fragment(html)

    assert doc |> LazyHTML.query("button") |> LazyHTML.attribute("aria-expanded") == ["false"]
    assert doc |> LazyHTML.query("#ck") |> LazyHTML.attribute("data-state") == ["closed"]
    assert doc |> LazyHTML.query("#ck-content") |> LazyHTML.attribute("inert") == [""]
  end

  test "open flips the state, the aria and the inert guard" do
    html = markup(%{id: "ck", open: true})
    doc = LazyHTML.from_fragment(html)

    assert doc |> LazyHTML.query("button") |> LazyHTML.attribute("aria-expanded") == ["true"]
    assert doc |> LazyHTML.query("#ck") |> LazyHTML.attribute("data-state") == ["open"]
    assert doc |> LazyHTML.query("#ck-content") |> LazyHTML.attribute("inert") == []
  end

  test "the chevron is present and carries the rotation class only when open" do
    closed = markup(%{id: "ck"})
    open = markup(%{id: "ck", open: true})

    assert has_icon?(closed, "hero-chevron-down-solid")
    assert has_icon?(open, "hero-chevron-down-solid")

    # read the class off the chevron itself: "rotate-180" also appears inside the
    # encoded phx-click, which is the client half of the same rotation
    chevron_class = fn html ->
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(".pc-collapsible__chevron")
      |> LazyHTML.attribute("class")
      |> hd()
    end

    assert chevron_class.(open) =~ "rotate-180"
    refute chevron_class.(closed) =~ "rotate-180"
  end

  test "an id is generated when none is passed, and both regions derive from it" do
    html = markup(%{})
    doc = LazyHTML.from_fragment(html)

    [id] = doc |> LazyHTML.query(".pc-collapsible") |> LazyHTML.attribute("id")
    assert id =~ ~r/^c-collapsible-/

    assert doc |> LazyHTML.query("button") |> LazyHTML.attribute("id") == ["#{id}-trigger"]

    assert doc |> LazyHTML.query("button") |> LazyHTML.attribute("aria-controls") == [
             "#{id}-content"
           ]
  end

  test "disabled renders a natively disabled button" do
    html = markup(%{id: "ck", disabled: true})

    assert html
           |> LazyHTML.from_fragment()
           |> LazyHTML.query("button")
           |> LazyHTML.attribute("disabled") == [""]
  end

  test "the toggle wires data-state, aria-expanded, inert and the chevron" do
    html = markup(%{id: "ck"})

    [click] =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("button")
      |> LazyHTML.attribute("phx-click")

    assert click =~ "toggle_attr"
    assert click =~ "data-state"
    assert click =~ "aria-expanded"
    assert click =~ "inert"
    assert click =~ "#ck-trigger"
    assert click =~ "#ck-content"
    assert click =~ "rotate-180"
  end

  test "on_toggle composes ahead of the component's own commands" do
    assigns = %{on_toggle: JS.push("collapsed", value: %{id: "ck"})}

    html =
      rendered_to_string(~H"""
      <.collapsible id="ck" on_toggle={@on_toggle}>
        <:trigger>API keys</:trigger>
        <p>pk_live_9f2a</p>
      </.collapsible>
      """)

    [click] =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("button")
      |> LazyHTML.attribute("phx-click")

    assert click =~ "collapsed"
    # the user's push runs first, the component's toggles after
    assert :binary.match(click, "collapsed") < :binary.match(click, "data-state")
  end

  test "the trigger slot takes its own class, and content renders in the body" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.collapsible id="ck">
        <:trigger class="text-lg">Advanced options</:trigger>
        <span class="marker">Timeouts and retries</span>
      </.collapsible>
      """)

    doc = LazyHTML.from_fragment(html)

    assert doc |> LazyHTML.query("button") |> LazyHTML.attribute("class") |> hd() =~ "text-lg"

    assert doc |> LazyHTML.query(".pc-collapsible__label") |> LazyHTML.text() =~
             "Advanced options"

    assert doc |> LazyHTML.query(".pc-collapsible__body .marker") |> Enum.count() == 1
  end

  test "class and rest pass through to the container" do
    html = markup(%{id: "ck", class: "mt-4", "data-role": "disclosure"})

    assert_has_class(html, "pc-collapsible")
    assert_has_class(html, "mt-4")
    assert_attribute(html, "data-role", "disclosure")
  end

  test "the animation wrapper is present so the grid-rows transition has something to drive" do
    html = markup(%{id: "ck"})
    doc = LazyHTML.from_fragment(html)

    assert doc |> LazyHTML.query(".pc-collapsible > .pc-collapsible__panel") |> Enum.count() == 1

    assert doc
           |> LazyHTML.query(".pc-collapsible__panel > .pc-collapsible__content")
           |> Enum.count() == 1
  end

  test "toggle_collapsible/1 drives the same region from anywhere on the page" do
    js = PetalComponents.Collapsible.toggle_collapsible("ck")
    encoded = Phoenix.HTML.Safe.to_iodata(js) |> IO.iodata_to_binary()

    assert encoded =~ "#ck"
    assert encoded =~ "data-state"
  end
end
