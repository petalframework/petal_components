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

    assert html =~ "<svg"
  end

  test "it renders a group of avatars with images" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.avatar_group avatars={[
        "image.png",
        "image.png",
        "image.png",
        "image.png",
      ]} size="xs" class="inline-block"/>
      """)

    assert html =~ "<div"
    assert html =~ "-space-x-"
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

    assert html =~ "<svg"
    assert html =~ "dark:"
  end
end
