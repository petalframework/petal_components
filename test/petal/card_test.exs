defmodule PetalComponents.CardTest do
  use ComponentCase
  import PetalComponents.Card

  test "Basic card" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card>
        <.card_content category="Article" heading="Enhance your Phoenix development">
          <div class="mt-4 font-light text-gray-500 text-md">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eget leo interdum, feugiat ligula eu, facilisis massa. Nunc sollicitudin massa a elit laoreet.
          </div>
        </.card_content>
      </.card>
      """)

    assert html =~ "Enhance"
    assert html =~ "Article"
    assert html =~ "pc-card--basic"
  end

  test "Outline card" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card variant="outline">
        <.card_content category="Article" heading="Enhance your Phoenix development">
          <div class="mt-4 font-light text-gray-500 text-md">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eget leo interdum, feugiat ligula eu, facilisis massa. Nunc sollicitudin massa a elit laoreet.
          </div>
        </.card_content>
      </.card>
      """)

    assert html =~ "Enhance"
    assert html =~ "Article"
    assert html =~ "pc-card--outline"
  end

  test "Card with media no url" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card variant="outline">
        <.card_media class="h-48" />
        <.card_content category="Article" heading="Enhance your Phoenix development">
          <div class="mt-4 font-light text-gray-500 text-md">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eget leo interdum, feugiat ligula eu, facilisis massa. Nunc sollicitudin massa a elit laoreet.
          </div>
        </.card_content>
      </.card>
      """)

    assert html =~ "Enhance"
    assert html =~ "Article"
    assert html =~ "pc-card--outline"
    assert html =~ "pc-card__image-placeholder"
  end

  test "Card with media and url" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card variant="outline">
        <.card_media
          class="h-48"
          src="https://images.unsplash.com/photo-1551434678-e076c223a692?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2340&q=80"
        />
        <.card_content category="Article" heading="Enhance your Phoenix development">
          <div class="mt-4 font-light text-gray-500 text-md">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eget leo interdum, feugiat ligula eu, facilisis massa. Nunc sollicitudin massa a elit laoreet.
          </div>
        </.card_content>
      </.card>
      """)

    assert html =~ "Enhance"
    assert html =~ "Article"
    assert html =~ "pc-card--outline"
    assert html =~ "<img"
  end

  test "dark mode" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card variant="outline">
        <.card_media
          class="h-48"
          src="https://images.unsplash.com/photo-1551434678-e076c223a692?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2340&q=80"
        />
        <.card_content category="Article" heading="Enhance your Phoenix development">
          <div class="mt-4 font-light text-gray-500 text-md">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eget leo interdum, feugiat ligula eu, facilisis massa. Nunc sollicitudin massa a elit laoreet.
          </div>
        </.card_content>
      </.card>
      """)

    assert html =~ "Enhance"
    assert html =~ "Article"
    assert html =~ "pc-card--outline"
    assert html =~ "<img"
  end

  test "should include additional assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card variant="outline" custom-attr="1">
        <.card_media
          custom-attr="2"
          class="h-48"
          src="https://images.unsplash.com/photo-1551434678-e076c223a692?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2340&q=80"
        />
        <.card_media custom-attr="3" class="h-48" />
        <.card_content custom-attr="4" category="Article" heading="Enhance your Phoenix development">
          <div class="mt-4 font-light text-gray-500 text-md">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eget leo interdum, feugiat ligula eu, facilisis massa. Nunc sollicitudin massa a elit laoreet.
          </div>
        </.card_content>
        <.card_footer class="footer-class" custom-attr="5">FOOTER</.card_footer>
      </.card>
      """)

    for i <- 1..5 do
      assert html =~ ~s{custom-attr="#{i}"}
    end

    assert html =~ "footer-class"
  end

  @sample_review %{
    name: "John Doe",
    username: "@johndoe",
    img: "https://example.com/avatar.jpg",
    body: "This is an amazing product!"
  }

  describe "basic rendering" do
    test "renders with all required attributes" do
      assigns = @sample_review

      html =
        rendered_to_string(~H"""
        <.review_card name={@name} username={@username} img={@img} body={@body} />
        """)

      assert html =~ "pc-review-card"
      assert html =~ "John Doe"
      assert html =~ "@johndoe"
      assert html =~ "This is an amazing product!"
      assert html =~ "https://example.com/avatar.jpg"
    end

    test "renders with proper semantic elements" do
      assigns = @sample_review

      html =
        rendered_to_string(~H"""
        <.review_card name={@name} username={@username} img={@img} body={@body} />
        """)

      assert html =~ "<figure"
      assert html =~ "<figcaption"
      assert html =~ "<blockquote"
    end
  end

  describe "component structure" do
    test "includes all necessary sections" do
      assigns = @sample_review

      html =
        rendered_to_string(~H"""
        <.review_card name={@name} username={@username} img={@img} body={@body} />
        """)

      assert html =~ "pc-review-header"
      assert html =~ "pc-review-meta"
      assert html =~ "pc-review-name"
      assert html =~ "pc-review-username"
      assert html =~ "pc-review-body"
    end

    test "renders avatar component" do
      assigns = @sample_review

      html =
        rendered_to_string(~H"""
        <.review_card name={@name} username={@username} img={@img} body={@body} />
        """)

      assert html =~ "pc-avatar"
      assert html =~ ~s(src="https://example.com/avatar.jpg")
    end
  end

  describe "customization" do
    test "applies custom classes" do
      assigns = Map.put(@sample_review, :custom_class, "my-custom-class")

      html =
        rendered_to_string(~H"""
        <.review_card name={@name} username={@username} img={@img} body={@body} class={@custom_class} />
        """)

      assert html =~ "my-custom-class"
    end

    test "passes through rest attributes" do
      assigns = @sample_review

      html =
        rendered_to_string(~H"""
        <.review_card
          name={@name}
          username={@username}
          img={@img}
          body={@body}
          data-test="review-card"
          aria-label="Review"
        />
        """)

      assert html =~ ~s(data-test="review-card")
      assert html =~ ~s(aria-label="Review")
    end
  end

  describe "typography components" do
    test "uses typography components with correct classes" do
      assigns = @sample_review

      html =
        rendered_to_string(~H"""
        <.review_card name={@name} username={@username} img={@img} body={@body} />
        """)

      assert html =~ "text-sm"
      assert html =~ "pc-text"
    end
  end

  describe "validation" do
    test "raises error when required attributes are missing" do
      base_assigns = %{rest: %{}, __changed__: nil, class: "", __given__: %{__changed__: nil}}

      message = "key :img not found in: " <> inspect(base_assigns, pretty: true)

      assert_raise KeyError, message, fn ->
        assigns = %{}

        rendered_to_string(~H"""
        <.review_card />
        """)
      end

      assigns_with_name =
        Map.merge(base_assigns, %{
          name: "John",
          __given__: %{name: "John", __changed__: nil}
        })

      message = "key :img not found in: " <> inspect(assigns_with_name, pretty: true)

      assert_raise KeyError, message, fn ->
        assigns = %{name: "John"}

        rendered_to_string(~H"""
        <.review_card name={@name} />
        """)
      end

      assigns_with_username =
        Map.merge(base_assigns, %{
          name: "John",
          username: "@john",
          __given__: %{name: "John", username: "@john", __changed__: nil}
        })

      message = "key :img not found in: " <> inspect(assigns_with_username, pretty: true)

      assert_raise KeyError, message, fn ->
        assigns = %{name: "John", username: "@john"}

        rendered_to_string(~H"""
        <.review_card name={@name} username={@username} />
        """)
      end

      assigns_with_img =
        Map.merge(base_assigns, %{
          name: "John",
          username: "@john",
          img: "test.jpg",
          __given__: %{name: "John", username: "@john", img: "test.jpg", __changed__: nil}
        })

      message = "key :body not found in: " <> inspect(assigns_with_img, pretty: true)

      assert_raise KeyError, message, fn ->
        assigns = %{name: "John", username: "@john", img: "test.jpg"}

        rendered_to_string(~H"""
        <.review_card name={@name} username={@username} img={@img} />
        """)
      end
    end
  end
end
