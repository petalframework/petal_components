defmodule PetalComponents.PaginationTest do
  use ComponentCase
  import PetalComponents.Pagination
  import PetalComponents.PaginationInternal

  test "pager for negative number of pages, current page, siblings and boundary" <>
         " shows only the first (supposedly empty) page, no prev or next" do
    items = get_pagination_items(-1, -1, -1, -1)
    assert [%{type: "page", number: 1}] = items
  end

  test "pager for zero number of pages, current page, siblings and boundary" <>
         " shows only a single page, no prev or next" do
    items = get_pagination_items(0, 0, 0, 0)
    assert [%{type: "page", number: 1}] = items
  end

  test "pager for 2 pages, current page 1, siblings and boundary at zero" <>
         " shows only a single page and next, no prev" do
    items = get_pagination_items(2, 1, 0, 0)

    assert [
             %{type: "prev", number: 1, enabled?: false},
             %{type: "page", number: 1, current?: true},
             %{type: "next", number: 2, enabled?: true}
           ] = items
  end

  test "pager for 2 pages, current page 2, siblings and boundary at zero" <>
         " shows: only a single page and prev, no next" do
    items = get_pagination_items(2, 2, 0, 0)

    assert [
             %{type: "prev", number: 1, enabled?: true},
             %{type: "page", number: 2, current?: true},
             %{type: "next", number: 2, enabled?: false}
           ] = items
  end

  test "pager for 5 pages, current page 2, 0 siblings and boundary" <>
         " shows: prev, [2], next" do
    items = get_pagination_items(5, 2, 0, 0)

    assert [
             %{type: "prev", number: 1, enabled?: true},
             %{type: "page", number: 2, current?: true},
             %{type: "next", number: 3, enabled?: true}
           ] = items
  end

  test "pager for 5 pages, current page 1, 0 siblings and 1 boundary" <>
         " shows: [1], 2, ..., 5, next" do
    items = get_pagination_items(5, 1, 0, 1)

    assert [
             %{type: "prev", number: 1, enabled?: false},
             %{type: "page", number: 1, current?: true},
             %{type: "page", number: 2, current?: false},
             %{type: "..."},
             %{type: "page", number: 5, current?: false},
             %{type: "next", number: 2, enabled?: true}
           ] = items
  end

  test "pager for 5 pages, current page 2, 0 siblings and 1 boundary" <>
         " shows: prev, 1, [2], ..., 5, next" do
    items = get_pagination_items(5, 2, 0, 1)

    assert [
             %{type: "prev", number: 1, enabled?: true},
             %{type: "page", number: 1, current?: false},
             %{type: "page", number: 2, current?: true},
             %{type: "..."},
             %{type: "page", number: 5, current?: false},
             %{type: "next", number: 3, enabled?: true}
           ] = items
  end

  test "pager for 5 pages, current page 3, 0 siblings and 1 boundary" <>
         " shows: prev, 1, ,..., [3], ..., 5, next" do
    items = get_pagination_items(5, 3, 0, 1)

    assert [
             %{type: "prev", number: 2, enabled?: true},
             %{type: "page", number: 1, current?: false},
             %{type: "..."},
             %{type: "page", number: 3, current?: true},
             %{type: "..."},
             %{type: "page", number: 5, current?: false},
             %{type: "next", number: 4, enabled?: true}
           ] = items
  end

  test "pager for 5 pages, current page 4, 0 siblings and 1 boundary" <>
         " shows: prev, 1,... , [4], 5, next" do
    items = get_pagination_items(5, 4, 0, 1)

    assert [
             %{type: "prev", number: 3, enabled?: true},
             %{type: "page", number: 1, current?: false},
             %{type: "..."},
             %{type: "page", number: 4, current?: true},
             %{type: "page", number: 5, current?: false},
             %{type: "next", number: 5, enabled?: true}
           ] = items
  end

  test "pager for 5 pages, current page 5, 0 siblings and 1 boundary" <>
         " shows: prev, 1,... , 4, [5]" do
    items = get_pagination_items(5, 5, 0, 1)

    assert [
             %{type: "prev", number: 4, enabled?: true},
             %{type: "page", number: 1, current?: false},
             %{type: "..."},
             %{type: "page", number: 4, current?: false},
             %{type: "page", number: 5, current?: true},
             %{type: "next", number: 5, enabled?: false}
           ] = items
  end

  test "pager for 5 pages, current page 1, 1 sibling and 0 boundary" <>
         " shows: [1], 2, 3, next" do
    items = get_pagination_items(5, 1, 1, 0)

    assert [
             %{type: "prev", number: 1, enabled?: false},
             %{type: "page", number: 1, current?: true},
             %{type: "page", number: 2, current?: false},
             %{type: "page", number: 3, current?: false},
             %{type: "next", number: 2, enabled?: true}
           ] = items
  end

  test "pager for 5 pages, current page 2, 1 sibling and 0 boundary" <>
         " shows: prev, 1, [2], 3, next" do
    items = get_pagination_items(5, 2, 1, 0)

    assert [
             %{type: "prev", number: 1, enabled?: true},
             %{type: "page", number: 1, current?: false},
             %{type: "page", number: 2, current?: true},
             %{type: "page", number: 3, current?: false},
             %{type: "next", number: 3, enabled?: true}
           ] = items
  end

  test "pager for 5 pages, current page 3, 1 sibling and 0 boundary" <>
         " shows: prev, 2, [3], 4, next" do
    items = get_pagination_items(5, 3, 1, 0)

    assert [
             %{type: "prev", number: 2, enabled?: true},
             %{type: "page", number: 2, current?: false},
             %{type: "page", number: 3, current?: true},
             %{type: "page", number: 4, current?: false},
             %{type: "next", number: 4, enabled?: true}
           ] = items
  end

  test "pager for 5 pages, current page 4, 1 sibling and 0 boundary" <>
         " shows: prev, 3, [4], 5, next" do
    items = get_pagination_items(5, 4, 1, 0)

    assert [
             %{type: "prev", number: 3, enabled?: true},
             %{type: "page", number: 3, current?: false},
             %{type: "page", number: 4, current?: true},
             %{type: "page", number: 5, current?: false},
             %{type: "next", number: 5, enabled?: true}
           ] = items
  end

  test "pager for 5 pages, current page 5, 1 sibling and 0 boundary" <>
         " shows: prev, 3, 4, [5]" do
    items = get_pagination_items(5, 5, 1, 0)

    assert [
             %{type: "prev", number: 4, enabled?: true},
             %{type: "page", number: 3, current?: false},
             %{type: "page", number: 4, current?: false},
             %{type: "page", number: 5, current?: true},
             %{type: "next", number: 5, enabled?: false}
           ] = items
  end

  test "pager for 100 pages, current page 1, 2 siblings and 2 boundary pages" <>
         " shows: [1], 2, 3, 4, ... , 98, 99, 100, next" do
    items = get_pagination_items(100, 1, 2, 2)

    assert [
             %{type: "prev", number: 1, enabled?: false},
             # current page
             %{type: "page", number: 1, current?: true},
             # start boundary pages
             %{type: "page", number: 2, current?: false},
             %{type: "page", number: 3, current?: false},
             # start sibling pages
             %{type: "page", number: 4, current?: false},
             %{type: "page", number: 5, current?: false},
             # end sibling pages
             %{type: "page", number: 6, current?: false},
             %{type: "page", number: 7, current?: false},
             # ellipsis
             %{type: "..."},
             # end boundary pages
             %{type: "page", number: 99, current?: false},
             %{type: "page", number: 100, current?: false},
             %{type: "next", number: 2, enabled?: true}
           ] = items
  end

  test "pager for 100 pages, current page 5, 2 siblings and 2 boundary pages" <>
         " shows: prev, 1, 2, 3, 4, [5], 6, 7 ... , 98, 99, 100, next" do
    items = get_pagination_items(100, 5, 2, 2)

    assert [
             %{type: "prev", number: 4, enabled?: true},
             # start boundary pages
             %{type: "page", number: 1, current?: false},
             %{type: "page", number: 2, current?: false},
             # start sibling pages
             %{type: "page", number: 3, current?: false},
             %{type: "page", number: 4, current?: false},
             # current page
             %{type: "page", number: 5, current?: true},
             # end sibling pages
             %{type: "page", number: 6, current?: false},
             %{type: "page", number: 7, current?: false},
             # ellipsis
             %{type: "..."},
             # end boundary pages
             %{type: "page", number: 99, current?: false},
             %{type: "page", number: 100, current?: false},
             %{type: "next", number: 6, enabled?: true}
           ] = items
  end

  test "pager for 100 pages, current page 6, 2 siblings and 2 boundary pages" <>
         " shows: prev, 1, 2, .., 4, 5, [6], 7, 8, ... , 98, 99, 100, next" do
    items = get_pagination_items(100, 6, 2, 2)

    assert [
             %{type: "prev", number: 5, enabled?: true},
             # start boundary pages
             %{type: "page", number: 1, current?: false},
             %{type: "page", number: 2, current?: false},
             # ellipsis
             %{type: "..."},
             # start sibling pages
             %{type: "page", number: 4, current?: false},
             %{type: "page", number: 5, current?: false},
             # current page
             %{type: "page", number: 6, current?: true},
             # end sibling pages
             %{type: "page", number: 7, current?: false},
             %{type: "page", number: 8, current?: false},
             # ellipsis
             %{type: "..."},
             # end boundary pages
             %{type: "page", number: 99, current?: false},
             %{type: "page", number: 100, current?: false},
             %{type: "next", number: 7, enabled?: true}
           ] = items
  end

  test "pager for 100 pages, current page 7, 2 siblings and 2 boundary pages" <>
         " shows prev, [1], 2, 3, 4, ... , 98, 99, 100, next" do
    items = get_pagination_items(100, 7, 2, 2)

    assert [
             # prev page 6
             %{type: "prev", number: 6, enabled?: true},
             # start boundary pages
             %{type: "page", number: 1, current?: false},
             %{type: "page", number: 2, current?: false},
             # ellipsis
             %{type: "..."},
             # start sibling pages
             %{type: "page", number: 5, current?: false},
             %{type: "page", number: 6, current?: false},
             # current page
             %{type: "page", number: 7, current?: true},
             # end sibling pages
             %{type: "page", number: 8, current?: false},
             %{type: "page", number: 9, current?: false},
             # ellipsis
             %{type: "..."},
             # end boundary pages
             %{type: "page", number: 99, current?: false},
             %{type: "page", number: 100, current?: false},
             # next page 8
             %{type: "next", number: 8, enabled?: true}
           ] = items
  end

  test "pager for 100 pages, current page 100, 2 siblings and 2 boundary pages" <>
         " shows prev, 1, 2, ... 94, 95, 96, 97, 98, 99, [100]" do
    items = get_pagination_items(100, 100, 2, 2)

    assert [
             # prev page 6
             %{type: "prev", number: 99, enabled?: true},
             # start boundary pages
             %{type: "page", number: 1, current?: false},
             %{type: "page", number: 2, current?: false},
             # ellipsis
             %{type: "..."},
             # start sibling pages
             %{type: "page", number: 94, current?: false},
             %{type: "page", number: 95, current?: false},
             # end sibling pages
             %{type: "page", number: 96, current?: false},
             %{type: "page", number: 97, current?: false},
             # end boundary pages
             %{type: "page", number: 98, current?: false},
             %{type: "page", number: 99, current?: false},
             # current page
             %{type: "page", number: 100, current?: true},
             # next page 8
             %{type: "next", number: 100, enabled?: false}
           ] = items
  end

  test "test less than 5 pages" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pagination link_type="a" class="mb-5" path="/:page" current_page={1} total_pages={1} />
      """)

    refute html =~ "/page/2"
  end

  test "previous doesn't show on page 1" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pagination path="/page/:page" total_pages={10} current_page={1} />
      """)

    refute html =~ "/page/0"
  end

  test "next doesn't show on last page" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pagination path="/page/:page" total_pages={10} current_page={10} />
      """)

    refute html =~ "/page/11"
  end

  test "show front ellipsis if current page is greater than the boundary count" do
    # bc: 1, sib: 1
    # 10 no [1], 2, 3, 4, 5,
    # 10 no 1, [2], 3, 4, 5,
    # 10 no 1, 2, [3], 4, 5,
    # 10 no 1, ..., 3, [4], 5,
    # 10 no 1, ..., 4, [5],6,

    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pagination path="/page/:page" total_pages={10} current_page={1} />
      """)

    ellipis_count = (html |> String.split("...") |> length()) - 1
    assert ellipis_count == 1

    html =
      rendered_to_string(~H"""
      <.pagination path="/page/:page" total_pages={10} current_page={2} />
      """)

    ellipis_count = (html |> String.split("...") |> length()) - 1
    assert ellipis_count == 1

    html =
      rendered_to_string(~H"""
      <.pagination path="/page/:page" total_pages={10} current_page={3} />
      """)

    ellipis_count = (html |> String.split("...") |> length()) - 1
    assert ellipis_count == 1

    html =
      rendered_to_string(~H"""
      <.pagination path="/page/:page" total_pages={10} current_page={4} />
      """)

    ellipis_count = (html |> String.split("...") |> length()) - 1
    assert ellipis_count == 2

    html =
      rendered_to_string(~H"""
      <.pagination path="/page/:page" total_pages={10} current_page={5} />
      """)

    ellipis_count = (html |> String.split("...") |> length()) - 1
    assert ellipis_count == 2
  end

  test "show back ellipsis if current page is less than the total - boundary count" do
    # bc: 1, sib: 1
    # 10 no 6, 7, 8, 9, [10]
    # 10 no 6, 7, 8, [9], 10
    # 10 no 6, 7, [8], 9, 10
    # 10 no 6, [7], 8, ..., 10
    # 10 no [6], 7, ..., 10

    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pagination path="/page/:page" total_pages={10} current_page={10} />
      """)

    refute html =~ "/page/11"
  end

  test "dark mode" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pagination path="/page/:page" total_pages={10} current_page={1} />
      """)

    refute html =~ "/page/0"
    assert html =~ "dark:"
  end

  test "should include additional assigns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pagination path="/page/:page" total_pages={10} current_page={1} custom-attrs="12" />
      """)

    assert html =~ ~s{custom-attrs="12"}
  end

  test "correct link type for live_patch" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pagination path="/page/:page" total_pages={10} current_page={1} link_type="live_patch" />
      """)

    assert html =~ ~s{data-phx-link="patch"}
  end

  test "correct link type for live_redirect" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pagination path="/page/:page" total_pages={10} current_page={1} link_type="live_redirect" />
      """)

    assert html =~ ~s{data-phx-link="redirect"}
  end

  test "accepts function to define path" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pagination path={&"/page/#{&1}"} total_pages={3} current_page={1} />
      """)

    assert html =~ "/page/2"
    assert html =~ "/page/3"
  end
end
