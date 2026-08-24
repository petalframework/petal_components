defmodule PetalComponents.Showcase.QrCode do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.QrCode,
    title: "QR code",
    functions: [:qr_code]

  example :basic, "Scan to open",
    description:
      "Server-rendered SVG, no JavaScript. Every dark module is one path, so a dense code is still a single DOM node. Colour rides currentColor, size rides classes." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-10">
      <div class="text-center">
        <.qr_code value="https://petal.build" class="size-36 text-gray-900 dark:text-white" />
        <div class="mt-3 text-xs text-gray-500 dark:text-gray-400">petal.build</div>
      </div>
      <div class="text-center">
        <.qr_code
          value="https://petal.build"
          rounded={0.6}
          class="size-36 text-primary-600 dark:text-primary-400"
        />
        <div class="mt-3 text-xs text-gray-500 dark:text-gray-400">rounded={0.6}</div>
      </div>
      <div class="text-center">
        <.qr_code
          value="https://petal.build"
          rounded={1}
          class="size-36 text-gray-900 dark:text-white"
        />
        <div class="mt-3 text-xs text-gray-500 dark:text-gray-400">rounded={1}</div>
      </div>
    </div>
    """
  end

  example :totp, "Two-factor enrolment",
    description:
      "The number one reason to reach for this. The secret is printed underneath as text too - a QR code must never be the only way in." do
    ~H"""
    <div class="w-full max-w-sm p-6 mx-auto border border-gray-200 rounded-xl dark:border-gray-800">
      <div class="text-base font-semibold text-gray-900 dark:text-white">
        Scan with your authenticator
      </div>
      <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
        Open 1Password, Authy or Google Authenticator and point it at this code.
      </p>
      <div class="flex justify-center p-4 mt-5 bg-white rounded-lg">
        <.qr_code
          value="otpauth://totp/Petal:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Petal"
          background="white"
          label="QR code to enrol your authenticator app"
          class="size-44 text-gray-900"
        />
      </div>
      <div class="mt-4 text-xs text-gray-500 dark:text-gray-400">
        Can't scan? Enter this key by hand:
      </div>
      <div class="px-3 py-2 mt-1 font-mono text-sm text-gray-900 rounded bg-gray-100 dark:bg-gray-800 dark:text-gray-100">
        JBSW Y3DP EHPK 3PXP
      </div>
    </div>
    """
  end

  example :dark_surface, "On a dark surface",
    description:
      "Scanners want dark modules on a light background. On the left, the safe default: a white card behind the code, readable by anything. On the right, inverted - it looks better, most modern phones cope, older scanners may not." do
    ~H"""
    <div class="grid w-full gap-6 p-6 bg-gray-900 sm:grid-cols-2 rounded-xl">
      <div class="text-center">
        <div class="inline-flex p-4 bg-white rounded-xl">
          <.qr_code value="https://petal.build" background="white" class="size-32 text-gray-900" />
        </div>
        <div class="mt-3 text-xs text-gray-400">safe: dark on light</div>
      </div>
      <div class="text-center">
        <div class="inline-flex p-4">
          <.qr_code value="https://petal.build" class="size-32 text-white" />
        </div>
        <div class="mt-3 text-xs text-gray-400">inverted: test your scanners</div>
      </div>
    </div>
    """
  end

  example :logo, "With a centre logo",
    description:
      "The logo slot knocks a hole in the middle and bumps error correction to :h, so the code survives the missing modules. Slot content is laid out in a 100x100 box scaled to fit the hole." do
    ~H"""
    <div class="flex justify-center">
      <div class="p-4 bg-white rounded-xl">
        <.qr_code
          value="https://petal.build"
          background="white"
          rounded={0.5}
          label="QR code linking to petal.build"
          class="size-44 text-gray-900"
        >
          <:logo>
            <div class="flex h-full items-center justify-center text-5xl font-semibold text-primary-600">
              PC
            </div>
          </:logo>
        </.qr_code>
      </div>
    </div>
    """
  end

  example :share, "Share this page",
    description:
      "Small enough to sit in a card footer next to a copy-link button. The URL stays visible as text." do
    ~H"""
    <div class="flex items-center w-full max-w-md gap-4 p-4 mx-auto border border-gray-200 rounded-xl dark:border-gray-800">
      <div class="p-2 bg-white rounded-lg shrink-0">
        <.qr_code
          value="https://petal.build/components"
          background="white"
          label="QR code linking to the component library"
          class="size-20 text-gray-900"
        />
      </div>
      <div class="min-w-0">
        <div class="text-sm font-medium text-gray-900 dark:text-white">Open on your phone</div>
        <div class="mt-1 text-xs text-gray-500 truncate dark:text-gray-400">
          petal.build/components
        </div>
        <.button size="xs" variant="outline" label="Copy link" class="mt-3" />
      </div>
    </div>
    """
  end
end
