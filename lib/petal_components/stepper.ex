defmodule PetalComponents.Stepper do
  use Phoenix.Component
  import PetalComponents.Icon

  attr :steps, :list, required: true
  attr :orientation, :string, default: "horizontal", values: ["horizontal", "vertical"]
  attr :size, :string, default: "md", values: ["sm", "md", "lg"]
  attr :class, :string, default: ""

  def stepper(assigns) do
    ~H"""
    <div
      class={[
        "pc-stepper",
        "pc-stepper--#{@orientation}",
        "pc-stepper--#{@size}",
        @class
      ]}
      role="list"
      aria-label="Progress steps"
    >
      <div class="pc-stepper__container">
        <%= for {step, index} <- Enum.with_index(@steps) do %>
          <!-- Step Item -->
          <div class="pc-stepper__item" role="listitem">
            <button
              type="button"
              class="pc-stepper__item-content"
              id={"step-#{index}"}
              phx-click={step[:on_click]}
              aria-current={step.active? && "step"}
              aria-label={"Step #{index + 1}: #{step.name}#{if step.complete?, do: " (completed)"}"}
            >
              <!-- Node -->
              <div class={[
                "pc-stepper__node",
                step.complete? && "pc-stepper__node--complete",
                step.active? && "pc-stepper__node--active"
              ]}>
                <div class="pc-stepper__indicator" aria-hidden="true">
                  <%= if step.complete? do %>
                    <.icon name="hero-check-solid" class="pc-stepper__check" />
                  <% else %>
                    <span class="pc-stepper__number">
                      {index + 1}
                    </span>
                  <% end %>
                </div>
              </div>
              <!-- Content -->
              <div class="pc-stepper__content">
                <h3 class="pc-stepper__title" id={"step-title-#{index}"}>
                  {step.name}
                </h3>
                <%= if Map.get(step, :description) do %>
                  <p class="pc-stepper__description" id={"step-description-#{index}"}>
                    {step.description}
                  </p>
                <% end %>
              </div>
            </button>
          </div>

          <%= if index < length(@steps) - 1 do %>
            <div class="pc-stepper__connector-wrapper" aria-hidden="true">
              <div class={[
                "pc-stepper__connector",
                step.complete? && Enum.at(@steps, index + 1).complete? &&
                  "pc-stepper__connector--complete"
              ]} />
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end
