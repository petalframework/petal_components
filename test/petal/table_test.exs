defmodule PetalComponents.TableTest do
  use ComponentCase
  import PetalComponents.Table

  test "Basic table" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.table></.table>
      """)

    assert html =~ "<table"
    assert html =~ "pc-table"
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
end
