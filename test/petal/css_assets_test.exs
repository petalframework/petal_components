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

  describe "badge status dot" do
    # The dot's colour lives entirely in CSS - the markup is one class on
    # every colour x variant combination - so this is the only place the
    # mapping can be checked at all.

    @badge_colors ~w(primary secondary info success warning danger gray)

    setup do
      %{css: File.read!(Path.join(@app_root, "assets/default.css"))}
    end

    test "the base dot is a currentColor circle", %{css: css} do
      body = rule_body(css, ".pc-badge__dot")

      # currentColor is what makes the `dark` variant work without a rule of
      # its own: on a saturated 600 fill no stop of the same ramp reads, and
      # inheriting the text colour picks up primary-dark's
      # --pc-button-solid-fg token instead of hardcoding white.
      assert body =~ "bg-current"
      assert body =~ "rounded-full"
      assert body =~ "shrink-0", "the dot must not squash when the label is long"
    end

    test "every colour maps its dot onto the ramp", %{css: css} do
      for color <- @badge_colors do
        # light keeps a pale surface in both schemes (bg-100 / dark:bg-200),
        # so its dot is scheme-invariant.
        light = rule_body(css, ".pc-badge--#{color}-light .pc-badge__dot")
        assert light =~ "bg-#{color}-600"
        refute light =~ "dark:", "#{color}-light's surface doesn't change with the scheme"

        # soft and outline follow their own text down the ramp in the dark.
        tinted =
          rule_body(
            css,
            ".pc-badge--#{color}-soft .pc-badge__dot,\n  .pc-badge--#{color}-outline .pc-badge__dot"
          )

        assert tinted =~ "bg-#{color}-600"
        assert tinted =~ "dark:bg-#{color}-400"
      end
    end

    test "the dark variant takes no dot colour of its own", %{css: css} do
      # A `bg-<color>-600` dot on a `bg-<color>-600` badge is an invisible
      # dot. dark must fall through to the base rule's currentColor.
      for color <- @badge_colors do
        refute css =~ ".pc-badge--#{color}-dark .pc-badge__dot",
               "#{color}-dark overrides the dot colour; it must inherit currentColor"
      end
    end

    test "the dot gap outranks the icon gap by source order", %{css: css} do
      # Both selectors are one class deep (0,1,0), so ONLY source order
      # gives a dot-plus-icon badge the roomier gap. If --with-dot moves
      # above --with-icon the dot crowds the label whenever both are set.
      {icon_pos, _} = :binary.match(css, ".pc-badge--with-icon {")
      {dot_pos, _} = :binary.match(css, ".pc-badge--with-dot {")
      assert dot_pos > icon_pos

      assert rule_body(css, ".pc-badge--with-dot") =~ "gap-"
    end
  end

  describe "badge dot colour override" do
    # dot_color's whole promise is that it moves the dot's hue and nothing
    # else. Both halves of that - the stops, and the source order that lets
    # them win - live in CSS, so this is the only place to hold them.

    setup do
      %{css: File.read!(Path.join(@app_root, "assets/default.css"))}
    end

    test "each override matches the stop an inherited dot of that colour shows", %{css: css} do
      # Compared declaration for declaration, not by eye: a dot_color="success"
      # dot on an outline badge has to be the same green a success outline
      # badge's own dot is, in both schemes.
      for color <- @badge_colors do
        assert rule_body(css, ".pc-badge__dot.pc-badge__dot--#{color}-light") ==
                 rule_body(css, ".pc-badge--#{color}-light .pc-badge__dot"),
               "#{color} override on light diverges from the inherited stop"

        assert rule_body(
                 css,
                 ".pc-badge__dot.pc-badge__dot--#{color}-soft,\n  .pc-badge__dot.pc-badge__dot--#{color}-outline"
               ) ==
                 rule_body(
                   css,
                   ".pc-badge--#{color}-soft .pc-badge__dot,\n  .pc-badge--#{color}-outline .pc-badge__dot"
                 ),
               "#{color} override on soft/outline diverges from the inherited stop"
      end
    end

    test "the dark variant override takes the 400 stop", %{css: css} do
      # `dark` is the one variant with no inherited stop to match - its dot
      # is currentColor - so an override there picks the stop this file
      # already uses for a dot against a dark surface, and does so in both
      # schemes because the fill is dark in both.
      for color <- @badge_colors do
        body = rule_body(css, ".pc-badge__dot.pc-badge__dot--#{color}-dark")

        assert body =~ "bg-#{color}-400"
        refute body =~ "dark:", "a dark-variant badge is a dark surface in either scheme"
      end
    end

    test "an override sets a colour and nothing else", %{css: css} do
      # Size, gap and whitespace are settled once, above. A stop rule that
      # grew geometry would change a dot's shape when it changed its hue.
      for color <- @badge_colors,
          selector <- [
            ".pc-badge__dot.pc-badge__dot--#{color}-light",
            ".pc-badge__dot.pc-badge__dot--#{color}-soft,\n  .pc-badge__dot.pc-badge__dot--#{color}-outline",
            ".pc-badge__dot.pc-badge__dot--#{color}-dark"
          ] do
        body = css |> rule_body(selector) |> String.trim()

        assert Regex.match?(~r/^@apply bg-#{color}-\d00( dark:bg-#{color}-\d00)?;$/, body),
               "#{selector} must set a background colour and nothing else, got: #{body}"
      end
    end

    test "the override outranks the inherited mapping by source order", %{css: css} do
      # Both sides are (0,2,0) - a descendant pair one way, the dot class
      # doubled the other - so ONLY source order lets dot_color win. Move
      # this block above the inherited one and dot_color silently does
      # nothing on every variant but `dark`.
      {inherited, _} = :binary.match(css, ".pc-badge--gray-outline .pc-badge__dot {")
      {override, _} = :binary.match(css, ".pc-badge__dot.pc-badge__dot--gray-outline {")
      assert override > inherited
    end
  end

  describe "dropdown side-out anatomy" do
    # side="left"/"right" put the panel BESIDE the trigger. The Elixir side
    # only emits two class names; everything about where the panel actually
    # lands is here, so this is the only place the geometry can be checked.

    setup do
      %{css: File.read!(Path.join(@app_root, "assets/default.css"))}
    end

    test "each side anchors on the trigger's far edge with a horizontal gap", %{css: css} do
      left = rule_body(css, ".pc-dropdown__menu-items-wrapper-side--left")
      assert left =~ "right-full", "a left-side panel hangs off the trigger's left edge"
      assert left =~ "mr-2"

      right = rule_body(css, ".pc-dropdown__menu-items-wrapper-side--right")
      assert right =~ "left-full", "a right-side panel hangs off the trigger's right edge"
      assert right =~ "ml-2"
    end

    test "the vertical margin is cleared, and only source order does it", %{css: css} do
      # The base rule's mt-2 is the gap for a panel that opens downward.
      # Beside the trigger the gap is horizontal, so the top margin has to
      # go - and both selectors are one class deep (0,1,0), so nothing but
      # order decides it. Move these above the base rule and every side-out
      # panel picks up 8px of drop it should not have.
      {base_pos, _} = :binary.match(css, ".pc-dropdown__menu-items-wrapper {")

      for side <- ~w(left right) do
        selector = ".pc-dropdown__menu-items-wrapper-side--#{side}"
        assert rule_body(css, selector) =~ "mt-0"
        {side_pos, _} = :binary.match(css, selector <> " {")
        assert side_pos > base_pos
      end
    end

    test "align anchors the panel vertically when it is beside the trigger", %{css: css} do
      # start = tops flush, end = bottoms flush (the sidebar-bottom one).
      assert rule_body(css, ".pc-dropdown__menu-items-wrapper-align--start") =~ "top-0"
      assert rule_body(css, ".pc-dropdown__menu-items-wrapper-align--end") =~ "bottom-0"
    end

    test "the transform origin is split across the two rules", %{css: css} do
      # Four corners out of two classes: the side rule hands its horizontal
      # half over in a custom property and the align rule spends it. If a
      # side rule stops publishing the property the align rules silently
      # fall back to the left column and a left-side panel unfolds from the
      # wrong corner.
      assert rule_body(css, ".pc-dropdown__menu-items-wrapper-side--left") =~
               "--pc-dropdown-origin-x: right"

      assert rule_body(css, ".pc-dropdown__menu-items-wrapper-side--right") =~
               "--pc-dropdown-origin-x: left"

      assert rule_body(css, ".pc-dropdown__menu-items-wrapper-align--start") =~
               "transform-origin: top var(--pc-dropdown-origin-x"

      assert rule_body(css, ".pc-dropdown__menu-items-wrapper-align--end") =~
               "transform-origin: bottom var(--pc-dropdown-origin-x"
    end

    test "no side rule pairs itself with the vertical flip", %{css: css} do
      # data-flip is the vertical question. A side-out panel is not on that
      # axis, the hook never attaches to it, and a [data-flip] rule aimed at
      # a side class would only ever fire by accident.
      refute css =~ ~r/\.pc-dropdown__menu-items-wrapper-side--\w+\[data-flip\]/
    end
  end

  describe "the dialog footer band" do
    # A footer a component OWNS wears one band - the table tfoot's border
    # plus muted wash - so a modal and a slide over open on the same page
    # cannot disagree about what a footer looks like. The pair exists only
    # in CSS (the markup is one class either side), so this is the only
    # place it can be pinned. The slide over drifted here once already: a
    # bare gray-100 hairline and no wash at all.

    @footer_band ~w(border-t border-gray-200 bg-gray-50 dark:border-gray-400/17 dark:bg-gray-400/8)

    setup do
      %{css: File.read!(Path.join(@app_root, "assets/default.css"))}
    end

    test "the tfoot still defines the pair the others copy", %{css: css} do
      body = rule_body(css, ".pc-table__tfoot")

      for token <- @footer_band do
        assert body =~ token, "the tfoot lost #{token}; the band's source of truth moved"
      end
    end

    test "the modal and slide over footers wear it too", %{css: css} do
      for selector <- [".pc-modal__footer", ".pc-slideover__footer"], token <- @footer_band do
        assert rule_body(css, selector) =~ token,
               "#{selector} is missing #{token} from the footer band"
      end
    end

    test "the modal's footer is pinned, not scrolled", %{css: css} do
      # The box is a column and the content is the only scroller. Drop
      # flex-none here (or the overflow off the content) and a long body
      # pushes the action row off the bottom of the dialog.
      assert rule_body(css, ".pc-modal__footer") =~ "flex-none"
      assert rule_body(css, ".pc-modal__box") =~ "flex-col"
      assert rule_body(css, ".pc-modal__content") =~ "overflow-y-auto"
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

    test "the hue revolution is rainbow-only", %{css: css} do
      # Pulse animates --pc-plasma-hue through 360deg; consumed raw, it
      # drags every palette around the colour wheel (brand blues morphing
      # to yellow - shipped). The gain multiplier defaults to 0 so only
      # rainbow's opt-in cycles hue.
      refute css =~ "hue-rotate(var(--pc-plasma-hue",
             "a plasma filter consumes the hue var without the gain multiplier"

      assert css =~ "hue-rotate(calc(var(--pc-plasma-hue, 0deg) * var(--pc-plasma-hue-gain, 0)))"
      assert rule_body(css, ".pc-border-plasma--rainbow") =~ "--pc-plasma-hue-gain: 1"

      for palette <- ["brand", "ocean", "sunset", "mono"] do
        refute rule_body(css, ".pc-border-plasma--#{palette}") =~ "--pc-plasma-hue-gain",
               "palette #{palette} must not opt into the hue revolution"
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

  describe "slider thumb-anchor invariant" do
    setup do
      %{css: File.read!(Path.join(@app_root, "assets/default.css"))}
    end

    test "nothing positions itself at the raw fraction", %{css: css} do
      # A native thumb's centre travels from thumb/2 to width - thumb/2, so a
      # layer placed at the raw fraction is up to half a thumb adrift at the
      # ends. Everything that has to line up with the thumb goes through
      # --pc-slider-anchor*, which does that conversion once.
      offenders =
        Regex.scan(~r/^\s*(?:left|right|top|bottom):[^;]*--pc-slider-frac[^;]*;/m, css)

      assert offenders == [],
             "slider geometry positioned at the raw fraction: #{inspect(offenders)}"
    end

    test "every anchor compensates for the thumb", %{css: css} do
      anchors = Regex.scan(~r/--pc-slider-anchor(?:-min|-max)?:\s*calc\(([^;]*)\);/, css)

      assert length(anchors) == 3

      for [_, body] <- anchors do
        assert body =~ "100% - var(--pc-slider-thumb)"
        assert body =~ "var(--pc-slider-thumb) / 2"
      end
    end
  end

  describe "slider thumb-centring invariant" do
    setup do
      %{css: File.read!(Path.join(@app_root, "assets/default.css"))}
    end

    test "the compensation lives in exactly one rule", %{css: css} do
      # WebKit centres ::-webkit-slider-runnable-track in the input's content
      # box and then puts the thumb's TOP EDGE on the runnable track's top
      # edge. This margin is the only thing that turns that into "centred", so
      # every mode has to go through the one rule that carries it. Dual mode
      # used to reset it to 0 and collapse the input to height: 0, which hung
      # both thumbs (thumb - track) / 2 low: 6px at sm, 7px at md, 8px at lg.
      compensation = "margin-top: calc((var(--pc-slider-track) - var(--pc-slider-thumb)) / 2)"

      assert rule_body(css, ".pc-slider__input::-webkit-slider-thumb") =~ compensation

      with_margins =
        ~r/\.pc-slider[^{}]*::-webkit-slider-thumb\s*\{[^}]*margin-top:/
        |> Regex.scan(css)
        |> length()

      assert with_margins == 1,
             "#{with_margins} slider thumb rules set margin-top; the compensation must live in one"
    end

    test "a dual input keeps the single input's box", %{css: css} do
      # A dual input is a single input taken out of flow. Same box, same thumb,
      # same centring - only `position` and pointer-events differ.
      assert [_, body] = Regex.run(~r/\n  \.pc-slider--dual \.pc-slider__input \{([^}]*)\}/, css)

      refute body =~ ~r/height:\s*0/,
             "collapsing the dual input's box moves its thumb off the track centreline"

      assert [_, vertical] =
               Regex.run(
                 ~r/\n  \.pc-slider--vertical\.pc-slider--dual \.pc-slider__input \{([^}]*)\}/,
                 css
               )

      refute vertical =~ ~r/width:\s*0/,
             "the standing dual input's cross size is the box WebKit centres its thumb in"
    end
  end

  describe "slider vertical-orientation invariant" do
    setup do
      %{css: File.read!(Path.join(@app_root, "assets/default.css"))}
    end

    test "vertical never hands the control back to the UA", %{css: css} do
      # -webkit-appearance IS `appearance`, so `-webkit-appearance:
      # slider-vertical` on the vertical rule outranked the base rule's
      # appearance: none at higher specificity and restored native rendering:
      # ::-webkit-slider-thumb generated no box at all, and a native vertical
      # slider painted over our track and fill. Vertical stands the input up
      # with writing-mode and keeps every custom rule.
      declarations = String.replace(css, ~r|/\*.*?\*/|s, "")

      refute declarations =~ ~r/appearance:\s*slider-vertical/,
             "the deprecated vertical appearance re-enables native rendering: " <>
               inspect(Regex.run(~r/^.*appearance:\s*slider-vertical.*$/m, declarations))

      assert rule_body(css, ".pc-slider--vertical .pc-slider__input") =~
               "writing-mode: vertical-lr"
    end

    test "no dark: variant rides a slider pseudo-element", %{css: css} do
      # A `dark:` variant compiles to a trailing :where(.dark, .dark *) ancestor
      # test, which a pseudo-element can never satisfy - it reads as an
      # intention the paint never honours. Scheme-dependent values ride a custom
      # property on .pc-slider (a real element), the way --pc-slider-surface
      # does. This has shipped as a live bug more than once.
      offenders =
        Regex.scan(~r/^\s*\.pc-slider[^{}\n]*::[a-z-]+ \{[^}]*dark:[^}]*\}/m, css)

      assert offenders == [],
             "dark: variant on a slider pseudo-element rule: #{inspect(offenders)}"
    end
  end
end
