defmodule PetalComponents.AvatarTest do
  use ComponentCase
  import PetalComponents.Avatar

  test "it renders the avatar correctly" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.avatar src="image.png" />
      """)

    assert html =~ "<img"
  end

  test "it renders the avatar with placeholder" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.avatar />
      """)

    assert has_icon?(html)
  end

  test "it renders a group of avatars with images" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.avatar_group
        avatars={[
          "image.png",
          "image.png",
          "image.png",
          "image.png"
        ]}
        size="xs"
        class="inline-block"
      />
      """)

    assert html =~ "<div"
    assert html =~ "pc-avatar-group--xs"
  end

  test "it renders the avatar with initials" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.avatar name="John Smith" />
      """)

    assert html =~ "<div style"
  end

  test "it renders the avatar with initials and randomly generates the color correctly" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.avatar name="John Smith" random_color />
      """)

    assert html =~ "background-color:"
  end

  test "dark mode" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.avatar />
      """)

    assert has_icon?(html)
  end

  test "should include additional assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.avatar custom-attrs="123" src="image.png" />
      <.avatar custom-attrs="456" />
      <.avatar name="John Smith" custom-attrs="789" />
      """)

    assert html =~ ~s{custom-attrs="123"}
    assert html =~ ~s{custom-attrs="456"}
    assert html =~ ~s{custom-attrs="789"}
  end

  test "status renders a ringed presence dot in a relative anchor" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.avatar name="Grace Hopper" status="online" />
      """)

    assert html =~ "pc-avatar-anchor"
    assert html =~ "pc-avatar__status--online"
    assert html =~ "pc-avatar__status--md"
    assert html =~ ~s(aria-label="online")
  end

  test "avatar_group max renders the +N overflow bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.avatar_group avatars={["/a.jpg", "/b.jpg", "/c.jpg", "/d.jpg", "/e.jpg"]} max={3} />
      """)

    assert 3 == html |> String.split("pc-avatar--with-image") |> length() |> Kernel.-(1)
    assert html =~ "pc-avatar-group__overflow"
    assert html =~ "+2"
    assert html =~ ~s(aria-label="2 more")
  end
end
