defmodule PetalComponents.TextAnimationTest do
  use ComponentCase
  import PetalComponents.TextAnimation

  describe "gradient_text/1" do
    test "renders with base class and default gradient variables" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.gradient_text>Introducing Petal</.gradient_text>
        """)

      assert html =~ "pc-gradient-text"
      assert html =~ "Introducing Petal"
      assert html =~ "--pc-gradient-from: #ffaa40"
      assert html =~ "--pc-gradient-to: #9c40ff"
      assert html =~ "--pc-gradient-duration: 8s"
    end

    test "applies custom colors, duration and class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.gradient_text color_from="#38bdf8" color_to="#818cf8" duration="4s" class="text-5xl">
          Fast
        </.gradient_text>
        """)

      assert html =~ "--pc-gradient-from: #38bdf8"
      assert html =~ "--pc-gradient-to: #818cf8"
      assert html =~ "--pc-gradient-duration: 4s"
      assert html =~ "text-5xl"
    end
  end

  describe "shimmer_text/1" do
    test "renders with base class and duration variable" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.shimmer_text>✨ Introducing</.shimmer_text>
        """)

      assert html =~ "pc-shimmer-text"
      assert html =~ "✨ Introducing"
      assert html =~ "--pc-shimmer-duration: 2.5s"
    end

    test "applies custom duration and class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.shimmer_text duration="5s" class="text-sm">Hello</.shimmer_text>
        """)

      assert html =~ "--pc-shimmer-duration: 5s"
      assert html =~ "text-sm"
    end
  end

  describe "word_rotate/1" do
    test "renders the first word with the hook and encoded word list" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.word_rotate id="rotate" words={["beautiful", "fast"]} />
        """)

      assert html =~ "pc-word-rotate"
      assert html =~ "pc-word-rotate__word"
      assert html =~ ~s(phx-hook="PetalWordRotate")
      assert html =~ ~s(id="rotate")
      assert html =~ "beautiful"
      assert html =~ "data-words="
      assert html =~ ~s(data-interval="2500")
    end

    test "applies a custom interval" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.word_rotate id="rotate" words={["a", "b"]} interval={4000} />
        """)

      assert html =~ ~s(data-interval="4000")
    end
  end

  describe "typing_effect/1" do
    test "renders the full text server-side with the hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.typing_effect id="typing" text="mix igniter.install petal_components" />
        """)

      assert html =~ "pc-typing-effect"
      assert html =~ "pc-typing-effect__text"
      assert html =~ ~s(phx-hook="PetalTypingEffect")
      assert html =~ "mix igniter.install petal_components"
      assert html =~ ~s(data-speed="60")
      assert html =~ ~s(data-loop="false")
      assert html =~ "pc-typing-effect__cursor"
    end

    test "hides the cursor when disabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.typing_effect id="typing" text="hello" cursor={false} />
        """)

      refute html =~ "pc-typing-effect__cursor"
    end

    test "applies loop, speed and start_delay" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.typing_effect id="typing" text="hello" loop speed={30} start_delay={500} />
        """)

      assert html =~ ~s(data-loop="true")
      assert html =~ ~s(data-speed="30")
      assert html =~ ~s(data-start-delay="500")
    end
  end
end
