defmodule PetalComponents.Pagination do
  use Phoenix.Component

  alias PetalComponents.Link

  import PetalComponents.Helpers
  import PetalComponents.PaginationInternal

  attr(:path, :string, default: "/:page", doc: "page path")
  attr(:class, :string, default: "", doc: "Parent div CSS class")

  attr(:link_type, :string,
    default: "a",
    values: ["a", "live_patch", "live_redirect"]
  )

  attr(:total_pages, :integer, default: nil, doc: "sets a total page count")
  attr(:current_page, :integer, default: nil, doc: "sets the current page")
  attr(:sibling_count, :integer, default: 1, doc: "sets a sibling count")
  attr(:boundary_count, :integer, default: 1, doc: "sets a boundary count")
  attr(:rest, :global)

  @doc """
  In the `path` param you can specify :page as the place your page number will appear.
  e.g "/posts/:page" => "/posts/1"
  """

  def pagination(assigns) do
    ~H"""
    <div {@rest} class={"#{@class} flex"}>
      <ul class="inline-flex -space-x-px text-sm font-medium">
        <%= for item <- get_pagination_items(@total_pages, @current_page, @sibling_count, @boundary_count) do %>
          <%= if item.type == "prev" and item.enabled? do %>
            <div>
              <Link.a link_type={@link_type} to={get_path(@path, item.number, @current_page)} class="mr-2 inline-flex items-center justify-center rounded leading-5 px-2.5 py-2 bg-white hover:bg-gray-50 dark:bg-gray-900 dark:hover:bg-gray-800 border dark:border-gray-700 border-gray-200 text-gray-600 hover:text-gray-800">
                <Heroicons.chevron_left solid class="w-5 h-5 text-gray-600 dark:text-gray-400" />
              </Link.a>
            </div>
          <% end %>

          <%= if item.type == "page" do %>
            <li>
              <%= if item.current? do %>
                <span class={get_box_class(item)}><%= item.number %></span>
              <% else %>
                <Link.a link_type={@link_type} to={get_path(@path, item.number, @current_page)} class={get_box_class(item)}>
                  <%= item.number %>
                </Link.a>
              <% end %>
            </li>
          <% end %>

          <%= if item.type == "..." do %>
            <li>
              <span class="inline-flex items-center justify-center leading-5 px-3.5 py-2 bg-white border dark:bg-gray-900 dark:border-gray-700 border-gray-200 text-gray-400">...</span>
            </li>
          <% end %>

          <%= if item.type == "next" and item.enabled? do %>
            <div>
              <Link.a link_type={@link_type} to={get_path(@path, item.number, @current_page)} class="ml-2 inline-flex items-center justify-center rounded leading-5 px-2.5 py-2 bg-white hover:bg-gray-50 dark:bg-gray-900 dark:hover:bg-gray-800 dark:border-gray-700 border border-gray-200 text-gray-600 hover:text-gray-800">
                <Heroicons.chevron_right solid class="w-5 h-5 text-gray-600 dark:text-gray-400" />
              </Link.a>
            </div>
          <% end %>
        <% end %>
      </ul>
    </div>
    """
  end

  defp get_box_class(item) do
    base_classes =
      "inline-flex items-center justify-center leading-5 px-3.5 py-2 border border-gray-200 dark:border-gray-700"

    active_classes =
      if item.current?,
        do: "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-300",
        else:
          "bg-white text-gray-600 hover:bg-gray-50 hover:text-gray-800 dark:bg-gray-900 dark:text-gray-400 dark:hover:bg-gray-800 dark:hover:text-gray-400"

    rounded_classes =
      case item do
        %{first?: true, last?: true} ->
          "rounded"

        %{first?: true, last?: false} ->
          "rounded-l "

        %{first?: false, last?: true} ->
          "rounded-r"

        _ ->
          ""
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
