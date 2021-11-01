defmodule Petal.Container do
  use Phoenix.Component

  # <.container max_width="sm|md|lg|xl" />
  # <.container no_padding_on_mobile={true} />
  def container(assigns) do
    assigns = assign_new(assigns, :max_width, fn -> "lg" end)

    ~H"""
    <div class={get_full_width_classes(assigns)}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp get_full_width_classes(assigns) do
    base_classes = "mx-auto sm:px-6 lg:px-8"

    max_width_class =
      case assigns.max_width do
        "sm" -> "max-w-3xl"
        "md" -> "max-w-5xl"
        "lg" -> "max-w-7xl"
        "full" -> "max-w-full"
      end

    custom_classes = assigns[:class] || ""
    underline_classes = if assigns[:no_padding_on_mobile], do: "", else: "px-4"

    [max_width_class, base_classes, custom_classes, underline_classes]
    |> Enum.join(" ")
  end
end
