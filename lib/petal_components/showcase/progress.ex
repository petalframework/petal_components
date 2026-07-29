defmodule PetalComponents.Showcase.Progress do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Progress, title: "Progress"

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
end
