defmodule PetalComponents.Avatar do
  use Phoenix.Component
  import PetalComponents.Helpers

  attr(:src, :string, default: nil, doc: "hosted avatar URL")
  attr(:size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"])
  attr(:class, :string, default: "", doc: "CSS class")
  attr(:name, :string, default: nil, doc: "name for placeholder initials")

  attr(:random_color, :boolean,
    default: false,
    doc: "generates a random color for placeholder initials avatar"
  )

  attr(:rest, :global)

  def avatar(assigns) do
    ~H"""
    <%= if src_blank?(@src) && !@name do %>
      <div
        {@rest}
        class={
          build_class([
            "inline-block relative overflow-hidden bg-gray-100 dark:bg-gray-700 rounded-full",
            get_size_classes(@size),
            @class
          ])
        }
      >
        <Heroicons.user
          solid
          class="relative w-full h-full text-gray-300 dark:text-gray-300 dark:bg-gray-700 top-[12%] scale-[1.15] transform"
        />
      </div>
    <% else %>
      <%= if src_blank?(@src) && @name do %>
        <div
          {@rest}
          style={maybe_generate_random_color(@random_color, @name)}
          class={
            build_class([
              "flex items-center justify-center bg-gray-100 dark:bg-gray-700 rounded-full font-semibold uppercase text-gray-500 dark:text-gray-300",
              get_size_classes(@size),
              @class
            ])
          }
        >
          <%= generate_initials(@name) %>
        </div>
      <% else %>
        <img
          {@rest}
          src={@src}
          class={
            build_class([
              "rounded-full object-cover",
              get_size_classes(@size),
              @class
            ])
          }
        />
      <% end %>
    <% end %>
    """
  end

  attr(:size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"])
  attr(:class, :string, default: "", doc: "CSS class")
  attr(:avatars, :list, default: [], doc: "list of your hosted avatar URLs")
  attr(:rest, :global)

  def avatar_group(assigns) do
    assigns =
      assigns
      |> assign(:classes, avatar_group_classes(assigns))

    ~H"""
    <div {@rest} class={@classes}>
      <%= for src <- @avatars do %>
        <.avatar
          src={src}
          size={@size}
          class={build_class(["ring-white ring-2 dark:ring-gray-100", @class])}
        />
      <% end %>
    </div>
    """
  end

  defp get_size_classes(size) do
    case size do
      "xs" -> "w-7 h-7 text-xs"
      "sm" -> "w-8 h-8 text-sm"
      "md" -> "w-10 h-10 text-md"
      "lg" -> "w-12 h-12 text-lg"
      "xl" -> "w-14 h-14 text-xl"
    end
  end

  defp avatar_group_classes(opts) do
    opts = %{
      size: opts[:size] || "md",
      class: opts[:class] || ""
    }

    size_css =
      case opts[:size] do
        "xs" -> "relative z-0 flex -space-x-2"
        "sm" -> "relative z-0 flex -space-x-3"
        "md" -> "relative z-0 flex -space-x-4"
        "lg" -> "relative z-0 flex -space-x-5"
        "xl" -> "relative z-0 flex -space-x-6"
      end

    """
      #{opts.class}
      #{size_css}
    """
  end

  defp src_blank?(src) do
    !src || src == ""
  end

  defp maybe_generate_random_color(false, _), do: nil

  defp maybe_generate_random_color(true, name) do
    "background-color: #{generate_color_from_string(name)}; color: white;"
  end

  defp generate_color_from_string(string) do
    a_number =
      string
      |> String.to_charlist()
      |> Enum.reduce(0, fn x, acc -> x + acc end)

    "hsl(#{rem(a_number, 360)}, 100%, 35%)"
  end

  defp generate_initials(name) when is_binary(name) do
    word_array = String.split(name)

    if length(word_array) == 1 do
      List.first(word_array)
      |> String.slice(0..1)
      |> String.upcase()
    else
      initial1 = String.first(List.first(word_array))
      initial2 = String.first(List.last(word_array))
      String.upcase(initial1 <> initial2)
    end
  end

  defp generate_initials(_) do
    ""
  end
end
