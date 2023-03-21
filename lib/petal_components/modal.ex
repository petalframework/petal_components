defmodule PetalComponents.Modal do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import PetalComponents.Helpers

  attr(:title, :string, default: nil, doc: "modal title")

  attr(:close_modal_target, :string,
    default: nil,
    doc:
      "close_modal_target allows you to target a specific live component for the close event to go to. eg: close_modal_target={@myself}"
  )

  attr(:max_width, :string,
    default: "md",
    values: ["sm", "md", "lg", "xl", "2xl", "full"],
    doc: "modal max width"
  )

  attr(:rest, :global)
  slot(:inner_block, required: false)

  def modal(assigns) do
    assigns =
      assigns
      |> assign(:classes, get_classes(assigns))

    ~H"""
    <div {@rest} id="modal">
      <div id="modal-overlay" class="pc-modal__overlay" aria-hidden="true"></div>

      <div class="pc-modal__wrapper" role="dialog" aria-modal="true">
        <div
          id="modal-content"
          class={@classes}
          phx-click-away={hide_modal(@close_modal_target)}
          phx-window-keydown={hide_modal(@close_modal_target)}
          phx-key="escape"
        >
          <!-- Header -->
          <div class="pc-modal__header">
            <div class="pc-modal__header__container">
              <div class="pc-modal__header__text">
                <%= @title %>
              </div>

              <button phx-click={hide_modal(@close_modal_target)} class="pc-modal__header__button">
                <div class="sr-only">Close</div>
                <svg class="pc-modal__header__close-svg">
                  <path d="M7.95 6.536l4.242-4.243a1 1 0 111.415 1.414L9.364 7.95l4.243 4.242a1 1 0 11-1.415 1.415L7.95 9.364l-4.243 4.243a1 1 0 01-1.414-1.415L6.536 7.95 2.293 3.707a1 1 0 011.414-1.414L7.95 6.536z" />
                </svg>
              </button>
            </div>
          </div>
          <!-- Content -->
          <div class="pc-modal__content">
            <%= render_slot(@inner_block) %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # The live view that calls <.modal> will need to handle the "close_modal" event. eg:
  # def handle_event("close_modal", _, socket) do
  #   {:noreply, push_patch(socket, to: Routes.moderate_users_path(socket, :index))}
  # end
  def hide_modal(close_modal_target \\ nil) do
    js =
      %JS{}
      |> JS.remove_class("overflow-hidden", to: "body")
      |> JS.remove_class("animate-fade-in", to: "#modal-overlay")
      |> JS.hide(
        transition: {
          "ease-in duration-200",
          "opacity-100",
          "opacity-0"
        },
        to: "#modal-overlay"
      )
      |> JS.hide(
        transition: {
          "ease-in duration-200",
          "opacity-100 translate-y-0 md:scale-100",
          "opacity-0 translate-y-4 md:translate-y-0 md:scale-95"
        },
        to: "#modal-content"
      )

    if close_modal_target do
      JS.push(js, "close_modal", target: close_modal_target)
    else
      JS.push(js, "close_modal")
    end
  end

  # We are unsure of what the best practice is for using this.
  # Open to suggestions/PRs
  def show_modal(js \\ %JS{}) do
    js
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.show(
      transition: {
        "ease-in duration-300",
        "opacity-0",
        "opacity-100"
      },
      to: "#modal-overlay"
    )
    |> JS.show(
      transition: {
        "transition ease-in-out duration-200",
        "opacity-0 translate-y-4",
        "opacity-100 translate-y-0"
      },
      to: "#modal-content"
    )
  end

  defp get_classes(assigns) do
    opts = %{
      max_width: assigns[:max_width] || "md",
      class: assigns[:class] || ""
    }

    base_classes = "pc-modal__box"
    max_width_class = "pc-modal__box--#{opts.max_width}"
    custom_classes = opts.class

    build_class([max_width_class, base_classes, custom_classes])
  end
end
