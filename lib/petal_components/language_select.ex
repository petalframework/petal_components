defmodule PetalComponents.LanguageSelect do
  @moduledoc """
  A locale switcher - the flag dropdown a multilingual app puts in its
  header or footer.

  A pure composition of `PetalComponents.Dropdown`: the trigger shows the
  current locale's flag, the menu lists every language as a plain link to
  the current path with `?locale=...` appended (`&`-joined when the path
  already carries a query). That is the conventional Phoenix contract -
  a plug or `on_mount` hook reads the param, calls `Gettext.put_locale/2`
  and persists the choice - and because the items are real links, the
  switcher works on live and dead views alike.

      <.language_select
        current_locale={Gettext.get_locale(MyAppWeb.Gettext)}
        current_path={@current_path}
        language_options={[
          %{locale: "en", flag: "🇬🇧", label: "English"},
          %{locale: "fr", flag: "🇫🇷", label: "Français"}
        ]}
      />

  When `current_locale` matches no option, the trigger falls back to a
  language glyph instead of raising - a half-configured app renders a
  working menu, not a crash.
  """
  use Phoenix.Component

  import PetalComponents.Dropdown
  import PetalComponents.Icon

  attr :current_locale, :string,
    required: true,
    doc: "the active locale, e.g. from Gettext.get_locale/1"

  attr :language_options, :list,
    required: true,
    doc: "one map per language: %{locale: \"en\", flag: \"🇬🇧\", label: \"English\"}"

  attr :current_path, :string,
    default: "",
    doc: "the path the locale links return to; the locale query param is appended"

  attr :label, :string, default: "Change language", doc: "accessible name for the trigger"
  attr :placement, :string, default: "left", values: ["left", "right"]
  attr :class, :any, default: nil, doc: "extra classes for the dropdown container"
  attr :rest, :global

  def language_select(assigns) do
    assigns =
      assign(
        assigns,
        :current_option,
        Enum.find(assigns.language_options, &(&1.locale == assigns.current_locale))
      )

    ~H"""
    <.dropdown class={["pc-language-select", @class]} placement={@placement} {@rest}>
      <:trigger_element>
        <span class="pc-language-select__trigger">
          <span :if={@current_option} class="pc-language-select__flag">
            {@current_option.flag}
          </span>
          <.icon :if={is_nil(@current_option)} name="hero-language" class="pc-language-select__globe" />
          <.icon name="hero-chevron-down-mini" class="pc-language-select__chevron" />
          <span class="sr-only">{@label}</span>
        </span>
      </:trigger_element>
      <.dropdown_menu_item
        :for={language <- @language_options}
        link_type="a"
        to={locale_href(@current_path, language.locale)}
        aria-current={language.locale == @current_locale && "true"}
        class="pc-language-select__item"
      >
        <span class="pc-language-select__item-flag">{language.flag}</span>
        <span class="pc-language-select__item-label">{language.label}</span>
        <.icon
          :if={language.locale == @current_locale}
          name="hero-check-mini"
          class="pc-language-select__check"
        />
      </.dropdown_menu_item>
    </.dropdown>
    """
  end

  defp locale_href(path, locale) do
    sep = if String.contains?(path, "?"), do: "&", else: "?"
    path <> sep <> "locale=" <> URI.encode_www_form(locale)
  end
end
