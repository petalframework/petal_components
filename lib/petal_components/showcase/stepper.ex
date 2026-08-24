defmodule PetalComponents.Showcase.Stepper do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Stepper, title: "Stepper"

  example :horizontal, "Steps from plain maps",
    description:
      "Multi-step progress for onboarding, checkout, wizards. Steps are plain maps - name, description, complete?, active?, and an optional on_click JS command to make them jump targets. aria-current and completed labels are wired for screen readers. Beside-labels run wide, so a constrained container gives the rail an overflow-x-auto wrapper and lets it scroll." do
    ~H"""
    <div class="overflow-x-auto">
      <.stepper steps={[
        %{name: "Account", description: "Email and password", complete?: true, active?: false},
        %{name: "Workspace", description: "Name your project", complete?: false, active?: true},
        %{name: "Invite", description: "Bring the team", complete?: false, active?: false},
        %{name: "Review", description: "Confirm and finish", complete?: false, active?: false}
      ]} />
    </div>
    """
  end

  example :label_less, "Circles that don't need names",
    description:
      "Leave name and description off a step and the label block isn't rendered at all, so you get circles and connectors with nothing padding them out. No variant to reach for: it's the same stepper with less in the maps. Pairs with size=\"xs\" when the rail is a status line above a form rather than the page's headline." do
    ~H"""
    <.stepper
      size="xs"
      steps={[
        %{complete?: true, active?: false},
        %{complete?: true, active?: false},
        %{complete?: false, active?: true},
        %{complete?: false, active?: false},
        %{complete?: false, active?: false}
      ]}
    />
    """
  end

  example :bottom_labels, "Labels underneath",
    description:
      "label_placement=\"bottom\" is the classic wizard look - circles in a row, labels centred underneath, connectors pinned to the circle centres. Horizontal only, at every width - on small screens the rail compresses rather than stacking." do
    ~H"""
    <.stepper
      label_placement="bottom"
      steps={[
        %{name: "Cart", complete?: true, active?: false},
        %{name: "Shipping", complete?: true, active?: false},
        %{name: "Payment", complete?: false, active?: true},
        %{name: "Confirm", complete?: false, active?: false}
      ]}
    />
    """
  end

  example :vertical, "Vertical",
    description:
      "orientation=\"vertical\" runs the rail down the side - the settings-checklist and deploy-pipeline arrangement, with descriptions beside each circle." do
    ~H"""
    <.stepper
      orientation="vertical"
      steps={[
        %{
          name: "Repository connected",
          description: "GitHub app installed",
          complete?: true,
          active?: false
        },
        %{name: "First deploy", description: "Build and release", complete?: false, active?: true},
        %{
          name: "Custom domain",
          description: "DNS and certificates",
          complete?: false,
          active?: false
        }
      ]}
    />
    """
  end

  example :bars, "Segments instead of circles",
    description:
      "variant=\"bars\" swaps the numbered discs for a row of 4px segments and drops the connectors, because the gaps between segments are already the rail. Done and current fill solid, ahead of you stays gray. The numerals stay in the DOM for screen readers, and clicking a segment still fires that step's on_click. Horizontal only." do
    ~H"""
    <.stepper
      variant="bars"
      steps={[
        %{complete?: true, active?: false},
        %{complete?: true, active?: false},
        %{complete?: false, active?: true},
        %{complete?: false, active?: false},
        %{complete?: false, active?: false}
      ]}
    />
    """
  end

  example :bars_with_titles, "Segments with titles",
    description:
      "Give the steps names and each title sits under its own segment, left-aligned to it, with the ones you haven't reached reading a notch back. Below sm every title but the current step's hides, so the segments carry the count on a phone and the aria-labels keep the names." do
    ~H"""
    <.stepper
      variant="bars"
      steps={[
        %{name: "Cart", complete?: true, active?: false},
        %{name: "Address", complete?: true, active?: false},
        %{name: "Payment", complete?: false, active?: true},
        %{name: "Confirm", complete?: false, active?: false}
      ]}
    />
    """
  end

  example :step_counter, "One label for the whole rail",
    description:
      "The other way to label a stepper: nameless segments, then a single line naming the step you're on with a count beside it. That's composition, not an attr - the stepper renders the rail and you own the row underneath, which is also where Back and Next belong. Copy it as the shape for a wizard footer." do
    ~H"""
    <div class="w-full max-w-md">
      <.stepper
        variant="bars"
        steps={[
          %{complete?: true, active?: false},
          %{complete?: true, active?: false},
          %{complete?: false, active?: true},
          %{complete?: false, active?: false}
        ]}
      />
      <div class="flex items-baseline justify-between mt-4">
        <p class="text-sm font-semibold text-gray-900 dark:text-gray-100">Payment</p>
        <p class="text-sm text-gray-500 tabular-nums dark:text-gray-400">Step 3 of 4</p>
      </div>
      <div class="flex items-center justify-between mt-4">
        <.button color="gray" variant="outline" size="sm" label="Back" />
        <.button size="sm" label="Continue" />
      </div>
    </div>
    """
  end
end
