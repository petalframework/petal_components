defmodule PetalComponents.Showcase.Table do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Table,
    title: "Table",
    functions: [:table, :user_inner_td]

  example :sortable, "The presentation layer for data",
    description:
      "Rows in, markup out - and honest sorting: a sortable header is a real button that fires on_sort (default event \"sort\") with the column's sort_key, aria-sort announces the state, and your app owns the actual reorder. The :footer slot pins a totals row (colspan works); :empty_state renders whenever rows is empty. density=\"compact\", striped, sticky_header and the frameless variant=\"ghost\" restyle it; LiveView streams work unchanged." do
    ~H"""
    <div class="max-w-full overflow-x-auto">
      <.table
        sort_by="age"
        sort_dir="asc"
        rows={[
          %{name: "Sarah Chen", role: "Engineering", age: 34, status: "Active"},
          %{name: "Alex Rivera", role: "Design", age: 29, status: "Active"},
          %{name: "Jordan Lee", role: "Support", age: 41, status: "Away"}
        ]}
      >
        <:col :let={p} label="Name" sortable sort_key="name">{p.name}</:col>
        <:col :let={p} label="Role">{p.role}</:col>
        <:col :let={p} label="Age" sortable sort_key="age">{p.age}</:col>
        <:col :let={p} label="Status">
          <.badge
            color={if p.status == "Active", do: "success", else: "gray"}
            variant="soft"
            size="sm"
            label={p.status}
          />
        </:col>
        <:footer>
          <.td colspan={2}>3 people</.td>
          <.td>avg 35</.td>
          <.td></.td>
        </:footer>
      </.table>
    </div>
    """
  end

  example :people_cells, "People cells",
    description:
      "user_inner_td is the avatar + name + sub-label cell in one helper - avatar_assigns passes straight through to the avatar, so name-hashed initials work with no photos anywhere." do
    ~H"""
    <div class="max-w-full overflow-x-auto">
      <.table rows={[
        %{name: "Alex Rivera", email: "alex@example.com", plan: "Team"},
        %{name: "Ada Lovelace", email: "ada@analytical.engine", plan: "Pro"}
      ]}>
        <:col :let={u} label="User">
          <.user_inner_td
            label={u.name}
            sub_label={u.email}
            avatar_assigns={%{name: u.name, size: "sm"}}
          />
        </:col>
        <:col :let={u} label="Plan">{u.plan}</:col>
      </.table>
    </div>
    """
  end
end
