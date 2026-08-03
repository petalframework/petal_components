defmodule PetalComponents.Showcase.SocialButton do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.SocialButton,
    title: "Social button",
    functions: [:social_button]

  example :providers, "The sign-in stack",
    description:
      "The canonical auth-card column: outline buttons, coloured glyphs, riding pc-button geometry so they match every other button and follow the radius dial. OAuth flows are plain GETs, so href points at /auth/:provider." do
    ~H"""
    <div class="flex flex-col w-full max-w-xs gap-3 mx-auto">
      <.social_button provider="google" href="#" class="w-full" />
      <.social_button provider="github" href="#" class="w-full" />
      <.social_button provider="apple" href="#" class="w-full" />
      <.social_button provider="x" href="#" class="w-full" />
    </div>
    """
  end

  example :solid, "Solid, the brand's own paint",
    description:
      "variant=\"solid\" puts the provider's colour on the button. The black brands (GitHub, Apple, X) keep a hairline border in dark mode so they never dissolve into the page." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-3">
      <.social_button provider="google" variant="solid" href="#" />
      <.social_button provider="github" variant="solid" href="#" />
      <.social_button provider="discord" variant="solid" href="#" />
      <.social_button provider="gitlab" variant="solid" href="#" />
    </div>
    """
  end

  example :compact, "Icon-only rows",
    description:
      "icon_only for tight layouts - the label moves into aria-label, so the compact row stays accessible. Custom labels replace the default \"Continue with\" copy." do
    ~H"""
    <div class="flex flex-col items-center gap-4">
      <div class="flex items-center gap-2">
        <.social_button provider="google" icon_only href="#" />
        <.social_button provider="github" icon_only href="#" />
        <.social_button provider="microsoft" icon_only href="#" />
        <.social_button provider="linkedin" icon_only href="#" />
        <.social_button provider="facebook" icon_only href="#" />
      </div>
      <.social_button provider="google" label="Login with Google" size="sm" href="#" />
    </div>
    """
  end

  example :glyphs, "The brand glyphs themselves",
    description:
      "brand_icon is its own component - monochrome currentColor by default so it tints like any icon, colored for the official treatment. Use it anywhere, not just in buttons." do
    ~H"""
    <div class="flex flex-col items-center gap-5">
      <div class="flex flex-wrap items-center justify-center gap-4 text-gray-700 dark:text-gray-300">
        <.brand_icon name="google" class="w-6 h-6" />
        <.brand_icon name="github" class="w-6 h-6" />
        <.brand_icon name="apple" class="w-6 h-6" />
        <.brand_icon name="x" class="w-6 h-6" />
        <.brand_icon name="facebook" class="w-6 h-6" />
        <.brand_icon name="microsoft" class="w-6 h-6" />
        <.brand_icon name="gitlab" class="w-6 h-6" />
        <.brand_icon name="discord" class="w-6 h-6" />
        <.brand_icon name="linkedin" class="w-6 h-6" />
      </div>
      <div class="flex flex-wrap items-center justify-center gap-4">
        <.brand_icon name="google" colored class="w-6 h-6" />
        <.brand_icon name="github" colored class="w-6 h-6 text-gray-900 dark:text-white" />
        <.brand_icon name="apple" colored class="w-6 h-6 text-gray-900 dark:text-white" />
        <.brand_icon name="x" colored class="w-6 h-6 text-gray-900 dark:text-white" />
        <.brand_icon name="facebook" colored class="w-6 h-6" />
        <.brand_icon name="microsoft" colored class="w-6 h-6" />
        <.brand_icon name="gitlab" colored class="w-6 h-6" />
        <.brand_icon name="discord" colored class="w-6 h-6" />
        <.brand_icon name="linkedin" colored class="w-6 h-6" />
      </div>
    </div>
    """
  end
end
