defmodule PetalComponents.Showcase.TextAnimation do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.TextAnimation,
    title: "Text animation",
    functions: [:gradient_text, :shimmer_text, :typing_effect, :word_rotate]

  example :four_ways, "Four ways to make words move",
    description:
      "gradient_text sweeps a gradient and shimmer_text a highlight - both pure CSS with colour and duration attrs. word_rotate cycles through its list and typing_effect types, each on a tiny hook. All respect prefers-reduced-motion." do
    ~H"""
    <div class="flex flex-col items-center gap-10 text-center">
      <.gradient_text class="text-4xl font-bold">Ship something tonight</.gradient_text>
      <.shimmer_text class="text-2xl font-semibold">Generating your app...</.shimmer_text>
      <div class="text-2xl font-semibold">
        Build
        <.word_rotate
          id="showcase-word-rotate"
          words={["faster", "calmer", "together", "tonight"]}
          class="text-primary-600 dark:text-primary-400"
        />
      </div>
      <.typing_effect
        id="showcase-typing"
        text="mix petal.gen.live Accounts User users"
        class="font-mono text-sm"
      />
    </div>
    """
  end
end
