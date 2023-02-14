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
            "pc-avatar--with-placeholder-icon",
            get_size_classes(@size),
            @class
          ])
        }
      >
        <Heroicons.user solid class="pc-avatar__placeholder-icon" />
      </div>
    <% else %>
      <%= if src_blank?(@src) && @name do %>
        <div
          {@rest}
          style={maybe_generate_random_color(@random_color, @name)}
          class={
            build_class([
              "pc-avatar--with-placeholder-initials",
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
              "pc-avatar--with-image",
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
        <.avatar src={src} size={@size} class={build_class(["pc-avatar-group", @class])} />
      <% end %>
    </div>
    """
  end

  defp get_size_classes(size) do
    case size do
      "xs" -> "pc-avatar--xs"
      "sm" -> "pc-avatar--sm"
      "md" -> "pc-avatar--md"
      "lg" -> "pc-avatar--lg"
      "xl" -> "pc-avatar--xl"
    end
  end

  defp avatar_group_classes(opts) do
    opts = %{
      size: opts[:size] || "md",
      class: opts[:class] || ""
    }

    size_css =
      case opts[:size] do
        "xs" -> "pc-avatar-group--xs"
        "sm" -> "pc-avatar-group--sm"
        "md" -> "pc-avatar-group--md"
        "lg" -> "pc-avatar-group--lg"
        "xl" -> "pc-avatar-group--xl"
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
