defmodule Petal.Container do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div class="px-4 mx-auto max-w-7xl sm:px-6 lg:px-8">
      <div cslass="max-w-3xl mx-auto">
      </div>
    </div>
    """
  end
end
