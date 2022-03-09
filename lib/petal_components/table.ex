defmodule PetalComponents.Table do
  use Phoenix.Component
  import PetalComponents.Avatar

  def table(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:extra_assigns, fn ->
        assigns_to_attributes(assigns, ~w(
          class
        )a)
      end)

    ~H"""
    <table class={Enum.join([
      "min-w-full overflow-hidden divide-y divide-gray-200 rounded-sm shadow table-auto dark:divide-y-0 dark:divide-gray-800 sm:rounded",
      @class,
    ], " ")} {@extra_assigns}>
      <%= render_slot(@inner_block) %>
    </table>
    """
  end

  def th(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:extra_assigns, fn ->
        assigns_to_attributes(assigns, ~w(
          class
        )a)
      end)

    ~H"""
    <th class={Enum.join([
      "px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-300",
      @class,
    ], " ")} {@extra_assigns}>
      <%= if @inner_block do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </th>
    """
  end

  def tr(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:extra_assigns, fn ->
        assigns_to_attributes(assigns, ~w(
          class
        )a)
      end)

    ~H"""
    <tr class={Enum.join([
      "border-b dark:border-gray-700 bg-white dark:bg-gray-800 last:border-none",
      @class,
    ], " ")} {@extra_assigns}>
      <%= render_slot(@inner_block) %>
    </tr>
    """
  end

  def td(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:extra_assigns, fn ->
        assigns_to_attributes(assigns, ~w(
          class
        )a)
      end)

    ~H"""
    <td class={Enum.join([
      "px-6 py-4 text-sm text-gray-500 dark:text-gray-400",
      @class
    ], " ")} {@extra_assigns}>
      <%= render_slot(@inner_block) %>
    </td>
    """
  end

  def user_inner_td(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:avatar_assigns, fn -> nil end)
      |> assign_new(:extra_assigns, fn ->
        assigns_to_attributes(assigns, ~w(
          class
          avatar_assigns
          label
          sub_label
        )a)
      end)

    ~H"""
    <div class={@class} {@extra_assigns}>
      <div class="flex items-center gap-3">
        <%= if @avatar_assigns do %>
          <.avatar {@avatar_assigns} />
        <% end %>

        <div class="flex flex-col overflow-hidden">
          <div class="overflow-hidden font-medium text-gray-900 whitespace-nowrap text-ellipsis dark:text-gray-300"><%= @label %></div>
          <div class="overflow-hidden font-normal text-gray-500 whitespace-nowrap text-ellipsis"><%= @sub_label %></div>
        </div>
      </div>
    </div>
    """
  end
end
