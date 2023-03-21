defmodule PetalComponents.Icon do
  use Phoenix.Component

  attr :rest, :global,
    doc: "the arbitrary HTML attributes for the svg container",
    include: ~w(fill stroke stroke-width)

  attr :name, :atom, required: true
  attr :outline, :boolean, default: true
  attr :solid, :boolean, default: false
  attr :mini, :boolean, default: false

  @doc """
  A dynamic way of generating a Heroicon (v2).

  Example:

      <.icon name={:arrow_right} class="w-5 h-5 text-gray-600 dark:text-gray-400" />
  """
  def icon(assigns) do
    apply(Heroicons, assigns.name, [assigns])
  end
end
