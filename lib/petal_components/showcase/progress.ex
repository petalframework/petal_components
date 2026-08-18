defmodule PetalComponents.Showcase.Progress do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Progress,
    title: "Progress",
    functions: [:progress, :progress_ring]

  example :semantic_colors, "Semantic colours",
    description:
      "Determinate progress on a washed track. color tints the bar with the semantic range - success for healthy, warning and danger as budgets run down." do
    ~H"""
    <div class="w-full max-w-md space-y-4">
      <.progress value={80} color="success" />
      <.progress value={55} color="info" />
      <.progress value={35} color="warning" />
      <.progress value={15} color="danger" />
    </div>
    """
  end

  example :sizes, "Sizes",
    description:
      "size runs xs to xl. The thin end suits page-top loading strips; xl is the only size tall enough to carry a label inside the bar." do
    ~H"""
    <div class="w-full max-w-md space-y-4">
      <.progress :for={z <- ~w(xs sm md lg xl)} value={60} size={z} />
    </div>
    """
  end

  example :labels_status, "Labels and status",
    description:
      "label renders inside the bar at xl (the only size tall enough); label_position=\"top\" puts it in a label row above the bar at any size. status adds the \"Downloading assets...\" line under the bar in a polite live region, so screen readers hear stage changes without being spammed by every percent." do
    ~H"""
    <div class="w-full max-w-md space-y-6">
      <.progress value={60} size="xl" label="60%" />
      <.progress value={56} size="sm" label="Upload progress" label_position="top" />
      <.progress
        value={45}
        size="sm"
        label="Installing"
        label_position="top"
        status="Downloading assets (12 of 30)..."
      />
    </div>
    """
  end

  example :ring, "Ring",
    description:
      "The same component, drawn round. Same value, max, size and color attrs as the bar, so the two shapes stay in step on a page that uses both. The arc starts at 12 o'clock and rides currentColor, so a text class recolours it. show_value drops the percentage in the hole - md and up have room to read it." do
    ~H"""
    <div class="flex flex-col items-center gap-8">
      <div class="flex flex-wrap items-center justify-center gap-6">
        <.progress_ring :for={z <- ~w(xs sm md lg xl)} value={68} size={z} />
      </div>
      <div class="flex flex-wrap items-center justify-center gap-6">
        <.progress_ring value={92} size="lg" color="success" show_value />
        <.progress_ring value={64} size="lg" color="info" show_value />
        <.progress_ring value={38} size="lg" color="warning" show_value />
        <.progress_ring value={11} size="lg" color="danger" show_value />
      </div>
    </div>
    """
  end

  example :ring_in_rows, "Rings in a table",
    description:
      "The one that earns its keep: a 16px ring beside the number, read down a column at a glance. Five bars stacked in five rows is a barcode; five rings is a shape you can scan. The middle takes a slot too, so it can hold a count instead of a percentage." do
    ~H"""
    <div class="w-full max-w-md">
      <div class="divide-y divide-gray-200 dark:divide-gray-800">
        <div class="flex items-center justify-between gap-4 py-3">
          <span class="text-sm">Design system</span>
          <span class="flex items-center gap-2 text-sm text-gray-500 tabular-nums dark:text-gray-400">
            <.progress_ring value={92} size="xs" color="success" label="Design system" /> 92%
          </span>
        </div>
        <div class="flex items-center justify-between gap-4 py-3">
          <span class="text-sm">Billing rewrite</span>
          <span class="flex items-center gap-2 text-sm text-gray-500 tabular-nums dark:text-gray-400">
            <.progress_ring value={61} size="xs" color="info" label="Billing rewrite" /> 61%
          </span>
        </div>
        <div class="flex items-center justify-between gap-4 py-3">
          <span class="text-sm">Docs backlog</span>
          <span class="flex items-center gap-2 text-sm text-gray-500 tabular-nums dark:text-gray-400">
            <.progress_ring value={18} size="xs" color="warning" label="Docs backlog" /> 18%
          </span>
        </div>
      </div>
      <div class="flex items-center gap-4 pt-6">
        <.progress_ring value={12} max={30} size="lg" color="secondary" label="Files uploaded">
          <span class="text-xs">12/30</span>
        </.progress_ring>
        <div class="text-sm text-gray-500 dark:text-gray-400">
          The slot wins over show_value, so the middle can carry a count or an icon.
        </div>
      </div>
    </div>
    """
  end
end
