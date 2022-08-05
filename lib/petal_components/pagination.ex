defmodule PetalComponents.Pagination do
  use Phoenix.Component

  alias PetalComponents.Heroicons
  alias PetalComponents.Link

  import PetalComponents.Helpers

  # prop path, :string
  # prop class, :string
  # prop sibling_count, :integer
  # prop boundary_count, :integer
  # prop link_type, :string, options: ["a", "live_patch", "live_redirect"]

  @doc """
  In the `path` param you can specify :page as the place your page number will appear.
  e.g "/posts/:page" => "/posts/1"
  """

  def pagination(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:link_type, fn -> "a" end)
      |> assign_new(:sibling_count, fn -> 1 end)
      |> assign_new(:boundary_count, fn -> 1 end)
      |> assign_new(:path, fn -> "/:page" end)
      |> assign_rest(
        ~w(link_type sibling_count boundary_count total_pages current_page path class)a
      )

    ~H"""
    <div {@rest} class={"#{@class} flex"}>
      <ul class="inline-flex -space-x-px text-sm font-medium">
        <%= for item <- get_items(@total_pages, @current_page, @sibling_count, @boundary_count) do %>
          <%= if item.type == "previous" and item.enabled? do %>
            <div>
              <Link.link link_type={@link_type} to={get_path(@path, item.number, @current_page)} class="mr-2 inline-flex items-center justify-center rounded leading-5 px-2.5 py-2 bg-white hover:bg-gray-50 dark:bg-gray-900 dark:hover:bg-gray-800 border dark:border-gray-700 border-gray-200 text-gray-600 hover:text-gray-800">
                <Heroicons.Solid.chevron_left class="w-5 h-5 text-gray-600 dark:text-gray-400" />
              </Link.link>
            </div>
          <% end %>

          <%= if item.type == "page" do %>
            <li>
              <%= if item.current? do %>
                <span class={get_box_class(item)}><%= item.number %></span>
              <% else %>
                <Link.link link_type={@link_type} to={get_path(@path, item.number, @current_page)} class={get_box_class(item)}>
                  <%= item.number %>
                </Link.link>
              <% end %>
            </li>
          <% end %>

          <%= if item.type == "ellipsis" do %>
            <li>
              <span class="inline-flex items-center justify-center leading-5 px-3.5 py-2 bg-white border dark:bg-gray-900 dark:border-gray-700 border-gray-200 text-gray-400">...</span>
            </li>
          <% end %>

          <%= if item.type == "next" and item.enabled? do %>
            <div>
              <Link.link link_type={@link_type} to={get_path(@path, item.number, @current_page)} class="ml-2 inline-flex items-center justify-center rounded leading-5 px-2.5 py-2 bg-white hover:bg-gray-50 dark:bg-gray-900 dark:hover:bg-gray-800 dark:border-gray-700 border border-gray-200 text-gray-600 hover:text-gray-800">
                <Heroicons.Solid.chevron_right class="w-5 h-5 text-gray-600 dark:text-gray-400" />
              </Link.link>
            </div>
          <% end %>
        <% end %>
      </ul>
    </div>
    """
  end

  defp get_items(total_pages, current_page, sibling_count, boundary_count) do
    total_pages = max(1, total_pages)
    current_page = max(1, min(current_page, total_pages))
    boundary_count = max(0, min(boundary_count, total_pages))
    sibling_count = max(0, sibling_count)

    siblings_size = 1 + 2 * sibling_count
    start_siblings = max(1, min(current_page - sibling_count, total_pages - siblings_size - boundary_count + 1))
    end_siblings = min(max(current_page + sibling_count, siblings_size + boundary_count), total_pages)

    boundary_start =
      if boundary_count > 0 do
        1..min(boundary_count, start_siblings) |> Enum.to_list()
      else
        [start_siblings]
      end

    siblings = start_siblings..end_siblings |> Enum.to_list()

    boundary_end =
      if boundary_count > 0 do
        max(total_pages - boundary_count + 1, end_siblings)..total_pages |> Enum.to_list()
      else
        [end_siblings]
      end

    pages =
      Enum.concat([boundary_start, siblings, boundary_end])
      |> Enum.sort()
      |> Enum.dedup()
      |> Enum.to_list()

    first_page = List.first(pages)
    last_page = List.last(pages)

    pages_next =
      Enum.drop(pages, 1)
      |> Enum.concat([List.last(pages) + 1])
      |> Enum.to_list()

    Enum.zip(pages, pages_next)
    |> Enum.flat_map(fn t ->
      case t do
        {page, next} when next - page == 1 ->
          [%{type: "page", number: page}]

        {page, next} when next - page > 1 ->
          [%{type: "page", number: page}, %{type: "ellipsis"}]

        _ ->
          []
      end
    end)
    |> Enum.map(fn item ->
      case item do
        %{type: "page"} ->
          item
          |> Map.put(:first?, item.number == first_page)
          |> Map.put(:current?, item.number == current_page)
          |> Map.put(:last?, item.number == last_page)

        _ ->
          item
      end
    end)
    |> Enum.flat_map(fn item ->
      case item do
        %{first?: true, current?: true, last?: true} when total_pages > 1 ->
          [
            get_prev_item(current_page, total_pages),
            item,
            get_next_item(current_page, total_pages)
          ]

        %{first?: true, last?: false} when total_pages > 1 ->
          [
            get_prev_item(current_page, total_pages),
            item
          ]

        %{first?: false, last?: true} when total_pages > 1 ->
          [
            item,
            get_next_item(current_page, total_pages)
          ]

        _ ->
          [item]
      end
    end)
  end

  defp get_prev_item(current_page, _total_pages) do
    %{
      type: "previous",
      number: max(1, current_page - 1),
      enabled?: current_page > 1
    }
  end

  defp get_next_item(current_page, total_pages) do
    %{
      type: "next",
      number: min(current_page + 1, total_pages),
      enabled?: current_page < total_pages
    }
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

  defp get_path(path, "previous", current_page) do
    String.replace(path, ":page", Integer.to_string(current_page - 1))
  end

  defp get_path(path, "next", current_page) do
    String.replace(path, ":page", Integer.to_string(current_page + 1))
  end

  defp get_path(path, page_number, _current_page) do
    String.replace(path, ":page", Integer.to_string(page_number))
  end
end
