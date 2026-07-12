defmodule PetalComponents.Aurora do
  use Phoenix.Component

  alias PetalComponents.Helpers

  @default_colors ["#3b82f6", "#a5b4fc", "#93c5fd", "#ddd6fe", "#60a5fa"]

  @doc """
  A soft animated aurora glow behind your content - the hero-section
  backdrop. Pure CSS (blurred repeating gradients blended over a stripe
  texture); the optional `PetalAurora` hook pauses the animation while the
  section is off-screen.

  The wrapper sizes to its content, so a padded hero just works:

      <.aurora class="rounded-2xl">
        <div class="px-8 py-24 text-center">
          <h1>Ship your SaaS this weekend</h1>
          <.button label="Get started" />
        </div>
      </.aurora>

  Pass any palette and the gradient is built for you:

      <.aurora colors={["#f97316", "#f43f5e", "#fbbf24"]}>...</.aurora>

  By default the effect auto-adapts: inverted on light backgrounds,
  un-inverted in dark mode (`invert="always"` / `invert="none"` to force).
  Respects `prefers-reduced-motion` (the drift freezes, the glow stays).
  """
  attr :id, :string, doc: "defaults to a generated id (needed by the pause-offscreen hook)"

  attr :colors, :list,
    default: @default_colors,
    doc: "3-6 CSS colors; the aurora gradient is built from them in order"

  attr :invert, :string,
    default: "auto",
    values: ["auto", "none", "always"],
    doc: "auto inverts on light and not in dark; none/always force one look"

  attr :speed, :string, default: "60s", doc: "duration of one drift cycle"
  attr :opacity, :string, default: "0.5", doc: "strength of the glow"
  attr :blur, :string, default: "10px", doc: "softness of the glow"

  attr :mask_position, :string,
    default: "100% 0",
    doc: "where the glow concentrates (radial mask origin), e.g. \"50% 0\" for top-centre"

  attr :mask_coverage, :string,
    default: "10%, 70%",
    doc: "inner/outer stops of the radial mask - widen to flood more of the container"

  attr :class, :any, default: nil, doc: "CSS class"
  attr :rest, :global
  slot :inner_block

  def aurora(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> Helpers.uniq_id("pc-aurora") end)
      |> assign(:style, build_style(assigns))

    ~H"""
    <div
      id={@id}
      class={[
        "pc-aurora",
        @invert == "always" && "pc-aurora--invert",
        @invert == "none" && "pc-aurora--no-invert",
        @class
      ]}
      style={@style}
      phx-hook="PetalAurora"
      {@rest}
    >
      <div class="pc-aurora__backdrop" aria-hidden="true">
        <div class="pc-aurora__lights" data-pc-aurora></div>
      </div>
      <div class="pc-aurora__content">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp build_style(assigns) do
    [
      "--pc-aurora-gradient: #{gradient(assigns.colors)};",
      "--pc-aurora-speed: #{assigns.speed};",
      "--pc-aurora-opacity: #{assigns.opacity};",
      "--pc-aurora-blur: #{assigns.blur};",
      "--pc-aurora-mask-position: #{assigns.mask_position};",
      "--pc-aurora-mask-coverage: #{assigns.mask_coverage};"
    ]
    |> Enum.join(" ")
  end

  # ["#a", "#b", "#c"] -> repeating-linear-gradient(100deg, #a 10%, #b 15%, #c 20%)
  defp gradient(colors) do
    stops =
      colors
      |> Enum.with_index()
      |> Enum.map_join(", ", fn {color, i} -> "#{color} #{10 + i * 5}%" end)

    "repeating-linear-gradient(100deg, #{stops})"
  end
end
