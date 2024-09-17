defmodule PetalComponents.BreadcrumbsTest do
  use ComponentCase
  import PetalComponents.Breadcrumbs

  test "breadcrumbs" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.breadcrumbs
        class="text-md"
        links={[
          %{label: "Link 1", to: "/", icon: "hero-home"}
        ]}
      />
      """)

    assert html =~ "Link 1"
    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "text-md"
    assert html =~ "hero-home"
    assert find_icon(html, "hero-home")
  end

  test "breadcrumbs with no label" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.breadcrumbs
        class="text-md"
        links={[
          %{to: "/", icon: "hero-home"}
        ]}
      />
      """)

    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "text-md"
    assert html =~ "hero-home"
    assert find_icon(html, "hero-home")
  end

  test "breadcrumb_patch" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.breadcrumbs
        class="text-md"
        links={[
          %{label: "Link 1", to: "/", link_type: "live_patch"}
        ]}
      />
      """)

    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "patch"
  end

  test "breadcrumb_redirect" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.breadcrumbs
        class="text-md"
        links={[
          %{label: "Link 1", to: "/", link_type: "live_redirect"}
        ]}
      />
      """)

    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "redirect"
  end

  test "dark mode" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.breadcrumbs
        class="text-md"
        links={[
          %{label: "Link 1", to: "/"}
        ]}
      />
      """)

    assert html =~ "Link 1"
    assert html =~ "<a"
    assert html =~ "href"
    assert html =~ "text-md"
    assert html =~ "pc-breadcrumb"
  end

  test "should include additional assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.breadcrumbs
        custom-attrs="123"
        class="text-md"
        links={[
          %{label: "Link 1", to: "/"}
        ]}
      />
      """)

    assert html =~ ~s{custom-attrs="123"}
  end

  test "render multiple links with default separator" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.breadcrumbs
        class="text-md"
        links={[
          %{label: "Link 1", to: "/"},
          %{label: "Link 2", to: "/"}
        ]}
      />
      """)

    assert html =~ "pc-breadcrumbs__separator-slash"
  end

  test "render multiple links with chevron separator" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.breadcrumbs
        separator="chevron"
        class="text-md"
        links={[
          %{label: "Link 1", to: "/"},
          %{label: "Link 2", to: "/"}
        ]}
      />
      """)

    assert html =~ "pc-breadcrumbs__separator-chevron"
    assert find_icon(html, "hero-chevron-right-solid")
  end
end
