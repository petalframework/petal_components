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

  attr(:multiple, :boolean,
    default: false,
    doc: "When true, multiple sections can be expanded simultaneously"
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
      class={[
        @class,
        if(@variant == "ghost", do: "pc-accordion--ghost")
      ]}
      {@rest}
      {js_attributes("container", @js_lib, @container_id, nil, nil, @open_index, @variant, @multiple)}
    >
      <%= for {current_item, i} <- Enum.with_index(@item) do %>
        <% is_open = i == @open_index %>
        <div
          {js_attributes("item", @js_lib, @container_id, i, length(@item), is_open, @variant, @multiple)}
          data-i={i}
          data-open={if is_open, do: "true", else: "false"}
          class={if(@variant == "ghost", do: "pc-accordion-item--ghost")}
        >
          <h2 id={content_panel_header_id(@container_id, i)}>
            <button
              type="button"
              {js_attributes("button", @js_lib, @container_id, i, length(@item), is_open, @variant, @multiple)}
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
                {current_item.heading}
              </span>

              <%= if @variant == "ghost" do %>
                <span class="pc-accordion-item__icon-container--ghost">
                  <.icon
                    name="hero-plus-mini"
                    class="pc-accordion-item__plus"
                    x-cloak={@js_lib == "alpine_js"}
                    data-js-loading={@js_lib == "live_view_js"}
                    {js_attributes("icon", @js_lib, @container_id, i, length(@item), is_open, @variant, @multiple)}
                  />
                  <.icon
                    name="hero-minus-mini"
                    class="pc-accordion-item__minus"
                    x-cloak={@js_lib == "alpine_js"}
                    data-js-loading={@js_lib == "live_view_js"}
                    {js_attributes("icon_minus", @js_lib, @container_id, i, length(@item), is_open, @variant, @multiple)}
                  />
                </span>
              <% else %>
                <.icon
                  name="hero-chevron-down-solid"
                  class={["pc-accordion-item__chevron", if(is_open, do: "rotate-180")]}
                  {js_attributes("icon", @js_lib, @container_id, i, length(@item), is_open, @variant, @multiple)}
                />
              <% end %>
            </button>
          </h2>
          <div
            {js_attributes("content_container", @js_lib, @container_id, i, length(@item), is_open, @variant, @multiple)}
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
              {render_slot(current_item, current_item.entry)}
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
        let l = e.detail.length;
        let isMultiple = !!e.detail.multiple;
        let clickedAccordionItem = e.target;
        let container = clickedAccordionItem.closest("[id^='accordion_']");
        let currentlyOpenAccordionItem = container.querySelector("[data-open='true']");
        let isClosingClickedAccordionItem = clickedAccordionItem.dataset.open === "true";
        let isLastAccordionItem = i == l - 1;
        let isGhostVariant = container.classList.contains("pc-accordion--ghost");

        function closeItem(item) {
          item.dataset.open = "false";
          if (isGhostVariant) {
            let plusIcon = item.querySelector(".pc-accordion-item__plus");
            let minusIcon = item.querySelector(".pc-accordion-item__minus");
            if (plusIcon && minusIcon) {
              plusIcon.classList.remove("hidden");
              minusIcon.classList.add("hidden");
            }
          } else {
            let chevron = item.querySelector("span.hero-chevron-down-solid");
            if (chevron) chevron.classList.remove("rotate-180");
            let btn = item.querySelector(".accordion-button");
            if (btn) btn.classList.remove("pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes");
            if (isLastAccordionItem && item === clickedAccordionItem) {
              let btn2 = item.querySelector(".accordion-button");
              if (btn2) btn2.classList.add("pc-accordion-item--last--closed");
            }
          }
          item.querySelector(".accordion-content-container").style.display = "none";
        }

        function openItem(item) {
          item.dataset.open = "true";
          if (isGhostVariant) {
            let plusIcon = item.querySelector(".pc-accordion-item__plus");
            let minusIcon = item.querySelector(".pc-accordion-item__minus");
            if (plusIcon && minusIcon) {
              plusIcon.classList.add("hidden");
              minusIcon.classList.remove("hidden");
            }
          } else {
            let chevron = item.querySelector("span.hero-chevron-down-solid");
            if (chevron) chevron.classList.add("rotate-180");
            let btn = item.querySelector(".accordion-button");
            if (btn) btn.classList.add("pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes");
            if (isLastAccordionItem) {
              let btn2 = item.querySelector(".accordion-button");
              if (btn2) btn2.classList.remove("pc-accordion-item--last--closed");
            }
          }
          item.querySelector(".accordion-content-container").style.display = "block";
        }

        // In single mode, close the currently open item (if different from clicked)
        if (!isMultiple && currentlyOpenAccordionItem && currentlyOpenAccordionItem !== clickedAccordionItem) {
          closeItem(currentlyOpenAccordionItem);
        }

        // Toggle clicked item
        if (isClosingClickedAccordionItem) {
          closeItem(clickedAccordionItem);
        } else {
          // In single mode, also close the currently open item if it's the same
          if (!isMultiple && currentlyOpenAccordionItem === clickedAccordionItem) {
            closeItem(clickedAccordionItem);
          }
          openItem(clickedAccordionItem);
        }
        })
    </script>
    """
  end

  defp js_attributes(type, js_lib, container_id, i, l, open, variant, multiple) do
    case {type, js_lib} do
      {"container", "alpine_js"} ->
        init_value =
          if multiple do
            if open, do: "[#{open}]", else: "[]"
          else
            "#{open || "null"}"
          end

        %{"x-data": "{ active: #{init_value} }"}

      {"item", "alpine_js"} ->
        %{}

      {"button", "alpine_js"} ->
        click_expr = alpine_click_expr(i, multiple)
        expanded_expr = alpine_expanded_expr(i, multiple)

        base = %{
          "x-on:click": click_expr,
          ":aria-expanded": expanded_expr,
          "aria-controls": content_panel_id(container_id, i)
        }

        if variant == "ghost" do
          base
        else
          class_expr =
            if i == l - 1 do
              "#{expanded_expr} ? 'pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes' : 'pc-accordion-item--last--closed'"
            else
              "#{expanded_expr} ? 'pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes' : ''"
            end

          Map.put(base, ":class", class_expr)
        end

      {"content_container", "alpine_js"} ->
        %{
          id: content_panel_id(container_id, i),
          role: "region",
          "aria-labelledby": content_panel_header_id(container_id, i),
          "x-show": alpine_expanded_expr(i, multiple),
          "x-cloak": true,
          style: if(open, do: "", else: "display: none;")
        }

      {"icon", "alpine_js"} ->
        expanded = alpine_expanded_expr(i, multiple)

        if variant == "ghost" do
          %{"x-show": "!(#{expanded})"}
        else
          %{":class": "{ 'rotate-180': #{expanded} }"}
        end

      {"icon_minus", "alpine_js"} ->
        %{"x-show": alpine_expanded_expr(i, multiple)}

      {"container", "live_view_js"} ->
        %{"phx-update": "ignore"}

      {"item", "live_view_js"} ->
        %{}

      {"button", "live_view_js"} ->
        detail =
          %{container_id: container_id, index: i, length: l}
          |> then(fn d -> if variant == "ghost", do: Map.put(d, :variant, "ghost"), else: d end)
          |> then(fn d -> if multiple, do: Map.put(d, :multiple, true), else: d end)

        %{
          "phx-click":
            JS.dispatch("click_accordion",
              to: "##{container_id} [data-i='#{i}']",
              detail: detail
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
        if variant == "ghost" do
          %{class: if(open, do: "hidden")}
        else
          %{class: if(open, do: "rotate-180")}
        end

      {"icon_minus", "live_view_js"} ->
        %{class: if(open, do: "", else: "hidden")}

      _ ->
        %{}
    end
  end

  defp alpine_click_expr(i, true = _multiple) do
    "active.includes(#{i}) ? active = active.filter(x => x !== #{i}) : active = [...active, #{i}]"
  end

  defp alpine_click_expr(i, _multiple) do
    "active = active === #{i} ? null : #{i}"
  end

  defp alpine_expanded_expr(i, true = _multiple), do: "active.includes(#{i})"
  defp alpine_expanded_expr(i, _multiple), do: "active === #{i}"

  defp content_panel_header_id(container_id, idx) do
    "acc-header-#{container_id}-#{idx}"
  end

  defp content_panel_id(container_id, idx) do
    "acc-content-panel-#{container_id}-#{idx}"
  end
end
