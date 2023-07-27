defmodule PetalComponents.Accordion do
  use Phoenix.Component
  import PetalComponents.Helpers
  alias Phoenix.LiveView.JS

  attr(:container_id, :string)
  attr(:class, :string, default: "", doc: "CSS class for parent container")
  attr(:entries, :list, default: [%{}])

  attr(:js_lib, :string,
    default: "alpine_js",
    values: ["alpine_js", "live_view_js"],
    doc: "javascript library used for toggling"
  )

  attr(:rest, :global)

  slot :item, required: true, doc: "CSS class for parent container" do
    attr(:heading, :string)
  end

  def accordion(assigns) do
    assigns =
      assigns
      |> assign_new(:container_id, fn -> "accordion_#{Ecto.UUID.generate()}" end)

    item =
      for entry <- assigns.entries, item <- assigns.item do
        item_heading = Map.get(item, :heading)
        entry_heading = Map.get(entry, :heading)

        if item_heading && entry_heading do
          raise ArgumentError, "specify heading in either :item or :entries"
        end

        heading = item_heading || entry_heading

        item
        |> Map.put(:heading, heading)
        |> Map.put(:entry, entry)
      end

    assigns = assign(assigns, :item, item)

    ~H"""
    <div
      id={@container_id}
      class={@class}
      {@rest}
      {js_attributes("container", @js_lib, @container_id, nil, nil)}
    >
      <%= for {current_item, i} <- Enum.with_index(@item) do %>
        <div {js_attributes("item", @js_lib, @container_id, i, length(@item))} data-i={i}>
          <h2>
            <button
              type="button"
              {js_attributes("button", @js_lib, @container_id, i, length(@item))}
              class={
                build_class([
                  "pc-accordion-item accordion-button",
                  if(i == 0, do: "pc-accordion-item--first"),
                  unless(i == length(@item) - 1, do: "pc-accordion-item--all-except-last"),
                  if(i == length(@item) - 1,
                    do:
                      "pc-accordion-item--last #{if @js_lib == "live_view_js", do: "pc-accordion-item--last--closed"}"
                  )
                ])
              }
            >
              <span class="pc-accordion-item__heading">
                <%= current_item.heading %>
              </span>

              <Heroicons.chevron_down
                solid
                class="pc-accordion-item__chevron"
                {js_attributes("icon", @js_lib, @container_id, i, length(@item))}
              />
            </button>
          </h2>
          <div
            {js_attributes("content_container", @js_lib, @container_id, i, length(@item))}
            class="accordion-content-container"
          >
            <div class={
              build_class([
                "pc-accordion-item__content-container",
                if(i == length(@item) - 1,
                  do: "pc-accordion-item__content-container--last",
                  else: "pc-accordion-item__content-container--not-last"
                )
              ])
            }>
              <%= render_slot(current_item, current_item.entry) %>
            </div>
          </div>
        </div>
      <% end %>
    </div>

    <script>
      window.addEventListener("click_accordion", e => {
        let i = e.detail.index;
        let l = e.detail.length
        let clickedAccordionItem = e.target;
        let currentlyOpenAccordionItem = document.querySelector("[data-open='true']")
        let isClosingClickedAccordionItem = !!currentlyOpenAccordionItem && currentlyOpenAccordionItem == clickedAccordionItem;
        let isLastAccordionItem = i == l - 1;

        // Close open accordion item
        if(currentlyOpenAccordionItem) {
          currentlyOpenAccordionItem.dataset.open = false
          currentlyOpenAccordionItem.querySelector("svg").classList.remove("rotate-180");
          currentlyOpenAccordionItem.querySelector(`.accordion-content-container`).style.display = "none";
          currentlyOpenAccordionItem.querySelector(`.accordion-button`).classList.remove("pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes");
          if(isLastAccordionItem){
            clickedAccordionItem.querySelector(`.accordion-button`).classList.add("pc-accordion-item--last--closed");
          }
        }

        // Open clicked accordion item (if not already open)
        if (!isClosingClickedAccordionItem) {
          clickedAccordionItem.dataset.open = true
          clickedAccordionItem.querySelector("svg").classList.add("rotate-180");
          clickedAccordionItem.querySelector(`.accordion-content-container`).style.display = "block";
          clickedAccordionItem.querySelector(`.accordion-button`).classList.add("pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes");
          if(isLastAccordionItem){
            clickedAccordionItem.querySelector(`.accordion-button`).classList.remove("pc-accordion-item--last--closed");
          }
        }
      })
    </script>
    """
  end

  defp js_attributes("container", "alpine_js", _container_id, _i, _) do
    %{
      "x-data": "{ active: null }"
    }
  end

  defp js_attributes("item", "alpine_js", _container_id, i, _) do
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

  defp js_attributes("button", "alpine_js", _container_id, i, l) when i == l - 1 do
    %{
      "x-on:click": "expanded = !expanded",
      ":class":
        "expanded ? 'pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes' : 'pc-accordion-item--last--closed'",
      ":aria-expanded": "expanded"
    }
  end

  defp js_attributes("button", "alpine_js", _container_id, _i, _l) do
    %{
      "x-on:click": "expanded = !expanded",
      ":class":
        "expanded ? 'pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes' : ''",
      ":aria-expanded": "expanded"
    }
  end

  defp js_attributes("content_container", "alpine_js", _container_id, _, _) do
    %{
      "x-show": "expanded",
      "x-cloak": true,
      "x-collapse": true
    }
  end

  defp js_attributes("icon", "alpine_js", _container_id, _, _) do
    %{
      ":class": "{ 'rotate-180': expanded }"
    }
  end

  defp js_attributes("container", "live_view_js", _container_id, _i, _) do
    %{}
  end

  defp js_attributes("item", "live_view_js", _container_id, _i, _) do
    %{}
  end

  defp js_attributes("button", "live_view_js", container_id, i, l) do
    %{
      "phx-click":
        JS.dispatch("click_accordion",
          to: "##{container_id} [data-i='#{i}']",
          detail: %{container_id: container_id, index: i, length: l}
        )
    }
  end

  defp js_attributes("content_container", "live_view_js", _container_id, _i, _) do
    %{
      style: "display: none;"
    }
  end

  defp js_attributes("icon", "live_view_js", _container_id, _, _) do
    %{}
  end
end
