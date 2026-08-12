defmodule PetalComponents.CssAssetsTest do
  use ExUnit.Case, async: true

  # The shipped stylesheets are consumed by strict downstream parsers
  # (Lightning CSS via Tailwind v4's --minify). These guards keep selector
  # mistakes that plain `mix test` can't see from reaching users' builds.

  @app_root Path.expand("../..", __DIR__)
  @css_assets ["assets/default.css", "assets/tailwind-gray.css"]

  for path <- @css_assets do
    test "#{path} contains no escaped-colon class selectors" do
      css = File.read!(Path.join(@app_root, unquote(path)))

      # pc-* semantic classes never contain colons, so a backslash-escaped
      # colon in this file means a Tailwind utility name (peer-checked:*,
      # dark:*, ...) leaked in as a selector. Those never match anything the
      # components render, and the double-backslash form (`\\:`) additionally
      # trips Lightning CSS with "not a valid pseudo-class" warnings on every
      # consumer asset build (issue #582).
      refute css =~ ~r/\\+:/,
             "#{unquote(path)} contains a backslash-escaped colon selector: " <>
               inspect(Regex.run(~r/^.*\\+:.*$/m, css))
    end
  end

  describe "border_plasma cross-rule invariants" do
    # This CSS section has shipped three cross-rule interaction bugs
    # (custom-property var scoping twice, headroom geometry drift once).
    # These guards pin the invariants a refactor could silently break.

    setup do
      %{css: File.read!(Path.join(@app_root, "assets/default.css"))}
    end

    defp rule_body(css, selector) do
      case Regex.run(~r/#{Regex.escape(selector)}\s*\{([^}]*)\}/s, css) do
        [_, body] -> body
        nil -> flunk("selector not found in default.css: #{selector}")
      end
    end

    test "rotate's aura hide outranks glow-both's show by source order", %{css: css} do
      # Both selectors are specificity (0,2,0): ONLY source order keeps the
      # aura dark for mode="rotate" glow="both" (a legal attr combination).
      # If the rotate rule moves above the glow-both rule, rotate grows a
      # static unmasked halo outside its silhouette.
      show = :binary.match(css, ".pc-border-plasma--glow-both > .pc-border-plasma__aura")
      hide = :binary.match(css, ".pc-border-plasma--rotate > .pc-border-plasma__aura")
      assert {show_pos, _} = show
      assert {hide_pos, _} = hide
      assert hide_pos > show_pos
    end

    test "the aura is dark by default", %{css: css} do
      # The bare one-class rule specifically - not the aura's appearances
      # at the tail of selector lists (hence the no-preceding-comma guard).
      assert [_, body] =
               Regex.run(~r/(?<!,)\n  \.pc-border-plasma__aura \{([^}]*)\}/, css),
             "bare .pc-border-plasma__aura rule not found"

      assert body =~ "display: none"
    end

    test "every ring/wash override resets the halo headroom border", %{css: css} do
      # The base halo rules put 33px/86px transparent borders on core and
      # bloom. Every rule that repurposes those layers with content-box
      # mask or inset-0 geometry must reset the border, or the headroom
      # drags its geometry out from under it.
      for selector <- [
            ".pc-border-plasma--glow-inside > .pc-border-plasma__core,\n  .pc-border-plasma--glow-both > .pc-border-plasma__core",
            ".pc-border-plasma--glow-inside > .pc-border-plasma__bloom",
            ".pc-border-plasma--rotate > .pc-border-plasma__core",
            ".pc-border-plasma--rotate > .pc-border-plasma__bloom"
          ] do
        assert rule_body(css, selector) =~ "border: 0",
               "#{selector} must reset the halo headroom border"
      end
    end

    test "the halo recipes keep their headroom contract", %{css: css} do
      core =
        rule_body(
          css,
          ".pc-border-plasma__core,\n  .pc-border-plasma--glow-both > .pc-border-plasma__aura"
        )

      bloom = rule_body(css, ".pc-border-plasma__bloom")

      # Transparent border = Safari blur headroom (sized ~3x blur radius);
      # origin padding-box keeps the art at the original geometry; no-repeat
      # stops the padding-box-sized image tiling ghost blobs into the band.
      assert core =~ "border: 33px solid transparent"
      assert bloom =~ "border: 86px solid transparent"

      for {name, body} <- [core: core, bloom: bloom] do
        assert body =~ "background-origin: padding-box", "#{name} lost background-origin"
        assert body =~ "background-repeat: no-repeat", "#{name} lost background-repeat"
      end
    end

    test "rotate's geometry is not motion-gated (reduced-motion silhouette contract)", %{css: css} do
      # The full rotate core/bloom recipes must live OUTSIDE the plasma
      # oscillator media block, or reduce users fall through to the base
      # halo and rotate leaks a static outside glow. The oscillator
      # animation list ("pc-plasma-bw1 calc") anchors that block; the
      # first occurrence of each rotate selector is the hoisted geometry
      # rule and must come before it, carrying the full recipe.
      {media_pos, _} = :binary.match(css, "pc-plasma-bw1 calc")

      for selector <- [
            ".pc-border-plasma--rotate > .pc-border-plasma__core",
            ".pc-border-plasma--rotate > .pc-border-plasma__bloom"
          ] do
        {pos, _} = :binary.match(css, selector)
        assert pos < media_pos, "#{selector} geometry is motion-gated"
        body = rule_body(css, selector)
        assert body =~ "mask", "#{selector} hoisted rule lost its mask recipe"
        refute body =~ ~r/animation:/, "#{selector} geometry rule must not carry the animation"
      end
    end

    test "animation shorthands re-declare the pause hook", %{css: css} do
      # `animation:` resets animation-play-state at its own specificity,
      # which silently kills the viewport observer's pause (that shipped).
      # Every plasma rule using the shorthand must re-declare the longhand.
      plasma_shorthand_rules =
        Regex.scan(~r/\.pc-border-plasma[^{]*\{[^}]*animation:\s*pc-plasma[^}]*\}/s, css)

      assert plasma_shorthand_rules != []

      for [rule] <- plasma_shorthand_rules do
        assert rule =~ "animation-play-state: var(--pc-plasma-play, running)",
               "a plasma animation shorthand lost its play-state re-declaration:\n" <>
                 String.slice(rule, 0, 200)
      end
    end

    test "forced-colors drops the transparent-border halo layers", %{css: css} do
      # WHCM repaints transparent borders in an opaque system colour, so
      # the headroom borders would render as giant blurred frames.
      [_, after_media] = String.split(css, "@media (forced-colors: active)", parts: 2)
      [guard_block | _] = String.split(after_media, "\n  }\n", parts: 2)
      assert guard_block =~ ".pc-border-plasma__core"
      assert guard_block =~ ".pc-border-plasma__bloom"
      assert guard_block =~ ".pc-border-plasma--glow-both > .pc-border-plasma__aura"
      assert guard_block =~ "display: none"
    end
  end
end
