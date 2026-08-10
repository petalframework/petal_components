defmodule PetalComponents.Pagination do
  @moduledoc """
  Pagination is the method of splitting up content into discrete pages. It specifies the total number of pages and inidicates to a user the current page within the context of total pages.
  """
  use Phoenix.Component

  import PetalComponents.PaginationInternal

  alias PetalComponents.Link
  import PetalComponents.Icon

  attr :path, :string, default: "/:page", doc: "page path"
  attr :class, :any, default: nil, doc: "parent div CSS class"

  attr :variant, :string,
    default: "numbered",
    values: ["numbered", "simple"],
    doc:
      "numbered renders the windowed page list; simple renders Previous/Next outline buttons only - fewer decisions on short lists, and the honest form when a total is unreliable"

  attr :previous_label, :string,
    default: "Previous",
    doc:
      "the previous button's label - visible in the simple variant, announced in the numbered one"

  attr :next_label, :string,
    default: "Next",
    doc: "the next button's label - visible in the simple variant, announced in the numbered one"

  attr :aria_label, :string,
    default: "Pagination",
    doc: "names the navigation landmark, localizable"

  attr :link_type, :string,
    default: "a",
    values: ["a", "live_patch", "live_redirect", "button"]

  attr :event, :any,
    default: false,
    doc: """
    use `phx-click` events instead of linking (disables `link_type` and
    `path`). `true` fires the classic "goto-page" event; a STRING fires
    that event name instead - how the data table routes page changes
    through its single on_change grammar.
    """

  attr :target, :any,
    default: nil,
    doc:
      "the LiveView/LiveComponent to send the event to. Example: `@myself`. Will be ignored if `event` is not enabled."

  attr :total_pages, :integer, default: nil, doc: "sets a total page count"
  attr :current_page, :integer, default: nil, doc: "sets the current page"
  attr :sibling_count, :integer, default: 1, doc: "sets a sibling count"
  attr :boundary_count, :integer, default: 1, doc: "sets a boundary count"

  attr :show_boundary_chevrons, :boolean,
    default: false,
    doc: "whether to show prev & next buttons at boundary pages"

  attr :event_values, :map,
    default: %{},
    doc: ~s|extra phx-value-* pairs sent with event-mode clicks, e.g. %{"op" => "page"}|

  attr :rest, :global

  @doc """
  In the `path` param you can specify :page as the place your page number will appear.
  e.g "/posts/:page" => "/posts/1"
  """

  def pagination(%{variant: "simple"} = assigns) do
    # Normalize like the numbered branch does via get_pagination_items:
    # nil/zero totals become one page, current clamps into range - so the
    # neighbour links can never point outside 1..total_pages.
    total_pages = max(assigns.total_pages || 1, 1)
    current_page = (assigns.current_page || 1) |> max(1) |> min(total_pages)

    assigns =
      assigns
      |> assign(:total_pages, total_pages)
      |> assign(:current_page, current_page)
      |> assign(:prev_enabled?, current_page > 1)
      |> assign(:next_enabled?, current_page < total_pages)
      |> assign(:event?, assigns.event not in [false, nil])

    ~H"""
    <div {@rest} class={["pc-pagination", @class]}>
      <nav class="pc-pagination__simple" aria-label="Pagination">
        <Link.a
          phx-click={event_name(@event)}
          {phx_values(@event_values)}
          phx-target={if @event?, do: @target}
          phx-value-page={@current_page - 1}
          link_type={if @event?, do: "button", else: @link_type}
          to={if not @event?, do: get_path(@path, "previous", @current_page)}
          type={if @event? or @link_type == "button", do: "button"}
          class="pc-pagination__simple-button"
          disabled={!@prev_enabled?}
        >
          <.icon name="hero-chevron-left-mini" class="pc-pagination__simple-chevron" />
          {@previous_label}
        </Link.a>

        <Link.a
          phx-click={event_name(@event)}
          {phx_values(@event_values)}
          phx-target={if @event?, do: @target}
          phx-value-page={@current_page + 1}
          link_type={if @event?, do: "button", else: @link_type}
          to={if not @event?, do: get_path(@path, "next", @current_page)}
          type={if @event? or @link_type == "button", do: "button"}
          class="pc-pagination__simple-button"
          disabled={!@next_enabled?}
        >
          {@next_label}
          <.icon name="hero-chevron-right-mini" class="pc-pagination__simple-chevron" />
        </Link.a>
      </nav>
    </div>
    """
  end

  def pagination(assigns) do
    assigns = assign(assigns, :event?, assigns.event not in [false, nil])

    ~H"""
    <div {@rest} class={["pc-pagination", @class]}>
      <nav aria-label={@aria_label}>
        <ul class="pc-pagination__inner">
          <%= for item <- get_pagination_items(@total_pages, @current_page, @sibling_count, @boundary_count) do %>
            <%= if item.type == "prev" and (item.enabled? or @show_boundary_chevrons) do %>
              <li>
                <Link.a
                  phx-click={event_name(@event)}
                  {phx_values(@event_values)}
                  phx-target={if @event?, do: @target}
                  phx-value-page={item.number}
                  link_type={if @event?, do: "button", else: @link_type}
                  to={if not @event?, do: get_path(@path, item.number, @current_page)}
                  class="pc-pagination__item__previous"
                  disabled={!item.enabled?}
                >
                  <.icon
                    name="hero-chevron-left-solid"
                    class="pc-pagination__item__previous__chevron"
                  />
                  <span class="sr-only">{@previous_label}</span>
                </Link.a>
              </li>
            <% end %>

            <%= if item.type == "page" do %>
              <li>
                <%= if item.current? do %>
                  <span class={get_box_class(item)} aria-current="page">{item.number}</span>
                <% else %>
                  <Link.a
                    phx-click={event_name(@event)}
                    {phx_values(@event_values)}
                    phx-target={if @event?, do: @target}
                    phx-value-page={item.number}
                    link_type={if @event?, do: "button", else: @link_type}
                    to={if not @event?, do: get_path(@path, item.number, @current_page)}
                    class={get_box_class(item)}
                  >
                    {item.number}
                  </Link.a>
                <% end %>
              </li>
            <% end %>

            <%= if item.type == "..." do %>
              <li>
                <span class="pc-pagination__item__ellipsis">
                  ...
                </span>
              </li>
            <% end %>

            <%= if item.type == "next" and (item.enabled? or @show_boundary_chevrons) do %>
              <li>
                <Link.a
                  phx-click={event_name(@event)}
                  {phx_values(@event_values)}
                  phx-target={if @event?, do: @target}
                  phx-value-page={item.number}
                  link_type={if @event?, do: "button", else: @link_type}
                  to={if not @event?, do: get_path(@path, item.number, @current_page)}
                  class="pc-pagination__item__next"
                  disabled={!item.enabled?}
                >
                  <.icon name="hero-chevron-right-solid" class="pc-pagination__item__next__chevron" />
                  <span class="sr-only">{@next_label}</span>
                </Link.a>
              </li>
            <% end %>
          <% end %>
        </ul>
      </nav>
    </div>
    """
  end

  defp get_box_class(item) do
    base_classes = "pc-pagination__item"

    active_classes =
      if item.current?,
        do: "pc-pagination__item--is-current",
        else: "pc-pagination__item--is-not-current"

    rounded_classes =
      case item do
        %{first?: true, last?: true} ->
          "pc-pagination__item--with-single-box"

        %{first?: true, last?: false} ->
          "pc-pagination__item--with-multiple-boxes--left"

        %{first?: false, last?: true} ->
          "pc-pagination__item--with-multiple-boxes--right"

        _ ->
          "pc-pagination__item--rounded-catch-all"
      end

    [base_classes, active_classes, rounded_classes]
  end

  defp event_name(event) when is_binary(event), do: event
  defp event_name(event) when event in [false, nil], do: nil
  defp event_name(_event), do: "goto-page"

  defp phx_values(values) when values == %{}, do: []

  # event_values keys are developer-authored component API (a handful of
  # op names), never user input - the atom creation here is bounded
  defp phx_values(values), do: Enum.map(values, fn {k, v} -> {:"phx-value-#{k}", v} end)

  defp get_path(path, page_number, current_page) when is_binary(path) do
    # replace on `%3Apage` or `:page` in case we receive an URI encoded path
    fun = &String.replace(path, ~r/%3Apage|:page/, Integer.to_string(&1))
    get_path(fun, page_number, current_page)
  end

  defp get_path(fun, "previous", current_page) when is_function(fun, 1) do
    get_path(fun, current_page - 1, current_page)
  end

  defp get_path(fun, "next", current_page) when is_function(fun, 1) do
    get_path(fun, current_page + 1, current_page)
  end

  defp get_path(fun, page_number, _current_page) when is_function(fun, 1) do
    then(page_number, fun)
  end
end
