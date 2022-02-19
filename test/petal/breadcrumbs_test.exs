defmodule PetalComponents.BreadcrumbsTest do
  use ComponentCase
  import PetalComponents.Breadcrumbs

  test "breadcrumbs" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.breadcrumbs class="text-md" links={[
        %{ label: "Link 1", to: "/" }
      ]} />
      """)

    assert html =~ "Link 1"
    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "text-md"
  end

  test "breadcrumb_patch" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.breadcrumbs class="text-md" links={[
        %{ label: "Link 1", to: "/", link_type: "live_patch" }
      ]} />
      """)

    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "patch"
  end

  test "breadcrumb_redirect" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.breadcrumbs class="text-md" links={[
        %{ label: "Link 1", to: "/", link_type: "live_redirect" }
      ]} />
      """)

    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "redirect"
  end

  test "dark mode" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.breadcrumbs class="text-md" links={[
        %{ label: "Link 1", to: "/" }
      ]} />
      """)

    assert html =~ "Link 1"
    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "text-md"
    assert html =~ "dark:"
  end

  test "should include additional assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.breadcrumbs custom-attrs="123" class="text-md" links={[
        %{ label: "Link 1", to: "/" }
      ]} />
      """)

    assert html =~ ~s{custom-attrs="123"}
  end
end
