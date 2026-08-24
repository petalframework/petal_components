defmodule PetalComponents.Stepper do
  use Phoenix.Component
  import PetalComponents.Icon

  attr :steps, :list, required: true
  attr :orientation, :string, default: "horizontal", values: ["horizontal", "vertical"]
  attr :size, :string, default: "md", values: ["xs", "sm", "md", "lg"]

  attr :variant, :string,
    default: "circles",
    values: ["circles", "bars"],
    doc:
      "bars trades the numbered circles for a row of segments - the progress-bar read, with each step's title under its own segment. Horizontal only; ignored when vertical, and it takes precedence over label_placement (a bar's title always sits under it)"

  attr :label_placement, :string,
    default: "beside",
    values: ["beside", "bottom"],
    doc:
      "horizontal only: bottom centres the labels under the circles (the classic wizard look); ignored when vertical, where labels always sit beside"

  attr :class, :string, default: ""

  def stepper(assigns) do
    # Bars is a horizontal paint - a column of full-width segments is a
    # different component - so the whole variant resolves once, here, and the
    # rest of the template (and every CSS rule) reads the resolved answer.
    assigns =
      assign(assigns, :bars, assigns.orientation == "horizontal" and assigns.variant == "bars")

    ~H"""
    <div
      class={[
        "pc-stepper",
        "pc-stepper--#{@orientation}",
        "pc-stepper--#{@size}",
        @bars && "pc-stepper--bars",
        !@bars && @orientation == "horizontal" && @label_placement == "bottom" &&
          "pc-stepper--labels-bottom",
        @class
      ]}
      role="list"
      aria-label="Progress steps"
    >
      <div class="pc-stepper__container">
        <%= for {step, index} <- Enum.with_index(@steps) do %>
          <!-- Step Item -->
          <div
            class={[
              "pc-stepper__item",
              index > 0 && step.complete? && Enum.at(@steps, index - 1).complete? &&
                "pc-stepper__item--line-complete"
            ]}
            role="listitem"
          >
            <button
              type="button"
              class="pc-stepper__item-content"
              id={"step-#{index}"}
              phx-click={step[:on_click]}
              aria-current={step.active? && "step"}
              aria-label={step_aria_label(step, index)}
            >
              <!-- Node -->
              <div class={[
                "pc-stepper__node",
                step.complete? && "pc-stepper__node--complete",
                step.active? && "pc-stepper__node--active"
              ]}>
                <div class="pc-stepper__indicator" aria-hidden="true">
                  <%= if step.complete? and not @bars do %>
                    <.icon name="hero-check-solid" class="pc-stepper__check" />
                  <% else %>
                    <%!-- A 4px segment has no room for a glyph and reui draws
                    none, so bars keep the numeral as sr-only text rather than
                    painting it (and drop the tick entirely - it is disc
                    furniture). What assistive tech actually announces is the
                    button's aria-label, which is identical in both variants. --%>
                    <span class={["pc-stepper__number", @bars && "sr-only"]}>
                      {index + 1}
                    </span>
                  <% end %>
                </div>
              </div>
              <%!-- Content. A step with neither name nor description renders no
              content block at all - not an empty one - so the item's gap has
              nothing to reserve space for and a nameless stepper is just
              circles and connectors (reui's "basic stepper", no variant
              needed). --%>
              <div :if={step[:name] || step[:description]} class="pc-stepper__content">
                <h3 :if={step[:name]} class="pc-stepper__title" id={"step-title-#{index}"}>
                  {step[:name]}
                </h3>
                <p
                  :if={step[:description]}
                  class="pc-stepper__description"
                  id={"step-description-#{index}"}
                >
                  {step[:description]}
                </p>
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

  # The label is the one place a step's name is guaranteed to reach assistive
  # tech - the visual title hides under sm, and a nameless step never had one -
  # so the number carries the announcement on its own when there is no name.
  defp step_aria_label(step, index) do
    done = if step.complete?, do: " (completed)", else: ""

    case step[:name] do
      nil -> "Step #{index + 1}#{done}"
      name -> "Step #{index + 1}: #{name}#{done}"
    end
  end
end
