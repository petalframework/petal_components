defmodule PetalComponents.Modal do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import PetalComponents.Helpers

  # prop title, :string
  # prop size, :string
  # prop close_modal_target, :string
  # slot default
  def modal(assigns) do
    assigns =
      assigns
      |> assign_new(:classes, fn -> get_classes(assigns) end)
      |> assign_new(:close_modal_target, fn -> nil end)
      |> assign_rest(~w(classes title size)a)

    ~H"""
    <div {@rest} id="modal">
      <div
        id="modal-overlay"
        class="fixed inset-0 z-50 transition-opacity bg-gray-900 animate-fade-in dark:bg-gray-900 bg-opacity-30 dark:bg-opacity-70"
        aria-hidden="true"
      >
      </div>

      <div
        class="fixed inset-0 z-50 flex items-center justify-center px-4 my-4 overflow-hidden transform sm:px-6"
        role="dialog"
        aria-modal="true"
      >

        <div
          id="modal-content"
          class={@classes}
          phx-click-away={hide_modal(@close_modal_target)}
          phx-window-keydown={hide_modal(@close_modal_target)}
          phx-key="escape"
        >

          <!-- Header -->
          <div class="px-5 py-3 border-b border-gray-100 dark:border-gray-700">
            <div class="flex items-center justify-between">
              <div class="font-semibold text-gray-800 dark:text-gray-200">
                <%= @title %>
              </div>

              <button phx-click={hide_modal(@close_modal_target)} class="text-gray-400 hover:text-gray-500">
                <div class="sr-only">Close</div>
                <svg class="w-4 h-4 fill-current">
                  <path d="M7.95 6.536l4.242-4.243a1 1 0 111.415 1.414L9.364 7.95l4.243 4.242a1 1 0 11-1.415 1.415L7.95 9.364l-4.243 4.243a1 1 0 01-1.414-1.415L6.536 7.95 2.293 3.707a1 1 0 011.414-1.414L7.95 6.536z" />
                </svg>
              </button>
            </div>
          </div>

          <!-- Content -->
          <div class="p-5">
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

    base_classes =
      "animate-fade-in-scale w-full max-h-full overflow-auto bg-white rounded shadow-lg dark:bg-gray-800"

    max_width_class =
      case opts.max_width do
        "sm" -> "max-w-sm"
        "md" -> "max-w-xl"
        "lg" -> "max-w-3xl"
        "xl" -> "max-w-5xl"
        "2xl" -> "max-w-7xl"
        "full" -> "max-w-full"
      end

    custom_classes = opts.class

    build_class([max_width_class, base_classes, custom_classes])
  end
end
