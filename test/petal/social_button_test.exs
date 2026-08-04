defmodule PetalComponents.SocialButtonTest do
  use ComponentCase

  import PetalComponents.SocialButton

  test "renders an outline button with the coloured glyph and auto label by default" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.social_button provider="google" />
      """)

    assert html =~ "<button"
    assert html =~ "pc-button"
    assert html =~ "pc-button--md"
    assert html =~ "pc-button--gray-outline"
    assert html =~ "pc-social-button"
    assert html =~ "Continue with Google"
    assert html =~ ~s(fill="#4285F4")
  end

  test "solid paints the provider class and goes monochrome" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.social_button provider="github" variant="solid" />
      """)

    assert html =~ "pc-social-button--github"
    refute html =~ "pc-button--gray-outline"
    assert html =~ ~s(fill="currentColor")
    assert html =~ "Continue with GitHub"
  end

  test "href renders a link - OAuth flows are plain GETs" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.social_button provider="google" href="/auth/google" />
      """)

    assert html =~ "<a"
    assert html =~ ~s(href="/auth/google")
    refute html =~ "<button"
  end

  test "custom label and size" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.social_button provider="google" label="Login with Google" size="sm" />
      """)

    assert html =~ "Login with Google"
    refute html =~ "Continue with Google"
    assert html =~ "pc-button--sm"
  end

  test "icon_only hides the text and becomes the accessible name" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.social_button provider="discord" icon_only />
      """)

    assert html =~ ~s(aria-label="Continue with Discord")
    assert html =~ "pc-social-button--icon-only"

    refute html
           |> LazyHTML.from_fragment()
           |> LazyHTML.query("button > span")
           |> Enum.any?()
  end

  test "phx bindings pass through on the button form" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.social_button provider="x" phx-click="oauth" phx-value-provider="x" />
      """)

    assert html =~ ~s(phx-click="oauth")
    assert html =~ ~s(phx-value-provider="x")
    assert html =~ "Continue with X"
  end
end
