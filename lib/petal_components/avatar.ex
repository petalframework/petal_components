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

  attr(:random_gradient, :boolean,
    default: false,
    doc:
      "generates a gradient background for placeholder initials, hashed from the name like random_color - same name, same gradient. Wins over random_color when both are set"
  )

  attr(:art, :string,
    default: nil,
    values: [nil, "mesh", "dither"],
    doc:
      "generative art instead of initials: mesh is a soft multi-hue gradient, dither an ordered-dither blend - both hashed from the name, so the same name always draws the same avatar. Pure art by default; the name still labels the avatar for screen readers, and a photo src wins when present"
  )

  attr(:initials, :boolean,
    default: false,
    doc:
      "art variants only: overlay the monogram on the art. Because the palette is generated server-side, text colour and pattern contrast adjust automatically - a dark hue-tinted monogram over slightly lifted tones"
  )

  attr(:shape, :string,
    default: "circle",
    values: ["circle", "rounded"],
    doc:
      "circle is the convention for people; rounded (proportional soft corners) suits orgs, teams and workspaces. Deliberately independent of the --pc-radius dial - avatars are identity, not surface, and a sharp-cornered theme still wants soft avatars"
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

  defp avatar_media(%{art: art} = assigns) when not is_nil(art) do
    ~H"""
    <%= if src_blank?(@src) do %>
      <div
        {@rest}
        role="img"
        aria-label={@name || "avatar"}
        style={art_style(@art, @name || "", @initials)}
        class={[
          "pc-avatar--art",
          "pc-avatar--#{@size}",
          @shape == "rounded" && "pc-avatar--rounded",
          @class
        ]}
      >
        {if @initials && @name, do: generate_initials(@name)}
      </div>
    <% else %>
      <img
        {@rest}
        src={@src}
        alt={@alt || @name}
        class={[
          "pc-avatar--with-image",
          "pc-avatar--#{@size}",
          @shape == "rounded" && "pc-avatar--rounded",
          @class
        ]}
      />
    <% end %>
    """
  end

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
          @shape == "rounded" && "pc-avatar--rounded",
          @class
        ]}
      >
        <.icon name="hero-user-solid" class="pc-avatar__placeholder-icon" />
      </div>
    <% else %>
      <%= if src_blank?(@src) && @name do %>
        <div
          {@rest}
          style={placeholder_background(@random_color, @random_gradient, @name)}
          role="img"
          aria-label="user avatar"
          class={[
            "pc-avatar--with-placeholder-initials",
            "pc-avatar--#{@size}",
            @shape == "rounded" && "pc-avatar--rounded",
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
            @shape == "rounded" && "pc-avatar--rounded",
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

  attr(:shape, :string,
    default: "circle",
    values: ["circle", "rounded"],
    doc: "shape passed through to every avatar and the +N bubble"
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
        <.avatar src={src} size={@size} shape={@shape} class="pc-avatar-group" />
      <% end %>
      <div
        :if={@overflow > 0}
        class={[
          "pc-avatar--with-placeholder-initials",
          "pc-avatar--#{@size}",
          @shape == "rounded" && "pc-avatar--rounded",
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

  defp placeholder_background(_color, true, name) do
    hue = hue_from_string(name)

    "background-image: linear-gradient(135deg, hsl(#{hue}, 88%, 52%), hsl(#{rem(hue + 65, 360)}, 88%, 32%)); color: white;"
  end

  defp placeholder_background(true, _gradient, name) do
    "background-color: hsl(#{hue_from_string(name)}, 100%, 35%); color: white;"
  end

  defp placeholder_background(_color, _gradient, _name), do: nil

  defp hue_from_string(string) do
    string
    |> String.to_charlist()
    |> Enum.reduce(0, fn x, acc -> x + acc end)
    |> rem(360)
  end

  # Generative art placeholders. Everything derives from hashes of the name,
  # so the same name always draws the same avatar - no state, no JS, no deps.

  # Soft multi-hue mesh: two or three radial blobs at hashed positions over a
  # base tone, hues spread around the wheel for the aurora look. With
  # initials on, the monogram goes dark in the base hue - the mesh reads
  # light, so a tinted-dark monogram always contrasts.
  defp art_style("mesh", name, initials?) do
    h = hue_from_string(name)
    [x1, y1, x2, y2, x3, y3] = for i <- 1..6, do: 10 + :erlang.phash2({name, i}, 81)
    spread1 = 70 + :erlang.phash2({name, :spread1}, 90)
    spread2 = 160 + :erlang.phash2({name, :spread2}, 120)

    "background-color: hsl(#{h}, 75%, 62%); background-image: " <>
      "radial-gradient(at #{x1}% #{y1}%, hsl(#{rem(h + spread1, 360)}, 90%, 70%) 0px, transparent 55%), " <>
      "radial-gradient(at #{x2}% #{y2}%, hsl(#{rem(h + spread2, 360)}, 85%, 66%) 0px, transparent 55%), " <>
      "radial-gradient(at #{x3}% #{y3}%, hsl(#{h}, 95%, 76%) 0px, transparent 60%);" <>
      if(initials?, do: " color: hsl(#{h}, 60%, 18%);", else: "")
  end

  # Two hues blended across the diagonal through an ordered 4x4 Bayer
  # threshold - the retro print look. Rendered as a tiny inline SVG so the
  # pixels stay crisp at any display size. With initials on, the two tones
  # lift and move closer so the texture quiets down behind the monogram.
  defp art_style("dither", name, initials?) do
    {l1, l2} = if initials?, do: {72, 60}, else: {66, 52}

    "background-image: url('#{dither_data_uri(name, l1, l2)}');" <>
      if(initials?, do: " color: hsl(#{hue_from_string(name)}, 60%, 16%);", else: "")
  end

  @bayer {{0, 8, 2, 10}, {12, 4, 14, 6}, {3, 11, 1, 9}, {15, 7, 13, 5}}
  @dither_cells 12

  defp dither_data_uri(name, l1, l2) do
    n = @dither_cells
    h1 = hue_from_string(name)
    h2 = rem(h1 + 70 + :erlang.phash2({name, :spread}, 150), 360)
    flip? = :erlang.phash2({name, :dir}, 2) == 1

    cells =
      for y <- 0..(n - 1), x <- 0..(n - 1) do
        fx = if flip?, do: n - 1 - x, else: x
        # steepen the diagonal ramp so the corners go solid and the dither
        # concentrates in a band across the middle - without the gain the
        # whole circle reads as uniform checkerboard
        t = ((fx + y) / (2 * (n - 1)) - 0.5) * 2.2 + 0.5
        threshold = (@bayer |> elem(rem(y, 4)) |> elem(rem(x, 4))) / 16 + 0.03
        if t > threshold, do: "M#{x} #{y}h1v1h-1z"
      end
      |> Enum.reject(&is_nil/1)
      |> Enum.join()

    svg =
      "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 #{n} #{n}' shape-rendering='crispEdges'>" <>
        "<rect width='#{n}' height='#{n}' fill='hsl(#{h1},85%,#{l1}%)'/>" <>
        "<path fill='hsl(#{h2},85%,#{l2}%)' d='#{cells}'/></svg>"

    "data:image/svg+xml," <>
      (svg
       |> String.replace("<", "%3C")
       |> String.replace(">", "%3E")
       |> String.replace("#", "%23")
       |> String.replace("'", "%27")
       |> String.replace(" ", "%20"))
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
