defmodule PetalComponents.Table do
  use Phoenix.Component

  import PetalComponents.Avatar
  import PetalComponents.Helpers

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def table(assigns) do
    ~H"""
    <table
      class={
        build_class([
          "pc-table",
          @class
        ])
      }
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </table>
    """
  end

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:rest, :global, include: ~w(colspan rowspan))
  slot(:inner_block, required: false)

  def th(assigns) do
    ~H"""
    <th
      class={
        build_class(
          [
            "pc-table__th",
            @class
          ],
          " "
        )
      }
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </th>
    """
  end

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def tr(assigns) do
    ~H"""
    <tr
      class={
        build_class([
          "pc-table__tr",
          @class
        ])
      }
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </tr>
    """
  end

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:rest, :global, include: ~w(colspan headers rowspan))
  slot(:inner_block, required: false)

  def td(assigns) do
    ~H"""
    <td
      class={
        build_class(
          [
            "pc-table__td",
            @class
          ],
          " "
        )
      }
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </td>
    """
  end

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:label, :string, default: nil, doc: "Adds a label your user, e.g name")
  attr(:sub_label, :string, default: nil, doc: "Adds a sub-label your to your user, e.g title")
  attr(:rest, :global)

  attr(:avatar_assigns, :map,
    default: nil,
    doc: "if using an avatar, this map will be passed to the avatar component as props"
  )

  def user_inner_td(assigns) do
    ~H"""
    <div class={@class} {@rest}>
      <div class="pc-table__user-inner-td">
        <%= if @avatar_assigns do %>
          <.avatar {@avatar_assigns} />
        <% end %>

        <div class="pc-table__user-inner-td__inner">
          <div class="pc-table__user-inner-td__label">
            <%= @label %>
          </div>
          <div class="pc-table__user-inner-td__sub-label">
            <%= @sub_label %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
