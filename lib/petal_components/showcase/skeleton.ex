defmodule PetalComponents.Showcase.Skeleton do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Skeleton,
    title: "Skeleton",
    functions: [:skeleton, :skeleton_group, :skeleton_text]

  example :article, "Compose any loading state",
    description:
      "One brick, sized with classes - compose the layout you're loading instead of picking from prebuilt shapes. skeleton_group is the accessibility wrapper: role=\"status\" and aria-busy announce loading once (set the label) while the bricks stay aria-hidden, and its animation cascades to everything inside." do
    ~H"""
    <.skeleton_group label="Loading article" class="flex w-full max-w-md flex-col gap-5">
      <.skeleton class="h-40 w-full" />
      <div class="flex items-center gap-4">
        <.skeleton variant="circle" class="size-12 shrink-0" />
        <div class="flex-1 space-y-2.5">
          <.skeleton variant="text" class="w-1/2" />
          <.skeleton variant="text" class="w-3/4" />
        </div>
      </div>
      <.skeleton_text lines={3} />
    </.skeleton_group>
    """
  end

  example :shapes, "Shapes",
    description:
      "Three forms cover everything: the block (follows the radius token), variant=\"circle\" for avatars, and skeleton_text for line runs - its widths are deterministic, so LiveView re-renders never make it dance. animation is pulse, shimmer or none; shimmer respects prefers-reduced-motion." do
    ~H"""
    <div class="flex items-end justify-center gap-8">
      <div class="flex flex-col items-center gap-2">
        <.skeleton class="h-16 w-24" />
        <span class="text-[11px] text-gray-400">block</span>
      </div>
      <div class="flex flex-col items-center gap-2">
        <.skeleton variant="circle" class="size-16" animation="shimmer" />
        <span class="text-[11px] text-gray-400">circle, shimmer</span>
      </div>
      <div class="flex w-40 flex-col items-center gap-2">
        <.skeleton_text lines={3} />
        <span class="text-[11px] text-gray-400">skeleton_text</span>
      </div>
    </div>
    """
  end
end
