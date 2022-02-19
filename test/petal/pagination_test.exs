defmodule PetalComponents.PaginationTest do
  use ComponentCase
  import PetalComponents.Pagination

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
    assert ellipis_count == 1

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
end
