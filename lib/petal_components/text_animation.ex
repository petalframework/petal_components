defmodule PetalComponents.TextAnimation do
  @moduledoc """
  Animated text effects for hero sections and landing pages.

  * `gradient_text/1` — a gradient that sweeps through the text (pure CSS)
  * `shimmer_text/1` — a band of light passing over the text (pure CSS)
  * `word_rotate/1` — cycles through a list of words (requires the
    `PetalWordRotate` hook from the JS bundle)
  * `typing_effect/1` — types text out character by character with a blinking
    caret (requires the `PetalTypingEffect` hook from the JS bundle)

  The hook-based effects render their full text server-side, so they degrade
  gracefully without JavaScript and stay visible to search engines.
  """
  use Phoenix.Component

  attr :color_from, :string, default: "#ffaa40", doc: "start color of the gradient"
  attr :color_to, :string, default: "#9c40ff", doc: "end color of the gradient"
  attr :duration, :string, default: "8s", doc: "time for one full gradient sweep"
  attr :class, :any, default: nil, doc: "extra classes (set font size/weight here)"
  attr :rest, :global

  slot :inner_block, required: true

  @doc """
  Text filled with an animated gradient that sweeps from end to end.

      <.h1><.gradient_text>Introducing Petal</.gradient_text></.h1>

      <.gradient_text color_from="#38bdf8" color_to="#818cf8" class="text-5xl font-bold">
        Build faster
      </.gradient_text>
  """
  def gradient_text(assigns) do
    assigns =
      assign(
        assigns,
        :style,
        "--pc-gradient-from: #{assigns.color_from}; " <>
          "--pc-gradient-to: #{assigns.color_to}; " <>
          "--pc-gradient-duration: #{assigns.duration};"
      )

    ~H"""
    <span class={["pc-gradient-text", @class]} style={@style} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :duration, :string, default: "2.5s", doc: "time for one full shimmer pass"
  attr :class, :any, default: nil, doc: "extra classes (set font size/weight here)"
  attr :rest, :global

  slot :inner_block, required: true

  @doc """
  Muted text with a band of light sweeping across it — the classic
  "✨ Introducing ..." pill treatment.

      <.shimmer_text class="text-sm font-medium">✨ Introducing Petal Components v4</.shimmer_text>
  """
  def shimmer_text(assigns) do
    ~H"""
    <span
      class={["pc-shimmer-text", @class]}
      style={"--pc-shimmer-duration: #{@duration};"}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :id, :string, required: true
  attr :words, :list, required: true, doc: "the words to cycle through"

  attr :interval, :integer,
    default: 2500,
    doc: "milliseconds each word stays on screen"

  attr :class, :any, default: nil, doc: "extra classes (set font size/weight here)"
  attr :rest, :global

  @doc """
  Cycles through a list of words with a smooth roll-up transition. The first
  word is rendered server-side; the `PetalWordRotate` hook animates the rest.

      <.h1>
        Petal makes your app
        <.word_rotate id="word-rotate" words={["beautiful", "fast", "accessible"]} class="text-primary-600" />
      </.h1>
  """
  def word_rotate(assigns) do
    ~H"""
    <span
      id={@id}
      class={["pc-word-rotate", @class]}
      phx-hook="PetalWordRotate"
      data-words={Phoenix.json_library().encode!(@words)}
      data-interval={@interval}
      {@rest}
    >
      <span class="pc-word-rotate__word">{List.first(@words)}</span>
    </span>
    """
  end

  attr :id, :string, required: true
  attr :text, :string, required: true, doc: "the text to type out"

  attr :speed, :integer, default: 60, doc: "milliseconds per character"

  attr :start_delay, :integer,
    default: 0,
    doc: "milliseconds to wait before typing starts"

  attr :loop, :boolean,
    default: false,
    doc: "delete the text and type it again, forever"

  attr :cursor, :boolean, default: true, doc: "show a blinking caret"
  attr :class, :any, default: nil, doc: "extra classes (set font size/weight here)"
  attr :rest, :global

  @doc """
  A typewriter effect. The full text is rendered server-side (visible without
  JavaScript); the `PetalTypingEffect` hook replays it character by character.

      <.typing_effect id="typing" text="shadcn for Phoenix" class="font-mono" />
  """
  def typing_effect(assigns) do
    ~H"""
    <span
      id={@id}
      class={["pc-typing-effect", @class]}
      phx-hook="PetalTypingEffect"
      data-text={@text}
      data-speed={@speed}
      data-start-delay={@start_delay}
      data-loop={to_string(@loop)}
      {@rest}
    >
      <span class="pc-typing-effect__text">{@text}</span><span
        :if={@cursor}
        class="pc-typing-effect__cursor"
        aria-hidden="true"
      ></span>
    </span>
    """
  end
end
