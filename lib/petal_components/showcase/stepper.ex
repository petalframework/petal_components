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
end
