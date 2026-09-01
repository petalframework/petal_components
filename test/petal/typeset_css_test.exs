defmodule PetalComponents.TypesetCssTest do
  use ExUnit.Case, async: true

  # The Typeset token contract lives entirely in CSS, so like the badge-dot
  # and escaped-colon guards this is the only place it can be checked at all.
  # The contract: the package only READS --pc-font-* (never defines them),
  # and every read's fallback chain terminates in `inherit` or the exact
  # value the surface consumed before the tokens existed - that is the
  # zero-change-when-unset promise.

  @app_root Path.expand("../..", __DIR__)

  @mono_chain "var(--pc-font-mono, var(--font-mono, ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, \"Liberation Mono\", \"Courier New\", monospace))"
  @heading_chain "var(--pc-font-heading, var(--pc-font-body, inherit))"
  @body_chain "var(--pc-font-body, inherit)"

  setup do
    %{css: File.read!(Path.join(@app_root, "assets/default.css"))}
  end

  test "no --pc-font-* token is ever defined in the package", %{css: css} do
    # Reads are `var(--pc-font-...` - a definition would be `--pc-font-x:`
    # at the start of a declaration. An app that sets nothing must keep
    # inheriting the host's stack, which only holds while we never ship a
    # value of our own.
    definitions =
      ~r/^\s*--pc-font-[a-z-]+\s*:/m
      |> Regex.scan(css)
      |> List.flatten()

    assert definitions == [],
           "default.css defines a --pc-font-* token: #{inspect(definitions)}"
  end

  test "every heading read falls back through body, every body read to inherit", %{css: css} do
    for [read] <- Regex.scan(~r/var\(--pc-font-heading[^;]*/, css) do
      assert read =~ @heading_chain,
             "a --pc-font-heading read does not chain through --pc-font-body -> inherit: #{read}"
    end

    # Body reads are either the bare inherit chain (reading surfaces) or the
    # kbd chain through --font-sans (identical to the old font-sans utility
    # when unset).
    for [read] <- Regex.scan(~r/var\(--pc-font-body[^;]*/, css),
        not String.contains?(read, "var(--pc-font-body, inherit)") do
      assert read =~ "var(--pc-font-body, var(--font-sans,",
             "a --pc-font-body read ends in neither inherit nor the --font-sans chain: #{read}"
    end

    assert css =~ @body_chain
  end

  test "every mono read chains through --font-mono with the literal tail", %{css: css} do
    reads = Regex.scan(~r/var\(--pc-font-mono[^;]*;/, css)
    assert reads != [], "no --pc-font-mono reads found"

    for [read] <- reads do
      assert read =~ @mono_chain,
             "a --pc-font-mono read is missing the --font-mono chain or the literal mono tail: #{read}"
    end
  end

  test "kbd tracks the body face, never mono", %{css: css} do
    kbd = rule_body(css, ":is(.pc-kbd, .pc-input-group__addon kbd)")

    assert kbd =~ "var(--pc-font-body, var(--font-sans,",
           "kbd must chain body -> --font-sans (the value its old font-sans utility compiled to)"

    [apply_line] = Regex.run(~r/@apply[^;]*;/, kbd)

    refute apply_line =~ "font-sans",
           "the font-sans utility must be gone from kbd's @apply (replaced by the raw chain)"

    refute kbd =~ "--pc-font-mono", "kbd deliberately does not follow the mono dial (see kbd.ex)"
  end

  test "the converted mono surfaces carry no font-mono utility any more", %{css: css} do
    for selector <- [
          ".pc-inline-code",
          ".pc-chat__markdown :not(pre) > code",
          ".pc-chat__tool-name",
          ".pc-chat__tool-code",
          ".pc-showcase-props__fn",
          ".pc-showcase-props__name",
          ".pc-showcase-props__type",
          ".pc-showcase-props__default"
        ] do
      body = rule_body(css, selector)
      refute body =~ "font-mono;", "#{selector} still carries the font-mono utility"
      assert body =~ "var(--pc-font-mono", "#{selector} lost its mono binding"
    end
  end

  test "prose rules exist at zero specificity", %{css: css} do
    # <.prose> is styled by the host's typography plugin; our three rules
    # must stay inert without it and lose to any host override, which is
    # what :where() buys on the descendant selectors.
    assert css =~ ".prose :where(h1, h2, h3, h4, h5, h6)"
    assert css =~ ".prose :where(pre, code)"
    assert rule_body(css, ".prose :where(h1, h2, h3, h4, h5, h6)") =~ @heading_chain
    assert rule_body(css, ".prose :where(pre, code)") =~ @mono_chain
  end

  defp rule_body(css, selector) do
    case Regex.run(~r/#{Regex.escape(selector)}\s*\{([^}]*)\}/s, css) do
      [_, body] -> body
      nil -> flunk("selector not found in default.css: #{selector}")
    end
  end
end
