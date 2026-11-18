defmodule PetalComponents.Check.Rules.ImportantOnPcTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Rules.ImportantOnPc

  defp run(src), do: findings(:css, src, rules: [ImportantOnPc])

  describe "must flag" do
    test "a colour on a pc class, at the bang" do
      src = ".pc-button {\n  color: red !important;\n}\n"
      assert [f] = run(src)
      assert {f.line, f.column} == {2, 14}
      assert f.subject == "!important"
      assert f.replacement == ""
      assert f.message == "!important on .pc-button (color) fights the component's styling API"
      assert f.fix =~ "drop !important"
      assert f.severity == :error
      assert_at(src, f)
    end

    test "a descendant selector, and the first pc selector of a list is named" do
      src = ".card .pc-button__icon, .other { background: blue ! important; }\n"
      assert [f] = run(src)
      assert f.message =~ "on .card .pc-button__icon (background)"
      assert f.subject == "! important"
      assert_at(src, f)
    end

    test "nesting, @apply siblings and @media" do
      src = """
      .pc-x {
        @apply p-2;
        &:hover {
          border-color: red !important;
        }
      }
      @media (min-width: 640px) {
        .pc-modal { box-shadow: none !important; }
      }
      """

      assert [a, b] = run(src)
      assert {a.line, b.line} == {4, 8}
      assert Enum.all?([a, b], &(&1.severity == :error))
    end

    test "animation outside reduced motion is a warning" do
      assert [f] = run(".pc-marquee__content { animation: none !important; }\n")
      assert f.severity == :warning
      assert f.replacement == nil
      assert f.message =~ "the library may set animation inline"
    end

    test "sizes and positions are warnings" do
      src =
        ".pc-icon { width: 1rem !important; margin-left: 0 !important; z-index: 5 !important; }\n"

      assert [_, _, _] = found = run(src)
      assert Enum.all?(found, &(&1.severity == :warning))
    end
  end

  describe "must not flag" do
    test "no pc class" do
      assert run(".btn { color: red !important; }\n") == []
    end

    test ".pc- only inside :not() or :has()" do
      src = """
      html.x *:not(.pc-scheme-toggle, .pc-scheme-toggle *) { transition: none !important; }
      .foo:has(.pc-x) { color: red !important; }
      .a:not(:has(.pc-y)) { color: red !important; }
      """

      assert run(src) == []
    end

    test "motion inside prefers-reduced-motion" do
      src = """
      @media (prefers-reduced-motion: reduce) {
        .pc-marquee__content { animation: none !important; transition-duration: 0s !important; }
      }
      """

      assert run(src) == []
    end

    test "comments, and pc rules with no !important" do
      assert run("/* .pc-x { color: red !important; } */\n.pc-button { color: red; }\n") == []
    end

    test "a !important inside a string" do
      assert run(~s(.pc-x::after { content: "!important"; }\n)) == []
    end
  end

  test "every error replacement is pasteable" do
    src = ".pc-button { color: red !important; }\n.pc-card {\n  background: none !important;\n}\n"
    found = run(src)
    assert [_, _] = found
    assert run(apply_replacements(src, found)) == []
  end

  describe "the warning list keeps up with the library" do
    # Properties petal_components.js writes as inline styles, and properties
    # default.css pins with !important, must be warnings: an app !important
    # there may be needed, or may never work.
    test "every inline or pinned property is a warning" do
      {exact, prefixes} = ImportantOnPc.warn_properties()
      warn? = fn p -> p in exact or Enum.any?(prefixes, &String.starts_with?(p, &1)) end

      js = File.read!("assets/js/petal_components.js")

      inline =
        for [_, camel] <- Regex.scan(~r/\.style\.([a-zA-Z]+)\s*=/, js),
            camel not in ["cssText", "setProperty"],
            uniq: true,
            do: camel |> String.replace(~r/[A-Z]/, &("-" <> String.downcase(&1)))

      pinned =
        for [_, p] <-
              Regex.scan(~r/([a-z-]+)\s*:[^;{}]*!important/, File.read!("assets/default.css")),
            uniq: true,
            do: p

      # color is only written on a hidden probe element (colour parsing), not on a component.
      not_styling = ["color"]

      for p <- Enum.uniq(inline ++ pinned) -- not_styling do
        assert warn?.(p),
               "#{p} is set inline or pinned by the library; add it to the warning list"
      end

      assert "width" in pinned
      assert "transform" in inline
    end
  end
end
