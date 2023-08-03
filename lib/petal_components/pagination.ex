defmodule PetalComponents.Pagination do
  @moduledoc """
  Pagination is the method of splitting up content into discrete pages. It specifies the total number of pages and inidicates to a user the current page within the context of total pages.
  """
  use Phoenix.Component

  import PetalComponents.Helpers
  import PetalComponents.PaginationInternal

  alias PetalComponents.Link

  attr :path, :string, default: "/:page", doc: "page path"
  attr :class, :string, default: "", doc: "Parent div CSS class"

  attr :link_type, :string,
    default: "a",
    values: ["a", "live_patch", "live_redirect", "button"]

  attr :event, :boolean,
    default: false,
    doc:
      "whether to use `phx-click` events instead of linking. Enabling this will disable `link_type` and `path`."

  attr :total_pages, :integer, default: nil, doc: "sets a total page count"
  attr :current_page, :integer, default: nil, doc: "sets the current page"
  attr :sibling_count, :integer, default: 1, doc: "sets a sibling count"
  attr :boundary_count, :integer, default: 1, doc: "sets a boundary count"
  attr :rest, :global

  @doc """
  In the `path` param you can specify :page as the place your page number will appear.
  e.g "/posts/:page" => "/posts/1"
  """

  def pagination(assigns) do
    ~H"""
    <div {@rest} class={"#{@class} pc-pagination"}>
      <ul class="pc-pagination__inner">
        <%= for item <- get_pagination_items(@total_pages, @current_page, @sibling_count, @boundary_count) do %>
          <%= if item.type == "prev" and item.enabled? do %>
            <div>
              <Link.a
                phx-click={if @event, do: "goto-page"}
                phx-value-page={item.number}
                link_type={if @event, do: "button", else: @link_type}
                to={if not @event, do: get_path(@path, item.number, @current_page)}
                class="pc-pagination__item__previous"
              >
                <Heroicons.chevron_left solid class="pc-pagination__item__previous__chevron" />
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

          <%= if item.type == "next" and item.enabled? do %>
            <div>
              <Link.a
                phx-click={if @event, do: "goto-page"}
                phx-value-page={item.number}
                link_type={if @event, do: "button", else: @link_type}
                to={if not @event, do: get_path(@path, item.number, @current_page)}
                class="pc-pagination__item__next"
              >
                <Heroicons.chevron_right solid class="pc-pagination__item__next__chevron" />
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

    build_class([base_classes, active_classes, rounded_classes])
  end

  defp get_path(path, page_number, current_page) when is_binary(path) do
    get_path(&String.replace(path, ":page", Integer.to_string(&1)), page_number, current_page)
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
