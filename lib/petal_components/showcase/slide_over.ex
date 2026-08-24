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
    <.button
      color="gray"
      variant="outline"
      phx-click={show_slide_over("right", "showcase-sheet-cart")}
    >
      <.icon name="hero-shopping-bag" class="w-4 h-4 mr-1" /> Open cart
      <.badge color="primary" size="sm" label="3" class="ml-2" />
    </.button>

    <.slide_over
      id="showcase-sheet-cart"
      hide
      origin="right"
      max_width="sm"
      title="Your cart"
      description="3 items"
    >
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

  example :filter_drawer, "Mobile filter sheet",
    description:
      "origin=\"bottom\" is a drawer, not just a sheet that happens to come from below: rounded top corners, a grab handle, safe-area padding under the action row. Drag it down past about a quarter of its height, or flick it, and it closes - through the same close_slide_over event as escape or the button." do
    ~H"""
    <.button
      color="gray"
      variant="outline"
      phx-click={show_slide_over("bottom", "showcase-sheet-filters")}
    >
      <.icon name="hero-adjustments-horizontal" class="w-4 h-4 mr-1" /> Filters
      <.badge color="primary" size="sm" label="2" class="ml-2" />
    </.button>

    <.slide_over
      id="showcase-sheet-filters"
      hide
      origin="bottom"
      title="Filters"
      description="Narrow the list down"
    >
      <div class="flex flex-col gap-5">
        <div>
          <p class="mb-2 text-xs font-medium tracking-wide text-gray-400 uppercase">Availability</p>
          <div class="flex flex-col gap-2">
            <.field
              :for={
                {name, label, checked} <- [
                  {"filter_stock", "In stock", true},
                  {"filter_preorder", "Available to pre-order", false},
                  {"filter_soon", "Back in soon", false}
                ]
              }
              type="checkbox"
              name={name}
              value={checked}
              label={label}
            />
          </div>
        </div>
        <div>
          <p class="mb-2 text-xs font-medium tracking-wide text-gray-400 uppercase">Price</p>
          <div class="flex flex-col gap-2">
            <.field
              :for={
                {name, label, checked} <- [
                  {"filter_under_50", "Under $50", true},
                  {"filter_50_150", "$50 to $150", false},
                  {"filter_over_150", "Over $150", false}
                ]
              }
              type="checkbox"
              name={name}
              value={checked}
              label={label}
            />
          </div>
        </div>
      </div>
      <:footer>
        <div class="flex items-center justify-between w-full gap-4">
          <.button
            color="gray"
            variant="ghost"
            phx-click={hide_slide_over("bottom", "showcase-sheet-filters")}
          >
            Clear all
          </.button>
          <.button phx-click={hide_slide_over("bottom", "showcase-sheet-filters")}>
            Show 42 results
          </.button>
        </div>
      </:footer>
    </.slide_over>
    """
  end

  example :queue_drawer, "Queue sheet with snap points",
    description:
      "snap_points are viewport-height fractions the drawer can rest at, and initial_snap picks the one it opens on. This one peeks at 0.4 with the current track, then drags up to 0.9 for the whole queue. A flick skips to the next point in the direction you threw it; only a downward release below the lowest point closes it." do
    ~H"""
    <.button
      color="gray"
      variant="outline"
      phx-click={show_slide_over("bottom", "showcase-sheet-queue")}
    >
      <.icon name="hero-queue-list" class="w-4 h-4 mr-1" /> Open queue
    </.button>

    <.slide_over
      id="showcase-sheet-queue"
      hide
      origin="bottom"
      snap_points={[0.4, 0.9]}
      initial_snap={0.4}
      title="Up next"
      description="Drag the sheet up for the full queue"
    >
      <div class="flex items-center gap-3 pb-4 mb-2 border-b border-gray-100 dark:border-white/10">
        <div class="flex items-center justify-center flex-none w-14 h-14 rounded-lg bg-primary-500/10">
          <.icon name="hero-musical-note" class="w-6 h-6 text-primary-500" />
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-xs tracking-wide text-gray-400 uppercase">Now playing</p>
          <p class="text-sm font-medium text-gray-900 truncate dark:text-gray-100">
            Midnight in the Garden
          </p>
          <p class="text-xs text-gray-500 truncate dark:text-gray-400">Marlowe Hart</p>
        </div>
        <.icon name="hero-pause-circle" class="flex-none w-8 h-8 text-gray-400" />
      </div>

      <div class="flex flex-col divide-y divide-gray-100 dark:divide-white/10">
        <div
          :for={
            {track, artist, length} <- [
              {"Slow Tide", "Marlowe Hart", "3:41"},
              {"Paper Lanterns", "The Wilder Sons", "4:12"},
              {"Coastline", "Ivy Kane", "2:58"},
              {"Halfway Home", "Marlowe Hart", "5:03"},
              {"Blue Hour", "Ivy Kane", "3:22"},
              {"Northbound", "The Wilder Sons", "4:47"},
              {"Little Fires", "Ada Vance", "3:09"},
              {"Weather Report", "Ivy Kane", "3:55"}
            ]
          }
          class="flex items-center gap-3 py-3"
        >
          <.icon name="hero-bars-3" class="flex-none w-4 h-4 text-gray-300 dark:text-gray-600" />
          <div class="flex-1 min-w-0">
            <p class="text-sm text-gray-900 truncate dark:text-gray-100">{track}</p>
            <p class="text-xs text-gray-500 truncate dark:text-gray-400">{artist}</p>
          </div>
          <p class="text-xs tabular-nums text-gray-400">{length}</p>
        </div>
      </div>
    </.slide_over>
    """
  end

  example :action_drawer, "Action sheet",
    description:
      "The classic phone pattern: a short list of actions and a cancel row. The sheet is content-height with no snap points, so it sits exactly as tall as it needs to be. Drag works from anywhere on it, not just the pill - the handle is decorative and aria-hidden." do
    ~H"""
    <.button
      color="gray"
      variant="outline"
      phx-click={show_slide_over("bottom", "showcase-sheet-share")}
    >
      <.icon name="hero-share" class="w-4 h-4 mr-1" /> Share
    </.button>

    <.slide_over id="showcase-sheet-share" hide origin="bottom" title="Share this page">
      <div class="flex flex-col -mx-2">
        <button
          :for={
            {icon, label, hint} <- [
              {"hero-link", "Copy link", "petal.build/components"},
              {"hero-envelope", "Email a colleague", "Opens your mail client"},
              {"hero-chat-bubble-left-right", "Post to Slack", "#design-system"},
              {"hero-bookmark", "Save for later", "Adds to your reading list"}
            ]
          }
          type="button"
          class="flex items-center gap-3 px-2 py-3 text-left transition-colors rounded-lg cursor-pointer hover:bg-gray-50 focus:outline-hidden focus-visible:ring-2 focus-visible:ring-primary-500/50 dark:hover:bg-white/5"
        >
          <div class="flex items-center justify-center flex-none w-9 h-9 rounded-full bg-gray-100 dark:bg-white/10">
            <.icon name={icon} class="w-4 h-4 text-gray-500 dark:text-gray-400" />
          </div>
          <div class="min-w-0">
            <p class="text-sm font-medium text-gray-900 dark:text-gray-100">{label}</p>
            <p class="text-xs text-gray-500 truncate dark:text-gray-400">{hint}</p>
          </div>
        </button>
      </div>
      <:footer>
        <.button
          color="gray"
          variant="outline"
          class="w-full"
          phx-click={hide_slide_over("bottom", "showcase-sheet-share")}
        >
          Cancel
        </.button>
      </:footer>
    </.slide_over>
    """
  end
end
