defmodule PetalComponents.NumberTickerTest do
  use ComponentCase
  import PetalComponents.NumberTicker

  describe "basic rendering" do
    test "renders the final value server-side with the hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_ticker id="ticker" value={5200} />
        """)

      assert html =~ "pc-number-ticker"
      assert html =~ ~s(phx-hook="PetalNumberTicker")
      assert html =~ ~s(id="ticker")
      assert html =~ ~s(data-value="5200")
      assert html =~ "5200"
      assert html =~ ~s(data-duration="1500")
      assert html =~ ~s(data-decimal-places="0")
      assert html =~ ~s(data-start-value="0")
    end

    test "renders prefix and suffix in the fallback content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_ticker id="ticker" value={99} prefix="$" suffix="+" />
        """)

      assert html =~ ~s(data-prefix="$")
      assert html =~ ~s(data-suffix="+")
      assert html =~ "$99+"
    end
  end

  describe "customization" do
    test "applies duration, decimal places, start value and locale" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_ticker
          id="ticker"
          value={42.5}
          start_value={10}
          duration={3000}
          decimal_places={1}
          locale="de-DE"
        />
        """)

      assert html =~ ~s(data-value="42.5")
      assert html =~ ~s(data-start-value="10")
      assert html =~ ~s(data-duration="3000")
      assert html =~ ~s(data-decimal-places="1")
      assert html =~ ~s(data-locale="de-DE")
    end

    test "applies custom classes and rest attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.number_ticker id="ticker" value={1} class="text-4xl" data-test="ticker" />
        """)

      assert html =~ "text-4xl"
      assert html =~ ~s(data-test="ticker")
    end
  end
end
