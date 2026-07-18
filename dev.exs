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
        <script src="https://cdn.jsdelivr.net/npm/echarts@5.5.1/dist/echarts.min.js">
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
  import PetalComponents.Showcase.Frame

  alias Phoenix.LiveView.JS
  alias PetalComponents.Chat

  # Update by hand occasionally; formatted as "1k" style in the header.
  @stars 1037

  @chat_seed_answer """
  Add the dep and pull it in:

  ```elixir
  def deps do
    [{:petal_components, "~> 4.5"}]
  end
  ```

  Then `use PetalComponents` in your web module - every component in this
  playground is available as a plain HEEx tag.
  """

  @chat_replies [
    """
    Good question. The short version:

    1. **Streaming** rides the LiveView socket - `push_event/3` per token, no client AI SDK
    2. **Markdown** is sanitised server-side via the optional `:mdex` dep
    3. **Tool calls** render real Phoenix components inside the thread

    Try the stop button mid-answer, or scroll up while I'm typing - the thread never yanks you back down.
    """,
    """
    Here's a live example - a component the model could emit as a tool call:

    ```elixir
    <Chat.tool_call name="get_weather" status={:complete}>
      <.weather_card city="Paris" temp={21} />
    </Chat.tool_call>
    ```

    The widget is a real LiveView component: it can hold its own `phx-click`, forms, even streams.
    """
  ]

  @chat_history [
    %{id: "m-yesterday", role: :marker, text: "Yesterday"},
    %{id: "hist-q", role: :user, text: "Does it support dark mode?", stream_id: nil},
    %{
      id: "hist-a",
      role: :assistant,
      stream_id: nil,
      text:
        "Every component ships light and dark out of the box - flip the moon icon in the top bar to see this whole thread switch."
    }
  ]

  @nav [
    %{
      group: "Foundations",
      items: [
        %{slug: "typography", name: "Typography", ready: true},
        %{slug: "colors", name: "Colours", ready: true},
        %{slug: "links", name: "Links", ready: true},
        %{slug: "icons", name: "Icons", ready: true}
      ]
    },
    %{
      group: "Inputs",
      items: [
        %{slug: "button", name: "Button", ready: true},
        %{slug: "button-group", name: "Button group", ready: true},
        %{slug: "input", name: "Input", ready: true},
        %{slug: "checkbox", name: "Checkbox", ready: true},
        %{slug: "select", name: "Select", ready: true},
        %{slug: "radio", name: "Radio", ready: true},
        %{slug: "switch", name: "Switch", ready: true},
        %{slug: "input-otp", name: "Input OTP", ready: true}
      ]
    },
    %{
      group: "Feedback",
      items: [
        %{slug: "alert", name: "Alert", ready: true},
        %{slug: "badge", name: "Badge", ready: true},
        %{slug: "progress", name: "Progress", ready: true},
        %{slug: "rating", name: "Rating", ready: true},
        %{slug: "skeleton", name: "Skeleton", ready: true},
        %{slug: "loading", name: "Loading", ready: true}
      ]
    },
    %{
      group: "Navigation",
      items: [
        %{slug: "tabs", name: "Tabs", ready: true},
        %{slug: "pagination", name: "Pagination", ready: true},
        %{slug: "breadcrumbs", name: "Breadcrumbs", ready: true},
        %{slug: "stepper", name: "Stepper", ready: true},
        %{slug: "menu", name: "Menu", ready: true},
        %{slug: "navigation-menu", name: "Navigation menu", ready: true}
      ]
    },
    %{
      group: "Data",
      items: [
        %{slug: "table", name: "Table", ready: true},
        %{slug: "chart", name: "Chart", ready: true}
      ]
    },
    %{
      group: "Display",
      items: [
        %{slug: "avatar", name: "Avatar", ready: true},
        %{slug: "card", name: "Card", ready: true},
        %{slug: "accordion", name: "Accordion", ready: true},
        %{slug: "container", name: "Container", ready: true}
      ]
    },
    %{
      group: "Overlay",
      items: [
        %{slug: "tooltip", name: "Tooltip", ready: true},
        %{slug: "popover", name: "Popover", ready: true},
        %{slug: "modal", name: "Modal", ready: true},
        %{slug: "dropdown", name: "Dropdown", ready: true},
        %{slug: "command", name: "Command", ready: true},
        %{slug: "slide-over", name: "Slide over", ready: true}
      ]
    },
    %{
      group: "AI",
      items: [
        %{slug: "chat", name: "AI Chat", ready: true}
      ]
    },
    %{
      group: "Effects",
      items: [
        %{slug: "aurora", name: "Aurora", ready: true},
        %{slug: "border-beam", name: "Border beam", ready: true},
        %{slug: "meteors", name: "Meteors", ready: true},
        %{slug: "shine-border", name: "Shine border", ready: true},
        %{slug: "marquee", name: "Marquee", ready: true},
        %{slug: "spotlight-card", name: "Spotlight card", ready: true},
        %{slug: "number-ticker", name: "Number ticker", ready: true},
        %{slug: "text-animation", name: "Text animation", ready: true},
        %{slug: "confetti", name: "Confetti", ready: true}
      ]
    }
  ]

  @slugs Enum.flat_map(@nav, fn g -> Enum.map(g.items, & &1.slug) end)

  # {name, rail swatch css}. Neutral adapts to the mode, hence the split dot.
  @primaries [
    {"neutral", "linear-gradient(135deg,#18181b 50%,#e4e4e7 50%)"},
    {"blue", "#2563eb"},
    {"indigo", "#4f46e5"},
    {"violet", "#7c3aed"},
    {"emerald", "#059669"},
    {"rose", "#e11d48"},
    {"amber", "#d97706"}
  ]
  @primary_names Enum.map(@primaries, &elem(&1, 0))

  # Neutral dial - which gray every surface (and the ghost material) derives
  # from. Dots show each ramp's 500.
  @grays [
    {"zinc", "oklch(55.2% 0.016 285.938)"},
    {"slate", "oklch(55.4% 0.046 257.417)"},
    {"gray", "oklch(55.1% 0.027 264.364)"},
    {"neutral", "oklch(55.6% 0 none)"},
    {"stone", "oklch(55.3% 0.013 58.071)"}
  ]
  @gray_names Enum.map(@grays, &elem(&1, 0))

  # Secondary dial - the brand accent. Dots show each ramp's 600.
  @secondaries [
    {"pink", "oklch(59.2% 0.249 0.584)"},
    {"fuchsia", "oklch(59.1% 0.293 322.896)"},
    {"teal", "oklch(60% 0.118 184.704)"},
    {"cyan", "oklch(60.9% 0.126 221.723)"},
    {"lime", "oklch(64.8% 0.2 131.684)"},
    {"orange", "oklch(64.6% 0.222 41.116)"}
  ]
  @secondary_names Enum.map(@secondaries, &elem(&1, 0))

  # The full Tailwind palette (extracted from the shipped binary) - the hues
  # an app maps primary/secondary from. Hard-coded because Tailwind v4
  # tree-shakes unused colour vars out of the build.
  @tw_palette [
    {"red",
     [
       "oklch(97.1% 0.013 17.38)",
       "oklch(93.6% 0.032 17.717)",
       "oklch(88.5% 0.062 18.334)",
       "oklch(80.8% 0.114 19.571)",
       "oklch(70.4% 0.191 22.216)",
       "oklch(63.7% 0.237 25.331)",
       "oklch(57.7% 0.245 27.325)",
       "oklch(50.5% 0.213 27.518)",
       "oklch(44.4% 0.177 26.899)",
       "oklch(39.6% 0.141 25.723)",
       "oklch(25.8% 0.092 26.042)"
     ]},
    {"orange",
     [
       "oklch(98% 0.016 73.684)",
       "oklch(95.4% 0.038 75.164)",
       "oklch(90.1% 0.076 70.697)",
       "oklch(83.7% 0.128 66.29)",
       "oklch(75% 0.183 55.934)",
       "oklch(70.5% 0.213 47.604)",
       "oklch(64.6% 0.222 41.116)",
       "oklch(55.3% 0.195 38.402)",
       "oklch(47% 0.157 37.304)",
       "oklch(40.8% 0.123 38.172)",
       "oklch(26.6% 0.079 36.259)"
     ]},
    {"amber",
     [
       "oklch(98.7% 0.022 95.277)",
       "oklch(96.2% 0.059 95.617)",
       "oklch(92.4% 0.12 95.746)",
       "oklch(87.9% 0.169 91.605)",
       "oklch(82.8% 0.189 84.429)",
       "oklch(76.9% 0.188 70.08)",
       "oklch(66.6% 0.179 58.318)",
       "oklch(55.5% 0.163 48.998)",
       "oklch(47.3% 0.137 46.201)",
       "oklch(41.4% 0.112 45.904)",
       "oklch(27.9% 0.077 45.635)"
     ]},
    {"yellow",
     [
       "oklch(98.7% 0.026 102.212)",
       "oklch(97.3% 0.071 103.193)",
       "oklch(94.5% 0.129 101.54)",
       "oklch(90.5% 0.182 98.111)",
       "oklch(85.2% 0.199 91.936)",
       "oklch(79.5% 0.184 86.047)",
       "oklch(68.1% 0.162 75.834)",
       "oklch(55.4% 0.135 66.442)",
       "oklch(47.6% 0.114 61.907)",
       "oklch(42.1% 0.095 57.708)",
       "oklch(28.6% 0.066 53.813)"
     ]},
    {"lime",
     [
       "oklch(98.6% 0.031 120.757)",
       "oklch(96.7% 0.067 122.328)",
       "oklch(93.8% 0.127 124.321)",
       "oklch(89.7% 0.196 126.665)",
       "oklch(84.1% 0.238 128.85)",
       "oklch(76.8% 0.233 130.85)",
       "oklch(64.8% 0.2 131.684)",
       "oklch(53.2% 0.157 131.589)",
       "oklch(45.3% 0.124 130.933)",
       "oklch(40.5% 0.101 131.063)",
       "oklch(27.4% 0.072 132.109)"
     ]},
    {"green",
     [
       "oklch(98.2% 0.018 155.826)",
       "oklch(96.2% 0.044 156.743)",
       "oklch(92.5% 0.084 155.995)",
       "oklch(87.1% 0.15 154.449)",
       "oklch(79.2% 0.209 151.711)",
       "oklch(72.3% 0.219 149.579)",
       "oklch(62.7% 0.194 149.214)",
       "oklch(52.7% 0.154 150.069)",
       "oklch(44.8% 0.119 151.328)",
       "oklch(39.3% 0.095 152.535)",
       "oklch(26.6% 0.065 152.934)"
     ]},
    {"emerald",
     [
       "oklch(97.9% 0.021 166.113)",
       "oklch(95% 0.052 163.051)",
       "oklch(90.5% 0.093 164.15)",
       "oklch(84.5% 0.143 164.978)",
       "oklch(76.5% 0.177 163.223)",
       "oklch(69.6% 0.17 162.48)",
       "oklch(59.6% 0.145 163.225)",
       "oklch(50.8% 0.118 165.612)",
       "oklch(43.2% 0.095 166.913)",
       "oklch(37.8% 0.077 168.94)",
       "oklch(26.2% 0.051 172.552)"
     ]},
    {"teal",
     [
       "oklch(98.4% 0.014 180.72)",
       "oklch(95.3% 0.051 180.801)",
       "oklch(91% 0.096 180.426)",
       "oklch(85.5% 0.138 181.071)",
       "oklch(77.7% 0.152 181.912)",
       "oklch(70.4% 0.14 182.503)",
       "oklch(60% 0.118 184.704)",
       "oklch(51.1% 0.096 186.391)",
       "oklch(43.7% 0.078 188.216)",
       "oklch(38.6% 0.063 188.416)",
       "oklch(27.7% 0.046 192.524)"
     ]},
    {"cyan",
     [
       "oklch(98.4% 0.019 200.873)",
       "oklch(95.6% 0.045 203.388)",
       "oklch(91.7% 0.08 205.041)",
       "oklch(86.5% 0.127 207.078)",
       "oklch(78.9% 0.154 211.53)",
       "oklch(71.5% 0.143 215.221)",
       "oklch(60.9% 0.126 221.723)",
       "oklch(52% 0.105 223.128)",
       "oklch(45% 0.085 224.283)",
       "oklch(39.8% 0.07 227.392)",
       "oklch(30.2% 0.056 229.695)"
     ]},
    {"sky",
     [
       "oklch(97.7% 0.013 236.62)",
       "oklch(95.1% 0.026 236.824)",
       "oklch(90.1% 0.058 230.902)",
       "oklch(82.8% 0.111 230.318)",
       "oklch(74.6% 0.16 232.661)",
       "oklch(68.5% 0.169 237.323)",
       "oklch(58.8% 0.158 241.966)",
       "oklch(50% 0.134 242.749)",
       "oklch(44.3% 0.11 240.79)",
       "oklch(39.1% 0.09 240.876)",
       "oklch(29.3% 0.066 243.157)"
     ]},
    {"blue",
     [
       "oklch(97% 0.014 254.604)",
       "oklch(93.2% 0.032 255.585)",
       "oklch(88.2% 0.059 254.128)",
       "oklch(80.9% 0.105 251.813)",
       "oklch(70.7% 0.165 254.624)",
       "oklch(62.3% 0.214 259.815)",
       "oklch(54.6% 0.245 262.881)",
       "oklch(48.8% 0.243 264.376)",
       "oklch(42.4% 0.199 265.638)",
       "oklch(37.9% 0.146 265.522)",
       "oklch(28.2% 0.091 267.935)"
     ]},
    {"indigo",
     [
       "oklch(96.2% 0.018 272.314)",
       "oklch(93% 0.034 272.788)",
       "oklch(87% 0.065 274.039)",
       "oklch(78.5% 0.115 274.713)",
       "oklch(67.3% 0.182 276.935)",
       "oklch(58.5% 0.233 277.117)",
       "oklch(51.1% 0.262 276.966)",
       "oklch(45.7% 0.24 277.023)",
       "oklch(39.8% 0.195 277.366)",
       "oklch(35.9% 0.144 278.697)",
       "oklch(25.7% 0.09 281.288)"
     ]},
    {"violet",
     [
       "oklch(96.9% 0.016 293.756)",
       "oklch(94.3% 0.029 294.588)",
       "oklch(89.4% 0.057 293.283)",
       "oklch(81.1% 0.111 293.571)",
       "oklch(70.2% 0.183 293.541)",
       "oklch(60.6% 0.25 292.717)",
       "oklch(54.1% 0.281 293.009)",
       "oklch(49.1% 0.27 292.581)",
       "oklch(43.2% 0.232 292.759)",
       "oklch(38% 0.189 293.745)",
       "oklch(28.3% 0.141 291.089)"
     ]},
    {"purple",
     [
       "oklch(97.7% 0.014 308.299)",
       "oklch(94.6% 0.033 307.174)",
       "oklch(90.2% 0.063 306.703)",
       "oklch(82.7% 0.119 306.383)",
       "oklch(71.4% 0.203 305.504)",
       "oklch(62.7% 0.265 303.9)",
       "oklch(55.8% 0.288 302.321)",
       "oklch(49.6% 0.265 301.924)",
       "oklch(43.8% 0.218 303.724)",
       "oklch(38.1% 0.176 304.987)",
       "oklch(29.1% 0.149 302.717)"
     ]},
    {"fuchsia",
     [
       "oklch(97.7% 0.017 320.058)",
       "oklch(95.2% 0.037 318.852)",
       "oklch(90.3% 0.076 319.62)",
       "oklch(83.3% 0.145 321.434)",
       "oklch(74% 0.238 322.16)",
       "oklch(66.7% 0.295 322.15)",
       "oklch(59.1% 0.293 322.896)",
       "oklch(51.8% 0.253 323.949)",
       "oklch(45.2% 0.211 324.591)",
       "oklch(40.1% 0.17 325.612)",
       "oklch(29.3% 0.136 325.661)"
     ]},
    {"pink",
     [
       "oklch(97.1% 0.014 343.198)",
       "oklch(94.8% 0.028 342.258)",
       "oklch(89.9% 0.061 343.231)",
       "oklch(82.3% 0.12 346.018)",
       "oklch(71.8% 0.202 349.761)",
       "oklch(65.6% 0.241 354.308)",
       "oklch(59.2% 0.249 0.584)",
       "oklch(52.5% 0.223 3.958)",
       "oklch(45.9% 0.187 3.815)",
       "oklch(40.8% 0.153 2.432)",
       "oklch(28.4% 0.109 3.907)"
     ]},
    {"rose",
     [
       "oklch(96.9% 0.015 12.422)",
       "oklch(94.1% 0.03 12.58)",
       "oklch(89.2% 0.058 10.001)",
       "oklch(81% 0.117 11.638)",
       "oklch(71.2% 0.194 13.428)",
       "oklch(64.5% 0.246 16.439)",
       "oklch(58.6% 0.253 17.585)",
       "oklch(51.4% 0.222 16.935)",
       "oklch(45.5% 0.188 13.697)",
       "oklch(41% 0.159 10.272)",
       "oklch(27.1% 0.105 12.094)"
     ]},
    {"slate",
     [
       "oklch(98.4% 0.003 247.858)",
       "oklch(96.8% 0.007 247.896)",
       "oklch(92.9% 0.013 255.508)",
       "oklch(86.9% 0.022 252.894)",
       "oklch(70.4% 0.04 256.788)",
       "oklch(55.4% 0.046 257.417)",
       "oklch(44.6% 0.043 257.281)",
       "oklch(37.2% 0.044 257.287)",
       "oklch(27.9% 0.041 260.031)",
       "oklch(20.8% 0.042 265.755)",
       "oklch(12.9% 0.042 264.695)"
     ]},
    {"gray",
     [
       "oklch(98.5% 0.002 247.839)",
       "oklch(96.7% 0.003 264.542)",
       "oklch(92.8% 0.006 264.531)",
       "oklch(87.2% 0.01 258.338)",
       "oklch(70.7% 0.022 261.325)",
       "oklch(55.1% 0.027 264.364)",
       "oklch(44.6% 0.03 256.802)",
       "oklch(37.3% 0.034 259.733)",
       "oklch(27.8% 0.033 256.848)",
       "oklch(21% 0.034 264.665)",
       "oklch(13% 0.028 261.692)"
     ]},
    {"zinc",
     [
       "oklch(98.5% 0 0)",
       "oklch(96.7% 0.001 286.375)",
       "oklch(92% 0.004 286.32)",
       "oklch(87.1% 0.006 286.286)",
       "oklch(70.5% 0.015 286.067)",
       "oklch(55.2% 0.016 285.938)",
       "oklch(44.2% 0.017 285.786)",
       "oklch(37% 0.013 285.805)",
       "oklch(27.4% 0.006 286.033)",
       "oklch(21% 0.006 285.885)",
       "oklch(14.1% 0.005 285.823)"
     ]},
    {"neutral",
     [
       "oklch(98.5% 0 0)",
       "oklch(97% 0 0)",
       "oklch(92.2% 0 0)",
       "oklch(87% 0 0)",
       "oklch(70.8% 0 0)",
       "oklch(55.6% 0 0)",
       "oklch(43.9% 0 0)",
       "oklch(37.1% 0 0)",
       "oklch(26.9% 0 0)",
       "oklch(20.5% 0 0)",
       "oklch(14.5% 0 0)"
     ]},
    {"stone",
     [
       "oklch(98.5% 0.001 106.423)",
       "oklch(97% 0.001 106.424)",
       "oklch(92.3% 0.003 48.717)",
       "oklch(86.9% 0.005 56.366)",
       "oklch(70.9% 0.01 56.259)",
       "oklch(55.3% 0.013 58.071)",
       "oklch(44.4% 0.011 73.639)",
       "oklch(37.4% 0.01 67.558)",
       "oklch(26.8% 0.007 34.298)",
       "oklch(21.6% 0.006 56.043)",
       "oklch(14.7% 0.004 49.25)"
     ]}
  ]

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
       primaries: @primaries,
       grays: @grays,
       secondaries: @secondaries,
       tw_palette: @tw_palette,
       radii: @radii,
       stars: @stars,
       variant: "outline",
       color: "primary",
       size: "md",
       icon: false,
       loading: false,
       disabled: false,
       show_code: false,
       chat: %{
         turns: [
           %{id: "m-today", role: :marker, text: "Today"},
           %{
             id: "seed-q",
             role: :user,
             text: "How do I install petal_components?",
             stream_id: nil
           },
           %{id: "seed-a", role: :assistant, text: @chat_seed_answer, stream_id: nil}
         ],
         streaming: false,
         seq: 1,
         history: false,
         variant: "plain",
         actions: "always",
         editing: nil,
         sent: false
       },
       alert: %{color: "gray", variant: "outline", icon: true, heading: false},
       badge: %{color: "primary", variant: "outline", size: "md", icon: false},
       input: %{type: "text", disabled: false, error: false, help: false},
       checkbox: %{layout: "row", disabled: false, error: false},
       select: %{disabled: false, error: false, help: false},
       radio: %{variant: "outline", size: "md", layout: "row"},
       switch: %{size: "md", disabled: false, error: false},
       otp: %{length: 6, grouped: false, pattern: "numeric", disabled: false},
       progress: %{value: 60, color: "primary", size: "xs", label: "top"},
       beam: %{
         duration: "8s",
         beams: 1,
         reverse: false,
         easing: "linear",
         size: "60px",
         glow: false
       },
       shine: %{scheme: "mono", duration: "14s", width: "1px"},
       meteors: %{count: 20, angle: "215deg", color: "slate", reverse: false, seed: 0},
       rating: %{
         icon: "star",
         size: "md",
         value: 3.0,
         hearts: 2.0,
         mood: 4,
         label: "none",
         step: "whole"
       },
       slideover: %{origin: "right", width: "md"},
       tabs: %{variant: "segmented", active: "overview", number: true},
       table: %{
         sort_by: "name",
         sort_dir: "asc",
         density: "comfortable",
         striped: false,
         variant: "basic",
         empty: false
       },
       page: %{current: 3, sibling: 1, boundary: 1},
       skeleton: %{animation: "pulse", loading: false},
       accordion: %{variant: "default", multiple: false, size: "md"},
       stepper: %{orientation: "horizontal", size: "md", at: 0, done: false},
       nav_trigger: "hover",
       crumbs: %{separator: "chevron"},
       marquee_ctl: %{reverse: false, vertical: false, pause: true},
       ticker: %{value: 1024},
       tooltip: %{placement: "top", arrow: true},
       popover: %{placement: "bottom", top_layer: false},
       chart: %{
         revenue: gen_wave(1100, 1),
         expenses: gen_wave(650, 4),
         type: "line",
         shape: "smooth",
         area: "fade",
         dots: false,
         chrome: true,
         two_series: false,
         gap: "cozy",
         stacked: false
       }
     )}
  end

  # Theme state lives in the URL, so any look is shareable / screenshotable.
  def handle_params(params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:active, allow(params["c"], @slugs, "button"))
     |> assign(:primary, allow(params["primary"] || params["accent"], @primary_names, "neutral"))
     |> assign(:gray, allow(params["gray"], @gray_names, "zinc"))
     |> assign(:secondary, allow(params["secondary"], @secondary_names, "pink"))
     |> assign(:radius, allow(params["radius"], @radius_labels, "10"))
     |> assign(:dark, params["dark"] == "1")}
  end

  def handle_event("select", %{"slug" => slug}, socket), do: patch_theme(socket, %{active: slug})

  def handle_event("set_gray", %{"gray" => g}, socket), do: patch_theme(socket, %{gray: g})

  def handle_event("set_primary", %{"primary" => p}, socket),
    do: patch_theme(socket, %{primary: p})

  def handle_event("set_secondary", %{"secondary" => x}, socket),
    do: patch_theme(socket, %{secondary: x})

  def handle_event("set_radius", %{"radius" => r}, socket), do: patch_theme(socket, %{radius: r})

  def handle_event("toggle_dark", _params, socket),
    do: patch_theme(socket, %{dark: !socket.assigns.dark})

  def handle_event("ctl_variant", %{"v" => v}, socket)
      when v in ~w(solid soft light outline ghost),
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

  def handle_event("flip", %{"k" => "disabled"}, socket),
    do: {:noreply, update(socket, :disabled, &(!&1))}

  def handle_event("flip", %{"k" => "show_code"}, socket),
    do: {:noreply, update(socket, :show_code, &(!&1))}

  def handle_event("ctl_input", %{"k" => "type", "v" => v}, socket) when v in @input_types,
    do: {:noreply, update(socket, :input, &%{&1 | type: v})}

  def handle_event("ctl_input", %{"k" => k}, socket) when k in ~w(disabled error help),
    do:
      {:noreply,
       update(socket, :input, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  def handle_event("ctl_progress", %{"k" => "value", "v" => v}, socket)
      when v in ~w(15 40 60 85 100),
      do: {:noreply, update(socket, :progress, &%{&1 | value: String.to_integer(v)})}

  def handle_event("ctl_progress", %{"k" => "color", "v" => v}, socket)
      when v in ~w(primary secondary info success warning danger gray),
      do: {:noreply, update(socket, :progress, &%{&1 | color: v})}

  def handle_event("ctl_progress", %{"k" => "size", "v" => v}, socket)
      when v in ~w(xs sm md lg xl),
      do: {:noreply, update(socket, :progress, &%{&1 | size: v})}

  def handle_event("ctl_progress", %{"k" => "label", "v" => v}, socket)
      when v in ~w(none inside top),
      do:
        {:noreply,
         update(
           socket,
           :progress,
           &%{&1 | label: v, size: if(v == "inside", do: "xl", else: &1.size)}
         )}

  def handle_event("ctl_beam", %{"k" => "glow"}, socket),
    do: {:noreply, update(socket, :beam, &%{&1 | glow: !&1.glow})}

  def handle_event("chart_randomize", _params, socket) do
    revenue = Enum.map(1..30, fn i -> 550 + i * 12 + :rand.uniform(600) end)
    expenses = Enum.map(1..30, fn i -> 300 + i * 6 + :rand.uniform(350) end)
    {:noreply, update(socket, :chart, &%{&1 | revenue: revenue, expenses: expenses})}
  end

  def handle_event("ctl_chart", %{"k" => "two_series"}, socket),
    do: {:noreply, update(socket, :chart, &%{&1 | two_series: !socket.assigns.chart.two_series})}

  def handle_event("ctl_chart", %{"k" => "gap", "v" => v}, socket) when v in ~w(cozy tight),
    do: {:noreply, update(socket, :chart, &%{&1 | gap: v})}

  def handle_event("ctl_chart", %{"k" => "type", "v" => v}, socket)
      when v in ~w(line bar),
      do: {:noreply, update(socket, :chart, &%{&1 | type: v})}

  def handle_event("ctl_chart", %{"k" => "shape", "v" => v}, socket)
      when v in ~w(smooth linear step),
      do: {:noreply, update(socket, :chart, &%{&1 | shape: v})}

  def handle_event("ctl_chart", %{"k" => "area", "v" => v}, socket)
      when v in ~w(fade solid none),
      do: {:noreply, update(socket, :chart, &%{&1 | area: v})}

  def handle_event("ctl_chart", %{"k" => "dots"}, socket),
    do: {:noreply, update(socket, :chart, &%{&1 | dots: !socket.assigns.chart.dots})}

  def handle_event("ctl_chart", %{"k" => "chrome"}, socket),
    do: {:noreply, update(socket, :chart, &%{&1 | chrome: !socket.assigns.chart.chrome})}

  def handle_event("ctl_chart", %{"k" => "stacked"}, socket),
    do: {:noreply, update(socket, :chart, &%{&1 | stacked: !socket.assigns.chart.stacked})}

  def handle_event("ctl_meteors", %{"k" => "count", "v" => v}, socket) when v in ~w(10 20 40),
    do: {:noreply, update(socket, :meteors, &%{&1 | count: String.to_integer(v)})}

  def handle_event("ctl_meteors", %{"k" => "angle", "v" => v}, socket)
      when v in ~w(200deg 215deg 235deg),
      do: {:noreply, update(socket, :meteors, &%{&1 | angle: v})}

  def handle_event("ctl_meteors", %{"k" => "color", "v" => v}, socket)
      when v in ~w(slate sky violet),
      do: {:noreply, update(socket, :meteors, &%{&1 | color: v})}

  def handle_event("ctl_rating", %{"k" => "icon", "v" => v}, socket)
      when v in ~w(star heart face),
      do:
        {:noreply,
         update(
           socket,
           :rating,
           &%{&1 | icon: v, step: if(v == "face", do: "whole", else: &1.step)}
         )}

  def handle_event("ctl_rating", %{"k" => "size", "v" => v}, socket) when v in ~w(sm md lg),
    do: {:noreply, update(socket, :rating, &%{&1 | size: v})}

  def handle_event("ctl_rating", %{"k" => "label", "v" => v}, socket)
      when v in ~w(none right bottom),
      do: {:noreply, update(socket, :rating, &%{&1 | label: v})}

  def handle_event("ctl_rating", %{"k" => "step", "v" => v}, socket) when v in ~w(whole half),
    do: {:noreply, update(socket, :rating, &%{&1 | step: v})}

  def handle_event("rate", params, socket) do
    rating = socket.assigns.rating
    parse = fn v -> v |> Float.parse() |> elem(0) end

    rating =
      rating
      |> then(&if v = params["score"], do: %{&1 | value: parse.(v)}, else: &1)
      |> then(&if v = params["love"], do: %{&1 | hearts: parse.(v)}, else: &1)
      |> then(&if v = params["mood"], do: %{&1 | mood: v |> parse.() |> round()}, else: &1)

    {:noreply, assign(socket, :rating, rating)}
  end

  def handle_event("ctl_slideover", %{"k" => "origin", "v" => v}, socket)
      when v in ~w(left right top bottom),
      do: {:noreply, update(socket, :slideover, &%{&1 | origin: v})}

  def handle_event("ctl_slideover", %{"k" => "width", "v" => v}, socket) when v in ~w(sm md lg),
    do: {:noreply, update(socket, :slideover, &%{&1 | width: v})}

  def handle_event("close_slide_over", _, socket), do: {:noreply, socket}

  def handle_event("ctl_tabs", %{"k" => "variant", "v" => v}, socket)
      when v in ~w(pill underline segmented),
      do: {:noreply, update(socket, :tabs, &%{&1 | variant: v})}

  def handle_event("ctl_tabs", %{"k" => "tab", "v" => v}, socket)
      when v in ~w(overview analytics reports settings),
      do: {:noreply, update(socket, :tabs, &%{&1 | active: v})}

  def handle_event("ctl_tabs", %{"k" => "number"}, socket),
    do: {:noreply, update(socket, :tabs, &%{&1 | number: !&1.number})}

  def handle_event("sort", %{"sort" => key}, socket) do
    {:noreply,
     update(socket, :table, fn t ->
       if t.sort_by == key,
         do: %{t | sort_dir: if(t.sort_dir == "asc", do: "desc", else: "asc")},
         else: %{t | sort_by: key, sort_dir: "asc"}
     end)}
  end

  def handle_event("ctl_table", %{"k" => "density", "v" => v}, socket)
      when v in ~w(comfortable compact),
      do: {:noreply, update(socket, :table, &%{&1 | density: v})}

  def handle_event("ctl_table", %{"k" => "striped"}, socket),
    do: {:noreply, update(socket, :table, &%{&1 | striped: !&1.striped})}

  def handle_event("ctl_table", %{"k" => "variant", "v" => v}, socket) when v in ~w(basic ghost),
    do: {:noreply, update(socket, :table, &%{&1 | variant: v})}

  def handle_event("ctl_table", %{"k" => "empty"}, socket),
    do: {:noreply, update(socket, :table, &%{&1 | empty: !&1.empty})}

  def handle_event("ctl_page", %{"k" => "sibling", "v" => v}, socket) when v in ~w(0 1 2),
    do: {:noreply, update(socket, :page, &%{&1 | sibling: String.to_integer(v)})}

  def handle_event("ctl_page", %{"k" => "boundary", "v" => v}, socket) when v in ~w(1 2),
    do: {:noreply, update(socket, :page, &%{&1 | boundary: String.to_integer(v)})}

  def handle_event("ctl_skeleton", %{"k" => "animation", "v" => v}, socket)
      when v in ~w(pulse shimmer none),
      do: {:noreply, update(socket, :skeleton, &%{&1 | animation: v})}

  def handle_event("ctl_skeleton", %{"k" => "load"}, socket) do
    Process.send_after(self(), :pg_skeleton_loaded, 1600)
    {:noreply, update(socket, :skeleton, &%{&1 | loading: true})}
  end

  def handle_info(:pg_skeleton_loaded, socket),
    do: {:noreply, update(socket, :skeleton, &%{&1 | loading: false})}

  def handle_info({:chat_tick, id, chunks}, socket) do
    chat = socket.assigns.chat

    cond do
      !chat.streaming ->
        # stopped mid-stream: leave the partial text as-is
        {:noreply, socket}

      chunks == [] ->
        # done: commit the turn (streaming span swaps to rendered markdown)
        turns =
          Enum.map(chat.turns, fn
            %{stream_id: ^id} = turn -> %{turn | stream_id: nil}
            turn -> turn
          end)

        {:noreply, assign(socket, :chat, %{chat | turns: turns, streaming: false})}

      true ->
        [chunk | rest] = chunks
        Process.send_after(self(), {:chat_tick, id, rest}, 40)
        {:noreply, push_event(socket, "pc-chat-token", %{id: id, text: chunk})}
    end
  end

  def handle_event("ctl_accordion", %{"k" => "variant", "v" => v}, socket)
      when v in ~w(default bordered),
      do: {:noreply, update(socket, :accordion, &%{&1 | variant: v})}

  def handle_event("ctl_accordion", %{"k" => "multiple"}, socket),
    do: {:noreply, update(socket, :accordion, &%{&1 | multiple: !&1.multiple})}

  def handle_event("ctl_accordion", %{"k" => "size", "v" => v}, socket) when v in ~w(sm md),
    do: {:noreply, update(socket, :accordion, &%{&1 | size: v})}

  def handle_event("ctl_stepper", %{"k" => "orientation", "v" => v}, socket)
      when v in ~w(horizontal vertical),
      do: {:noreply, update(socket, :stepper, &%{&1 | orientation: v})}

  def handle_event("ctl_stepper", %{"k" => "size", "v" => v}, socket) when v in ~w(sm md lg),
    do: {:noreply, update(socket, :stepper, &%{&1 | size: v})}

  def handle_event("ctl_stepper", %{"k" => "goto", "v" => v}, socket),
    do: {:noreply, update(socket, :stepper, &%{&1 | at: String.to_integer(v), done: false})}

  def handle_event("ctl_stepper", %{"k" => "next"}, socket) do
    st = socket.assigns.stepper
    last = length(pg_step_defs()) - 1

    st = if st.at >= last, do: %{st | done: true}, else: %{st | at: st.at + 1}
    {:noreply, assign(socket, :stepper, st)}
  end

  def handle_event("ctl_stepper", %{"k" => "back"}, socket),
    do: {:noreply, update(socket, :stepper, &%{&1 | at: max(&1.at - 1, 0), done: false})}

  def handle_event("ctl_stepper", %{"k" => "reset"}, socket),
    do: {:noreply, update(socket, :stepper, &%{&1 | at: 0, done: false})}

  def handle_event("ctl_navmenu", %{"k" => "trigger", "v" => v}, socket)
      when v in ~w(hover click),
      do: {:noreply, assign(socket, :nav_trigger, v)}

  def handle_event("ctl_crumbs", %{"k" => "separator", "v" => v}, socket)
      when v in ~w(slash chevron),
      do: {:noreply, update(socket, :crumbs, &%{&1 | separator: v})}

  def handle_event("ctl_marquee", %{"k" => k}, socket) when k in ~w(reverse vertical pause) do
    key = String.to_existing_atom(k)
    {:noreply, update(socket, :marquee_ctl, &Map.update!(&1, key, fn v -> !v end))}
  end

  def handle_event("ticker_bump", _params, socket),
    do: {:noreply, update(socket, :ticker, &%{&1 | value: &1.value + Enum.random(137..913)})}

  def handle_event("goto-page", %{"page" => page}, socket),
    do: {:noreply, update(socket, :page, &%{&1 | current: String.to_integer(page)})}

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

  def handle_event("ctl_tooltip", %{"k" => "placement", "v" => v}, socket)
      when v in ~w(top bottom left right),
      do: {:noreply, update(socket, :tooltip, &%{&1 | placement: v})}

  def handle_event("ctl_tooltip", %{"k" => "arrow"}, socket),
    do: {:noreply, update(socket, :tooltip, &%{&1 | arrow: !&1.arrow})}

  def handle_event("ctl_popover", %{"k" => "placement", "v" => v}, socket)
      when v in ~w(top bottom left right),
      do: {:noreply, update(socket, :popover, &%{&1 | placement: v})}

  def handle_event("ctl_popover", %{"k" => "top_layer"}, socket),
    do: {:noreply, update(socket, :popover, &%{&1 | top_layer: !&1.top_layer})}

  def handle_event("ctl_otp", %{"k" => "length", "v" => v}, socket) when v in ~w(4 6),
    do: {:noreply, update(socket, :otp, &%{&1 | length: String.to_integer(v)})}

  def handle_event("ctl_otp", %{"k" => "pattern", "v" => v}, socket)
      when v in ~w(numeric alphanumeric),
      do: {:noreply, update(socket, :otp, &%{&1 | pattern: v})}

  def handle_event("ctl_otp", %{"k" => k}, socket) when k in ~w(grouped disabled),
    do:
      {:noreply,
       update(socket, :otp, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  def handle_event("ctl_switch", %{"k" => "size", "v" => v}, socket) when v in ~w(xs sm md lg xl),
    do: {:noreply, update(socket, :switch, &%{&1 | size: v})}

  def handle_event("ctl_switch", %{"k" => k}, socket) when k in ~w(disabled error),
    do:
      {:noreply,
       update(socket, :switch, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  def handle_event("ctl_radio", %{"k" => "variant", "v" => v}, socket)
      when v in ~w(outline classic),
      do: {:noreply, update(socket, :radio, &%{&1 | variant: v})}

  def handle_event("ctl_radio", %{"k" => "size", "v" => v}, socket) when v in ~w(sm md lg),
    do: {:noreply, update(socket, :radio, &%{&1 | size: v})}

  def handle_event("ctl_radio", %{"k" => "layout", "v" => v}, socket) when v in ~w(row col),
    do: {:noreply, update(socket, :radio, &%{&1 | layout: v})}

  def handle_event("ctl_select", %{"k" => k}, socket) when k in ~w(disabled error help),
    do:
      {:noreply,
       update(socket, :select, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  def handle_event("ctl_checkbox", %{"k" => "layout", "v" => v}, socket) when v in ~w(row col),
    do: {:noreply, update(socket, :checkbox, &%{&1 | layout: v})}

  def handle_event("ctl_checkbox", %{"k" => k}, socket) when k in ~w(disabled error),
    do:
      {:noreply,
       update(socket, :checkbox, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

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

  def handle_event("chat_send", %{"prompt" => prompt}, socket), do: chat_start(socket, prompt)

  def handle_event("chat_suggest", %{"prompt" => prompt}, socket), do: chat_start(socket, prompt)

  def handle_event("chat_stop", _params, socket) do
    {:noreply, assign(socket, :chat, %{socket.assigns.chat | streaming: false})}
  end

  def handle_event("chat_history", _params, socket) do
    chat = socket.assigns.chat
    {:noreply, assign(socket, :chat, %{chat | turns: @chat_history ++ chat.turns, history: true})}
  end

  def handle_event("ctl_chat", %{"k" => "variant", "v" => v}, socket)
      when v in ~w(plain bubbles) do
    {:noreply, assign(socket, :chat, %{socket.assigns.chat | variant: v})}
  end

  def handle_event("ctl_chat", %{"k" => "actions", "v" => v}, socket)
      when v in ~w(always hover) do
    {:noreply, assign(socket, :chat, %{socket.assigns.chat | actions: v})}
  end

  # edit a user message: load its text into the composer AND remember which
  # message so sending forks the thread there (ChatGPT-style), rather than
  # appending a duplicate. The app owns what "edit" does; this is the useful
  # version.
  def handle_event("chat_edit", %{"i" => i, "text" => text}, socket) do
    chat = %{socket.assigns.chat | editing: String.to_integer(i)}

    {:noreply,
     socket
     |> push_event("pc-chat-set-input", %{id: "pg-chat-composer", value: text})
     |> assign(:chat, chat)}
  end

  def handle_event("chat_cancel_edit", _params, socket) do
    {:noreply,
     socket
     |> push_event("pc-chat-set-input", %{id: "pg-chat-composer", value: ""})
     |> assign(:chat, %{socket.assigns.chat | editing: nil})}
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  defp chat_start(socket, prompt) do
    prompt = String.trim(prompt)

    if prompt == "" || socket.assigns.chat.streaming do
      {:noreply, socket}
    else
      chat = socket.assigns.chat
      seq = chat.seq + 1
      id = "pg-chat-ans-#{seq}"
      reply = Enum.at(@chat_replies, rem(seq - 1, length(@chat_replies)))
      # word-sized chunks so the stream reads like typing
      chunks = String.split(reply, ~r/(?<= )/)

      # editing forks the thread: drop the edited message and everything after
      # it, then regenerate. A plain send just appends.
      base = if chat.editing != nil, do: Enum.take(chat.turns, chat.editing), else: chat.turns

      turns =
        base ++
          [
            %{id: "u#{seq}", role: :user, text: prompt, stream_id: nil},
            %{id: "a#{seq}", role: :assistant, text: reply, stream_id: id}
          ]

      Process.send_after(self(), {:chat_tick, id, chunks}, 350)

      chat = %{
        chat
        | turns: turns,
          streaming: true,
          seq: seq,
          editing: nil,
          sent: true
      }

      {:noreply,
       socket
       |> push_event("pc-chat-set-input", %{id: "pg-chat-composer", value: ""})
       |> assign(:chat, chat)}
    end
  end

  defp patch_theme(socket, delta) do
    theme =
      socket.assigns
      |> Map.take([:active, :primary, :secondary, :gray, :radius, :dark])
      |> Map.merge(delta)

    {:noreply, push_patch(socket, to: theme_path(theme))}
  end

  defp theme_path(t) do
    []
    |> then(&if t.dark, do: [{"dark", "1"} | &1], else: &1)
    |> then(&if t.radius != "10", do: [{"radius", t.radius} | &1], else: &1)
    |> then(&if t.secondary != "pink", do: [{"secondary", t.secondary} | &1], else: &1)
    |> then(&if t.gray != "zinc", do: [{"gray", t.gray} | &1], else: &1)
    |> then(&if t.primary != "neutral", do: [{"primary", t.primary} | &1], else: &1)
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

  # Deterministic organic-looking series so the first paint is stable.
  defp gen_wave(base, phase) do
    Enum.map(1..30, fn i ->
      round(
        base + i * 9 + 260 * :math.sin((i + phase) / 4.3) + 140 * :math.sin((i + phase) / 1.7)
      )
    end)
  end

  defp revenue_option(chart) do
    datasets =
      if chart.two_series,
        do: [{"revenue", "Revenue", chart.revenue}, {"expenses", "Expenses", chart.expenses}],
        else: [{"revenue", "Revenue", chart.revenue}]

    # The shared ids + universalTransition make ECharts morph between the
    # line and bar forms when the type toggles.
    series =
      for {id, name, data} <- datasets do
        case chart.type do
          "line" ->
            %{
              id: id,
              name: name,
              type: "line",
              universalTransition: true,
              smooth: chart.shape == "smooth",
              symbolSize: 7,
              showSymbol: chart.dots,
              lineStyle: %{width: 2.5},
              data: data
            }
            |> then(&if chart.shape == "step", do: Map.put(&1, :step, "middle"), else: &1)
            |> then(fn s ->
              case chart.area do
                "fade" -> Map.put(s, :areaStyle, %{color: "petal:fade"})
                "solid" -> Map.put(s, :areaStyle, %{opacity: 0.12})
                "none" -> s
              end
            end)

          "bar" ->
            %{
              id: id,
              name: name,
              type: "bar",
              universalTransition: true,
              barGap: "6%",
              barCategoryGap: if(chart.gap == "tight", do: "12%", else: "38%"),
              data: data
            }
        end
      end

    axis_x = %{
      type: "category",
      boundaryGap: chart.type == "bar",
      axisLabel: %{interval: 3},
      data: Enum.map(1..30, &"Apr #{&1}")
    }

    base =
      if chart.chrome do
        %{
          grid: %{left: 44, right: 16, top: 16, bottom: 28},
          xAxis: axis_x,
          yAxis: %{type: "value"},
          tooltip: %{trigger: "axis"},
          series: series
        }
      else
        # Chromeless: no axis labels, no gridlines - just the shape.
        %{
          grid: %{left: 8, right: 8, top: 8, bottom: 8},
          xAxis: Map.put(axis_x, :show, false),
          yAxis: %{type: "value", show: false},
          tooltip: %{trigger: "axis"},
          series: series
        }
      end

    if chart.two_series && chart.chrome,
      do:
        Map.merge(base, %{legend: %{top: 0}, grid: %{left: 44, right: 16, top: 36, bottom: 28}}),
      else: base
  end

  defp bar_option(chart) do
    stack = if chart.stacked, do: "total"

    %{
      grid: %{left: 40, right: 8, top: 32, bottom: 28},
      legend: %{top: 0},
      tooltip: %{trigger: "axis"},
      xAxis: %{type: "category", data: ~w(Q1 Q2 Q3 Q4)},
      yAxis: %{type: "value"},
      series: [
        %{name: "Pro", type: "bar", barGap: 0, stack: stack, data: [320, 402, 391, 534]}
        |> then(&if chart.stacked, do: Map.put(&1, :itemStyle, %{borderRadius: 0}), else: &1),
        %{name: "Teams", type: "bar", stack: stack, data: [120, 182, 231, 290]}
      ]
    }
  end

  defp donut_option do
    %{
      tooltip: %{trigger: "item"},
      legend: %{bottom: 0},
      title: %{
        text: "960",
        subtext: "customers",
        left: "center",
        top: "33%",
        itemGap: 2,
        textStyle: %{fontSize: 24, fontWeight: 650},
        subtextStyle: %{fontSize: 12}
      },
      series: [
        %{
          name: "Plan",
          type: "pie",
          radius: ["48%", "72%"],
          center: ["50%", "44%"],
          avoidLabelOverlap: true,
          itemStyle: %{borderRadius: 5, borderWidth: 2},
          label: %{show: false},
          data: [
            %{value: 580, name: "Individual"},
            %{value: 260, name: "Team"},
            %{value: 120, name: "Legacy"}
          ]
        }
      ]
    }
  end

  defp chart_snippet do
    ~S"""
    <.chart
      id="revenue"
      option={%{
        xAxis: %{type: "category", data: ~w(Jan Feb Mar Apr)},
        yAxis: %{type: "value"},
        series: [
          %{type: "line", smooth: true, areaStyle: %{color: "petal:fade"}, data: @revenue}
        ]
      }}
    />
    """
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
      ~s( trigger_class="pc-button pc-button--gray-outline pc-button--md") <>
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

  @table_people [
    %{name: "Ada Lovelace", role: "Engineering", age: 36, status: "Active"},
    %{name: "Grace Hopper", role: "Engineering", age: 85, status: "Active"},
    %{name: "Alan Turing", role: "Research", age: 41, status: "Inactive"},
    %{name: "Katherine Johnson", role: "Research", age: 101, status: "Active"},
    %{name: "Edsger Dijkstra", role: "Engineering", age: 72, status: "Inactive"}
  ]

  defp sidebar_menu_items do
    [
      %{
        title: "Platform",
        menu_items: [
          %{name: :dashboard, label: "Dashboard", path: "#", icon: "hero-home"},
          %{
            name: :playground,
            label: "Playground",
            icon: "hero-command-line",
            menu_items: [
              %{name: :history, label: "History", path: "#"},
              %{name: :starred, label: "Starred", path: "#"},
              %{name: :ai_settings, label: "Settings", path: "#"}
            ]
          },
          %{name: :models, label: "Models", path: "#", icon: "hero-cube"},
          %{name: :docs, label: "Documentation", path: "#", icon: "hero-book-open"}
        ]
      },
      %{
        title: "Projects",
        menu_items: [
          %{name: :design, label: "Design Engineering", path: "#", icon: "hero-swatch"},
          %{
            name: :sales,
            label: "Sales & Marketing",
            path: "#",
            icon: "hero-presentation-chart-line"
          },
          %{name: :travel, label: "Travel", path: "#", icon: "hero-map"}
        ]
      }
    ]
  end

  defp pg_step_defs do
    [
      %{name: "Account", description: "Email and password"},
      %{name: "Workspace", description: "Name your project"},
      %{name: "Invite", description: "Bring the team"},
      %{name: "Review", description: "Confirm and finish"}
    ]
  end

  defp pg_steps(at, done) do
    pg_step_defs()
    |> Enum.with_index()
    |> Enum.map(fn {step, i} ->
      step
      |> Map.put(:complete?, done || i < at)
      |> Map.put(:active?, !done && i == at)
      |> Map.put(
        :on_click,
        Phoenix.LiveView.JS.push("ctl_stepper", value: %{k: "goto", v: to_string(i)})
      )
    end)
  end

  defp table_rows(%{sort_by: key, sort_dir: dir}) do
    key = String.to_existing_atom(key)
    Enum.sort_by(@table_people, & &1[key], if(dir == "asc", do: :asc, else: :desc))
  end

  defp rating_snippet(assigns) do
    name = %{"star" => "score", "heart" => "love", "face" => "mood"}[assigns.rating.icon]
    precision = if assigns.rating.step == "half", do: ~s| precision="half"|, else: ""

    ~s|<form phx-change="rate">
  <.rating interactive name="#{name}" rating={@#{name}} icon="#{assigns.rating.icon}"#{precision} size="#{assigns.rating.size}" />
</form>|
  end

  def render(assigns) do
    ~H"""
    <div
      class={[
        "flex flex-col h-screen bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-50",
        @dark && "dark"
      ]}
      data-primary={@primary}
      data-gray={@gray}
      data-secondary={@secondary}
      style={"--pc-radius: #{radius_css(@radius)}"}
    >
      <header class="flex items-center justify-between flex-none px-4 border-b h-14 border-gray-200 dark:border-gray-800">
        <div class="flex items-center gap-2 text-[15px] font-semibold">
          <svg viewBox="0 0 512 512" class="w-5 h-5" aria-hidden="true">
            <path
              d="M230.003 125.876C240.013 163.648 236.787 202.614 225.872 222.08C205.825 218.645 165.131 177.459 154.643 142.091C146.575 114.884 141.211 61.5546 163.147 42.9603C181.2 48.0856 206.638 59.5304 230.003 125.876Z"
              fill="#7C3AED"
            />
            <path
              d="M131.821 194.829C174.63 205.417 202.334 225.678 214.021 244.543C201.178 260.41 145.154 276.223 109.043 268.435C81.2645 262.444 31.9419 241.573 26.4252 213.497C39.7695 200.183 86.0939 184.721 131.821 194.829Z"
              fill="#8C3CE1"
            />
            <path
              d="M134.395 304.982C169.081 273.136 202.487 268.276 224.626 270.582C229.181 290.377 206.903 344.143 178.354 367.829C156.393 386.049 109.322 412.156 83.7427 399.371C81.5135 380.738 93.3967 339.963 134.395 304.982Z"
              fill="#9C3ED6"
            />
            <path
              d="M231.851 387.183C232.759 332.248 238.002 310.308 252.007 292.916C271.176 299.651 304.367 347.093 308.781 383.753C312.177 411.953 308.543 465.487 283.829 480.18C266.907 472.108 231.642 429.293 231.851 387.183Z"
              fill="#AD40C9"
            />
            <path
              d="M334.122 361.502C304.16 336.45 293.796 314.74 291.865 296.983C306.635 289.867 352.611 297.682 376.032 315.802C394.047 329.74 422.5 361.935 416.786 384.265C402.535 389.351 361.449 384.351 334.122 361.502Z"
              fill="#BA42BF"
            />
            <path
              d="M403.327 299.046C368.688 285.832 356.017 277.465 348.32 264.596C357.161 254.009 395.173 243.911 419.486 249.551C438.188 253.889 471.288 268.507 474.721 287.534C465.567 296.391 438.764 306.747 403.327 299.046Z"
              fill="#CB44B2"
            />
            <path
              d="M434.34 229.57C407.147 225.737 396.619 221.79 388.943 213.786C393.589 204.711 419.385 191.202 437.873 191.274C452.095 191.33 478.408 196.427 484.016 209.566C478.86 217.447 461.203 229.303 434.34 229.57Z"
              fill="#D445AB"
            />
          </svg>
          petal <span class="font-normal text-gray-400 dark:text-gray-500">playground</span>
        </div>
        <div class="flex items-center gap-1.5">
          <button
            phx-click={PetalComponents.Command.open_command("pg-cmdk")}
            class="hidden md:flex items-center gap-2 h-8 pl-3 pr-2 mr-1 text-sm text-gray-400 border rounded-lg w-56 border-gray-200 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-gray-900"
          >
            <.icon name="hero-magnifying-glass" class="w-4 h-4" />
            <span>Search components</span>
            <kbd class="pc-kbd ml-auto">⌘K</kbd>
          </button>
          <a
            href="https://github.com/petalframework/petal_components"
            target="_blank"
            class="flex items-center h-8 gap-1.5 px-2.5 text-sm rounded-lg text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-900"
          >
            <svg viewBox="0 0 438.549 438.549" class="w-4 h-4" fill="currentColor"><path d="M409.132 114.573c-19.608-33.596-46.205-60.194-79.798-79.8-33.598-19.607-70.277-29.408-110.063-29.408-39.781 0-76.472 9.804-110.063 29.408-33.596 19.605-60.192 46.204-79.8 79.8C9.803 148.168 0 184.854 0 224.63c0 47.78 13.94 90.745 41.827 128.906 27.884 38.164 63.906 64.572 108.063 79.227 5.14.954 8.945.283 11.419-1.996 2.475-2.282 3.711-5.14 3.711-8.562 0-.571-.049-5.708-.144-15.417a2549.81 2549.81 0 01-.144-25.406l-6.567 1.136c-4.187.767-9.469 1.092-15.846 1-6.374-.089-12.991-.757-19.842-1.999-6.854-1.231-13.229-4.086-19.13-8.559-5.898-4.473-10.085-10.328-12.56-17.556l-2.855-6.57c-1.903-4.374-4.899-9.233-8.992-14.559-4.093-5.331-8.232-8.945-12.419-10.848l-1.999-1.431c-1.332-.951-2.568-2.098-3.711-3.429-1.142-1.331-1.997-2.663-2.568-3.997-.572-1.335-.098-2.43 1.427-3.289 1.525-.859 4.281-1.276 8.28-1.276l5.708.853c3.807.763 8.516 3.042 14.133 6.851 5.614 3.806 10.229 8.754 13.846 14.842 4.38 7.806 9.657 13.754 15.846 17.847 6.184 4.093 12.419 6.136 18.699 6.136 6.28 0 11.704-.476 16.274-1.423 4.565-.952 8.848-2.383 12.847-4.285 1.713-12.758 6.377-22.559 13.988-29.41-10.848-1.14-20.601-2.857-29.264-5.14-8.658-2.286-17.605-5.996-26.835-11.14-9.235-5.137-16.896-11.516-22.985-19.126-6.09-7.614-11.088-17.61-14.987-29.979-3.901-12.374-5.852-26.648-5.852-42.826 0-23.035 7.52-42.637 22.557-58.817-7.044-17.318-6.379-36.732 1.997-58.24 5.52-1.715 13.706-.428 24.554 3.853 10.85 4.283 18.794 7.952 23.84 10.994 5.046 3.041 9.089 5.618 12.135 7.708 17.705-4.947 35.976-7.421 54.818-7.421s37.117 2.474 54.823 7.421l10.849-6.849c7.419-4.57 16.18-8.758 26.262-12.565 10.088-3.805 17.802-4.853 23.134-3.138 8.562 21.509 9.325 40.922 2.279 58.24 15.036 16.18 22.559 35.787 22.559 58.817 0 16.178-1.958 30.497-5.853 42.966-3.9 12.471-8.941 22.457-15.125 29.979-6.191 7.521-13.901 13.85-23.131 18.986-9.232 5.14-18.182 8.85-26.84 11.136-8.662 2.286-18.415 4.004-29.263 5.146 9.894 8.562 14.842 22.077 14.842 40.539v60.237c0 3.422 1.19 6.279 3.572 8.562 2.379 2.279 6.136 2.95 11.276 1.995 44.163-14.653 80.185-41.062 108.068-79.226 27.88-38.161 41.825-81.126 41.825-128.906-.01-39.771-9.818-76.454-29.414-110.049z" /></svg>
            <span class="text-xs tabular-nums">{fmt_stars(@stars)}</span>
          </a>
          <a
            href="https://discord.com/invite/exbwVbjAct"
            target="_blank"
            aria-label="Discord"
            class="flex items-center justify-center w-8 h-8 rounded-lg text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-900"
          >
            <svg viewBox="0 0 24 24" class="w-4 h-4" fill="currentColor"><path d="M20.317 4.37a19.79 19.79 0 0 0-4.885-1.515a.074.074 0 0 0-.079.037c-.21.375-.444.865-.608 1.25a18.27 18.27 0 0 0-5.487 0a12.64 12.64 0 0 0-.617-1.25a.077.077 0 0 0-.079-.037A19.74 19.74 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057a19.9 19.9 0 0 0 5.993 3.03a.078.078 0 0 0 .084-.028a14.09 14.09 0 0 0 1.226-1.994a.076.076 0 0 0-.041-.106a13.107 13.107 0 0 1-1.872-.892a.077.077 0 0 1-.008-.128a10.2 10.2 0 0 0 .372-.292a.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127a12.299 12.299 0 0 1-1.873.892a.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028a19.839 19.839 0 0 0 6.002-3.03a.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419c0-1.333.956-2.419 2.157-2.419c1.21 0 2.176 1.096 2.157 2.42c0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419c0-1.333.955-2.419 2.157-2.419c1.21 0 2.176 1.096 2.157 2.42c0 1.333-.946 2.418-2.157 2.418z" /></svg>
          </a>
          <a
            href="https://x.com/PetalFramework"
            target="_blank"
            aria-label="X"
            class="flex items-center justify-center w-8 h-8 rounded-lg text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-900"
          >
            <svg viewBox="0 0 24 24" class="w-3.5 h-3.5" fill="currentColor"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" /></svg>
          </a>
          <button
            phx-click={JS.dispatch("pg:theme-switch") |> JS.push("toggle_dark")}
            aria-label="Toggle dark mode"
            class="flex items-center justify-center w-8 h-8 rounded-lg text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-900"
          >
            <.icon :if={@dark} name="hero-sun" class="w-4 h-4" />
            <.icon :if={!@dark} name="hero-moon" class="w-3.5 h-3.5" />
          </button>
        </div>
      </header>

      <div class="flex items-center flex-none h-11 gap-5 px-4 border-b border-gray-200 dark:border-gray-800 bg-gray-50/60 dark:bg-gray-900/30">
        <div class="flex items-center gap-2.5">
          <span class="text-[11px] font-medium text-gray-400 dark:text-gray-500">primary</span>
          <div class="flex items-center gap-1.5">
            <button
              :for={{name, css} <- @primaries}
              phx-click="set_primary"
              phx-value-primary={name}
              aria-label={"primary #{name}"}
              class={[
                "w-4.5 h-4.5 rounded-full transition-transform hover:scale-110",
                @primary == name &&
                  "ring-2 ring-offset-2 ring-gray-400 dark:ring-gray-500 ring-offset-gray-50 dark:ring-offset-gray-950"
              ]}
              style={"background:#{css}"}
            ></button>
          </div>
        </div>
        <div class="flex items-center gap-2.5">
          <span class="text-[11px] font-medium text-gray-400 dark:text-gray-500">secondary</span>
          <div class="flex items-center gap-1.5">
            <button
              :for={{name, css} <- @secondaries}
              phx-click="set_secondary"
              phx-value-secondary={name}
              aria-label={"secondary #{name}"}
              class={[
                "w-4.5 h-4.5 rounded-full transition-transform hover:scale-110",
                @secondary == name &&
                  "ring-2 ring-offset-2 ring-gray-400 dark:ring-gray-500 ring-offset-gray-50 dark:ring-offset-gray-950"
              ]}
              style={"background:#{css}"}
            ></button>
          </div>
        </div>
        <div class="flex items-center gap-2.5">
          <span class="text-[11px] font-medium text-gray-400 dark:text-gray-500">gray</span>
          <div class="flex items-center gap-1.5">
            <button
              :for={{name, css} <- @grays}
              phx-click="set_gray"
              phx-value-gray={name}
              aria-label={"gray #{name}"}
              title={name}
              class={[
                "w-4.5 h-4.5 rounded-full transition-transform hover:scale-110",
                @gray == name &&
                  "ring-2 ring-offset-2 ring-gray-400 dark:ring-gray-500 ring-offset-gray-50 dark:ring-offset-gray-950"
              ]}
              style={"background:#{css}"}
            ></button>
          </div>
        </div>
        <div class="flex items-center gap-2.5">
          <span class="text-[11px] font-medium text-gray-400 dark:text-gray-500">radius</span>
          <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
        <span class="hidden ml-auto text-[11px] text-gray-400 dark:text-gray-600 sm:block">
          theme is in the URL, share the look
        </span>
      </div>

      <.command_dialog id="pg-cmdk" loop>
        <.command_input placeholder="Search components and actions..." />
        <.command_list label="Playground">
          <.command_empty>Nothing matches. Try a component name.</.command_empty>
          <.command_group :for={grp <- @nav} heading={grp.group}>
            <.command_item
              :for={item <- grp.items}
              phx-click="select"
              phx-value-slug={item.slug}
            >
              <.icon name="hero-square-3-stack-3d" /> {item.name}
            </.command_item>
          </.command_group>
          <.command_separator />
          <.command_group heading="Theme">
            <.command_item phx-click="toggle_dark" keywords={["light", "theme", "mode"]}>
              <.icon name="hero-moon" /> Toggle dark mode
            </.command_item>
          </.command_group>
        </.command_list>
      </.command_dialog>

      <div class="flex flex-1 min-h-0">
        <nav class="flex-none p-3 overflow-y-auto border-r w-52 border-gray-200 dark:border-gray-800">
          <div :for={grp <- @nav}>
            <div class="px-2 pt-4 pb-1 text-[11px] font-medium tracking-wide text-gray-400 dark:text-gray-500">
              {grp.group}
            </div>
            <button
              :for={it <- grp.items}
              phx-click="select"
              phx-value-slug={it.slug}
              class={[
                "w-full flex items-center px-2.5 py-1.5 rounded-lg text-sm text-left transition-colors",
                (@active == it.slug &&
                   "bg-gray-100 dark:bg-gray-800 text-gray-900 dark:text-gray-50 font-medium") ||
                  "text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-900 hover:text-gray-900 dark:hover:text-gray-100"
              ]}
            >
              {it.name}
              <span
                :if={not it.ready}
                class="ml-auto text-[10px] px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800/80 text-gray-400 dark:text-gray-500"
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
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Triggers an action. Five variants, plus a semantic range for when the action carries meaning.
        The colour dials and radius up top restyle everything live.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">colour</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
          class="px-6 pb-3 -mt-1 text-xs text-gray-400 dark:text-gray-500"
        >
          colour always tints - the default primary is monochrome, so its outline reads neutral until you dial a hue up top; secondary follows the second dial
        </p>
      </div>

      <button
        phx-click="flip"
        phx-value-k="show_code"
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"
      ><code>{button_snippet(assigns)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Variants</div>
      <div class="flex flex-wrap items-center justify-center gap-3 px-6 py-10 border border-gray-200 rounded-xl dark:border-gray-800">
        <.button>Solid</.button>
        <.button variant="soft">Soft</.button>
        <.button variant="light">Light</.button>
        <.button variant="outline">Outline</.button>
        <.button variant="ghost">Ghost</.button>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Semantic colours
      </div>
      <div class="flex flex-wrap items-center justify-center gap-3 px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <.button color="info" variant={@variant}>Info</.button>
        <.button color="success" variant={@variant}>Success</.button>
        <.button color="warning" variant={@variant}>Warning</.button>
        <.button color="danger" variant={@variant}>Danger</.button>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Sizes</div>
      <div class="flex flex-wrap items-center justify-center gap-3 px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <.button size="xs">Extra small</.button>
        <.button size="sm">Small</.button>
        <.button size="md">Medium</.button>
        <.button size="lg">Large</.button>
        <.button size="xl">Extra large</.button>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">States</div>
      <div class="flex flex-wrap items-center justify-center gap-3 px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <.button>Default</.button>
        <.button icon="hero-rocket-launch">With icon</.button>
        <.button loading>Loading</.button>
        <.button disabled>Disabled</.button>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Icon button</div>
      <div class="flex flex-wrap items-center justify-center gap-3 px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
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
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        One field surface for every type: label, control, help and error.
        Border, radius and focus ring follow the rail above.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">type</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"
      ><code>{field_snippet(@input)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Anatomy</div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
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

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Error state</div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
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

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        In-field actions
      </div>
      <div class="px-6 py-8 space-y-6 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="max-w-sm mx-auto space-y-6">
          <.field
            type="password"
            name="pw_viewable"
            label="Password (viewable)"
            value="hunter2hunter2"
            viewable
            no_margin
          />
          <.field
            type="text"
            name="api_key"
            label="API key (copyable)"
            value="pk_live_51J8s0"
            copyable
            no_margin
          />
          <.field
            type="search"
            name="q"
            label="Search (clearable)"
            value="petal components"
            clearable
            no_margin
          />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Input group</div>
      <div class="px-6 py-8 space-y-6 border border-gray-200 rounded-xl dark:border-gray-800">
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

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Select and checkbox
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
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
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A light beam tracing the border - pure CSS on an offset-path, with the
        tail fading smoothly around corners at any aspect ratio. The panel
        follows the rail radius.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
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
              <div class="text-xs font-medium tracking-wide uppercase text-gray-400">Now free</div>
              <div class="mt-2 text-lg font-semibold text-gray-900 dark:text-gray-100">
                Aurora and border beam
              </div>
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                Both live in the open source library now.
              </p>
            </div>
          </.border_beam>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">duration</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
          class="px-6 pb-3 -mt-1 text-xs text-gray-400 dark:text-gray-500"
        >
          spring is a single-beam motion - with multiple beams the chase runs at constant speed
        </p>
        <p
          :if={@beam.size == "160px" and not @beam.glow}
          class="px-6 pb-3 -mt-1 text-xs text-gray-400 dark:text-gray-500"
        >
          a long sharp beam clamps to the panel for corner safety - turn on glow for the full length
        </p>
      </div>

      <button
        phx-click="flip"
        phx-value-k="show_code"
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"
      ><code>{beam_snippet(@beam)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Now playing (two long glow beams)
      </div>
      <div class="px-6 py-14 border border-gray-200 rounded-xl dark:border-gray-800">
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
            <div class="mt-1.5 text-sm text-gray-500 dark:text-gray-400">
              Stairway to Heaven - Led Zeppelin
            </div>
            <div class="w-40 h-40 mx-auto mt-5 rounded-lg bg-gradient-to-br from-purple-500 to-pink-500">
            </div>
            <div class="mt-5">
              <.progress value={34} size="xs" />
            </div>
            <div class="flex justify-between mt-2 text-sm text-gray-500 dark:text-gray-400">
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

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Spring release (a button-sized lap)
      </div>
      <div class="px-6 py-14 border border-gray-200 rounded-xl dark:border-gray-800">
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
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A slow, ambient shimmer sweeping the border - the quiet sibling of the
        border beam. Pure CSS, and it holds still for reduced-motion users.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
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
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                Unlimited projects and priority support.
              </p>
            </div>
          </.shine_border>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">colour</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"
      ><code>{shine_snippet(@shine)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        On an input (thicker border)
      </div>
      <div class="px-6 py-14 border border-gray-200 rounded-xl dark:border-gray-800">
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

  defp render_page(%{active: "chart"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Chart</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Apache ECharts behind a declarative HEEx component. The spec is a plain Elixir map,
        and every colour derives from your tokens at mount - flip the primary or gray dial
        up top and the charts follow. Updating an assign animates the chart in place.
      </p>

      <div class="mt-8 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Live updates - change the assign, the chart morphs
      </div>
      <div class="border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="px-6 py-6">
          <.chart id="pg-chart-revenue" option={revenue_option(@chart)} height="16rem" />
        </div>
        <div class="flex flex-wrap items-end gap-x-6 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-gray-800">
          <.button size="sm" variant="outline" phx-click="chart_randomize" label="Randomize data" />
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">type</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={t <- ~w(line bar)}
                phx-click="ctl_chart"
                phx-value-k="type"
                phx-value-v={t}
                class={seg(@chart.type == t)}
              >
                {t}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">series</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button phx-click="ctl_chart" phx-value-k="two_series" class={seg(!@chart.two_series)}>
                one
              </button>
              <button phx-click="ctl_chart" phx-value-k="two_series" class={seg(@chart.two_series)}>
                two
              </button>
            </div>
          </div>
          <div :if={@chart.type == "bar"}>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">gap</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={g <- ~w(cozy tight)}
                phx-click="ctl_chart"
                phx-value-k="gap"
                phx-value-v={g}
                class={seg(@chart.gap == g)}
              >
                {g}
              </button>
            </div>
          </div>
          <div :if={@chart.type == "line"}>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">area</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={a <- ~w(fade solid none)}
                phx-click="ctl_chart"
                phx-value-k="area"
                phx-value-v={a}
                class={seg(@chart.area == a)}
              >
                {a}
              </button>
            </div>
          </div>
          <div :if={@chart.type == "line"}>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">shape</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={s <- ~w(smooth linear step)}
                phx-click="ctl_chart"
                phx-value-k="shape"
                phx-value-v={s}
                class={seg(@chart.shape == s)}
              >
                {s}
              </button>
            </div>
          </div>
          <div :if={@chart.type == "line"}>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">dots</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button phx-click="ctl_chart" phx-value-k="dots" class={seg(@chart.dots)}>on</button>
              <button phx-click="ctl_chart" phx-value-k="dots" class={seg(!@chart.dots)}>off</button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">chrome</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button phx-click="ctl_chart" phx-value-k="chrome" class={seg(@chart.chrome)}>on</button>
              <button phx-click="ctl_chart" phx-value-k="chrome" class={seg(!@chart.chrome)}>
                off
              </button>
            </div>
          </div>
        </div>
      </div>
      <pre class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"><code>{chart_snippet()}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Bar + donut - the palette is the --pc-chart-* token group
      </div>
      <div class="grid gap-6 sm:grid-cols-2">
        <div class="px-4 py-5 border border-gray-200 rounded-xl dark:border-gray-800">
          <.chart id="pg-chart-bar" option={bar_option(@chart)} height="14rem" />
          <div class="flex justify-center mt-3">
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button phx-click="ctl_chart" phx-value-k="stacked" class={seg(!@chart.stacked)}>
                grouped
              </button>
              <button phx-click="ctl_chart" phx-value-k="stacked" class={seg(@chart.stacked)}>
                stacked
              </button>
            </div>
          </div>
        </div>
        <div class="px-4 py-5 border border-gray-200 rounded-xl dark:border-gray-800">
          <.chart id="pg-chart-donut" option={donut_option()} height="14rem" />
        </div>
      </div>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Sparkline - pure server-rendered SVG, zero JavaScript
      </div>
      <div class="grid gap-4 sm:grid-cols-3">
        <div
          :for={
            {label, value, delta, data, color} <- [
              {"MRR", "$12,480", "+8.2%", [8, 9, 9, 11, 10, 12, 13, 14], "text-primary-500"},
              {"Signups", "1,204", "+3.1%", [30, 34, 31, 38, 36, 41, 40, 44], "text-success-500"},
              {"Churn", "1.9%", "-0.4%", [9, 8, 9, 7, 8, 6, 7, 5], "text-danger-500"}
            ]
          }
          class="flex items-center justify-between px-5 py-4 border border-gray-200 rounded-xl dark:border-gray-800"
        >
          <div>
            <div class="text-xs text-gray-400 dark:text-gray-500">{label}</div>
            <div class="mt-1 text-xl font-semibold">{value}</div>
            <div class="mt-0.5 text-xs text-gray-400 dark:text-gray-500">{delta} this month</div>
          </div>
          <.sparkline data={data} class={"h-10 w-28 #{color}"} />
        </div>
      </div>
      <pre class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"><code>{~s|<.sparkline data={[8, 9, 9, 11, 10, 12, 13, 14]} class="h-10 w-28 text-primary-500" />|}</code></pre>
    </div>
    """
  end

  defp render_page(%{active: "meteors"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Meteors</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A meteor shower inside any container - positions generated server-side,
        so it costs zero JavaScript and never jumps on re-render.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="px-6 py-8">
          <div class="relative w-full overflow-hidden bg-gray-950 rounded-xl h-56">
            <.meteors
              count={@meteors.count}
              angle={@meteors.angle}
              color={meteor_color(@meteors.color)}
              reverse={@meteors.reverse}
              seed={@meteors.seed}
            />
            <div class="relative flex flex-col items-center justify-center h-full text-center">
              <div class="text-lg font-semibold text-white">Ship something tonight</div>
              <div class="mt-1 text-sm text-gray-400">Meteors sit behind your content.</div>
            </div>
          </div>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">count</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"
      ><code>{meteor_snippet(@meteors)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Deterministic (same seed, same sky)
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="relative w-full max-w-lg mx-auto overflow-hidden border border-gray-200 rounded-xl h-40 dark:border-gray-800 dark:bg-gray-900">
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
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        The refined 4.2 scale: self-composing vertical rhythm, balanced
        headings, and a three-tier emphasis system that holds in both modes.
      </p>

      <div class="mt-8 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Headings</div>
      <div class="px-8 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <.h1>The quick brown fox</.h1>
        <.h2>The quick brown fox</.h2>
        <.h3>The quick brown fox</.h3>
        <.h4>The quick brown fox</.h4>
        <.h5>The quick brown fox</.h5>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Body and emphasis tiers
      </div>
      <div class="px-8 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <.lead>
          A lead paragraph sits between heading and body - one size up, muted a step.
        </.lead>
        <.p>
          Default body copy carries the middle emphasis tier. It pairs
          <.inline_code>inline_code</.inline_code>
          with <strong>strong text</strong>
          at the top tier, and stays readable
          across light and dark without per-mode overrides.
        </.p>
        <.text_muted>Muted text is the quiet tier - captions, hints, timestamps.</.text_muted>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Structure</div>
      <div class="px-8 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
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
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Four roles: primary is your base action colour (monochrome by
        default), secondary is your brand accent, semantics carry meaning,
        gray is the chrome. One rule everywhere: colour picks the ramp,
        variant picks the treatment - both dials up top restyle every
        component live.
      </p>

      <div class="mt-8 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Primary (first dial - monochrome by default)
      </div>
      <div class="px-6 py-6 border border-gray-200 rounded-xl dark:border-gray-800">
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
          <div
            :for={stop <- ~w(50 100 200 300 400 500 600 700 800 900 950)}
            class="flex-1 text-center"
          >
            {stop}
          </div>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Secondary (second dial - the brand accent)
      </div>
      <div class="px-6 py-6 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex overflow-hidden rounded-lg">
          <div
            :for={stop <- ~w(50 100 200 300 400 500 600 700 800 900 950)}
            class="flex-1 h-14"
            style={"background-color: var(--color-secondary-#{stop})"}
            title={"secondary-#{stop}"}
          >
          </div>
        </div>
        <div class="flex mt-1.5 text-[10px] text-gray-400">
          <div
            :for={stop <- ~w(50 100 200 300 400 500 600 700 800 900 950)}
            class="flex-1 text-center"
          >
            {stop}
          </div>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Semantic ramps (fixed hues)
      </div>
      <div class="px-6 py-6 space-y-3 border border-gray-200 rounded-xl dark:border-gray-800">
        <div :for={c <- ~w(info success warning danger)} class="flex items-center gap-3">
          <div class="w-16 text-xs text-gray-500 dark:text-gray-400">{c}</div>
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

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Gray (zinc) - the chrome family
      </div>
      <div class="px-6 py-6 border border-gray-200 rounded-xl dark:border-gray-800">
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
          <div
            :for={stop <- ~w(50 100 200 300 400 500 600 700 800 900 950)}
            class="flex-1 text-center"
          >
            {stop}
          </div>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        In your app, primary and secondary are plain ramps in colors.css -
        map each to any hue below (or keep primary monochrome for the
        shadcn look). The surface tokens - washes at 500/15, borders at
        600/30 light and 500/40 dark, solids at 600 - are derived from the
        ramps, which is why one dial swap restyles every component.
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        The Tailwind palette - what you map primary and secondary from
      </div>
      <div class="px-6 py-6 space-y-2 border border-gray-200 rounded-xl dark:border-gray-800">
        <div :for={{hue, ramp} <- @tw_palette} class="flex items-center gap-3">
          <div class="w-16 text-xs text-gray-500 dark:text-gray-400">{hue}</div>
          <div class="flex flex-1 overflow-hidden rounded-md">
            <div
              :for={{stop, value} <- Enum.zip(~w(50 100 200 300 400 500 600 700 800 900 950), ramp)}
              class="flex-1 h-6"
              style={"background-color: #{value}"}
              title={"#{hue}-#{stop}"}
            >
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_page(%{active: "command"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Command</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        The ⌘K palette. Type to filter, arrows to move, Enter to run. Items are real
        links and buttons, so navigate/patch and any phx binding just work. Filtering is
        client-side - keystrokes never wait on the server.
      </p>

      <div :for={ex <- PetalComponents.Showcase.Command.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Command} function={:command} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Command</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "dropdown"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Dropdown</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Menus on the floating-panel surface: group labels, separators, icons,
        keyboard hints and destructive items. Triggers follow the rail radius.
      </p>

      <div class="mt-8 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Account menu</div>
      <div class="px-6 pt-10 border border-gray-200 rounded-xl dark:border-gray-800 pb-72">
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

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Row actions (ellipsis trigger) and a custom trigger
      </div>
      <div class="px-6 pt-10 border border-gray-200 rounded-xl dark:border-gray-800 pb-56">
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
          <.dropdown placement="right" trigger_class="pc-button pc-button--primary pc-button--md">
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

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Triggers are chrome: the built-in labelled trigger and the ghost
        ellipsis stay neutral gray whatever your palette (only their focus
        ring rides primary). A custom trigger is your own button - brand it
        when the action deserves it, like the solid one above, and it follows
        your colour dials. Items are links or buttons (a / live_patch /
        live_redirect / button) and take arbitrary content: icons, .pc-kbd
        hints, custom classes for destructive actions. dropdown_menu_label
        and dropdown_menu_separator organise groups.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "modal"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Modal</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Dialog on the panel surface with a proper scrim. Escape and
        click-away close it; the box radius scales gently with the rail.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center px-6 py-16">
          <.button color="gray" variant="outline" phx-click={show_modal("pg-modal")}>
            Open modal
          </.button>
        </div>
      </div>

      <.modal id="pg-modal" title="Invite your team" hide max_width="sm">
        <p class="text-sm text-gray-500 dark:text-gray-400">
          Share this link with your teammates and they'll join the workspace
          with member access.
        </p>
        <div class="mt-4">
          <.input_group>
            <.input type="text" name="invite_url" value="https://example.com/join/x1y2z3" readonly />
            <:trailing><kbd>&#8984;C</kbd></:trailing>
          </.input_group>
        </div>
        <div class="flex justify-end gap-2 mt-6">
          <.button color="gray" variant="outline" phx-click={hide_modal("pg-modal")}>Cancel</.button>
          <.button phx-click={hide_modal("pg-modal")}>Copy link</.button>
        </div>
      </.modal>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
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
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Determinate progress on a washed track. The bar animates between
        values - click the value control and watch it move.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">value</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"
      ><code>{progress_snippet(@progress)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Semantic colours
      </div>
      <div class="px-6 py-8 space-y-4 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="max-w-md mx-auto space-y-4">
          <.progress value={80} color="success" />
          <.progress value={55} color="info" />
          <.progress value={35} color="warning" />
          <.progress value={15} color="danger" />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Sizes</div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="max-w-md mx-auto space-y-4">
          <.progress :for={z <- ~w(xs sm md lg)} value={60} size={z} />
          <.progress value={60} size="xl" label="60%" />
          <.progress value={56} size="sm" label="Upload progress" label_position="top" />
        </div>
      </div>
    </div>
    """
  end

  defp render_page(%{active: "rating"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Rating</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Click one - it's a real radio group, so it posts in forms, arrow keys work, and the
        hover preview is pure CSS. Zero JavaScript.
      </p>

      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center justify-center gap-3 px-6 py-14">
          <form :if={@rating.icon == "star"} phx-change="rate">
            <.rating
              interactive
              name="score"
              rating={@rating.value}
              icon="star"
              size={@rating.size}
              precision={@rating.step}
              include_label={@rating.label != "none"}
              label_position={if @rating.label == "none", do: "right", else: @rating.label}
            />
          </form>
          <form :if={@rating.icon == "heart"} phx-change="rate">
            <.rating
              interactive
              name="love"
              rating={@rating.hearts}
              icon="heart"
              size={@rating.size}
              precision={@rating.step}
              include_label={@rating.label != "none"}
              label_position={if @rating.label == "none", do: "right", else: @rating.label}
            />
          </form>
          <form :if={@rating.icon == "face"} phx-change="rate">
            <.rating
              interactive
              name="mood"
              rating={@rating.mood}
              icon="face"
              size={@rating.size}
              include_label={@rating.label != "none"}
              label_position={if @rating.label == "none", do: "right", else: @rating.label}
            />
          </form>
        </div>

        <div class="grid gap-5 px-6 py-5 border-t border-gray-100 md:grid-cols-2 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">icon</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={i <- ~w(star heart face)}
                phx-click="ctl_rating"
                phx-value-k="icon"
                phx-value-v={i}
                class={seg(@rating.icon == i)}
              >
                {i}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={sz <- ~w(sm md lg)}
                phx-click="ctl_rating"
                phx-value-k="size"
                phx-value-v={sz}
                class={seg(@rating.size == sz)}
              >
                {sz}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">step</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                phx-click="ctl_rating"
                phx-value-k="step"
                phx-value-v="whole"
                class={seg(@rating.step == "whole")}
              >
                1
              </button>
              <button
                phx-click="ctl_rating"
                phx-value-k="step"
                phx-value-v="half"
                disabled={@rating.icon == "face"}
                class={[
                  seg(@rating.step == "half"),
                  @rating.icon == "face" && "opacity-40 cursor-not-allowed"
                ]}
              >
                ½
              </button>
            </div>
            <p :if={@rating.icon == "face"} class="mt-1.5 text-[11px] text-gray-400">
              faces are an ordinal scale - always whole
            </p>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">label</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={l <- ~w(none right bottom)}
                phx-click="ctl_rating"
                phx-value-k="label"
                phx-value-v={l}
                class={seg(@rating.label == l)}
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
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"
      ><code>{rating_snippet(assigns)}</code></pre>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        The sentiment scale - each face is its own expression and colour
      </div>
      <div class="px-6 py-10 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center gap-6">
          <.rating
            interactive
            name="csat"
            rating={0}
            icon="face"
            size="lg"
            label="How was your experience?"
          />
          <p class="text-sm text-gray-500 dark:text-gray-400">How was your support experience?</p>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Display only - fractional values, any total
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center gap-4">
          <.rating rating={3.5} include_label />
          <.rating rating={3.5} icon="heart" include_label />
          <.rating rating={4.2} icon="face" include_label />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Bring your own glyph - the :glyph slot + one colour token
      </div>
      <div class="px-6 py-10 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center gap-2">
          <.rating
            interactive
            name="heat"
            rating={3}
            label="Spice level"
            style="--pc-rating-active-color: var(--color-orange-500)"
          >
            <:glyph>
              <svg viewBox="0 0 24 24" fill="currentColor" class="pc-rating__icon">
                <path
                  fill-rule="evenodd"
                  d="M12.963 2.286a.75.75 0 00-1.071-.136 9.742 9.742 0 00-3.539 6.176 7.547 7.547 0 01-1.705-1.715.75.75 0 00-1.152-.082A9 9 0 1015.68 4.534a7.46 7.46 0 01-2.717-2.248zM15.75 14.25a3.75 3.75 0 11-7.313-1.172c.628.465 1.35.81 2.133 1a5.99 5.99 0 011.925-3.545 3.75 3.75 0 013.255 3.717z"
                  clip-rule="evenodd"
                />
              </svg>
            </:glyph>
          </.rating>
          <p class="text-sm text-gray-500 dark:text-gray-400">Spice level</p>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Interactive mode is a fieldset of radios: the value posts under name like any form
        field, arrows move between options, and focus-visible rings the focused icon.
        precision="half" doubles the hit areas so 3.5 is clickable (and arrow keys step by
        halves) - still radios, still zero JavaScript. Faces are a discrete five-point
        scale, so they always step whole and fractional display values round to the nearest
        expression with the label carrying the precision. Any icon set can be recoloured per
        instance with --pc-rating-active-color, and the :glyph slot swaps in your own icon
        entirely.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "slide-over"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Slide over</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        An edge-attached panel (a "sheet") for forms and detail views that don't warrant a
        full page. Slides from any edge, scrolls its body, pins its footer.
      </p>

      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center px-6 py-16">
          <.button
            color="gray"
            variant="outline"
            phx-click={PetalComponents.SlideOver.show_slide_over(@slideover.origin, "pg-sheet")}
          >
            <.icon name="hero-pencil-square" class="w-4 h-4 mr-1" /> Edit profile
          </.button>
        </div>

        <div class="grid gap-5 px-6 py-5 border-t border-gray-100 md:grid-cols-2 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">origin</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={o <- ~w(left right top bottom)}
                phx-click="ctl_slideover"
                phx-value-k="origin"
                phx-value-v={o}
                class={seg(@slideover.origin == o)}
              >
                {o}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">
              max width (left/right)
            </div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={w <- ~w(sm md lg)}
                phx-click="ctl_slideover"
                phx-value-k="width"
                phx-value-v={w}
                class={seg(@slideover.width == w)}
              >
                {w}
              </button>
            </div>
          </div>
        </div>
      </div>

      <.slide_over
        id="pg-sheet"
        hide
        origin={@slideover.origin}
        max_width={@slideover.width}
        title="Edit profile"
        description="Make changes to your profile here. Click save when you're done."
      >
        <div class="flex flex-col gap-4">
          <.field type="text" name="name" value="Alex Rivera" label="Name" />
          <.field type="text" name="username" value="@alexrivera" label="Username" />
          <.field type="textarea" name="bio" value="" label="Bio" placeholder="A line about you" />
        </div>
        <:footer>
          <.button
            color="gray"
            variant="outline"
            phx-click={PetalComponents.SlideOver.hide_slide_over(@slideover.origin, "pg-sheet")}
          >
            Cancel
          </.button>
          <.button phx-click={
            PetalComponents.SlideOver.hide_slide_over(@slideover.origin, "pg-sheet")
          }>
            Save changes
          </.button>
        </:footer>
      </.slide_over>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        A cart - scrolling body, pinned summary footer
      </div>
      <div class="px-6 py-16 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex justify-center">
          <.button
            color="gray"
            variant="outline"
            phx-click={PetalComponents.SlideOver.show_slide_over("right", "pg-cart")}
          >
            <.icon name="hero-shopping-bag" class="w-4 h-4 mr-1" /> Open cart
            <.badge color="primary" size="sm" label="3" class="ml-2" />
          </.button>
        </div>
      </div>

      <.slide_over
        id="pg-cart"
        hide
        origin="right"
        max_width="sm"
        title="Your cart"
        description="3 items"
      >
        <div class="flex flex-col divide-y divide-gray-100 dark:divide-white/10">
          <div
            :for={
              {name, meta, price} <- [
                {"Petal Pro licence", "Single project", "$299"},
                {"Petal Pro team", "Unlimited projects", "$599"},
                {"Petal stickers", "Pack of 12", "$9"}
              ]
            }
            class="flex items-center gap-3 py-4"
          >
            <div class="flex items-center justify-center flex-none w-12 h-12 rounded-lg bg-gray-100 dark:bg-white/10">
              <.icon name="hero-cube" class="w-5 h-5 text-gray-400" />
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-900 truncate dark:text-gray-100">{name}</p>
              <p class="text-xs text-gray-500 dark:text-gray-400">{meta}</p>
            </div>
            <p class="text-sm font-medium tabular-nums text-gray-900 dark:text-gray-100">{price}</p>
          </div>
        </div>
        <:footer>
          <div class="flex items-center justify-between w-full gap-4">
            <div>
              <p class="text-xs text-gray-500 dark:text-gray-400">Total</p>
              <p class="text-base font-semibold tabular-nums text-gray-900 dark:text-gray-100">
                $907
              </p>
            </div>
            <.button phx-click={PetalComponents.SlideOver.hide_slide_over("right", "pg-cart")}>
              Checkout
            </.button>
          </div>
        </:footer>
      </.slide_over>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        The panel is the floating surface: white / gray-900 with a hairline border on its
        attached edge. title and description wire aria-labelledby/describedby; the footer
        slot pins action rows below the scrolling body. Escape and click-away close by
        default, and open/close are LiveView.JS commands (show_slide_over / hide_slide_over),
        so no server round-trip is needed to animate.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "skeleton"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Skeleton</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        One composable brick - size it with classes, pick a shape, pick a motion.
        Compose any loading state instead of picking from prebuilt layouts.
      </p>

      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex justify-center px-6 py-14">
          <.skeleton_group
            label="Loading article"
            animation={@skeleton.animation}
            class="flex w-full max-w-md flex-col gap-5"
          >
            <.skeleton class="h-40 w-full" />
            <div class="flex items-center gap-4">
              <.skeleton variant="circle" class="size-12 shrink-0" />
              <div class="flex-1 space-y-2.5">
                <.skeleton variant="text" class="w-1/2" />
                <.skeleton variant="text" class="w-3/4" />
              </div>
            </div>
            <.skeleton_text lines={3} />
          </.skeleton_group>
        </div>

        <div class="grid gap-5 px-6 py-5 border-t border-gray-100 md:grid-cols-2 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">animation</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={a <- ~w(pulse shimmer none)}
                phx-click="ctl_skeleton"
                phx-value-k="animation"
                phx-value-v={a}
                class={seg(@skeleton.animation == a)}
              >
                {a}
              </button>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        The real pattern - skeleton while loading, content when ready
      </div>
      <div class="px-6 py-10 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="mx-auto max-w-md">
          <%= if @skeleton.loading do %>
            <.skeleton_group
              label="Loading profile"
              animation="shimmer"
              class="flex items-center gap-4"
            >
              <.skeleton variant="circle" class="size-14 shrink-0" />
              <div class="flex-1 space-y-2.5">
                <.skeleton variant="text" class="w-40" />
                <.skeleton variant="text" class="w-56" />
              </div>
            </.skeleton_group>
          <% else %>
            <div class="flex items-center gap-4">
              <.avatar name="Grace Hopper" size="lg" />
              <div>
                <p class="font-semibold text-gray-900 dark:text-gray-100">Grace Hopper</p>
                <p class="text-sm text-gray-500 dark:text-gray-400">
                  Invented the compiler. Debugs moths.
                </p>
              </div>
              <.button
                color="gray"
                variant="outline"
                size="sm"
                class="ml-auto"
                phx-click="ctl_skeleton"
                phx-value-k="load"
              >
                Reload
              </.button>
            </div>
          <% end %>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Shapes
      </div>
      <div class="px-6 py-10 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-end justify-center gap-8">
          <div class="flex flex-col items-center gap-2">
            <.skeleton class="h-16 w-24" />
            <span class="text-[11px] text-gray-400">block</span>
          </div>
          <div class="flex flex-col items-center gap-2">
            <.skeleton variant="circle" class="size-16" />
            <span class="text-[11px] text-gray-400">circle</span>
          </div>
          <div class="flex w-40 flex-col items-center gap-2">
            <.skeleton_text lines={3} />
            <span class="text-[11px] text-gray-400">skeleton_text</span>
          </div>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        skeleton_group is the accessibility wrapper: role="status" + aria-busy announces
        loading once (set the label), while the bricks stay aria-hidden. Its animation
        cascades to everything inside; a brick's own animation wins. Blocks follow the
        radius token, shimmer respects prefers-reduced-motion, and skeleton_text's line
        widths are deterministic so LiveView re-renders never make it dance. The old
        kind={:card}-style prebuilt layouts still render for compatibility.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "button-group"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Button group</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Fuses buttons, inputs and text segments into one control - split buttons,
        toolbars, mixed rails.
      </p>
      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-wrap items-center justify-center gap-6 px-6 py-12">
          <.button_group aria_label="Merge options">
            <.button color="gray" variant="outline" label="Merge pull request" />
            <.dropdown
              placement="left"
              menu_items_wrapper_class="w-72"
              trigger_class="pc-button pc-button--gray-outline pc-button--icon rounded-l-none border-l-0"
            >
              <:trigger_element>
                <.icon name="hero-chevron-down" class="w-4 h-4" />
              </:trigger_element>
              <.dropdown_menu_item link_type="button">
                <.icon name="hero-arrow-down-on-square" class="w-4 h-4 mt-0.5 text-gray-500 shrink-0" />
                <div class="flex flex-col">
                  <span class="font-medium text-gray-900 dark:text-gray-100">
                    Create a merge commit
                  </span>
                  <span class="text-xs text-gray-500 dark:text-gray-400">
                    All commits added to the base via a merge commit
                  </span>
                </div>
              </.dropdown_menu_item>
              <.dropdown_menu_item link_type="button">
                <.icon name="hero-arrows-pointing-in" class="w-4 h-4 mt-0.5 text-gray-500 shrink-0" />
                <div class="flex flex-col">
                  <span class="font-medium text-gray-900 dark:text-gray-100">Squash and merge</span>
                  <span class="text-xs text-gray-500 dark:text-gray-400">
                    Commits combined into one before merging
                  </span>
                </div>
              </.dropdown_menu_item>
              <.dropdown_menu_item link_type="button">
                <.icon name="hero-arrow-path" class="w-4 h-4 mt-0.5 text-gray-500 shrink-0" />
                <div class="flex flex-col">
                  <span class="font-medium text-gray-900 dark:text-gray-100">Rebase and merge</span>
                  <span class="text-xs text-gray-500 dark:text-gray-400">
                    Commits rebased onto the base branch
                  </span>
                </div>
              </.dropdown_menu_item>
            </.dropdown>
          </.button_group>
          <.button_group aria_label="Change view">
            <.button color="gray" variant="outline" label="Day" />
            <.button color="gray" variant="outline" label="Week" />
            <.button color="gray" variant="outline" label="Month" />
          </.button_group>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Toolbar - nested groups gap apart, buttons inside fuse
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex justify-center">
          <.button_group aria_label="Editor toolbar">
            <.button_group aria_label="History">
              <.button color="gray" variant="outline" size="icon" aria-label="Undo">
                <.icon name="hero-arrow-uturn-left" class="w-4 h-4" />
              </.button>
              <.button color="gray" variant="outline" size="icon" aria-label="Redo">
                <.icon name="hero-arrow-uturn-right" class="w-4 h-4" />
              </.button>
            </.button_group>
            <.button_group aria_label="Formatting">
              <.button color="gray" variant="outline" size="icon" aria-label="Bold">
                <.icon name="hero-bold" class="w-4 h-4" />
              </.button>
              <.button color="gray" variant="outline" size="icon" aria-label="Italic">
                <.icon name="hero-italic" class="w-4 h-4" />
              </.button>
              <.button color="gray" variant="outline" size="icon" aria-label="Link">
                <.icon name="hero-link" class="w-4 h-4" />
              </.button>
            </.button_group>
            <.button_group aria_label="Share">
              <.button color="gray" variant="outline" size="sm" label="Share" />
            </.button_group>
          </.button_group>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Sizes - the buttons carry it, the group just joins
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center gap-4">
          <div :for={sz <- ~w(sm md lg)} class="flex items-center gap-3">
            <.button_group aria_label={"Pager " <> sz}>
              <.button color="gray" variant="outline" size={sz} label="Previous" />
              <.button color="gray" variant="outline" size={sz} label="Next" />
            </.button_group>
            <span class="text-[11px] text-gray-400">{sz}</span>
          </div>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Split button - solid buttons have no borders, the separator is the divider
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex justify-center">
          <.button_group aria_label="Save options">
            <.button label="Save changes" />
            <.button_group_separator />
            <.button size="icon" aria-label="More save options">
              <.icon name="hero-chevron-down" class="w-4 h-4" />
            </.button>
          </.button_group>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Mixed rail - text prefix, input and button share one surface
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center gap-5">
          <.button_group aria_label="Site address" class="w-full max-w-sm">
            <.button_group_text>https://</.button_group_text>
            <.input type="text" name="bg_domain" value="" placeholder="example.com" />
            <.button color="gray" variant="outline" label="Visit" />
          </.button_group>
          <.button_group aria_label="Search the docs" class="w-full max-w-sm">
            <.input type="search" name="bg_q" value="" placeholder="Search the docs..." />
            <.button color="gray" variant="outline" size="icon" aria-label="Search">
              <.icon name="hero-magnifying-glass" class="w-4 h-4" />
            </.button>
          </.button_group>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Vertical - fuses top to bottom
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex justify-center">
          <.button_group aria_label="Zoom" orientation="vertical">
            <.button color="gray" variant="outline" size="icon" aria-label="Zoom in">
              <.icon name="hero-plus" class="w-4 h-4" />
            </.button>
            <.button color="gray" variant="outline" size="icon" aria-label="Zoom out">
              <.icon name="hero-minus" class="w-4 h-4" />
            </.button>
          </.button_group>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Drop real components in and the group fuses them: outer corners keep the radius
        token, inner borders collapse to a single line. Outline buttons and inputs carry
        their own dividers; solid buttons have transparent borders, so put a
        button_group_separator between them (between primary solids it tints from the
        solid label colour; elsewhere it matches the border colour).
        Nested groups stop fusing and gap into clusters. The :button slot API from
        earlier releases still renders unchanged.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "loading"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Loading</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        The spinner. Buttons already know it (loading attr) - use it standalone for
        anything else that waits.
      </p>
      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center gap-6 px-6 py-12">
          <div class="flex flex-wrap items-center justify-center gap-3">
            <.button loading>Saving changes</.button>
            <.button color="gray" variant="outline" loading disabled>Generating</.button>
          </div>
          <div class="flex items-center gap-2.5 text-sm text-gray-500 dark:text-gray-400">
            <.spinner size="sm" /> Syncing workspace...
          </div>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        A loading panel
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center justify-center max-w-md gap-3 py-12 mx-auto border border-gray-200 border-dashed rounded-xl dark:border-gray-700">
          <.spinner size="md" />
          <p class="text-sm font-medium text-gray-900 dark:text-gray-100">Generating preview</p>
          <p class="text-xs text-gray-500 dark:text-gray-400">This usually takes a few seconds</p>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Sizes and colour
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-end justify-center gap-10">
          <div :for={sz <- ~w(sm md lg)} class="flex flex-col items-center gap-2">
            <.spinner size={sz} />
            <span class="text-[11px] text-gray-400">{sz}</span>
          </div>
          <div class="flex flex-col items-center gap-2">
            <.spinner size_class="h-8 w-8 text-secondary-500" />
            <span class="text-[11px] text-gray-400">custom</span>
          </div>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Buttons take loading directly (spinner swaps in, label stays). Standalone, pair
        the spinner with a status line or a panel state. show toggles visibility without
        unmounting; size_class takes over sizing and colour (currentColor, so text-*
        utilities recolour it). For full skeleton states, reach for the skeleton
        component instead.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "breadcrumbs"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Breadcrumbs</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Where am I, and how do I get back up. Links from a plain list.
      </p>
      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex justify-center px-6 py-12">
          <.breadcrumbs
            separator={@crumbs.separator}
            links={[
              %{icon: "hero-home", to: "#", link_type: "button"},
              %{label: "Projects", to: "#", link_type: "button"},
              %{label: "petal_components", to: "#", link_type: "button"}
            ]}
          />
        </div>
        <div class="grid gap-5 px-6 py-5 border-t border-gray-100 md:grid-cols-2 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">separator</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={sp <- ~w(chevron slash)}
                phx-click="ctl_crumbs"
                phx-value-k="separator"
                phx-value-v={sp}
                class={seg(@crumbs.separator == sp)}
              >
                {sp}
              </button>
            </div>
          </div>
        </div>
      </div>
      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        links take label and/or icon (the first crumb here is a home icon), to, and
        link_type (a / live_patch / live_redirect / button). The last crumb renders as
        the current page - strong text + aria-current. The nav carries an aria_label.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "stepper"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Stepper</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Multi-step progress - onboarding, checkout, wizards. This one's live: walk the
        Back/Continue flow, or click any step to jump.
      </p>
      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class={[
          "px-6 pt-8 pb-8",
          @stepper.orientation == "vertical" && "md:flex md:items-start md:gap-8"
        ]}>
          <div class={[
            "flex overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden",
            @stepper.orientation == "horizontal" && "justify-center pb-6",
            @stepper.orientation == "vertical" && "justify-center md:justify-start md:shrink-0"
          ]}>
            <.stepper
              steps={pg_steps(@stepper.at, @stepper.done)}
              orientation={@stepper.orientation}
              size={@stepper.size}
            />
          </div>
          <div class={[
            "max-w-md",
            @stepper.orientation == "horizontal" && "mx-auto",
            @stepper.orientation == "vertical" && "mx-auto mt-8 md:mx-0 md:mt-0 md:flex-1"
          ]}>
            <%= if @stepper.done do %>
              <div class="flex flex-col items-center py-8 text-center">
                <div class="flex items-center justify-center w-12 h-12 rounded-full bg-success-100 text-success-600 dark:bg-success-500/15 dark:text-success-400">
                  <.icon name="hero-check" class="w-6 h-6" />
                </div>
                <h3 class="mt-4 text-lg font-semibold text-gray-900 dark:text-gray-100">
                  You're all set
                </h3>
                <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                  Your workspace is ready. Time to build something.
                </p>
                <.button
                  color="gray"
                  variant="outline"
                  class="mt-5"
                  phx-click="ctl_stepper"
                  phx-value-k="reset"
                >
                  Start over
                </.button>
              </div>
            <% else %>
              <div class="min-h-[9rem]">
                <%= case @stepper.at do %>
                  <% 0 -> %>
                    <div class="space-y-3">
                      <div>
                        <label class="block mb-1.5 text-sm font-medium text-gray-700 dark:text-gray-300">
                          Work email
                        </label>
                        <.input type="email" name="wiz_email" value="" placeholder="you@company.com" />
                      </div>
                      <div>
                        <label class="block mb-1.5 text-sm font-medium text-gray-700 dark:text-gray-300">
                          Password
                        </label>
                        <.input type="password" name="wiz_pass" value="" placeholder="8+ characters" />
                      </div>
                    </div>
                  <% 1 -> %>
                    <div class="space-y-3">
                      <div>
                        <label class="block mb-1.5 text-sm font-medium text-gray-700 dark:text-gray-300">
                          Workspace name
                        </label>
                        <.input type="text" name="wiz_ws" value="" placeholder="Northwind" />
                      </div>
                      <p class="text-xs text-gray-500 dark:text-gray-400">
                        This is how your team will see the project across the app.
                      </p>
                    </div>
                  <% 2 -> %>
                    <div class="space-y-3">
                      <div>
                        <label class="block mb-1.5 text-sm font-medium text-gray-700 dark:text-gray-300">
                          Invite teammates
                        </label>
                        <.input
                          type="text"
                          name="wiz_invite"
                          value=""
                          placeholder="alex@acme.com, sam@acme.com"
                        />
                      </div>
                      <p class="text-xs text-gray-500 dark:text-gray-400">
                        Comma-separated - or skip and invite them later.
                      </p>
                    </div>
                  <% _ -> %>
                    <div class="text-sm rounded-lg bg-gray-50 p-4 dark:bg-white/[0.03]">
                      <div class="flex items-center justify-between py-1">
                        <span class="text-gray-500 dark:text-gray-400">Email</span>
                        <span class="font-medium text-gray-900 dark:text-gray-100">you@company.com</span>
                      </div>
                      <div class="flex items-center justify-between py-1">
                        <span class="text-gray-500 dark:text-gray-400">Workspace</span>
                        <span class="font-medium text-gray-900 dark:text-gray-100">Northwind</span>
                      </div>
                      <div class="flex items-center justify-between py-1">
                        <span class="text-gray-500 dark:text-gray-400">Invites</span>
                        <span class="font-medium text-gray-900 dark:text-gray-100">2 teammates</span>
                      </div>
                    </div>
                <% end %>
              </div>
              <div class="flex items-center justify-between mt-6">
                <.button
                  color="gray"
                  variant="outline"
                  disabled={@stepper.at == 0}
                  phx-click="ctl_stepper"
                  phx-value-k="back"
                >
                  Back
                </.button>
                <.button phx-click="ctl_stepper" phx-value-k="next">
                  {if @stepper.at == length(pg_step_defs()) - 1, do: "Complete", else: "Continue"}
                </.button>
              </div>
            <% end %>
          </div>
        </div>
        <div class="grid gap-5 px-6 py-5 border-t border-gray-100 md:grid-cols-2 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">orientation</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={o <- ~w(horizontal vertical)}
                phx-click="ctl_stepper"
                phx-value-k="orientation"
                phx-value-v={o}
                class={seg(@stepper.orientation == o)}
              >
                {o}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={sz <- ~w(sm md lg)}
                phx-click="ctl_stepper"
                phx-value-k="size"
                phx-value-v={sz}
                class={seg(@stepper.size == sz)}
              >
                {sz}
              </button>
            </div>
          </div>
        </div>
      </div>
      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Steps are plain maps: name, description, complete?, active?, on_click (any JS
        command - this demo pushes an event). aria-current and completed labels are wired
        for screen readers.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "avatar"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Avatar</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Images, initials fallbacks, presence dots, and stacked groups.
      </p>
      <div class="mt-8 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Sizes - xs to xl
      </div>
      <div class="border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-end justify-center gap-4 px-6 py-12">
          <div :for={sz <- ~w(xs sm md lg xl)} class="flex flex-col items-center gap-2">
            <.avatar size={sz} src="/dev-static/avatars/p32.jpg" alt="Team member" />
            <span class="text-[11px] text-gray-400">{sz}</span>
          </div>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Fallback chain - photo, initials, icon
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center gap-6">
          <div class="flex flex-col items-center gap-2">
            <.avatar src="/dev-static/avatars/p44.jpg" alt="Photo" />
            <span class="text-[11px] text-gray-400">src</span>
          </div>
          <div class="flex flex-col items-center gap-2">
            <.avatar name="Ada Lovelace" />
            <span class="text-[11px] text-gray-400">initials</span>
          </div>
          <div class="flex flex-col items-center gap-2">
            <.avatar name="Grace Hopper" random_color />
            <span class="text-[11px] text-gray-400">random_color</span>
          </div>
          <div class="flex flex-col items-center gap-2">
            <.avatar />
            <span class="text-[11px] text-gray-400">no name</span>
          </div>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Presence - a team list with status dots
      </div>
      <div class="px-6 py-6 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="max-w-sm mx-auto divide-y divide-gray-100 dark:divide-white/10">
          <div
            :for={
              {src, name, role, status, label} <- [
                {"/dev-static/avatars/p32.jpg", "Amelia Ward", "Engineering", "online", "Online"},
                {"/dev-static/avatars/p65.jpg", "Jonah Reyes", "Design", "busy", "In a meeting"},
                {"/dev-static/avatars/p44.jpg", "Priya Anand", "Support", "away", "Back in 20m"},
                {"/dev-static/avatars/p12.jpg", "Maya Okafor", "Engineering", "offline", "Offline"}
              ]
            }
            class="flex items-center gap-3 py-3"
          >
            <.avatar src={src} alt={name} status={status} />
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-900 truncate dark:text-gray-100">{name}</p>
              <p class="text-xs text-gray-500 truncate dark:text-gray-400">{role}</p>
            </div>
            <span class="text-xs text-gray-400 dark:text-gray-500">{label}</span>
          </div>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Groups - stacked, with a +N overflow
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center gap-5">
          <.avatar_group
            size="md"
            max={3}
            avatars={[
              "/dev-static/avatars/p32.jpg",
              "/dev-static/avatars/p44.jpg",
              "/dev-static/avatars/p65.jpg",
              "/dev-static/avatars/p12.jpg",
              "/dev-static/avatars/p68.jpg"
            ]}
          />
          <div class="flex items-center gap-3">
            <.avatar_group
              size="sm"
              avatars={[
                "/dev-static/avatars/p65.jpg",
                "/dev-static/avatars/p68.jpg",
                "/dev-static/avatars/p12.jpg"
              ]}
            />
            <span class="text-sm text-gray-500 dark:text-gray-400">3 people are viewing this page</span>
          </div>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        The fallback chain is automatic: src renders the photo, name renders initials
        (random_color hashes a stable hue from the name), neither renders the person
        icon. status adds a ringed presence dot that scales with the avatar (online /
        busy / away / offline). avatar_group stacks with overlap; max caps the row and
        folds the rest into a +N bubble. Demo photos are tiny local files, dev-only.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "card"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Card</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        The container for everything - media, content, footer, composed from parts.
      </p>
      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex justify-center px-6 py-12">
          <.card class="w-full max-w-sm">
            <.card_header
              title="Login to your account"
              description="Enter your email below to login"
            >
              <:action>
                <.button color="gray" variant="ghost" size="sm" link_type="a" to="#">
                  Sign up
                </.button>
              </:action>
            </.card_header>
            <.card_content>
              <div class="flex flex-col gap-4">
                <.field type="email" name="email" value="" label="Email" placeholder="m@example.com" />
                <div>
                  <div class="flex items-center justify-between mb-1.5">
                    <label class="text-sm font-medium text-gray-900 dark:text-gray-100">Password</label>
                    <a
                      href="#"
                      class="text-xs text-gray-500 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100"
                    >
                      Forgot your password?
                    </a>
                  </div>
                  <.input type="password" name="password" value="" />
                </div>
              </div>
            </.card_content>
            <.card_footer class="flex-col">
              <.button class="w-full">Login</.button>
              <.button color="gray" variant="outline" class="w-full">Login with Google</.button>
            </.card_footer>
          </.card>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Media card - full-bleed image, category, heading
      </div>
      <div class="px-6 py-10 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="max-w-sm mx-auto">
          <.card>
            <.card_media src="/dev-static/covers/release.jpg" alt="Release cover" />
            <.card_content category="Release" heading="petal_components 4.5">
              Command palette, interactive ratings, sheets, sortable tables and a
              composable skeleton.
            </.card_content>
            <.card_footer>
              <.button color="gray" variant="outline" size="sm">Read more</.button>
            </.card_footer>
          </.card>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Variants - the panel and the well
      </div>
      <div class="px-6 py-10 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="grid max-w-2xl gap-6 mx-auto md:grid-cols-2">
          <.card>
            <.card_header title="Basic" description="The card" />
            <.card_content>
              The bordered panel - primary content lives here. This is the default and
              the only card most screens need.
            </.card_content>
          </.card>
          <.card variant="muted">
            <.card_header title="Muted" description="The well" />
            <.card_content>
              A quiet tinted fill, no border - secondary content, form sections, stat
              tiles. It recedes where basic asserts.
            </.card_content>
          </.card>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        card_header carries title + description + a top-right :action; card_content and
        card_footer pad themselves so media can run full-bleed. Two variants, two jobs:
        the panel asserts, the well recedes. (variant="outline" still renders - it is a
        legacy alias of basic, going away in 5.0.) The cover photo is a 36KB local file,
        dev-only.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "accordion"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Accordion</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Expandable sections for FAQs and dense settings. Pure LiveView.JS - no server
        round-trip to toggle.
      </p>
      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="px-6 py-10">
          <div class="max-w-xl mx-auto">
            <.accordion
              container_id={"pg-acc-#{@accordion.variant}-#{@accordion.size}-#{if @accordion.multiple, do: "m", else: "s"}"}
              variant={@accordion.variant}
              size={@accordion.size}
              multiple={@accordion.multiple}
              open_index={0}
            >
              <:item heading="Is it accessible?">
                Yes - proper button semantics, aria-expanded, and keyboard toggling out of
                the box.
              </:item>
              <:item heading="Can several be open at once?">
                That is the multiple attr - flip it in the controls below.
              </:item>
              <:item heading="Does it follow the theme?">
                Borders, radius token and text tiers all come from the doctrine.
              </:item>
            </.accordion>
          </div>
        </div>
        <div class="grid gap-5 px-6 py-5 border-t border-gray-100 md:grid-cols-2 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={v <- ~w(default bordered)}
                phx-click="ctl_accordion"
                phx-value-k="variant"
                phx-value-v={v}
                class={seg(@accordion.variant == v)}
              >
                {v}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={sz <- ~w(md sm)}
                phx-click="ctl_accordion"
                phx-value-k="size"
                phx-value-v={sz}
                class={seg(@accordion.size == sz)}
              >
                {if sz == "sm", do: "compact", else: "default"}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <div class="flex gap-1.5">
              <button
                phx-click="ctl_accordion"
                phx-value-k="multiple"
                class={tog(@accordion.multiple)}
              >
                allow multiple open
              </button>
            </div>
          </div>
        </div>
      </div>
      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        default is the shadcn row style - hairline dividers, headings underline on
        hover, no highlight on open; bordered is the boxed card-accordion, whose open
        header keeps a soft fill so you can see which section is expanded. "Allow
        multiple open" changes what happens on the NEXT clicks: off, opening a section
        closes the others (classic FAQ); on, sections stay open independently - open two
        to see it. (variant="ghost" still renders - a legacy alias of default, going
        away in 5.0.)
      </div>
    </div>
    """
  end

  defp render_page(%{active: "marquee"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Marquee</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        An infinite scroller for logos, testimonials, anything. Pure CSS animation with
        edge fade.
      </p>
      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="px-2 py-10">
          <.marquee
            reverse={@marquee_ctl.reverse}
            vertical={@marquee_ctl.vertical}
            pause_on_hover={@marquee_ctl.pause}
            duration="24s"
            max_height={@marquee_ctl.vertical && "300px"}
          >
            <div
              :for={name <- ~w(Phoenix LiveView Tailwind Elixir Postgres Oban Ecto)}
              class="flex items-center gap-2 px-5 py-3 mx-2 border border-gray-200 rounded-xl dark:border-gray-700"
            >
              <.icon name="hero-bolt" class="w-4 h-4 text-gray-400" />
              <span class="text-sm font-medium">{name}</span>
            </div>
          </.marquee>
        </div>
        <div class="grid gap-5 px-6 py-5 border-t border-gray-100 md:grid-cols-2 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <div class="flex gap-1.5">
              <button phx-click="ctl_marquee" phx-value-k="reverse" class={tog(@marquee_ctl.reverse)}>reverse</button>
              <button
                phx-click="ctl_marquee"
                phx-value-k="vertical"
                class={tog(@marquee_ctl.vertical)}
              >vertical</button>
              <button phx-click="ctl_marquee" phx-value-k="pause" class={tog(@marquee_ctl.pause)}>pause on hover</button>
            </div>
          </div>
        </div>
      </div>
      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        repeat controls how many copies keep the loop seamless; duration and gap tune the
        feel; overlay_gradient fades the edges. Holds still under prefers-reduced-motion.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "spotlight-card"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Spotlight card</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A radial glow follows your cursor across the card. Move your mouse over them.
      </p>
      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="grid gap-6 px-6 py-12 md:grid-cols-2">
          <.spotlight_card id="spot-1" class="p-8">
            <h3 class="text-lg font-semibold">Default glow</h3>
            <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
              Subtle by default - the light source tracks the pointer.
            </p>
          </.spotlight_card>
          <.spotlight_card
            id="spot-2"
            spotlight_color="rgba(124, 58, 237, 0.25)"
            spotlight_size="500px"
            class="p-8"
          >
            <h3 class="text-lg font-semibold">Tuned glow</h3>
            <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
              spotlight_color and spotlight_size make it a brand moment.
            </p>
          </.spotlight_card>
        </div>
      </div>
      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Powered by the tiny PetalSpotlight hook (pointer position only - the paint is pure
        CSS). Reads best on dark panels.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "number-ticker"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Number ticker</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Numbers that count up to their value. Feed it new numbers and it animates the
        difference.
      </p>
      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center gap-6 px-6 py-12">
          <div class="text-5xl font-bold tabular-nums tracking-tight">
            <.number_ticker id="pg-ticker" value={@ticker.value} prefix="$" />
          </div>
          <.button color="gray" variant="outline" size="sm" phx-click="ticker_bump">
            <.icon name="hero-arrow-trending-up" class="w-4 h-4 mr-1" /> Add revenue
          </.button>
          <div class="flex gap-10 text-center">
            <div>
              <div class="text-2xl font-semibold tabular-nums">
                <.number_ticker id="t-stars" value={1024} suffix="+" />
              </div>
              <div class="mt-1 text-xs text-gray-400">GitHub stars</div>
            </div>
            <div>
              <div class="text-2xl font-semibold tabular-nums">
                <.number_ticker
                  id="t-uptime"
                  value={99.98}
                  decimal_places={2}
                  suffix="%"
                  duration={2200}
                />
              </div>
              <div class="mt-1 text-xs text-gray-400">Uptime</div>
            </div>
          </div>
        </div>
      </div>
      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        prefix/suffix/decimal_places/locale handle formatting; duration tunes the count.
        The PetalNumberTicker hook animates on mount and on every value change.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "text-animation"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Text animation</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Four ways to make words move: gradient sweep, shimmer, typing, and word rotation.
      </p>
      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center gap-10 px-6 py-14 text-center">
          <.gradient_text class="text-4xl font-bold">Ship something tonight</.gradient_text>
          <.shimmer_text class="text-2xl font-semibold">Generating your app...</.shimmer_text>
          <div class="text-2xl font-semibold">
            Build
            <.word_rotate
              id="pg-rotate"
              words={["faster", "calmer", "together", "tonight"]}
              class="text-primary-600 dark:text-primary-400"
            />
          </div>
          <.typing_effect
            id="pg-typing"
            text="mix petal.gen.live Accounts User users"
            class="font-mono text-sm"
          />
        </div>
      </div>
      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        gradient_text and shimmer_text are pure CSS (colours + duration attrs);
        word_rotate and typing_effect use tiny hooks. All respect
        prefers-reduced-motion.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "confetti"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Confetti</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Zero-dependency canvas confetti. Fire it from the client or push it from the
        server on the moments that matter.
      </p>
      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center gap-4 px-6 py-16">
          <.confetti id="pg-confetti" />
          <.button phx-click={Phoenix.LiveView.JS.dispatch("pc:confetti", to: "#pg-confetti")}>
            <.icon name="hero-sparkles" class="w-4 h-4 mr-1.5" /> Celebrate
          </.button>
          <p class="text-sm text-gray-500 dark:text-gray-400">
            no server round-trip - it's a JS.dispatch
          </p>
        </div>
      </div>
      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Tune particle_count, spread, angle, velocity, colors and origin. From LiveView:
        push_event(socket, "pc-confetti", %{}) fires it server-side - ship it on signup
        complete, plan upgraded, streak kept.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "tabs"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Tabs</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Three styles: segmented (a raised pill on a muted track), underline, and pill.
        Tabs are links or buttons - wire them to live_patch, JS commands or events.
      </p>

      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center gap-6 px-6 py-12">
          <.tabs variant={@tabs.variant}>
            <.tab
              :for={
                {slug, name, n} <- [
                  {"overview", "Overview", nil},
                  {"analytics", "Analytics", nil},
                  {"reports", "Reports", 4},
                  {"settings", "Settings", nil}
                ]
              }
              variant={@tabs.variant}
              is_active={@tabs.active == slug}
              number={@tabs.number && n}
              link_type="button"
              phx-click="ctl_tabs"
              phx-value-k="tab"
              phx-value-v={slug}
            >
              {name}
            </.tab>
          </.tabs>
          <div class="w-full max-w-md p-5 text-sm border border-gray-200 rounded-lg text-gray-500 dark:border-gray-800 dark:text-gray-400">
            {case @tabs.active do
              "overview" -> "Your project at a glance - traffic, revenue and recent activity."
              "analytics" -> "Charts and breakdowns. This panel swapped without a page load."
              "reports" -> "Four reports ready to export."
              "settings" -> "Project name, members and billing."
            end}
          </div>
        </div>

        <div class="grid gap-5 px-6 py-5 border-t border-gray-100 md:grid-cols-2 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={v <- ~w(segmented underline pill)}
                phx-click="ctl_tabs"
                phx-value-k="variant"
                phx-value-v={v}
                class={seg(@tabs.variant == v)}
              >
                {v}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <div class="flex gap-1.5">
              <button phx-click="ctl_tabs" phx-value-k="number" class={tog(@tabs.number)}>number badge</button>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        With icons - anything goes in the tab body
      </div>
      <div class="px-6 py-10 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex justify-center">
          <.tabs variant="segmented">
            <.tab variant="segmented" is_active link_type="button">
              <.icon name="hero-chart-bar" class="w-4 h-4 mr-1.5" /> Dashboard
            </.tab>
            <.tab variant="segmented" link_type="button">
              <.icon name="hero-users" class="w-4 h-4 mr-1.5" /> Team
            </.tab>
            <.tab variant="segmented" link_type="button">
              <.icon name="hero-cog-6-tooth" class="w-4 h-4 mr-1.5" /> Settings
            </.tab>
          </.tabs>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        segmented is the modern default for in-page switching (the active tab is a raised
        white pill, nested-radius on the track); underline suits page-level navigation;
        pill is the roomy classic. The legacy underline flag still works - variant wins
        when both are set.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "pagination"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Pagination</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Discrete page buttons with a solid primary current page. Works as links
        (path templates) or pure events - this one is events.
      </p>

      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center gap-4 px-6 py-14">
          <.pagination
            event
            total_pages={12}
            current_page={@page.current}
            sibling_count={@page.sibling}
            boundary_count={@page.boundary}
          />
          <p class="text-sm tabular-nums text-gray-500 dark:text-gray-400">
            Page {@page.current} of 12
          </p>
        </div>

        <div class="grid gap-5 px-6 py-5 border-t border-gray-100 md:grid-cols-2 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">sibling count</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={n <- ~w(0 1 2)}
                phx-click="ctl_page"
                phx-value-k="sibling"
                phx-value-v={n}
                class={seg(to_string(@page.sibling) == n)}
              >
                {n}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">boundary count</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={n <- ~w(1 2)}
                phx-click="ctl_page"
                phx-value-k="boundary"
                phx-value-v={n}
                class={seg(to_string(@page.boundary) == n)}
              >
                {n}
              </button>
            </div>
          </div>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        The current page carries the outline surface (border + wash - the same recipe as
        outline buttons), everything else is quiet ghost chrome with hover washes.
        sibling and boundary counts
        control the windowing around the ellipses. Link mode takes a path template like
        /users/:page; event mode fires goto-page with phx-value-page. One style by design -
        variants multiply here without earning their keep.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "table"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Table</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Sortable headers, density, stripes - the presentation layer for data. Click
        Name or Age to sort; the component fires the event, your app reorders the rows.
      </p>

      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="px-6 py-8">
          <.table
            rows={if @table.empty, do: [], else: table_rows(@table)}
            variant={@table.variant}
            density={@table.density}
            striped={@table.striped}
            sort_by={@table.sort_by}
            sort_dir={@table.sort_dir}
          >
            <:col :let={p} label="Name" sortable sort_key="name">{p.name}</:col>
            <:col :let={p} label="Role">{p.role}</:col>
            <:col :let={p} label="Age" sortable sort_key="age">{p.age}</:col>
            <:col :let={p} label="Status">
              <.badge
                color={if p.status == "Active", do: "success", else: "gray"}
                variant="soft"
                size="sm"
                label={p.status}
              />
            </:col>
            <:empty_state>
              <div class="py-8 text-center text-gray-500 dark:text-gray-400">
                No people match. The empty_state slot renders whenever rows is empty.
              </div>
            </:empty_state>
            <:footer>
              <.td colspan={2}>5 people</.td>
              <.td>avg 67</.td>
              <.td></.td>
            </:footer>
          </.table>
        </div>

        <div class="grid gap-5 px-6 py-5 border-t border-gray-100 md:grid-cols-2 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">density</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={d <- ~w(comfortable compact)}
                phx-click="ctl_table"
                phx-value-k="density"
                phx-value-v={d}
                class={seg(@table.density == d)}
              >
                {d}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={v <- ~w(basic ghost)}
                phx-click="ctl_table"
                phx-value-k="variant"
                phx-value-v={v}
                class={seg(@table.variant == v)}
              >
                {v}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <div class="flex gap-1.5">
              <button phx-click="ctl_table" phx-value-k="striped" class={tog(@table.striped)}>striped</button>
              <button phx-click="ctl_table" phx-value-k="empty" class={tog(@table.empty)}>empty state</button>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        People cells - avatar + name + sub-label in one helper
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <.table rows={[
          %{name: "Alex Rivera", email: "alex@example.com", plan: "Team"},
          %{name: "Ada Lovelace", email: "ada@analytical.engine", plan: "Pro"}
        ]}>
          <:col :let={u} label="User">
            <.user_inner_td
              label={u.name}
              sub_label={u.email}
              avatar_assigns={%{name: u.name, size: "sm"}}
            />
          </:col>
          <:col :let={u} label="Plan">{u.plan}</:col>
        </.table>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Sorting is honest: the header is a real button firing on_sort (default event
        "sort") with the column's sort_key, aria-sort announces the state, and the arrow
        shows direction - your app owns the actual reorder. sticky_header pins the header
        row inside a scrolling container; ghost is the shadcn-minimal look - no frame, no
        header fill, tighter cells, hairline separators only - for embedding in cards and
        detail views. Rows carry a scan-friendly hover wash, and the :footer slot pins a
        totals row (colspan works) under the body; LiveView streams work unchanged. Search and filtering are deliberately NOT
        here - they are data-layer concerns (queries, params, debounce), which is exactly
        where the pro data_table picks up. This component draws the line at presentation:
        it renders state and fires events.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "tooltip"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Tooltip</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A label on hover or keyboard focus. Pure CSS - no JS, no dependencies.
        The bubble inverts against the page in both modes.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center px-6 py-16">
          <.tooltip
            label="Copied to clipboard"
            placement={@tooltip.placement}
            arrow={@tooltip.arrow}
          >
            <.button color="gray" variant="outline">Hover me</.button>
          </.tooltip>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">placement</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"
      ><code>{tooltip_snippet(@tooltip)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Icon buttons (the classic use)
      </div>
      <div class="px-6 py-12 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center gap-3">
          <.tooltip label="Bold">
            <.button color="gray" variant="ghost" size="icon" aria-label="Bold"><.icon name="hero-bold" /></.button>
          </.tooltip>
          <.tooltip label="Italic">
            <.button color="gray" variant="ghost" size="icon" aria-label="Italic"><.icon name="hero-italic" /></.button>
          </.tooltip>
          <.tooltip label="Link">
            <.button color="gray" variant="ghost" size="icon" aria-label="Link"><.icon name="hero-link" /></.button>
          </.tooltip>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Rich content</div>
      <div class="px-6 py-12 border border-gray-200 rounded-xl dark:border-gray-800">
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
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Click-to-open panel with light dismiss. Optional top_layer mode uses the
        native popover API to escape clipped containers.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center px-6 py-20">
          <.popover
            id={"pg-popover-#{@popover.placement}-#{@popover.top_layer}"}
            placement={@popover.placement}
            top_layer={@popover.top_layer}
            trigger_class="pc-button pc-button--gray-outline pc-button--md"
          >
            <:trigger>Open popover</:trigger>
            <div class="max-w-56">
              <div class="text-sm font-semibold">Dimensions</div>
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                Set the width and height for the layer.
              </p>
            </div>
          </.popover>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">placement</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"
      ><code>{popover_snippet(@popover)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        top_layer escapes clipped containers
      </div>
      <div class="px-6 py-10 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="max-w-md mx-auto">
          <div class="relative h-24 p-4 overflow-hidden border border-dashed rounded-lg border-gray-300 dark:border-gray-700">
            <div class="mb-2 text-xs text-gray-400">overflow: hidden container</div>
            <.popover
              id="pg-popover-clipped"
              placement="bottom"
              top_layer
              trigger_class="pc-button pc-button--gray-outline pc-button--sm"
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
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A segmented one-time-code input. One real input under the hood, so
        paste, SMS autofill and form posts all just work. Try typing in it.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">length</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"
      ><code>{otp_snippet(@otp)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Grouped</div>
      <div class="px-6 py-10 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex justify-center">
          <.input_otp id="otp-grouped-demo" name="grouped_code" length={6} group_size={3} />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        In a form field (error state)
      </div>
      <div class="px-6 py-10 border border-gray-200 rounded-xl dark:border-gray-800">
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
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        On or off, applied immediately. Switches are pill-shaped by nature, so
        the radius rail deliberately leaves them alone.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"
      ><code>{switch_snippet(@switch)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">States</div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-wrap items-center justify-center gap-x-10 gap-y-4">
          <.field type="switch" name="st_off" label="Off" no_margin />
          <.field type="switch" name="st_on" label="On" checked no_margin />
          <.field type="switch" name="st_dis" label="Disabled" disabled no_margin />
          <.field type="switch" name="st_dis_on" label="Disabled on" checked disabled no_margin />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Sizes</div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-wrap items-center justify-center gap-x-10 gap-y-4">
          <.field
            :for={z <- ~w(xs sm md lg xl)}
            type="switch"
            name={"sz_" <> z}
            label={z}
            size={z}
            checked
            no_margin
          />
        </div>
      </div>
    </div>
    """
  end

  defp render_page(%{active: "radio"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Radio</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Plain radio groups, plus radio cards - selectable panels with labels and
        descriptions that most libraries make you hand-roll.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"
      ><code>{radio_snippet(@radio)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Radio group</div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
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

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        With radio indicator
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
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

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Disabled option
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
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
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        The native select on the shared field surface: prompt, option groups and
        multiple selection, no JS required.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-gray-800">
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
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"
      ><code>{select_snippet(@select)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Option groups</div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="max-w-sm mx-auto">
          <.field
            type="select"
            name="region"
            label="Region"
            value="Sydney"
            options={[
              APAC: ["Sydney", "Tokyo", "Singapore"],
              Europe: ["Amsterdam", "Berlin"],
              Americas: ["Denver", "Sao Paulo"]
            ]}
            no_margin
          />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Multiple</div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
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
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Single agreements and multi-select groups. The box nests the rail radius;
        the ring only shows for keyboard focus.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">layout</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"
      ><code>{checkbox_snippet(@checkbox)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        States (click one - no ring; tab to it - ring)
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-wrap items-center justify-center gap-x-8 gap-y-4">
          <.field type="checkbox" name="s_off" label="Unchecked" no_margin />
          <.field type="checkbox" name="s_on" label="Checked" checked no_margin />
          <.field type="checkbox" name="s_dis" label="Disabled" disabled no_margin />
          <.field type="checkbox" name="s_dis_on" label="Disabled checked" checked disabled no_margin />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Single checkbox
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
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

  defp render_page(%{active: "aurora"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Aurora</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A drifting aurora glow behind your content - the hero-section backdrop.
        Pure CSS; pauses off-screen.
      </p>
      <div class="mt-8">
        <.aurora class="border border-gray-200 rounded-2xl dark:border-gray-800">
          <div class="flex flex-col items-center px-8 text-center py-24">
            <.badge color="primary" variant="outline" label="Now in petal_components" />
            <h2 class="mt-4 text-4xl font-bold tracking-tight text-gray-900 dark:text-gray-100">
              Ship your Phoenix app this weekend
            </h2>
            <p class="max-w-md mt-3 text-gray-600 dark:text-gray-300">
              Auth, billing, orgs and a component library that looks like you hired a designer.
            </p>
            <div class="flex items-center gap-3 mt-6">
              <.button label="Get started" />
              <.button color="gray" variant="outline" label="Live demo" />
            </div>
          </div>
        </.aurora>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Any palette - colors builds the gradient for you
      </div>
      <div class="grid gap-4 sm:grid-cols-3">
        <div :for={
          {label, colors} <- [
            {"sunset", ["#f97316", "#f43f5e", "#fbbf24", "#fb7185"]},
            {"emerald", ["#10b981", "#5eead4", "#a7f3d0", "#34d399"]},
            {"violet", ["#8b5cf6", "#f0abfc", "#c4b5fd", "#a78bfa"]}
          ]
        }>
          <.aurora colors={colors} class="border border-gray-200 rounded-xl dark:border-gray-800">
            <div class="flex items-end px-4 h-36">
              <span class="pb-3 font-mono text-xs text-gray-500 dark:text-gray-400">{label}</span>
            </div>
          </.aurora>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Tuning - flood the whole container, or slow the drift
      </div>
      <div class="grid gap-4 sm:grid-cols-2">
        <.aurora
          mask_position="50% 0"
          mask_coverage="30%, 100%"
          class="border border-gray-200 rounded-xl dark:border-gray-800"
        >
          <div class="flex items-end px-4 h-36">
            <span class="pb-3 font-mono text-xs text-gray-500 dark:text-gray-400">
              mask_position="50% 0" mask_coverage="30%, 100%"
            </span>
          </div>
        </.aurora>
        <.aurora
          speed="20s"
          opacity="0.7"
          class="border border-gray-200 rounded-xl dark:border-gray-800"
        >
          <div class="flex items-end px-4 h-36">
            <span class="pb-3 font-mono text-xs text-gray-500 dark:text-gray-400">
              speed="20s" opacity="0.7"
            </span>
          </div>
        </.aurora>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        The wrapper sizes to its content - pad a hero and it just works. By default the
        effect inverts on light backgrounds and renders natural in dark
        (invert="always"/"none" to force). The PetalAurora hook pauses the drift while
        off-screen, and prefers-reduced-motion freezes it entirely. Ported from Petal Pro
        and rebuilt: pc-prefixed classes, palette-driven gradients, content above the glow.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "links"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Links</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        The routing primitive. One tag, four behaviours - plain anchor, LiveView
        patch, LiveView redirect, or a styled-as-link button.
      </p>
      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="max-w-lg px-6 py-10 mx-auto text-sm leading-7 text-gray-600 dark:text-gray-300">
          Petal ships with
          <.a
            to="#"
            class="font-medium text-primary-600 underline underline-offset-2 hover:text-primary-700 dark:text-primary-400"
          >
            36 components
          </.a>
          out of the box. Read the
          <.a
            to="#"
            link_type="live_patch"
            class="font-medium text-primary-600 underline underline-offset-2 hover:text-primary-700 dark:text-primary-400"
          >
            install guide
          </.a>
          or jump straight to the
          <.a
            to="#"
            link_type="live_redirect"
            class="font-medium text-primary-600 underline underline-offset-2 hover:text-primary-700 dark:text-primary-400"
          >
            live demo
          </.a>
          to see it running.
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Behaviours - same tag, different navigation
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-wrap items-center justify-center gap-x-8 gap-y-3 text-sm">
          <div
            :for={
              {type, label} <- [
                {"a", "plain anchor"},
                {"live_patch", "live_patch"},
                {"live_redirect", "live_redirect"},
                {"button", "button"}
              ]
            }
            class="flex flex-col items-center gap-1"
          >
            <.a
              to={if type == "button", do: nil, else: "#"}
              link_type={type}
              class="font-medium text-primary-600 underline underline-offset-2 dark:text-primary-400"
            >
              {label}
            </.a>
            <span class="text-[11px] text-gray-400">link_type="{type}"</span>
          </div>
          <div class="flex flex-col items-center gap-1">
            <.a to="#" disabled class="font-medium text-gray-400 underline underline-offset-2">
              disabled
            </.a>
            <span class="text-[11px] text-gray-400">disabled</span>
          </div>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        &lt;.a&gt; is deliberately unstyled - it is the primitive under button, breadcrumbs,
        pagination and dropdown items. Style it with classes (or just use those
        components). disabled turns an anchor into a real disabled button, since
        anchors can't be disabled.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "icons"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Icons</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Every Heroicon by name - outline, solid, mini and micro. Sized and coloured
        with classes like any other element.
      </p>
      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="grid grid-cols-4 gap-1 p-4 sm:grid-cols-6">
          <div
            :for={
              name <-
                ~w(home user users cog-6-tooth bell envelope calendar chart-bar folder document magnifying-glass plus trash pencil check x-mark arrow-right arrow-path cloud-arrow-up lock-closed star heart bolt sparkles)
            }
            class="flex flex-col items-center gap-2 py-4 rounded-lg hover:bg-gray-50 dark:hover:bg-white/5"
          >
            <.icon name={"hero-" <> name} class="w-5 h-5 text-gray-700 dark:text-gray-300" />
            <span class="font-mono text-[10px] text-gray-400 truncate max-w-full px-1">{name}</span>
          </div>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Variants - outline, solid, mini, micro
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-end justify-center gap-8">
          <div
            :for={
              {suffix, label} <- [
                {"", "outline"},
                {"-solid", "solid"},
                {"-mini", "mini"},
                {"-micro", "micro"}
              ]
            }
            class="flex flex-col items-center gap-2"
          >
            <.icon name={"hero-star" <> suffix} class="w-6 h-6 text-gray-700 dark:text-gray-300" />
            <span class="font-mono text-[10px] text-gray-400">hero-star{suffix}</span>
          </div>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Size and colour are just classes
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-end justify-center gap-6">
          <.icon name="hero-bolt" class="w-4 h-4 text-gray-400" />
          <.icon name="hero-bolt" class="w-5 h-5 text-gray-600 dark:text-gray-300" />
          <.icon name="hero-bolt" class="w-6 h-6 text-primary-600 dark:text-primary-400" />
          <.icon name="hero-bolt" class="w-8 h-8 text-warning-500" />
          <.icon name="hero-bolt" class="w-10 h-10 text-danger-500" />
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Any hero-* name from heroicons.com works - this grid is a sample, not the set.
        Icons render as masked spans, so text colour utilities colour them. The other
        petal components (button icon attr, breadcrumbs, alerts) use this same
        component under the hood.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "menu"} = assigns) do
    ~H"""
    <div class="max-w-4xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Menu</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        The sidebar menu - a workspace switcher, grouped nav with collapsible
        sub-items, and an account menu. All composed from menu, dropdown and avatar.
      </p>

      <div class="mt-8 flex h-[34rem] overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <aside class="flex flex-col w-64 border-r shrink-0 border-gray-200 bg-gray-50 dark:border-white/10 dark:bg-white/[0.02]">
          <div class="p-2 border-b border-gray-200 dark:border-white/10">
            <.dropdown
              class="w-full"
              trigger_class="w-full"
              placement="right"
              menu_items_wrapper_class="w-60"
            >
              <:trigger_element>
                <div class="flex items-center w-full gap-2 px-2 py-1.5 rounded-lg transition-colors hover:bg-gray-100 dark:hover:bg-white/5">
                  <div class="flex items-center justify-center w-8 h-8 text-sm font-semibold rounded-lg shrink-0 bg-primary-600 text-(--pc-button-solid-fg)">
                    N
                  </div>
                  <div class="flex-1 min-w-0 text-left">
                    <div class="text-sm font-semibold text-gray-900 truncate dark:text-gray-100">
                      Northwind
                    </div>
                    <div class="text-xs text-gray-500 truncate dark:text-gray-400">Enterprise</div>
                  </div>
                  <.icon name="hero-chevron-up-down" class="w-4 h-4 text-gray-400 shrink-0" />
                </div>
              </:trigger_element>
              <.dropdown_menu_label>Workspaces</.dropdown_menu_label>
              <.dropdown_menu_item link_type="button">
                <div class="flex items-center justify-center w-6 h-6 text-xs font-semibold rounded shrink-0 bg-primary-600 text-(--pc-button-solid-fg)">
                  N
                </div>
                Northwind
              </.dropdown_menu_item>
              <.dropdown_menu_item link_type="button">
                <div class="flex items-center justify-center w-6 h-6 text-xs font-semibold text-gray-600 bg-gray-200 rounded shrink-0 dark:bg-white/10 dark:text-gray-300">
                  V
                </div>
                Vertex Labs
              </.dropdown_menu_item>
              <.dropdown_menu_separator />
              <.dropdown_menu_item link_type="button">
                <.icon name="hero-plus" class="w-5 h-5 text-gray-500" /> Add workspace
              </.dropdown_menu_item>
            </.dropdown>
          </div>

          <div class="flex-1 p-2 overflow-y-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
            <.vertical_menu current_page={:history} menu_items={sidebar_menu_items()} />
          </div>

          <div class="p-2 border-t border-gray-200 dark:border-white/10">
            <.dropdown
              class="w-full"
              trigger_class="w-full"
              placement="right"
              menu_items_wrapper_class="w-60 top-auto bottom-full mb-2"
            >
              <:trigger_element>
                <div class="flex items-center w-full gap-2 px-2 py-1.5 rounded-lg transition-colors hover:bg-gray-100 dark:hover:bg-white/5">
                  <.avatar name="Alex Rivera" size="sm" random_color />
                  <div class="flex-1 min-w-0 text-left">
                    <div class="text-sm font-semibold text-gray-900 truncate dark:text-gray-100">
                      Alex Rivera
                    </div>
                    <div class="text-xs text-gray-500 truncate dark:text-gray-400">
                      alex@example.com
                    </div>
                  </div>
                  <.icon name="hero-chevron-up-down" class="w-4 h-4 text-gray-400 shrink-0" />
                </div>
              </:trigger_element>
              <.dropdown_menu_label>alex@example.com</.dropdown_menu_label>
              <.dropdown_menu_item link_type="button">
                <.icon name="hero-user-circle" class="w-5 h-5 text-gray-500" /> Account
              </.dropdown_menu_item>
              <.dropdown_menu_item link_type="button">
                <.icon name="hero-credit-card" class="w-5 h-5 text-gray-500" /> Billing
              </.dropdown_menu_item>
              <.dropdown_menu_item link_type="button">
                <.icon name="hero-bell" class="w-5 h-5 text-gray-500" /> Notifications
              </.dropdown_menu_item>
              <.dropdown_menu_separator />
              <.dropdown_menu_item link_type="button">
                <.icon name="hero-arrow-right-on-rectangle" class="w-5 h-5 text-gray-500" /> Log out
              </.dropdown_menu_item>
            </.dropdown>
          </div>
        </aside>

        <div class="flex-col flex-1 hidden min-w-0 sm:flex bg-white dark:bg-gray-950">
          <div class="flex items-center h-12 gap-2 px-4 text-sm text-gray-500 border-b shrink-0 border-gray-200 dark:border-white/10 dark:text-gray-400">
            <.icon name="hero-bars-3" class="w-4 h-4" />
            <span class="w-px h-4 bg-gray-200 dark:bg-white/10"></span>
            <span>Platform</span>
            <.icon name="hero-chevron-right" class="w-3.5 h-3.5" />
            <span class="font-medium text-gray-900 dark:text-gray-100">History</span>
          </div>
          <div class="grid flex-1 grid-cols-3 gap-4 p-4 auto-rows-min">
            <div class="rounded-xl bg-gray-100 dark:bg-white/[0.03] aspect-video"></div>
            <div class="rounded-xl bg-gray-100 dark:bg-white/[0.03] aspect-video"></div>
            <div class="rounded-xl bg-gray-100 dark:bg-white/[0.03] aspect-video"></div>
            <div class="col-span-3 rounded-xl bg-gray-100 dark:bg-white/[0.03] h-40"></div>
          </div>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        The whole sidebar is composition, not a new component: vertical_menu for the
        grouped nav (menu_items with a nested menu_items renders a collapsible
        sub-menu - Playground is open because a child is the current_page), dropdown
        for the workspace switcher and the account menu (footer one opens upward), and
        avatar for the account. Petal Pro's SidebarLayout wraps this with collapse and
        a mobile drawer.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "navigation-menu"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Navigation menu</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        The marketing-site top nav - plain links and flyout panels with rich link
        rows and a CTA footer.
      </p>
      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex justify-center px-6 pt-6 pb-72">
          <.navigation_menu id={"pg-nav-demo-#{@nav_trigger}"} trigger={@nav_trigger}>
            <:item label="Product" width="md">
              <.navigation_menu_link
                to="#"
                icon="hero-chart-bar"
                title="Analytics"
                description="Understand your traffic"
              />
              <.navigation_menu_link
                to="#"
                icon="hero-arrow-path"
                title="Automations"
                description="Put repetitive work on autopilot"
              />
              <.navigation_menu_link
                to="#"
                icon="hero-shield-check"
                title="Security"
                description="SSO, 2FA and audit logs"
              />
              <.navigation_menu_footer>
                <.navigation_menu_footer_link to="#" icon="hero-play-circle" label="Watch demo" />
                <.navigation_menu_footer_link to="#" icon="hero-phone" label="Contact sales" />
              </.navigation_menu_footer>
            </:item>
            <:item label="Pricing" to="#" />
            <:item label="Docs" to="#" current />
          </.navigation_menu>
        </div>
        <div class="px-6 py-4 border-t border-gray-100 dark:border-gray-800/80">
          <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">trigger</div>
          <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
            <button
              :for={t <- ~w(hover click)}
              phx-click="ctl_navmenu"
              phx-value-k="trigger"
              phx-value-v={t}
              class={seg(@nav_trigger == t)}
            >
              {t}
            </button>
          </div>
        </div>
      </div>
      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Hover Product (or tab to it) to open the flyout. A close grace period keeps
        it open while you move from the trigger down into the panel, and the panel
        nudges itself to stay inside the viewport - no manual align needed.
        trigger="click" switches to explicit tap-to-open for touch-first apps. Items
        with to render plain links, current marks the active page. width sizes the
        panel sm-xl, full_width spans a mega menu.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "container"} = assigns) do
    ~H"""
    <div class="max-w-5xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Container</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Centred max-width wrapper with responsive gutters - the outermost div of
        every page.
      </p>
      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col gap-3 py-8">
          <.container :for={mw <- ~w(sm md lg xl full)} max_width={mw}>
            <div class="flex items-center justify-between px-4 py-2.5 text-xs font-mono rounded-lg bg-primary-50 text-primary-700 dark:bg-primary-500/10 dark:text-primary-300">
              <span>max_width="{mw}"</span>
              <span class="text-primary-400 dark:text-primary-500">
                {case mw do
                  "sm" -> "42rem"
                  "md" -> "56rem"
                  "lg" -> "64rem"
                  "xl" -> "72rem"
                  "full" -> "100%"
                end}
              </span>
            </div>
          </.container>
        </div>
      </div>
      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Wrap page content once and forget about horizontal padding - gutters are
        responsive (none on mobile with no_padding_on_mobile). Larger sizes clamp to
        their parent - lg upwards is capped by this demo panel. The playground pages
        you're reading use the same pattern.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "chat"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">AI Chat</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        The LiveView-native AI chat kit. Tokens stream over the socket you already
        have - no client AI SDK. This demo is live: ask it something.
      </p>
      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <Chat.conversation id="pg-chat" variant={@chat.variant}>
          <div :if={!@chat.history} class="flex justify-center">
            <button
              type="button"
              phx-click="chat_history"
              class="px-3 py-1 text-xs font-medium text-gray-500 rounded-full hover:bg-gray-100 hover:text-gray-700 dark:text-gray-400 dark:hover:bg-white/10 dark:hover:text-gray-200"
            >
              Load earlier messages
            </button>
          </div>
          <%= for {turn, i} <- Enum.with_index(@chat.turns) do %>
            <Chat.marker
              :if={turn.role == :marker}
              id={"pg-chat-row-#{turn.id}"}
              variant="separator"
            >
              {turn.text}
            </Chat.marker>
            <Chat.chat_message
              :if={turn.role == :user}
              id={"pg-chat-row-#{turn.id}"}
              role="user"
              class={@chat.editing == i && "pc-chat__row--editing"}
            >
              {turn.text}
              <:actions>
                <Chat.message_actions visible={@chat.actions}>
                  <Chat.copy_button id={"pg-chat-uc-#{turn.id}"} text={turn.text} icon />
                  <Chat.action_button
                    icon="hero-pencil-square"
                    label="Edit"
                    phx-click="chat_edit"
                    phx-value-i={i}
                    phx-value-text={turn.text}
                  />
                </Chat.message_actions>
              </:actions>
            </Chat.chat_message>
            <Chat.chat_message
              :if={turn.role == :assistant}
              id={"pg-chat-row-#{turn.id}"}
              role="assistant"
            >
              <%= if turn.stream_id do %>
                <Chat.streaming_text id={turn.stream_id} />
              <% else %>
                <Chat.markdown content={turn.text} id={"pg-chat-md-#{turn.id}"} />
              <% end %>
              <:actions :if={turn.stream_id == nil}>
                <Chat.message_actions visible={@chat.actions}>
                  <Chat.copy_button id={"pg-chat-copy-#{turn.id}"} text={turn.text} icon />
                  <Chat.action_button
                    icon="hero-hand-thumb-up"
                    label="Good response"
                    phx-click="chat_feedback"
                    phx-value-vote="up"
                  />
                  <Chat.action_button
                    icon="hero-hand-thumb-down"
                    label="Bad response"
                    phx-click="chat_feedback"
                    phx-value-vote="down"
                  />
                  <Chat.action_button
                    icon="hero-arrow-path"
                    label="Regenerate"
                    phx-click="chat_feedback"
                  />
                </Chat.message_actions>
              </:actions>
            </Chat.chat_message>
          <% end %>
          <:footer>
            <Chat.suggestions
              :if={not @chat.sent}
              items={["What makes this different from React AI kits?", "Show me a tool call"]}
              on_select="chat_suggest"
              class="mb-2"
            />
            <Chat.prompt_input
              id="pg-chat-composer"
              phx-submit="chat_send"
              editing={@chat.editing != nil}
              on_cancel_edit="chat_cancel_edit"
              loading={@chat.streaming}
              on_stop="chat_stop"
              placeholder="Ask the (canned) assistant..."
            />
          </:footer>
        </Chat.conversation>
        <div class="flex flex-wrap gap-6 px-6 py-4 border-t border-gray-100 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={v <- ~w(plain bubbles)}
                phx-click="ctl_chat"
                phx-value-k="variant"
                phx-value-v={v}
                class={seg(@chat.variant == v)}
              >
                {v}
              </button>
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">action bar</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
              <button
                :for={v <- ~w(always hover)}
                phx-click="ctl_chat"
                phx-value-k="actions"
                phx-value-v={v}
                class={seg(@chat.actions == v)}
              >
                {v}
              </button>
            </div>
          </div>
        </div>
      </div>
      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Streaming is real here: the LiveView pushes word-sized tokens with
        push_event and the PetalChatStream hook appends them - then the bubble
        snaps to rendered markdown when the answer commits. Sending always drops
        you to the live edge and the thread rides it as tokens land; scroll up
        mid-answer and it lets go instantly (the arrow button brings you back).
        "Load earlier messages" inserts history above without moving what you're
        reading. The bar under a message is message_actions in the
        chat_message :actions slot (role-agnostic - the user question above has
        copy + edit, hover the bubble; edit loads it into the composer and sending
        forks the thread there - replaces the message, drops what followed, and
        regenerates, like ChatGPT. prompt_input shows an edit banner with a
        cancel while you're at it); the
        starter chips are the suggestions component; the send button defaults
        to the arrow icon (submit_label brings text back). The thread itself is
        variant="plain" by default - assistant text on the surface, ChatGPT
        style; variant="bubbles" puts both sides in bubbles (messenger style).
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Markers - system notes, status rows, separators
      </div>
      <div class="px-6 py-6 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="max-w-md mx-auto">
          <Chat.marker variant="separator">Today</Chat.marker>
          <Chat.marker icon="hero-magnifying-glass">Searched the web - 8 sources</Chat.marker>
          <Chat.marker loading>
            <.shimmer_text class="text-xs font-medium">Running the numbers...</.shimmer_text>
          </Chat.marker>
          <Chat.marker variant="border" icon="hero-archive-box">
            Context compacted - 12k tokens summarised
          </Chat.marker>
          <Chat.marker icon="hero-check-circle">Answer complete</Chat.marker>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Tool calls, reasoning and errors
      </div>
      <div class="px-6 py-6 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col max-w-md gap-3 mx-auto">
          <Chat.tool_call name="get_weather" status={:complete} label="Checked the weather">
            <div class="flex items-center gap-3 text-sm">
              <.icon name="hero-sun" class="w-8 h-8 text-warning-500" />
              <div>
                <div class="font-medium text-gray-900 dark:text-gray-100">Paris - 21°C</div>
                <div class="text-xs text-gray-500 dark:text-gray-400">Clear skies until 6pm</div>
              </div>
            </div>
          </Chat.tool_call>
          <Chat.tool_call name="query_db" status={:running} label="Querying the database" />
          <Chat.reasoning label="Thought for 3s">
            The user asked about installs. Check the hex package name, then give
            the two-step answer with a code fence.
          </Chat.reasoning>
          <Chat.chat_error on_retry="chat_history">Rate limited - give it a moment.</Chat.chat_error>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Chat isn't pulled in by use PetalComponents - alias PetalComponents.Chat
        and call it namespaced (it owns generic names like markdown). Markdown
        needs the optional :mdex dep. Reactions and read receipts are social-chat
        territory, not AI - deliberately out of scope for now.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "alert"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-8 py-10 mx-auto">
      <h1 class="text-3xl font-bold tracking-tight">Alert</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A prominent message tied to state: information, success, caution or failure.
        Radius follows the rail above.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">colour</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"
      ><code>{alert_snippet(@alert)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Semantic colours
      </div>
      <div class="px-6 py-8 space-y-3 border border-gray-200 rounded-xl dark:border-gray-800">
        <.alert color="info" variant={@alert.variant} with_icon>
          A new version of this page is available.
        </.alert>
        <.alert color="success" variant={@alert.variant} with_icon>Your changes were saved.</.alert>
        <.alert color="warning" variant={@alert.variant} with_icon>Your trial ends in 3 days.</.alert>
        <.alert color="danger" variant={@alert.variant} with_icon>
          Payment failed. Check your card details.
        </.alert>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Variants</div>
      <div class="px-6 py-8 space-y-3 border border-gray-200 rounded-xl dark:border-gray-800">
        <.alert color="gray" variant="light" with_icon>
          Light, the default. Stays light even in dark mode.
        </.alert>
        <.alert color="gray" variant="soft" with_icon>Soft adapts to dark mode.</.alert>
        <.alert color="gray" variant="dark" with_icon>Dark, maximum emphasis.</.alert>
        <.alert color="gray" variant="outline" with_icon>Outline, for calm surfaces.</.alert>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Dismissible (click the cross)
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
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
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A small label for counts, statuses and categories. Radius follows the rail above.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center px-6 py-14">
          <.badge
            color={@badge.color}
            variant={@badge.variant}
            size={@badge.size}
            with_icon={@badge.icon}
          >
            <.icon :if={@badge.icon} name="hero-sparkles" class="w-3 h-3" /> New
          </.badge>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-6 py-4 border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">colour</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-gray-700">
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
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"
      ><code>{badge_snippet(@badge)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Variants</div>
      <div class="flex flex-wrap items-center justify-center gap-3 px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <.badge label="Light" />
        <.badge variant="soft" label="Soft" />
        <.badge variant="dark" label="Dark" />
        <.badge variant="outline" label="Outline" />
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Semantic colours
      </div>
      <div class="flex flex-wrap items-center justify-center gap-3 px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <.badge
          :for={c <- ~w(primary secondary info success warning danger gray)}
          color={c}
          variant={@badge.variant}
          label={c}
        />
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Sizes</div>
      <div class="flex flex-wrap items-center justify-center gap-3 px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <.badge :for={z <- ~w(xs sm md lg xl)} size={z} label={z} />
      </div>
    </div>
    """
  end

  defp render_page(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center h-full px-8 text-center">
      <.icon name="hero-cube-transparent" class="w-10 h-10 text-gray-300 dark:text-gray-700" />
      <p class="mt-4 text-lg font-medium capitalize">{@active}</p>
      <p class="max-w-sm mt-1 text-sm text-gray-500 dark:text-gray-400">
        This page gets the same treatment next. We're locking the shell and the pattern on Button first.
      </p>
    </div>
    """
  end

  defp seg(true), do: "px-2.5 py-1 text-xs font-medium bg-primary-600 text-(--pc-button-solid-fg)"

  defp seg(false),
    do:
      "px-2.5 py-1 text-xs text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"

  defp tog(true),
    do:
      "px-2.5 py-1 text-xs font-medium rounded-lg border border-transparent bg-primary-600 text-(--pc-button-solid-fg)"

  defp tog(false),
    do:
      "px-2.5 py-1 text-xs rounded-lg border border-gray-200 dark:border-gray-700 text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"
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
  plug Plug.Static, from: Path.expand("dev/static", __DIR__), at: "/dev-static"

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
