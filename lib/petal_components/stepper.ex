defmodule PetalComponents.Stepper do
  use Phoenix.Component
  import Phoenix.HTML
  import PetalComponents.Icon

  attr :steps, :list, required: true
  attr :orientation, :string, default: "horizontal", values: ["horizontal", "vertical"]
  attr :size, :string, default: "md", values: ["sm", "md", "lg"]
  attr :class, :string, default: ""

  def stepper(assigns) do
    ~H"""
    <div class={[
      "pc-stepper",
      "pc-stepper--#{@orientation}",
      "pc-stepper--#{@size}",
      @class
    ]}>
      <div class="pc-stepper__container">
        <%= for {step, index} <- Enum.with_index(@steps) do %>
          <div class="pc-stepper__item">
            <div class="pc-stepper__item-content">
              <div
                class={[
                  "pc-stepper__node",
                  step.complete? && "pc-stepper__node--complete",
                  step.active? && "pc-stepper__node--active"
                ]}
                id={"step-#{index}"}
                phx-click={step[:on_click]}
              >
                <div class="pc-stepper__indicator">
                  <%= if step.complete? do %>
                    <.icon name="hero-check-solid" class="pc-stepper__check" />
                  <% else %>
                    <span class="pc-stepper__number">
                      <%= index + 1 %>
                    </span>
                  <% end %>
                </div>
                <div class="pc-stepper__content">
                  <h3 class="pc-stepper__title">
                    <%= step.name %>
                  </h3>
                  <%= if Map.get(step, :description) do %>
                    <p class="pc-stepper__description">
                      <%= step.description %>
                    </p>
                  <% end %>
                </div>
              </div>
            </div>
            <%= if index < length(@steps) - 1 do %>
              <div class="pc-stepper__connector-wrapper">
                <div class={[
                  "pc-stepper__connector",
                  step.complete? && Enum.at(@steps, index + 1).complete? &&
                    "pc-stepper__connector--complete"
                ]} />
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
