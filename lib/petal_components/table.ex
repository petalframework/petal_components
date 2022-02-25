defmodule PetalComponents.Table do
  use Phoenix.Component

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
    <table class="min-w-full overflow-hidden divide-y divide-gray-200 rounded-sm shadow table-auto sm:rounded">
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
    <th class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
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
      @class
    ], " ")}>
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
      "px-6 py-4 text-sm text-gray-500 whitespace-nowrap dark:text-gray-400",
      @class
    ], " ")}>
      <%= render_slot(@inner_block) %>
    </td>
    """
  end
end
