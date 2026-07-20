defmodule PetalComponents.ColorSchemeSwitch do
  @moduledoc """
  Light / dark / system colour-scheme switching, in three faces.

      <.color_scheme_switch id="scheme" variant="toggle" />
      <.color_scheme_switch id="scheme" variant="dropdown" />
      <.color_scheme_switch id="scheme" variant="segmented" />

  * **toggle** - a compact icon button that flips between light and dark
    instantly (the sun rotates out, the moon rotates in). No system option
    on purpose: a cycling three-state toggle can't show you which state
    you're in.
  * **dropdown** - the same compact trigger opening Light / Dark / System.
  * **segmented** - a three-way pill with all states visible. Settings
    pages, roomy navbars, preview chrome.

  ## The scheme contract

  Render `<.color_scheme_script />` once in your root layout's `<head>`,
  before your app's JS. It applies the scheme *before first paint* (no
  flash), and defines `window.PetalColorScheme`:

    * **preference** - `"light" | "dark" | "system"`. Stored in
      `localStorage.scheme` only for explicit choices; system is the
      absence of a stored value (drop-in compatible with existing petal
      apps that store `scheme`).
    * **resolved** - what the page is actually showing. While the
      preference is system, a `matchMedia` listener follows the OS live.
    * Changing scheme in one tab updates every open tab (a `storage`
      listener), and every change dispatches a
      `window` `petal:scheme-changed` event with
      `{preference, resolved}` - all switch instances stay in sync, and
      your own code can react too.

  The switches require the `PetalColorScheme` hook from the JS bundle
  (`hooks: { ...PetalComponents }`).
  """
  use Phoenix.Component

  import PetalComponents.Icon

  alias PetalComponents.Dropdown

  @doc """
  The no-flash scheme script. Render once in `<head>`, before `app.js`.
  """
  def color_scheme_script(assigns) do
    ~H"""
    <script phx-no-curly-interpolation>
      (() => {
        const KEY = "scheme";
        const media = window.matchMedia("(prefers-color-scheme: dark)");
        const preference = () => localStorage.getItem(KEY) || "system";
        const resolved = () => {
          const pref = preference();
          return pref === "system" ? (media.matches ? "dark" : "light") : pref;
        };
        const apply = () => {
          document.documentElement.classList.toggle("dark", resolved() === "dark");
          window.dispatchEvent(
            new CustomEvent("petal:scheme-changed", {
              detail: { preference: preference(), resolved: resolved() },
            })
          );
        };
        window.PetalColorScheme = {
          preference,
          resolved,
          set(pref) {
            if (pref === "system") localStorage.removeItem(KEY);
            else localStorage.setItem(KEY, pref);
            apply();
          },
        };
        media.addEventListener("change", () => {
          if (preference() === "system") apply();
        });
        window.addEventListener("storage", (e) => {
          if (e.key === KEY || e.key === null) apply();
        });
        apply();
      })();
    </script>
    """
  end

  attr :id, :string, required: true

  attr :variant, :string,
    default: "toggle",
    values: ["toggle", "dropdown", "segmented"],
    doc: "toggle flips light/dark; dropdown and segmented offer system too"

  attr :light_label, :string, default: "Light", doc: "label/aria text (i18n)"
  attr :dark_label, :string, default: "Dark", doc: "label/aria text (i18n)"
  attr :system_label, :string, default: "System", doc: "label/aria text (i18n)"
  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  Renders a colour-scheme switch bound to the `PetalColorScheme` hook.
  """
  def color_scheme_switch(%{variant: "toggle"} = assigns) do
    ~H"""
    <button
      type="button"
      id={@id}
      phx-hook="PetalColorScheme"
      data-variant="toggle"
      class={["pc-scheme-toggle", @class]}
      aria-label={"#{@light_label} / #{@dark_label}"}
      {@rest}
    >
      <.icon name="hero-sun" class="pc-scheme-toggle__sun" />
      <.icon name="hero-moon" class="pc-scheme-toggle__moon" />
    </button>
    """
  end

  def color_scheme_switch(%{variant: "segmented"} = assigns) do
    assigns =
      assign(assigns, :options, [
        {"system", "hero-computer-desktop", assigns.system_label},
        {"light", "hero-sun", assigns.light_label},
        {"dark", "hero-moon", assigns.dark_label}
      ])

    ~H"""
    <div
      id={@id}
      phx-hook="PetalColorScheme"
      data-variant="segmented"
      role="radiogroup"
      aria-label="Colour scheme"
      class={["pc-scheme-segmented", @class]}
      {@rest}
    >
      <label :for={{value, icon, label} <- @options} class="pc-scheme-segmented__option">
        <input
          type="radio"
          name={"#{@id}-scheme"}
          value={value}
          aria-label={label}
          class="pc-scheme-segmented__input"
        />
        <.icon name={icon} class="pc-scheme-segmented__icon" />
      </label>
    </div>
    """
  end

  def color_scheme_switch(%{variant: "dropdown"} = assigns) do
    assigns =
      assign(assigns, :options, [
        {"light", "hero-sun", assigns.light_label},
        {"dark", "hero-moon", assigns.dark_label},
        {"system", "hero-computer-desktop", assigns.system_label}
      ])

    ~H"""
    <div
      id={@id}
      phx-hook="PetalColorScheme"
      data-variant="dropdown"
      class={["pc-scheme-dropdown", @class]}
      {@rest}
    >
      <Dropdown.dropdown placement="right" menu_items_wrapper_class="pc-scheme-dropdown__menu">
        <:trigger_element>
          <span class="pc-scheme-toggle pc-scheme-dropdown__trigger" aria-label="Colour scheme">
            <.icon name="hero-sun" class="pc-scheme-toggle__sun" />
            <.icon name="hero-moon" class="pc-scheme-toggle__moon" />
          </span>
        </:trigger_element>
        <button
          :for={{value, icon, label} <- @options}
          type="button"
          role="menuitemradio"
          aria-checked="false"
          aria-label={label}
          title={label}
          data-scheme={value}
          class="pc-scheme-dropdown__item"
        >
          <.icon name={icon} class="pc-scheme-dropdown__item-icon" />
        </button>
      </Dropdown.dropdown>
    </div>
    """
  end
end
