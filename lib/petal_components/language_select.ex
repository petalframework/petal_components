defmodule PetalComponents.LanguageSelect do
  @moduledoc """
  A locale switcher - the language dropdown a multilingual app puts in its
  header or footer.

  A pure composition of `PetalComponents.Dropdown`: the trigger shows the
  current locale (flag, code or label - see `variant`), the menu lists
  every language as a plain link to the current path with `?locale=...`
  appended (`&`-joined when the path already carries a query). That is
  the conventional Phoenix contract - a plug or `on_mount` hook reads the
  param, calls `Gettext.put_locale/2` and persists the choice - and
  because the items are real links, the switcher works on live and dead
  views alike.

      <.language_select
        current_locale={Gettext.get_locale(MyAppWeb.Gettext)}
        current_path={@current_path}
        language_options={[
          %{locale: "en", flag: "🇬🇧", label: "English"},
          %{locale: "fr", flag: "🇫🇷", label: "Français"}
        ]}
      />

  Flags read fast but a flag is a country, not a language - Portuguese
  isn't only 🇵🇹. When that matters, drop the `:flag` keys and switch the
  trigger to text: `variant="code"` renders the locale code (EN), and
  `variant="label"` renders the language name. Options without a `:flag`
  simply render without one.

  When `current_locale` matches no option, the flag trigger falls back to
  a language glyph (and the text triggers fall back to the raw locale) -
  a half-configured app renders a working menu, not a crash.
  """
  use Phoenix.Component

  import PetalComponents.Dropdown
  import PetalComponents.Icon

  attr :current_locale, :string,
    required: true,
    doc: "the active locale, e.g. from Gettext.get_locale/1"

  attr :language_options, :list,
    required: true,
    doc:
      "one map per language: %{locale: \"en\", flag: \"🇬🇧\", label: \"English\"} - :flag is optional"

  attr :current_path, :string,
    default: "",
    doc: "the path the locale links return to; the locale query param is appended"

  attr :variant, :string,
    default: "flag",
    values: ["flag", "code", "label"],
    doc: "what the trigger shows: the current flag, the locale code (EN), or the language name"

  attr :label, :string, default: "Change language", doc: "accessible name for the trigger"

  attr :show_chevron, :boolean,
    default: true,
    doc: "hide for the cleanest text triggers - the flag or code stands alone"

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
          <%= case trigger_mode(@variant, @current_option) do %>
            <% :flag -> %>
              <span class="pc-language-select__flag">{@current_option.flag}</span>
            <% :globe -> %>
              <.icon name="hero-language" class="pc-language-select__globe" />
            <% :code -> %>
              <span class="pc-language-select__code">{String.upcase(@current_locale)}</span>
            <% :label -> %>
              <span class="pc-language-select__label">
                {(@current_option && @current_option.label) || @current_locale}
              </span>
          <% end %>
          <.icon
            :if={@show_chevron}
            name="hero-chevron-down-mini"
            class="pc-language-select__chevron"
          />
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
        <span :if={language[:flag]} class="pc-language-select__item-flag">{language.flag}</span>
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

  defp trigger_mode("code", _current), do: :code
  defp trigger_mode("label", _current), do: :label
  defp trigger_mode("flag", %{flag: flag}) when is_binary(flag), do: :flag
  defp trigger_mode("flag", _current), do: :globe

  # The query goes BEFORE any #fragment - appended blindly it would land
  # inside the fragment and never reach the server. A fragment-only path
  # ("#") yields a relative "?locale=..#" URL, which the browser resolves
  # against the current page - so even the degenerate input still switches
  # locale instead of silently doing nothing.
  defp locale_href(path, locale) do
    {base, fragment} =
      case String.split(path, "#", parts: 2) do
        [base, fragment] -> {base, "#" <> fragment}
        [base] -> {base, ""}
      end

    sep = if String.contains?(base, "?"), do: "&", else: "?"
    base <> sep <> "locale=" <> URI.encode_www_form(locale) <> fragment
  end
end
