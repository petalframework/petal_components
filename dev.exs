# dev.exs — Standalone dev server for petal_components contributors
#
# Setup (first time only):
#   mix deps.get
#   mix tailwind.install
#
# Run:
#   iex -S mix run dev.exs
#
# Then open http://localhost:4000 in your browser.
# Changes to components in lib/ trigger live reload automatically.

# -- ErrorView ----------------------------------------------------------------

defmodule Dev.ErrorHTML do
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end

# -- Layout -------------------------------------------------------------------

defmodule Dev.Layouts do
  use Phoenix.Component

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <.live_title>Petal Components Playground</.live_title>
        <meta name="pg-rev" content="alert-badge-1" />
        <link rel="stylesheet" href="/assets/app.css" />
      </head>
      <body class="bg-white antialiased">
        <script>
          // Hidden webviews (Claude preview, headless CDP) never fire
          // requestAnimationFrame - Chrome pauses it while document.hidden.
          // LiveView schedules every client-side JS command DOM write
          // (show/hide/add_class/...) on rAF, so those commands silently
          // never run under automation. While hidden, fall back to a
          // timeout; when visible, native rAF is untouched. Must run before
          // the LiveView bundle loads.
          (() => {
            const nativeRAF = window.requestAnimationFrame.bind(window);
            const nativeCAF = window.cancelAnimationFrame.bind(window);
            let shimId = -1;
            const shimTimers = new Map();
            window.requestAnimationFrame = (cb) => {
              if (!document.hidden) return nativeRAF(cb);
              const id = shimId--;
              shimTimers.set(id, setTimeout(() => { shimTimers.delete(id); cb(performance.now()); }, 16));
              return id;
            };
            window.cancelAnimationFrame = (id) => {
              if (shimTimers.has(id)) { clearTimeout(shimTimers.get(id)); shimTimers.delete(id); return; }
              nativeCAF(id);
            };
          })();
        </script>
        <script src="/assets/phoenix/phoenix.js">
        </script>
        <script src="/assets/phoenix_live_view/phoenix_live_view.js">
        </script>
        <script type="module">
          import PetalComponents from "/assets/js/petal_components.js";
          window.liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket, {
            hooks: { ...PetalComponents },
            uploaders: {},
          });
          window.liveSocket.connect();
          window.addEventListener("pg:theme-switch", () => {
            const style = document.createElement("style");
            style.textContent = "* { transition: none !important; }";
            document.head.appendChild(style);
            setTimeout(() => style.remove(), 250);
          });
        </script>
        {@inner_content}
      </body>
    </html>
    """
  end

  def live(assigns) do
    ~H"""
    {@inner_content}
    """
  end
end

# -- Playground LiveView ------------------------------------------------------

defmodule Dev.PlaygroundLive do
  use Phoenix.LiveView,
    layout: {Dev.Layouts, :live},
    global_prefixes: ~w(x-)

  use PetalComponents

  alias Phoenix.LiveView.JS

  # Update by hand occasionally; formatted as "1k" style in the header.
  @stars 1037

  @nav [
    %{group: "Foundations",
      items: [
        %{slug: "typography", name: "Typography", ready: true},
        %{slug: "colors", name: "Colours", ready: true}
      ]},
    %{group: "Inputs",
      items: [
        %{slug: "button", name: "Button", ready: true},
        %{slug: "input", name: "Input", ready: true},
        %{slug: "checkbox", name: "Checkbox", ready: true},
        %{slug: "select", name: "Select", ready: true},
        %{slug: "radio", name: "Radio", ready: true},
        %{slug: "switch", name: "Switch", ready: true},
        %{slug: "input-otp", name: "Input OTP", ready: true}
      ]},
    %{group: "Feedback",
      items: [
        %{slug: "alert", name: "Alert", ready: true},
        %{slug: "badge", name: "Badge", ready: true},
        %{slug: "progress", name: "Progress", ready: true}
      ]},
    %{group: "Overlay",
      items: [
        %{slug: "tooltip", name: "Tooltip", ready: true},
        %{slug: "popover", name: "Popover", ready: true},
        %{slug: "modal", name: "Modal", ready: true},
        %{slug: "dropdown", name: "Dropdown", ready: true}
      ]},
    %{group: "Effects",
      items: [
        %{slug: "border-beam", name: "Border beam", ready: true},
        %{slug: "meteors", name: "Meteors", ready: true},
        %{slug: "shine-border", name: "Shine border", ready: true}
      ]}
  ]

  @slugs Enum.flat_map(@nav, fn g -> Enum.map(g.items, & &1.slug) end)

  # {name, rail swatch css}. Neutral adapts to the mode, hence the split dot.
  @accents [
    {"neutral", "linear-gradient(135deg,#18181b 50%,#e4e4e7 50%)"},
    {"blue", "#2563eb"},
    {"indigo", "#4f46e5"},
    {"violet", "#7c3aed"},
    {"emerald", "#059669"},
    {"rose", "#e11d48"},
    {"amber", "#d97706"}
  ]
  @accent_names Enum.map(@accents, &elem(&1, 0))

  # Theme radius: the rail sets --pc-radius on the page, so every component
  # that reads the token follows. Labels are honest pixel values.
  @radii [
    {"0", "0px"},
    {"6", "0.375rem"},
    {"10", "0.625rem"},
    {"14", "0.875rem"},
    {"full", "9999px"}
  ]
  @radius_labels Enum.map(@radii, &elem(&1, 0))

  @input_types ~w(text email password search date time select textarea file color)

  @alert_colors ~w(gray info success warning danger)
  @badge_colors ~w(primary secondary info success warning danger gray)
  @tint_variants ~w(light soft dark outline)

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       nav: @nav,
       accents: @accents,
       radii: @radii,
       stars: @stars,
       variant: "outline",
       color: "primary",
       size: "md",
       icon: false,
       loading: false,
       disabled: false,
       show_code: false,
       alert: %{color: "gray", variant: "outline", icon: true, heading: false},
       badge: %{color: "primary", variant: "outline", size: "md", icon: false},
       input: %{type: "text", disabled: false, error: false, help: false},
       checkbox: %{layout: "row", disabled: false, error: false},
       select: %{disabled: false, error: false, help: false},
       radio: %{variant: "outline", size: "md", layout: "row"},
       switch: %{size: "md", disabled: false, error: false},
       otp: %{length: 6, grouped: false, pattern: "numeric", disabled: false},
       progress: %{value: 60, color: "primary", size: "md", label: "none"},
       beam: %{duration: "8s", beams: 1, reverse: false, easing: "linear", size: "60px", glow: false},
       shine: %{scheme: "mono", duration: "14s", width: "1px"},
       meteors: %{count: 20, angle: "215deg", color: "slate", reverse: false, seed: 0},
       tooltip: %{placement: "top", arrow: true},
       popover: %{placement: "bottom", top_layer: false}
     )}
  end

  # Theme state lives in the URL, so any look is shareable / screenshotable.
  def handle_params(params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:active, allow(params["c"], @slugs, "button"))
     |> assign(:accent, allow(params["accent"], @accent_names, "neutral"))
     |> assign(:radius, allow(params["radius"], @radius_labels, "10"))
     |> assign(:dark, params["dark"] == "1")}
  end

  def handle_event("select", %{"slug" => slug}, socket), do: patch_theme(socket, %{active: slug})
  def handle_event("set_accent", %{"accent" => a}, socket), do: patch_theme(socket, %{accent: a})
  def handle_event("set_radius", %{"radius" => r}, socket), do: patch_theme(socket, %{radius: r})
  def handle_event("toggle_dark", _params, socket), do: patch_theme(socket, %{dark: !socket.assigns.dark})

  def handle_event("ctl_variant", %{"v" => v}, socket) when v in ~w(solid soft light outline ghost),
    do: {:noreply, assign(socket, :variant, v)}

  def handle_event("ctl_color", %{"v" => v}, socket)
      when v in ~w(primary secondary info success warning danger gray),
      do: {:noreply, assign(socket, :color, v)}

  def handle_event("ctl_size", %{"v" => v}, socket) when v in ~w(xs sm md lg xl),
    do: {:noreply, assign(socket, :size, v)}

  def handle_event("flip", %{"k" => "icon"}, socket),
    do: {:noreply, socket |> update(:icon, &(!&1)) |> assign(:loading, false)}

  def handle_event("flip", %{"k" => "loading"}, socket),
    do: {:noreply, socket |> update(:loading, &(!&1)) |> assign(:icon, false)}
  def handle_event("flip", %{"k" => "disabled"}, socket), do: {:noreply, update(socket, :disabled, &(!&1))}
  def handle_event("flip", %{"k" => "show_code"}, socket), do: {:noreply, update(socket, :show_code, &(!&1))}

  def handle_event("ctl_input", %{"k" => "type", "v" => v}, socket) when v in @input_types,
    do: {:noreply, update(socket, :input, &%{&1 | type: v})}

  def handle_event("ctl_input", %{"k" => k}, socket) when k in ~w(disabled error help),
    do: {:noreply, update(socket, :input, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  def handle_event("ctl_progress", %{"k" => "value", "v" => v}, socket) when v in ~w(15 40 60 85 100),
    do: {:noreply, update(socket, :progress, &%{&1 | value: String.to_integer(v)})}

  def handle_event("ctl_progress", %{"k" => "color", "v" => v}, socket)
      when v in ~w(primary secondary info success warning danger gray),
      do: {:noreply, update(socket, :progress, &%{&1 | color: v})}

  def handle_event("ctl_progress", %{"k" => "size", "v" => v}, socket) when v in ~w(xs sm md lg xl),
    do: {:noreply, update(socket, :progress, &%{&1 | size: v})}

  def handle_event("ctl_progress", %{"k" => "label", "v" => v}, socket) when v in ~w(none inside top),
    do:
      {:noreply,
       update(socket, :progress, &%{&1 | label: v, size: if(v == "inside", do: "xl", else: &1.size)})}

  def handle_event("ctl_beam", %{"k" => "glow"}, socket),
    do: {:noreply, update(socket, :beam, &%{&1 | glow: !&1.glow})}

  def handle_event("ctl_meteors", %{"k" => "count", "v" => v}, socket) when v in ~w(10 20 40),
    do: {:noreply, update(socket, :meteors, &%{&1 | count: String.to_integer(v)})}

  def handle_event("ctl_meteors", %{"k" => "angle", "v" => v}, socket) when v in ~w(200deg 215deg 235deg),
    do: {:noreply, update(socket, :meteors, &%{&1 | angle: v})}

  def handle_event("ctl_meteors", %{"k" => "color", "v" => v}, socket) when v in ~w(slate sky violet),
    do: {:noreply, update(socket, :meteors, &%{&1 | color: v})}

  def handle_event("ctl_meteors", %{"k" => "reverse"}, socket),
    do: {:noreply, update(socket, :meteors, &%{&1 | reverse: !&1.reverse})}

  def handle_event("ctl_meteors", %{"k" => "shuffle"}, socket),
    do: {:noreply, update(socket, :meteors, &%{&1 | seed: &1.seed + 1})}

  def handle_event("ctl_shine", %{"k" => "scheme", "v" => v}, socket) when v in ~w(mono blend),
    do: {:noreply, update(socket, :shine, &%{&1 | scheme: v})}

  def handle_event("ctl_shine", %{"k" => "duration", "v" => v}, socket) when v in ~w(6s 14s 24s),
    do: {:noreply, update(socket, :shine, &%{&1 | duration: v})}

  def handle_event("ctl_shine", %{"k" => "width", "v" => v}, socket) when v in ~w(1px 2px 3px),
    do: {:noreply, update(socket, :shine, &%{&1 | width: v})}

  def handle_event("ctl_beam", %{"k" => "size", "v" => v}, socket) when v in ~w(40px 60px 160px),
    do: {:noreply, update(socket, :beam, &%{&1 | size: v})}

  def handle_event("ctl_beam", %{"k" => "duration", "v" => v}, socket) when v in ~w(4s 8s 12s),
    do: {:noreply, update(socket, :beam, &%{&1 | duration: v})}

  def handle_event("ctl_beam", %{"k" => "beams", "v" => v}, socket) when v in ~w(1 2 3),
    do: {:noreply, update(socket, :beam, &%{&1 | beams: String.to_integer(v)})}

  def handle_event("ctl_beam", %{"k" => "easing", "v" => v}, socket) when v in ~w(linear spring),
    do: {:noreply, update(socket, :beam, &%{&1 | easing: v})}

  def handle_event("ctl_beam", %{"k" => "reverse"}, socket),
    do: {:noreply, update(socket, :beam, &%{&1 | reverse: !&1.reverse})}

  def handle_event("ctl_tooltip", %{"k" => "placement", "v" => v}, socket) when v in ~w(top bottom left right),
    do: {:noreply, update(socket, :tooltip, &%{&1 | placement: v})}

  def handle_event("ctl_tooltip", %{"k" => "arrow"}, socket),
    do: {:noreply, update(socket, :tooltip, &%{&1 | arrow: !&1.arrow})}

  def handle_event("ctl_popover", %{"k" => "placement", "v" => v}, socket) when v in ~w(top bottom left right),
    do: {:noreply, update(socket, :popover, &%{&1 | placement: v})}

  def handle_event("ctl_popover", %{"k" => "top_layer"}, socket),
    do: {:noreply, update(socket, :popover, &%{&1 | top_layer: !&1.top_layer})}

  def handle_event("ctl_otp", %{"k" => "length", "v" => v}, socket) when v in ~w(4 6),
    do: {:noreply, update(socket, :otp, &%{&1 | length: String.to_integer(v)})}

  def handle_event("ctl_otp", %{"k" => "pattern", "v" => v}, socket) when v in ~w(numeric alphanumeric),
    do: {:noreply, update(socket, :otp, &%{&1 | pattern: v})}

  def handle_event("ctl_otp", %{"k" => k}, socket) when k in ~w(grouped disabled),
    do: {:noreply, update(socket, :otp, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  def handle_event("ctl_switch", %{"k" => "size", "v" => v}, socket) when v in ~w(xs sm md lg xl),
    do: {:noreply, update(socket, :switch, &%{&1 | size: v})}

  def handle_event("ctl_switch", %{"k" => k}, socket) when k in ~w(disabled error),
    do: {:noreply, update(socket, :switch, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  def handle_event("ctl_radio", %{"k" => "variant", "v" => v}, socket) when v in ~w(outline classic),
    do: {:noreply, update(socket, :radio, &%{&1 | variant: v})}

  def handle_event("ctl_radio", %{"k" => "size", "v" => v}, socket) when v in ~w(sm md lg),
    do: {:noreply, update(socket, :radio, &%{&1 | size: v})}

  def handle_event("ctl_radio", %{"k" => "layout", "v" => v}, socket) when v in ~w(row col),
    do: {:noreply, update(socket, :radio, &%{&1 | layout: v})}

  def handle_event("ctl_select", %{"k" => k}, socket) when k in ~w(disabled error help),
    do: {:noreply, update(socket, :select, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  def handle_event("ctl_checkbox", %{"k" => "layout", "v" => v}, socket) when v in ~w(row col),
    do: {:noreply, update(socket, :checkbox, &%{&1 | layout: v})}

  def handle_event("ctl_checkbox", %{"k" => k}, socket) when k in ~w(disabled error),
    do: {:noreply, update(socket, :checkbox, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  def handle_event("ctl_alert", %{"k" => "color", "v" => v}, socket) when v in @alert_colors,
    do: {:noreply, update(socket, :alert, &%{&1 | color: v})}

  def handle_event("ctl_alert", %{"k" => "variant", "v" => v}, socket) when v in @tint_variants,
    do: {:noreply, update(socket, :alert, &%{&1 | variant: v})}

  def handle_event("ctl_alert", %{"k" => "icon"}, socket),
    do: {:noreply, update(socket, :alert, &%{&1 | icon: !&1.icon})}

  def handle_event("ctl_alert", %{"k" => "heading"}, socket),
    do: {:noreply, update(socket, :alert, &%{&1 | heading: !&1.heading})}

  def handle_event("ctl_badge", %{"k" => "color", "v" => v}, socket) when v in @badge_colors,
    do: {:noreply, update(socket, :badge, &%{&1 | color: v})}

  def handle_event("ctl_badge", %{"k" => "variant", "v" => v}, socket) when v in @tint_variants,
    do: {:noreply, update(socket, :badge, &%{&1 | variant: v})}

  def handle_event("ctl_badge", %{"k" => "size", "v" => v}, socket) when v in ~w(xs sm md lg xl),
    do: {:noreply, update(socket, :badge, &%{&1 | size: v})}

  def handle_event("ctl_badge", %{"k" => "icon"}, socket),
    do: {:noreply, update(socket, :badge, &%{&1 | icon: !&1.icon})}

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  defp patch_theme(socket, delta) do
    theme =
      socket.assigns
      |> Map.take([:active, :accent, :radius, :dark])
      |> Map.merge(delta)

    {:noreply, push_patch(socket, to: theme_path(theme))}
  end

  defp theme_path(t) do
    []
    |> then(&if t.dark, do: [{"dark", "1"} | &1], else: &1)
    |> then(&if t.radius != "10", do: [{"radius", t.radius} | &1], else: &1)
    |> then(&if t.accent != "neutral", do: [{"accent", t.accent} | &1], else: &1)
    |> then(&if t.active != "button", do: [{"c", t.active} | &1], else: &1)
    |> case do
      [] -> "/"
      q -> "/?" <> URI.encode_query(q)
    end
  end

  defp allow(value, allowed, default), do: if(value in allowed, do: value, else: default)

  defp radius_title("0"), do: "Square corners"
  defp radius_title("10"), do: "10px — the shipped default"
  defp radius_title("full"), do: "Pill"
  defp radius_title(label), do: label <> "px"

  defp radius_css(label) do
    {_, v} = List.keyfind(@radii, label, 0) || {label, "0.625rem"}
    v
  end

  defp fmt_stars(n) when n >= 1000 do
    k = Float.round(n / 1000, 1)
    if k == trunc(k), do: "#{trunc(k)}k", else: "#{k}k"
  end

  defp fmt_stars(n), do: "#{n}"

  defp button_snippet(a) do
    attrs =
      [
        a.variant != "solid" && ~s(variant="#{a.variant}"),
        a.color != "primary" && ~s(color="#{a.color}"),
        a.size != "md" && ~s(size="#{a.size}"),
        a.icon && ~s(icon="hero-rocket-launch"),
        a.loading && "loading",
        a.disabled && "disabled"
      ]
      |> Enum.filter(& &1)

    case attrs do
      [] -> "<.button>Get started</.button>"
      _ -> "<.button #{Enum.join(attrs, " ")}>Get started</.button>"
    end
  end

  defp input_meta("text"), do: {"Full name", "Ada Lovelace"}
  defp input_meta("email"), do: {"Email address", "you@example.com"}
  defp input_meta("password"), do: {"Password", nil}
  defp input_meta("search"), do: {"Search", "Search components..."}
  defp input_meta("date"), do: {"Renewal date", nil}
  defp input_meta("time"), do: {"Meeting time", nil}
  defp input_meta("select"), do: {"Country", nil}
  defp input_meta("textarea"), do: {"Bio", "A little about you"}
  defp input_meta("file"), do: {"Avatar", nil}
  defp input_meta("color"), do: {"Brand colour", nil}

  defp field_snippet(i) do
    {label, placeholder} = input_meta(i.type)

    attrs =
      [
        i.type != "text" && ~s(type="#{i.type}"),
        ~s(name="#{i.type}"),
        ~s(label="#{label}"),
        placeholder && ~s(placeholder="#{placeholder}"),
        i.type == "select" && ~s(options={["Australia", "New Zealand", "Japan"]}),
        i.help && ~s(help_text="Shown on your public profile."),
        i.error && ~s(errors={["can't be blank"]}),
        i.disabled && "disabled"
      ]
      |> Enum.filter(& &1)

    "<.field #{Enum.join(attrs, " ")} />"
  end

  defp progress_snippet(pr) do
    attrs =
      [
        ~s(value={#{pr.value}}),
        pr.color != "primary" && ~s(color="#{pr.color}"),
        pr.size != "md" && ~s(size="#{pr.size}"),
        pr.label == "inside" && ~s(label="#{pr.value}%"),
        pr.label == "top" && ~s(label="Upload progress" label_position="top")
      ]
      |> Enum.filter(& &1)

    "<.progress #{Enum.join(attrs, " ")} />"
  end

  defp shine_colors("blend"), do: ["#f43f5e", "#8b5cf6", "#3b82f6"]
  defp shine_colors(_mono), do: "#a1a1aa"

  defp shine_snippet(sh) do
    attrs =
      [
        sh.scheme == "blend" && ~s(shine_color={["#f43f5e", "#8b5cf6", "#3b82f6"]}),
        sh.duration != "14s" && ~s(duration="#{sh.duration}"),
        sh.width != "1px" && ~s(border_width="#{sh.width}")
      ]
      |> Enum.filter(& &1)

    open = Enum.join(["<.shine_border" | attrs], " ")
    open <> ">\n  <div class=\"p-8\">...</div>\n</.shine_border>"
  end

  defp meteor_color("sky"), do: "#38bdf8"
  defp meteor_color("violet"), do: "#a78bfa"
  defp meteor_color(_slate), do: "#64748b"

  defp meteor_snippet(m) do
    attrs =
      [
        m.count != 20 && "count={#{m.count}}",
        m.angle != "215deg" && ~s(angle="#{m.angle}"),
        m.color != "slate" && ~s(color="#{meteor_color(m.color)}"),
        m.reverse && "reverse"
      ]
      |> Enum.filter(& &1)

    "<.meteors #{Enum.join(attrs, " ")} />"
  end

  defp beam_snippet(bm) do
    attrs =
      [
        bm.duration != "8s" && ~s(duration="#{bm.duration}"),
        bm.size != "60px" && ~s(size="#{bm.size}"),
        bm.glow && "glow",
        bm.beams != 1 && "beams={#{bm.beams}}",
        bm.easing != "linear" && ~s(easing="#{bm.easing}"),
        bm.reverse && "reverse"
      ]
      |> Enum.filter(& &1)

    open = Enum.join(["<.border_beam" | attrs], " ")
    open <> ">\n  <div class=\"p-8\">...</div>\n</.border_beam>"
  end

  defp tooltip_snippet(t) do
    attrs =
      [
        ~s(label="Copied to clipboard"),
        t.placement != "top" && ~s(placement="#{t.placement}"),
        !t.arrow && "arrow={false}"
      ]
      |> Enum.filter(& &1)

    "<.tooltip #{Enum.join(attrs, " ")}>\n  <.button variant=\"outline\">Hover me</.button>\n</.tooltip>"
  end

  defp popover_snippet(po) do
    attrs =
      [
        po.placement != "bottom" && ~s(placement="#{po.placement}"),
        po.top_layer && "top_layer"
      ]
      |> Enum.filter(& &1)

    open = Enum.join(["<.popover" | attrs], " ")
    open <>
      ~s( trigger_class="pc-button pc-button--primary-outline pc-button--md") <>
      ">\n  <:trigger>Open popover</:trigger>\n  Panel content here.\n</.popover>"
  end

  defp otp_snippet(o) do
    attrs =
      [
        ~s(name="code"),
        o.length != 6 && ~s(length={#{o.length}}),
        o.grouped && ~s(group_size={#{div(o.length, 2)}}),
        o.pattern != "numeric" && ~s(pattern="#{o.pattern}"),
        o.disabled && "disabled"
      ]
      |> Enum.filter(& &1)

    "<.input_otp #{Enum.join(attrs, " ")} />"
  end

  defp switch_snippet(sw) do
    attrs =
      [
        ~s(type="switch"),
        ~s(name="notifications"),
        ~s(label="Email notifications"),
        "checked",
        sw.size != "md" && ~s(size="#{sw.size}"),
        sw.error && ~s(errors={["must be enabled"]}),
        sw.disabled && "disabled"
      ]
      |> Enum.filter(& &1)

    "<.field #{Enum.join(attrs, " ")} />"
  end

  defp radio_snippet(r) do
    attrs =
      [
        ~s(type="radio-card"),
        ~s(name="plan"),
        ~s(label="Plan"),
        ~s(value="pro"),
        r.variant != "outline" && ~s(variant="#{r.variant}"),
        r.size != "md" && ~s(size="#{r.size}"),
        r.layout != "row" && ~s(group_layout="#{r.layout}"),
        ~s(options={[%{value: "starter", label: "Starter", description: "For side projects"}, ...]})
      ]
      |> Enum.filter(& &1)

    "<.field #{Enum.join(attrs, " ")} />"
  end

  defp select_snippet(sel) do
    attrs =
      [
        ~s(type="select"),
        ~s(name="country"),
        ~s(label="Country"),
        ~s(prompt="Pick a country"),
        ~s(options={["Australia", "New Zealand", "Japan"]}),
        sel.help && ~s(help_text="Where you pay tax."),
        sel.error && ~s(errors={["can't be blank"]}),
        sel.disabled && "disabled"
      ]
      |> Enum.filter(& &1)

    "<.field #{Enum.join(attrs, " ")} />"
  end

  defp checkbox_snippet(c) do
    attrs =
      [
        ~s(type="checkbox-group"),
        ~s(name="stack[]"),
        ~s(label="Stack"),
        ~s(options={[{"Phoenix", "phoenix"}, {"LiveView", "live_view"}, {"Oban", "oban"}]}),
        c.layout != "row" && ~s(group_layout="#{c.layout}"),
        c.error && ~s(errors={["pick at least one"]}),
        c.disabled && "disabled"
      ]
      |> Enum.filter(& &1)

    "<.field #{Enum.join(attrs, " ")} />"
  end

  defp alert_snippet(a) do
    attrs =
      [
        a.color != "info" && ~s(color="#{a.color}"),
        a.variant != "light" && ~s(variant="#{a.variant}"),
        a.icon && "with_icon",
        a.heading && ~s(heading="Heads up")
      ]
      |> Enum.filter(& &1)

    open = Enum.join(["<.alert" | attrs], " ")
    open <> ">Your subscription renews on 12 August.</.alert>"
  end

  defp badge_snippet(b) do
    attrs =
      [
        b.color != "primary" && ~s(color="#{b.color}"),
        b.variant != "light" && ~s(variant="#{b.variant}"),
        b.size != "md" && ~s(size="#{b.size}"),
        b.icon && "with_icon"
      ]
      |> Enum.filter(& &1)

    open = Enum.join(["<.badge" | attrs], " ")

    if b.icon do
      open <> ~s|>\n  <.icon name="hero-sparkles" class="w-3 h-3" /> New\n</.badge>|
    else
      open <> ~s( label="New" />)
    end
  end

  def render(assigns) do
    ~H"""
    <div
      class={[
        "flex flex-col h-screen bg-white text-gray-900 dark:bg-zinc-950 dark:text-zinc-50",
        @dark && "dark"
      ]}
      data-accent={@accent}
      style={"--pc-radius: #{radius_css(@radius)}"}
    >
      <header class="flex items-center justify-between flex-none px-4 border-b h-14 border-gray-200 dark:border-zinc-800">
        <div class="flex items-center gap-2 text-[15px] font-semibold">
          <svg viewBox="0 0 512 512" class="w-5 h-5" aria-hidden="true">
            <path d="M230.003 125.876C240.013 163.648 236.787 202.614 225.872 222.08C205.825 218.645 165.131 177.459 154.643 142.091C146.575 114.884 141.211 61.5546 163.147 42.9603C181.2 48.0856 206.638 59.5304 230.003 125.876Z" fill="#7C3AED" />
            <path d="M131.821 194.829C174.63 205.417 202.334 225.678 214.021 244.543C201.178 260.41 145.154 276.223 109.043 268.435C81.2645 262.444 31.9419 241.573 26.4252 213.497C39.7695 200.183 86.0939 184.721 131.821 194.829Z" fill="#8C3CE1" />
            <path d="M134.395 304.982C169.081 273.136 202.487 268.276 224.626 270.582C229.181 290.377 206.903 344.143 178.354 367.829C156.393 386.049 109.322 412.156 83.7427 399.371C81.5135 380.738 93.3967 339.963 134.395 304.982Z" fill="#9C3ED6" />
            <path d="M231.851 387.183C232.759 332.248 238.002 310.308 252.007 292.916C271.176 299.651 304.367 347.093 308.781 383.753C312.177 411.953 308.543 465.487 283.829 480.18C266.907 472.108 231.642 429.293 231.851 387.183Z" fill="#AD40C9" />
            <path d="M334.122 361.502C304.16 336.45 293.796 314.74 291.865 296.983C306.635 289.867 352.611 297.682 376.032 315.802C394.047 329.74 422.5 361.935 416.786 384.265C402.535 389.351 361.449 384.351 334.122 361.502Z" fill="#BA42BF" />
            <path d="M403.327 299.046C368.688 285.832 356.017 277.465 348.32 264.596C357.161 254.009 395.173 243.911 419.486 249.551C438.188 253.889 471.288 268.507 474.721 287.534C465.567 296.391 438.764 306.747 403.327 299.046Z" fill="#CB44B2" />
            <path d="M434.34 229.57C407.147 225.737 396.619 221.79 388.943 213.786C393.589 204.711 419.385 191.202 437.873 191.274C452.095 191.33 478.408 196.427 484.016 209.566C478.86 217.447 461.203 229.303 434.34 229.57Z" fill="#D445AB" />
          </svg>
          petal
          <span class="font-normal text-gray-400 dark:text-zinc-500">playground</span>
        </div>
        <div class="flex items-center gap-1.5">
          <button class="hidden md:flex items-center gap-2 h-8 pl-3 pr-2 mr-1 text-sm text-gray-400 border rounded-lg w-56 border-gray-200 dark:border-zinc-800 hover:bg-gray-50 dark:hover:bg-zinc-900">
            <.icon name="hero-magnifying-glass" class="w-4 h-4" />
            <span>Search components</span>
            <kbd class="pc-kbd ml-auto">⌘K</kbd>
          </button>
          <a
            href="https://github.com/petalframework/petal_components"
            target="_blank"
            class="flex items-center h-8 gap-1.5 px-2.5 text-sm rounded-lg text-gray-600 dark:text-zinc-300 hover:bg-gray-100 dark:hover:bg-zinc-900"
          >
            <svg viewBox="0 0 438.549 438.549" class="w-4 h-4" fill="currentColor"><path d="M409.132 114.573c-19.608-33.596-46.205-60.194-79.798-79.8-33.598-19.607-70.277-29.408-110.063-29.408-39.781 0-76.472 9.804-110.063 29.408-33.596 19.605-60.192 46.204-79.8 79.8C9.803 148.168 0 184.854 0 224.63c0 47.78 13.94 90.745 41.827 128.906 27.884 38.164 63.906 64.572 108.063 79.227 5.14.954 8.945.283 11.419-1.996 2.475-2.282 3.711-5.14 3.711-8.562 0-.571-.049-5.708-.144-15.417a2549.81 2549.81 0 01-.144-25.406l-6.567 1.136c-4.187.767-9.469 1.092-15.846 1-6.374-.089-12.991-.757-19.842-1.999-6.854-1.231-13.229-4.086-19.13-8.559-5.898-4.473-10.085-10.328-12.56-17.556l-2.855-6.57c-1.903-4.374-4.899-9.233-8.992-14.559-4.093-5.331-8.232-8.945-12.419-10.848l-1.999-1.431c-1.332-.951-2.568-2.098-3.711-3.429-1.142-1.331-1.997-2.663-2.568-3.997-.572-1.335-.098-2.43 1.427-3.289 1.525-.859 4.281-1.276 8.28-1.276l5.708.853c3.807.763 8.516 3.042 14.133 6.851 5.614 3.806 10.229 8.754 13.846 14.842 4.38 7.806 9.657 13.754 15.846 17.847 6.184 4.093 12.419 6.136 18.699 6.136 6.28 0 11.704-.476 16.274-1.423 4.565-.952 8.848-2.383 12.847-4.285 1.713-12.758 6.377-22.559 13.988-29.41-10.848-1.14-20.601-2.857-29.264-5.14-8.658-2.286-17.605-5.996-26.835-11.14-9.235-5.137-16.896-11.516-22.985-19.126-6.09-7.614-11.088-17.61-14.987-29.979-3.901-12.374-5.852-26.648-5.852-42.826 0-23.035 7.52-42.637 22.557-58.817-7.044-17.318-6.379-36.732 1.997-58.24 5.52-1.715 13.706-.428 24.554 3.853 10.85 4.283 18.794 7.952 23.84 10.994 5.046 3.041 9.089 5.618 12.135 7.708 17.705-4.947 35.976-7.421 54.818-7.421s37.117 2.474 54.823 7.421l10.849-6.849c7.419-4.57 16.18-8.758 26.262-12.565 10.088-3.805 17.802-4.853 23.134-3.138 8.562 21.509 9.325 40.922 2.279 58.24 15.036 16.18 22.559 35.787 22.559 58.817 0 16.178-1.958 30.497-5.853 42.966-3.9 12.471-8.941 22.457-15.125 29.979-6.191 7.521-13.901 13.85-23.131 18.986-9.232 5.14-18.182 8.85-26.84 11.136-8.662 2.286-18.415 4.004-29.263 5.146 9.894 8.562 14.842 22.077 14.842 40.539v60.237c0 3.422 1.19 6.279 3.572 8.562 2.379 2.279 6.136 2.95 11.276 1.995 44.163-14.653 80.185-41.062 108.068-79.226 27.88-38.161 41.825-81.126 41.825-128.906-.01-39.771-9.818-76.454-29.414-110.049z" /></svg>
            <span class="text-xs tabular-nums">{fmt_stars(@stars)}</span>
          </a>
          <a
            href="https://discord.com/invite/exbwVbjAct"
            target="_blank"
            aria-label="Discord"
            class="flex items-center justify-center w-8 h-8 rounded-lg text-gray-600 dark:text-zinc-300 hover:bg-gray-100 dark:hover:bg-zinc-900"
          >
            <svg viewBox="0 0 24 24" class="w-4 h-4" fill="currentColor"><path d="M20.317 4.37a19.79 19.79 0 0 0-4.885-1.515a.074.074 0 0 0-.079.037c-.21.375-.444.865-.608 1.25a18.27 18.27 0 0 0-5.487 0a12.64 12.64 0 0 0-.617-1.25a.077.077 0 0 0-.079-.037A19.74 19.74 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057a19.9 19.9 0 0 0 5.993 3.03a.078.078 0 0 0 .084-.028a14.09 14.09 0 0 0 1.226-1.994a.076.076 0 0 0-.041-.106a13.107 13.107 0 0 1-1.872-.892a.077.077 0 0 1-.008-.128a10.2 10.2 0 0 0 .372-.292a.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127a12.299 12.299 0 0 1-1.873.892a.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028a19.839 19.839 0 0 0 6.002-3.03a.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419c0-1.333.956-2.419 2.157-2.419c1.21 0 2.176 1.096 2.157 2.42c0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419c0-1.333.955-2.419 2.157-2.419c1.21 0 2.176 1.096 2.157 2.42c0 1.333-.946 2.418-2.157 2.418z" /></svg>
          </a>
          <a
            href="https://x.com/PetalFramework"
            target="_blank"
            aria-label="X"
            class="flex items-center justify-center w-8 h-8 rounded-lg text-gray-600 dark:text-zinc-300 hover:bg-gray-100 dark:hover:bg-zinc-900"
          >
            <svg viewBox="0 0 24 24" class="w-3.5 h-3.5" fill="currentColor"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" /></svg>
          </a>
          <button
            phx-click={JS.dispatch("pg:theme-switch") |> JS.push("toggle_dark")}
            aria-label="Toggle dark mode"
            class="flex items-center justify-center w-8 h-8 rounded-lg text-gray-600 dark:text-zinc-300 hover:bg-gray-100 dark:hover:bg-zinc-900"
          >
            <.icon :if={@dark} name="hero-sun" class="w-4 h-4" />
            <.icon :if={!@dark} name="hero-moon" class="w-3.5 h-3.5" />
          </button>
        </div>
      </header>

      <div class="flex items-center flex-none h-11 gap-5 px-4 border-b border-gray-200 dark:border-zinc-800 bg-gray-50/60 dark:bg-zinc-900/30">
        <div class="flex items-center gap-2.5">
          <span class="text-[11px] font-medium text-gray-400 dark:text-zinc-500">accent</span>
          <div class="flex items-center gap-1.5">
            <button
              :for={{name, css} <- @accents}
              phx-click="set_accent"
              phx-value-accent={name}
              aria-label={name}
              class={[
                "w-4.5 h-4.5 rounded-full transition-transform hover:scale-110",
                @accent == name &&
                  "ring-2 ring-offset-2 ring-gray-400 dark:ring-zinc-500 ring-offset-gray-50 dark:ring-offset-zinc-950"
              ]}
              style={"background:#{css}"}
            >
            </button>
          </div>
        </div>
        <div class="flex items-center gap-2.5">
          <span class="text-[11px] font-medium text-gray-400 dark:text-zinc-500">radius</span>
          <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
            <button
              :for={{label, _value} <- @radii}
              phx-click="set_radius"
              phx-value-radius={label}
              title={radius_title(label)}
              class={seg(@radius == label)}
            >
              {label}
            </button>
          </div>
        </div>
        <span class="hidden ml-auto text-[11px] text-gray-400 dark:text-zinc-600 sm:block">
          theme is in the URL, share the look
        </span>
      </div>

      <div class="flex flex-1 min-h-0">
        <nav class="flex-none p-3 overflow-y-auto border-r w-52 border-gray-200 dark:border-zinc-800">
          <div :for={grp <- @nav}>
            <div class="px-2 pt-4 pb-1 text-[11px] font-medium tracking-wide text-gray-400 dark:text-zinc-500">
              {grp.group}
            </div>
            <button
              :for={it <- grp.items}
              phx-click="select"
              phx-value-slug={it.slug}
              class={[
                "w-full flex items-center px-2.5 py-1.5 rounded-lg text-sm text-left transition-colors",
                (@active == it.slug &&
                   "bg-gray-100 dark:bg-zinc-800 text-gray-900 dark:text-zinc-50 font-medium") ||
                  "text-gray-600 dark:text-zinc-400 hover:bg-gray-50 dark:hover:bg-zinc-900 hover:text-gray-900 dark:hover:text-zinc-100"
              ]}
            >
              {it.name}
              <span
                :if={not it.ready}
                class="ml-auto text-[10px] px-1.5 py-0.5 rounded bg-gray-100 dark:bg-zinc-800/80 text-gray-400 dark:text-zinc-500"
              >
                soon
              </span>
            </button>
          </div>
        </nav>

        <main class="flex-1 overflow-y-auto">
          {render_page(assigns)}
        </main>
      </div>
    </div>
    """
  end

  defp render_page(%{active: "button"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Button</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        Triggers an action. Five variants, plus a semantic range for when the action carries meaning.
        Accent and radius follow the rail above.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex items-center justify-center px-6 py-14">
          <.button
            variant={@variant}
            color={@color}
            size={@size}
            icon={if @icon, do: "hero-rocket-launch"}
            loading={@loading}
            disabled={@disabled}
          >
            Get started
          </.button>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-zinc-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">colour</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={c <- ~w(primary secondary info success warning danger gray)}
                phx-click="ctl_color"
                phx-value-v={c}
                class={seg(@color == c)}
              >
                {c}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={v <- ~w(solid soft light outline ghost)}
                phx-click="ctl_variant"
                phx-value-v={v}
                class={seg(@variant == v)}
              >
                {v}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={s <- ~w(xs sm md lg xl)}
                phx-click="ctl_size"
                phx-value-v={s}
                class={seg(@size == s)}
              >
                {s}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">state</div>
            <div class="flex gap-1.5">
              <button phx-click="flip" phx-value-k="icon" class={tog(@icon)}>icon</button>
              <button phx-click="flip" phx-value-k="loading" class={tog(@loading)}>loading</button>
              <button phx-click="flip" phx-value-k="disabled" class={tog(@disabled)}>disabled</button>
            </div>
          </div>
        </div>
        <p
          :if={@variant in ~w(outline ghost) and @color in ~w(primary secondary gray)}
          class="px-6 pb-3 -mt-1 text-xs text-gray-400 dark:text-zinc-500"
        >
          outline and ghost render neutral chrome for brand colours, so the accent dial won't change them - pick a semantic colour to tint
        </p>
      </div>

      <button
        phx-click="flip"
        phx-value-k="show_code"
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-zinc-900 rounded-xl dark:border dark:border-zinc-800"
      ><code>{button_snippet(assigns)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Variants</div>
      <div class="flex flex-wrap items-center justify-center gap-3 px-6 py-10 border border-gray-200 rounded-xl dark:border-zinc-800">
        <.button>Solid</.button>
        <.button variant="soft">Soft</.button>
        <.button variant="light">Light</.button>
        <.button variant="outline">Outline</.button>
        <.button variant="ghost">Ghost</.button>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Semantic colours</div>
      <div class="flex flex-wrap items-center justify-center gap-3 px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <.button color="info" variant={@variant}>Info</.button>
        <.button color="success" variant={@variant}>Success</.button>
        <.button color="warning" variant={@variant}>Warning</.button>
        <.button color="danger" variant={@variant}>Danger</.button>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Sizes</div>
      <div class="flex flex-wrap items-center justify-center gap-3 px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <.button size="xs">Extra small</.button>
        <.button size="sm">Small</.button>
        <.button size="md">Medium</.button>
        <.button size="lg">Large</.button>
        <.button size="xl">Extra large</.button>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">States</div>
      <div class="flex flex-wrap items-center justify-center gap-3 px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <.button>Default</.button>
        <.button icon="hero-rocket-launch">With icon</.button>
        <.button loading>Loading</.button>
        <.button disabled>Disabled</.button>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Icon button</div>
      <div class="flex flex-wrap items-center justify-center gap-3 px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <.button size="icon" aria-label="Submit">
          <.icon name="hero-arrow-up" class="w-5 h-5" />
        </.button>
        <.button variant="outline" size="icon" aria-label="Add">
          <.icon name="hero-plus" class="w-5 h-5" />
        </.button>
        <.button variant="ghost" size="icon" aria-label="Settings">
          <.icon name="hero-cog-6-tooth" class="w-5 h-5" />
        </.button>
      </div>
    </div>
    """
  end



  defp render_page(%{active: "input"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Input</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        One field surface for every type: label, control, help and error.
        Border, radius and focus ring follow the rail above.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex items-center justify-center px-6 py-12">
          <div class="w-full max-w-sm">
            <.field
              :if={@input.type == "select"}
              type="select"
              name="pg_country"
              label="Country"
              value=""
              prompt="Pick a country"
              options={["Australia", "New Zealand", "Japan"]}
              disabled={@input.disabled}
              errors={if @input.error, do: ["can't be blank"], else: []}
              help_text={if @input.help, do: "Shown on your public profile."}
              no_margin
            />
            <.field
              :if={@input.type == "textarea"}
              type="textarea"
              name="pg_bio"
              label="Bio"
              value=""
              placeholder="A little about you"
              disabled={@input.disabled}
              errors={if @input.error, do: ["can't be blank"], else: []}
              help_text={if @input.help, do: "Shown on your public profile."}
              no_margin
            />
            <.field
              :if={@input.type not in ~w(select textarea)}
              type={@input.type}
              name={"pg_" <> @input.type}
              label={elem(input_meta(@input.type), 0)}
              value=""
              placeholder={elem(input_meta(@input.type), 1)}
              disabled={@input.disabled}
              errors={if @input.error, do: ["can't be blank"], else: []}
              help_text={if @input.help, do: "Shown on your public profile."}
              no_margin
            />
          </div>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-zinc-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">type</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={t <- ~w(text email password search date time select textarea file color)}
                phx-click="ctl_input"
                phx-value-k="type"
                phx-value-v={t}
                class={seg(@input.type == t)}
              >
                {t}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">state</div>
            <div class="flex gap-1.5">
              <button phx-click="ctl_input" phx-value-k="help" class={tog(@input.help)}>help</button>
              <button phx-click="ctl_input" phx-value-k="error" class={tog(@input.error)}>error</button>
              <button phx-click="ctl_input" phx-value-k="disabled" class={tog(@input.disabled)}>disabled</button>
            </div>
          </div>
        </div>
      </div>

      <button
        phx-click="flip"
        phx-value-k="show_code"
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-zinc-900 rounded-xl dark:border dark:border-zinc-800"
      ><code>{field_snippet(@input)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Anatomy</div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="max-w-sm mx-auto">
          <.field
            type="email"
            name="anatomy_email"
            label="Email address"
            value=""
            placeholder="you@example.com"
            help_text="We only use this for receipts."
            no_margin
          />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Error state</div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="max-w-sm mx-auto">
          <.field
            type="email"
            name="error_email"
            label="Email address"
            value="not-an-email"
            errors={["must include an @ sign"]}
            no_margin
          />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">In-field actions</div>
      <div class="px-6 py-8 space-y-6 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="max-w-sm mx-auto space-y-6">
          <.field type="password" name="pw_viewable" label="Password (viewable)" value="hunter2hunter2" viewable no_margin />
          <.field type="text" name="api_key" label="API key (copyable)" value="pk_live_51J8s0" copyable no_margin />
          <.field type="search" name="q" label="Search (clearable)" value="petal components" clearable no_margin />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Input group</div>
      <div class="px-6 py-8 space-y-6 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="max-w-sm mx-auto space-y-6">
          <.input_group>
            <:leading>https://</:leading>
            <.input type="text" name="ig_domain" value="" placeholder="example.com" />
          </.input_group>
          <.input_group>
            <:leading>$</:leading>
            <.input type="number" name="ig_amount" value="" placeholder="0.00" />
            <:trailing>USD</:trailing>
          </.input_group>
          <.input_group>
            <:leading><.icon name="hero-magnifying-glass" class="w-4 h-4" /></:leading>
            <.input type="search" name="ig_q" value="" placeholder="Search components..." />
            <:trailing><kbd>&#8984;K</kbd></:trailing>
          </.input_group>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Select and checkbox</div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="max-w-sm mx-auto">
          <.field
            type="select"
            name="plan"
            label="Plan"
            value="Pro"
            options={["Free", "Pro", "Team"]}
            no_margin
          />
          <div class="mt-6">
            <.field type="checkbox" name="tos" label="I agree to the terms" checked no_margin />
          </div>
        </div>
      </div>
    </div>
    """
  end











  defp render_page(%{active: "border-beam"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Border beam</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        A light beam tracing the border - pure CSS on an offset-path, with the
        tail fading smoothly around corners at any aspect ratio. The panel
        follows the rail radius.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex items-center justify-center px-6 py-14">
          <.border_beam
            id={"pg-beam-#{@beam.duration}-#{@beam.beams}-#{@beam.reverse}-#{@beam.easing}-#{@beam.glow}"}
            duration={@beam.duration}
            beams={@beam.beams}
            reverse={@beam.reverse}
            easing={@beam.easing}
            size={@beam.size}
            glow={@beam.glow}
            class="w-full max-w-sm"
          >
            <div class="p-8">
              <div class="text-xs font-medium tracking-wide uppercase text-gray-400">Launch</div>
              <div class="mt-2 text-lg font-semibold text-gray-900 dark:text-gray-100">
                4.4.0 is coming
              </div>
              <p class="mt-1 text-sm text-gray-500 dark:text-zinc-400">
                Theme tokens, one surface system, and the forms overhaul.
              </p>
            </div>
          </.border_beam>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-zinc-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">duration</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={d <- ~w(4s 8s 12s)}
                phx-click="ctl_beam"
                phx-value-k="duration"
                phx-value-v={d}
                class={seg(@beam.duration == d)}
              >
                {d}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">beams</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={n <- ~w(1 2 3)}
                phx-click="ctl_beam"
                phx-value-k="beams"
                phx-value-v={n}
                class={seg(to_string(@beam.beams) == n)}
              >
                {n}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">length</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={{lbl, v} <- [{"sm", "40px"}, {"md", "60px"}, {"lg", "160px"}]}
                phx-click="ctl_beam"
                phx-value-k="size"
                phx-value-v={v}
                class={seg(@beam.size == v)}
              >
                {lbl}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">motion</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={e <- ~w(linear spring)}
                phx-click="ctl_beam"
                phx-value-k="easing"
                phx-value-v={e}
                class={seg(@beam.easing == e)}
              >
                {e}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <div class="flex gap-1.5">
              <button phx-click="ctl_beam" phx-value-k="glow" class={tog(@beam.glow)}>glow</button>
              <button phx-click="ctl_beam" phx-value-k="reverse" class={tog(@beam.reverse)}>
                reverse
              </button>
            </div>
          </div>
        </div>
        <p
          :if={@beam.easing == "spring" and @beam.beams > 1}
          class="px-6 pb-3 -mt-1 text-xs text-gray-400 dark:text-zinc-500"
        >
          spring is a single-beam motion - with multiple beams the chase runs at constant speed
        </p>
        <p
          :if={@beam.size == "160px" and not @beam.glow}
          class="px-6 pb-3 -mt-1 text-xs text-gray-400 dark:text-zinc-500"
        >
          a long sharp beam clamps to the panel for corner safety - turn on glow for the full length
        </p>
      </div>

      <button
        phx-click="flip"
        phx-value-k="show_code"
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-zinc-900 rounded-xl dark:border dark:border-zinc-800"
      ><code>{beam_snippet(@beam)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">
        Now playing (two long glow beams)
      </div>
      <div class="px-6 py-14 border border-gray-200 rounded-xl dark:border-zinc-800">
        <.border_beam
          glow
          beams={2}
          size="400px"
          duration="9s"
          color_from="#f43f5e"
          color_to="#3b82f6"
          class="w-full max-w-sm mx-auto"
        >
          <div class="p-6">
            <div class="font-semibold leading-none text-gray-900 dark:text-gray-100">
              Now playing
            </div>
            <div class="mt-1.5 text-sm text-gray-500 dark:text-zinc-400">
              Stairway to Heaven - Led Zeppelin
            </div>
            <div class="w-40 h-40 mx-auto mt-5 rounded-lg bg-gradient-to-br from-purple-500 to-pink-500">
            </div>
            <div class="mt-5">
              <.progress value={34} size="xs" />
            </div>
            <div class="flex justify-between mt-2 text-sm text-gray-500 dark:text-zinc-400">
              <span>2:45</span><span>8:02</span>
            </div>
            <div class="flex justify-center gap-3 mt-4">
              <.button variant="outline" size="icon" radius="full" aria-label="Previous">
                <.icon name="hero-backward" />
              </.button>
              <.button size="icon" radius="full" aria-label="Play">
                <.icon name="hero-play" />
              </.button>
              <.button variant="outline" size="icon" radius="full" aria-label="Next">
                <.icon name="hero-forward" />
              </.button>
            </div>
          </div>
        </.border_beam>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">
        Spring release (a button-sized lap)
      </div>
      <div class="px-6 py-14 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex justify-center">
          <.border_beam
            glow
            easing="spring"
            duration="3s"
            size="60px"
            color_from="#eab308"
            color_to="#eab308"
            class="inline-block"
          >
            <div class="px-6 py-2.5 text-sm font-medium text-gray-900 dark:text-gray-100">
              Buy now
            </div>
          </.border_beam>
        </div>
      </div>

    </div>
    """
  end

  defp render_page(%{active: "shine-border"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Shine border</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        A slow, ambient shimmer sweeping the border - the quiet sibling of the
        border beam. Pure CSS, and it holds still for reduced-motion users.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex items-center justify-center px-6 py-14">
          <.shine_border
            shine_color={shine_colors(@shine.scheme)}
            duration={@shine.duration}
            border_width={@shine.width}
            class="w-full max-w-sm"
          >
            <div class="p-8">
              <div class="text-lg font-semibold text-gray-900 dark:text-gray-100">
                Upgrade to Pro
              </div>
              <p class="mt-1 text-sm text-gray-500 dark:text-zinc-400">
                Unlimited projects and priority support.
              </p>
            </div>
          </.shine_border>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-zinc-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">colour</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={c <- ~w(mono blend)}
                phx-click="ctl_shine"
                phx-value-k="scheme"
                phx-value-v={c}
                class={seg(@shine.scheme == c)}
              >
                {c}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">sweep</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={{lbl, v} <- [{"fast", "6s"}, {"med", "14s"}, {"slow", "24s"}]}
                phx-click="ctl_shine"
                phx-value-k="duration"
                phx-value-v={v}
                class={seg(@shine.duration == v)}
              >
                {lbl}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">width</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={w <- ~w(1px 2px 3px)}
                phx-click="ctl_shine"
                phx-value-k="width"
                phx-value-v={w}
                class={seg(@shine.width == w)}
              >
                {w}
              </button>
            </div>
          </div>
        </div>
      </div>

      <button
        phx-click="flip"
        phx-value-k="show_code"
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-zinc-900 rounded-xl dark:border dark:border-zinc-800"
      ><code>{shine_snippet(@shine)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">
        On an input (thicker border)
      </div>
      <div class="px-6 py-14 border border-gray-200 rounded-xl dark:border-zinc-800">
        <.shine_border shine_color="#3b82f6" border_width="2px" class="w-full max-w-sm mx-auto">
          <input
            type="text"
            value="magic search..."
            class="w-full px-4 py-2.5 text-sm bg-transparent border-0 focus:outline-hidden text-gray-900 dark:text-gray-100"
          />
        </.shine_border>
      </div>
    </div>
    """
  end

  defp render_page(%{active: "meteors"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Meteors</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        A meteor shower inside any container - positions generated server-side,
        so it costs zero JavaScript and never jumps on re-render.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="px-6 py-8">
          <div class="relative w-full overflow-hidden bg-zinc-950 rounded-xl h-56">
            <.meteors
              count={@meteors.count}
              angle={@meteors.angle}
              color={meteor_color(@meteors.color)}
              reverse={@meteors.reverse}
              seed={@meteors.seed}
            />
            <div class="relative flex flex-col items-center justify-center h-full text-center">
              <div class="text-lg font-semibold text-white">Ship something tonight</div>
              <div class="mt-1 text-sm text-zinc-400">Meteors sit behind your content.</div>
            </div>
          </div>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-zinc-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">count</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={n <- ~w(10 20 40)}
                phx-click="ctl_meteors"
                phx-value-k="count"
                phx-value-v={n}
                class={seg(to_string(@meteors.count) == n)}
              >
                {n}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">angle</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={{lbl, v} <- [{"shallow", "200deg"}, {"default", "215deg"}, {"steep", "235deg"}]}
                phx-click="ctl_meteors"
                phx-value-k="angle"
                phx-value-v={v}
                class={seg(@meteors.angle == v)}
              >
                {lbl}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">colour</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={c <- ~w(slate sky violet)}
                phx-click="ctl_meteors"
                phx-value-k="color"
                phx-value-v={c}
                class={seg(@meteors.color == c)}
              >
                {c}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <div class="flex gap-1.5">
              <button phx-click="ctl_meteors" phx-value-k="reverse" class={tog(@meteors.reverse)}>
                reverse
              </button>
              <button phx-click="ctl_meteors" phx-value-k="shuffle" class={tog(false)}>shuffle</button>
            </div>
          </div>
        </div>
      </div>

      <button
        phx-click="flip"
        phx-value-k="show_code"
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-zinc-900 rounded-xl dark:border dark:border-zinc-800"
      ><code>{meteor_snippet(@meteors)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">
        Deterministic (same seed, same sky)
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="relative w-full max-w-lg mx-auto overflow-hidden border border-gray-200 rounded-xl h-40 dark:border-zinc-800 dark:bg-zinc-900">
          <.meteors count={8} seed={42} />
        </div>
      </div>
    </div>
    """
  end

  defp render_page(%{active: "typography"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Typography</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        The refined 4.2 scale: self-composing vertical rhythm, balanced
        headings, and a three-tier emphasis system that holds in both modes.
      </p>

      <div class="mt-8 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Headings</div>
      <div class="px-8 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <.h1>The quick brown fox</.h1>
        <.h2>The quick brown fox</.h2>
        <.h3>The quick brown fox</.h3>
        <.h4>The quick brown fox</.h4>
        <.h5>The quick brown fox</.h5>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">
        Body and emphasis tiers
      </div>
      <div class="px-8 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <.lead>
          A lead paragraph sits between heading and body - one size up, muted a step.
        </.lead>
        <.p>
          Default body copy carries the middle emphasis tier. It pairs
          <.inline_code>inline_code</.inline_code>
          with <strong>strong text</strong> at the top tier, and stays readable
          across light and dark without per-mode overrides.
        </.p>
        <.text_muted>Muted text is the quiet tier - captions, hints, timestamps.</.text_muted>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Structure</div>
      <div class="px-8 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <.blockquote>
          Design is the silent ambassador of your brand.
        </.blockquote>
        <.ul class="mt-6">
          <li>Unordered lists keep the body rhythm</li>
          <li>With markers in the muted tier</li>
        </.ul>
        <.hr class="my-6" />
        <.ol>
          <li>Ordered lists number in tabular figures</li>
          <li>So multi-digit lists stay aligned</li>
        </.ol>
      </div>
    </div>
    """
  end

  defp render_page(%{active: "colors"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Colours</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        Four roles: primary follows the accent rail, secondary is your second
        brand hue, semantics carry meaning, gray is the chrome. Filled
        variants take colour; transparent variants stay neutral.
      </p>

      <div class="mt-8 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">
        Primary (accent-driven - try the rail)
      </div>
      <div class="px-6 py-6 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex overflow-hidden rounded-lg">
          <div
            :for={stop <- ~w(50 100 200 300 400 500 600 700 800 900 950)}
            class="flex-1 h-14"
            style={"background-color: var(--color-primary-#{stop})"}
            title={"primary-#{stop}"}
          >
          </div>
        </div>
        <div class="flex mt-1.5 text-[10px] text-gray-400">
          <div :for={stop <- ~w(50 100 200 300 400 500 600 700 800 900 950)} class="flex-1 text-center">
            {stop}
          </div>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">
        Semantic ramps (fixed hues)
      </div>
      <div class="px-6 py-6 space-y-3 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div :for={c <- ~w(info success warning danger)} class="flex items-center gap-3">
          <div class="w-16 text-xs text-gray-500 dark:text-zinc-400">{c}</div>
          <div class="flex flex-1 overflow-hidden rounded-lg">
            <div
              :for={stop <- ~w(50 100 200 300 400 500 600 700 800 900 950)}
              class="flex-1 h-8"
              style={"background-color: var(--color-#{c}-#{stop})"}
              title={"#{c}-#{stop}"}
            >
            </div>
          </div>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">
        Gray (zinc) - the chrome family
      </div>
      <div class="px-6 py-6 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex overflow-hidden rounded-lg">
          <div
            :for={stop <- ~w(50 100 200 300 400 500 600 700 800 900 950)}
            class="flex-1 h-14"
            style={"background-color: var(--color-gray-#{stop})"}
            title={"gray-#{stop}"}
          >
          </div>
        </div>
        <div class="flex mt-1.5 text-[10px] text-gray-400">
          <div :for={stop <- ~w(50 100 200 300 400 500 600 700 800 900 950)} class="flex-1 text-center">
            {stop}
          </div>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-zinc-800 dark:text-zinc-400">
        Secondary maps to your second brand hue in app config (pink in this
        playground). The surface tokens - washes at 500/15, borders at 600/30
        light and 500/40 dark, solids at 600 - are derived from these ramps,
        which is why one accent swap restyles every component.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "dropdown"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Dropdown</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        Menus on the floating-panel surface: group labels, separators, icons,
        keyboard hints and destructive items. Triggers follow the rail radius.
      </p>

      <div class="mt-8 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Account menu</div>
      <div class="px-6 pt-10 border border-gray-200 rounded-xl dark:border-zinc-800 pb-72">
        <div class="flex justify-center">
          <.dropdown label="you@example.com">
            <.dropdown_menu_label>My account</.dropdown_menu_label>
            <.dropdown_menu_item link_type="button">
              <.icon name="hero-user" class="w-4 h-4" /> Profile
              <kbd class="pc-kbd ml-auto">&#8679;&#8984;P</kbd>
            </.dropdown_menu_item>
            <.dropdown_menu_item link_type="button">
              <.icon name="hero-credit-card" class="w-4 h-4" /> Billing
            </.dropdown_menu_item>
            <.dropdown_menu_item link_type="button">
              <.icon name="hero-cog-6-tooth" class="w-4 h-4" /> Settings
              <kbd class="pc-kbd ml-auto">&#8984;,</kbd>
            </.dropdown_menu_item>
            <.dropdown_menu_separator />
            <.dropdown_menu_label>Team</.dropdown_menu_label>
            <.dropdown_menu_item link_type="button">
              <.icon name="hero-user-plus" class="w-4 h-4" /> Invite members
            </.dropdown_menu_item>
            <.dropdown_menu_item link_type="button" disabled>
              <.icon name="hero-plus" class="w-4 h-4" /> New team (Pro)
            </.dropdown_menu_item>
            <.dropdown_menu_separator />
            <.dropdown_menu_item link_type="button" class="text-danger-600 dark:text-danger-400">
              <.icon name="hero-arrow-right-start-on-rectangle" class="w-4 h-4" /> Sign out
              <kbd class="pc-kbd ml-auto">&#8679;&#8984;Q</kbd>
            </.dropdown_menu_item>
          </.dropdown>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">
        Row actions (ellipsis trigger) and a custom trigger
      </div>
      <div class="px-6 pt-10 border border-gray-200 rounded-xl dark:border-zinc-800 pb-56">
        <div class="flex items-start justify-center gap-16">
          <.dropdown>
            <.dropdown_menu_item link_type="button">
              <.icon name="hero-pencil-square" class="w-4 h-4" /> Edit
              <kbd class="pc-kbd ml-auto">&#8984;E</kbd>
            </.dropdown_menu_item>
            <.dropdown_menu_item link_type="button">
              <.icon name="hero-document-duplicate" class="w-4 h-4" /> Duplicate
              <kbd class="pc-kbd ml-auto">&#8984;D</kbd>
            </.dropdown_menu_item>
            <.dropdown_menu_item link_type="button">
              <.icon name="hero-archive-box" class="w-4 h-4" /> Archive
            </.dropdown_menu_item>
            <.dropdown_menu_separator />
            <.dropdown_menu_item link_type="button" class="text-danger-600 dark:text-danger-400">
              <.icon name="hero-trash" class="w-4 h-4" /> Delete
              <kbd class="pc-kbd ml-auto">&#8984;&#9003;</kbd>
            </.dropdown_menu_item>
          </.dropdown>
          <.dropdown placement="right" trigger_class="pc-button pc-button--primary-outline pc-button--md">
            <:trigger_element>
              Move to project <.icon name="hero-chevron-down" class="w-4 h-4 ml-1" />
            </:trigger_element>
            <.dropdown_menu_label>Recent</.dropdown_menu_label>
            <.dropdown_menu_item link_type="button">petal_components</.dropdown_menu_item>
            <.dropdown_menu_item link_type="button">petal_pro</.dropdown_menu_item>
            <.dropdown_menu_item link_type="button">marketing site</.dropdown_menu_item>
          </.dropdown>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-zinc-800 dark:text-zinc-400">
        The default trigger is a labelled outline button (or a ghost ellipsis
        with no label) - both follow the rail radius. Items are links or
        buttons (a / live_patch / live_redirect / button) and take arbitrary
        content: icons, .pc-kbd hints, custom classes for destructive actions.
        dropdown_menu_label and dropdown_menu_separator organise groups.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "modal"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Modal</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        Dialog on the panel surface with a proper scrim. Escape and
        click-away close it; the box radius scales gently with the rail.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex items-center justify-center px-6 py-16">
          <.button variant="outline" phx-click={show_modal("pg-modal")}>
            Open modal
          </.button>
        </div>
      </div>

      <.modal id="pg-modal" title="Invite your team" hide max_width="sm">
        <p class="text-sm text-gray-500 dark:text-zinc-400">
          Share this link with your teammates and they'll join the workspace
          with member access.
        </p>
        <div class="mt-4">
          <.input_group>
            <.input type="text" name="invite_url" value="https://petal.build/join/x1y2z3" readonly />
            <:trailing><kbd>&#8984;C</kbd></:trailing>
          </.input_group>
        </div>
        <div class="flex justify-end gap-2 mt-6">
          <.button variant="outline" phx-click={hide_modal("pg-modal")}>Cancel</.button>
          <.button phx-click={hide_modal("pg-modal")}>Copy link</.button>
        </div>
      </.modal>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-zinc-800 dark:text-zinc-400">
        show_modal/1 and hide_modal/1 are plain LiveView.JS commands - wire them
        to any phx-click. close_on_click_away and close_on_escape default on.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "progress"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Progress</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        Determinate progress on a washed track. The bar animates between
        values - click the value control and watch it move.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex items-center justify-center px-6 py-16">
          <div class="w-full max-w-md">
            <.progress
              value={@progress.value}
              color={@progress.color}
              size={@progress.size}
              label={
                case @progress.label do
                  "inside" -> "#{@progress.value}%"
                  "top" -> "Upload progress"
                  _ -> nil
                end
              }
              label_position={if @progress.label == "top", do: "top", else: "inside"}
            />
          </div>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-zinc-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">value</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={v <- ~w(15 40 60 85 100)}
                phx-click="ctl_progress"
                phx-value-k="value"
                phx-value-v={v}
                class={seg(to_string(@progress.value) == v)}
              >
                {v}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">colour</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={c <- ~w(primary secondary info success warning danger gray)}
                phx-click="ctl_progress"
                phx-value-k="color"
                phx-value-v={c}
                class={seg(@progress.color == c)}
              >
                {c}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={z <- ~w(xs sm md lg xl)}
                phx-click="ctl_progress"
                phx-value-k="size"
                phx-value-v={z}
                class={seg(@progress.size == z)}
              >
                {z}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">label</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={l <- ~w(none inside top)}
                phx-click="ctl_progress"
                phx-value-k="label"
                phx-value-v={l}
                class={seg(@progress.label == l)}
              >
                {l}
              </button>
            </div>
          </div>
        </div>
      </div>

      <button
        phx-click="flip"
        phx-value-k="show_code"
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-zinc-900 rounded-xl dark:border dark:border-zinc-800"
      ><code>{progress_snippet(@progress)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Semantic colours</div>
      <div class="px-6 py-8 space-y-4 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="max-w-md mx-auto space-y-4">
          <.progress value={80} color="success" />
          <.progress value={55} color="info" />
          <.progress value={35} color="warning" />
          <.progress value={15} color="danger" />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Sizes</div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="max-w-md mx-auto space-y-4">
          <.progress :for={z <- ~w(xs sm md lg)} value={60} size={z} />
          <.progress value={60} size="xl" label="60%" />
          <.progress value={56} size="sm" label="Upload progress" label_position="top" />
        </div>
      </div>
    </div>
    """
  end

  defp render_page(%{active: "tooltip"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Tooltip</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        A label on hover or keyboard focus. Pure CSS - no JS, no dependencies.
        The bubble inverts against the page in both modes.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex items-center justify-center px-6 py-16">
          <.tooltip
            label="Copied to clipboard"
            placement={@tooltip.placement}
            arrow={@tooltip.arrow}
          >
            <.button variant="outline">Hover me</.button>
          </.tooltip>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-zinc-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">placement</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={pl <- ~w(top bottom left right)}
                phx-click="ctl_tooltip"
                phx-value-k="placement"
                phx-value-v={pl}
                class={seg(@tooltip.placement == pl)}
              >
                {pl}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <div class="flex gap-1.5">
              <button phx-click="ctl_tooltip" phx-value-k="arrow" class={tog(@tooltip.arrow)}>arrow</button>
            </div>
          </div>
        </div>
      </div>

      <button
        phx-click="flip"
        phx-value-k="show_code"
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-zinc-900 rounded-xl dark:border dark:border-zinc-800"
      ><code>{tooltip_snippet(@tooltip)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">
        Icon buttons (the classic use)
      </div>
      <div class="px-6 py-12 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex items-center justify-center gap-3">
          <.tooltip label="Bold">
            <.button variant="ghost" size="icon" aria-label="Bold"><.icon name="hero-bold" /></.button>
          </.tooltip>
          <.tooltip label="Italic">
            <.button variant="ghost" size="icon" aria-label="Italic"><.icon name="hero-italic" /></.button>
          </.tooltip>
          <.tooltip label="Link">
            <.button variant="ghost" size="icon" aria-label="Link"><.icon name="hero-link" /></.button>
          </.tooltip>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Rich content</div>
      <div class="px-6 py-12 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex items-center justify-center">
          <.tooltip placement="bottom">
            <:content>
              <span class="font-semibold">Deploys locked</span><br />ask in #releases to unlock
            </:content>
            <.badge color="warning" label="Locked" />
          </.tooltip>
        </div>
      </div>
    </div>
    """
  end

  defp render_page(%{active: "popover"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Popover</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        Click-to-open panel with light dismiss. Optional top_layer mode uses the
        native popover API to escape clipped containers.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex items-center justify-center px-6 py-20">
          <.popover
            id={"pg-popover-#{@popover.placement}-#{@popover.top_layer}"}
            placement={@popover.placement}
            top_layer={@popover.top_layer}
            trigger_class="pc-button pc-button--primary-outline pc-button--md"
          >
            <:trigger>Open popover</:trigger>
            <div class="max-w-56">
              <div class="text-sm font-semibold">Dimensions</div>
              <p class="mt-1 text-sm text-gray-500 dark:text-zinc-400">
                Set the width and height for the layer.
              </p>
            </div>
          </.popover>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-zinc-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">placement</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={pl <- ~w(top bottom left right)}
                phx-click="ctl_popover"
                phx-value-k="placement"
                phx-value-v={pl}
                class={seg(@popover.placement == pl)}
              >
                {pl}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <div class="flex gap-1.5">
              <button phx-click="ctl_popover" phx-value-k="top_layer" class={tog(@popover.top_layer)}>
                top_layer
              </button>
            </div>
          </div>
        </div>
      </div>

      <button
        phx-click="flip"
        phx-value-k="show_code"
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-zinc-900 rounded-xl dark:border dark:border-zinc-800"
      ><code>{popover_snippet(@popover)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">
        top_layer escapes clipped containers
      </div>
      <div class="px-6 py-10 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="max-w-md mx-auto">
          <div class="relative h-24 p-4 overflow-hidden border border-dashed rounded-lg border-gray-300 dark:border-zinc-700">
            <div class="mb-2 text-xs text-gray-400">overflow: hidden container</div>
            <.popover
              id="pg-popover-clipped"
              placement="bottom"
              top_layer
              trigger_class="pc-button pc-button--primary-outline pc-button--sm"
            >
              <:trigger>Open from inside</:trigger>
              <div class="max-w-64 text-sm">
                This panel paints on the browser top layer - the clipped
                container can't cut it off.
              </div>
            </.popover>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_page(%{active: "input-otp"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Input OTP</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        A segmented one-time-code input. One real input under the hood, so
        paste, SMS autofill and form posts all just work. Try typing in it.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex items-center justify-center px-6 py-14">
          <.input_otp
            id={"pg-otp-#{@otp.length}-#{@otp.grouped}-#{@otp.pattern}-#{@otp.disabled}"}
            name="pg_code"
            length={@otp.length}
            group_size={if @otp.grouped, do: div(@otp.length, 2)}
            pattern={@otp.pattern}
            disabled={@otp.disabled}
          />
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-zinc-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">length</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={l <- ~w(4 6)}
                phx-click="ctl_otp"
                phx-value-k="length"
                phx-value-v={l}
                class={seg(to_string(@otp.length) == l)}
              >
                {l}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">pattern</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={pt <- ~w(numeric alphanumeric)}
                phx-click="ctl_otp"
                phx-value-k="pattern"
                phx-value-v={pt}
                class={seg(@otp.pattern == pt)}
              >
                {pt}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <div class="flex gap-1.5">
              <button phx-click="ctl_otp" phx-value-k="grouped" class={tog(@otp.grouped)}>grouped</button>
              <button phx-click="ctl_otp" phx-value-k="disabled" class={tog(@otp.disabled)}>disabled</button>
            </div>
          </div>
        </div>
      </div>

      <button
        phx-click="flip"
        phx-value-k="show_code"
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-zinc-900 rounded-xl dark:border dark:border-zinc-800"
      ><code>{otp_snippet(@otp)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Grouped</div>
      <div class="px-6 py-10 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex justify-center">
          <.input_otp id="otp-grouped-demo" name="grouped_code" length={6} group_size={3} />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">
        In a form field (error state)
      </div>
      <div class="px-6 py-10 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex justify-center">
          <div class="pc-form-field-wrapper pc-form-field-wrapper--error mb-0!">
            <.input_otp id="otp-error-demo" name="error_code" length={6} value="123" />
            <p class="pc-form-field-error">that code has expired - we sent a new one</p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_page(%{active: "switch"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Switch</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        On or off, applied immediately. Switches are pill-shaped by nature, so
        the radius rail deliberately leaves them alone.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex items-center justify-center px-6 py-12">
          <div class="w-full max-w-sm">
            <.field
              type="switch"
              name="pg_notifications"
              label="Email notifications"
              checked
              size={@switch.size}
              disabled={@switch.disabled}
              errors={if @switch.error, do: ["must be enabled"], else: []}
              no_margin
            />
          </div>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-zinc-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={z <- ~w(xs sm md lg xl)}
                phx-click="ctl_switch"
                phx-value-k="size"
                phx-value-v={z}
                class={seg(@switch.size == z)}
              >
                {z}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">state</div>
            <div class="flex gap-1.5">
              <button phx-click="ctl_switch" phx-value-k="error" class={tog(@switch.error)}>error</button>
              <button phx-click="ctl_switch" phx-value-k="disabled" class={tog(@switch.disabled)}>
                disabled
              </button>
            </div>
          </div>
        </div>
      </div>

      <button
        phx-click="flip"
        phx-value-k="show_code"
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-zinc-900 rounded-xl dark:border dark:border-zinc-800"
      ><code>{switch_snippet(@switch)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">States</div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex flex-wrap items-center justify-center gap-x-10 gap-y-4">
          <.field type="switch" name="st_off" label="Off" no_margin />
          <.field type="switch" name="st_on" label="On" checked no_margin />
          <.field type="switch" name="st_dis" label="Disabled" disabled no_margin />
          <.field type="switch" name="st_dis_on" label="Disabled on" checked disabled no_margin />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Sizes</div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex flex-wrap items-center justify-center gap-x-10 gap-y-4">
          <.field :for={z <- ~w(xs sm md lg xl)} type="switch" name={"sz_" <> z} label={z} size={z} checked no_margin />
        </div>
      </div>
    </div>
    """
  end

  defp render_page(%{active: "radio"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Radio</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        Plain radio groups, plus radio cards - selectable panels with labels and
        descriptions that most libraries make you hand-roll.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex items-center justify-center px-6 py-12">
          <div class="w-full max-w-lg">
            <.field
              type="radio-card"
              name="pg_plan"
              label="Plan"
              value="pro"
              variant={@radio.variant}
              size={@radio.size}
              group_layout={@radio.layout}
              options={[
                %{value: "starter", label: "Starter", description: "For side projects"},
                %{value: "pro", label: "Pro", description: "For small teams"},
                %{value: "team", label: "Team", description: "For growing orgs"}
              ]}
              no_margin
            />
          </div>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-zinc-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={v <- ~w(outline classic)}
                phx-click="ctl_radio"
                phx-value-k="variant"
                phx-value-v={v}
                class={seg(@radio.variant == v)}
              >
                {v}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={z <- ~w(sm md lg)}
                phx-click="ctl_radio"
                phx-value-k="size"
                phx-value-v={z}
                class={seg(@radio.size == z)}
              >
                {z}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">layout</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={l <- ~w(row col)}
                phx-click="ctl_radio"
                phx-value-k="layout"
                phx-value-v={l}
                class={seg(@radio.layout == l)}
              >
                {l}
              </button>
            </div>
          </div>
        </div>
      </div>

      <button
        phx-click="flip"
        phx-value-k="show_code"
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-zinc-900 rounded-xl dark:border dark:border-zinc-800"
      ><code>{radio_snippet(@radio)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Radio group</div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="max-w-sm mx-auto">
          <.field
            type="radio-group"
            name="billing"
            label="Billing period"
            value="monthly"
            options={[{"Monthly", "monthly"}, {"Yearly (save 20%)", "yearly"}]}
            no_margin
          />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">
        With radio indicator
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="max-w-sm mx-auto">
          <.field
            type="radio-card"
            name="speed"
            label="Delivery speed"
            value="express"
            group_layout="col"
            indicator
            options={[
              %{value: "standard", label: "Standard", description: "4 to 6 business days - free"},
              %{value: "express", label: "Express", description: "1 to 2 business days - $12"},
              %{value: "overnight", label: "Overnight", description: "Next business day - $29"}
            ]}
            no_margin
          />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">
        Disabled option
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="max-w-lg mx-auto">
          <.field
            type="radio-card"
            name="tier"
            label="Tier"
            value="cloud"
            options={[
              %{value: "cloud", label: "Cloud", description: "Managed for you"},
              %{value: "self", label: "Self-hosted", description: "Coming soon", disabled: true}
            ]}
            no_margin
          />
        </div>
      </div>
    </div>
    """
  end

  defp render_page(%{active: "select"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Select</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        The native select on the shared field surface: prompt, option groups and
        multiple selection, no JS required.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex items-center justify-center px-6 py-12">
          <div class="w-full max-w-sm">
            <.field
              type="select"
              name="pg_country"
              label="Country"
              value=""
              prompt="Pick a country"
              options={["Australia", "New Zealand", "Japan"]}
              disabled={@select.disabled}
              errors={if @select.error, do: ["can't be blank"], else: []}
              help_text={if @select.help, do: "Where you pay tax."}
              no_margin
            />
          </div>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-zinc-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">state</div>
            <div class="flex gap-1.5">
              <button phx-click="ctl_select" phx-value-k="help" class={tog(@select.help)}>help</button>
              <button phx-click="ctl_select" phx-value-k="error" class={tog(@select.error)}>error</button>
              <button phx-click="ctl_select" phx-value-k="disabled" class={tog(@select.disabled)}>disabled</button>
            </div>
          </div>
        </div>
      </div>

      <button
        phx-click="flip"
        phx-value-k="show_code"
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-zinc-900 rounded-xl dark:border dark:border-zinc-800"
      ><code>{select_snippet(@select)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Option groups</div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="max-w-sm mx-auto">
          <.field
            type="select"
            name="region"
            label="Region"
            value="Sydney"
            options={[APAC: ["Sydney", "Tokyo", "Singapore"], Europe: ["Amsterdam", "Berlin"], Americas: ["Denver", "Sao Paulo"]]}
            no_margin
          />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Multiple</div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="max-w-sm mx-auto">
          <.field
            type="select"
            name="channels"
            label="Notification channels"
            value={["Email", "Slack"]}
            options={["Email", "Slack", "SMS", "Webhook"]}
            multiple
            help_text="Cmd-click to select more than one."
            no_margin
          />
        </div>
      </div>
    </div>
    """
  end

  defp render_page(%{active: "checkbox"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Checkbox</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        Single agreements and multi-select groups. The box nests the rail radius;
        the ring only shows for keyboard focus.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex items-center justify-center px-6 py-12">
          <div class="w-full max-w-sm">
            <.field
              type="checkbox-group"
              name="pg_stack[]"
              label="Stack"
              value={["phoenix"]}
              options={[{"Phoenix", "phoenix"}, {"LiveView", "live_view"}, {"Oban", "oban"}]}
              group_layout={@checkbox.layout}
              disabled={@checkbox.disabled}
              errors={if @checkbox.error, do: ["pick at least one"], else: []}
              no_margin
            />
          </div>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-zinc-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">layout</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={l <- ~w(row col)}
                phx-click="ctl_checkbox"
                phx-value-k="layout"
                phx-value-v={l}
                class={seg(@checkbox.layout == l)}
              >
                {l}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">state</div>
            <div class="flex gap-1.5">
              <button phx-click="ctl_checkbox" phx-value-k="error" class={tog(@checkbox.error)}>error</button>
              <button phx-click="ctl_checkbox" phx-value-k="disabled" class={tog(@checkbox.disabled)}>
                disabled
              </button>
            </div>
          </div>
        </div>
      </div>

      <button
        phx-click="flip"
        phx-value-k="show_code"
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-zinc-900 rounded-xl dark:border dark:border-zinc-800"
      ><code>{checkbox_snippet(@checkbox)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">
        States (click one - no ring; tab to it - ring)
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex flex-wrap items-center justify-center gap-x-8 gap-y-4">
          <.field type="checkbox" name="s_off" label="Unchecked" no_margin />
          <.field type="checkbox" name="s_on" label="Checked" checked no_margin />
          <.field type="checkbox" name="s_dis" label="Disabled" disabled no_margin />
          <.field type="checkbox" name="s_dis_on" label="Disabled checked" checked disabled no_margin />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Single checkbox</div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="max-w-sm mx-auto">
          <.field
            type="checkbox"
            name="terms"
            label="I agree to the terms and privacy policy"
            help_text="You can withdraw consent at any time."
            no_margin
          />
        </div>
      </div>
    </div>
    """
  end

  defp render_page(%{active: "alert"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Alert</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        A prominent message tied to state: information, success, caution or failure.
        Radius follows the rail above.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex items-center justify-center px-6 py-12">
          <div class="w-full max-w-xl">
            <.alert
              color={@alert.color}
              variant={@alert.variant}
              with_icon={@alert.icon}
              heading={if @alert.heading, do: "Heads up"}
            >
              Your subscription renews on 12 August.
            </.alert>
          </div>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-zinc-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">colour</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={c <- ~w(gray info success warning danger)}
                phx-click="ctl_alert"
                phx-value-k="color"
                phx-value-v={c}
                class={seg(@alert.color == c)}
              >
                {c}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={v <- ~w(light soft dark outline)}
                phx-click="ctl_alert"
                phx-value-k="variant"
                phx-value-v={v}
                class={seg(@alert.variant == v)}
              >
                {v}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <div class="flex gap-1.5">
              <button phx-click="ctl_alert" phx-value-k="icon" class={tog(@alert.icon)}>icon</button>
              <button phx-click="ctl_alert" phx-value-k="heading" class={tog(@alert.heading)}>heading</button>
            </div>
          </div>
        </div>
      </div>

      <button
        phx-click="flip"
        phx-value-k="show_code"
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-zinc-900 rounded-xl dark:border dark:border-zinc-800"
      ><code>{alert_snippet(@alert)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Semantic colours</div>
      <div class="px-6 py-8 space-y-3 border border-gray-200 rounded-xl dark:border-zinc-800">
        <.alert color="info" variant={@alert.variant} with_icon>A new version of this page is available.</.alert>
        <.alert color="success" variant={@alert.variant} with_icon>Your changes were saved.</.alert>
        <.alert color="warning" variant={@alert.variant} with_icon>Your trial ends in 3 days.</.alert>
        <.alert color="danger" variant={@alert.variant} with_icon>Payment failed. Check your card details.</.alert>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Variants</div>
      <div class="px-6 py-8 space-y-3 border border-gray-200 rounded-xl dark:border-zinc-800">
        <.alert color="gray" variant="light" with_icon>Light, the default. Stays light even in dark mode.</.alert>
        <.alert color="gray" variant="soft" with_icon>Soft adapts to dark mode.</.alert>
        <.alert color="gray" variant="dark" with_icon>Dark, maximum emphasis.</.alert>
        <.alert color="gray" variant="outline" with_icon>Outline, for calm surfaces.</.alert>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">
        Dismissible (click the cross)
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <.alert color="success" with_icon heading="Invite sent" close_button_properties={[]}>
          We emailed Ana a link to join your workspace.
        </.alert>
      </div>
    </div>
    """
  end

  defp render_page(%{active: "badge"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Badge</h1>
      <p class="mt-2 text-gray-500 dark:text-zinc-400">
        A small label for counts, statuses and categories. Radius follows the rail above.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex items-center justify-center px-6 py-14">
          <.badge color={@badge.color} variant={@badge.variant} size={@badge.size} with_icon={@badge.icon}>
            <.icon :if={@badge.icon} name="hero-sparkles" class="w-3 h-3" /> New
          </.badge>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-zinc-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">colour</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={c <- ~w(primary secondary info success warning danger gray)}
                phx-click="ctl_badge"
                phx-value-k="color"
                phx-value-v={c}
                class={seg(@badge.color == c)}
              >
                {c}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={v <- ~w(light soft dark outline)}
                phx-click="ctl_badge"
                phx-value-k="variant"
                phx-value-v={v}
                class={seg(@badge.variant == v)}
              >
                {v}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={z <- ~w(xs sm md lg xl)}
                phx-click="ctl_badge"
                phx-value-k="size"
                phx-value-v={z}
                class={seg(@badge.size == z)}
              >
                {z}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <div class="flex gap-1.5">
              <button phx-click="ctl_badge" phx-value-k="icon" class={tog(@badge.icon)}>icon</button>
            </div>
          </div>
        </div>
      </div>

      <button
        phx-click="flip"
        phx-value-k="show_code"
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-zinc-900 rounded-xl dark:border dark:border-zinc-800"
      ><code>{badge_snippet(@badge)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Variants</div>
      <div class="flex flex-wrap items-center justify-center gap-3 px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <.badge label="Light" />
        <.badge variant="soft" label="Soft" />
        <.badge variant="dark" label="Dark" />
        <.badge variant="outline" label="Outline" />
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Semantic colours</div>
      <div class="flex flex-wrap items-center justify-center gap-3 px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <.badge :for={c <- ~w(primary secondary info success warning danger gray)} color={c} variant={@badge.variant} label={c} />
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-zinc-500">Sizes</div>
      <div class="flex flex-wrap items-center justify-center gap-3 px-6 py-8 border border-gray-200 rounded-xl dark:border-zinc-800">
        <.badge :for={z <- ~w(xs sm md lg xl)} size={z} label={z} />
      </div>
    </div>
    """
  end

  defp render_page(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center h-full px-8 text-center">
      <.icon name="hero-cube-transparent" class="w-10 h-10 text-gray-300 dark:text-zinc-700" />
      <p class="mt-4 text-lg font-medium capitalize">{@active}</p>
      <p class="max-w-sm mt-1 text-sm text-gray-500 dark:text-zinc-400">
        This page gets the same treatment next. We're locking the shell and the pattern on Button first.
      </p>
    </div>
    """
  end

  defp seg(true), do: "px-2.5 py-1 text-xs font-medium bg-primary-600 text-(--pc-button-solid-fg)"

  defp seg(false),
    do: "px-2.5 py-1 text-xs text-gray-500 dark:text-zinc-400 hover:bg-gray-100 dark:hover:bg-zinc-800"

  defp tog(true),
    do: "px-2.5 py-1 text-xs font-medium rounded-lg border border-transparent bg-primary-600 text-(--pc-button-solid-fg)"

  defp tog(false),
    do:
      "px-2.5 py-1 text-xs rounded-lg border border-gray-200 dark:border-zinc-700 text-gray-500 dark:text-zinc-400 hover:bg-gray-100 dark:hover:bg-zinc-800"
end

defmodule Dev.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, html: {Dev.Layouts, :root}
  end

  scope "/" do
    pipe_through :browser
    live "/", Dev.PlaygroundLive
  end
end

# -- Serialized code reloader --------------------------------------------------

defmodule Dev.Reloader do
  # phoenix_playground's reloader re-evaluates this whole file on every
  # request. Two concurrent requests (e.g. a HEAD + GET from tooling like curl
  # or browser prefetch) race the compiler and crash with "module is currently
  # being defined", so serialize reloads behind a global lock.
  def reload(endpoint, opts) do
    :global.trans({__MODULE__, self()}, fn ->
      PhoenixPlayground.CodeReloader.reload(endpoint, opts)
    end)
  end
end

# -- Custom endpoint with Plug.Static for compiled CSS ------------------------

defmodule Dev.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix_playground

  plug Plug.Logger

  socket "/live", Phoenix.LiveView.Socket

  # Phoenix and LiveView JS assets
  plug Plug.Static, from: {:phoenix, "priv/static"}, at: "/assets/phoenix"
  plug Plug.Static, from: {:phoenix_live_view, "priv/static"}, at: "/assets/phoenix_live_view"

  # Petal Components hook bundle (loaded as an ES module by the root layout)
  plug Plug.Static, from: Path.expand("assets/js", __DIR__), at: "/assets/js"

  # Compiled Tailwind CSS
  plug Plug.Static,
    from: Path.expand("priv/static", __DIR__),
    at: "/"

  socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
  plug Phoenix.LiveReloader
  plug Phoenix.CodeReloader, reloader: &Dev.Reloader.reload/2

  plug Plug.Session,
    store: :cookie,
    key: "_dev_key",
    signing_salt: "petal_dev"

  # Answer HEAD probes (readiness checks from agents/CI) as GET
  plug Plug.Head

  plug Dev.Router
end

# -- Heroicon CSS generator ----------------------------------------------------

defmodule Dev.HeroiconsCSS do
  @icons_dir Path.expand("deps/heroicons/optimized", __DIR__)
  @output Path.expand("dev/heroicons.css", __DIR__)

  @variants [
    {"", "24/outline", "1.5rem"},
    {"-solid", "24/solid", "1.5rem"},
    {"-mini", "20/solid", "1.25rem"},
    {"-micro", "16/solid", "1rem"}
  ]

  def generate do
    if File.dir?(@icons_dir) do
      rules =
        for {suffix, dir, size} <- @variants,
            full_dir = Path.join(@icons_dir, dir),
            File.dir?(full_dir),
            file <- File.ls!(full_dir) |> Enum.sort(),
            String.ends_with?(file, ".svg") do
          name = Path.basename(file, ".svg") <> suffix
          svg = File.read!(Path.join(full_dir, file)) |> String.replace(~r/\r?\n|\r/, "")

          """
          .hero-#{name} {
            --hero-#{name}: url('data:image/svg+xml;utf8,#{svg}');
            -webkit-mask: var(--hero-#{name});
            mask: var(--hero-#{name});
            mask-repeat: no-repeat;
            background-color: currentColor;
            vertical-align: middle;
            display: inline-block;
            width: #{size};
            height: 1lh;
          }
          """
        end

      css = "/* Auto-generated heroicon CSS — do not edit */\n" <> Enum.join(rules, "\n")
      File.write!(@output, css)
      IO.puts("Generated #{length(rules)} heroicon CSS rules")
    else
      IO.puts("Warning: heroicons dep not found, skipping icon CSS generation")
      File.write!(@output, "/* heroicons not available */")
    end
  end
end

# -- Start the server ---------------------------------------------------------

# Ensure output directory exists for compiled CSS
File.mkdir_p!("priv/static/assets")

# Generate heroicon CSS from SVG files, then build Tailwind
Dev.HeroiconsCSS.generate()

# Pre-configure endpoint (PhoenixPlayground merges on top of this)
Application.put_env(:phoenix_playground, Dev.Endpoint, secret_key_base: String.duplicate("a", 64))

# Run initial Tailwind build before starting the server
Mix.Task.run("tailwind", ["petal_dev"])

PhoenixPlayground.start(
  endpoint: Dev.Endpoint,
  # OPEN_BROWSER=false for headless runs (CI, agents); PORT to avoid clashes
  open_browser: System.get_env("OPEN_BROWSER", "true") != "false",
  port: String.to_integer(System.get_env("PORT", "4000")),
  live_reload: true,
  endpoint_options: [
    debug_errors: true,
    render_errors: [formats: [html: Dev.ErrorHTML], layout: false],
    watchers: [
      tailwind: {Tailwind, :install_and_run, [:petal_dev, ~w(--watch)]}
    ]
  ]
)
