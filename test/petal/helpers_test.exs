defmodule PetalComponents.HelpersTest do
  use ComponentCase

  alias PetalComponents.Helpers

  describe "blank_render?/1" do
    defp nothing(assigns) do
      ~H"""
      <a :if={@href} href={@href}>Learn more</a>
      """
    end

    defmodule FooterLive do
      use Phoenix.LiveComponent
      def render(assigns), do: ~H"<span id={@id}>live footer</span>"
    end

    test "nil, empty strings and whitespace are blank" do
      assert Helpers.blank_render?(nil)
      assert Helpers.blank_render?("")
      assert Helpers.blank_render?("  \n\t ")
      assert Helpers.blank_render?({:safe, "  "})
      assert Helpers.blank_render?({:safe, ["  ", ["\n"], ""]})
      assert Helpers.blank_render?([])
    end

    test "text is not blank" do
      refute Helpers.blank_render?("x")
      refute Helpers.blank_render?({:safe, ["  ", "<b>x</b>"]})
      refute Helpers.blank_render?([" ", "Updated hourly"])
    end

    test "a rendered block of whitespace, nil, an empty string, raw whitespace and a false if is blank" do
      assigns = %{link: nil, show?: false}

      assert Helpers.blank_render?(~H"""
             {@link}
             {""}
             {Phoenix.HTML.raw("   ")}
             <%= if false do %>
               <p>hidden</p>
             <% end %>
             <a :if={@show?} href="/docs">Learn more</a>
             """)
    end

    test "a nested function component that renders nothing is blank, and with content it is not" do
      assigns = %{}

      assert Helpers.blank_render?(~H"""
             <.nothing href={nil} />
             """)

      refute Helpers.blank_render?(~H"""
             <.nothing href="/docs" />
             """)
    end

    test "{0} is content" do
      assigns = %{}

      refute Helpers.blank_render?(~H"""
             {0}
             """)
    end

    test "markup and text are content" do
      assigns = %{}

      refute Helpers.blank_render?(~H"""
             Updated hourly
             """)

      refute Helpers.blank_render?(~H"""
             <span></span>
             """)

      # An HTML comment is static text, so it counts too.
      refute Helpers.blank_render?(~H"""
             <!-- todo -->
             """)
    end

    # Deliberate: a comprehension counts as content without being looked
    # into, so a :for over an empty list keeps the wrapper. Pinned so a
    # change to it is a decision, not an accident.
    test "a :for over an empty list counts as content" do
      assigns = %{items: []}

      refute Helpers.blank_render?(~H"""
             <span :for={item <- @items}>{item}</span>
             """)
    end

    test "a live component counts as content and is not rendered to find out" do
      assigns = %{}

      refute Helpers.blank_render?(~H"""
             <.live_component module={PetalComponents.HelpersTest.FooterLive} id="footer-lc" />
             """)
    end
  end
end
