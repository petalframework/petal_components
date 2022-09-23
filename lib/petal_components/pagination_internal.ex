defmodule PetalComponents.PaginationInternal do
  @doc """
  get_items computes the pagination button information based on
  - total number of pages,
  - current page,
  - sibling count (pages left and right of current page)
  - boundary count (pages at start, and at end of the page range)

  As this control receives user input, possibly from the internet
  a reasonable result is computed despite invalid input values and
  at least one page item is returned always.

  * The resulting items list always has 1 + max(0, sibling_count) + max(0, boundary_count) page items
  * The resulting items may/will contains ellipsis items only if boundary_count > 0
  * The previous item has `:enabled?` false if page 1 is current
  * The next item has `:enabled?` false if the last page is current

  please see the unit tests for examples
  """
  def get_pagination_items(total_pages, current_page, sibling_count, boundary_count) do
    total_pages = max(1, total_pages)
    current_page = max(1, min(current_page, total_pages))
    boundary_count = max(0, min(boundary_count, total_pages))
    sibling_count = max(0, sibling_count)

    siblings_size = 1 + 2 * sibling_count

    start_siblings =
      max(1, min(current_page - sibling_count, total_pages - siblings_size - boundary_count + 1))

    end_siblings =
      min(max(current_page + sibling_count, siblings_size + boundary_count), total_pages)

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
          [%{type: "page", number: page}, %{type: "..."}]

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
      type: "prev",
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
end
