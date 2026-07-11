defmodule PetalComponents.Avatar do
  use Phoenix.Component

  import PetalComponents.Icon

  attr(:src, :string, default: nil, doc: "hosted avatar URL")
  attr(:alt, :string, default: nil, doc: "alt text for avatar image")
  attr(:size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"])
  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:name, :string, default: nil, doc: "name for placeholder initials")

  attr(:random_color, :boolean,
    default: false,
    doc: "generates a random color for placeholder initials avatar"
  )

  attr(:status, :string,
    default: nil,
    values: [nil, "online", "offline", "busy", "away"],
    doc: "presence dot on the bottom-right corner, ringed to separate from the image"
  )

  attr(:rest, :global)

  def avatar(%{status: status} = assigns) when not is_nil(status) do
    ~H"""
    <span class="pc-avatar-anchor">
      {avatar_media(assigns)}
      <span
        class={["pc-avatar__status", "pc-avatar__status--#{@status}", "pc-avatar__status--#{@size}"]}
        role="status"
        aria-label={@status}
      ></span>
    </span>
    """
  end

  def avatar(assigns), do: avatar_media(assigns)

  defp avatar_media(assigns) do
    ~H"""
    <%= if src_blank?(@src) && !@name do %>
      <div
        {@rest}
        role="img"
        aria-label="user avatar"
        class={[
          "pc-avatar--with-placeholder-icon",
          "pc-avatar--#{@size}",
          @class
        ]}
      >
        <.icon name="hero-user-solid" class="pc-avatar__placeholder-icon" />
      </div>
    <% else %>
      <%= if src_blank?(@src) && @name do %>
        <div
          {@rest}
          style={maybe_generate_random_color(@random_color, @name)}
          role="img"
          aria-label="user avatar"
          class={[
            "pc-avatar--with-placeholder-initials",
            "pc-avatar--#{@size}",
            @class
          ]}
        >
          {generate_initials(@name)}
        </div>
      <% else %>
        <img
          {@rest}
          src={@src}
          alt={@alt || @src}
          class={[
            "pc-avatar--with-image",
            "pc-avatar--#{@size}",
            @class
          ]}
        />
      <% end %>
    <% end %>
    """
  end

  attr(:size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"])
  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:avatars, :list, default: [], doc: "list of your hosted avatar URLs")

  attr(:max, :integer,
    default: nil,
    doc: "show at most this many avatars, then a +N overflow bubble for the rest"
  )

  attr(:rest, :global)

  def avatar_group(assigns) do
    {shown, hidden} =
      if assigns.max, do: Enum.split(assigns.avatars, assigns.max), else: {assigns.avatars, []}

    assigns =
      assigns
      |> assign(:shown, shown)
      |> assign(:overflow, length(hidden))

    ~H"""
    <div {@rest} class={["pc-avatar-group--#{@size}", @class]}>
      <%= for src <- @shown do %>
        <.avatar src={src} size={@size} class="pc-avatar-group" />
      <% end %>
      <div
        :if={@overflow > 0}
        class={[
          "pc-avatar--with-placeholder-initials",
          "pc-avatar--#{@size}",
          "pc-avatar-group",
          "pc-avatar-group__overflow"
        ]}
        aria-label={"#{@overflow} more"}
      >
        +{@overflow}
      </div>
    </div>
    """
  end

  defp src_blank?(src), do: !src || src == ""

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
