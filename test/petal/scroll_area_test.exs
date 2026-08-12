defmodule PetalComponents.ScrollAreaTest do
  use ComponentCase

  import PetalComponents.ScrollArea

  defp container(html) do
    html |> parse_html() |> LazyHTML.query("div.pc-scroll-area")
  end

  defp classes(html) do
    html
    |> container()
    |> LazyHTML.attribute("class")
    |> List.first()
    |> to_string()
    |> String.split(" ", trim: true)
  end

  defp attribute(html, name) do
    html |> container() |> LazyHTML.attribute(name) |> List.first()
  end

  # ComponentCase only IMPORTS Phoenix.Component, so attr `values:` validation
  # never runs in this suite - it runs in the consumer's module. Compile a
  # caller the way a consumer project does and read stderr.
  defp warn_for(attrs) do
    ExUnit.CaptureIO.capture_io(:stderr, fn ->
      Code.compile_string("""
      defmodule ScrollAreaProbe#{:erlang.unique_integer([:positive])} do
        use Phoenix.Component
        import PetalComponents.ScrollArea

        def render(assigns) do
          ~H\"\"\"
          <.scroll_area #{attrs}>x</.scroll_area>
          \"\"\"
        end
      end
      """)
    end)
  end

  describe "scroll_area/1" do
    test "renders a single container with the base and default orientation classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area>Content</.scroll_area>
        """)

      assert Enum.count(container(html)) == 1
      assert "pc-scroll-area" in classes(html)
      assert "pc-scroll-area--vertical" in classes(html)
      assert html =~ "Content"
    end

    test "renders the inner block inside the container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area>
          <p class="inner">A paragraph</p>
        </.scroll_area>
        """)

      inner = html |> parse_html() |> LazyHTML.query("div.pc-scroll-area p.inner")

      assert Enum.count(inner) == 1
      assert LazyHTML.text(inner) =~ "A paragraph"
    end

    test "no wrapper soup - the component is exactly one element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area>x</.scroll_area>
        """)

      assert html |> parse_html() |> LazyHTML.query("div") |> Enum.count() == 1
    end
  end

  describe "orientation" do
    for orientation <- ~w(vertical horizontal both) do
      test "#{orientation} emits its modifier and no other orientation modifier" do
        assigns = %{orientation: unquote(orientation)}

        html =
          rendered_to_string(~H"""
          <.scroll_area orientation={@orientation}>x</.scroll_area>
          """)

        orientation_classes =
          Enum.filter(classes(html), &(&1 in ~w(
             pc-scroll-area--vertical
             pc-scroll-area--horizontal
             pc-scroll-area--both
           )))

        assert orientation_classes == ["pc-scroll-area--#{unquote(orientation)}"]
      end
    end

    test "an unknown orientation warns at compile time in the consumer's module" do
      refute warn_for(~s|orientation="horizontal"|) =~ "must be one of"
      assert warn_for(~s|orientation="diagonal"|) =~ "must be one of"
    end
  end

  describe "fade_edges" do
    test "off by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area>x</.scroll_area>
        """)

      refute "pc-scroll-area--fade" in classes(html)
    end

    test "on emits the fade modifier" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area fade_edges>x</.scroll_area>
        """)

      assert "pc-scroll-area--fade" in classes(html)
    end
  end

  describe "gutter_stable" do
    test "off by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area>x</.scroll_area>
        """)

      refute "pc-scroll-area--gutter-stable" in classes(html)
    end

    test "on emits the gutter modifier" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area gutter_stable>x</.scroll_area>
        """)

      assert "pc-scroll-area--gutter-stable" in classes(html)
    end
  end

  describe "visibility" do
    test "auto adds nothing" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area visibility="auto">x</.scroll_area>
        """)

      refute "pc-scroll-area--always" in classes(html)
    end

    test "always emits the always modifier" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area visibility="always">x</.scroll_area>
        """)

      assert "pc-scroll-area--always" in classes(html)
    end

    test "an unknown visibility warns at compile time in the consumer's module" do
      refute warn_for(~s|visibility="always"|) =~ "must be one of"
      assert warn_for(~s|visibility="never"|) =~ "must be one of"
    end
  end

  describe "class merging" do
    test "consumer classes ride alongside the pc-* classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area class="max-h-72 rounded-lg">x</.scroll_area>
        """)

      assert "pc-scroll-area" in classes(html)
      assert "pc-scroll-area--vertical" in classes(html)
      assert "max-h-72" in classes(html)
      assert "rounded-lg" in classes(html)
    end

    test "class accepts a list" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area class={["max-h-40", nil, "w-full"]}>x</.scroll_area>
        """)

      assert "max-h-40" in classes(html)
      assert "w-full" in classes(html)
    end
  end

  describe "accessibility" do
    test "focusable by default so the arrow keys scroll it" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area>x</.scroll_area>
        """)

      assert attribute(html, "tabindex") == "0"
    end

    test "a caller-supplied tabindex wins, so a second tab stop can be removed" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area tabindex="-1">x</.scroll_area>
        """)

      assert attribute(html, "tabindex") == "-1"
      assert count_substring(html, "tabindex=") == 1
    end

    test "an aria-label lands on the container and promotes it to a named region" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area aria-label="Chat messages">x</.scroll_area>
        """)

      assert attribute(html, "aria-label") == "Chat messages"
      assert attribute(html, "role") == "region"
    end

    test "aria-labelledby also names the region" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area aria-labelledby="thread-heading">x</.scroll_area>
        """)

      assert attribute(html, "aria-labelledby") == "thread-heading"
      assert attribute(html, "role") == "region"
    end

    test "no name means no role - an unnamed landmark is noise" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area>x</.scroll_area>
        """)

      assert attribute(html, "role") == nil
      refute html =~ "role="
    end

    test "an explicit role wins over the region default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area aria-label="Log output" role="log">x</.scroll_area>
        """)

      assert attribute(html, "role") == "log"
      assert count_substring(html, "role=") == 1
    end
  end

  describe "global attributes" do
    test "id, data-* and phx-* pass through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area id="thread" data-testid="thread" phx-hook="Sticky">x</.scroll_area>
        """)

      assert attribute(html, "id") == "thread"
      assert attribute(html, "data-testid") == "thread"
      assert attribute(html, "phx-hook") == "Sticky"
    end
  end

  describe "edge cases" do
    test "every dial at once composes rather than conflicts" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area
          orientation="both"
          fade_edges
          gutter_stable
          visibility="always"
          aria-label="Everything"
          class="max-h-64"
        >
          x
        </.scroll_area>
        """)

      for class <- ~w(
            pc-scroll-area
            pc-scroll-area--both
            pc-scroll-area--fade
            pc-scroll-area--gutter-stable
            pc-scroll-area--always
            max-h-64
          ) do
        assert class in classes(html)
      end
    end

    test "empty content still renders a valid container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area></.scroll_area>
        """)

      assert Enum.count(container(html)) == 1
      assert attribute(html, "tabindex") == "0"
    end
  end
end
