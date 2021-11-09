defmodule PetalComponents.BreadcrumbsTest do
  use ComponentCase
  import PetalComponents.Breadcrumbs

  test "breadcrumbs" do
    assigns = %{}

    html = rendered_to_string(
      ~H"""
      <.breadcrumbs links={[
        %{ label: "Link 1", to: "/", link_type: "live_patch" }
        ]} class="text-md"
      />
      """
    )
    assert html =~ "Link 1"
    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "patch"
  end

  test "breadcrumb" do
    assigns = %{}

    html = rendered_to_string(
      ~H"""
      <.breadcrumb to="/" label="a" separator="chevron" />
      """
    )
    assert html =~ "a"
    assert html =~ "<a"
    assert html =~ "href"
  end

  test "breadcrumb_patch" do
    assigns = %{}

    html = rendered_to_string(
      ~H"""
      <.breadcrumb to="/" label="Live Patch" separator="chevron" link_type="live_patch" />
      """
    )
    assert html =~ "Live Patch"
    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "patch"
  end

  test "breadcrumb_redirect" do
    assigns = %{}

    html = rendered_to_string(
      ~H"""
      <.breadcrumb to="/" label="Live Redirect" separator="chevron" link_type="live_redirect" />
      """
    )
    assert html =~ "Live Redirect"
    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "redirect"
  end
end
