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

  test "random_gradient renders a deterministic gradient hashed from the name" do
    assigns = %{}

    render = fn ->
      rendered_to_string(~H"""
      <.avatar name="Ada Lovelace" random_gradient />
      """)
    end

    html = render.()
    assert html =~ "linear-gradient"
    # same name, same gradient
    assert html == render.()
  end

  test "random_gradient wins over random_color when both are set" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.avatar name="Ada Lovelace" random_color random_gradient />
      """)

    assert html =~ "linear-gradient"
    refute html =~ "background-color:"
  end

  test "art mesh draws a deterministic radial mesh with no initials" do
    assigns = %{}

    render = fn ->
      rendered_to_string(~H"""
      <.avatar name="Ada Lovelace" art="mesh" />
      """)
    end

    html = render.()
    assert html =~ "pc-avatar--art"
    assert html =~ "radial-gradient"
    # no initials render; the name still labels the avatar
    refute html =~ ">AL<"
    assert html =~ ~s(aria-label="Ada Lovelace")
    assert html == render.()
  end

  test "art dither embeds an inline svg data uri" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.avatar name="Ada Lovelace" art="dither" />
      """)

    assert html =~ "data:image/svg+xml"
    assert html =~ "pc-avatar--art"
  end

  test "art initials overlays a contrast-managed monogram" do
    assigns = %{}

    mesh =
      rendered_to_string(~H"""
      <.avatar name="Ada Lovelace" art="mesh" initials />
      """)

    dither =
      rendered_to_string(~H"""
      <.avatar name="Ada Lovelace" art="dither" initials />
      """)

    assert mesh =~ "AL"
    # dark hue-tinted monogram
    assert mesh =~ "color: hsl("
    assert dither =~ "AL"
    assert dither =~ "color: hsl("

    # the quieted dither palette differs from the pure-art one
    pure =
      rendered_to_string(~H"""
      <.avatar name="Ada Lovelace" art="dither" />
      """)

    refute pure =~ "AL"
    refute dither == pure
  end

  test "shape rounded applies across photo, initials and art variants" do
    assigns = %{}

    photo =
      rendered_to_string(~H"""
      <.avatar src="/a.jpg" shape="rounded" />
      """)

    initials =
      rendered_to_string(~H"""
      <.avatar name="Ada Lovelace" shape="rounded" />
      """)

    art =
      rendered_to_string(~H"""
      <.avatar name="Ada Lovelace" art="mesh" shape="rounded" />
      """)

    for html <- [photo, initials, art], do: assert(html =~ "pc-avatar--rounded")

    # circle default carries no modifier
    circle =
      rendered_to_string(~H"""
      <.avatar src="/a.jpg" />
      """)

    refute circle =~ "pc-avatar--rounded"
  end

  test "avatar_group threads shape to children and the overflow bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.avatar_group shape="rounded" max={1} avatars={["/a.jpg", "/b.jpg"]} />
      """)

    # the shown avatar and the +1 bubble both carry the modifier
    assert length(String.split(html, "pc-avatar--rounded")) == 3
  end

  test "a photo src wins over art" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.avatar src="/a.jpg" name="Ada Lovelace" art="mesh" />
      """)

    assert html =~ "pc-avatar--with-image"
    refute html =~ "pc-avatar--art"
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
