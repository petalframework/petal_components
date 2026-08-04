defmodule PetalComponents.SocialButton do
  @moduledoc """
  The provider sign-in button - "Continue with Google" and its siblings,
  so auth pages stop hand-rolling them.

      <.social_button provider="google" href={~p"/auth/google"} class="w-full" />
      <.social_button provider="github" variant="solid" href={~p"/auth/github"} />

  Rides `pc-button` geometry (sizes, radius token, focus ring), so social
  buttons match every other button in the app and follow the theme.
  `variant="outline"` is the default - the neutral button with the
  brand's coloured glyph, today's convention. `variant="solid"` paints
  the provider's own background.

  The label defaults to "Continue with {Provider}"; pass `label` for
  other copy ("Login with Google") or `icon_only` for compact rows -
  the label then becomes the accessible name.

  A link when `href`/`navigate`/`patch` is set (OAuth flows are plain
  GETs to `/auth/:provider`), a button otherwise (`phx-click` works via
  the usual bindings).
  """
  use Phoenix.Component

  import PetalComponents.BrandIcon

  @providers PetalComponents.BrandIcon.names()

  @provider_names %{
    "google" => "Google",
    "github" => "GitHub",
    "apple" => "Apple",
    "x" => "X",
    "facebook" => "Facebook",
    "microsoft" => "Microsoft",
    "gitlab" => "GitLab",
    "discord" => "Discord",
    "linkedin" => "LinkedIn"
  }

  attr :provider, :string, required: true, values: @providers

  attr :variant, :string,
    default: "outline",
    values: ["outline", "solid"],
    doc: "outline is the neutral button with the coloured glyph; solid paints the brand colour"

  attr :size, :string, default: "md", values: ["sm", "md", "lg"]

  attr :label, :string,
    default: nil,
    doc: "button text; defaults to \"Continue with {Provider}\""

  attr :icon_only, :boolean,
    default: false,
    doc: "glyph only; the label becomes the accessible name"

  attr :href, :string, default: nil, doc: "plain link target - OAuth flows are GETs"
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(method download target rel),
    doc: "phx-click and friends work here when rendered as a button"

  def social_button(assigns) do
    assigns =
      assigns
      |> assign(:text, assigns.label || "Continue with #{@provider_names[assigns.provider]}")
      |> assign(:link?, !!(assigns.href || assigns.navigate || assigns.patch))

    ~H"""
    <.link
      :if={@link?}
      href={@href}
      navigate={@navigate}
      patch={@patch}
      class={button_classes(assigns)}
      aria-label={@icon_only && @text}
      {@rest}
    >
      <.brand_icon
        name={@provider}
        colored={@variant == "outline"}
        class="pc-social-button__icon"
      />
      <span :if={!@icon_only}>{@text}</span>
    </.link>
    <button
      :if={!@link?}
      type="button"
      class={button_classes(assigns)}
      aria-label={@icon_only && @text}
      {@rest}
    >
      <.brand_icon
        name={@provider}
        colored={@variant == "outline"}
        class="pc-social-button__icon"
      />
      <span :if={!@icon_only}>{@text}</span>
    </button>
    """
  end

  defp button_classes(assigns) do
    [
      "pc-button",
      "pc-button--#{assigns.size}",
      variant_class(assigns.variant, assigns.provider),
      "pc-social-button",
      assigns.icon_only && "pc-social-button--icon-only",
      assigns.class
    ]
  end

  defp variant_class("outline", _provider), do: "pc-button--gray-outline"
  defp variant_class("solid", provider), do: "pc-social-button--#{provider}"
end
