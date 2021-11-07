defmodule PetalComponents.Container do
  use Phoenix.Component

  # <.container max_width="sm|md|lg|xl" />
  # <.container no_padding_on_mobile={true} />
  def container(assigns) do
    assigns = assigns
      |> assign_new(:classes, fn -> get_full_width_classes(assigns) end)

    ~H"""
    <div class={@classes}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp get_full_width_classes(assigns) do
    opts = %{
      max_width: assigns[:max_width] || "lg",
      class: assigns[:class] || "",
      no_padding_on_mobile: assigns[:no_padding_on_mobile],
    }

    base_classes = "mx-auto sm:px-6 lg:px-8"

    max_width_class =
      case opts.max_width do
        "sm" -> "max-w-3xl"
        "md" -> "max-w-5xl"
        "lg" -> "max-w-7xl"
        "full" -> "max-w-full"
      end

    custom_classes = opts.class
    underline_classes = if opts.no_padding_on_mobile, do: "", else: "px-4"

    [max_width_class, base_classes, custom_classes, underline_classes]
    |> Enum.join(" ")
  end
end
