defmodule PetalComponents.Showcase.SlideOver do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.SlideOver, title: "Slide over"

  example :edit_profile, "Edit profile sheet",
    description:
      "An edge-attached panel for forms that don't warrant a full page. origin slides it from left, right, top or bottom (right here); title and description wire aria-labelledby and aria-describedby; the :footer slot pins the action row below the scrolling body. show_slide_over and hide_slide_over are LiveView.JS commands - no server round-trip to animate." do
    ~H"""
    <.button
      color="gray"
      variant="outline"
      phx-click={show_slide_over("right", "showcase-sheet-profile")}
    >
      <.icon name="hero-pencil-square" class="w-4 h-4 mr-1" /> Edit profile
    </.button>

    <.slide_over
      id="showcase-sheet-profile"
      hide
      origin="right"
      max_width="md"
      title="Edit profile"
      description="Make changes to your profile here. Click save when you're done."
    >
      <div class="flex flex-col gap-4">
        <.field type="text" name="profile_name" value="Alex Rivera" label="Name" />
        <.field type="text" name="profile_username" value="@alexrivera" label="Username" />
        <.field
          type="textarea"
          name="profile_bio"
          value=""
          label="Bio"
          placeholder="A line about you"
        />
      </div>
      <:footer>
        <.button
          color="gray"
          variant="outline"
          phx-click={hide_slide_over("right", "showcase-sheet-profile")}
        >
          Cancel
        </.button>
        <.button phx-click={hide_slide_over("right", "showcase-sheet-profile")}>
          Save changes
        </.button>
      </:footer>
    </.slide_over>
    """
  end

  example :cart, "A cart - scrolling body, pinned summary",
    description:
      "The panel is the floating surface: the body scrolls while the :footer stays put, so totals and the checkout button never leave the screen. Escape and click-away close by default." do
    ~H"""
    <.button color="gray" variant="outline" phx-click={show_slide_over("right", "showcase-sheet-cart")}>
      <.icon name="hero-shopping-bag" class="w-4 h-4 mr-1" /> Open cart
      <.badge color="primary" size="sm" label="3" class="ml-2" />
    </.button>

    <.slide_over id="showcase-sheet-cart" hide origin="right" max_width="sm" title="Your cart" description="3 items">
      <div class="flex flex-col divide-y divide-gray-100 dark:divide-white/10">
        <div
          :for={
            {name, meta, price} <- [
              {"Petal Pro licence", "Single project", "$299"},
              {"Petal Pro team", "Unlimited projects", "$599"},
              {"Petal stickers", "Pack of 12", "$9"}
            ]
          }
          class="flex items-center gap-3 py-4"
        >
          <div class="flex items-center justify-center flex-none w-12 h-12 rounded-lg bg-gray-100 dark:bg-white/10">
            <.icon name="hero-cube" class="w-5 h-5 text-gray-400" />
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-gray-900 truncate dark:text-gray-100">{name}</p>
            <p class="text-xs text-gray-500 dark:text-gray-400">{meta}</p>
          </div>
          <p class="text-sm font-medium tabular-nums text-gray-900 dark:text-gray-100">{price}</p>
        </div>
      </div>
      <:footer>
        <div class="flex items-center justify-between w-full gap-4">
          <div>
            <p class="text-xs text-gray-500 dark:text-gray-400">Total</p>
            <p class="text-base font-semibold tabular-nums text-gray-900 dark:text-gray-100">
              $907
            </p>
          </div>
          <.button phx-click={hide_slide_over("right", "showcase-sheet-cart")}>
            Checkout
          </.button>
        </div>
      </:footer>
    </.slide_over>
    """
  end
end
