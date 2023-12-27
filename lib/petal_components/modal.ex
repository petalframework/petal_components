defmodule PetalComponents.Modal do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, default: "modal", doc: "modal id"
  attr :hide, :boolean, default: false, doc: "modal is hidden"
  attr :title, :string, default: nil, doc: "modal title"

  attr :close_modal_target, :string,
    default: nil,
    doc:
      "close_modal_target allows you to target a specific live component for the close event to go to. eg: close_modal_target={@myself}"

  attr :close_on_click_away, :boolean,
    default: true,
    doc: "whether the modal should close when a user clicks away"

  attr :close_on_escape, :boolean,
    default: true,
    doc: "whether the modal should close when a user hits escape"

  attr :hide_close_button, :boolean,
    default: false,
    doc: "whether or not the modal should have a close button in the header"

  attr :max_width, :string,
    default: "md",
    values: ["sm", "md", "lg", "xl", "2xl", "full"],
    doc: "modal max width"

  attr :rest, :global
  slot :inner_block, required: false

  def modal(assigns) do
    assigns =
      assigns
      |> assign(:classes, get_classes(assigns))

    ~H"""
    <div
      id={@id}
      phx-mounted={!@hide && show_modal(@id)}
      phx-remove={hide_modal(@close_modal_target, @id)}
      {@rest}
      class="hidden pc-modal"
    >
      <div class="pc-modal__overlay" aria-hidden="true"></div>
      <div class="pc-modal__wrapper" role="dialog" aria-modal="true">
        <div
          class={@classes}
          phx-click-away={@close_on_click_away && hide_modal(@close_modal_target, @id)}
          phx-window-keydown={@close_on_escape && hide_modal(@close_modal_target, @id)}
          phx-key="escape"
        >
          <!-- Header -->
          <div class="pc-modal__header">
            <div class="pc-modal__header__container">
              <div class="pc-modal__header__text">
                <%= @title %>
              </div>
              <%= unless @hide_close_button do %>
                <button
                  type="button"
                  phx-click={hide_modal(@close_modal_target, @id)}
                  class="pc-modal__header__button"
                >
                  <div class="sr-only">Close</div>
                  <Heroicons.x_mark class="pc-modal__header__close-svg" />
                </button>
              <% end %>
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
  def hide_modal(close_modal_target \\ nil, id \\ "modal") do
    js =
      %JS{}
      |> JS.hide(
        to: "##{id} .pc-modal__overlay",
        transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
      )
      |> JS.hide(
        to: "##{id} .pc-modal__box",
        time: 200,
        transition:
          {"transition-all transform ease-in duration-200",
           "opacity-100 translate-y-0 sm:scale-100",
           "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
      )
      |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
      |> JS.remove_class("overflow-hidden", to: "body")

    if close_modal_target do
      JS.push(js, "close_modal", target: close_modal_target, value: %{id: id})
    else
      JS.push(js, "close_modal", value: %{id: id})
    end
  end

  # We are unsure of what the best practice is for using this.
  # Open to suggestions/PRs
  def show_modal(js \\ %JS{}, id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id} .pc-modal__overlay",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id} .pc-modal__box",
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id} .pc-modal__box")
  end

  defp get_classes(assigns) do
    opts = %{
      max_width: assigns[:max_width] || "md",
      class: assigns[:class] || ""
    }

    base_classes = "pc-modal__box"
    max_width_class = "pc-modal__box--#{opts.max_width}"
    custom_classes = opts.class

    [max_width_class, base_classes, custom_classes]
  end
end
