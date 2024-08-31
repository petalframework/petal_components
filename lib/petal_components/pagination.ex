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

  attr :link_type, :string,
    default: "a",
    values: ["a", "live_patch", "live_redirect", "button"]

  attr :event, :boolean,
    default: false,
    doc:
      "whether to use `phx-click` events instead of linking. Enabling this will disable `link_type` and `path`."

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

  attr :rest, :global

  @doc """
  In the `path` param you can specify :page as the place your page number will appear.
  e.g "/posts/:page" => "/posts/1"
  """

  def pagination(assigns) do
    ~H"""
    <div {@rest} class={["pc-pagination", @class]}>
      <ul class="pc-pagination__inner">
        <%= for item <- get_pagination_items(@total_pages, @current_page, @sibling_count, @boundary_count) do %>
          <%= if item.type == "prev" and (item.enabled? or @show_boundary_chevrons) do %>
            <div>
              <Link.a
                phx-click={if @event, do: "goto-page"}
                phx-target={if @event, do: @target}
                phx-value-page={item.number}
                link_type={if @event, do: "button", else: @link_type}
                to={if not @event, do: get_path(@path, item.number, @current_page)}
                class="pc-pagination__item__previous"
                disabled={!item.enabled?}
              >
                <.icon name="hero-chevron-left-solid" class="pc-pagination__item__previous__chevron" />
              </Link.a>
            </div>
          <% end %>

          <%= if item.type == "page" do %>
            <li>
              <%= if item.current? do %>
                <span class={get_box_class(item)}><%= item.number %></span>
              <% else %>
                <Link.a
                  phx-click={if @event, do: "goto-page"}
                  phx-target={if @event, do: @target}
                  phx-value-page={item.number}
                  link_type={if @event, do: "button", else: @link_type}
                  to={if not @event, do: get_path(@path, item.number, @current_page)}
                  class={get_box_class(item)}
                >
                  <%= item.number %>
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
            <div>
              <Link.a
                phx-click={if @event, do: "goto-page"}
                phx-target={if @event, do: @target}
                phx-value-page={item.number}
                link_type={if @event, do: "button", else: @link_type}
                to={if not @event, do: get_path(@path, item.number, @current_page)}
                class="pc-pagination__item__next"
                disabled={!item.enabled?}
              >
                <.icon name="hero-chevron-right-solid" class="pc-pagination__item__next__chevron" />
              </Link.a>
            </div>
          <% end %>
        <% end %>
      </ul>
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
