defmodule PetalComponents.ColorSchemeSwitchTest do
  use ComponentCase
  import PetalComponents.ColorSchemeSwitch

  describe "color_scheme_script/1" do
    test "renders the no-flash contract script" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.color_scheme_script />
        """)

      assert html =~ "<script"
      assert html =~ "PetalColorScheme"
      assert html =~ "prefers-color-scheme: dark"
      assert html =~ "petal:scheme-changed"
      # multi-tab sync
      assert html =~ ~s|addEventListener("storage"|
    end
  end

  describe "color_scheme_switch/1" do
    test "toggle renders a hook-bound button with both icons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.color_scheme_switch id="scheme" variant="toggle" />
        """)

      assert html =~ ~s(phx-hook="PetalColorScheme")
      assert html =~ ~s(data-variant="toggle")
      assert has_icon?(html, "hero-sun")
      assert has_icon?(html, "hero-moon")
    end

    test "segmented renders three radios for system, light and dark" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.color_scheme_switch id="scheme" variant="segmented" />
        """)

      assert html =~ ~s(data-variant="segmented")
      assert html =~ ~s(role="radiogroup")

      for value <- ~w(system light dark) do
        assert html =~ ~s(value="#{value}")
      end

      assert html =~ ~s(name="scheme-scheme")
    end

    test "dropdown renders menuitemradio entries carrying data-scheme" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.color_scheme_switch id="scheme" variant="dropdown" />
        """)

      assert html =~ ~s(data-variant="dropdown")

      for value <- ~w(system light dark) do
        assert html =~ ~s(data-scheme="#{value}")
      end

      assert html =~ ~s(role="menuitemradio")
    end

    test "dropdown labels attr shows text beside icons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.color_scheme_switch id="scheme" variant="dropdown" labels />
        """)

      assert html =~ "pc-scheme-dropdown__item--labeled"
      assert html =~ ">Light</span>"
      assert html =~ ">System</span>"
    end

    test "labels are overridable for i18n" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.color_scheme_switch id="scheme" variant="segmented" light_label="Hell" dark_label="Dunkel" />
        """)

      assert html =~ ~s(aria-label="Hell")
      assert html =~ ~s(aria-label="Dunkel")
    end
  end
end
