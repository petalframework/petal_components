defmodule PetalComponents.Accordion do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  import PetalComponents.Icon

  attr(:container_id, :string)
  attr(:class, :any, default: nil, doc: "CSS class for parent container")
  attr(:entries, :list, default: [%{}])
  attr(:variant, :string, default: "default", values: ["default", "ghost"])

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
      class={[
        @class,
        if(@variant == "ghost", do: "pc-accordion--ghost")
      ]}
      {@rest}
      {js_attributes("container", @js_lib, @container_id, nil, nil, @open_index, @variant)}
    >
      <%= for {current_item, i} <- Enum.with_index(@item) do %>
        <% is_open = i == @open_index %>
        <div
          {js_attributes("item", @js_lib, @container_id, i, length(@item), is_open, @variant)}
          data-i={i}
          data-open={if is_open, do: "true", else: "false"}
          class={if(@variant == "ghost", do: "pc-accordion-item--ghost")}
        >
          <h2 id={content_panel_header_id(@container_id, i)}>
            <button
              type="button"
              {js_attributes("button", @js_lib, @container_id, i, length(@item), is_open, @variant)}
              class={
                if @variant == "ghost" do
                  "pc-accordion-item__button--ghost"
                else
                  [
                    "pc-accordion-item accordion-button",
                    if(i == 0, do: "pc-accordion-item--first"),
                    unless(i == length(@item) - 1, do: "pc-accordion-item--all-except-last"),
                    if(i == length(@item) - 1,
                      do:
                        "pc-accordion-item--last #{if @js_lib == "live_view_js" and !is_open, do: "pc-accordion-item--last--closed"}"
                    )
                  ]
                end
              }
            >
              <span class={
                if(@variant == "ghost",
                  do: "pc-accordion-item__heading--ghost",
                  else: "pc-accordion-item__heading"
                )
              }>
                <%= current_item.heading %>
              </span>

              <%= if @variant == "ghost" do %>
                <span class="pc-accordion-item__icon-container--ghost">
                  <.icon
                    name="hero-plus-mini"
                    class="pc-accordion-item__plus"
                    x-cloak={@js_lib == "alpine_js"}
                    data-js-loading={@js_lib == "live_view_js"}
                    {js_attributes("icon", @js_lib, @container_id, i, length(@item), is_open, @variant)}
                  />
                  <.icon
                    name="hero-minus-mini"
                    class="pc-accordion-item__minus"
                    x-cloak={@js_lib == "alpine_js"}
                    data-js-loading={@js_lib == "live_view_js"}
                    {js_attributes("icon_minus", @js_lib, @container_id, i, length(@item), is_open, @variant)}
                  />
                </span>
              <% else %>
                <.icon
                  name="hero-chevron-down-solid"
                  class={["pc-accordion-item__chevron", if(is_open, do: "rotate-180")]}
                  {js_attributes("icon", @js_lib, @container_id, i, length(@item), is_open, @variant)}
                />
              <% end %>
            </button>
          </h2>
          <div
            {js_attributes("content_container", @js_lib, @container_id, i, length(@item), is_open, @variant)}
            class="accordion-content-container"
          >
            <div class={
              if(@variant == "ghost",
                do: "pc-accordion-item__content--ghost",
                else: [
                  "pc-accordion-item__content-container",
                  if(i == length(@item) - 1,
                    do: "pc-accordion-item__content-container--last",
                    else: "pc-accordion-item__content-container--not-last"
                  )
                ]
              )
            }>
              <%= render_slot(current_item, current_item.entry) %>
            </div>
          </div>
        </div>
      <% end %>
    </div>

    <script>
      window.addEventListener("DOMContentLoaded", () => {
      document.querySelectorAll('[data-js-loading]').forEach(el => {
      el.removeAttribute('data-js-loading');
      });
      });
        window.addEventListener("click_accordion", e => {
        let i = e.detail.index;
        let l = e.detail.length
        let clickedAccordionItem = e.target;
        let currentlyOpenAccordionItem = document.querySelector("[data-open='true']")
        let isClosingClickedAccordionItem = !!currentlyOpenAccordionItem && currentlyOpenAccordionItem == clickedAccordionItem;
        let isLastAccordionItem = i == l - 1;
        let isGhostVariant = clickedAccordionItem.closest("[id^='accordion_']").classList.contains("pc-accordion--ghost");

        // Close open accordion item
        if(currentlyOpenAccordionItem) {
          currentlyOpenAccordionItem.dataset.open = false;
          if (isGhostVariant) {
            let plusIcon = currentlyOpenAccordionItem.querySelector(".pc-accordion-item__plus");
            let minusIcon = currentlyOpenAccordionItem.querySelector(".pc-accordion-item__minus");
            if (plusIcon && minusIcon) {
              plusIcon.classList.remove("hidden");
              minusIcon.classList.add("hidden");
            }
          } else {
            currentlyOpenAccordionItem.querySelector("span.hero-chevron-down-solid").classList.remove("rotate-180");
            currentlyOpenAccordionItem.querySelector(`.accordion-button`).classList.remove("pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes");
            if(isLastAccordionItem){
              clickedAccordionItem.querySelector(`.accordion-button`).classList.add("pc-accordion-item--last--closed");
            }
          }
          currentlyOpenAccordionItem.querySelector(`.accordion-content-container`).style.display = "none";
        }

        // Open clicked accordion item (if not already open)
        if (!isClosingClickedAccordionItem) {
          clickedAccordionItem.dataset.open = true;
          if (isGhostVariant) {
            let plusIcon = clickedAccordionItem.querySelector(".pc-accordion-item__plus");
            let minusIcon = clickedAccordionItem.querySelector(".pc-accordion-item__minus");
            if (plusIcon && minusIcon) {
              plusIcon.classList.add("hidden");
              minusIcon.classList.remove("hidden");
            }
          } else {
            clickedAccordionItem.querySelector("span.hero-chevron-down-solid").classList.add("rotate-180");
            clickedAccordionItem.querySelector(`.accordion-button`).classList.add("pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes");
            if(isLastAccordionItem){
              clickedAccordionItem.querySelector(`.accordion-button`).classList.remove("pc-accordion-item--last--closed");
            }
          }
          clickedAccordionItem.querySelector(`.accordion-content-container`).style.display = "block";
        }
        })
    </script>
    """
  end

  defp js_attributes(type, js_lib, container_id, i, l, open, variant) do
    case {type, js_lib} do
      {"container", "alpine_js"} ->
        %{"x-data": "{ active: #{open || "null"}, isGhost: #{variant == "ghost"} }"}

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
        if variant == "ghost" do
          %{
            "x-on:click": "expanded = !expanded",
            ":aria-expanded": "expanded",
            "aria-controls": content_panel_id(container_id, i)
          }
        else
          %{
            "x-on:click": "expanded = !expanded",
            ":class":
              "expanded ? 'pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes' : 'pc-accordion-item--last--closed'",
            ":aria-expanded": "expanded",
            "aria-controls": content_panel_id(container_id, i)
          }
        end

      {"button", "alpine_js"} ->
        if variant == "ghost" do
          %{
            "x-on:click": "expanded = !expanded",
            ":aria-expanded": "expanded",
            "aria-controls": content_panel_id(container_id, i)
          }
        else
          %{
            "x-on:click": "expanded = !expanded",
            ":class":
              "expanded ? 'pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes' : ''",
            ":aria-expanded": "expanded",
            "aria-controls": content_panel_id(container_id, i)
          }
        end

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
        if variant == "ghost" do
          %{
            "x-show": "!expanded"
          }
        else
          %{
            ":class": "{ 'rotate-180': expanded }"
          }
        end

      {"icon_minus", "alpine_js"} ->
        %{
          "x-show": "expanded"
        }

      {"container", "live_view_js"} ->
        %{}

      {"item", "live_view_js"} ->
        %{}

      {"button", "live_view_js"} ->
        if variant == "ghost" do
          %{
            "phx-click":
              JS.dispatch("click_accordion",
                to: "##{container_id} [data-i='#{i}']",
                detail: %{container_id: container_id, index: i, length: l, variant: "ghost"}
              ),
            "aria-controls": content_panel_id(container_id, i),
            "aria-expanded": "#{open}"
          }
        else
          %{
            "phx-click":
              JS.dispatch("click_accordion",
                to: "##{container_id} [data-i='#{i}']",
                detail: %{container_id: container_id, index: i, length: l}
              ),
            "aria-controls": content_panel_id(container_id, i),
            "aria-expanded": "#{open}"
          }
        end

      {"content_container", "live_view_js"} ->
        %{
          id: content_panel_id(container_id, i),
          role: "region",
          "aria-labelledby": content_panel_header_id(container_id, i),
          style: if(open, do: "display: block;", else: "display: none;")
        }

      {"icon", "live_view_js"} ->
        if variant == "ghost" do
          %{
            class: if(open, do: "hidden")
          }
        else
          %{
            class: if(open, do: "rotate-180")
          }
        end

      {"icon_minus", "live_view_js"} ->
        %{
          class: if(open, do: "", else: "hidden")
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
