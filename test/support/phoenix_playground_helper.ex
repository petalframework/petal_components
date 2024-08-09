defmodule PhoenixPlaygroundHelper do
  @moduledoc """
  Phoenix Playground doesn't yet support running in the background during test outside of LiveView tests.
  a11y_helper runs with Wallaby, so these are helpers to gracefully shutdown the Phoenix Playground started in test_helper.exs.
  """

  def shutdown, do: Application.stop(:phoenix_playground)

  def exit_processes(pid) when is_pid(pid), do: exit_tree(pid)

  defp exit_tree(pid) when is_pid(pid) do
    exit_tree_recursive(pid, MapSet.new())
    Process.exit(pid, :normal)
  end

  defp exit_tree_recursive(pid, visited) when is_pid(pid) do
    if MapSet.member?(visited, pid) do
      visited
    else
      visited = MapSet.put(visited, pid)

      case Process.info(pid, :links) do
        {:links, links} ->
          Enum.reduce(links, visited, fn link, acc ->
            exit_tree_recursive(link, acc)
          end)

        nil ->
          visited
      end
    end
  end

  defp exit_tree_recursive(port, visited) when is_port(port) do
    if MapSet.member?(visited, port) do
      visited
    else
      MapSet.put(visited, port)
    end
  end

  defp exit_tree_recursive(_, visited), do: visited
end
