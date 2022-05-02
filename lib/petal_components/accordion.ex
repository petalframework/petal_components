defmodule PetalComponents.Accordion do
  use Phoenix.Component
  import PetalComponents.Class
  alias PetalComponents.Heroicons
  alias Phoenix.LiveView.JS

  # prop js_lib, :string, default: "alpine_js", options: ["alpine_js", "live_view_js"]
  # prop class, :string
  # prop heading, :string
  # prop icon, :string
  # slot default
  def accordion(assigns) do
    assigns =
      assigns
      |> assign_new(:container_id, fn -> "accordion_#{Ecto.UUID.generate()}" end)
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:inner_block, fn -> nil end)
      |> assign_new(:heading, fn -> nil end)
      |> assign_new(:item, fn -> nil end)
      |> assign_new(:icon, fn -> "chevron" end)
      |> assign_new(:js_lib, fn -> "alpine_js" end)
      |> assign_new(:extra_assigns, fn ->
        assigns_to_attributes(assigns, ~w(
          class
          js_lib
          container_id
          inner_block
          icon
          heading
          item
        )a)
      end)

    ~H"""
    <div
      id={@container_id}
      class={@class}
      {@extra_assigns}
      {js_attributes("container", @js_lib, @container_id, nil)}
    >
      <%= for {item, i} <- Enum.with_index(@item) do %>
        <div {js_attributes("item", @js_lib, @container_id, i)} data-i={i}>
          <h2>
            <button
              {js_attributes("button", @js_lib, @container_id, i)}
              class={build_class([
                "flex items-center justify-between w-full p-5 text-left text-gray-500 border border-gray-200 dark:border-gray-700 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800 accordion-button",
                (if i == 0, do: "rounded-t-xl"),
                (unless i == length(@item) - 1, do: "border-b-0")
              ])}
            >
              <span class="font-semibold text-md">
                <%= item.heading %>
              </span>

              <%= if @icon == "chevron" do %>
                <Heroicons.Solid.chevron_down
                  class="flex-shrink-0 w-6 h-6 ml-3 text-gray-400 duration-300 fill-current dark:group-hover:text-gray-300 group-hover:text-gray-500"
                  {js_attributes("icon", @js_lib, @container_id, i)}
                />
              <% else %>
                <Heroicons.Solid.render
                  icon={@icon}
                  class="flex-shrink-0 w-6 h-6 ml-3 text-gray-400 duration-300 fill-current dark:group-hover:text-gray-300 group-hover:text-gray-500"
                  {js_attributes("icon", @js_lib, @container_id, i)}
                />
              <% end %>
            </button>
          </h2>
          <div {js_attributes("content_container", @js_lib, @container_id, i)} class="accordion-content-container">
            <div
              class={build_class([
                "p-5 border border-gray-200 dark:border-gray-700 dark:bg-gray-900",
                (if i == length(@item) - 1, do: "border-t-0", else: "border-b-0")
              ])}
            >
              <%= render_slot(item) %>
            </div>
          </div>
        </div>
      <% end %>
    </div>

    <script>
      window.addEventListener("click_accordion", e => {
        let containerId = e.detail.container_id;
        let i = e.detail.index;
        let clickedAccordionItem = e.target;
        let currentlyOpenAccordionItem = document.querySelector("[data-open='true']")
        let isClosingClickedAccordionItem = !!currentlyOpenAccordionItem && currentlyOpenAccordionItem == clickedAccordionItem;

        // Close open accordion item
        if(currentlyOpenAccordionItem) {
          currentlyOpenAccordionItem.dataset.open = false
          currentlyOpenAccordionItem.querySelector("svg").classList.remove("rotate-180");
          currentlyOpenAccordionItem.querySelector(`.accordion-content-container`).style.display = "none";
          currentlyOpenAccordionItem.querySelector(`.accordion-button`).classList.remove("bg-gray-50", "dark:bg-gray-800");
        }

        // Open clicked accordion item (if not already open)
        if (!isClosingClickedAccordionItem) {
          clickedAccordionItem.dataset.open = true
          clickedAccordionItem.querySelector("svg").classList.add("rotate-180");
          clickedAccordionItem.querySelector(`.accordion-content-container`).style.display = "block";
          clickedAccordionItem.querySelector(`.accordion-button`).classList.add("bg-gray-50", "dark:bg-gray-800");
        }
      })
    </script>
    """
  end

  defp js_attributes("container", "alpine_js", _container_id, _i) do
    %{
      "x-data": "{ active: null }"
    }
  end

  defp js_attributes("item", "alpine_js", _container_id, i) do
    %{
      "x-data": "{
        id: #{i},
        get expanded() {
          return this.active === this.id
        },
        set expanded(value) {
          this.active = value ? this.id : null
        },
      }"
    }
  end

  defp js_attributes("button", "alpine_js", _container_id, _) do
    %{
      "x-on:click": "expanded = !expanded",
      ":class": "expanded ? 'bg-gray-50 dark:bg-gray-800' : ''",
      ":aria-expanded": "expanded"
    }
  end

  defp js_attributes("content_container", "alpine_js", _container_id, _) do
    %{
      "x-show": "expanded",
      "x-cloak": true,
      "x-collapse": true
    }
  end

  defp js_attributes("icon", "alpine_js", _container_id, _) do
    %{
      ":class": "{ 'rotate-180': expanded }"
    }
  end

  defp js_attributes("container", "live_view_js", _container_id, _i) do
    %{}
  end

  defp js_attributes("item", "live_view_js", _container_id, _i) do
    %{}
  end

  defp js_attributes("button", "live_view_js", container_id, i) do
    %{
      "phx-click":
        JS.dispatch("click_accordion",
          to: "##{container_id} [data-i='#{i}']",
          detail: %{container_id: container_id, index: i}
        )
    }
  end

  defp js_attributes("content_container", "live_view_js", _container_id, _i) do
    %{
      style: "display: none;"
    }
  end

  defp js_attributes("icon", "live_view_js", _container_id, _) do
    %{}
  end
end
