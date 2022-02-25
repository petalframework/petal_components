defmodule PetalComponents.TableTest do
  use ComponentCase
  import PetalComponents.Table

  test "Basic table" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.table>
        <.tr>
          <.th>Name</.th>
          <.th>Title</.th>
          <.th>Email</.th>
        </.tr>

        <.tr>
          <.td>
            John Smith
          </.td>
          <.td>Engineer</.td>
          <.td>john.smith@example.com</.td>
        </.tr>

        <.tr>
          <.td>
            Beth Springs
          </.td>
          <.td>Developer</.td>
          <.td>beth.springs@example.com</.td>
        </.tr>

        <.tr>
          <.td>
            Peter Knowles
          </.td>
          <.td>Programmer</.td>
          <.td>Peter.knowles@example.com</.td>
        </.tr>

        <.tr>
          <.td>
            Sarah Hill
          </.td>
          <.td>Marketer</.td>
          <.td>sarah.hill@example.com</.td>
        </.tr>
      </.table>
      """)

    assert html =~ "<table"
    assert html =~ "<th"
    assert html =~ "<tr"
    assert html =~ "<td"
    assert html =~ "last:border-none"
    assert html =~ "Name"
    assert html =~ "bg-gray-50"
    assert html =~ "bg-white"
  end
end
