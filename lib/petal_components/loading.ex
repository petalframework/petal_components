defmodule PetalComponents.Loading do
  use Phoenix.Component

  # prop size, :string, values: ["sm", "md", "lg"]
  # prop class, :string, default: ""
  # prop show, :boolean, default: true
  def spinner(assigns) do
    assigns =
      assigns
      |> assign_new(:classes, fn -> get_spinner_classes(assigns) end)
      |> assign_new(:extra_assigns, fn ->
        assigns_to_attributes(assigns, ~w(
          classes
          class
          size
          show
        )a)
      end)

    ~H"""
    <svg
      {@extra_assigns}
      class={get_spinner_classes(assigns)}
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
    >
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
      <path
        class="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      />
    </svg>
    """
  end

  defp get_spinner_classes(assigns) do
    base_classes = "animate-spin"
    custom_classes = assigns[:class] || ""
    show_class = if assigns[:show] == false, do: "hidden", else: ""
    size_classes = assigns[:size_class] || get_size_classes(assigns[:size])

    Enum.join(
      [
        base_classes,
        custom_classes,
        show_class,
        size_classes
      ],
      " "
    )
  end

  defp get_size_classes("sm"), do: "h-5 w-5"
  defp get_size_classes("md"), do: "h-8 w-8"
  defp get_size_classes("lg"), do: "h-16 w-16"
  defp get_size_classes(_), do: "h-8 w-8"
end
