defmodule PetalComponents.BrandIconTest do
  use ComponentCase

  import PetalComponents.BrandIcon

  test "every registered name renders an svg with path data" do
    for name <- PetalComponents.BrandIcon.names() do
      assigns = %{name: name}

      html =
        rendered_to_string(~H"""
        <.brand_icon name={@name} />
        """)

      assert html =~ "<svg", "#{name} did not render an svg"
      assert html =~ "pc-brand-icon"
      assert html =~ ~s(d="M) or html =~ ~s(d="m), "#{name} has no path data"
    end
  end

  test "monochrome by default: every path is currentColor" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.brand_icon name="google" />
      """)

    fills =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("path")
      |> LazyHTML.attribute("fill")

    assert length(fills) == 4
    assert Enum.all?(fills, &(&1 == "currentColor"))
  end

  test "colored renders Google's four official colours" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.brand_icon name="google" colored />
      """)

    fills =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("path")
      |> LazyHTML.attribute("fill")

    assert Enum.sort(fills) == Enum.sort(["#4285F4", "#34A853", "#FBBC05", "#EB4335"])
  end

  test "black brands stay currentColor even when colored (dark mode legibility)" do
    for name <- ~w(github apple x) do
      assigns = %{name: name}

      html =
        rendered_to_string(~H"""
        <.brand_icon name={@name} colored />
        """)

      assert html =~ ~s(fill="currentColor"), "#{name} colored should remain currentColor"
    end
  end

  test "decorative by default, overridable for standalone use" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.brand_icon name="discord" />
      """)

    assert html =~ ~s(aria-hidden="true")

    html =
      rendered_to_string(~H"""
      <.brand_icon name="discord" role="img" aria-label="Discord" class="w-6 h-6" />
      """)

    assert html =~ ~s(role="img")
    assert html =~ ~s(aria-label="Discord")
    assert html =~ "w-6 h-6"
  end
end
