defmodule PetalComponents.Showcase.LanguageSelect do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.LanguageSelect,
    title: "Language select",
    functions: [:language_select]

  example :header, "The locale switcher",
    description:
      "The flag dropdown for a header or footer. Items are plain links carrying ?locale= (&-joined when the path already has a query) - the conventional Phoenix contract, working on live and dead views alike. The current language is marked with aria-current and a check." do
    ~H"""
    <div class="flex justify-center py-4">
      <.language_select
        current_locale="en"
        current_path="#"
        language_options={[
          %{locale: "en", flag: "🇬🇧", label: "English"},
          %{locale: "fr", flag: "🇫🇷", label: "Français"},
          %{locale: "de", flag: "🇩🇪", label: "Deutsch"},
          %{locale: "es", flag: "🇪🇸", label: "Español"}
        ]}
      />
    </div>
    """
  end

  example :text_triggers, "Text triggers, flags optional",
    description:
      "A flag is a country, not a language - Portuguese isn't only 🇵🇹. variant=\"code\" puts the locale code on the trigger, variant=\"label\" the language name, and options that omit :flag render as clean text rows." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-10 py-4">
      <.language_select
        current_locale="en"
        current_path="#"
        variant="code"
        language_options={[
          %{locale: "en", label: "English"},
          %{locale: "pt", label: "Português"},
          %{locale: "de", label: "Deutsch"}
        ]}
      />
      <.language_select
        current_locale="pt"
        current_path="#"
        variant="label"
        show_chevron={false}
        language_options={[
          %{locale: "en", flag: "🇬🇧", label: "English"},
          %{locale: "pt", flag: "🇵🇹", label: "Português"},
          %{locale: "de", flag: "🇩🇪", label: "Deutsch"}
        ]}
      />
    </div>
    """
  end

  example :fallback, "Graceful when unconfigured",
    description:
      "An unknown current_locale falls back to a language glyph instead of raising - a half-configured app renders a working menu, not a crash." do
    ~H"""
    <div class="flex justify-center py-4">
      <.language_select
        current_locale="xx"
        current_path="#"
        language_options={[
          %{locale: "en", flag: "🇬🇧", label: "English"},
          %{locale: "fr", flag: "🇫🇷", label: "Français"}
        ]}
      />
    </div>
    """
  end
end
