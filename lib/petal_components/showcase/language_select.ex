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
