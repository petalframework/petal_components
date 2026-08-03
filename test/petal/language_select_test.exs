defmodule PetalComponents.LanguageSelectTest do
  use ComponentCase

  import PetalComponents.LanguageSelect

  @langs [
    %{locale: "en", flag: "🇬🇧", label: "English"},
    %{locale: "fr", flag: "🇫🇷", label: "Français"}
  ]

  test "renders the current locale's flag and the accessible label" do
    assigns = %{langs: @langs}

    html =
      rendered_to_string(~H"""
      <.language_select current_locale="en" language_options={@langs} />
      """)

    assert html =~ "pc-language-select"
    assert html =~ "🇬🇧"
    assert html =~ "Change language"
  end

  test "unknown current_locale falls back to the language glyph without raising" do
    assigns = %{langs: @langs}

    html =
      rendered_to_string(~H"""
      <.language_select current_locale="xx" language_options={@langs} />
      """)

    assert html =~ "hero-language"

    trigger_flags =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(".pc-language-select__flag")
      |> Enum.count()

    assert trigger_flags == 0
  end

  test "items link to ?locale= on a bare path" do
    assigns = %{langs: @langs}

    html =
      rendered_to_string(~H"""
      <.language_select current_locale="en" current_path="/settings" language_options={@langs} />
      """)

    assert html =~ ~s(href="/settings?locale=en")
    assert html =~ ~s(href="/settings?locale=fr")
  end

  test "items join with & when the path already carries a query" do
    assigns = %{langs: @langs}

    html =
      rendered_to_string(~H"""
      <.language_select current_locale="en" current_path="/docs?page=2" language_options={@langs} />
      """)

    assert html =~ ~s(href="/docs?page=2&amp;locale=fr")
  end

  test "locales are URL-encoded in the href" do
    assigns = %{langs: [%{locale: "en US", flag: "🇺🇸", label: "English (US)"}]}

    html =
      rendered_to_string(~H"""
      <.language_select current_locale="en US" language_options={@langs} />
      """)

    assert html =~ ~s(href="?locale=en+US")
  end

  test "the current language is marked for assistive tech and the eye" do
    assigns = %{langs: @langs}

    html =
      rendered_to_string(~H"""
      <.language_select current_locale="fr" language_options={@langs} />
      """)

    current =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(~s([aria-current="true"]))
      |> Enum.count()

    assert current == 1
    assert html =~ "hero-check-mini"
    assert html =~ "🇫🇷"
  end

  test "label and class pass through" do
    assigns = %{langs: @langs}

    html =
      rendered_to_string(~H"""
      <.language_select
        current_locale="en"
        language_options={@langs}
        label="Sprache wählen"
        class="ml-4"
      />
      """)

    assert html =~ "Sprache wählen"
    assert html =~ "ml-4"
  end
end
