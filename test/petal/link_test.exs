defmodule PetalComponents.LinkTest do
  use ComponentCase
  alias PetalComponents.Link

  test "a link with label" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Link.link link_type="a" to="/" label="Press me" phx-click="click_event" />
      """)

    assert html =~ "Press me"
    assert html =~ "href="
    assert html =~ "phx-click"
  end

  test "live_patch link with label" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Link.link link_type="live_patch" to="/" label="Press me" phx-click="click_event" />
      """)

    assert html =~ "Press me"
    assert html =~ "href="
    assert html =~ "phx-click"
  end

  test "live_redirect link with label" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Link.link link_type="live_redirect" to="/" label="Press me" phx-click="click_event" />
      """)

    assert html =~ "Press me"
    assert html =~ "href="
    assert html =~ "phx-click"
  end

  test "link with inner_block" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Link.link link_type="a" to="/" phx-click="click_event">
        Press me
      </Link.link>
      """)

    assert html =~ "Press me"
    assert html =~ "phx-click"
  end

  test "link with method" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Link.link to="/" method={:put}>
        Press me
      </Link.link>
      """)

    assert html =~ "Press me"
    assert html =~ "data-method"
  end

  test "link contains no extra spaces" do
    assigns = %{}

    assert rendered_to_string(~H"""
           <Link.link to="/" label="Press me" />
           """) =~ ">Press me<"

    assert rendered_to_string(~H"""
           <Link.link to="/" label=" Press me " />
           """) =~ "> Press me <"

    assert rendered_to_string(~H"""
           <Link.link link_type="live_patch" to="/" label="Press me" />
           """) =~ ">Press me<"

    assert rendered_to_string(~H"""
           <Link.link link_type="live_redirect" to="/" label="Press me" />
           """) =~ ">Press me<"

    assert rendered_to_string(~H"""
           <Link.link to="/">Press me</Link.link>
           """) =~ ">Press me<"

    assert rendered_to_string(~H"""
           <Link.link to="/"> Press me </Link.link>
           """) =~ "> Press me <"

    assert rendered_to_string(~H"""
           <Link.link to="/" label="Press me" />, blah
           """) =~ "</a>, blah"
  end
end
