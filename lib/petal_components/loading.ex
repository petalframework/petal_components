defmodule PetalComponents.Loading do
  use Phoenix.Component

  import PetalComponents.Helpers

  attr(:size, :string, default: "sm", values: ["sm", "md", "lg"])
  attr(:size_class, :string, default: nil, doc: "custom CSS classes for size. eg: h-4 w-4")
  attr(:class, :string, default: nil, doc: "CSS class")
  attr(:show, :boolean, default: true, doc: "show or hide spinner")
  attr(:rest, :global)

  def spinner(assigns) do
    ~H"""
    <svg
      {@rest}
      class={get_spinner_classes(@class, @show, @size, @size_class)}
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

  defp get_spinner_classes(user_added_classes, show, size, custom_size_class) do
    base_classes = "pc-button__spinner-icon"
    custom_classes = user_added_classes
    show_class = if show == false, do: "hidden", else: ""
    size_classes = custom_size_class || get_size_classes(size)
    build_class([base_classes, show_class, size_classes, custom_classes])
  end

  defp get_size_classes("sm"), do: "pc-spinner--sm"
  defp get_size_classes("md"), do: "pc-spinner--md"
  defp get_size_classes("lg"), do: "pc-spinner--lg"
  defp get_size_classes(_), do: "pc-spinner--md"
end
