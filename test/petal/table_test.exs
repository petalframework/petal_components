defmodule PetalComponents.TableTest do
  use ComponentCase
  import PetalComponents.Table

  describe "Dynamic table" do
    setup do
      %{
        posts: [
          %{
            id: 1,
            name: "Some post"
          },
          %{
            id: 2,
            name: "Another post"
          }
        ]
      }
    end

    test "plain", assigns do
      html =
        rendered_to_string(~H"""
        <.table class="my-class" id="posts" row_id={fn post -> "row_#{post.id}" end} rows={@posts}>
          <:col :let={post} label="Name" class="col-class" row_class="row-class">{post.name}</:col>
        </.table>
        """)

      assert html =~ "<table"
      assert html =~ "pc-table"
      assert html =~ "my-class"
      assert html =~ "col-class"
      assert html =~ "row-class"

      Enum.each(assigns.posts, fn post ->
        assert html =~ "row_#{post.id}"
        assert html =~ post.name
      end)
    end

    test "with empty state", assigns do
      html =
        rendered_to_string(~H"""
        <.table class="my-class" id="posts" row_id={fn post -> "row_#{post.id}" end} rows={[]}>
          <:col :let={post} label="Name" class="col-class" row_class="row-class">{post.name}</:col>
          <:empty_state row_class="empty-class">This table is empty</:empty_state>
        </.table>
        """)

      assert html =~ "empty-class"
      assert html =~ "This table is empty"
    end

    test "row_click", assigns do
      html =
        rendered_to_string(~H"""
        <.table
          id="posts"
          row_id={fn post -> "row_#{post.id}" end}
          rows={@posts}
          row_click={fn post -> Phoenix.LiveView.JS.navigate("/link_to_#{post.id}") end}
        >
          <:col :let={post} label="Name">{post.name}</:col>
        </.table>
        """)

      assert html =~ "pc-table__tr--row-click"

      Enum.each(assigns.posts, fn post ->
        assert html =~ "link_to_#{post.id}"
      end)
    end
  end

  test "Basic table" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.table></.table>
      """)

    assert html =~ "<table"
    assert html =~ "pc-table--basic"
  end

  test "Basic table (ghost variant)" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.table variant="ghost"></.table>
      """)

    assert html =~ "<table"
    assert html =~ "pc-table--ghost"
  end

  test "tr" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tr></.tr>
      """)

    assert html =~ "<tr"
    assert html =~ "table__tr"
  end

  test "th" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.th>Name</.th>
      """)

    assert html =~ "<th"
    assert html =~ "pc-table__th"
  end

  test "td" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.td>
        John Smith
      </.td>
      """)

    assert html =~ "<td"
    assert html =~ "pc-table__td"
  end

  test "user_inner_td" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.user_inner_td
        avatar_assigns={
          %{
            src:
              "https://res.cloudinary.com/wickedsites/image/upload/v1636595188/dummy_data/avatar_1_lc8plf.png"
          }
        }
        label="Beth Springs"
        sub_label="beth.springs@example.com"
      />
      """)

    assert html =~ "<img src="
    assert html =~ "pc-table__user-inner-td__inner"
    assert html =~ "pc-table__user-inner-td__sub-label"
  end

  test "components include additional assigns" do
    assigns = %{}

    assert rendered_to_string(~H"""
           <.table custom-attr="123"></.table>
           """) =~ ~s{custom-attr="123"}

    assert rendered_to_string(~H"""
           <.tr custom-attr="123"></.tr>
           """) =~ ~s{custom-attr="123"}

    assert rendered_to_string(~H"""
           <.th custom-attr="123"></.th>
           """) =~ ~s{custom-attr="123"}

    assert rendered_to_string(~H"""
           <.td custom-attr="123"></.td>
           """) =~ ~s{custom-attr="123"}

    assert rendered_to_string(~H"""
           <.user_inner_td label="John" sub_label="Smith" custom-attr="123" />
           """) =~ ~s{custom-attr="123"}
  end

  test "components include additional classes" do
    assigns = %{}

    assert rendered_to_string(~H"""
           <.table class="extra-class"></.table>
           """) =~ "extra-class"

    assert rendered_to_string(~H"""
           <.tr class="extra-class"></.tr>
           """) =~ "extra-class"

    assert rendered_to_string(~H"""
           <.th class="extra-class"></.th>
           """) =~ "extra-class"

    assert rendered_to_string(~H"""
           <.td class="extra-class"></.td>
           """) =~ "extra-class"

    assert rendered_to_string(~H"""
           <.user_inner_td label="John" sub_label="Smith" class="extra-class" />
           """) =~ "extra-class"
  end

  test "sortable column renders a sort button with aria-sort and state icon" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.table rows={[%{name: "Ada"}]} sort_by="name" sort_dir="asc" on_sort="sort">
        <:col :let={u} label="Name" sortable>{u.name}</:col>
        <:col :let={u} label="Role">{u.name}</:col>
      </.table>
      """)

    assert html =~ "pc-table__sort"
    assert html =~ ~s(phx-click="sort")
    assert html =~ ~s(phx-value-sort="name")
    assert html =~ ~s(aria-sort="ascending")
    assert html =~ "pc-table__sort-icon--active"
  end

  test "density, striped and sticky header classes" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.table rows={[%{a: 1}]} density="compact" striped sticky_header>
        <:col :let={r} label="A">{r.a}</:col>
      </.table>
      """)

    assert html =~ "pc-table--compact"
    assert html =~ "pc-table--striped"
    assert html =~ "pc-table__th--sticky"
  end

  test "footer slot renders a tfoot totals row" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.table rows={[%{n: 1}]}>
        <:col :let={r} label="N">{r.n}</:col>
        <:footer>
          <.td colspan={1}>Total: 1</.td>
        </:footer>
      </.table>
      """)

    assert html =~ "<tfoot"
    assert html =~ "pc-table__tfoot"
    assert html =~ "Total: 1"
  end
end
