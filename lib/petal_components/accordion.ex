defmodule PetalComponents.Accordion do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  import PetalComponents.Icon

  attr(:container_id, :string)
  attr(:class, :any, default: nil, doc: "CSS class for parent container")
  attr(:entries, :list, default: [%{}])

  attr(:js_lib, :string,
    default: PetalComponents.default_js_lib(),
    values: ["alpine_js", "live_view_js"],
    doc: "JavaScript library used for toggling"
  )

  attr(:open_index, :integer, default: nil, doc: "Index of item to be open at render")
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
      {js_attributes("container", @js_lib, @container_id, nil, nil, @open_index)}
    >
      <%= for {current_item, i} <- Enum.with_index(@item) do %>
        <% is_open = i == @open_index %>
        <div
          {js_attributes("item", @js_lib, @container_id, i, length(@item), is_open)}
          data-i={i}
          data-open={if is_open, do: "true", else: "false"}
        >
          <h2 id={content_panel_header_id(@container_id, i)}>
            <button
              type="button"
              {js_attributes("button", @js_lib, @container_id, i, length(@item), is_open)}
              class={[
                "pc-accordion-item accordion-button",
                if(i == 0, do: "pc-accordion-item--first"),
                unless(i == length(@item) - 1, do: "pc-accordion-item--all-except-last"),
                if(i == length(@item) - 1,
                  do:
                    "pc-accordion-item--last #{if @js_lib == "live_view_js" and !is_open, do: "pc-accordion-item--last--closed"}"
                )
              ]}
            >
              <span class="pc-accordion-item__heading">
                <%= current_item.heading %>
              </span>

              <.icon
                name="hero-chevron-down-solid"
                class={["pc-accordion-item__chevron", if(is_open, do: "rotate-180")]}
                {js_attributes("icon", @js_lib, @container_id, i, length(@item), is_open)}
              />
            </button>
          </h2>
          <div
            {js_attributes("content_container", @js_lib, @container_id, i, length(@item), is_open)}
            class="accordion-content-container"
          >
            <div class={[
              "pc-accordion-item__content-container",
              if(i == length(@item) - 1,
                do: "pc-accordion-item__content-container--last",
                else: "pc-accordion-item__content-container--not-last"
              )
            ]}>
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
          currentlyOpenAccordionItem.querySelector("span.hero-chevron-down-solid").classList.remove("rotate-180");
          currentlyOpenAccordionItem.querySelector(`.accordion-content-container`).style.display = "none";
          currentlyOpenAccordionItem.querySelector(`.accordion-button`).classList.remove("pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes");
          if(isLastAccordionItem){
            clickedAccordionItem.querySelector(`.accordion-button`).classList.add("pc-accordion-item--last--closed");
          }
        }

        // Open clicked accordion item (if not already open)
        if (!isClosingClickedAccordionItem) {
          clickedAccordionItem.dataset.open = true
          clickedAccordionItem.querySelector("span.hero-chevron-down-solid").classList.add("rotate-180");
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

  defp js_attributes(type, js_lib, container_id, i, l, open) do
    case {type, js_lib} do
      {"container", "alpine_js"} ->
        %{"x-data": "{ active: #{open || "null"} }"}

      {"item", "alpine_js"} ->
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

      {"button", "alpine_js"} when i == l - 1 ->
        %{
          "x-on:click": "expanded = !expanded",
          ":class":
            "expanded ? 'pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes' : 'pc-accordion-item--last--closed'",
          ":aria-expanded": "expanded",
          "aria-controls": content_panel_id(container_id, i)
        }

      {"button", "alpine_js"} ->
        %{
          "x-on:click": "expanded = !expanded",
          ":class":
            "expanded ? 'pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes' : ''",
          ":aria-expanded": "expanded",
          "aria-controls": content_panel_id(container_id, i)
        }

      {"content_container", "alpine_js"} ->
        %{
          id: content_panel_id(container_id, i),
          role: "region",
          "aria-labelledby": content_panel_header_id(container_id, i),
          "x-show": "expanded",
          "x-cloak": true,
          "x-collapse": true
        }

      {"icon", "alpine_js"} ->
        %{
          ":class": "{ 'rotate-180': expanded }"
        }

      {"container", "live_view_js"} ->
        %{}

      {"item", "live_view_js"} ->
        %{}

      {"button", "live_view_js"} ->
        %{
          "phx-click":
            JS.dispatch("click_accordion",
              to: "##{container_id} [data-i='#{i}']",
              detail: %{container_id: container_id, index: i, length: l}
            ),
          "aria-controls": content_panel_id(container_id, i),
          "aria-expanded": "#{open}"
        }

      {"content_container", "live_view_js"} ->
        %{
          id: content_panel_id(container_id, i),
          role: "region",
          "aria-labelledby": content_panel_header_id(container_id, i),
          style: if(open, do: "display: block;", else: "display: none;")
        }

      {"icon", "live_view_js"} ->
        %{
          class: if(open, do: "rotate-180", else: "")
        }

      _ ->
        %{}
    end
  end

  defp content_panel_header_id(container_id, idx) do
    "acc-header-#{container_id}-#{idx}"
  end

  defp content_panel_id(container_id, idx) do
    "acc-content-panel-#{container_id}-#{idx}"
  end
end
