defmodule PetalComponents.SlideOver do
  use Phoenix.Component

  import PetalComponents.Helpers

  alias Phoenix.LiveView.JS

  attr(:origin, :string,
    default: "right",
    values: ["left", "right", "top", "bottom"],
    doc: "slideover point of origin"
  )

  attr(:close_slide_over_target, :string,
    default: nil,
    doc:
      "close_slide_over_target allows you to target a specific live component for the close event to go to. eg: close_slide_over_target={@myself}"
  )

  attr(:title, :string, default: nil, doc: "slideover title")

  attr(:max_width, :string,
    default: "md",
    values: ["sm", "md", "lg", "xl", "2xl", "full"],
    doc: "sets container max-width"
  )

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def slide_over(assigns) do
    ~H"""
    <div {@rest} id="slide-over">
      <div id="slide-over-overlay" class="pc-slideover__overlay" aria-hidden="true"></div>

      <div
        class={
          build_class([
            "pc-slideover__wrapper",
            get_margin_classes(@origin),
            @class
          ])
        }
        role="dialog"
        aria-modal="true"
      >
        <div
          id="slide-over-content"
          class={get_classes(@max_width, @origin, @class)}
          phx-click-away={hide_slide_over(@origin, @close_slide_over_target)}
          phx-window-keydown={hide_slide_over(@origin, @close_slide_over_target)}
          phx-key="escape"
        >
          <!-- Header -->
          <div class="pc-slideover__header">
            <div class="pc-slideover__header__container">
              <div class="pc-slideover__header__text">
                <%= @title %>
              </div>

              <button
                phx-click={hide_slide_over(@origin, @close_slide_over_target)}
                class="pc-slideover__header__button"
              >
                <div class="sr-only">Close</div>
                <svg class="pc-slideover__header__close-svg">
                  <path d="M7.95 6.536l4.242-4.243a1 1 0 111.415 1.414L9.364 7.95l4.243 4.242a1 1 0 11-1.415 1.415L7.95 9.364l-4.243 4.243a1 1 0 01-1.414-1.415L6.536 7.95 2.293 3.707a1 1 0 011.414-1.414L7.95 6.536z" />
                </svg>
              </button>
            </div>
          </div>
          <!-- Content -->
          <div class="pc-slideover__content">
            <%= render_slot(@inner_block) %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # The live view that calls <.slide_over> will need to handle the "close_slide_over" event. eg:
  # def handle_event("close_slide_over", _, socket) do
  #   {:noreply, push_patch(socket, to: Routes.moderate_users_path(socket, :index))}
  # end
  def hide_slide_over(origin, close_slide_over_target \\ nil) do
    origin_class =
      case origin do
        x when x in ["left", "right"] -> "translate-x-0"
        x when x in ["top", "bottom"] -> "translate-y-0"
      end

    destination_class =
      case origin do
        "left" -> "-translate-x-full"
        "right" -> "translate-x-full"
        "top" -> "-translate-y-full"
        "bottom" -> "translate-y-full"
      end

    js =
      JS.remove_class("overflow-hidden", to: "body")
      |> JS.hide(
        transition: {
          "ease-in duration-200",
          "opacity-100",
          "opacity-0"
        },
        to: "#slide-over-overlay"
      )
      |> JS.hide(
        transition: {
          "ease-in duration-200",
          origin_class,
          destination_class
        },
        to: "#slide-over-content"
      )

    if close_slide_over_target do
      JS.push(js, "close_slide_over", target: close_slide_over_target)
    else
      JS.push(js, "close_slide_over")
    end
  end

  defp get_classes(max_width, origin, class) do
    base_classes = "pc-slideover__box"

    slide_over_classes =
      case origin do
        "left" -> "transition translate-x-0"
        "right" -> "transition translate-x-0 absolute right-0 inset-y-0"
        "top" -> "transition translate-y-0 absolute inset-x-0"
        "bottom" -> "transition translate-y-0 absolute inset-x-0 bottom-0"
      end

    max_width_class =
      case origin do
        x when x in ["left", "right"] ->
          case max_width do
            "sm" -> "pc-slideover__box--sm"
            "md" -> "pc-slideover__box--md"
            "lg" -> "pc-slideover__box--lg"
            "xl" -> "pc-slideover__box--xl"
            "2xl" -> "pc-slideover__box--2xl"
            "full" -> "pc-slideover__box--full"
          end

        x when x in ["top", "bottom"] ->
          ""
      end

    custom_classes = class

    build_class([slide_over_classes, max_width_class, base_classes, custom_classes])
  end

  defp get_margin_classes(margin) do
    case margin do
      "left" -> "mr-10"
      "right" -> "ml-10"
      "top" -> "mb-10"
      "bottom" -> "mt-10"
    end
  end
end
