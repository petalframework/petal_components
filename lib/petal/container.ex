defmodule Petal.Container do
  use Phoenix.Component

  def full_width(assigns) do
    ~H"""
    <div class={get_full_width_classes(assigns)}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp get_full_width_classes(assigns) do
    base_classes = "mx-auto max-w-7xl sm:px-6 lg:px-8"
    custom_classes = assigns[:class] || ""
    underline_classes = if assigns[:padding_on_mobile], do: "px-4", else: ""

    [base_classes, custom_classes, underline_classes]
    |> Enum.join(" ")
  end
end
