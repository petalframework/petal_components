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

  # Fathom (cookieless, no personal data, nothing to consent to) on the
  # PUBLIC deployment only: PLAYGROUND_DEPLOY gates it so a local
  # `mix run dev.exs` never phones home, and the site id comes from the
  # environment so anyone forking this repo and deploying their own
  # playground doesn't report into ours. data-spa="auto" because choosing
  # a component is a push_patch, not a page load - without it we'd record
  # one pageview per session no matter how much of the library you browse.
  defp fathom_site do
    if System.get_env("PLAYGROUND_DEPLOY") == "true", do: System.get_env("FATHOM_SITE_ID")
  end

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <%!-- html AND body carry the scheme backgrounds: iOS paints rubber-band
    overscroll from them (roughly html above the page, body below), so a
    bg-white body under a dark app flashes white at both boundaries.
    theme-color keeps the browser chrome matching. --%>
    <html lang="en" class="bg-white dark:bg-gray-950">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)" />
        <meta name="theme-color" content="#030712" media="(prefers-color-scheme: dark)" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <.live_title>Petal Components Playground</.live_title>
        <PetalComponents.ColorSchemeSwitch.color_scheme_script />
        <script phx-no-curly-interpolation>
          // Playground-only capture override: ?dark=1 / ?dark=0 force the
          // scheme on load (headless screenshots), without touching the
          // visitor's stored preference.
          (() => {
            const dark = new URLSearchParams(location.search).get("dark");
            if (dark === "1") document.documentElement.classList.add("dark");
            if (dark === "0") document.documentElement.classList.remove("dark");
          })();
        </script>
        <meta name="pg-rev" content="alert-badge-1" />
        <link rel="stylesheet" href="/assets/app.css" />
        <script
          :if={fathom_site()}
          src="https://cdn.usefathom.com/script.js"
          data-site={fathom_site()}
          data-spa="auto"
          data-canonical="false"
          defer
        >
        </script>
      </head>
      <body class="bg-white dark:bg-gray-950 antialiased">
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
          window.addEventListener("phx:pg:toggle-scheme", () => {
            if (window.PetalColorScheme) {
              window.PetalColorScheme.set(
                window.PetalColorScheme.resolved() === "dark" ? "light" : "dark"
              );
            }
          });
          window.addEventListener("petal:scheme-changed", () => {
            window.dispatchEvent(new Event("pg:theme-switch"));
          });
          window.addEventListener("pg:theme-switch", () => {
            const style = document.createElement("style");
            style.textContent =
              "*:not(.pc-scheme-toggle__sun):not(.pc-scheme-toggle__moon) { transition: none !important; }";
            document.head.appendChild(style);
            setTimeout(() => style.remove(), 250);
          });
          // Playground-only economy: border_plasma repaints on the main
          // thread every frame, and the demo page runs many instances at
          // once - a worst case no real app ships. Pause any instance
          // that scrolls out of view (the reference library's own driver
          // does the same). The shipped component stays pure CSS.
          const plasmaPause = new IntersectionObserver((entries) => {
            for (const e of entries) {
              e.target.style.setProperty(
                "--pc-plasma-play",
                e.isIntersecting ? "running" : "paused"
              );
            }
          }, { rootMargin: "100px" });
          const watchPlasmas = () => {
            document.querySelectorAll(".pc-border-plasma").forEach((el) => plasmaPause.observe(el));
          };
          watchPlasmas();
          document.addEventListener("phx:update", watchPlasmas);
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
        %{slug: "social-button", name: "Social button", ready: true},
        %{slug: "button-group", name: "Button group", ready: true},
        %{slug: "toggle-group", name: "Toggle group", ready: true},
        %{slug: "input", name: "Input", ready: true},
        %{slug: "input-group", name: "Input group", ready: true},
        %{slug: "checkbox", name: "Checkbox", ready: true},
        %{slug: "select", name: "Select", ready: true},
        %{slug: "combo-box", name: "Combobox", ready: true},
        %{slug: "radio", name: "Radio", ready: true},
        %{slug: "switch", name: "Switch", ready: true},
        %{slug: "slider", name: "Slider", ready: true},
        %{slug: "input-otp", name: "Input OTP", ready: true},
        %{slug: "color-scheme", name: "Color scheme", ready: true}
      ]
    },
    %{
      group: "Feedback",
      items: [
        %{slug: "alert", name: "Alert", ready: true},
        %{slug: "toast", name: "Toast", ready: true},
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
        %{slug: "navigation-menu", name: "Navigation menu", ready: true},
        %{slug: "user-menu", name: "User menu", ready: true},
        %{slug: "language-select", name: "Language select", ready: true}
      ]
    },
    %{
      group: "Data",
      items: [
        %{slug: "table", name: "Table", ready: true},
        %{slug: "data-table", name: "Data table", ready: true},
        %{slug: "chart", name: "Chart", ready: true},
        %{slug: "local-time", name: "Local time", ready: true}
      ]
    },
    %{
      group: "Display",
      items: [
        %{slug: "avatar", name: "Avatar", ready: true},
        %{slug: "card", name: "Card", ready: true},
        %{slug: "carousel", name: "Carousel", ready: true},
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
        %{slug: "border-plasma", name: "Border plasma", ready: true},
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
  @locale_codes ~w(en fr de es pt)
  @playground_languages [
    %{locale: "en", flag: "🇬🇧", label: "English"},
    %{locale: "fr", flag: "🇫🇷", label: "Français"},
    %{locale: "de", flag: "🇩🇪", label: "Deutsch"},
    %{locale: "es", flag: "🇪🇸", label: "Español"},
    %{locale: "pt", flag: "🇵🇹", label: "Português"}
  ]

  # {name, rail swatch css}. Neutral adapts to the mode, hence the split dot.
  @primaries [
    {"neutral", "linear-gradient(135deg,var(--pg-gray-900) 50%,var(--pg-gray-200) 50%)"},
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
  @tint_variants ~w(light soft dark outline callout)

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
       nav_open: false,
       variant: "outline",
       color: "primary",
       size: "md",
       icon: nil,
       loading: false,
       disabled: false,
       show_code: false,
       tg_density: "cozy",
       lang_placement: "left",
       lang_variant: "flag",
       playground_languages: @playground_languages,
       tg_formats: ["bold"],
       tg_device: "desktop",
       tg_variant: "solid",
       tg_size: "md",
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
       alert: %{
         color: "gray",
         variant: "outline",
         icon: true,
         heading: false,
         dismissible: false,
         actions: false,
         rev: 0
       },
       badge: %{
         color: "primary",
         variant: "outline",
         size: "md",
         icon: false,
         dot: false,
         dot_color: nil
       },
       input: %{type: "text", disabled: false, error: false, help: false},
       checkbox: %{layout: "row", disabled: false, error: false},
       select: %{disabled: false, error: false, help: false},
       combo: %{disabled: false, chosen: nil},
       rich: %{labels: ~w(feat bug imp des), team: ~w(amelia jonah)},
       dt: PetalComponents.DataTable.State |> struct(page_size: 5) |> run_dt(),
       dt_selected: [],
       dt_hidden: [],
       dt_order: [],
       dt_refunded: [],
       radio: %{
         style: "cards",
         variant: "outline",
         size: "md",
         layout: "row",
         indicator: false,
         ind_pos: "end",
         disabled: false
       },
       switch: %{size: "md", disabled: false, error: false},
       slider: %{thumbs: "dual", format: "money", disabled: false, fill: true},
       slider_form: slider_form("money"),
       otp: %{length: 6, grouped: false, pattern: "numeric", disabled: false},
       progress: %{
         shape: "bar",
         value: 0,
         color: "primary",
         size: "xs",
         label: "top",
         status: true,
         live: true,
         ticking: false
       },
       beam: %{
         duration: "8s",
         beams: 1,
         reverse: false,
         easing: "linear",
         size: "60px",
         glow: false
       },
       plasma: %{
         mode: "pulse",
         intensity: "medium",
         duration: "2.3s",
         glow: "outside",
         palette: "rainbow"
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
       stepper: %{orientation: "horizontal", size: "md", labels: "beside", at: 0, done: false},
       toast: %{pos: "bottom-right", undone: 0},
       car: %{
         transition: "fade",
         buttons: "overlay",
         indicators: "bars",
         ind_pos: "overlay",
         orientation: "horizontal",
         loop: true,
         autoplay: false,
         thumbnails: false
       },
       nav_trigger: "hover",
       user_menu_opens: "up",
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
         chrome: "full",
         two_series: false,
         gap: "cozy",
         points: 14
       }
     )}
  end

  # Theme state lives in the URL, so any look is shareable / screenshotable.
  def handle_params(params, uri, socket) do
    # /c/data-table-link folded into /c/data-table (Aug 2026). Old shared
    # links keep working: same page, and the State query params decode as
    # before. The address bar normalises on the first link-mode click.
    c = if params["c"] == "data-table-link", do: "data-table", else: params["c"]

    socket =
      socket
      |> assign(:active, allow(c, @slugs, "button"))
      |> assign(:primary, allow(params["primary"] || params["accent"], @primary_names, "neutral"))
      |> assign(:gray, allow(params["gray"], @gray_names, "zinc"))
      |> assign(:secondary, allow(params["secondary"], @secondary_names, "pink"))
      |> assign(:radius, allow(params["radius"], @radius_labels, "10"))
      |> assign(:lang, allow(params["locale"], @locale_codes, "en"))
      |> assign(:dark, false)
      # Any navigation (sidebar, overlay menu, cmdk) lands here - close the
      # mobile menu so picking a component reveals it immediately.
      |> assign(:nav_open, false)
      |> maybe_run_dt_link(params, uri)

    {:noreply, maybe_start_progress_sim(socket)}
  end

  # Link mode's whole loop: the table patches State-encoded URLs, this
  # decodes them back through the same whitelist and re-runs the engine.
  # No events, no other server state - the URL IS the table state.
  defp maybe_run_dt_link(%{assigns: %{active: "data-table"}} = socket, params, uri) do
    alias PetalComponents.DataTable.State

    # PhoenixPlayground's dead render hands handle_params only the path
    # params - the query string arrives solely in uri (the theme dials
    # have always had this flash). Decode it from there so a shared or
    # curled URL renders the right rows on FIRST paint, which is the
    # claim the link-mode demo exists to make. Plug's decoder, not URI's,
    # because filters use bracket-indexed params. On connected patches
    # params already carries the query and the merge is a no-op.
    query = uri |> URI.parse() |> Map.get(:query) || ""
    params = Map.merge(Plug.Conn.Query.decode(query), params)

    state = State.from_params(params, fields: [:name, :email, :status, :amount])
    assign(socket, :dt_link, run_dt(state))
  end

  defp maybe_run_dt_link(socket, _params, _uri), do: socket

  # The progress flagship simulates a live upload while you watch. One
  # timer at a time; it dies quietly when you leave the page or take
  # manual control via the value dial.
  defp maybe_start_progress_sim(socket) do
    %{live: live, ticking: ticking} = socket.assigns.progress

    if socket.assigns.active == "progress" && live && !ticking &&
         Phoenix.LiveView.connected?(socket) do
      Process.send_after(self(), :pg_progress_tick, 700)
      update(socket, :progress, &%{&1 | ticking: true, value: 0})
    else
      socket
    end
  end

  def handle_event("select", %{"slug" => slug}, socket), do: patch_theme(socket, %{active: slug})

  def handle_event("set_gray", %{"gray" => g}, socket), do: patch_theme(socket, %{gray: g})

  def handle_event("set_primary", %{"primary" => p}, socket),
    do: patch_theme(socket, %{primary: p})

  def handle_event("set_secondary", %{"secondary" => x}, socket),
    do: patch_theme(socket, %{secondary: x})

  def handle_event("set_radius", %{"radius" => r}, socket), do: patch_theme(socket, %{radius: r})

  def handle_event("toggle_nav", _params, socket),
    do: {:noreply, assign(socket, nav_open: !socket.assigns.nav_open)}

  def handle_event("close_nav", _params, socket),
    do: {:noreply, assign(socket, nav_open: false)}

  def handle_event("toggle_dark", _params, socket),
    do: {:noreply, push_event(socket, "pg:toggle-scheme", %{})}

  def handle_event("pg_lang_placement", %{"toggle" => p}, socket) when p in ~w(left right),
    do: {:noreply, assign(socket, lang_placement: p)}

  def handle_event("pg_lang_variant", %{"toggle" => v}, socket) when v in ~w(flag code label),
    do: {:noreply, assign(socket, lang_variant: v)}

  def handle_event("pg_tg_density", %{"toggle" => density}, socket)
      when density in ~w(compact cozy comfortable),
      do: {:noreply, assign(socket, tg_density: density)}

  def handle_event("pg_tg_device", %{"toggle" => device}, socket)
      when device in ~w(desktop tablet mobile),
      do: {:noreply, assign(socket, tg_device: device)}

  def handle_event("pg_tg_variant", %{"toggle" => variant}, socket)
      when variant in ~w(solid outline accent),
      do: {:noreply, assign(socket, tg_variant: variant)}

  def handle_event("pg_tg_size", %{"toggle" => size}, socket)
      when size in ~w(sm md lg),
      do: {:noreply, assign(socket, tg_size: size)}

  def handle_event("pg_tg_format", %{"toggle" => format}, socket)
      when format in ~w(bold italic underline) do
    formats = socket.assigns.tg_formats

    formats =
      if format in formats, do: List.delete(formats, format), else: formats ++ [format]

    {:noreply, assign(socket, tg_formats: formats)}
  end

  def handle_event("ctl_variant", %{"v" => v}, socket)
      when v in ~w(solid soft light outline ghost),
      do: {:noreply, assign(socket, :variant, v)}

  def handle_event("ctl_color", %{"v" => v}, socket)
      when v in ~w(primary secondary info success warning danger gray),
      do: {:noreply, assign(socket, :color, v)}

  def handle_event("ctl_size", %{"v" => v}, socket) when v in ~w(xs sm md lg xl),
    do: {:noreply, assign(socket, :size, v)}

  def handle_event("ctl_icon", %{"v" => "off"}, socket),
    do: {:noreply, assign(socket, :icon, nil)}

  def handle_event("ctl_icon", %{"v" => v}, socket) when v in ~w(left right),
    do: {:noreply, assign(socket, :icon, v)}

  def handle_event("flip", %{"k" => "loading"}, socket),
    do: {:noreply, update(socket, :loading, &(!&1))}

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

  # Swapping shape keeps the value/colour/size dials where they are, which is
  # the point: the ring is the same component wearing a different outline.
  # The bar's xs is a hairline, so the ring borrows a size you can see.
  def handle_event("ctl_progress", %{"k" => "shape", "v" => v}, socket) when v in ~w(bar ring),
    do:
      {:noreply,
       update(socket, :progress, fn p ->
         # Same normalisation as the size dial, in both directions: inside only
         # draws where the shape has room for it, so arriving at a shape that
         # can't show it must stop the label dial claiming "inside".
         size = if(v == "ring" and p.size in ~w(xs sm), do: "xl", else: p.size)

         label =
           if p.label == "inside" and not progress_inside_fits?(v, size),
             do: "top",
             else: p.label

         %{p | shape: v, size: size, label: label}
       end)}

  def handle_event("ctl_progress", %{"k" => "value", "v" => v}, socket)
      when v in ~w(15 40 60 85 100),
      do: {:noreply, update(socket, :progress, &%{&1 | live: false, value: String.to_integer(v)})}

  def handle_event("ctl_progress", %{"k" => "color", "v" => v}, socket)
      when v in ~w(primary secondary info success warning danger gray),
      do: {:noreply, update(socket, :progress, &%{&1 | color: v})}

  # The ring only draws its readout in the hole at lg and xl, so shrinking past
  # that moves the readout beside the ring - and the dial follows, dropping
  # from "inside" to the option the ring labels "beside".
  def handle_event("ctl_progress", %{"k" => "size", "v" => v}, socket)
      when v in ~w(xs sm md lg xl),
      do:
        {:noreply,
         update(
           socket,
           :progress,
           &%{
             &1
             | size: v,
               label:
                 if(&1.shape == "ring" and &1.label == "inside" and v not in ~w(lg xl),
                   do: "top",
                   else: &1.label
                 )
           }
         )}

  # Picking "inside" at a size with no room for it moves the size rather than
  # break the promise - xl is the only bar tall enough to carry a label in the
  # track. A ring already at lg keeps its lg: the hole is big enough there.
  def handle_event("ctl_progress", %{"k" => "label", "v" => v}, socket)
      when v in ~w(none inside top),
      do:
        {:noreply,
         update(socket, :progress, fn p ->
           size =
             if v == "inside" and not progress_inside_fits?(p.shape, p.size),
               do: "xl",
               else: p.size

           %{p | label: v, size: size}
         end)}

  def handle_event("ctl_plasma", %{"k" => "mode", "v" => v}, socket) when v in ~w(pulse rotate),
    do: {:noreply, update(socket, :plasma, &%{&1 | mode: v})}

  def handle_event("ctl_plasma", %{"k" => "intensity", "v" => v}, socket)
      when v in ~w(subtle medium strong),
      do: {:noreply, update(socket, :plasma, &%{&1 | intensity: v})}

  def handle_event("ctl_plasma", %{"k" => "duration", "v" => v}, socket) when v in ~w(2.3s 4s 6s),
    do: {:noreply, update(socket, :plasma, &%{&1 | duration: v})}

  def handle_event("ctl_plasma", %{"k" => "glow", "v" => v}, socket)
      when v in ~w(outside inside both),
      do: {:noreply, update(socket, :plasma, &%{&1 | glow: v})}

  def handle_event("ctl_plasma", %{"k" => "palette", "v" => v}, socket)
      when v in ~w(rainbow brand mono ocean sunset),
      do: {:noreply, update(socket, :plasma, &%{&1 | palette: v})}

  def handle_event("ctl_plasma", %{"k" => "width", "v" => v}, socket) when v in ~w(1px 2px 4px),
    do: {:noreply, update(socket, :plasma, &%{&1 | width: v})}

  def handle_event("ctl_beam", %{"k" => "glow"}, socket),
    do: {:noreply, update(socket, :beam, &%{&1 | glow: !&1.glow})}

  def handle_event("chart_randomize", _params, socket) do
    revenue = Enum.map(1..30, fn i -> 550 + i * 12 + :rand.uniform(600) end)
    expenses = Enum.map(1..30, fn i -> 300 + i * 6 + :rand.uniform(350) end)
    {:noreply, update(socket, :chart, &%{&1 | revenue: revenue, expenses: expenses})}
  end

  def handle_event("ctl_chart", %{"k" => "two_series", "v" => v}, socket) when v in ~w(one two),
    do: {:noreply, update(socket, :chart, &%{&1 | two_series: v == "two"})}

  def handle_event("ctl_chart", %{"k" => "gap", "v" => v}, socket) when v in ~w(cozy tight),
    do: {:noreply, update(socket, :chart, &%{&1 | gap: v})}

  def handle_event("ctl_chart", %{"k" => "points", "v" => v}, socket) when v in ~w(7 14 30),
    do: {:noreply, update(socket, :chart, &%{&1 | points: String.to_integer(v)})}

  def handle_event("ctl_chart", %{"k" => "type", "v" => v}, socket)
      when v in ~w(line bar),
      do: {:noreply, update(socket, :chart, &%{&1 | type: v})}

  def handle_event("ctl_chart", %{"k" => "shape", "v" => v}, socket)
      when v in ~w(smooth linear step),
      do: {:noreply, update(socket, :chart, &%{&1 | shape: v})}

  def handle_event("ctl_chart", %{"k" => "area", "v" => v}, socket)
      when v in ~w(fade solid none),
      do: {:noreply, update(socket, :chart, &%{&1 | area: v})}

  def handle_event("ctl_chart", %{"k" => "dots", "v" => v}, socket) when v in ~w(on off),
    do: {:noreply, update(socket, :chart, &%{&1 | dots: v == "on"})}

  def handle_event("ctl_chart", %{"k" => "chrome", "v" => v}, socket) when v in ~w(full x off),
    do: {:noreply, update(socket, :chart, &%{&1 | chrome: v})}

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

  def handle_info(:toast_morph_done, socket) do
    {:noreply,
     PetalComponents.Toast.send_toast(socket, :success,
       id: "pg-export",
       title: "Export ready",
       description: "report-q3.csv - 2.4 MB",
       duration: 5000,
       action: %{label: "Download", event: "toast_undo", value: %{}}
     )}
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

  def handle_event("ctl_stepper", %{"k" => "labels", "v" => v}, socket)
      when v in ~w(beside bottom),
      do: {:noreply, update(socket, :stepper, &%{&1 | labels: v})}

  def handle_event("ctl_carousel", %{"k" => "transition", "v" => v}, socket)
      when v in ~w(fade slide),
      do: {:noreply, update(socket, :car, &%{&1 | transition: v})}

  def handle_event("ctl_carousel", %{"k" => "buttons", "v" => v}, socket)
      when v in ~w(overlay below outside none),
      do: {:noreply, update(socket, :car, &%{&1 | buttons: v})}

  def handle_event("ctl_carousel", %{"k" => "indicators", "v" => v}, socket)
      when v in ~w(bars dots off),
      do: {:noreply, update(socket, :car, &%{&1 | indicators: v})}

  def handle_event("ctl_carousel", %{"k" => "ind_pos", "v" => v}, socket)
      when v in ~w(overlay below),
      do: {:noreply, update(socket, :car, &%{&1 | ind_pos: v})}

  def handle_event("ctl_carousel", %{"k" => "loop"}, socket),
    do: {:noreply, update(socket, :car, &%{&1 | loop: !&1.loop})}

  def handle_event("ctl_carousel", %{"k" => "autoplay"}, socket),
    do: {:noreply, update(socket, :car, &%{&1 | autoplay: !&1.autoplay})}

  def handle_event("ctl_carousel", %{"k" => "thumbnails"}, socket),
    do: {:noreply, update(socket, :car, &%{&1 | thumbnails: !&1.thumbnails})}

  def handle_event("ctl_carousel", %{"k" => "orientation", "v" => v}, socket)
      when v in ~w(horizontal vertical),
      do: {:noreply, update(socket, :car, &%{&1 | orientation: v})}

  def handle_event("toast_demo", %{"kind" => kind}, socket)
      when kind in ~w(info success warning danger neutral) do
    titles = %{
      "info" => {"Heads up", "A new version of the app is available."},
      "success" => {"Changes saved", "Your profile is up to date."},
      "warning" => {"Storage almost full", "You have used 90% of your plan."},
      "danger" => {"Payment failed", "Your card was declined - try another."},
      "neutral" => {"Event logged", nil}
    }

    {title, desc} = titles[kind]

    {:noreply,
     PetalComponents.Toast.send_toast(socket, String.to_existing_atom(kind),
       title: title,
       description: desc
     )}
  end

  def handle_event("toast_demo", %{"demo" => "morph"}, socket) do
    Process.send_after(self(), :toast_morph_done, 2500)

    {:noreply,
     PetalComponents.Toast.send_toast(socket, :loading,
       id: "pg-export",
       title: "Exporting report...",
       description: "Crunching 3 months of data."
     )}
  end

  def handle_event("toast_demo", %{"demo" => "action"}, socket) do
    {:noreply,
     PetalComponents.Toast.send_toast(socket, :info,
       title: "Message archived",
       action: %{label: "Undo", event: "toast_undo", value: %{}}
     )}
  end

  def handle_event("toast_demo", %{"demo" => "sticky"}, socket) do
    {:noreply,
     PetalComponents.Toast.send_toast(socket, :warning,
       duration: :infinity,
       title: "Scheduled maintenance tonight",
       description: "Stays until dismissed - no timer, no progress."
     )}
  end

  def handle_event("toast_demo", %{"demo" => "burst"}, socket) do
    socket =
      Enum.reduce(1..6, socket, fn i, acc ->
        PetalComponents.Toast.send_toast(acc, :neutral,
          title: "Notification #{i} of 6",
          duration: 6000
        )
      end)

    {:noreply, socket}
  end

  def handle_event("toast_demo", %{"demo" => "dismiss_all"}, socket),
    do: {:noreply, PetalComponents.Toast.dismiss_toast(socket, :all)}

  def handle_event("toast_demo", %{"demo" => "flash"}, socket),
    do: {:noreply, Phoenix.LiveView.put_flash(socket, :info, "This came through put_flash.")}

  def handle_event("toast_undo", _params, socket) do
    socket = update(socket, :toast, &%{&1 | undone: &1.undone + 1})

    {:noreply,
     PetalComponents.Toast.send_toast(socket, :success,
       title: "Restored",
       description: "Undo #{socket.assigns.toast.undone} handled by the LiveView."
     )}
  end

  def handle_event("ctl_toast", %{"k" => "pos", "v" => v}, socket)
      when v in ~w(top-left top-center top-right bottom-left bottom-center bottom-right),
      do: {:noreply, update(socket, :toast, &%{&1 | pos: v})}

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

  def handle_event("ctl_usermenu", %{"k" => "opens", "v" => v}, socket)
      when v in ~w(up beside),
      do: {:noreply, assign(socket, :user_menu_opens, v)}

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

  def handle_event("ctl_slider", %{"k" => "format", "v" => v}, socket)
      when v in ~w(money percent plain),
      do:
        {:noreply,
         socket
         |> update(:slider, &%{&1 | format: v})
         |> assign(:slider_form, slider_form(v))}

  def handle_event("ctl_slider", %{"k" => "disabled"}, socket),
    do: {:noreply, update(socket, :slider, &%{&1 | disabled: !&1.disabled})}

  def handle_event("ctl_slider", %{"k" => "fill"}, socket),
    do: {:noreply, update(socket, :slider, &%{&1 | fill: !&1.fill})}

  def handle_event("ctl_slider", %{"k" => "thumbs", "v" => v}, socket)
      when v in ~w(single dual),
      do: {:noreply, update(socket, :slider, &%{&1 | thumbs: v})}

  def handle_event("ctl_radio", %{"k" => "style", "v" => v}, socket)
      when v in ~w(cards plain),
      do: {:noreply, update(socket, :radio, &%{&1 | style: v})}

  def handle_event("ctl_radio", %{"k" => k}, socket) when k in ~w(indicator disabled),
    do:
      {:noreply,
       update(socket, :radio, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  def handle_event("ctl_radio", %{"k" => "ind_pos", "v" => v}, socket)
      when v in ~w(end corner start),
      do: {:noreply, update(socket, :radio, &%{&1 | ind_pos: v})}

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

  def handle_event("ctl_combo", %{"k" => k}, socket) when k in ~w(disabled),
    do:
      {:noreply,
       update(socket, :combo, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  # the hidden select posts like any select - this is the whole point of the
  # component, so the page proves it live
  def handle_event("pg_combo_change", %{"pg_city" => value}, socket),
    do: {:noreply, update(socket, :combo, &%{&1 | chosen: value})}

  # the data table's event-mode op grammar: State.handle_op speaks all of
  # it (sort/page/search/page_size/filter/clear_filters), so the whole
  # backend is one call plus a re-run through the free engine
  def handle_event("pg_table", params, socket) do
    alias PetalComponents.DataTable.State
    {state, _rows} = socket.assigns.dt

    state = State.handle_op(state, params, fields: [:name, :email, :status, :amount])

    # selection is UI state, outside State - a MapSet and three clauses
    was_selected = socket.assigns.dt_selected
    selected = was_selected

    selected =
      case params do
        %{"op" => "select", "id" => id} ->
          if id in selected, do: List.delete(selected, id), else: selected ++ [id]

        %{"op" => "select_all"} ->
          {_state, rows} = socket.assigns.dt
          page_ids = Enum.map(rows, &to_string(&1.id))

          if Enum.all?(page_ids, &(&1 in selected)),
            do: selected -- page_ids,
            else: Enum.uniq(selected ++ page_ids)

        %{"op" => "clear_selection"} ->
          []

        # a bulk action consumes the selection: act, then clear
        %{"op" => "refund"} ->
          []

        _ ->
          selected
      end

    refunded =
      case params do
        %{"op" => "refund"} -> Enum.uniq(socket.assigns.dt_refunded ++ was_selected)
        _ -> socket.assigns.dt_refunded
      end

    hidden =
      case params do
        %{"op" => "toggle_column", "field" => field} ->
          hidden = socket.assigns.dt_hidden
          if field in hidden, do: List.delete(hidden, field), else: hidden ++ [field]

        _ ->
          socket.assigns.dt_hidden
      end

    order =
      case params do
        %{"op" => "move_column", "field" => f, "dir" => dir} ->
          PetalComponents.DataTable.move_column(
            socket.assigns.dt_order,
            [:name, :email, :status, :amount],
            f,
            dir
          )

        _ ->
          socket.assigns.dt_order
      end

    {:noreply,
     socket
     |> assign(:dt, run_dt(state, refunded))
     |> assign(:dt_selected, selected)
     |> assign(:dt_hidden, hidden)
     |> assign(:dt_order, order)
     |> assign(:dt_refunded, refunded)}
  end

  defp run_dt(state, refunded \\ []) do
    rows =
      Enum.map(PetalComponents.Showcase.DataTable.sample_rows(), fn row ->
        if to_string(row.id) in refunded, do: %{row | status: "refunded"}, else: row
      end)

    {rows, state} = PetalComponents.DataTable.Engine.List.run(rows, state)

    {state, rows}
  end

  def handle_event("pg_remote_search", term, socket) do
    term = String.downcase(to_string(term))

    results =
      ~w(Amsterdam Athens Auckland Bangkok Barcelona Beijing Berlin Bogota Boston Brisbane
         Brussels Budapest BuenosAires Cairo CapeTown Chicago Copenhagen Dallas Delhi Dubai
         Dublin Edinburgh Geneva Hanoi Helsinki HongKong Houston Istanbul Jakarta Johannesburg
         KualaLumpur Lagos Lima Lisbon London LosAngeles Madrid Melbourne MexicoCity Miami
         Milan Montreal Moscow Mumbai Munich Nairobi NewYork Osaka Oslo Paris Prague Rome
         SanFrancisco Santiago Seoul Shanghai Singapore Stockholm Sydney Tokyo Toronto
         Vancouver Vienna Warsaw Wellington Zurich)
      |> Enum.filter(&String.contains?(String.downcase(&1), term))
      |> Enum.take(8)
      |> Enum.map(&%{text: &1, value: &1})

    {:reply, %{results: results}, socket}
  end

  def handle_event("pg_remote_change", _params, socket), do: {:noreply, socket}

  def handle_event("pg_rich_change", params, socket) do
    {:noreply,
     assign(socket, :rich, %{
       labels: Map.get(params, "pg_labels", []),
       team: Map.get(params, "pg_team", [])
     })}
  end

  def handle_event("ctl_checkbox", %{"k" => "layout", "v" => v}, socket) when v in ~w(row col),
    do: {:noreply, update(socket, :checkbox, &%{&1 | layout: v})}

  def handle_event("ctl_checkbox", %{"k" => k}, socket) when k in ~w(disabled error),
    do:
      {:noreply,
       update(socket, :checkbox, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  def handle_event("ctl_progress", %{"k" => "live"}, socket) do
    socket = update(socket, :progress, &%{&1 | live: !&1.live})
    {:noreply, maybe_start_progress_sim(socket)}
  end

  def handle_event("ctl_progress", %{"k" => "status"}, socket),
    do: {:noreply, update(socket, :progress, &%{&1 | status: !&1.status})}

  def handle_info(:pg_progress_tick, socket) do
    %{live: live, value: value} = socket.assigns.progress

    if socket.assigns.active == "progress" && live do
      # Small organic steps; linger a beat on "Done!" before restarting
      {next, delay} =
        if value >= 100,
          do: {0, 1600},
          else: {min(100, value + Enum.random(2..3)), Enum.random(180..300)}

      Process.send_after(self(), :pg_progress_tick, delay)
      {:noreply, update(socket, :progress, &%{&1 | value: next})}
    else
      {:noreply, update(socket, :progress, &%{&1 | ticking: false})}
    end
  end

  def handle_event("ctl_alert", %{"k" => "color", "v" => v}, socket) when v in @alert_colors,
    do: {:noreply, update(socket, :alert, &%{&1 | color: v, rev: &1.rev + 1})}

  def handle_event("ctl_alert", %{"k" => "variant", "v" => v}, socket) when v in @tint_variants,
    do: {:noreply, update(socket, :alert, &%{&1 | variant: v, rev: &1.rev + 1})}

  def handle_event("ctl_alert", %{"k" => "icon"}, socket),
    do: {:noreply, update(socket, :alert, &%{&1 | icon: !&1.icon, rev: &1.rev + 1})}

  def handle_event("ctl_alert", %{"k" => "heading"}, socket),
    do: {:noreply, update(socket, :alert, &%{&1 | heading: !&1.heading, rev: &1.rev + 1})}

  def handle_event("ctl_alert", %{"k" => "dismissible"}, socket),
    do: {:noreply, update(socket, :alert, &%{&1 | dismissible: !&1.dismissible, rev: &1.rev + 1})}

  def handle_event("ctl_alert", %{"k" => "actions"}, socket),
    do: {:noreply, update(socket, :alert, &%{&1 | actions: !&1.actions, rev: &1.rev + 1})}

  def handle_event("ctl_badge", %{"k" => "color", "v" => v}, socket) when v in @badge_colors,
    do: {:noreply, update(socket, :badge, &%{&1 | color: v})}

  def handle_event("ctl_badge", %{"k" => "variant", "v" => v}, socket) when v in @tint_variants,
    do: {:noreply, update(socket, :badge, &%{&1 | variant: v})}

  def handle_event("ctl_badge", %{"k" => "size", "v" => v}, socket) when v in ~w(xs sm md lg xl),
    do: {:noreply, update(socket, :badge, &%{&1 | size: v})}

  # dot and icon are mutually exclusive on the flagship. They compose fine -
  # the showcase examples below the dials still demonstrate the pairing - but
  # as the one badge at the top of the page, a dot and an icon in front of a
  # two-word label is more furniture than label.
  def handle_event("ctl_badge", %{"k" => "icon"}, socket),
    do: {:noreply, update(socket, :badge, &%{&1 | icon: !&1.icon, dot: false})}

  def handle_event("ctl_badge", %{"k" => "dot"}, socket),
    do: {:noreply, update(socket, :badge, &%{&1 | dot: !&1.dot, icon: false})}

  # The dot colour survives toggling the dot off and on - it is the dial's
  # own state, not a consequence of the dot's.
  def handle_event("ctl_badge", %{"k" => "dot_color", "v" => "inherit"}, socket),
    do: {:noreply, update(socket, :badge, &%{&1 | dot_color: nil})}

  def handle_event("ctl_badge", %{"k" => "dot_color", "v" => v}, socket)
      when v in @badge_colors,
      do: {:noreply, update(socket, :badge, &%{&1 | dot_color: v})}

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
      |> Map.take([:active, :primary, :secondary, :gray, :radius])
      |> Map.merge(delta)

    {:noreply, push_patch(socket, to: theme_path(theme))}
  end

  defp theme_path(t) do
    # Component in the PATH (see the /c/:c route - Fathom needs it there),
    # theme in the query (it is a look, not a page; also Fathom drops query
    # strings, which for the dials is exactly right).
    base = if t.active == "button", do: "/", else: "/c/#{t.active}"

    []
    |> then(&if t.radius != "10", do: [{"radius", t.radius} | &1], else: &1)
    |> then(&if t.secondary != "pink", do: [{"secondary", t.secondary} | &1], else: &1)
    |> then(&if t.gray != "zinc", do: [{"gray", t.gray} | &1], else: &1)
    |> then(&if t.primary != "neutral", do: [{"primary", t.primary} | &1], else: &1)
    |> case do
      [] -> base
      q -> base <> "?" <> URI.encode_query(q)
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

  defp icon_for_side("right"), do: "hero-arrow-right"
  defp icon_for_side(_), do: "hero-rocket-launch"

  defp button_snippet(a) do
    attrs =
      [
        a.variant != "solid" && ~s(variant="#{a.variant}"),
        a.color != "primary" && ~s(color="#{a.color}"),
        a.size != "md" && ~s(size="#{a.size}"),
        a.icon && ~s(icon="#{icon_for_side(a.icon)}"),
        a.icon == "right" && ~s(icon_placement="right"),
        a.loading && "loading",
        a.disabled && "disabled"
      ]
      |> Enum.filter(& &1)

    case attrs do
      [] -> "<.button>Get started</.button>"
      _ -> "<.button #{Enum.join(attrs, " ")}>Get started</.button>"
    end
  end

  # A page's slice of a showcase module, in the page's order. Field is one
  # component (so one registry module), but the playground splits its examples
  # across the input / select / checkbox / radio / switch pages. Raises on a
  # typo'd id so a page can't silently drop an example.
  defp examples_for(module, ids) do
    by_id = Map.new(module.examples(), &{&1.id, &1})
    Enum.map(ids, &Map.fetch!(by_id, &1))
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

  defp progress_status(v) when v < 5, do: "Initializing download..."
  defp progress_status(v) when v < 30, do: "Downloading dependencies..."
  defp progress_status(v) when v < 60, do: "Downloading assets..."
  defp progress_status(v) when v < 85, do: "Extracting files..."
  defp progress_status(v) when v < 100, do: "Finishing up..."
  defp progress_status(_v), do: "Done!"

  # Where an inside label actually draws: the ring paints its readout in the
  # hole from lg up, the bar carries a label in the track at xl only.
  defp progress_inside_fits?("ring", size), do: size in ~w(lg xl)
  defp progress_inside_fits?(_bar, size), do: size == "xl"

  # Only the ring greys the option out, because only the ring can sit at a size
  # where "inside" would be a no-op: the bar's own dial moves the size to xl for
  # you, the way it always has.
  defp progress_inside_disabled?("ring" = shape, size), do: not progress_inside_fits?(shape, size)
  defp progress_inside_disabled?(_bar, _size), do: false

  # One state, two truthful names. The third position means "the readout lives
  # outside the indicator": the bar says that with the component's own
  # label_position="top", the ring by composing the readout beside itself (the
  # "Labels beside the ring" example further down the page). Renaming the state
  # value would only move the lie to the bar.
  defp progress_label_name("ring", "top"), do: "beside"
  defp progress_label_name(_shape, label), do: label

  defp progress_snippet(%{shape: "ring"} = pr) do
    attrs =
      [
        ~s(value={#{pr.value}}),
        pr.color != "primary" && ~s(color="#{pr.color}"),
        pr.size != "md" && ~s(size="#{pr.size}"),
        pr.label == "inside" && "show_value"
      ]
      |> Enum.filter(& &1)

    ring = "<.progress_ring #{Enum.join(attrs, " ")} />"

    # Beside the ring is composition, not an attr - so the snippet has to show
    # the row, or it stops matching what the preview is doing.
    if pr.label == "top" do
      """
      <div class="flex items-center gap-2 text-sm tabular-nums">
        #{ring}
        #{pr.value}%
      </div>\
      """
    else
      ring
    end
  end

  defp progress_snippet(pr) do
    attrs =
      [
        ~s(value={#{pr.value}}),
        pr.color != "primary" && ~s(color="#{pr.color}"),
        pr.size != "md" && ~s(size="#{pr.size}"),
        pr.label == "inside" && ~s(label="#{pr.value}%"),
        pr.label == "top" && ~s(label="Download progress" label_position="top"),
        pr.status && ~s(status="#{progress_status(pr.value)}")
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
    revenue = Enum.take(chart.revenue, chart.points)
    expenses = Enum.take(chart.expenses, chart.points)

    datasets =
      if chart.two_series,
        do: [{"revenue", "Revenue", revenue}, {"expenses", "Expenses", expenses}],
        else: [{"revenue", "Revenue", revenue}]

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
      axisLabel: %{interval: if(chart.points <= 7, do: 0, else: 3)},
      data: Enum.map(1..chart.points, &"Apr #{&1}")
    }

    tooltip = %{trigger: "axis", valueFormatter: "petal:currency:USD"}

    base =
      case chart.chrome do
        "full" ->
          %{
            grid: %{left: 8, right: 16, top: 16, bottom: 8, containLabel: true},
            xAxis: axis_x,
            yAxis: %{
              type: "value",
              axisLabel: %{formatter: "petal:currency-compact:USD"}
            },
            tooltip: tooltip,
            series: series
          }

        "x" ->
          # x labels only - the dashboard-card look (values live in the
          # tooltip, the categories anchor the shape)
          %{
            grid: %{left: 8, right: 8, top: 8, bottom: 8, containLabel: true},
            xAxis: axis_x,
            yAxis: %{type: "value", show: false},
            tooltip: tooltip,
            series: series
          }

        "off" ->
          # Chromeless: no axis labels, no gridlines - just the shape.
          %{
            grid: %{left: 8, right: 8, top: 8, bottom: 8},
            xAxis: Map.put(axis_x, :show, false),
            yAxis: %{type: "value", show: false},
            tooltip: tooltip,
            series: series
          }
      end

    if chart.two_series && chart.chrome != "off",
      do:
        Map.merge(base, %{
          legend: %{top: 0},
          grid: %{left: 8, right: 16, top: 36, bottom: 8, containLabel: true}
        }),
      else: base
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

  defp plasma_snippet(pl) do
    attrs =
      [
        pl.mode != "pulse" && ~s(mode="#{pl.mode}"),
        pl.intensity != "medium" && ~s(intensity="#{pl.intensity}"),
        pl.duration != "2.3s" && ~s(duration="#{pl.duration}"),
        pl.glow != "outside" && ~s(glow="#{pl.glow}"),
        pl.palette != "rainbow" && ~s(palette="#{pl.palette}")
      ]
      |> Enum.filter(& &1)

    open = Enum.join(["<.border_plasma" | attrs], " ")
    open <> ">\n  <div class=\"p-8\">...</div>\n</.border_plasma>"
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

  defp slider_form("money"), do: to_form(%{"min" => "250", "max" => "750"}, as: :pg_range)
  defp slider_form("percent"), do: to_form(%{"min" => "20", "max" => "80"}, as: :pg_range)
  defp slider_form("plain"), do: to_form(%{"min" => "25", "max" => "75"}, as: :pg_range)

  defp slider_bounds("money"),
    do: %{bound_min: 0, bound_max: 1000, step: 25, prefix: "$", suffix: "", label: "Price range"}

  defp slider_bounds("percent"),
    do: %{bound_min: 0, bound_max: 100, step: 5, prefix: "", suffix: "%", label: "Discount range"}

  defp slider_bounds("plain"),
    do: %{bound_min: 0, bound_max: 100, step: 1, prefix: "", suffix: "", label: "Value range"}

  defp slider_snippet(%{thumbs: "single"} = s) do
    attrs =
      [
        ~s(type="range"),
        ~s(name="volume"),
        ~s(label="Volume"),
        ~s(value="60"),
        ~s(min="0"),
        ~s(max="100"),
        s.fill && "fill",
        s.disabled && "disabled"
      ]
      |> Enum.filter(& &1)

    "<.field #{Enum.join(attrs, " ")} />"
  end

  defp slider_snippet(s) do
    b = slider_bounds(s.format)

    attrs =
      [
        ~s(type="range-dual"),
        ~s(min_field={@form[:min]}),
        ~s(max_field={@form[:max]}),
        ~s(range_min={#{b.bound_min}}),
        ~s(range_max={#{b.bound_max}}),
        b.step != 1 && ~s(step={#{b.step}}),
        b.prefix != "" && ~s(value_prefix="#{b.prefix}"),
        b.suffix != "" && ~s(value_suffix="#{b.suffix}"),
        ~s(label="#{b.label}"),
        s.disabled && "disabled"
      ]
      |> Enum.filter(& &1)
      |> Enum.map(&("    " <> &1))

    """
    <.form for={@form} phx-change="filter">
      <.field
    #{Enum.join(attrs, "\n")}
      />
    </.form>\
    """
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

  defp radio_snippet(%{style: "plain"} = r) do
    attrs =
      [
        ~s(type="radio-group"),
        ~s(name="plan"),
        ~s(label="Plan"),
        ~s(value="pro"),
        r.layout != "row" && ~s(group_layout="#{r.layout}"),
        r.disabled && "disabled",
        ~s|options={[{"Starter", "starter"}, {"Pro", "pro"}, {"Team", "team"}]}|
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
        r.indicator && "indicator",
        r.indicator && r.ind_pos != "end" && ~s(indicator_position="#{r.ind_pos}"),
        r.disabled && "disabled",
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
        b.icon && "with_icon",
        b.dot && "dot",
        b.dot && b.dot_color && ~s(dot_color="#{b.dot_color}")
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
      class={
        [
          # Dark mode is owned by the document class via the library's own
          # color_scheme_script - the playground dogfoods color_scheme_switch
          # in the topbar. The old ?dark=1 URL param survives only as a
          # capture override in the layout head (headless screenshots).
          "flex flex-col h-screen bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-50"
        ]
      }
      data-primary={@primary}
      data-gray={@gray}
      data-secondary={@secondary}
      style={"--pc-radius: #{radius_css(@radius)}"}
    >
      <.toast_group id="pg-toasts" position={@toast.pos} flash={@flash} />
      <%!-- inert while the menu is open: complete background isolation for
      keyboard AND assistive tech (focus_wrap alone only fences Tab). --%>
      <header
        inert={@nav_open}
        class="flex items-center justify-between flex-none px-4 border-b h-14 border-gray-200 dark:border-gray-800"
      >
        <div class="flex items-center gap-2 text-[15px] font-semibold">
          <button
            id="pg-menu-burger"
            phx-click="toggle_nav"
            aria-label="Open component menu"
            class="relative flex items-center justify-center w-8 h-8 -ml-1.5 mr-0.5 rounded-lg lg:hidden text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-900 before:absolute before:content-[''] before:-inset-1"
          >
            <.icon name="hero-bars-3" class="w-5 h-5" />
          </button>
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
            <kbd class="pc-kbd ml-auto"><span>⌘</span>K</kbd>
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
          <.color_scheme_switch id="pg-topbar-scheme" variant="toggle" />
        </div>
      </header>

      <%!-- Dial strip: on touch widths it scrolls sideways (scrollbar hidden)
      rather than wrapping - wrapping would push the canvas below the fold,
      and the dials are the point of the playground. --%>
      <div
        inert={@nav_open}
        class="flex items-center flex-none h-12 sm:h-11 gap-5 px-4 overflow-x-auto border-b border-gray-200 dark:border-gray-800 bg-gray-50/60 dark:bg-gray-900/30 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
      >
        <div class="flex items-center gap-2.5 shrink-0">
          <span class="text-[11px] font-medium text-gray-400 dark:text-gray-500">primary</span>
          <div class="flex items-center gap-2 sm:gap-1.5">
            <button
              :for={{name, css} <- @primaries}
              phx-click="set_primary"
              phx-value-primary={name}
              aria-label={"primary #{name}"}
              class={[
                "w-6 h-6 sm:w-4.5 sm:h-4.5 shrink-0 rounded-full transition-transform hover:scale-110",
                @primary == name &&
                  "ring-2 ring-offset-2 ring-gray-400 dark:ring-gray-500 ring-offset-gray-50 dark:ring-offset-gray-950"
              ]}
              style={"background:#{css}"}
            ></button>
          </div>
        </div>
        <div class="flex items-center gap-2.5 shrink-0">
          <span class="text-[11px] font-medium text-gray-400 dark:text-gray-500">secondary</span>
          <div class="flex items-center gap-2 sm:gap-1.5">
            <button
              :for={{name, css} <- @secondaries}
              phx-click="set_secondary"
              phx-value-secondary={name}
              aria-label={"secondary #{name}"}
              class={[
                "w-6 h-6 sm:w-4.5 sm:h-4.5 shrink-0 rounded-full transition-transform hover:scale-110",
                @secondary == name &&
                  "ring-2 ring-offset-2 ring-gray-400 dark:ring-gray-500 ring-offset-gray-50 dark:ring-offset-gray-950"
              ]}
              style={"background:#{css}"}
            ></button>
          </div>
        </div>
        <div class="flex items-center gap-2.5 shrink-0">
          <span class="text-[11px] font-medium text-gray-400 dark:text-gray-500">gray</span>
          <div class="flex items-center gap-2 sm:gap-1.5">
            <button
              :for={{name, css} <- @grays}
              phx-click="set_gray"
              phx-value-gray={name}
              aria-label={"gray #{name}"}
              title={name}
              class={[
                "w-6 h-6 sm:w-4.5 sm:h-4.5 shrink-0 rounded-full transition-transform hover:scale-110",
                @gray == name &&
                  "ring-2 ring-offset-2 ring-gray-400 dark:ring-gray-500 ring-offset-gray-50 dark:ring-offset-gray-950"
              ]}
              style={"background:#{css}"}
            ></button>
          </div>
        </div>
        <div class="flex items-center gap-2.5 shrink-0">
          <span class="text-[11px] font-medium text-gray-400 dark:text-gray-500">radius</span>
          <.toggle_group
            variant="outline"
            size="sm"
            aria_label="Corner radius"
            value={@radius}
            on_change="set_radius"
            class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
          >
            <:item
              :for={{label, _value} <- @radii}
              value={label}
              phx-value-radius={label}
              title={radius_title(label)}
            >
              {label}
            </:item>
          </.toggle_group>
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

      <%!-- Full-screen component menu, tablet down (shadcn/reui grammar: a
      menu you READ - large-text list, muted group labels - not a shrunken
      sidebar). Server-owned open state; any select patches the URL, and
      handle_params closes it. Hand-rolled on purpose: the sidebar primitive
      planned for 4.9 replaces this and inherits its grammar. --%>
      <div
        :if={@nav_open}
        id="pg-menu-overlay"
        class="fixed inset-0 z-50 lg:hidden"
        role="dialog"
        aria-modal="true"
        aria-label="Component menu"
        phx-window-keydown="close_nav"
        phx-key="escape"
        phx-remove={JS.focus(to: "#pg-menu-burger")}
      >
        <.focus_wrap
          id="pg-menu-focus"
          class="flex flex-col h-full bg-white/95 dark:bg-gray-950/95 backdrop-blur"
        >
          <div class="flex items-center justify-between flex-none h-14 px-4 border-b border-gray-200/60 dark:border-gray-800/60">
            <div class="flex items-center gap-3">
              <button
                phx-click="toggle_nav"
                aria-label="Close menu"
                class="relative flex items-center justify-center w-8 h-8 -ml-1.5 text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 before:absolute before:content-[''] before:-inset-2"
              >
                <.icon name="hero-x-mark" class="w-5 h-5" />
              </button>
              <span class="text-[15px] font-semibold">Menu</span>
            </div>
            <.color_scheme_switch id="pg-menu-scheme" variant="toggle" />
          </div>
          <nav class="flex-1 px-6 py-6 overflow-y-auto">
            <div :for={grp <- @nav} class="mb-10">
              <div class="mb-3 text-sm font-medium text-gray-400 dark:text-gray-500">
                {grp.group}
              </div>
              <div class="flex flex-col">
                <button
                  :for={it <- grp.items}
                  phx-click="select"
                  phx-value-slug={it.slug}
                  class={[
                    "flex items-center py-1.5 text-2xl font-medium text-left",
                    (@active == it.slug && "text-gray-900 dark:text-gray-50") ||
                      "text-gray-600 dark:text-gray-400"
                  ]}
                >
                  {it.name}
                  <span
                    :if={not it.ready}
                    class="ml-3 text-xs px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800/80 text-gray-400 dark:text-gray-500"
                  >
                    soon
                  </span>
                </button>
              </div>
            </div>
          </nav>
        </.focus_wrap>
      </div>

      <div inert={@nav_open} class="flex flex-1 min-h-0">
        <nav class="hidden lg:block flex-none p-3 overflow-y-auto border-r w-52 border-gray-200 dark:border-gray-800">
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

        <%!-- overflow-x-hidden: decorative bleed (the plasma halo's oversized
        blur-headroom boxes reach ~116px past their panels) must clip at the
        pane edge instead of growing phantom horizontal scroll on mobile.
        The glow still paints to the edge; only the scroll range is fenced. --%>
        <main class="flex-1 min-w-0 overflow-y-auto overflow-x-hidden">
          {render_page(assigns)}
        </main>
      </div>
    </div>
    """
  end

  defp render_page(%{active: "button"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
            icon={if @icon, do: icon_for_side(@icon)}
            icon_placement={@icon || "left"}
            loading={@loading}
            disabled={@disabled}
          >
            Get started
          </.button>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">colour</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Color"
              value={@color}
              on_change="ctl_color"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={c <- ~w(primary secondary info success warning danger gray)}
                value={c}
                phx-value-v={c}
              >
                {c}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Variant"
              value={@variant}
              on_change="ctl_variant"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={v <- ~w(solid soft light outline ghost)} value={v} phx-value-v={v}>
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Size"
              value={@size}
              on_change="ctl_size"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={s <- ~w(xs sm md lg xl)} value={s} phx-value-v={s}>{s}</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">icon</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Icon"
              value={@icon || "off"}
              on_change="ctl_icon"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="off" phx-value-v="off">off</:item>
              <:item value="left" phx-value-v="left">left</:item>
              <:item value="right" phx-value-v="right">right</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">state</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="State"
              value={for {k, on} <- [{"loading", @loading}, {"disabled", @disabled}], on, do: k}
              on_change="flip"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="loading" phx-value-k="loading">loading</:item>
              <:item value="disabled" phx-value-k="disabled">disabled</:item>
            </.toggle_group>
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

      <div :for={ex <- PetalComponents.Showcase.Button.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Button} functions={[:button, :icon_button]} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Button</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "input"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">type</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Type"
              value={@input.type}
              on_change="ctl_input"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={t <- ~w(text email password search date time select textarea file color)}
                value={t}
                phx-value-k="type"
                phx-value-v={t}
              >
                {t}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">state</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="State"
              value={
                for {k, on} <- [
                      {"help", @input.help},
                      {"error", @input.error},
                      {"disabled", @input.disabled}
                    ],
                    on,
                    do: k
              }
              on_change="ctl_input"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="help" phx-value-k="help">help</:item>
              <:item value="error" phx-value-k="error">error</:item>
              <:item value="disabled" phx-value-k="disabled">disabled</:item>
            </.toggle_group>
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

      <div
        :for={
          ex <-
            examples_for(
              PetalComponents.Showcase.Field,
              ~w(anatomy error_state in_field_actions every_type)a
            )
        }
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Field} function={:field} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Field</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift. Select, checkbox, radio and switch are the same field surface;
        their pages render the rest of the registry.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "border-plasma"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Border plasma</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Whispery lines of light warp along the rim, whole corners swell and
        dissipate on their own clocks, and a soft halo spills past the border
        onto the page - or set clip and nothing leaves the silhouette. Rotate
        sweeps a neutral light around the rim that wakes the colours as it
        passes. Pure CSS; rainbow by default, or on-brand via palette="brand".
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center px-6 py-14">
          <.border_plasma
            id={"pg-plasma-#{@plasma.mode}-#{@plasma.intensity}-#{@plasma.duration}-#{@plasma.glow}-#{@plasma.palette}"}
            mode={@plasma.mode}
            intensity={@plasma.intensity}
            duration={@plasma.duration}
            glow={@plasma.glow}
            palette={@plasma.palette}
            class="w-full max-w-sm"
          >
            <div class="p-8">
              <div class="text-xs font-medium tracking-wide uppercase text-gray-400">New in 4.14</div>
              <div class="mt-2 text-lg font-semibold text-gray-900 dark:text-gray-100">
                Border plasma
              </div>
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                Light pools on the border and leaks into the panel, instead of one dot running around it.
              </p>
            </div>
          </.border_plasma>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">mode</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Mode"
              value={@plasma.mode}
              on_change="ctl_plasma"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={m <- ~w(pulse rotate)} value={m} phx-value-k="mode" phx-value-v={m}>
                {m}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">intensity</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Intensity"
              value={@plasma.intensity}
              on_change="ctl_plasma"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={i <- ~w(subtle medium strong)}
                value={i}
                phx-value-k="intensity"
                phx-value-v={i}
              >
                {i}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">duration</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Duration"
              value={@plasma.duration}
              on_change="ctl_plasma"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={d <- ~w(2.3s 4s 6s)} value={d} phx-value-k="duration" phx-value-v={d}>
                {d}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">glow</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Glow"
              value={@plasma.glow}
              on_change="ctl_plasma"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={g <- ~w(outside inside both)} value={g} phx-value-k="glow" phx-value-v={g}>
                {g}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">palette</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Palette"
              value={@plasma.palette}
              on_change="ctl_plasma"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={p <- ~w(rainbow brand mono ocean sunset)}
                value={p}
                phx-value-k="palette"
                phx-value-v={p}
              >
                {p}
              </:item>
            </.toggle_group>
          </div>
        </div>
        <p class="px-6 pb-3 -mt-1 text-xs text-gray-400 dark:text-gray-500">
          both modes hold still for reduced-motion users - the ring stays lit, it just stops moving
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
      ><code>{plasma_snippet(@plasma)}</code></pre>

      <div class="mt-12 mb-3 text-xs font-medium tracking-wide text-gray-400 dark:text-gray-500">
        Three glows, three jobs
      </div>
      <div class="grid gap-6 px-6 py-14 border border-gray-200 sm:grid-cols-2 rounded-xl dark:border-gray-800">
        <div class="sm:col-span-2">
          <div class="mb-3 text-xs text-gray-400 dark:text-gray-500">
            glow="outside" - a prompt panel with the halo on the page
          </div>
          <.border_plasma class="max-w-xl mx-auto">
            <div class="p-5">
              <.icon name="hero-at-symbol" class="w-4 h-4 text-gray-400 dark:text-gray-500" />
              <p class="mt-3 text-gray-400 dark:text-gray-500">Build anything...</p>
              <div class="flex items-center gap-2 mt-4">
                <span class="px-3 py-1 text-sm rounded-full text-gray-600 bg-gray-100 dark:text-gray-300 dark:bg-gray-800">
                  Agent
                </span>
                <span class="px-3 py-1 text-sm rounded-full text-gray-600 bg-gray-100 dark:text-gray-300 dark:bg-gray-800">
                  Auto
                </span>
              </div>
            </div>
          </.border_plasma>
        </div>
        <div>
          <div class="mb-3 text-xs text-gray-400 dark:text-gray-500">
            glow="inside" - a working card, silhouette crisp
          </div>
          <.border_plasma glow="inside">
            <div class="p-5">
              <.shimmer_text class="text-gray-400 dark:text-gray-500">Working...</.shimmer_text>
              <ul class="mt-3 space-y-2 text-sm text-gray-600 dark:text-gray-300">
                <li
                  :for={
                    t <- [
                      "Generate colour palettes",
                      "Recommend font pairings",
                      "Create layout templates"
                    ]
                  }
                  class="flex items-center gap-2"
                >
                  <span class="inline-block w-3.5 h-3.5 border border-dashed rounded-full border-gray-400"></span>
                  {t}
                </li>
              </ul>
            </div>
          </.border_plasma>
        </div>
        <div class="flex items-center justify-center">
          <div>
            <div class="mb-3 text-xs text-center text-gray-400 dark:text-gray-500">
              glow="both" on a pill CTA
            </div>
            <.border_plasma glow="both" border_radius="9999px" intensity="strong" class="inline-block">
              <div class="px-7 py-2.5 font-medium text-center text-gray-900 dark:text-white">
                Subscribe
              </div>
            </.border_plasma>
          </div>
        </div>
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.BorderPlasma} function={:border_plasma} />
    </div>
    """
  end

  defp render_page(%{active: "border-beam"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">duration</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Duration"
              value={@beam.duration}
              on_change="ctl_beam"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={d <- ~w(4s 8s 12s)} value={d} phx-value-k="duration" phx-value-v={d}>
                {d}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">beams</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Beams"
              value={@beam.beams}
              on_change="ctl_beam"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={n <- ~w(1 2 3)} value={n} phx-value-k="beams" phx-value-v={n}>{n}</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">length</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Length"
              value={@beam.size}
              on_change="ctl_beam"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={{lbl, v} <- [{"sm", "40px"}, {"md", "60px"}, {"lg", "160px"}]}
                value={v}
                phx-value-k="size"
                phx-value-v={v}
              >
                {lbl}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">motion</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Easing"
              value={@beam.easing}
              on_change="ctl_beam"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={e <- ~w(linear spring)} value={e} phx-value-k="easing" phx-value-v={e}>
                {e}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="Extras"
              value={for {k, on} <- [{"glow", @beam.glow}, {"reverse", @beam.reverse}], on, do: k}
              on_change="ctl_beam"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="glow" phx-value-k="glow">glow</:item>
              <:item value="reverse" phx-value-k="reverse">reverse</:item>
            </.toggle_group>
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

      <div :for={ex <- PetalComponents.Showcase.BorderBeam.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.BorderBeam} function={:border_beam} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.BorderBeam</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "shine-border"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">colour</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Scheme"
              value={@shine.scheme}
              on_change="ctl_shine"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={c <- ~w(mono blend)} value={c} phx-value-k="scheme" phx-value-v={c}>
                {c}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">sweep</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Sweep"
              value={@shine.duration}
              on_change="ctl_shine"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={{lbl, v} <- [{"fast", "6s"}, {"med", "14s"}, {"slow", "24s"}]}
                value={v}
                phx-value-k="duration"
                phx-value-v={v}
              >
                {lbl}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">width</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Width"
              value={@shine.width}
              on_change="ctl_shine"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={w <- ~w(1px 2px 3px)} value={w} phx-value-k="width" phx-value-v={w}>
                {w}
              </:item>
            </.toggle_group>
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

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.ShineBorder, ~w(input)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.ShineBorder} function={:shine_border} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.ShineBorder</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "chart"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Type"
              value={@chart.type}
              on_change="ctl_chart"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={t <- ~w(line bar)} value={t} phx-value-k="type" phx-value-v={t}>{t}</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">series</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Series"
              value={(@chart.two_series && "two") || "one"}
              on_change="ctl_chart"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="one" phx-value-k="two_series" phx-value-v="one">one</:item>
              <:item value="two" phx-value-k="two_series" phx-value-v="two">two</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">days</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Points"
              value={@chart.points}
              on_change="ctl_chart"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={p <- ~w(7 14 30)} value={p} phx-value-k="points" phx-value-v={p}>
                {p}
              </:item>
            </.toggle_group>
          </div>
          <div :if={@chart.type == "bar"}>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">gap</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Gap"
              value={@chart.gap}
              on_change="ctl_chart"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={g <- ~w(cozy tight)} value={g} phx-value-k="gap" phx-value-v={g}>
                {g}
              </:item>
            </.toggle_group>
          </div>
          <div :if={@chart.type == "line"}>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">area</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Area"
              value={@chart.area}
              on_change="ctl_chart"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={a <- ~w(fade solid none)} value={a} phx-value-k="area" phx-value-v={a}>
                {a}
              </:item>
            </.toggle_group>
          </div>
          <div :if={@chart.type == "line"}>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">shape</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Shape"
              value={@chart.shape}
              on_change="ctl_chart"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={s <- ~w(smooth linear step)} value={s} phx-value-k="shape" phx-value-v={s}>
                {s}
              </:item>
            </.toggle_group>
          </div>
          <div :if={@chart.type == "line"}>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">dots</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Dots"
              value={(@chart.dots && "on") || "off"}
              on_change="ctl_chart"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="on" phx-value-k="dots" phx-value-v="on">on</:item>
              <:item value="off" phx-value-k="dots" phx-value-v="off">off</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">chrome</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Chrome"
              value={@chart.chrome}
              on_change="ctl_chart"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={c <- ~w(full x off)} value={c} phx-value-k="chrome" phx-value-v={c}>
                {c}
              </:item>
            </.toggle_group>
          </div>
        </div>
      </div>
      <pre class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"><code>{chart_snippet()}</code></pre>

      <div :for={ex <- PetalComponents.Showcase.Chart.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <div :for={ex <- PetalComponents.Showcase.Sparkline.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Chart} function={:chart} />
      <div class="mt-6">
        <.showcase_props component={PetalComponents.Sparkline} function={:sparkline} />
      </div>

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Chart</code>
        and <code>Sparkline</code>
        registries - the same source petal.build renders, so the
        playground and the marketing docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "color-scheme"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Color scheme</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Light, dark and system switching in three faces, sharing one no-flash
        scheme contract. System follows the OS live, explicit choices persist,
        and every open tab stays in sync.
      </p>

      <div class="mt-8 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Toggle - instant light/dark for tight navbars
      </div>
      <div class="flex items-center justify-center px-6 py-10 border border-gray-200 rounded-xl dark:border-gray-800">
        <.color_scheme_switch id="pg-scheme-toggle" variant="toggle" />
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Dropdown - compact, with a system option
      </div>
      <div class="flex items-center justify-center gap-10 px-6 py-10 border border-gray-200 rounded-xl dark:border-gray-800">
        <.color_scheme_switch id="pg-scheme-dropdown" variant="dropdown" />
        <.color_scheme_switch id="pg-scheme-dropdown-labeled" variant="dropdown" labels />
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Segmented - all three states visible
      </div>
      <div class="flex items-center justify-center px-6 py-10 border border-gray-200 rounded-xl dark:border-gray-800">
        <.color_scheme_switch id="pg-scheme-segmented" variant="segmented" />
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Bring your own icons - slots replace the Heroicons defaults
      </div>
      <div class="flex flex-col items-center justify-center gap-6 px-6 py-10 border border-gray-200 rounded-xl dark:border-gray-800">
        <.color_scheme_switch id="pg-scheme-custom" variant="toggle">
          <:light_icon>
            <svg viewBox="4.25 4.25 19.5 19.5" fill="none" xmlns="http://www.w3.org/2000/svg">
              <circle cx="14" cy="14" r="4.5" stroke="currentColor" stroke-linejoin="round" />
              <path
                d="M14 5.5v2M14 20.5v2M22.5 14h-2M7.5 14h-2M20.01 7.99l-1.42 1.42M9.41 18.59l-1.42 1.42M20.01 20.01l-1.42-1.42M9.41 9.41 7.99 7.99"
                stroke="currentColor"
                stroke-linecap="round"
              />
            </svg>
          </:light_icon>
          <:dark_icon>
            <svg viewBox="5.25 4.25 18.5 18.5" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path
                d="M10.5 9.99914C10.5 14.1413 13.8579 17.4991 18 17.4991C19.0332 17.4991 20.0176 17.2902 20.9132 16.9123C19.7761 19.6075 17.109 21.4991 14 21.4991C9.85786 21.4991 6.5 18.1413 6.5 13.9991C6.5 10.8902 8.39167 8.22304 11.0868 7.08594C10.7089 7.98159 10.5 8.96597 10.5 9.99914Z"
                stroke="currentColor"
                stroke-linejoin="round"
              />
              <path
                d="M16.3561 6.50754L16.5 5.5L16.6439 6.50754C16.7068 6.94752 17.0525 7.29321 17.4925 7.35607L18.5 7.5L17.4925 7.64393C17.0525 7.70679 16.7068 8.05248 16.6439 8.49246L16.5 9.5L16.3561 8.49246C16.2932 8.05248 15.9475 7.70679 15.5075 7.64393L14.5 7.5L15.5075 7.35607C15.9475 7.29321 16.2932 6.94752 16.3561 6.50754Z"
                fill="currentColor"
                stroke="currentColor"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
              <path
                d="M20.3561 11.5075L20.5 10.5L20.6439 11.5075C20.7068 11.9475 21.0525 12.2932 21.4925 12.3561L22.5 12.5L21.4925 12.6439C21.0525 12.7068 20.7068 13.0525 20.6439 13.4925L20.5 14.5L20.3561 13.4925C20.2932 13.0525 19.9475 12.7068 19.5075 12.6439L18.5 12.5L19.5075 12.3561C19.9475 12.2932 20.2932 11.9475 20.3561 11.5075Z"
                fill="currentColor"
                stroke="currentColor"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>
          </:dark_icon>
        </.color_scheme_switch>
        <p class="text-xs text-center text-gray-400 dark:text-gray-500">
          Tip: many icon sets pad their artwork. Crop the viewBox around the
          glyph so a dropped-in icon matches Heroicons' optical density.
        </p>
      </div>

      <div class="p-4 mt-8 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Every switch on this page and the toggle in the topbar drive the same <code>document</code>
        class through one contract: <code>&lt;.color_scheme_script /&gt;</code>
        rendered once in the layout head. Change any of them and the rest
        follow - including other open tabs.
      </div>

      <div :for={ex <- PetalComponents.Showcase.ColorSchemeSwitch.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.ColorSchemeSwitch} function={:color_scheme_switch} />
    </div>
    """
  end

  defp render_page(%{active: "carousel"} = assigns) do
    assigns =
      assign(assigns,
        forest: "/dev-static/carousel/forest.jpg",
        ocean: "/dev-static/carousel/sneaker.jpg",
        code: "/dev-static/carousel/code.jpg",
        car_id:
          "pg-car-flag-#{assigns.car.transition}-#{assigns.car.buttons}-#{assigns.car.indicators}-#{assigns.car.ind_pos}-#{assigns.car.orientation}-#{assigns.car.loop}-#{assigns.car.autoplay}-#{assigns.car.thumbnails}"
      )

    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Carousel</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Fade or scroll-snap slide transitions, swipe and drag, keyboard
        navigation, autoplay, indicators, synced thumbnails, and clickable
        slides - zero JavaScript dependencies, one hook.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="p-4">
          <.carousel
            id={@car_id}
            transition_type={@car.transition}
            button_style={@car.buttons}
            indicator={@car.indicators != "off"}
            indicator_style={(@car.indicators == "off" && "bars") || @car.indicators}
            indicator_position={@car.ind_pos}
            orientation={@car.orientation}
            loop={@car.loop}
            autoplay={@car.autoplay}
            autoplay_interval={3500}
            thumbnails={@car.thumbnails}
          >
            <:slide
              image={@forest}
              title="Every mode, one component"
              description="Flip the dials below - the carousel remounts with the new configuration."
            />
            <:slide
              image={@ocean}
              title="Drag me on slide mode"
              description="Scroll-snap gives native momentum; fade crossfades in place."
            />
            <:slide
              image={@code}
              title="Keyboard works too"
              description="Focus the carousel and use the arrow keys."
            />
          </.carousel>
        </div>
        <div class="flex flex-wrap gap-x-8 gap-y-5 px-6 py-5 border-t border-gray-100 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">transition</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Transition"
              value={@car.transition}
              on_change="ctl_carousel"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={t <- ~w(fade slide)} value={t} phx-value-k="transition" phx-value-v={t}>
                {t}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">buttons</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Buttons"
              value={@car.buttons}
              on_change="ctl_carousel"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={b <- ~w(overlay below outside none)}
                value={b}
                phx-value-k="buttons"
                phx-value-v={b}
              >
                {b}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">indicators</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Indicators"
              value={@car.indicators}
              on_change="ctl_carousel"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={i <- ~w(bars dots off)} value={i} phx-value-k="indicators" phx-value-v={i}>
                {i}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">placement</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Ind pos"
              value={@car.ind_pos}
              on_change="ctl_carousel"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={ip <- ~w(overlay below)} value={ip} phx-value-k="ind_pos" phx-value-v={ip}>
                {ip}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">orientation</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Orientation"
              value={@car.orientation}
              on_change="ctl_carousel"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={o <- ~w(horizontal vertical)}
                value={o}
                phx-value-k="orientation"
                phx-value-v={o}
              >
                {o}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="Extras"
              value={
                for {k, on} <- [
                      {"loop", @car.loop},
                      {"autoplay", @car.autoplay},
                      {"thumbnails", @car.thumbnails}
                    ],
                    on,
                    do: k
              }
              on_change="ctl_carousel"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="loop" phx-value-k="loop">loop</:item>
              <:item value="autoplay" phx-value-k="autoplay">autoplay</:item>
              <:item value="thumbnails" phx-value-k="thumbnails">thumbnails</:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Product view - aspect="square" in a narrow wrapper, dots below, matched thumbnails
      </div>
      <div class="flex justify-center px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="w-full max-w-sm">
          <.carousel
            id="pg-car-product"
            transition_type="slide"
            aspect="square"
            thumbnails
            indicator
            indicator_style="dots"
            indicator_position="below"
            button_style="none"
          >
            <:slide image={@forest} />
            <:slide image={@ocean} />
            <:slide image={@code} />
          </.carousel>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Multi-slide gallery - three per view with edge gradients
      </div>
      <.carousel
        id="pg-car-multi"
        transition_type="slide"
        slides_per_view={3}
        gap="0.75rem"
        overlay_gradient
        button_style="outside"
      >
        <:slide image={@forest} title="One" />
        <:slide image={@ocean} title="Two" />
        <:slide image={@code} title="Three" />
        <:slide image={@forest} title="Four" />
        <:slide image={@ocean} title="Five" />
        <:slide image={@code} title="Six" />
      </.carousel>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Clickable slides - the whole slide is the link
      </div>
      <.carousel id="pg-car-links" transition_type="fade">
        <:slide
          image={@forest}
          title="External link"
          description="Opens in a new tab - note the corner indicator."
          href="https://petal.build"
        />
        <:slide
          image={@ocean}
          title="Internal navigate"
          description="navigate keeps it in-app."
          navigate="/?c=avatar"
        />
      </.carousel>

      <div :for={ex <- PetalComponents.Showcase.Carousel.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Carousel} function={:carousel} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Slide corners ride the radius dial up top (the carousel is a surface;
        <code>rounded="none"</code>
        opts out, or pin a size). Every slide change dispatches <code>petal:carousel-change</code>
        with the id, index and count. Ported from the battle-tested
        petal_marketing carousel - the interaction logic is unchanged.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "toast"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Toast</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A collapsed stack that expands on hover, timeout progress that pauses
        while you read, swipe to dismiss, six positions - and the
        LiveView-native parts: server-pushed toasts, id-addressed updates,
        action buttons that push events, and a put_flash bridge.
      </p>

      <div class="mt-8 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Kinds - hover the stack to expand and pause (press and hold on touch), swipe or drag sideways to dismiss
      </div>
      <div class="px-6 py-6 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-wrap gap-2">
          <.button
            :for={kind <- ~w(info success warning danger neutral)}
            size="sm"
            variant="outline"
            color="gray"
            phx-click="toast_demo"
            phx-value-kind={kind}
          >
            {kind}
          </.button>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        LiveView-native - things a JS toast library can't do
      </div>
      <div class="px-6 py-6 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-wrap gap-2">
          <.button size="sm" phx-click="toast_demo" phx-value-demo="morph">
            Loading -> success morph
          </.button>
          <.button size="sm" variant="soft" phx-click="toast_demo" phx-value-demo="action">
            Action button (Undo)
          </.button>
          <.button size="sm" variant="soft" phx-click="toast_demo" phx-value-demo="flash">
            put_flash bridge
          </.button>
        </div>
        <p class="mt-4 text-xs text-gray-400 dark:text-gray-500">
          The morph pushes a sticky loading toast, then 2.5s later updates the
          same id into a success with an action. Undo pushes a real event back
          to this LiveView. put_flash renders as a toast and clears itself.
        </p>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Stack, queue and stickiness
      </div>
      <div class="px-6 py-6 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-wrap gap-2">
          <.button
            size="sm"
            variant="outline"
            color="gray"
            phx-click="toast_demo"
            phx-value-demo="burst"
          >
            Burst of 6
          </.button>
          <.button
            size="sm"
            variant="outline"
            color="gray"
            phx-click="toast_demo"
            phx-value-demo="sticky"
          >
            Sticky (no timeout)
          </.button>
          <.button
            size="sm"
            variant="outline"
            color="gray"
            phx-click="toast_demo"
            phx-value-demo="dismiss_all"
          >
            Dismiss all
          </.button>
        </div>
        <p class="mt-4 text-xs text-gray-400 dark:text-gray-500">
          Three stay visible in the collapsed stack; the rest wait behind and
          surface as older toasts leave.
        </p>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Position - moves the live group
      </div>
      <div class="px-6 py-5 border border-gray-200 rounded-xl dark:border-gray-800">
        <.toggle_group
          variant="outline"
          size="sm"
          aria_label="Pos"
          value={@toast.pos}
          on_change="ctl_toast"
          class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
        >
          <:item
            :for={pos <- ~w(top-left top-center top-right bottom-left bottom-center bottom-right)}
            value={pos}
            phx-value-k="pos"
            phx-value-v={pos}
          >
            {pos}
          </:item>
        </.toggle_group>
      </div>

      <div :for={ex <- PetalComponents.Showcase.Toast.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Toast} function={:toast_group} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        One <code>&lt;.toast_group flash=&lbrace;@flash&rbrace; /&gt;</code>
        in the root layout. Push from the server with
        <code>Toast.send_toast(socket, :success, title: "Saved")</code>
        or from plain JavaScript via a <code>petal:toast</code>
        CustomEvent. Danger toasts announce as <code>role="alert"</code>; the rest as polite status.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "local-time"} = assigns) do
    now = DateTime.utc_now()

    assigns =
      assign(assigns,
        lt_feed: [
          {"Amelia Ward", "pushed to main", DateTime.add(now, -20),
           "/dev-static/avatars/p32.jpg"},
          {"Deploy Bot", "released v4.8.0", DateTime.add(now, -8 * 60), nil},
          {"Jonah Reyes", "commented on PR #58", DateTime.add(now, -3 * 3600),
           "/dev-static/avatars/p65.jpg"},
          {"Priya Anand", "signed in", DateTime.add(now, -30 * 3600),
           "/dev-static/avatars/p44.jpg"},
          {"Billing", "sent invoice #204", DateTime.add(now, -6 * 86_400), nil},
          {"Maya Okafor", "created the workspace", DateTime.add(now, -45 * 86_400),
           "/dev-static/avatars/p12.jpg"},
          {"Status Page", "scheduled maintenance", DateTime.add(now, 45 * 60), nil}
        ],
        lt_two_hours: DateTime.add(now, -2 * 3600),
        lt_fixed: ~U[2026-07-21 08:30:00Z]
      )

    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Local time</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Timestamps in the visitor's own timezone, language and calendar. The
        server sends the UTC instant in a semantic <code>&lt;time&gt;</code>;
        the browser's <code>Intl</code> does the rest - no timezone tables,
        no date library.
      </p>

      <div class="mt-8 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Relative, in context - an activity feed that ticks live
      </div>
      <div class="px-6 py-4 border border-gray-200 rounded-xl dark:border-gray-800">
        <div
          :for={{{who, what, at, photo}, i} <- Enum.with_index(@lt_feed)}
          class="flex items-center gap-3 py-2.5 border-b border-gray-100 last:border-0 dark:border-gray-800/60"
        >
          <.avatar size="xs" src={photo} name={who} random_gradient />
          <span class="flex-1 text-sm truncate">
            <span class="font-medium">{who}</span>
            <span class="text-gray-500 dark:text-gray-400">{what}</span>
          </span>
          <.local_time
            id={"lt-feed-#{i}"}
            at={at}
            format="relative"
            class="text-xs text-gray-400 shrink-0 dark:text-gray-500"
          />
        </div>
        <p class="mt-4 text-xs text-gray-400 dark:text-gray-500">
          Events are seeded relative to when this page loaded, then the
          timestamps live their own lives - leave the page open and watch the
          top rows age. Hover any of them for the full date. Maya's row is older
          than the 7-day threshold, so it renders the date instead;
          the maintenance window is in the future ("in 45 minutes").
        </p>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Tighter threshold - flip to absolute sooner
      </div>
      <div class="px-6 py-5 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-between">
          <span class="flex-1 text-sm truncate">
            <span class="font-medium">Data export</span>
            <span class="text-gray-500 dark:text-gray-400">
              finished two hours before page load
            </span>
          </span>
          <.local_time
            id="lt-rel-threshold"
            at={@lt_two_hours}
            format="relative"
            threshold={3600}
            class="text-xs text-gray-400 shrink-0 dark:text-gray-500"
          />
        </div>
        <p class="mt-4 text-xs text-gray-400 dark:text-gray-500">
          Same relative format, but <code>threshold=&lbrace;3600&rbrace;</code>
          flips anything older than an hour to the absolute form - so a
          two-hour-old event shows its date and time, not "2 hours ago".
        </p>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Absolute - presets and raw Intl options
      </div>
      <div class="px-6 py-5 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-between py-2 border-b border-gray-100 dark:border-gray-800/60">
          <span class="font-mono text-xs text-gray-400">default</span>
          <.local_time id="lt-abs-default" at={@lt_fixed} class="text-sm" />
        </div>
        <div class="flex items-center justify-between py-2 border-b border-gray-100 dark:border-gray-800/60">
          <span class="font-mono text-xs text-gray-400">format="date"</span>
          <.local_time id="lt-abs-date" at={@lt_fixed} format="date" class="text-sm" />
        </div>
        <div class="flex items-center justify-between py-2 border-b border-gray-100 dark:border-gray-800/60">
          <span class="font-mono text-xs text-gray-400">format="time"</span>
          <.local_time id="lt-abs-time" at={@lt_fixed} format="time" class="text-sm" />
        </div>
        <div class="flex items-center justify-between py-2">
          <span class="font-mono text-xs text-gray-400">Intl options map</span>
          <.local_time
            id="lt-abs-custom"
            at={@lt_fixed}
            format={
              %{weekday: "long", day: "numeric", month: "long", hour: "2-digit", minute: "2-digit"}
            }
            class="text-sm"
          />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Pinned locale and timezone - the same instant, three colleagues
      </div>
      <div class="px-6 py-5 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-between py-2 border-b border-gray-100 dark:border-gray-800/60">
          <span class="font-mono text-xs text-gray-400">your browser</span>
          <.local_time id="lt-zone-browser" at={@lt_fixed} class="text-sm" />
        </div>
        <div class="flex items-center justify-between py-2 border-b border-gray-100 dark:border-gray-800/60">
          <span class="font-mono text-xs text-gray-400">de-DE / Europe/Berlin</span>
          <.local_time
            id="lt-zone-berlin"
            at={@lt_fixed}
            locale="de-DE"
            timezone="Europe/Berlin"
            class="text-sm"
          />
        </div>
        <div class="flex items-center justify-between py-2">
          <span class="font-mono text-xs text-gray-400">en-AU / Australia/Sydney</span>
          <.local_time
            id="lt-zone-sydney"
            at={@lt_fixed}
            locale="en-AU"
            timezone="Australia/Sydney"
            class="text-sm"
          />
        </div>
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.LocalTime} function={:local_time} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Before the hook runs - and anywhere JavaScript never runs - the element
        shows the UTC ISO string: honest, sortable, machine-readable. Relative
        timestamps re-render the moment a background tab wakes, so a page left
        open overnight never greets you with "2 minutes ago".
      </div>
    </div>
    """
  end

  defp render_page(%{active: "meteors"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">count</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Count"
              value={@meteors.count}
              on_change="ctl_meteors"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={n <- ~w(10 20 40)} value={n} phx-value-k="count" phx-value-v={n}>
                {n}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">angle</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Angle"
              value={@meteors.angle}
              on_change="ctl_meteors"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={{lbl, v} <- [{"shallow", "200deg"}, {"default", "215deg"}, {"steep", "235deg"}]}
                value={v}
                phx-value-k="angle"
                phx-value-v={v}
              >
                {lbl}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">colour</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Color"
              value={@meteors.color}
              on_change="ctl_meteors"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={c <- ~w(slate sky violet)} value={c} phx-value-k="color" phx-value-v={c}>
                {c}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="Extras"
              value={for {k, on} <- [{"reverse", @meteors.reverse}], on, do: k}
              on_change="ctl_meteors"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="reverse" phx-value-k="reverse">reverse</:item>
              <:item value="shuffle" phx-value-k="shuffle">shuffle</:item>
            </.toggle_group>
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

      <div :for={ex <- PetalComponents.Showcase.Meteors.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Meteors} function={:meteors} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Meteors</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "typography"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Colours</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Four roles: primary is your base action colour (monochrome by
        default), secondary is your brand accent, semantics carry meaning,
        gray is the chrome. One rule everywhere: colour picks the ramp,
        variant picks the treatment - both dials up top restyle every
        component live.
      </p>

      <div class="mt-8 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Primary (first dial - {if @primary == "neutral",
          do: "monochrome, tinted by your gray dial",
          else: @primary})
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
        Gray ({@gray} - the chrome family)
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
        map each to any hue below, or keep primary monochrome for the
        shadcn look. The monochrome ramp derives from your gray dial, so
        a slate chrome gives a slate-tinted accent. The surface tokens -
        washes at 500/15, borders at 600/30 light and 500/40 dark, solids
        at 600 - are derived from the ramps, which is why one dial swap
        restyles every component.
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
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Dropdown</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Menus on the floating-panel surface: group labels, separators, icons,
        keyboard hints and destructive items. Triggers follow the rail radius.
      </p>

      <div :for={ex <- PetalComponents.Showcase.Dropdown.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props
        component={PetalComponents.Dropdown}
        functions={[
          :dropdown,
          :dropdown_menu_item,
          :dropdown_menu_label,
          :dropdown_menu_row,
          :dropdown_menu_separator
        ]}
      />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Dropdown</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "social-button"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Social button</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        "Continue with Google" and its siblings, graduated from Petal Pro -
        the very first Pro component, now free. Rides pc-button geometry,
        so the radius dial and the theme drive it like any other button.
      </p>

      <div :for={ex <- PetalComponents.Showcase.SocialButton.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.SocialButton} function={:social_button} />

      <h2 class="mt-10 mb-2 text-lg font-semibold">brand_icon</h2>
      <.showcase_props component={PetalComponents.BrandIcon} function={:brand_icon} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.SocialButton</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "language-select"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Language select</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        The locale flag dropdown, graduated from Petal Pro. Items are plain
        links carrying <code>?locale=</code> - the conventional Phoenix
        contract - so it works on live and dead views alike.
      </p>

      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center px-4 py-12">
          <.language_select
            current_locale={@lang}
            current_path={"/?c=language-select&radius=#{@radius}"}
            language_options={@playground_languages}
            placement={@lang_placement}
            variant={@lang_variant}
          />
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 pt-5 pb-6 border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">trigger</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Trigger"
              value={@lang_variant}
              on_change="pg_lang_variant"
            >
              <:item :for={v <- ~w(flag code label)} value={v} phx-value-v={v}>{v}</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">placement</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Placement"
              value={@lang_placement}
              on_change="pg_lang_placement"
            >
              <:item :for={p <- ~w(left right)} value={p} phx-value-v={p}>{p}</:item>
            </.toggle_group>
          </div>
          <p class="max-w-xs text-[11px] leading-relaxed text-gray-400">
            picking a language reloads with <code>?locale=</code> and this page
            reads it back - the real contract, not a simulation
          </p>
        </div>
      </div>

      <div :for={ex <- PetalComponents.Showcase.LanguageSelect.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.LanguageSelect} function={:language_select} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.LanguageSelect</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "modal"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Modal</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Dialog on the panel surface with a proper scrim. Escape and
        click-away close it; the box radius scales gently with the rail.
      </p>

      <div :for={ex <- PetalComponents.Showcase.Modal.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Modal} function={:modal} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Modal</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "progress"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Progress</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Determinate progress on a washed track, bar or ring. The flagship
        simulates a live upload - or take the wheel with the value control
        (which pauses the simulation). Flip shape and the same dials drive
        the circular version, where the readout either sits in the hole (lg
        and up, where there's room to read a number) or beside the ring.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center px-6 py-16">
          <%!-- The label dial drives the ring's readout rather than guessing at
                it: "inside" is show_value in the hole (offered from lg up, where
                it draws), "beside" is the composed row the component's docs point
                at, and it stays available at every size. --%>
          <div :if={@progress.shape == "ring"} class="flex items-center gap-2">
            <.progress_ring
              value={@progress.value}
              color={@progress.color}
              size={@progress.size}
              show_value={@progress.label == "inside"}
              label="Download progress"
            />
            <span
              :if={@progress.label == "top"}
              class="text-sm text-gray-500 tabular-nums dark:text-gray-400"
            >
              {@progress.value}%
            </span>
          </div>
          <div :if={@progress.shape == "bar"} class="w-full max-w-md">
            <.progress
              value={@progress.value}
              color={@progress.color}
              size={@progress.size}
              label={
                case @progress.label do
                  "inside" -> "#{@progress.value}%"
                  "top" -> "Download progress"
                  _ -> nil
                end
              }
              label_position={if @progress.label == "top", do: "top", else: "inside"}
              status={if @progress.status, do: progress_status(@progress.value)}
            />
          </div>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">shape</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Shape"
              value={@progress.shape}
              on_change="ctl_progress"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={s <- ~w(bar ring)} value={s} phx-value-k="shape" phx-value-v={s}>
                {s}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">state</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="State"
              value={
                for {k, on} <- [{"live", @progress.live}, {"status", @progress.status}], on, do: k
              }
              on_change="ctl_progress"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="live" phx-value-k="live">live</:item>
              <:item value="status" phx-value-k="status">status</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">value</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Value"
              value={@progress.value}
              on_change="ctl_progress"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={v <- ~w(15 40 60 85 100)} value={v} phx-value-k="value" phx-value-v={v}>
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">colour</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Color"
              value={@progress.color}
              on_change="ctl_progress"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={c <- ~w(primary secondary info success warning danger gray)}
                value={c}
                phx-value-k="color"
                phx-value-v={c}
              >
                {c}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Size"
              value={@progress.size}
              on_change="ctl_progress"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={z <- ~w(xs sm md lg xl)} value={z} phx-value-k="size" phx-value-v={z}>
                {z}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">label</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Label"
              aria-describedby={
                progress_inside_disabled?(@progress.shape, @progress.size) &&
                  "pg-progress-inside-hint"
              }
              value={@progress.label}
              on_change="ctl_progress"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={l <- ~w(none inside top)}
                value={l}
                disabled={
                  l == "inside" and progress_inside_disabled?(@progress.shape, @progress.size)
                }
                phx-value-k="label"
                phx-value-v={l}
              >
                {progress_label_name(@progress.shape, l)}
              </:item>
            </.toggle_group>
            <%!-- aria-describedby on the group ties the hint to the radios, so
            assistive tech hears WHY inside is disabled, not just that it is. --%>
            <div
              :if={progress_inside_disabled?(@progress.shape, @progress.size)}
              id="pg-progress-inside-hint"
              class="mt-1.5 text-[10px] text-gray-400"
            >
              inside needs lg or xl
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

      <div :for={ex <- PetalComponents.Showcase.Progress.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Progress} functions={[:progress, :progress_ring]} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Progress</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "rating"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Icon"
              value={@rating.icon}
              on_change="ctl_rating"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={i <- ~w(star heart face)} value={i} phx-value-k="icon" phx-value-v={i}>
                {i}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Size"
              value={@rating.size}
              on_change="ctl_rating"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={sz <- ~w(sm md lg)} value={sz} phx-value-k="size" phx-value-v={sz}>
                {sz}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">step</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Step"
              value={@rating.step}
              on_change="ctl_rating"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="whole" phx-value-k="step" phx-value-v="whole">1</:item>
              <:item
                value="half"
                disabled={@rating.icon == "face"}
                phx-value-k="step"
                phx-value-v="half"
              >
                ½
              </:item>
            </.toggle_group>
            <p :if={@rating.icon == "face"} class="mt-1.5 text-[11px] text-gray-400">
              faces are an ordinal scale - always whole
            </p>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">label</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Label"
              value={@rating.label}
              on_change="ctl_rating"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={l <- ~w(none right bottom)} value={l} phx-value-k="label" phx-value-v={l}>
                {l}
              </:item>
            </.toggle_group>
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

      <div
        :for={
          ex <- examples_for(PetalComponents.Showcase.Rating, ~w(sentiment display custom_glyph)a)
        }
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Rating} function={:rating} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Rating</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "slide-over"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Origin"
              value={@slideover.origin}
              on_change="ctl_slideover"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={o <- ~w(left right top bottom)}
                value={o}
                phx-value-k="origin"
                phx-value-v={o}
              >
                {o}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">
              max width (left/right)
            </div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Width"
              value={@slideover.width}
              on_change="ctl_slideover"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={w <- ~w(sm md lg)} value={w} phx-value-k="width" phx-value-v={w}>
                {w}
              </:item>
            </.toggle_group>
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

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.SlideOver, ~w(cart)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.SlideOver} function={:slide_over} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.SlideOver</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "skeleton"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Animation"
              value={@skeleton.animation}
              on_change="ctl_skeleton"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={a <- ~w(pulse shimmer none)}
                value={a}
                phx-value-k="animation"
                phx-value-v={a}
              >
                {a}
              </:item>
            </.toggle_group>
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

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.Skeleton, ~w(shapes)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props
        component={PetalComponents.Skeleton}
        functions={[:skeleton, :skeleton_group, :skeleton_text]}
      />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Skeleton</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift. (The old kind={:card}-style prebuilt layouts still render for
        compatibility.)
      </div>
    </div>
    """
  end

  defp render_page(%{active: "button-group"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Button group</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Fuses buttons, inputs and text segments into one control - split buttons,
        toolbars, mixed rails.
      </p>
      <div :for={ex <- PetalComponents.Showcase.ButtonGroup.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props
        component={PetalComponents.ButtonGroup}
        functions={[:button_group, :button_group_separator, :button_group_text]}
      />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.ButtonGroup</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift. (The :button slot API from earlier releases still renders
        unchanged.)
      </div>
    </div>
    """
  end

  defp render_page(%{active: "toggle-group"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Toggle group</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A segmented selection rail - one pressed option, or several with multiple.
        Server-driven and stateless: pass value, handle on_change, no hook.
      </p>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Try it</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        Single select on the left, multiple on the right, both live against this page's
        LiveView state. The dials below are toggle groups themselves, so this section
        configures itself - and the radius dial up top drives every chip, step for step, on the same curve as buttons. Only full pills.
      </p>
      <div class="border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-wrap items-center justify-center gap-6 px-4 py-12">
          <.toggle_group
            variant={@tg_variant}
            size={@tg_size}
            aria_label="Density"
            value={@tg_density}
            on_change="pg_tg_density"
          >
            <:item value="compact">Compact</:item>
            <:item value="cozy">Cozy</:item>
            <:item value="comfortable">Comfortable</:item>
          </.toggle_group>
          <.toggle_group
            multiple
            variant={@tg_variant}
            size={@tg_size}
            aria_label="Formatting"
            value={@tg_formats}
            on_change="pg_tg_format"
          >
            <:item value="bold" aria-label="Bold"><.icon name="hero-bold" /></:item>
            <:item value="italic" aria-label="Italic"><.icon name="hero-italic" /></:item>
            <:item value="underline" aria-label="Underline"><.icon name="hero-underline" /></:item>
          </.toggle_group>
        </div>

        <div class="flex flex-wrap justify-center gap-6 px-4 pt-5 pb-6 border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-center text-gray-400">
              variant
            </div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Variant"
              value={@tg_variant}
              on_change="pg_tg_variant"
            >
              <:item value="solid">solid</:item>
              <:item value="outline">outline</:item>
              <:item value="accent">accent</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-center text-gray-400">
              size
            </div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Size"
              value={@tg_size}
              on_change="pg_tg_size"
            >
              <:item value="sm">sm</:item>
              <:item value="md">md</:item>
              <:item value="lg">lg</:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">The device rail, working</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        The canonical use, dogfooded: the rail drives the preview width below it, the way
        every playground's device switcher does. Same component, real content.
      </p>
      <div class="px-4 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex justify-center mb-6">
          <.toggle_group
            variant="outline"
            aria_label="Preview device"
            value={@tg_device}
            on_change="pg_tg_device"
          >
            <:item value="desktop" aria-label="Desktop">
              <.icon name="hero-computer-desktop" />
            </:item>
            <:item value="tablet" aria-label="Tablet"><.icon name="hero-device-tablet" /></:item>
            <:item value="mobile" aria-label="Phone">
              <.icon name="hero-device-phone-mobile" />
            </:item>
          </.toggle_group>
        </div>
        <div
          class={[
            "mx-auto transition-all duration-300 border border-dashed border-gray-300 rounded-xl p-5 dark:border-gray-700",
            @tg_device == "desktop" && "max-w-full",
            @tg_device == "tablet" && "max-w-md",
            @tg_device == "mobile" && "max-w-[250px]"
          ]}
          data-pg-device={@tg_device}
        >
          <h3 class="text-base font-semibold text-gray-900 dark:text-white">
            Publish your changes?
          </h3>
          <p class="mt-1 mb-4 text-sm text-gray-500 dark:text-gray-400">
            Two pages changed since the last deploy. The buttons below wrap on their own as
            the frame narrows - no breakpoint classes, just less room.
          </p>
          <div class="flex flex-wrap gap-2">
            <.button label="Publish now" />
            <.button color="gray" variant="outline" label="Preview first" />
          </div>
        </div>
      </div>

      <div :for={ex <- PetalComponents.Showcase.ToggleGroup.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.ToggleGroup} functions={[:toggle_group]} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.ToggleGroup</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift. Registry previews render fixed values by design (static, no outer
        state) - the Try it rail above is the live one.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "loading"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Loading</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        The spinner. Buttons already know it (loading attr) - use it standalone for
        anything else that waits.
      </p>
      <div :for={ex <- PetalComponents.Showcase.Loading.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Loading} function={:spinner} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Loading</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift. (show toggles visibility without unmounting.)
      </div>
    </div>
    """
  end

  defp render_page(%{active: "breadcrumbs"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Separator"
              value={@crumbs.separator}
              on_change="ctl_crumbs"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={sp <- ~w(chevron slash)}
                value={sp}
                phx-value-k="separator"
                phx-value-v={sp}
              >
                {sp}
              </:item>
            </.toggle_group>
          </div>
        </div>
      </div>
      <div
        :for={ex <- examples_for(PetalComponents.Showcase.Breadcrumbs, ~w(basic)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Breadcrumbs} function={:breadcrumbs} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Breadcrumbs</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "stepper"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
              label_placement={@stepper.labels}
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
        <div class="grid gap-5 px-6 py-5 border-t border-gray-100 md:grid-cols-3 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">orientation</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Orientation"
              value={@stepper.orientation}
              on_change="ctl_stepper"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={o <- ~w(horizontal vertical)}
                value={o}
                phx-value-k="orientation"
                phx-value-v={o}
              >
                {o}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Size"
              value={@stepper.size}
              on_change="ctl_stepper"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={sz <- ~w(sm md lg)} value={sz} phx-value-k="size" phx-value-v={sz}>
                {sz}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">labels</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Labels"
              value={@stepper.labels}
              on_change="ctl_stepper"
              disabled={@stepper.orientation == "vertical"}
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={lp <- ~w(beside bottom)} value={lp} phx-value-k="labels" phx-value-v={lp}>
                {lp}
              </:item>
            </.toggle_group>
            <div :if={@stepper.orientation == "vertical"} class="mt-1.5 text-[10px] text-gray-400">
              horizontal only
            </div>
          </div>
        </div>
      </div>
      <div :for={ex <- PetalComponents.Showcase.Stepper.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Stepper} function={:stepper} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Stepper</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift. (The wizard above is playground-only - its steps push events.)
      </div>
    </div>
    """
  end

  defp render_page(%{active: "avatar"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Avatar</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Images, initials fallbacks, presence dots, and stacked groups.
      </p>
      <div class="mt-8 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Sizes - 2xs to xl
      </div>
      <div class="border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-wrap items-end justify-center gap-4 px-6 py-12">
          <div :for={sz <- ~w(2xs xs sm md lg xl)} class="flex flex-col items-center gap-2 shrink-0">
            <.avatar size={sz} src="/dev-static/avatars/p32.jpg" alt="Team member" />
            <span class="text-[11px] text-gray-400">{sz}</span>
          </div>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Fallback chain - photo, initials, icon
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-wrap items-center justify-center gap-6">
          <div class="flex flex-col items-center gap-2 shrink-0">
            <.avatar src="/dev-static/avatars/p44.jpg" alt="Photo" />
            <span class="text-[11px] text-gray-400">src</span>
          </div>
          <div class="flex flex-col items-center gap-2 shrink-0">
            <.avatar name="Ada Lovelace" />
            <span class="text-[11px] text-gray-400">initials</span>
          </div>
          <div class="flex flex-col items-center gap-2 shrink-0">
            <.avatar name="Grace Hopper" random_color />
            <span class="text-[11px] text-gray-400">random_color</span>
          </div>
          <div class="flex flex-col items-center gap-2 shrink-0">
            <.avatar name="Ada Lovelace" random_gradient />
            <span class="text-[11px] text-gray-400">random_gradient</span>
          </div>
          <div class="flex flex-col items-center gap-2 shrink-0">
            <.avatar />
            <span class="text-[11px] text-gray-400">no name</span>
          </div>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Shape - circles for people, rounded for orgs and teams
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center gap-5">
          <div class="flex flex-wrap items-center justify-center gap-4">
            <.avatar src="/dev-static/avatars/p32.jpg" size="lg" />
            <.avatar src="/dev-static/avatars/p32.jpg" shape="rounded" size="lg" />
            <.avatar name="Acme Corp" shape="rounded" random_gradient size="lg" />
            <.avatar name="Petal Framework" shape="rounded" art="mesh" size="lg" />
            <.avatar name="Design Guild" shape="rounded" art="dither" size="lg" />
            <.avatar
              src="/dev-static/avatars/p65.jpg"
              shape="rounded"
              status="online"
              size="lg"
            />
          </div>
          <.avatar_group
            size="md"
            shape="rounded"
            max={3}
            avatars={[
              "/dev-static/avatars/p32.jpg",
              "/dev-static/avatars/p65.jpg",
              "/dev-static/avatars/p44.jpg",
              "/dev-static/avatars/p12.jpg",
              "/dev-static/avatars/p68.jpg"
            ]}
          />
          <p class="text-xs text-center text-gray-400 dark:text-gray-500">
            <code>shape="rounded"</code>
            works across every variant - photos, monograms, art, status dots
            and groups. Deliberately independent of the radius dial: avatars
            are identity, not surface.
          </p>
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Generative art - mesh and dither, hashed from the name
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center gap-6">
          <div class="flex flex-wrap items-center justify-center gap-4">
            <.avatar
              :for={name <- ~w(Amelia Jonah Priya Maya Deploy Billing Status Petal)}
              name={name}
              art="mesh"
              size="lg"
            />
          </div>
          <div class="flex flex-wrap items-center justify-center gap-4">
            <.avatar
              :for={name <- ~w(Amelia Jonah Priya Maya Deploy Billing Status Petal)}
              name={name}
              art="dither"
              size="lg"
            />
          </div>
          <div class="flex flex-wrap items-center justify-center gap-4">
            <.avatar
              :for={name <- ["Amelia Ward", "Jonah Reyes", "Priya Anand", "Maya Okafor"]}
              name={name}
              art="mesh"
              initials
              size="lg"
            />
          </div>
          <p class="text-xs text-center text-gray-400 dark:text-gray-500">
            <code>art="mesh"</code>
            and <code>art="dither"</code>
            draw the avatar instead of initials - deterministic per name, pure
            CSS and inline SVG, no JavaScript. Add <code>initials</code>
            to the mesh to overlay a dark hue-tinted monogram; dither stays
            pure art - pixels and letters never mix cleanly. A photo <code>src</code>
            still wins when present.
          </p>
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

      <div :for={ex <- PetalComponents.Showcase.Avatar.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Avatar} functions={[:avatar, :avatar_group]} />
    </div>
    """
  end

  defp render_page(%{active: "card"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Card</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        The container for everything - media, content, footer, composed from parts.
      </p>
      <div :for={ex <- PetalComponents.Showcase.Card.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        Media card - full-bleed image, category, heading (the cover photo is a
        dev-only local file, so this stays a playground extra)
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

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props
        component={PetalComponents.Card}
        functions={[:card, :card_header, :card_content, :card_footer, :card_media, :review_card]}
      />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Card</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "accordion"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Variant"
              value={@accordion.variant}
              on_change="ctl_accordion"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={v <- ~w(default bordered)} value={v} phx-value-k="variant" phx-value-v={v}>
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Size"
              value={@accordion.size}
              on_change="ctl_accordion"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={sz <- ~w(md sm)} value={sz} phx-value-k="size" phx-value-v={sz}>
                {if sz == "sm", do: "compact", else: "default"}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="Extras"
              value={for {k, on} <- [{"multiple", @accordion.multiple}], on, do: k}
              on_change="ctl_accordion"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="multiple" phx-value-k="multiple">allow multiple open</:item>
            </.toggle_group>
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

      <div :for={ex <- PetalComponents.Showcase.Accordion.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Accordion} function={:accordion} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Accordion</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "marquee"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="Extras"
              value={
                for {k, on} <- [
                      {"reverse", @marquee_ctl.reverse},
                      {"vertical", @marquee_ctl.vertical},
                      {"pause", @marquee_ctl.pause}
                    ],
                    on,
                    do: k
              }
              on_change="ctl_marquee"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="reverse" phx-value-k="reverse">reverse</:item>
              <:item value="vertical" phx-value-k="vertical">vertical</:item>
              <:item value="pause" phx-value-k="pause">pause on hover</:item>
            </.toggle_group>
          </div>
        </div>
      </div>
      <div :for={ex <- PetalComponents.Showcase.Marquee.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Marquee} function={:marquee} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Marquee</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift. (overlay_gradient fades the edges.)
      </div>
    </div>
    """
  end

  defp render_page(%{active: "spotlight-card"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Spotlight card</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A radial glow follows your cursor across the card. Move your mouse over them.
      </p>
      <div :for={ex <- PetalComponents.Showcase.SpotlightCard.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.SpotlightCard} function={:spotlight_card} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.SpotlightCard</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "number-ticker"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
        </div>
      </div>

      <div :for={ex <- PetalComponents.Showcase.NumberTicker.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.NumberTicker} function={:number_ticker} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.NumberTicker</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "text-animation"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Text animation</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Four ways to make words move: gradient sweep, shimmer, typing, and word rotation.
      </p>
      <div :for={ex <- PetalComponents.Showcase.TextAnimation.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props
        component={PetalComponents.TextAnimation}
        functions={[:gradient_text, :shimmer_text, :typing_effect, :word_rotate]}
      />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.TextAnimation</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "confetti"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Confetti</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Zero-dependency canvas confetti. Fire it from the client or push it from the
        server on the moments that matter.
      </p>
      <div :for={ex <- PetalComponents.Showcase.Confetti.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Confetti} function={:confetti} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Confetti</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "tabs"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Variant"
              value={@tabs.variant}
              on_change="ctl_tabs"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={v <- ~w(segmented underline pill)}
                value={v}
                phx-value-k="variant"
                phx-value-v={v}
              >
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="Extras"
              value={for {k, on} <- [{"number", @tabs.number}], on, do: k}
              on_change="ctl_tabs"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="number" phx-value-k="number">number badge</:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <div :for={ex <- PetalComponents.Showcase.Tabs.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Tabs} functions={[:tabs, :tab]} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Tabs</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "pagination"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Sibling"
              value={@page.sibling}
              on_change="ctl_page"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={n <- ~w(0 1 2)} value={n} phx-value-k="sibling" phx-value-v={n}>{n}</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">boundary count</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Boundary"
              value={@page.boundary}
              on_change="ctl_page"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={n <- ~w(1 2)} value={n} phx-value-k="boundary" phx-value-v={n}>{n}</:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.Pagination, ~w(link_mode simple)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Pagination} function={:pagination} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Pagination</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "table"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Table</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Sortable headers, density, stripes - the presentation layer for data. Click
        Name or Age to sort; the component fires the event, your app reorders the rows.
      </p>

      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="px-6 py-8 overflow-x-auto">
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
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Density"
              value={@table.density}
              on_change="ctl_table"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={d <- ~w(comfortable compact)}
                value={d}
                phx-value-k="density"
                phx-value-v={d}
              >
                {d}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Variant"
              value={@table.variant}
              on_change="ctl_table"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={v <- ~w(basic ghost)} value={v} phx-value-k="variant" phx-value-v={v}>
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="Extras"
              value={for {k, on} <- [{"striped", @table.striped}, {"empty", @table.empty}], on, do: k}
              on_change="ctl_table"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="striped" phx-value-k="striped">striped</:item>
              <:item value="empty" phx-value-k="empty">empty state</:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.Table, ~w(people_cells)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Search and filtering are deliberately NOT here - they are data-layer concerns
        (queries, params, debounce), which is exactly where the pro data_table picks up.
        This component draws the line at presentation: it renders state and fires events.
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Table} functions={[:table, :user_inner_td]} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Table</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "tooltip"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">placement</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Placement"
              value={@tooltip.placement}
              on_change="ctl_tooltip"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={pl <- ~w(top bottom left right)}
                value={pl}
                phx-value-k="placement"
                phx-value-v={pl}
              >
                {pl}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="Extras"
              value={for {k, on} <- [{"arrow", @tooltip.arrow}], on, do: k}
              on_change="ctl_tooltip"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="arrow" phx-value-k="arrow">arrow</:item>
            </.toggle_group>
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

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.Tooltip, ~w(icon_buttons rich_content)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Tooltip} function={:tooltip} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Tooltip</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "popover"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">placement</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Placement"
              value={@popover.placement}
              on_change="ctl_popover"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={pl <- ~w(top bottom left right)}
                value={pl}
                phx-value-k="placement"
                phx-value-v={pl}
              >
                {pl}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="Extras"
              value={for {k, on} <- [{"top_layer", @popover.top_layer}], on, do: k}
              on_change="ctl_popover"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="top_layer" phx-value-k="top_layer">top_layer</:item>
            </.toggle_group>
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

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.Popover, ~w(top_layer)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Popover} function={:popover} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Popover</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "input-otp"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">length</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Length"
              value={@otp.length}
              on_change="ctl_otp"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={l <- ~w(4 6)} value={l} phx-value-k="length" phx-value-v={l}>{l}</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">pattern</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Pattern"
              value={@otp.pattern}
              on_change="ctl_otp"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={pt <- ~w(numeric alphanumeric)}
                value={pt}
                phx-value-k="pattern"
                phx-value-v={pt}
              >
                {pt}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="Extras"
              value={
                for {k, on} <- [{"grouped", @otp.grouped}, {"disabled", @otp.disabled}], on, do: k
              }
              on_change="ctl_otp"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="grouped" phx-value-k="grouped">grouped</:item>
              <:item value="disabled" phx-value-k="disabled">disabled</:item>
            </.toggle_group>
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

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.InputOtp, ~w(grouped error_state)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.InputOtp} function={:input_otp} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.InputOtp</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "switch"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Size"
              value={@switch.size}
              on_change="ctl_switch"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={z <- ~w(xs sm md lg xl)} value={z} phx-value-k="size" phx-value-v={z}>
                {z}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">state</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="State"
              value={
                for {k, on} <- [{"error", @switch.error}, {"disabled", @switch.disabled}], on, do: k
              }
              on_change="ctl_switch"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="error" phx-value-k="error">error</:item>
              <:item value="disabled" phx-value-k="disabled">disabled</:item>
            </.toggle_group>
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

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.Field, ~w(switch switch_sizes)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Field} function={:field} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Field</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "input-group"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Input group</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        One field surface, many parts. The group carries the border, radius and
        focus ring; any petal input dropped inside sheds its own surface, so
        text, icons, kbd hints, selects and buttons all compose.
      </p>

      <div :for={ex <- PetalComponents.Showcase.InputGroup.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.InputGroup} function={:input_group} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.InputGroup</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "user-menu"} = assigns) do
    # The corner dial is one question with two answers, and each answer
    # settles both attrs: there is no alignment for "up" other than lining
    # the panel's left edge up with the row it grew out of, and none for
    # "beside" other than levelling their bottoms.
    assigns =
      case assigns.user_menu_opens do
        "up" -> assign(assigns, um_side: "top", um_align: "start")
        "beside" -> assign(assigns, um_side: "right", um_align: "end")
      end

    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">User menu</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        The avatar-with-chevron every app shell ends up needing - an avatar
        trigger, a dropdown, and a list of menu items from plain maps. Or, with
        variant="sidebar", the full-width name-and-email row a sidebar wants.
      </p>

      <div :for={ex <- PetalComponents.Showcase.UserDropdownMenu.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        With a photo - avatar_src wins over initials (demo photo is dev-only, so this
        stays a playground extra)
      </div>
      <div class="px-6 pt-10 border border-gray-200 rounded-xl dark:border-gray-800 pb-44">
        <div class="flex justify-center">
          <.user_dropdown_menu
            current_user_name="Sarah Chen"
            avatar_src="/dev-static/avatars/p32.jpg"
            user_menu_items={[
              %{path: "/?c=user-menu", icon: "hero-user", label: "Profile"},
              %{path: "/?c=user-menu", icon: "hero-cog-6-tooth", label: "Settings"},
              %{
                path: "/?c=user-menu",
                icon: "hero-arrow-right-start-on-rectangle",
                label: "Sign out"
              }
            ]}
          />
        </div>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        The corner it actually lives in - variant="sidebar" pinned to the bottom of a sidebar
      </div>
      <div class="border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex h-[500px]">
          <%!-- p-2 rather than p-3 so the sidebar's own padding matches the
          panel's 8px side gap: in "beside" mode the panel then clears the
          sidebar's edge exactly instead of landing 4px inside it. --%>
          <div class="flex flex-col flex-none p-2 border-r w-64 border-gray-200 dark:border-gray-800">
            <div class="px-2 py-1 text-sm font-semibold">Acme Inc</div>
            <div class="mt-3 space-y-0.5">
              <div
                :for={
                  {icon, label} <- [
                    {"hero-home", "Dashboard"},
                    {"hero-users", "Customers"},
                    {"hero-banknotes", "Billing"},
                    {"hero-cog-6-tooth", "Settings"}
                  ]
                }
                class="flex items-center gap-2 px-2 py-1.5 text-sm text-gray-500 rounded-lg dark:text-gray-400"
              >
                <.icon name={icon} class="w-4 h-4 text-gray-400 dark:text-gray-500" />{label}
              </div>
            </div>
            <div class="pt-3 mt-auto border-t border-gray-100 dark:border-gray-800/80">
              <.user_dropdown_menu
                variant="sidebar"
                current_user_name="Sarah Chen"
                current_user_email="sarah@acme.com"
                avatar_src="/dev-static/avatars/p32.jpg"
                side={@um_side}
                align={@um_align}
                menu_items_wrapper_class="w-60"
              >
                <.dropdown_menu_label>Organizations</.dropdown_menu_label>
                <.dropdown_menu_item link_type="button">
                  <.avatar name="Acme Inc" size="2xs" random_color /> Acme Inc
                  <.icon name="hero-check" class="w-4 h-4 ml-auto" />
                </.dropdown_menu_item>
                <.dropdown_menu_item link_type="button">
                  <.avatar name="Northwind" size="2xs" random_color /> Northwind
                </.dropdown_menu_item>
                <.dropdown_menu_item link_type="button">
                  <.avatar name="Petal Labs" size="2xs" random_color /> Petal Labs
                </.dropdown_menu_item>
                <.dropdown_menu_item link_type="button">
                  <.icon name="hero-plus" class="w-4 h-4" /> New organization
                </.dropdown_menu_item>
                <.dropdown_menu_separator />
                <.dropdown_menu_label>Account</.dropdown_menu_label>
                <.dropdown_menu_item link_type="button">
                  <.icon name="hero-user" class="w-4 h-4" /> Profile
                  <kbd class="pc-kbd ml-auto"><span>⇧</span><span>⌘</span>P</kbd>
                </.dropdown_menu_item>
                <.dropdown_menu_item link_type="button">
                  <.icon name="hero-adjustments-horizontal" class="w-4 h-4" /> Preferences
                </.dropdown_menu_item>
                <.dropdown_menu_row>
                  <.icon name="hero-paint-brush" class="w-4 h-4" /> Theme
                  <.color_scheme_switch id="pg-corner-scheme" variant="segmented" class="ml-auto" />
                </.dropdown_menu_row>
                <.dropdown_menu_separator />
                <.dropdown_menu_item
                  link_type="button"
                  class="text-danger-600 dark:text-danger-400"
                >
                  <.icon name="hero-arrow-right-start-on-rectangle" class="w-4 h-4" /> Sign out
                  <kbd class="pc-kbd ml-auto"><span>⇧</span><span>⌘</span>Q</kbd>
                </.dropdown_menu_item>
              </.user_dropdown_menu>
            </div>
          </div>
          <div class="flex-1 p-4 space-y-3">
            <div class="w-32 h-3 rounded bg-gray-100 dark:bg-gray-900"></div>
            <div class="w-full h-24 rounded-lg bg-gray-50 dark:bg-gray-900/50"></div>
            <div class="w-full h-24 rounded-lg bg-gray-50 dark:bg-gray-900/50"></div>
          </div>
        </div>
        <div class="px-6 py-4 border-t border-gray-100 dark:border-gray-800/80">
          <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">opens</div>
          <.toggle_group
            variant="outline"
            size="sm"
            aria_label="Opens"
            value={@user_menu_opens}
            on_change="ctl_usermenu"
            class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
          >
            <:item :for={o <- ~w(up beside)} value={o} phx-value-k="opens" phx-value-v={o}>
              {o}
            </:item>
          </.toggle_group>
        </div>
      </div>
      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        The row takes the full sidebar width and carries the name and email itself, so
        there is no avatar-plus-label pairing to hand-roll. Both lines truncate, which
        is what you want the first time someone signs in with a long address. And a
        menu down here is usually not a list of links at all - it is the account
        panel: an org switcher, a labelled account group with shortcuts, a theme row. <br /><br />
        side is which side of the trigger the panel opens on and align is which edges
        line up on the other axis, so this corner is either <code>side="top" align="start"</code>
        - above the row, left edges flush, growing into the app - or
        <code>side="right" align="end"</code>
        - out past the sidebar with its bottom edge level with the row that opened it.
        There is no third setting and no dial for align, because a sidebar-bottom menu
        opens up or out, never down, and each side leaves exactly one alignment that
        reads as part of the same corner. Neither one measures anything: an explicit
        side is a decision already made, so the hook never attaches and no first frame
        points the wrong way. What differs is what gets covered - up buries the nav
        you just came from, out lays over the content area instead. (placement and
        direction are the older spelling of these same two questions and still work
        exactly as they did.)
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.UserDropdownMenu} function={:user_dropdown_menu} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.UserDropdownMenu</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift. (An icon can be a heroicon name, a function component, or a raw
        svg string.)
      </div>
    </div>
    """
  end

  defp render_page(%{active: "slider"} = assigns) do
    assigns = assign(assigns, :sb, slider_bounds(assigns.slider.format))

    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Slider</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        One thumb or two, one grammar: the same track, thumb and focus ring
        whether you render a single range (pure CSS on the native input) or the
        dual range (two thumbs and a hook for min/max filtering).
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center px-6 py-12">
          <div class="w-full max-w-sm">
            <.field
              :if={@slider.thumbs == "dual"}
              id={"pg-slider-#{@slider.format}-#{@slider.disabled}"}
              type="range-dual"
              min_field={@slider_form[:min]}
              max_field={@slider_form[:max]}
              range_min={@sb.bound_min}
              range_max={@sb.bound_max}
              step={@sb.step}
              value_prefix={@sb.prefix}
              value_suffix={@sb.suffix}
              label={@sb.label}
              disabled={@slider.disabled}
              no_margin
            />
            <.field
              :if={@slider.thumbs == "single"}
              id={"pg-single-#{@slider.fill}-#{@slider.disabled}"}
              type="range"
              name="pg_flag_volume"
              label="Volume"
              value="60"
              min="0"
              max="100"
              fill={@slider.fill}
              disabled={@slider.disabled}
              no_margin
            />
          </div>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">thumbs</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Thumbs"
              value={@slider.thumbs}
              on_change="ctl_slider"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={t <- ~w(single dual)} value={t} phx-value-k="thumbs" phx-value-v={t}>
                {t}
              </:item>
            </.toggle_group>
          </div>
          <div :if={@slider.thumbs == "dual"}>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">format</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Format"
              value={@slider.format}
              on_change="ctl_slider"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={f <- ~w(money percent plain)}
                value={f}
                phx-value-k="format"
                phx-value-v={f}
              >
                {f}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">state</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="State"
              value={
                for {k, on} <- [{"fill", @slider.fill}, {"disabled", @slider.disabled}], on, do: k
              }
              on_change="ctl_slider"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :if={@slider.thumbs == "single"} value="fill" phx-value-k="fill">fill</:item>
              <:item value="disabled" phx-value-k="disabled">disabled</:item>
            </.toggle_group>
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
      ><code>{slider_snippet(@slider)}</code></pre>

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.Field, ~w(sliders slider_dual)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Field} function={:field} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Field</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift. Sliders are field types (range / range-dual), so they live in the
        field registry with the rest of the form surface.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "radio"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Radio</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Plain radio groups, plus radio cards - selectable panels with labels and
        descriptions that most libraries make you hand-roll.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center px-6 py-12">
          <div class="w-full max-w-lg">
            <.field
              :if={@radio.style == "cards"}
              type="radio-card"
              name="pg_plan"
              label="Plan"
              value="pro"
              variant={@radio.variant}
              size={@radio.size}
              group_layout={@radio.layout}
              indicator={@radio.indicator}
              indicator_position={@radio.ind_pos}
              disabled={@radio.disabled}
              options={[
                %{value: "starter", label: "Starter", description: "For side projects"},
                %{value: "pro", label: "Pro", description: "For small teams"},
                %{value: "team", label: "Team", description: "For growing orgs"}
              ]}
              no_margin
            />
            <div :if={@radio.style == "plain"} class="flex justify-center">
              <.field
                type="radio-group"
                name="pg_plan_plain"
                label="Plan"
                value="pro"
                group_layout={@radio.layout}
                disabled={@radio.disabled}
                options={[{"Starter", "starter"}, {"Pro", "pro"}, {"Team", "team"}]}
                no_margin
              />
            </div>
          </div>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">style</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Style"
              value={@radio.style}
              on_change="ctl_radio"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={st <- ~w(cards plain)} value={st} phx-value-k="style" phx-value-v={st}>
                {st}
              </:item>
            </.toggle_group>
          </div>
          <div :if={@radio.style == "cards"}>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Variant"
              value={@radio.variant}
              on_change="ctl_radio"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={v <- ~w(outline classic)} value={v} phx-value-k="variant" phx-value-v={v}>
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div :if={@radio.style == "cards"}>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Size"
              value={@radio.size}
              on_change="ctl_radio"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={z <- ~w(sm md lg)} value={z} phx-value-k="size" phx-value-v={z}>{z}</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">layout</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Layout"
              value={@radio.layout}
              on_change="ctl_radio"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={l <- ~w(row col)} value={l} phx-value-k="layout" phx-value-v={l}>
                {l}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">state</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="State"
              value={
                for {k, on} <- [{"indicator", @radio.indicator}, {"disabled", @radio.disabled}],
                    on,
                    do: k
              }
              on_change="ctl_radio"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :if={@radio.style == "cards"} value="indicator" phx-value-k="indicator">
                indicator
              </:item>
              <:item value="disabled" phx-value-k="disabled">disabled</:item>
            </.toggle_group>
          </div>
          <div :if={@radio.style == "cards" && @radio.indicator}>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">
              indicator position
            </div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Ind pos"
              value={@radio.ind_pos}
              on_change="ctl_radio"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={p <- ~w(end corner start)} value={p} phx-value-k="ind_pos" phx-value-v={p}>
                {p}
              </:item>
            </.toggle_group>
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

      <div
        :for={
          ex <-
            examples_for(
              PetalComponents.Showcase.Field,
              ~w(radio_group radio_cards radio_card_tiles radio_card_disabled)a
            )
        }
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">
        People picker - options take an image too (demo photos are dev-only, so this
        stays a playground extra)
      </div>
      <div class="px-6 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="max-w-sm mx-auto">
          <.field
            type="radio-card"
            name="pg_reviewer"
            label="Assign a reviewer"
            value="sarah"
            group_layout="col"
            indicator
            options={[
              %{
                value: "sarah",
                label: "Sarah Chen",
                description: "@sarahchen",
                image: "/dev-static/avatars/p32.jpg"
              },
              %{
                value: "alex",
                label: "Alex Rivera",
                description: "@alexrivera",
                image: "/dev-static/avatars/p44.jpg"
              },
              %{
                value: "jordan",
                label: "Jordan Lee",
                description: "@jordanlee",
                image: "/dev-static/avatars/p65.jpg"
              }
            ]}
            no_margin
          />
        </div>
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Field} function={:field} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Field</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "select"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">state</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="State"
              value={
                for {k, on} <- [
                      {"help", @select.help},
                      {"error", @select.error},
                      {"disabled", @select.disabled}
                    ],
                    on,
                    do: k
              }
              on_change="ctl_select"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="help" phx-value-k="help">help</:item>
              <:item value="error" phx-value-k="error">error</:item>
              <:item value="disabled" phx-value-k="disabled">disabled</:item>
            </.toggle_group>
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

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.Field, ~w(select_groups select_multiple)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Field} function={:field} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Field</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "data-table"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Data table</h1>
      <p class="mt-2 mb-6 text-gray-600 dark:text-gray-300">
        Sortable, paged and filter-aware, driven by one State struct. Wire it to events or
        to the URL - the two live demos below run the same free in-memory engine, one per
        mode.
      </p>

      <h2 class="mb-1 text-lg font-semibold">Event mode</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        Every interaction pushes a single op-grammar event, the handler applies it with
        State helpers and re-runs the engine. Sort this one and the URL stays put -
        the state lives on the server.
      </p>
      <div class="border border-gray-200 dark:border-gray-400/20 rounded-xl p-6">
        <% {state, rows} = @dt %>
        <.data_table
          id="pg-dt"
          rows={rows}
          state={state}
          on_change="pg_table"
          striped
          searchable
          page_size_options={[5, 10, 20]}
          selectable
          selected={@dt_selected}
          column_toggle
          hidden_columns={@dt_hidden}
          reorderable
          column_order={@dt_order}
        >
          <:col :let={row} field={:name} sortable>{row.name}</:col>
          <:col :let={row} field={:email} filterable="text">{row.email}</:col>
          <:col
            :let={row}
            field={:status}
            filterable="select"
            options={[{"Paid", "paid"}, {"Pending", "pending"}, {"Refunded", "refunded"}]}
          >
            <.badge
              size="sm"
              variant="soft"
              color={
                case row.status do
                  "paid" -> "success"
                  "pending" -> "warning"
                  _ -> "danger"
                end
              }
              label={row.status}
            />
          </:col>
          <:col :let={row} field={:amount} sortable align="right" filterable="number">
            ${row.amount}
          </:col>
          <:bulk_action :let={ids}>
            <.button
              size="sm"
              variant="soft"
              color="danger"
              phx-click="pg_table"
              phx-value-op="refund"
            >
              Refund {length(ids)}
            </.button>
          </:bulk_action>
        </.data_table>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Link mode</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        The same rows and engine, driven entirely by the URL: sort, filter, search and page
        all patch State-encoded query params, <code class="text-sm">handle_params</code>
        decodes them back through the field whitelist and re-runs the engine. No events -
        every view is a link you can share, bookmark or curl. No selection or column
        controls here either: those are UI state, and UI state rides events, never URLs.
        Try sorting, then reload.
      </p>
      <div class="border border-gray-200 dark:border-gray-400/20 rounded-xl p-6">
        <% {link_state, link_rows} = @dt_link %>
        <.data_table
          id="pg-dt-link"
          rows={link_rows}
          state={link_state}
          path={
            theme_path(%{
              active: "data-table",
              primary: @primary,
              secondary: @secondary,
              gray: @gray,
              radius: @radius
            })
          }
          striped
          searchable
          page_size_options={[5, 10, 20]}
        >
          <:col :let={row} field={:name} sortable>{row.name}</:col>
          <:col :let={row} field={:email} filterable="text">{row.email}</:col>
          <:col
            :let={row}
            field={:status}
            filterable="select"
            options={[{"Paid", "paid"}, {"Pending", "pending"}, {"Refunded", "refunded"}]}
          >
            <.badge
              size="sm"
              variant="soft"
              color={
                case row.status do
                  "paid" -> "success"
                  "pending" -> "warning"
                  _ -> "danger"
                end
              }
              label={row.status}
            />
          </:col>
          <:col :let={row} field={:amount} sortable align="right" filterable="number">
            ${row.amount}
          </:col>
        </.data_table>
      </div>

      <div class="mt-4">
        <p class="mb-1 text-sm text-gray-500 dark:text-gray-400">
          The state this demo decoded from the URL:
        </p>
        <pre class="p-3 overflow-x-auto text-xs rounded-lg bg-gray-100 dark:bg-gray-800"><code>{inspect(elem(@dt_link, 0), pretty: true, width: 60)}</code></pre>
      </div>

      <div
        :for={
          ex <-
            examples_for(
              PetalComponents.Showcase.DataTable,
              ~w(basic toolbar selection columns loading empty)a
            )
        }
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <.showcase_props component={PetalComponents.DataTable} function={:data_table} />
    </div>
    """
  end

  defp render_page(%{active: "combo-box"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Combobox</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A searchable select: type to filter, arrow keys to move, Enter to choose.
        The visible input is chrome - a hidden native select carries the value,
        so it posts and recovers like any other form control.
      </p>

      <h2 class="mt-8 mb-2 text-lg font-semibold">Try it</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        This one is wired to a real form with phx-change. Choose a city and the
        server receives it immediately - no hook messages, no client state, just
        the select underneath doing what selects do.
      </p>

      <div class="border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center px-6 py-12">
          <form id="pg-combo-form" phx-change="pg_combo_change" class="w-full max-w-sm">
            <.combo_box
              id="pg-combo"
              clearable
              name="pg_city"
              placeholder="Search cities…"
              value={@combo.chosen}
              disabled={@combo.disabled}
              options={[
                {"Oceania",
                 [
                   {"Sydney", "syd"},
                   {"Melbourne", "mel"},
                   {"Auckland", "akl"},
                   {"Perth", "per", disabled: true}
                 ]},
                {"Europe",
                 [{"Lisbon", "lis"}, {"Stockholm", "sto"}, {"Berlin", "ber"}, {"Porto", "opo"}]},
                {"Asia", [{"Tokyo", "tyo"}, {"Singapore", "sin"}, {"Seoul", "sel"}]}
              ]}
            />
          </form>
        </div>

        <div class="px-4 py-3 text-sm border-t border-gray-200 sm:px-6 dark:border-gray-800">
          <span class="text-gray-400">the server has:</span>
          <code class="ml-1 font-mono text-gray-900 dark:text-gray-100">
            {if @combo.chosen in [nil, ""], do: "nothing yet", else: @combo.chosen}
          </code>
        </div>

        <div class="flex flex-wrap items-end px-4 py-4 border-t border-gray-200 gap-x-8 gap-y-4 sm:px-6 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">state</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="State"
              value={for {k, on} <- [{"disabled", @combo.disabled}], on, do: k}
              on_change="ctl_combo"
            >
              <:item value="disabled" phx-value-k="disabled">disabled</:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Field citizenship + sizes</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        &lt;.field type="combobox"&gt; brings label, changeset errors and help_text; size spans
        the field family (xs/xl clamp to sm/lg). Rich slots stay on the bare component.
      </p>
      <div class="border border-gray-200 dark:border-gray-400/20 rounded-xl px-6 py-10">
        <div class="mx-auto flex w-full max-w-sm flex-col gap-1">
          <.field
            type="combobox"
            name="fc_city"
            value={nil}
            label="Destination"
            help_text="Where the team offsite lands"
            clearable
            options={[{"🇯🇵 Tokyo", "tyo"}, {"🇵🇹 Lisbon", "lis"}, {"🇸🇪 Stockholm", "sto"}]}
          />
        </div>
        <p class="mx-auto mt-8 mb-3 w-full max-w-sm text-sm font-medium">
          Sizes, side by side - same anatomy, three densities
        </p>
        <div class="mx-auto flex w-full max-w-sm flex-col gap-3">
          <.field
            type="combobox"
            name="fc_size_sm"
            value={nil}
            label="size=sm"
            size="sm"
            placeholder="28px control, text-xs"
            options={["Alpha", "Beta"]}
          />
          <.field
            type="combobox"
            name="fc_size_md"
            value={nil}
            label="size=md (default)"
            placeholder="36px control, text-sm"
            options={["Alpha", "Beta"]}
          />
          <.field
            type="combobox"
            name="fc_size_lg"
            value={nil}
            label="size=lg"
            size="lg"
            placeholder="44px control, text-base"
            options={["Alpha", "Beta"]}
          />
        </div>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Remote search - live</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        The LiveView is the data source: typing pushes a debounced event with the raw term, the
        handler replies with results, and the hook renders them - loading row, stale-reply
        protection and all. This one searches ~60 world cities server-side.
      </p>
      <div class="border border-gray-200 dark:border-gray-400/20 rounded-xl px-6 py-10">
        <form id="pg-remote-form" phx-change="pg_remote_change" class="mx-auto w-full max-w-sm">
          <.combo_box
            id="pg-combo-remote"
            name="pg_city_remote"
            placeholder="Search cities (server-side)…"
            remote_options_event_name="pg_remote_search"
            options={[]}
          />
        </form>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Rich closed states - live</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        The same :selected and :chip slots, wired to a real form with phx-change. Every pick
        round-trips, so the server re-renders the rich content immediately - dots, +N, avatar
        chips all track your choices live.
      </p>
      <div class="border border-gray-200 dark:border-gray-400/20 rounded-xl px-6 py-10">
        <form
          id="pg-rich-form"
          phx-change="pg_rich_change"
          class="mx-auto flex w-full max-w-sm flex-col gap-4"
        >
          <.combo_box
            id="pg-combo-labels"
            name="pg_labels"
            variant="trigger"
            multiple
            placeholder="Labels…"
            count_label="labels"
            value={@rich.labels}
            options={[
              {"Feature", "feat", color: "#0ea5e9"},
              {"Bug", "bug", color: "#f43f5e"},
              {"Improvement", "imp", color: "#10b981"},
              {"Design", "des", color: "#a855f7"},
              {"Docs", "docs", color: "#f59e0b"}
            ]}
          >
            <:selected :let={chosen}>
              <span
                :for={opt <- Enum.take(chosen, 3)}
                class="h-3 w-3 shrink-0 rounded-full"
                style={"background-color: #{opt.meta[:color]}"}
              ></span>
              <span :if={length(chosen) == 1} class="truncate">{hd(chosen).label}</span>
              <span
                :if={length(chosen) > 3}
                class="text-xs tabular-nums text-gray-500 dark:text-gray-400"
              >
                +{length(chosen) - 3}
              </span>
            </:selected>
            <:option :let={opt}>
              <span
                class="h-2.5 w-2.5 shrink-0 rounded-full"
                style={"background-color: #{opt.meta[:color]}"}
              ></span>
              <span class="truncate">{opt.label}</span>
            </:option>
          </.combo_box>

          <.combo_box
            id="pg-combo-team"
            name="pg_team"
            multiple
            placeholder="Add members…"
            value={@rich.team}
            options={[
              {"Amelia Ward", "amelia", role: "Engineering"},
              {"Jonah Reyes", "jonah", role: "Design"},
              {"Priya Anand", "priya", role: "Support"},
              {"Tom Hale", "tom", role: "Engineering"}
            ]}
          >
            <:chip :let={opt}>
              <.avatar size="2xs" name={opt.label} random_gradient />
              <span class="truncate">{opt.label}</span>
            </:chip>
            <:option :let={opt}>
              <.avatar size="xs" name={opt.label} random_gradient />
              <span class="flex min-w-0 flex-col leading-tight">
                <span class="truncate">{opt.label}</span>
                <span class="truncate text-xs text-gray-500 dark:text-gray-400">
                  {opt.meta[:role]}
                </span>
              </span>
            </:option>
          </.combo_box>
        </form>
      </div>

      <div
        :for={
          ex <-
            examples_for(
              PetalComponents.Showcase.ComboBox,
              ~w(creatable labels team panel_chrome multiple trigger rich_options basic preselected groups)a
            )
        }
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.ComboBox} function={:combo_box} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.ComboBox</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "checkbox"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">layout</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Layout"
              value={@checkbox.layout}
              on_change="ctl_checkbox"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={l <- ~w(row col)} value={l} phx-value-k="layout" phx-value-v={l}>
                {l}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">state</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="State"
              value={
                for {k, on} <- [{"error", @checkbox.error}, {"disabled", @checkbox.disabled}],
                    on,
                    do: k
              }
              on_change="ctl_checkbox"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="error" phx-value-k="error">error</:item>
              <:item value="disabled" phx-value-k="disabled">disabled</:item>
            </.toggle_group>
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

      <div
        :for={
          ex <- examples_for(PetalComponents.Showcase.Field, ~w(checkbox_states checkbox_single)a)
        }
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Field} function={:field} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Field</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "aurora"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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

      <div :for={ex <- PetalComponents.Showcase.Aurora.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Aurora} function={:aurora} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Aurora</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "links"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Link} function={:a} />
    </div>
    """
  end

  defp render_page(%{active: "icons"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
              {suffix, size_class, size_label} <- [
                {"", "w-6 h-6", "24px"},
                {"-solid", "w-6 h-6", "24px"},
                {"-mini", "w-5 h-5", "20px"},
                {"-micro", "w-4 h-4", "16px"}
              ]
            }
            class="flex flex-col items-center gap-2"
          >
            <.icon
              name={"hero-star" <> suffix}
              class={[size_class, "text-gray-700 dark:text-gray-300"]}
            />
            <span class="font-mono text-[10px] text-gray-400">hero-star{suffix}</span>
            <span class="text-[10px] text-gray-400">{size_label}</span>
          </div>
        </div>
        <p class="mt-6 text-xs text-center text-gray-400 dark:text-gray-500">
          mini and micro are not scaled-down copies - heroicons redraws them for
          20px and 16px UI, simplifying geometry so they stay crisp at the sizes
          they're named for. Render each at its native size.
        </p>
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

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Icon} function={:heroicon} />
    </div>
    """
  end

  defp render_page(%{active: "menu"} = assigns) do
    ~H"""
    <div class="max-w-4xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props
        component={PetalComponents.Menu}
        functions={[:vertical_menu, :vertical_menu_item, :menu_group]}
      />
    </div>
    """
  end

  defp render_page(%{active: "navigation-menu"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
          <.toggle_group
            variant="outline"
            size="sm"
            aria_label="Trigger"
            value={@nav_trigger}
            on_change="ctl_navmenu"
            class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
          >
            <:item :for={t <- ~w(hover click)} value={t} phx-value-k="trigger" phx-value-v={t}>
              {t}
            </:item>
          </.toggle_group>
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

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props
        component={PetalComponents.NavigationMenu}
        functions={[
          :navigation_menu,
          :navigation_menu_link,
          :navigation_menu_footer,
          :navigation_menu_footer_link
        ]}
      />
    </div>
    """
  end

  defp render_page(%{active: "container"} = assigns) do
    ~H"""
    <div class="max-w-5xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Container} function={:container} />
    </div>
    """
  end

  defp render_page(%{active: "chat"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Variant"
              value={@chat.variant}
              on_change="ctl_chat"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={v <- ~w(plain bubbles)} value={v} phx-value-k="variant" phx-value-v={v}>
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">action bar</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Actions"
              value={@chat.actions}
              on_change="ctl_chat"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={v <- ~w(always hover)} value={v} phx-value-k="actions" phx-value-v={v}>
                {v}
              </:item>
            </.toggle_group>
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

      <div
        :for={ex <- Enum.reject(PetalComponents.Showcase.Chat.examples(), &(&1.id == :flagship))}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props
        component={PetalComponents.Chat}
        functions={[
          :conversation,
          :chat_message,
          :streaming_text,
          :prompt_input,
          :tool_call,
          :markdown,
          :rich_text,
          :reasoning,
          :marker,
          :message_actions,
          :copy_button,
          :suggestions,
          :chat_error
        ]}
      />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Chat isn't pulled in by use PetalComponents - alias PetalComponents.Chat
        and call it namespaced (it owns generic names like markdown). Markdown
        needs the optional :mdex dep. The examples above (the live thread excepted)
        render from the shared <code>PetalComponents.Showcase.Chat</code> registry -
        the same source petal.build renders, so the playground and the marketing docs
        can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "alert"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
              on_dismiss={
                if @alert.dismissible, do: Phoenix.LiveView.JS.dispatch("pg:alert-dismissed")
              }
            >
              Your subscription renews on 12 August.
              <:actions :if={@alert.actions}>
                <.button size="sm" variant="soft">Manage plan</.button>
                <.button size="sm" variant="ghost" color="gray">Remind me later</.button>
              </:actions>
            </.alert>
          </div>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">colour</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Color"
              value={@alert.color}
              on_change="ctl_alert"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={c <- ~w(gray info success warning danger)}
                value={c}
                phx-value-k="color"
                phx-value-v={c}
              >
                {c}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Variant"
              value={@alert.variant}
              on_change="ctl_alert"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={v <- ~w(light soft dark outline callout)}
                value={v}
                phx-value-k="variant"
                phx-value-v={v}
              >
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="Extras"
              value={
                for {k, on} <- [
                      {"icon", @alert.icon},
                      {"heading", @alert.heading},
                      {"dismissible", @alert.dismissible},
                      {"actions", @alert.actions}
                    ],
                    on,
                    do: k
              }
              on_change="ctl_alert"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="icon" phx-value-k="icon">icon</:item>
              <:item value="heading" phx-value-k="heading">heading</:item>
              <:item value="dismissible" phx-value-k="dismissible">dismissible</:item>
              <:item value="actions" phx-value-k="actions">actions</:item>
            </.toggle_group>
            <div :if={@alert.dismissible} class="mt-1.5 text-[10px] text-gray-400">
              dismissing hides it - flip any dial to bring it back
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

      <div :for={ex <- PetalComponents.Showcase.Alert.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Alert} function={:alert} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Alert</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "badge"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
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
            dot={@badge.dot}
            dot_color={@badge.dot_color}
          >
            <.icon :if={@badge.icon} name="hero-sparkles" class="w-3 h-3" /> New
          </.badge>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">colour</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Color"
              value={@badge.color}
              on_change="ctl_badge"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={c <- ~w(primary secondary info success warning danger gray)}
                value={c}
                phx-value-k="color"
                phx-value-v={c}
              >
                {c}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Variant"
              value={@badge.variant}
              on_change="ctl_badge"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item
                :for={v <- ~w(light soft dark outline)}
                value={v}
                phx-value-k="variant"
                phx-value-v={v}
              >
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Size"
              value={@badge.size}
              on_change="ctl_badge"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item :for={z <- ~w(xs sm md lg xl)} value={z} phx-value-k="size" phx-value-v={z}>
                {z}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">extras</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="Extras"
              value={for {k, on} <- [{"icon", @badge.icon}, {"dot", @badge.dot}], on, do: k}
              on_change="ctl_badge"
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="icon" phx-value-k="icon">icon</:item>
              <:item value="dot" phx-value-k="dot">dot</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">dot colour</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Dot color"
              value={@badge.dot_color || "inherit"}
              on_change="ctl_badge"
              disabled={!@badge.dot}
              class="max-w-full overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            >
              <:item value="inherit" phx-value-k="dot_color" phx-value-v="inherit">inherit</:item>
              <:item
                :for={c <- ~w(primary secondary info success warning danger gray)}
                value={c}
                phx-value-k="dot_color"
                phx-value-v={c}
              >
                {c}
              </:item>
            </.toggle_group>
            <div :if={!@badge.dot} class="mt-1.5 text-[10px] text-gray-400">
              dot only
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

      <div :for={ex <- PetalComponents.Showcase.Badge.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Badge} function={:badge} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Badge</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
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
    # Path-based component URLs. Not cosmetic: Fathom drops query strings
    # for privacy, so with only /?c=slug the whole playground aggregates
    # into one path and per-component interest is unmeasurable. /?c= keeps
    # working (same handle_params reads merged path + query params) - every
    # existing link, script and screenshot pipeline stays valid.
    live "/c/:c", Dev.PlaygroundLive
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

  # Dev-only reload machinery, compiled out when PLAYGROUND_DEPLOY=true:
  # Phoenix.CodeReloader re-evaluates this ENTIRE file on every request
  # (~12s each measured) - live_reload: false alone does not disable it,
  # because these plugs are hardcoded here, not derived from that option.
  if System.get_env("PLAYGROUND_DEPLOY") != "true" do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader, reloader: &Dev.Reloader.reload/2
  end

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

# PLAYGROUND_DEPLOY=true is the public deployment (playground.petal.build):
# same file, dev conveniences off. The perf-critical switch lives in
# Dev.Endpoint below, where this flag compiles out Phoenix.CodeReloader -
# that plug re-evaluates this whole file on EVERY request (~12s each).
# Here the flag turns off the live-reload watcher, debug_errors (no
# stacktraces on a public URL) and the Tailwind watcher, requires a real
# signing key, and locks the LiveView websocket origin.
deploy? = System.get_env("PLAYGROUND_DEPLOY") == "true"

secret_key_base =
  if deploy?,
    do: System.fetch_env!("SECRET_KEY_BASE"),
    else: String.duplicate("a", 64)

# Pre-configure endpoint (PhoenixPlayground merges on top of this)
Application.put_env(:phoenix_playground, Dev.Endpoint, secret_key_base: secret_key_base)

# Run initial Tailwind build before starting the server
Mix.Task.run("tailwind", ["petal_dev"])

deploy_endpoint_options =
  if deploy? do
    [
      # The LiveView websocket rejects cross-origin connects; without this the
      # deployed site dead-renders and every dial silently stops working.
      check_origin: [
        "https://playground.petal.build",
        "https://petal-components-demo.fly.dev",
        # Local deploy-mode smoke tests: dev mode's per-request re-eval is
        # slower than browser nav timeouts, so interactions get verified
        # against PLAYGROUND_DEPLOY=true locally - the websocket needs the
        # loopback origin. Harmless in prod: public demo, no auth, no data.
        "http://localhost:#{System.get_env("PORT", "4000")}"
      ],
      url: [host: System.get_env("PHX_HOST", "playground.petal.build"), scheme: "https"]
    ]
  else
    []
  end

PhoenixPlayground.start(
  endpoint: Dev.Endpoint,
  # OPEN_BROWSER=false for headless runs (CI, agents); PORT to avoid clashes
  open_browser: not deploy? and System.get_env("OPEN_BROWSER", "true") != "false",
  port: String.to_integer(System.get_env("PORT", "4000")),
  # Dual-stack: "localhost" resolves to ::1 or 127.0.0.1 depending on the
  # client's Happy Eyeballs mood; a v4-only listener makes the LiveView
  # websocket silently fail on the ::1 pick (dead render, URL params ignored).
  # (Fly's proxy also reaches the app over the v6 private network.)
  ip: {0, 0, 0, 0, 0, 0, 0, 0},
  live_reload: not deploy?,
  endpoint_options:
    deploy_endpoint_options ++
      [
        debug_errors: not deploy?,
        render_errors: [formats: [html: Dev.ErrorHTML], layout: false],
        watchers:
          if deploy? do
            []
          else
            [tailwind: {Tailwind, :install_and_run, [:petal_dev, ~w(--watch)]}]
          end
      ]
)
