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

  # The playground's static assets go out with `cache-control: public` and no
  # max-age, which invites Safari's heuristic caching - the maintainer
  # refreshed an iPhone repeatedly and kept testing a build from BEFORE the
  # deploy. A boot-stamped rev on both asset URLs makes every deploy its own
  # cache key; unchanged files still answer 304 via the ETag.
  # Runtime css mtime, not compile-time: the module only recompiles when
  # dev.exs changes, so a compile-stamped rev left CSS-ONLY edits serving
  # stale sheets out of browser caches (found via a probe browser insisting
  # freshly-shipped rules did not exist).
  defp asset_rev do
    case File.stat(Path.expand("priv/static/assets/app.css", __DIR__)) do
      {:ok, %{mtime: t}} -> t |> :calendar.datetime_to_gregorian_seconds() |> Integer.to_string()
      {:error, _} -> "0"
    end
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
        <meta name="pg-asset-rev" content={asset_rev()} />
        <link rel="stylesheet" href={"/assets/app.css?v=" <> asset_rev()} />
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
          // Dynamic import so the rev can come from the meta tag - HEEx does
          // not interpolate inside script bodies. Top-level await is legal in
          // a module script.
          const rev = document.querySelector('meta[name="pg-asset-rev"]').content;
          const { default: PetalComponents } = await import(
            "/assets/js/petal_components.js?v=" + rev
          );
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

  # A mocked RAG answer: the model cites its context with [^N] footnote markers
  # and the app hands the same source maps to markdown/1 + chat_sources/1.
  @chat_rag_sources [
    %{
      id: "1",
      url: "https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html",
      title: "Phoenix.LiveView — behaviour and lifecycle",
      snippet:
        "LiveView provides rich, real-time user experiences with server-rendered HTML over a persistent connection."
    },
    %{
      id: "2",
      url: "https://hexdocs.pm/phoenix_live_view/js-interop.html",
      title: "JavaScript interoperability",
      snippet:
        "Client hooks let you run JavaScript when an element is added, updated or removed from the page."
    },
    %{
      id: "3",
      url: "https://hexdocs.pm/phoenix/Phoenix.Endpoint.html",
      title: "Phoenix.Endpoint",
      snippet: "The endpoint is the boundary where all requests to your application start."
    },
    %{
      id: "4",
      url: "https://elixir-lang.org/getting-started/processes.html",
      title: "Processes"
    }
  ]

  @chat_rag_answer """
  LiveView holds a **persistent connection** and diffs the rendered tree on the
  server, pushing only the parts that changed [^1]. Anything the server can't
  own - focus, clipboard, a third-party widget - drops down to a client
  hook [^2].

  Requests still enter through the endpoint like any other Phoenix request [^3],
  and each connected tab is just another cheap process [^4].
  """

  # Two-step mocked agent flow: the assistant asks which framework, then what
  # to scaffold. Both round-trip through real handle_event callbacks.
  @q_framework %{
    id: "q-framework",
    title: "Which framework are you targeting?",
    description: "This picks the generators I'll reach for.",
    fields: [
      %{
        id: "framework",
        type: :single_select,
        label: "Framework",
        required: true,
        options: [
          %{value: "phoenix", label: "Phoenix", description: "Elixir, LiveView, server-rendered"},
          %{value: "rails", label: "Rails", description: "Ruby, Hotwire, convention-first"},
          %{value: "next", label: "Next.js", description: "React, app router, RSC"}
        ]
      }
    ]
  }

  @q_scope %{
    id: "q-scope",
    title: "Before I scaffold, two things",
    fields: [
      %{
        id: "features",
        type: :multi_select,
        label: "Which features do you need?",
        options: [
          %{value: "auth", label: "Auth"},
          %{value: "billing", label: "Billing"},
          %{value: "admin", label: "Admin panel"}
        ]
      },
      %{id: "team", type: :text, label: "Team name", placeholder: "Platform"},
      %{
        id: "confidence",
        type: :scale,
        label: "How settled is this scope?",
        min_label: "Still exploring",
        max_label: "Locked",
        required: true
      }
    ]
  }

  # Inline SVG so the attachments example renders with no static asset host.
  @chat_shot_image "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='480' height='300'><rect width='100%25' height='100%25' fill='%23e2e8f0'/><rect x='24' y='24' width='432' height='40' rx='6' fill='%23cbd5e1'/><rect x='24' y='88' width='300' height='16' rx='4' fill='%23cbd5e1'/><rect x='24' y='120' width='240' height='16' rx='4' fill='%23cbd5e1'/><rect x='24' y='176' width='432' height='96' rx='6' fill='%23fecaca'/><text x='40' y='232' font-family='monospace' font-size='18' fill='%23991b1b'>CardTokenExpired</text></svg>"

  # The payloads the mocked agent run inspects. Both are JSON strings, exactly
  # what you hold when a function call streams back - tool_call pretty-prints
  # them server-side.
  @tool_run_input ~s|{"query":"phoenix liveview server-driven tool calls","limit":3,"freshness":"month"}|

  @tool_run_output ~s|{"results":[{"title":"Phoenix.LiveView","url":"https://hexdocs.pm/phoenix_live_view"},{"title":"Streams","url":"https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#stream/4"}],"count":2,"took_ms":842}|

  # A burst mid-run: two done, one failed, one working, one still queued.
  @tool_burst [
    %{
      name: "read_file",
      state: :complete,
      icon: "code",
      duration: "0.1s",
      input: ~s|{"path":"lib/app_web/router.ex"}|,
      output: ~s|{"lines":184,"bytes":6120}|,
      error: nil
    },
    %{
      name: "grep",
      state: :complete,
      icon: "web_search",
      duration: "0.2s",
      input: ~s|{"pattern":"live_session","glob":"lib/**/*.ex"}|,
      output: ~s|{"matches":6,"files":2}|,
      error: nil
    },
    %{
      name: "query_users",
      state: :error,
      icon: "database",
      duration: "0.4s",
      input: ~s|{"sql":"select * from users limit 5"}|,
      output: nil,
      error: "relation users does not exist"
    },
    %{
      name: "run_migrations",
      state: :running,
      icon: "database",
      duration: "2.1s",
      input: nil,
      output: nil,
      error: nil
    },
    %{
      name: "write_file",
      state: :pending,
      icon: "code",
      duration: nil,
      input: nil,
      output: nil,
      error: nil
    }
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
      group: "AI",
      items: [
        %{slug: "design-skill", name: "Design skill", ready: true}
      ]
    },
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
        %{slug: "number-field", name: "Number field", ready: true},
        %{slug: "checkbox", name: "Checkbox", ready: true},
        %{slug: "select", name: "Select", ready: true},
        %{slug: "combo-box", name: "Combobox", ready: true},
        %{slug: "radio", name: "Radio", ready: true},
        %{slug: "switch", name: "Switch", ready: true},
        %{slug: "slider", name: "Slider", ready: true},
        %{slug: "input-otp", name: "Input OTP", ready: true},
        %{slug: "file-upload", name: "File upload", ready: true},
        %{slug: "calendar", name: "Calendar", ready: true},
        %{slug: "date-picker", name: "Date picker", ready: true},
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
        %{slug: "empty", name: "Empty state", ready: true},
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
        %{slug: "sidebar", name: "Sidebar", ready: true},
        %{slug: "menu", name: "Menu", ready: true},
        %{slug: "navigation-menu", name: "Navigation menu", ready: true},
        %{slug: "scrollspy", name: "Scrollspy", ready: true},
        %{slug: "tree", name: "Tree", ready: true},
        %{slug: "user-menu", name: "User menu", ready: true},
        %{slug: "language-select", name: "Language select", ready: true}
      ]
    },
    %{
      group: "Data",
      items: [
        %{slug: "table", name: "Table", ready: true},
        %{slug: "data-table", name: "Data table", ready: true},
        %{slug: "filters", name: "Filters", ready: true},
        %{slug: "chart", name: "Chart", ready: true},
        %{slug: "qr-code", name: "QR code", ready: true},
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
        %{slug: "sortable", name: "Sortable", ready: true},
        %{slug: "collapsible", name: "Collapsible", ready: true},
        %{slug: "kbd", name: "Kbd", ready: true},
        %{slug: "separator", name: "Separator", ready: true},
        %{slug: "timeline", name: "Timeline", ready: true},
        %{slug: "scroll-area", name: "Scroll area", ready: true},
        %{slug: "container", name: "Container", ready: true},
        %{slug: "resizable", name: "Resizable", ready: true}
      ]
    },
    %{
      group: "Overlay",
      items: [
        %{slug: "tooltip", name: "Tooltip", ready: true},
        %{slug: "popover", name: "Popover", ready: true},
        %{slug: "hover-card", name: "Hover card", ready: true},
        %{slug: "modal", name: "Modal", ready: true},
        %{slug: "alert-dialog", name: "Alert dialog", ready: true},
        %{slug: "dropdown", name: "Dropdown", ready: true},
        %{slug: "context-menu", name: "Context menu", ready: true},
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

  # Dev-only: renders the skill-arm eval artifact with the full stylesheet for
  # eval-t1 stays out of deploy nav but must stay routable there - the
  # cold-start pair's "view the after side live" link points at it.
  @slugs Enum.uniq(Enum.flat_map(@nav, fn g -> Enum.map(g.items, & &1.slug) end) ++ ["eval-t1"])
  # the whitelist both filter-bar demos decode against - link mode's
  # from_params and event mode's handle_op take the same list
  @filters_fields [:name, :category, :price, :in_stock, :added_on]
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

  # The control-rail chrome, in ONE place: the strip's radius rail and every
  # per-page dial rail read this. The lining-nums episode is why - 155
  # verbatim copies were only sweepable en masse because none had drifted
  # yet; the first drifted rail would silently miss every future sweep.
  # (A wrapper component would have to forward toggle_group's :item slot,
  # which Phoenix components don't do cleanly - the shared attr is the fix.)
  @rail_class "max-w-full lining-nums overflow-x-auto overflow-y-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"

  # Type dials - the Typeset curated set, {slug, label, css_stack}. Every
  # stack ends in the matching system tail so the preview renders exactly
  # what Get Code emits. "system" is the shipped default and writes no
  # token at all (the URL elides it, like every other dial default).
  # Faces are vendored in dev/static/fonts (see dev/fetch_fonts.sh).
  @sans_tail ~s(ui-sans-serif, system-ui, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji")
  @serif_tail ~s(ui-serif, Georgia, Cambria, "Times New Roman", Times, serif)
  @mono_tail ~s(ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace)

  # The curated set, grouped the way the selects present it. slug == the
  # Fontsource id for every pick (the classic gotcha - Geist Sans is `geist`,
  # not `geist-sans` - holds), and weight ranges are per-family reality
  # verified via api.fontsource.org, consumed by Get Code's @font-face
  # emission - a blanket "100 900" lies for half of them. dev/fetch_fonts.sh
  # and dev/fonts.css are generated from this table; keep the three in sync.
  @font_groups [
    {"Sans", @sans_tail,
     [
       {"inter", "Inter", "100 900"},
       {"geist", "Geist", "100 900"},
       {"manrope", "Manrope", "200 800"},
       {"space-grotesk", "Space Grotesk", "300 700"},
       {"dm-sans", "DM Sans", "100 1000"},
       {"figtree", "Figtree", "300 900"},
       {"outfit", "Outfit", "100 900"},
       {"public-sans", "Public Sans", "100 900"},
       {"nunito-sans", "Nunito Sans", "200 1000"},
       {"montserrat", "Montserrat", "100 900"},
       {"ibm-plex-sans", "IBM Plex Sans", "100 700"},
       {"source-sans-3", "Source Sans 3", "200 900"}
     ]},
    {"Serif", @serif_tail,
     [
       {"fraunces", "Fraunces", "100 900"},
       {"source-serif-4", "Source Serif 4", "200 900"},
       {"lora", "Lora", "400 700"},
       {"merriweather", "Merriweather", "300 900"},
       {"newsreader", "Newsreader", "200 800"},
       {"playfair-display", "Playfair Display", "400 900"},
       {"roboto-slab", "Roboto Slab", "100 900"}
     ]},
    {"Mono", @mono_tail,
     [
       {"jetbrains-mono", "JetBrains Mono", "100 800"},
       {"geist-mono", "Geist Mono", "100 900"},
       {"fira-code", "Fira Code", "300 700"},
       {"source-code-pro", "Source Code Pro", "200 900"},
       {"roboto-mono", "Roboto Mono", "100 700"}
     ]}
  ]

  # Every role offers the whole catalogue (a mono heading is a legitimate
  # look); shuffle draws from tasteful pools instead - heading/body from
  # sans + serif, mono from mono - so the dice stay kind while hand-picking
  # stays free. System sits in every pool: an honest shuffle can land on
  # "what if we just didn't".
  @font_select_options [
    {"System", "system"}
    | Enum.map(@font_groups, fn {group, _tail, fonts} ->
        {group, Enum.map(fonts, fn {slug, label, _w} -> {label, slug} end)}
      end)
  ]

  @font_stacks Map.new(
                 for {_g, tail, fonts} <- @font_groups, {slug, label, _w} <- fonts,
                   do: {slug, ~s("#{label}", ) <> tail}
               )
  @font_labels Map.new(
                 for {_g, _t, fonts} <- @font_groups, {slug, label, _w} <- fonts, do: {slug, label}
               )
  @font_weights Map.new(
                  for {_g, _t, fonts} <- @font_groups, {slug, _l, wght} <- fonts, do: {slug, wght}
                )
  @font_names ["system" | Map.keys(@font_labels)]
  @shuffle_text_pool [
    "system"
    | for({g, _t, fonts} <- @font_groups, g != "Mono", {slug, _l, _w} <- fonts, do: slug)
  ]
  @shuffle_mono_pool [
    "system" | for({g, _t, fonts} <- @font_groups, g == "Mono", {slug, _l, _w} <- fonts, do: slug)
  ]

  @input_types ~w(text email password search date time select textarea file color)

  @qr_presets ~w(url totp wifi custom)
  @qr_preset_values %{
    "url" => "https://petal.build",
    "totp" => "otpauth://totp/Petal:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Petal",
    "wifi" => "WIFI:T:WPA;S:MyNetwork;P:secret;;"
  }

  @alert_colors ~w(gray info success warning danger)
  @badge_colors ~w(primary secondary info success warning danger gray)
  @tint_variants ~w(light soft dark outline callout)

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       nav: @nav,
       primaries: @primaries,
       grays: @grays,
       secondaries: @secondaries,
       tw_palette: @tw_palette,
       radii: @radii,
       font_select_options: @font_select_options,
       # @ in HEEx reads assigns, not module attributes - bridge the rail
       # chrome through here so templates can say class={@rail_class}.
       rail_class: @rail_class,
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
       alert_dialog: %{variant: "default", media: "none", description: "with", length: "short"},
       alert_dialog_result: nil,
       alert_dialog_rows: [1, 3],
       chat_rag_sources: @chat_rag_sources,
       chat_shot_image: @chat_shot_image,
       tool_run_input: @tool_run_input,
       tool_run_output: @tool_run_output,
       tool_burst: @tool_burst,
       q_framework: @q_framework,
       q_scope: @q_scope,
       quiz: %{
         # nil until answered; then the answer map or :skipped
         framework: nil,
         scope: nil,
         asked_scope: false,
         submitting: false,
         # dial state for the standalone demo below the flow
         field: "single_cards",
         allow_skip: true,
         state: "pending"
       },
       tool: %{
         # dials for the single-card demo
         state: :complete,
         compact: false,
         icon: "web_search",
         # the mocked agent run: nil while idle, otherwise the live state
         run_state: nil,
         run_duration: nil,
         run_outcome: :success,
         # bumped per run so a finished card is a fresh DOM node
         run_seq: 0
       },
       chat: %{
         turns: [
           %{id: "m-today", role: :marker, text: "Today"},
           %{
             id: "seed-q",
             role: :user,
             text: "How do I install petal_components?",
             stream_id: nil
           },
           %{id: "seed-a", role: :assistant, text: @chat_seed_answer, stream_id: nil},
           %{
             id: "seed-rag-q",
             role: :user,
             text: "How does LiveView keep the page in sync?",
             stream_id: nil
           },
           %{
             id: "seed-rag-a",
             role: :assistant,
             text: @chat_rag_answer,
             stream_id: nil,
             sources: @chat_rag_sources
           }
         ],
         streaming: false,
         seq: 1,
         history: false,
         variant: "plain",
         actions: "always",
         editing: nil,
         sent: false,
         sources_expanded: false,
         sources_max: 5,
         rag_streaming: false,
         attach_hint: true,
         attach_limit: "5mb"
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
       rsz: %{orientation: "horizontal", with_handle: true, collapsible: true},
       rsz_sizes: [65, 35],
       rich: %{labels: ~w(feat bug imp des), team: ~w(amelia jonah)},
       kbd: %{size: "md", separator: "+"},
       separator: %{orientation: "horizontal", label_position: "center", decorative: true},
       collapsible: %{open: false, disabled: false},
       dt: PetalComponents.DataTable.State |> struct(page_size: 5) |> run_dt(),
       qr: %{
         preset: "url",
         value: "https://petal.build",
         size: "md",
         ec: "m",
         rounded: "0",
         logo: false,
         surface: "light"
       },
       dt_selected: [],
       dt_hidden: [],
       dt_order: [],
       dt_refunded: [],
       # the filter bar demo: one State shared with a data table (event mode),
       # plus the registered field types the dials switch on and off
       filters_state: run_filters(%PetalComponents.DataTable.State{page_size: 5}),
       filters_types: ~w(text select number_range boolean date_range),
       radio: %{
         style: "cards",
         variant: "outline",
         size: "md",
         layout: "row",
         indicator: false,
         ind_pos: "end",
         disabled: false
       },
       switch: %{size: "md", variant: "default", disabled: false, error: false},
       modal: %{
         max_width: "sm",
         header: true,
         close: true,
         dismiss: true,
         footer: "actions",
         content: "short"
       },
       slider: %{
         mode: "single",
         show_value: "inline",
         orientation: "horizontal",
         step: 1,
         size: "md",
         marks: false,
         disabled: false
       },
       slider_price: to_form(%{"min" => "250", "max" => "750"}, as: :pg_price),
       slider_volume: 60,
       slider_year: 2010,
       otp: %{length: 6, grouped: false, pattern: "numeric", disabled: false},
       number: %{variant: "stacked", size: "md", bounds: "qty", disabled: false},
       sortable: %{
         handle: true,
         orientation: "vertical",
         disabled: false,
         # the server IS the order: the hook reorders optimistically, this
         # list is what the next render paints from
         todos: [
           %{id: "release", title: "Cut the 4.1 release build", locked: false},
           %{id: "changelog", title: "Write the changelog", locked: false},
           %{id: "docs", title: "Update the docs site", locked: false},
           %{id: "invoices", title: "Send the March invoices", locked: true},
           %{id: "standup", title: "Prep Monday standup", locked: false}
         ],
         photos: [
           %{id: "harbour", title: "Harbour at dawn", tone: "from-sky-400 to-indigo-500"},
           %{id: "ridge", title: "Ridge line", tone: "from-emerald-400 to-teal-600"},
           %{id: "salt", title: "Salt flats", tone: "from-amber-300 to-orange-500"},
           %{id: "pines", title: "Pines in fog", tone: "from-slate-400 to-slate-700"},
           %{id: "dunes", title: "Dunes", tone: "from-rose-400 to-pink-600"},
           %{id: "estuary", title: "Estuary", tone: "from-violet-400 to-purple-600"}
         ],
         log: []
       },
       cal: %{mode: "single", starts_on: 1, outside: true, window: false, size: "2.25rem"},
       cal_month: Date.beginning_of_month(Date.utc_today()),
       cal_single: Date.utc_today(),
       cal_range: {nil, nil},
       cal_multi: [],
       picker: %{mode: "range", two_months: true, clearable: true},
       pick_stay: {Date.utc_today(), Date.add(Date.utc_today(), 4)},
       # The flagship's single value starts EMPTY on purpose: its help text
       # invites typing, and the old seed (a 1987 birthday) sat before the
       # flagship's own min={Date.utc_today()} - a date the calendar itself
       # would refuse. The wired birthday example below keeps its own seed.
       pick_single: nil,
       pick_month: nil,
       pick_birthday: ~D[1987-06-12],
       pick_deadline: nil,
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
       scroll: %{orientation: "vertical", fade: "off", gutter: "auto", visibility: "auto"},
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
       drawer: %{handle: true, drag: true, snaps: "off", scale: false},
       empty: %{variant: "default", size: "md", actions: "primary"},
       slideover: %{origin: "right", width: "sm"},
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
       tree: %{
         guides: true,
         row_expand: true,
         expand: "first",
         picked: nil,
         # the file explorer scenario runs the server-controlled model
         expanded: MapSet.new(["lib", "petal_components"]),
         opened: "tree.ex",
         loaded: %{},
         # the settings nav scenario, same model, different data
         settings_expanded: MapSet.new(["workspace"]),
         settings_page: "members"
       },
       sidebar: %{
         collapsible: "icon",
         side: "left",
         collapsed: false,
         badges: true
       },
       stepper: %{
         orientation: "horizontal",
         size: "md",
         variant: "circles",
         labels: "beside",
         at: 0,
         done: false
       },
       timeline: %{
         variant: "default",
         orientation: "vertical",
         marker: "icon",
         connector: "solid",
         time_placement: "top",
         states: true
       },
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
       hover_card: %{placement: "bottom", open_delay: 350, close_delay: 150},
       scrollspy: %{offset: "6rem", nested: false, indicator: "bar"},
       context_menu: %{disabled: false},
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
       },
       file_upload: %{
         variant: "dropzone",
         max_entries: 4,
         saved: [],
         # Stand-ins for photos already on the listing: rows in a database with
         # a URL each, which is what an edit form actually starts from.
         photos: [
           %{id: "forest", name: "forest.jpg", url: "/dev-static/carousel/forest.jpg"},
           %{id: "code", name: "workspace.jpg", url: "/dev-static/carousel/code.jpg"}
         ]
       }
     )
     |> allow_pg_uploads(4)
     |> allow_upload(:chat_attachments,
       accept: ~w(.png .jpg .jpeg .pdf),
       max_entries: 4,
       max_file_size: 5_000_000
     )}
  end

  # The file-upload page runs on real LiveView uploads, not a mock. Drag and
  # drop, progress and cancel only exist because allow_upload/3 is wired here.
  @pg_hero_accept ~w(.png .jpg .jpeg .gif .pdf)

  defp allow_pg_uploads(socket, max_entries) do
    socket
    |> allow_upload(:pg_files,
      accept: @pg_hero_accept,
      max_entries: max_entries,
      max_file_size: 8_000_000,
      auto_upload: true
    )
    |> allow_upload(:pg_auto, accept: :any, max_entries: 3, auto_upload: true)
    |> allow_upload(:pg_manual, accept: :any, max_entries: 3)
    |> allow_upload(:pg_avatar,
      accept: ~w(.png .jpg .jpeg),
      max_entries: 1,
      max_file_size: 2_000_000,
      auto_upload: true
    )
    |> allow_upload(:pg_gallery,
      accept: ~w(.png .jpg .jpeg .webp),
      max_entries: 6,
      auto_upload: true
    )
    # A deliberately tiny cap so visitors can trip :too_large on purpose.
    |> allow_upload(:pg_small,
      accept: ~w(.pdf .png .jpg),
      max_entries: 3,
      max_file_size: 20_000,
      auto_upload: true
    )
  end

  # Theme state lives in the URL, so any look is shareable / screenshotable.
  def handle_params(params, uri, socket) do
    # PhoenixPlayground's dead render hands handle_params only the PATH
    # params - the query string arrives solely in uri - so a shared theme
    # link used to paint the defaults first and correct itself on the
    # connected mount (a visible flash, and a wall for headless capture,
    # which never sees the connected state). Decode the query from uri and
    # let params win, so the dials are right on first paint; on connected
    # patches params already carry the query and the merge is a no-op.
    params = Map.merge(query_params(uri), params)

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
      |> assign(:font_heading, allow(params["heading"], @font_names, "system"))
      |> assign(:font_body, allow(params["body"], @font_names, "system"))
      |> assign(:font_mono, allow(params["mono"], @font_names, "system"))
      |> assign(:lang, allow(params["locale"], @locale_codes, "en"))
      |> assign(:dark, false)
      # Any navigation (sidebar, overlay menu, cmdk) lands here - close the
      # mobile menu so picking a component reveals it immediately.
      |> assign(:nav_open, false)
      |> assign_base_url(uri)
      |> maybe_run_dt_link(params, uri)
      |> maybe_run_filters_link(params, uri)

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
    params = Map.merge(query_params(uri), params)

    state = State.from_params(params, fields: [:name, :email, :status, :amount])
    assign(socket, :dt_link, run_dt(state))
  end

  defp maybe_run_dt_link(socket, _params, _uri), do: socket

  # The filter page's third example: link mode, where the URL IS the filter
  # state. Same decode as the data table's link page - the query string is
  # the only place the filters live, so a shared or curled URL renders the
  # right rows on first paint and the back button walks the history.
  defp maybe_run_filters_link(%{assigns: %{active: "filters"}} = socket, params, uri) do
    alias PetalComponents.DataTable.State

    # The raw query string is also state here: it is what the page shows
    # as the shareable link, so keep it beside the decoded params.
    query = uri |> URI.parse() |> Map.get(:query) || ""
    params = Map.merge(query_params(uri), params)
    state = State.from_params(params, fields: @filters_fields)

    socket
    |> assign(:filters_link, run_filters(state))
    |> assign(:filters_query, query)
  end

  defp maybe_run_filters_link(socket, _params, _uri), do: socket

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

  def handle_event("set_font_heading", %{"heading" => v}, socket),
    do: patch_theme(socket, %{font_heading: v})

  def handle_event("set_font_body", %{"body" => v}, socket),
    do: patch_theme(socket, %{font_body: v})

  def handle_event("set_font_mono", %{"mono" => v}, socket),
    do: patch_theme(socket, %{font_mono: v})

  def handle_event("font_shuffle", _params, socket) do
    patch_theme(socket, %{
      font_heading: Enum.random(@shuffle_text_pool),
      font_body: Enum.random(@shuffle_text_pool),
      font_mono: Enum.random(@shuffle_mono_pool)
    })
  end

  def handle_event("font_reset", _params, socket),
    do: patch_theme(socket, %{font_heading: "system", font_body: "system", font_mono: "system"})

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

  def handle_event("ctl_file_upload", %{"k" => "variant", "v" => v}, socket)
      when v in ~w(dropzone compact avatar gallery),
      do: {:noreply, update(socket, :file_upload, &%{&1 | variant: v})}

  # max_entries is baked into the config at allow_upload/3 time, so changing
  # it means dropping the config and re-allowing it.
  def handle_event("ctl_file_upload", %{"k" => "max", "v" => v}, socket)
      when v in ~w(1 4 8) do
    n = String.to_integer(v)

    socket =
      socket
      |> disallow_upload(:pg_files)
      |> allow_upload(:pg_files,
        accept: @pg_hero_accept,
        max_entries: n,
        max_file_size: 8_000_000,
        auto_upload: true
      )
      |> update(:file_upload, &%{&1 | max_entries: n, saved: []})

    {:noreply, socket}
  end

  # Every upload form on the page posts here; entries only reach the server
  # because the form carries phx-change.
  def handle_event("pg_upload_validate", _params, socket), do: {:noreply, socket}

  # One cancel handler for all six demo configs. The suffix names the config
  # and the guard keeps the atom lookup bounded to what mount already allowed.
  def handle_event("pg_upload_cancel_" <> which, %{"ref" => ref}, socket)
      when which in ~w(files auto manual avatar gallery small),
      do: {:noreply, cancel_upload(socket, String.to_existing_atom("pg_" <> which), ref)}

  # A saved photo is a record, not an upload entry, so removing one is the
  # page's own event and cancel_upload/3 never enters into it.
  def handle_event("pg_photo_remove", %{"id" => id}, socket) do
    {:noreply,
     update(socket, :file_upload, fn fu ->
       %{fu | photos: Enum.reject(fu.photos, &(&1.id == id))}
     end)}
  end

  def handle_event("pg_upload_save", _params, socket) do
    names =
      consume_uploaded_entries(socket, :pg_files, fn _meta, entry ->
        # Nothing is written to disk - the playground only proves the entries
        # made the round trip and were consumed.
        {:ok, entry.client_name}
      end)

    {:noreply, update(socket, :file_upload, &%{&1 | saved: names})}
  end

  def handle_event("flip", %{"k" => "loading"}, socket),
    do: {:noreply, update(socket, :loading, &(!&1))}

  def handle_event("flip", %{"k" => "disabled"}, socket),
    do: {:noreply, update(socket, :disabled, &(!&1))}

  def handle_event("flip", %{"k" => "show_code"}, socket),
    do: {:noreply, update(socket, :show_code, &(!&1))}

  def handle_event("flip", %{"k" => "qr_logo"}, socket),
    do: {:noreply, update(socket, :qr, &%{&1 | logo: !&1.logo})}

  # QR code dials. The content preset swaps the encoded value too, so the code
  # in the hero is always really encoding whatever the preset says.
  def handle_event("ctl_qr", %{"k" => "preset", "v" => v}, socket) when v in @qr_presets,
    do: {:noreply, update(socket, :qr, &%{&1 | preset: v, value: qr_preset_value(v, &1.value)})}

  def handle_event("ctl_qr", %{"k" => "size", "v" => v}, socket) when v in ~w(sm md lg xl),
    do: {:noreply, update(socket, :qr, &%{&1 | size: v})}

  def handle_event("ctl_qr", %{"k" => "ec", "v" => v}, socket) when v in ~w(l m q h),
    do: {:noreply, update(socket, :qr, &%{&1 | ec: v})}

  def handle_event("ctl_qr", %{"k" => "rounded", "v" => v}, socket) when v in ~w(0 0.5 1),
    do: {:noreply, update(socket, :qr, &%{&1 | rounded: v})}

  def handle_event("ctl_qr", %{"k" => "surface", "v" => v}, socket) when v in ~w(light dark),
    do: {:noreply, update(socket, :qr, &%{&1 | surface: v})}

  def handle_event("ctl_qr_value", %{"pg_qr_value" => value}, socket),
    do: {:noreply, update(socket, :qr, &%{&1 | preset: "custom", value: value})}

  def handle_event("ctl_input", %{"k" => "type", "v" => v}, socket) when v in @input_types,
    do: {:noreply, update(socket, :input, &%{&1 | type: v})}

  def handle_event("ctl_input", %{"k" => k}, socket) when k in ~w(disabled error help),
    do:
      {:noreply,
       update(socket, :input, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  # Restored from feat/kbd-separator-collapsible - the omnibus --theirs wipe
  # ate this whole handler block; the dials referenced them into the void.
  def handle_event("ctl_kbd", %{"k" => k, "v" => v}, socket) when k in ~w(size separator),
    do: {:noreply, update(socket, :kbd, &Map.put(&1, String.to_existing_atom(k), v))}

  def handle_event("ctl_separator", %{"k" => k, "v" => v}, socket)
      when k in ~w(orientation label_position),
      do: {:noreply, update(socket, :separator, &Map.put(&1, String.to_existing_atom(k), v))}

  def handle_event("ctl_separator", %{"k" => "decorative"}, socket),
    do: {:noreply, update(socket, :separator, &%{&1 | decorative: !&1.decorative})}

  def handle_event("ctl_collapsible", %{"k" => k}, socket) when k in ~w(open disabled),
    do:
      {:noreply,
       update(socket, :collapsible, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

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

  def handle_event("ctl_scroll", %{"k" => "orientation", "v" => v}, socket)
      when v in ~w(vertical horizontal both),
      do: {:noreply, update(socket, :scroll, &%{&1 | orientation: v})}

  def handle_event("ctl_scroll", %{"k" => "fade", "v" => v}, socket) when v in ~w(off on),
    do: {:noreply, update(socket, :scroll, &%{&1 | fade: v})}

  def handle_event("ctl_scroll", %{"k" => "gutter", "v" => v}, socket) when v in ~w(auto stable),
    do: {:noreply, update(socket, :scroll, &%{&1 | gutter: v})}

  def handle_event("ctl_scroll", %{"k" => "visibility", "v" => v}, socket)
      when v in ~w(auto always),
      do: {:noreply, update(socket, :scroll, &%{&1 | visibility: v})}

  def handle_event("ctl_alert_dialog", %{"k" => "variant", "v" => v}, socket)
      when v in ~w(default destructive),
      do: {:noreply, update(socket, :alert_dialog, &%{&1 | variant: v})}

  def handle_event("ctl_alert_dialog", %{"k" => "media", "v" => v}, socket)
      when v in ~w(none icon image),
      do: {:noreply, update(socket, :alert_dialog, &%{&1 | media: v})}

  def handle_event("ctl_alert_dialog", %{"k" => "description", "v" => v}, socket)
      when v in ~w(with without),
      do: {:noreply, update(socket, :alert_dialog, &%{&1 | description: v})}

  def handle_event("ctl_alert_dialog", %{"k" => "length", "v" => v}, socket)
      when v in ~w(short long),
      do: {:noreply, update(socket, :alert_dialog, &%{&1 | length: v})}

  def handle_event("alert_dialog_answer", %{"answer" => answer}, socket),
    do: {:noreply, assign(socket, :alert_dialog_result, answer)}

  def handle_event("alert_dialog_toggle_row", %{"row" => row}, socket) do
    row = String.to_integer(row)

    {:noreply,
     update(socket, :alert_dialog_rows, fn rows ->
       if row in rows, do: rows -- [row], else: Enum.sort([row | rows])
     end)}
  end

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

  def handle_event("ctl_drawer", %{"k" => "snaps", "v" => v}, socket) when v in ~w(off 0.4-0.9),
    do: {:noreply, update(socket, :drawer, &%{&1 | snaps: v})}

  def handle_event("ctl_drawer", %{"k" => k, "v" => v}, socket)
      when k in ~w(handle drag scale) and v in ~w(on off),
      do: {:noreply, update(socket, :drawer, &Map.put(&1, String.to_existing_atom(k), v == "on"))}

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

  def handle_info({:chat_rag_tick, buffer, []}, socket) do
    {:noreply,
     socket
     |> assign(:chat, %{socket.assigns.chat | rag_streaming: false})
     |> push_event("pc-chat-rag-token", %{
       id: "pg-chat-rag-stream",
       html: Chat.to_html(buffer, sources: @chat_rag_sources)
     })}
  end

  def handle_info({:chat_rag_tick, buffer, [word | rest]}, socket) do
    buffer = if buffer == "", do: word, else: buffer <> " " <> word
    Process.send_after(self(), {:chat_rag_tick, buffer, rest}, 60)

    {:noreply,
     push_event(socket, "pc-chat-rag-token", %{
       id: "pg-chat-rag-stream",
       html: Chat.to_html(buffer, sources: @chat_rag_sources)
     })}
  end

  # The lazy branch's children finally arriving. In a real app this is the
  # reply from a query or an API call; here it is a 900ms delay so the
  # :loading row is actually visible.
  def handle_info({:tree_loaded, id}, socket) do
    {:noreply,
     update(socket, :tree, fn tree ->
       %{tree | loaded: Map.put(tree.loaded, id, tree_lazy_children(id))}
     end)}
  end

  # Each step is one assign patch. The card re-renders into the next state -
  # that is the entire server-driven contract the component asks for.
  def handle_info({:tool_step, :input_streaming}, socket) do
    Process.send_after(self(), {:tool_step, :running}, 1100)
    {:noreply, assign(socket, :tool, %{socket.assigns.tool | run_state: :input_streaming})}
  end

  def handle_info({:tool_step, :running}, socket) do
    Process.send_after(self(), {:tool_step, :settled}, 1600)
    {:noreply, assign(socket, :tool, %{socket.assigns.tool | run_state: :running})}
  end

  def handle_info({:tool_step, :settled}, socket) do
    tool = socket.assigns.tool
    final = if tool.run_outcome == :error, do: :error, else: :complete
    {:noreply, assign(socket, :tool, %{tool | run_state: final, run_duration: "3.6s"})}
  end

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

  def handle_event("ctl_sidebar", %{"k" => "collapsible", "v" => v}, socket)
      when v in ~w(icon offcanvas none),
      do: {:noreply, update(socket, :sidebar, &%{&1 | collapsible: v})}

  def handle_event("ctl_sidebar", %{"k" => "side", "v" => v}, socket) when v in ~w(left right),
    do: {:noreply, update(socket, :sidebar, &%{&1 | side: v})}

  def handle_event("ctl_sidebar", %{"k" => "collapsed"}, socket),
    do: {:noreply, update(socket, :sidebar, &%{&1 | collapsed: !&1.collapsed})}

  def handle_event("ctl_sidebar", %{"k" => "badges"}, socket),
    do: {:noreply, update(socket, :sidebar, &%{&1 | badges: !&1.badges})}

  def handle_event("ctl_tree", %{"k" => "guides"}, socket),
    do: {:noreply, update(socket, :tree, &%{&1 | guides: !&1.guides})}

  def handle_event("ctl_tree", %{"k" => "row_expand"}, socket),
    do: {:noreply, update(socket, :tree, &%{&1 | row_expand: !&1.row_expand})}

  def handle_event("ctl_tree", %{"k" => "expand", "v" => v}, socket) when v in ~w(none first all),
    do: {:noreply, update(socket, :tree, &%{&1 | expand: v})}

  # The dial tree runs the client-side model, so the server never hears about
  # expansion - only about the node the user chose.
  def handle_event("tree_pick", %{"id" => id}, socket),
    do: {:noreply, update(socket, :tree, &%{&1 | picked: id})}

  # The file explorer runs the server-controlled model: this is the entire
  # backend for it, plus the lazy fetch below.
  def handle_event("tree_toggle", %{"id" => id}, socket) do
    tree = socket.assigns.tree
    opening? = not MapSet.member?(tree.expanded, id)

    # a lazy branch has no children until we go and get them
    if opening? and id in tree_lazy_ids() and not Map.has_key?(tree.loaded, id),
      do: Process.send_after(self(), {:tree_loaded, id}, 900)

    {:noreply, assign(socket, :tree, %{tree | expanded: toggle_member(tree.expanded, id)})}
  end

  def handle_event("tree_open", %{"id" => id}, socket),
    do: {:noreply, update(socket, :tree, &%{&1 | opened: id})}

  def handle_event("settings_toggle", %{"id" => id}, socket),
    do:
      {:noreply,
       update(socket, :tree, &%{&1 | settings_expanded: toggle_member(&1.settings_expanded, id)})}

  def handle_event("settings_pick", %{"id" => id}, socket),
    do: {:noreply, update(socket, :tree, &%{&1 | settings_page: id})}

  def handle_event("ctl_stepper", %{"k" => "orientation", "v" => v}, socket)
      when v in ~w(horizontal vertical),
      do: {:noreply, update(socket, :stepper, &%{&1 | orientation: v})}

  def handle_event("ctl_stepper", %{"k" => "size", "v" => v}, socket) when v in ~w(xs sm md lg),
    do: {:noreply, update(socket, :stepper, &%{&1 | size: v})}

  def handle_event("ctl_stepper", %{"k" => "variant", "v" => v}, socket)
      when v in ~w(circles bars),
      do: {:noreply, update(socket, :stepper, &%{&1 | variant: v})}

  # "none" isn't a label_placement - it strips name and description from the
  # step maps, which is how a label-less stepper is built.
  def handle_event("ctl_stepper", %{"k" => "labels", "v" => v}, socket)
      when v in ~w(beside bottom none),
      do: {:noreply, update(socket, :stepper, &%{&1 | labels: v})}

  def handle_event("ctl_timeline", %{"k" => "variant", "v" => v}, socket)
      when v in ~w(default alternating compact),
      do: {:noreply, update(socket, :timeline, &%{&1 | variant: v})}

  def handle_event("ctl_timeline", %{"k" => "orientation", "v" => v}, socket)
      when v in ~w(vertical horizontal),
      do: {:noreply, update(socket, :timeline, &%{&1 | orientation: v})}

  def handle_event("ctl_timeline", %{"k" => "marker", "v" => v}, socket)
      when v in ~w(dot icon avatar number),
      do: {:noreply, update(socket, :timeline, &%{&1 | marker: v})}

  def handle_event("ctl_timeline", %{"k" => "connector", "v" => v}, socket)
      when v in ~w(solid dashed),
      do: {:noreply, update(socket, :timeline, &%{&1 | connector: v})}

  def handle_event("ctl_timeline", %{"k" => "time_placement", "v" => v}, socket)
      when v in ~w(top start),
      do: {:noreply, update(socket, :timeline, &%{&1 | time_placement: v})}

  def handle_event("ctl_timeline", %{"k" => "states"}, socket),
    do: {:noreply, update(socket, :timeline, &%{&1 | states: !&1.states})}

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

  def handle_event("ctl_context_menu", %{"k" => "disabled"}, socket),
    do: {:noreply, update(socket, :context_menu, &%{&1 | disabled: !&1.disabled})}

  @hover_card_placements ~w(top top-start top-end bottom bottom-start bottom-end left left-start left-end right right-start right-end)

  def handle_event("ctl_hover_card", %{"k" => "placement", "v" => v}, socket)
      when v in @hover_card_placements,
      do: {:noreply, update(socket, :hover_card, &%{&1 | placement: v})}

  def handle_event("ctl_hover_card", %{"k" => "open_delay", "v" => v}, socket)
      when v in ~w(0 350 700),
      do: {:noreply, update(socket, :hover_card, &%{&1 | open_delay: String.to_integer(v)})}

  def handle_event("ctl_hover_card", %{"k" => "close_delay", "v" => v}, socket)
      when v in ~w(0 150 500),
      do: {:noreply, update(socket, :hover_card, &%{&1 | close_delay: String.to_integer(v)})}

  def handle_event("ctl_scrollspy", %{"k" => "offset", "v" => v}, socket)
      when v in ~w(2rem 6rem 12rem),
      do: {:noreply, update(socket, :scrollspy, &%{&1 | offset: v})}

  def handle_event("ctl_scrollspy", %{"k" => "indicator", "v" => v}, socket)
      when v in ~w(bar none),
      do: {:noreply, update(socket, :scrollspy, &%{&1 | indicator: v})}

  def handle_event("ctl_scrollspy", %{"k" => "nested"}, socket),
    do: {:noreply, update(socket, :scrollspy, &%{&1 | nested: !&1.nested})}

  def handle_event("ctl_otp", %{"k" => "length", "v" => v}, socket) when v in ~w(4 6),
    do: {:noreply, update(socket, :otp, &%{&1 | length: String.to_integer(v)})}

  def handle_event("ctl_otp", %{"k" => "pattern", "v" => v}, socket)
      when v in ~w(numeric alphanumeric),
      do: {:noreply, update(socket, :otp, &%{&1 | pattern: v})}

  def handle_event("ctl_otp", %{"k" => k}, socket) when k in ~w(grouped disabled),
    do:
      {:noreply,
       update(socket, :otp, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  def handle_event("ctl_sortable", %{"k" => "orientation", "v" => v}, socket)
      when v in ~w(vertical grid),
      do: {:noreply, update(socket, :sortable, &%{&1 | orientation: v})}

  def handle_event("ctl_sortable", %{"k" => k}, socket) when k in ~w(handle disabled),
    do:
      {:noreply,
       update(socket, :sortable, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  # The whole server-truth story in one handler. The hook already moved the
  # DOM optimistically and pushed this; we move the list the same way, so the
  # next render agrees with what is on screen and the patch is a visual no-op.
  # Place by id, not by index - `from` is only a sanity check, because under
  # concurrency it can be stale while the id never is.
  def handle_event("pg_sortable", %{"id" => id, "from" => from, "to" => to}, socket)
      when is_integer(from) and is_integer(to) do
    {:noreply,
     update(socket, :sortable, fn s ->
       key = if s.orientation == "grid", do: :photos, else: :todos
       items = Map.fetch!(s, key)

       case Enum.find_index(items, &(&1.id == id)) do
         nil ->
           s

         index ->
           item = Enum.at(items, index)
           moved = items |> List.delete_at(index) |> List.insert_at(to, item)
           entry = "#{item.title}: #{index + 1} -> #{to + 1}"

           s |> Map.put(key, moved) |> Map.put(:log, Enum.take([entry | s.log], 5))
       end
     end)}
  end

  def handle_event("ctl_rsz", %{"k" => "orientation", "v" => v}, socket)
      when v in ~w(horizontal vertical),
      do: {:noreply, update(socket, :rsz, &%{&1 | orientation: v})}

  def handle_event("ctl_rsz", %{"k" => k}, socket) when k in ~w(with_handle collapsible),
    do:
      {:noreply,
       update(socket, :rsz, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  # The persistence hook point: on_resize pushes the released percentages here.
  # A real app would stash these in the session, the URL or localStorage - the
  # library itself stores nothing.
  def handle_event("pg_resize", %{"sizes" => sizes}, socket),
    do: {:noreply, assign(socket, :rsz_sizes, Enum.map(sizes, &round/1))}

  def handle_event("ctl_number", %{"k" => "variant", "v" => v}, socket)
      when v in ~w(stacked split plain),
      do: {:noreply, update(socket, :number, &%{&1 | variant: v})}

  def handle_event("ctl_number", %{"k" => "size", "v" => v}, socket) when v in ~w(sm md lg),
    do: {:noreply, update(socket, :number, &%{&1 | size: v})}

  def handle_event("ctl_number", %{"k" => "bounds", "v" => v}, socket)
      when v in ~w(qty pct free),
      do: {:noreply, update(socket, :number, &%{&1 | bounds: v})}

  def handle_event("ctl_number", %{"k" => "disabled"}, socket),
    do: {:noreply, update(socket, :number, &%{&1 | disabled: !&1.disabled})}

  def handle_event("ctl_cal", %{"k" => "mode", "v" => v}, socket)
      when v in ~w(single range multiple),
      do: {:noreply, update(socket, :cal, &%{&1 | mode: v})}

  def handle_event("ctl_cal", %{"k" => "starts_on", "v" => v}, socket) when v in ~w(1 7),
    do: {:noreply, update(socket, :cal, &%{&1 | starts_on: String.to_integer(v)})}

  # The dial writes the token as an inline style rather than an arbitrary
  # utility class: `[--pc-calendar-cell-size:#{v}]` built at runtime is a class
  # name Tailwind's scanner never sees, so it would compile to nothing.
  def handle_event("ctl_cal", %{"k" => "size", "v" => v}, socket)
      when v in ~w(2rem 2.25rem 3rem 4rem),
      do: {:noreply, update(socket, :cal, &%{&1 | size: v})}

  def handle_event("ctl_cal", %{"k" => k}, socket) when k in ~w(outside window),
    do:
      {:noreply,
       update(socket, :cal, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  def handle_event("ctl_picker", %{"k" => "mode", "v" => v}, socket) when v in ~w(single range),
    do: {:noreply, update(socket, :picker, &%{&1 | mode: v})}

  def handle_event("ctl_picker", %{"k" => k}, socket) when k in ~w(two_months clearable),
    do:
      {:noreply,
       update(socket, :picker, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  # The playground drives the calendar the event way, which is also the fastest
  # way to feel the keyboard map: arrow off the end of a month and the server
  # renders the next one under your focus.
  def handle_event("cal_month", %{"month" => iso}, socket) do
    {:noreply, assign(socket, :cal_month, parse_date!(iso))}
  end

  def handle_event("cal_pick", %{"date" => iso}, socket) do
    date = parse_date!(iso)

    socket =
      case socket.assigns.cal.mode do
        "single" -> assign(socket, :cal_single, date)
        "multiple" -> update(socket, :cal_multi, &toggle_date(&1, date))
        "range" -> update(socket, :cal_range, &extend_range(&1, date))
      end

    {:noreply, assign(socket, :cal_month, Date.beginning_of_month(date))}
  end

  def handle_event("stay_pick", %{"date" => iso}, socket),
    do: {:noreply, update(socket, :pick_stay, &extend_range(&1, parse_date!(iso)))}

  def handle_event("birthday_pick", %{"date" => iso}, socket),
    do: {:noreply, assign(socket, :pick_birthday, parse_date!(iso))}

  # The flagship's month paging. Its VALUE stays client-owned (no on_select -
  # that is the flagship's story), but link-based month nav only works when
  # the page handles the month_param patch, which this playground LV does
  # not - so the nav is evented instead and this is its handler.
  def handle_event("picker_month", %{"month" => iso}, socket),
    do: {:noreply, assign(socket, :pick_month, parse_date!(iso))}

  def handle_event("deadline_pick", %{"date" => iso}, socket),
    do: {:noreply, assign(socket, :pick_deadline, parse_date!(iso))}

  def handle_event("deadline_clear", _params, socket),
    do: {:noreply, assign(socket, :pick_deadline, nil)}

  def handle_event("ctl_switch", %{"k" => "size", "v" => v}, socket) when v in ~w(xs sm md lg xl),
    do: {:noreply, update(socket, :switch, &%{&1 | size: v})}

  def handle_event("ctl_switch", %{"k" => "variant", "v" => v}, socket)
      when v in ~w(default pill),
      do: {:noreply, update(socket, :switch, &%{&1 | variant: v})}

  def handle_event("ctl_switch", %{"k" => k}, socket) when k in ~w(disabled error),
    do:
      {:noreply,
       update(socket, :switch, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  def handle_event("ctl_modal", %{"k" => "max_width", "v" => v}, socket)
      when v in ~w(sm md lg xl 2xl full),
      do: {:noreply, update(socket, :modal, &%{&1 | max_width: v})}

  def handle_event("ctl_modal", %{"k" => "footer", "v" => v}, socket)
      when v in ~w(none actions),
      do: {:noreply, update(socket, :modal, &%{&1 | footer: v})}

  def handle_event("ctl_modal", %{"k" => "content", "v" => v}, socket)
      when v in ~w(short long),
      do: {:noreply, update(socket, :modal, &%{&1 | content: v})}

  def handle_event("ctl_modal", %{"k" => k}, socket) when k in ~w(header close dismiss),
    do:
      {:noreply,
       update(socket, :modal, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  def handle_event("ctl_slider", %{"k" => "mode", "v" => v}, socket)
      when v in ~w(single dual),
      do: {:noreply, update(socket, :slider, &%{&1 | mode: v})}

  def handle_event("ctl_slider", %{"k" => "show_value", "v" => v}, socket)
      when v in ~w(none tooltip inline),
      do: {:noreply, update(socket, :slider, &%{&1 | show_value: v})}

  def handle_event("ctl_slider", %{"k" => "orientation", "v" => v}, socket)
      when v in ~w(horizontal vertical),
      do: {:noreply, update(socket, :slider, &%{&1 | orientation: v})}

  def handle_event("ctl_slider", %{"k" => "step", "v" => v}, socket)
      when v in ~w(1 5 25),
      do: {:noreply, update(socket, :slider, &%{&1 | step: String.to_integer(v)})}

  def handle_event("ctl_slider", %{"k" => "size", "v" => v}, socket)
      when v in ~w(sm md lg),
      do: {:noreply, update(socket, :slider, &%{&1 | size: v})}

  def handle_event("ctl_slider", %{"k" => k}, socket) when k in ~w(marks disabled),
    do:
      {:noreply,
       update(socket, :slider, &Map.update!(&1, String.to_existing_atom(k), fn v -> !v end))}

  # The price filter is an ordinary form change - the two thumbs post two fields.
  def handle_event("slider_price", %{"pg_price" => params}, socket),
    do: {:noreply, assign(socket, :slider_price, to_form(params, as: :pg_price))}

  def handle_event("slider_volume", %{"volume" => v}, socket),
    do: {:noreply, assign(socket, :slider_volume, String.to_integer(v))}

  def handle_event("slider_year", %{"year" => v}, socket),
    do: {:noreply, assign(socket, :slider_year, String.to_integer(v))}

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

  # The filter bar's whole backend, event mode: State.handle_op speaks the
  # payloads the chips and editors post, so this is one call plus a re-run
  # through the free in-memory engine. The data table below it shares the
  # same State, which is why filtering from either surface updates both.
  def handle_event("pg_filters", params, socket) do
    alias PetalComponents.DataTable.State

    {state, _rows} = socket.assigns.filters_state
    state = State.handle_op(state, params, fields: @filters_fields)

    {:noreply, assign(socket, :filters_state, run_filters(state))}
  end

  def handle_event("pg_filters_types", %{"k" => type}, socket) do
    types = socket.assigns.filters_types
    types = if type in types, do: List.delete(types, type), else: types ++ [type]

    {:noreply, assign(socket, :filters_types, types)}
  end

  defp run_filters(state) do
    {rows, state} =
      PetalComponents.DataTable.Engine.List.run(
        PetalComponents.Showcase.Filters.products(),
        state
      )

    {state, rows}
  end

  defp run_dt(state, refunded \\ []) do
    rows =
      Enum.map(PetalComponents.Showcase.DataTable.sample_rows(), fn row ->
        if to_string(row.id) in refunded, do: %{row | status: "refunded"}, else: row
      end)

    {rows, state} = PetalComponents.DataTable.Engine.List.run(rows, state)

    {state, rows}
  end

  # A preset swaps in its canned payload; "custom" keeps whatever is typed.
  defp qr_preset_value(preset, current), do: Map.get(@qr_preset_values, preset, current)

  defp qr_rounded("0"), do: 0
  defp qr_rounded("0.5"), do: 0.5
  defp qr_rounded("1"), do: 1

  defp qr_size_class("sm"), do: "size-28"
  defp qr_size_class("md"), do: "size-44"
  defp qr_size_class("lg"), do: "size-60"
  defp qr_size_class("xl"), do: "size-72"

  # Never hand the component an empty string - there is nothing to encode.
  defp qr_value(""), do: "https://petal.build"
  defp qr_value(value), do: value

  # The snippet shows EXACTLY what the hero renders - the same PC monogram
  # slot content, and the label every hero render passes.
  defp qr_snippet(qr) do
    logo =
      if qr.logo do
        "\n  <:logo>\n" <>
          ~s|    <div class="flex items-center justify-center w-full h-full text-5xl font-bold">\n| <>
          ~s|      <span class="text-primary-600">PC</span>\n| <>
          "    </div>\n  </:logo>\n</.qr_code>"
      else
        "\n/>"
      end

    background = if qr.surface == "light", do: ~s(\n  background="white"), else: ""
    colour = if qr.surface == "light", do: "text-gray-900", else: "text-white"

    ~s|<.qr_code| <>
      ~s|\n  value="#{qr_value(qr.value)}"| <>
      ~s|\n  error_correction={:#{qr.ec}}| <>
      ~s|\n  rounded={#{qr.rounded}}| <>
      background <>
      ~s|\n  label="QR code for the value shown below"| <>
      ~s|\n  class="#{qr_size_class(qr.size)} #{colour}"| <>
      logo
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

  def handle_event("ctl_empty", %{"k" => "variant", "v" => v}, socket)
      when v in ~w(default compact card dashed),
      do: {:noreply, update(socket, :empty, &%{&1 | variant: v})}

  def handle_event("ctl_empty", %{"k" => "size", "v" => v}, socket) when v in ~w(sm md lg),
    do: {:noreply, update(socket, :empty, &%{&1 | size: v})}

  def handle_event("ctl_empty", %{"k" => "actions", "v" => v}, socket)
      when v in ~w(none primary both),
      do: {:noreply, update(socket, :empty, &%{&1 | actions: v})}

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

  # tool_call dials -----------------------------------------------------------

  def handle_event("ctl_tool", %{"k" => "state", "v" => v}, socket)
      when v in ~w(pending input_streaming running complete error) do
    {:noreply, assign(socket, :tool, %{socket.assigns.tool | state: String.to_existing_atom(v)})}
  end

  def handle_event("ctl_tool", %{"k" => "compact", "v" => v}, socket) do
    {:noreply, assign(socket, :tool, %{socket.assigns.tool | compact: v == "on"})}
  end

  def handle_event("ctl_tool", %{"k" => "icon", "v" => v}, socket)
      when v in ~w(web_search code database none) do
    icon = if v == "none", do: nil, else: v
    {:noreply, assign(socket, :tool, %{socket.assigns.tool | icon: icon})}
  end

  # The mocked agent run. This is the whole contract in eight lines: a timer
  # patches one assign and the card moves. No client state, no hook.
  def handle_event("tool_run", %{"outcome" => outcome}, socket)
      when outcome in ~w(success error) do
    tool = socket.assigns.tool

    if tool.run_state in [nil, :complete, :error] do
      Process.send_after(self(), {:tool_step, :input_streaming}, 900)

      {:noreply,
       assign(socket, :tool, %{
         tool
         | run_state: :pending,
           run_duration: nil,
           run_outcome: String.to_existing_atom(outcome),
           run_seq: tool.run_seq + 1
       })}
    else
      {:noreply, socket}
    end
  end

  def handle_event("tool_reset", _params, socket) do
    {:noreply, assign(socket, :tool, %{socket.assigns.tool | run_state: nil, run_duration: nil})}
  end

  def handle_event("ctl_chat", %{"k" => "sources_expanded", "v" => v}, socket) do
    {:noreply, assign(socket, :chat, %{socket.assigns.chat | sources_expanded: v == "open"})}
  end

  def handle_event("ctl_chat", %{"k" => "sources_max", "v" => v}, socket) do
    max = if v == "all", do: length(@chat_rag_sources), else: String.to_integer(v)
    {:noreply, assign(socket, :chat, %{socket.assigns.chat | sources_max: max})}
  end

  def handle_event("ctl_chat", %{"k" => "attach_hint", "v" => v}, socket) do
    {:noreply, assign(socket, :chat, %{socket.assigns.chat | attach_hint: v == "on"})}
  end

  # Re-allow the upload with a tiny cap so the "too large" error is one drop
  # away. disallow_upload first - allow_upload raises on a name it already owns.
  def handle_event("ctl_chat", %{"k" => "attach_limit", "v" => v}, socket) do
    max = if v == "tiny", do: 20_000, else: 5_000_000

    {:noreply,
     socket
     |> disallow_upload(:chat_attachments)
     |> allow_upload(:chat_attachments,
       accept: ~w(.png .jpg .jpeg .pdf),
       max_entries: 4,
       max_file_size: max
     )
     |> assign(:chat, %{socket.assigns.chat | attach_limit: v})}
  end

  # The whole point of the component: submit is a plain phx-submit, the parent
  # updates assigns, and the card flips to its resolved state. No client state.
  def handle_event("questionnaire_submit", %{"spec_id" => "q-framework"} = params, socket) do
    quiz = %{socket.assigns.quiz | framework: params["answers"] || %{}, asked_scope: true}
    {:noreply, assign(socket, :quiz, quiz)}
  end

  def handle_event("questionnaire_submit", %{"spec_id" => "q-scope"} = params, socket) do
    {:noreply, assign(socket, :quiz, %{socket.assigns.quiz | scope: params["answers"] || %{}})}
  end

  def handle_event("questionnaire_submit", _params, socket), do: {:noreply, socket}

  def handle_event("questionnaire_skip", %{"id" => "q-framework"}, socket) do
    {:noreply, assign(socket, :quiz, %{socket.assigns.quiz | framework: :skipped})}
  end

  def handle_event("questionnaire_skip", %{"id" => "q-scope"}, socket) do
    {:noreply, assign(socket, :quiz, %{socket.assigns.quiz | scope: :skipped})}
  end

  def handle_event("questionnaire_skip", _params, socket), do: {:noreply, socket}

  def handle_event("quiz_reset", _params, socket) do
    quiz = %{socket.assigns.quiz | framework: nil, scope: nil, asked_scope: false}
    {:noreply, assign(socket, :quiz, quiz)}
  end

  def handle_event("ctl_quiz", %{"k" => k, "v" => v}, socket) do
    quiz =
      case k do
        "field" -> %{socket.assigns.quiz | field: v}
        "allow_skip" -> %{socket.assigns.quiz | allow_skip: v == "on"}
        "state" -> %{socket.assigns.quiz | state: v}
        _ -> socket.assigns.quiz
      end

    {:noreply, assign(socket, :quiz, quiz)}
  end

  # Uploads need a change event on the form to make progress.
  def handle_event("chat_validate", _params, socket), do: {:noreply, socket}

  def handle_event("chat_cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :chat_attachments, ref)}
  end

  # Streams the same grounded answer word by word. Each tick re-renders the
  # buffer through to_html/2, so the [^N] chips appear as the markers complete
  # and a half-arrived "[^" never flashes broken.
  def handle_event("chat_rag_stream", _params, socket) do
    if socket.assigns.chat.rag_streaming do
      {:noreply, socket}
    else
      words = String.split(@chat_rag_answer, " ")
      Process.send_after(self(), {:chat_rag_tick, "", words}, 150)

      {:noreply,
       socket
       |> assign(:chat, %{socket.assigns.chat | rag_streaming: true})
       |> push_event("pc-chat-rag-token", %{id: "pg-chat-rag-stream", html: ""})}
    end
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
    pending? = socket.assigns.uploads.chat_attachments.entries != []

    if (prompt == "" && !pending?) || socket.assigns.chat.streaming do
      {:noreply, socket}
    else
      attachments = consume_chat_attachments(socket)
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
            %{
              id: "u#{seq}",
              role: :user,
              text: prompt,
              stream_id: nil,
              attachments: attachments
            },
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

  # One field at a time, so each type can be looked at on its own. Every branch
  # uses the "q-demo" id: the flow above renders @q_framework at the same time,
  # and two live copies of one spec id would collide on input ids.
  defp quiz_demo_spec("single_cards"), do: %{@q_framework | id: "q-demo"}

  defp quiz_demo_spec("single_buttons") do
    %{
      id: "q-demo",
      title: "Which framework are you targeting?",
      fields: [
        %{
          id: "framework",
          type: :single_select,
          label: "Framework",
          style: "buttons",
          required: true,
          options: [
            %{value: "phoenix", label: "Phoenix"},
            %{value: "rails", label: "Rails"},
            %{value: "next", label: "Next.js"}
          ]
        }
      ]
    }
  end

  defp quiz_demo_spec("multi") do
    %{
      id: "q-demo",
      title: "Which features do you need?",
      fields: [Enum.at(@q_scope.fields, 0)]
    }
  end

  defp quiz_demo_spec("text") do
    %{id: "q-demo", title: "What should I call it?", fields: [Enum.at(@q_scope.fields, 1)]}
  end

  defp quiz_demo_spec(_scale) do
    %{id: "q-demo", title: "How settled is this scope?", fields: [Enum.at(@q_scope.fields, 2)]}
  end

  defp quiz_demo_resolved(%{state: "skipped"}), do: :skipped

  defp quiz_demo_resolved(%{state: "resolved", field: field}) do
    case field do
      "multi" -> %{"features" => ["auth", "billing"]}
      "text" -> %{"team" => "Platform"}
      "scale" -> %{"confidence" => "5"}
      _ -> %{"framework" => "phoenix"}
    end
  end

  defp quiz_demo_resolved(_quiz), do: nil

  # A real app writes these somewhere it can serve from. The playground has no
  # static host for a temp dir, so small images become data URIs (enough to
  # prove message_attachments renders what was actually uploaded) and anything
  # else becomes a file row.
  defp consume_chat_attachments(socket) do
    consume_uploaded_entries(socket, :chat_attachments, fn %{path: path}, entry ->
      image? = String.starts_with?(entry.client_type, "image/")
      inlineable? = image? && entry.client_size <= 1_000_000

      url =
        if inlineable? do
          "data:#{entry.client_type};base64,#{Base.encode64(File.read!(path))}"
        else
          "#"
        end

      {:ok,
       %{
         kind: if(inlineable?, do: :image, else: :file),
         url: url,
         name: entry.client_name,
         size: entry.client_size
       }}
    end)
  end

  defp patch_theme(socket, delta) do
    theme =
      socket.assigns
      |> Map.take([:active, :primary, :secondary, :gray, :radius, :font_heading, :font_body, :font_mono])
      |> Map.merge(delta)

    {:noreply, push_patch(socket, to: theme_path(theme))}
  end

  defp theme_path(t) do
    # Component in the PATH (see the /c/:c route - Fathom needs it there),
    # theme in the query (it is a look, not a page; also Fathom drops query
    # strings, which for the dials is exactly right).
    base = if t.active == "button", do: "/", else: "/c/#{t.active}"

    []
    |> then(&if t.font_mono != "system", do: [{"mono", t.font_mono} | &1], else: &1)
    |> then(&if t.font_body != "system", do: [{"body", t.font_body} | &1], else: &1)
    |> then(&if t.font_heading != "system", do: [{"heading", t.font_heading} | &1], else: &1)
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

  # PhoenixPlayground's dead render hands handle_params only the path
  # params; the query string arrives solely in uri, so every decoder here
  # reads it from there. Malformed percent-encoding makes Plug's decoder
  # raise, and a garbage query string must degrade to "no dials set",
  # never to a 500 on every route.
  defp query_params(uri) do
    query = uri |> URI.parse() |> Map.get(:query) || ""
    Plug.Conn.Query.decode(query)
  rescue
    _ -> %{}
  end

  # Get Code's agent prompt carries a real shareable URL - the deployed host
  # in production, localhost in dev - taken from the uri handle_params
  # already receives.
  defp assign_base_url(socket, uri) do
    %URI{scheme: scheme, host: host, port: port} = URI.parse(uri)

    base =
      if (scheme == "https" and port == 443) or (scheme == "http" and port == 80),
        do: "#{scheme}://#{host}",
        else: "#{scheme}://#{host}:#{port}"

    assign(socket, :base_url, base)
  end

  # ---- Get Code: the dialed look as a paste-ready start story --------------
  #
  # Emission rule everywhere: only what differs from PACKAGE stock (blue
  # primary, pink secondary, zinc gray, 0.625rem radius, host fonts). The
  # playground's neutral-primary DEFAULT therefore emits a block - that
  # look is not stock, it's the light-dark() monochrome accent.

  defp get_code_sections(a) do
    theme = theme_code(a)
    fonts = font_code(a)

    [
      {"Install", install_code()},
      theme && {"Theme - assets/css/app.css", theme},
      fonts && {"Fonts - self-hosted", fonts},
      {"Hand it to your agent", agent_code(a, theme, fonts)}
    ]
    |> Enum.reject(&is_nil/1)
  end

  # Derived from the running package, so the deployed playground always emits
  # the requirement matching what is actually on Hex at deploy time (deploys
  # follow the release commit) - never a version ahead of the published one.
  defp pc_requirement do
    [maj, min | _] = Application.spec(:petal_components, :vsn) |> to_string() |> String.split(".")
    "~> #{maj}.#{min}"
  end

  defp install_code do
    """
    # 1. mix.exs
    {:petal_components, "#{pc_requirement()}"}

    # 2. mix deps.get

    # 3. assets/css/app.css - under @import "tailwindcss";
    @source "../deps/petal_components/**/*.*ex";
    @source not "../deps/petal_components/lib/petal_components/showcase";
    @import "../deps/petal_components/assets/default.css";

    # 4. lib/<your_app>_web.ex - inside `def html`'s quote block
    use PetalComponents

    # 5. assets/js/app.js - spread the bundled hooks into your LiveSocket
    import PetalComponents from "../../deps/petal_components/assets/js/petal_components"
    hooks: { ...PetalComponents }\
    """
  end

  defp theme_code(a) do
    blocks =
      [primary_code(a.primary), secondary_code(a.secondary), gray_code(a.gray), radius_code(a.radius)]
      |> Enum.reject(&is_nil/1)

    if blocks != [], do: Enum.join(blocks, "\n\n")
  end

  # Stock is blue. Neutral is the playground's monochrome accent: near-black
  # action colour in light, near-white in dark, derived from the gray ramp -
  # light-dark() needs color-scheme wired to the dark class to resolve.
  defp primary_code("blue"), do: nil

  defp primary_code("neutral") do
    """
    :root { color-scheme: light; }
    .dark { color-scheme: dark; }

    @theme inline {
    #{neutral_ramp_lines()}
    }

    :root {
      --pc-button-solid-fg: light-dark(#ffffff, var(--color-gray-900));
    }\
    """
  end

  defp primary_code(hue), do: ramp_remap("primary", hue)

  defp neutral_ramp_lines do
    # The exact ramp the playground's neutral dial paints (dev/colors.css),
    # with --color-gray-* in place of the pg mirrors: light stop -> dark stop.
    [
      {"50", "50", "900"},
      {"100", "100", "700"},
      {"200", "200", "800"},
      {"300", "300", "300"},
      {"400", "400", "600"},
      {"500", "600", "400"},
      {"600", "900", "50"},
      {"700", "800", "200"},
      {"800", "700", "300"},
      {"900", "900", "100"},
      {"950", "950", "50"}
    ]
    |> Enum.map_join("\n", fn {stop, l, d} ->
      "  --color-primary-#{stop}: light-dark(var(--color-gray-#{l}), var(--color-gray-#{d}));"
    end)
  end

  defp secondary_code("pink"), do: nil
  defp secondary_code(hue), do: ramp_remap("secondary", hue)

  defp gray_code("zinc"), do: nil

  # Tailwind's own gray is the one ramp a var() can't reach (petal ships
  # zinc under the gray name) - restoring it is the one-line import.
  defp gray_code("gray") do
    """
    /* after the default.css import */
    @import "../deps/petal_components/assets/tailwind-gray.css";\
    """
  end

  defp gray_code(ramp), do: ramp_remap("gray", ramp)

  defp ramp_remap(role, ramp) do
    stops = ~w(50 100 200 300 400 500 600 700 800 900 950)

    lines =
      Enum.map_join(stops, "\n", fn stop ->
        "  --color-#{role}-#{stop}: var(--color-#{ramp}-#{stop});"
      end)

    "@theme inline {\n#{lines}\n}"
  end

  defp radius_code("10"), do: nil

  defp radius_code(r) do
    """
    :root {
      --pc-radius: #{radius_css(r)};
    }\
    """
  end

  defp font_code(a) do
    picks =
      [heading: a.font_heading, body: a.font_body, mono: a.font_mono]
      |> Enum.reject(fn {_role, slug} -> slug == "system" end)

    if picks != [] do
      families = picks |> Enum.map(&elem(&1, 1)) |> Enum.uniq()

      curls =
        Enum.map_join(families, "\n", fn slug ->
          "curl -o priv/static/fonts/#{slug}-latin-wght-normal.woff2 \\\n" <>
            "  https://cdn.jsdelivr.net/npm/@fontsource-variable/#{slug}@5.3.0/files/#{slug}-latin-wght-normal.woff2"
        end)

      faces =
        Enum.map_join(families, "\n\n", fn slug ->
          """
          @font-face {
            font-family: "#{@font_labels[slug]}";
            font-style: normal;
            font-weight: #{@font_weights[slug]};
            font-display: swap;
            src: url("/fonts/#{slug}-latin-wght-normal.woff2") format("woff2-variations");
          }\
          """
        end)

      body_slug = a.font_body
      mono_slug = a.font_mono
      heading_slug = a.font_heading

      theme_lines =
        [
          body_slug != "system" && "  --font-sans: #{@font_stacks[body_slug]};",
          mono_slug != "system" && "  --font-mono: #{@font_stacks[mono_slug]};"
        ]
        |> Enum.filter(& &1)

      theme_block =
        if theme_lines != [],
          do: "/* body -> --font-sans reskins the whole app via preflight;\n   mono -> --font-mono reaches every pc mono surface */\n@theme {\n#{Enum.join(theme_lines, "\n")}\n}",
          else: nil

      heading_block =
        if heading_slug != "system" and heading_slug != body_slug,
          do:
            ":root {\n  --pc-font-heading: #{@font_stacks[heading_slug]};\n}\n\n" <>
              "/* optional: raw h1-h6 outside <.h1>..<.h5> follow the heading face too */\n" <>
              "h1, h2, h3, h4, h5, h6 {\n  font-family: var(--pc-font-heading, inherit);\n}",
          else: nil

      preload =
        if body_slug != "system" do
          "<%!-- root.html.heex, before the CSS link - preload the body face only --%>\n" <>
            ~s|<link rel="preload" href={~p"/fonts/#{body_slug}-latin-wght-normal.woff2"} as="font" type="font/woff2" crossorigin="anonymous" />|
        end

      [
        "# fetch once, commit the files (Phoenix static_paths already serves /fonts;\n# mix phx.digest fingerprints them; italics render synthetic)\n" <> curls,
        "/* assets/css/app.css */\n" <> faces,
        theme_block,
        heading_block,
        preload
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n\n")
    end
  end

  defp agent_code(a, theme, fonts) do
    url =
      a.base_url <>
        theme_path(
          Map.take(a, [:active, :primary, :secondary, :gray, :radius, :font_heading, :font_body, :font_mono])
        )

    steps =
      [
        "1. Install petal_components per https://petal.build/petal-components/rules.md (hex dep, the @source/@import lines in assets/css/app.css, `use PetalComponents` in the web module, spread the bundled JS hooks).",
        theme && "2. Add this to assets/css/app.css:\n\n#{theme}",
        fonts && "#{if theme, do: 3, else: 2}. Self-host these fonts:\n\n#{fonts}"
      ]
      |> Enum.filter(& &1)

    """
    Set up petal_components in this Phoenix + Tailwind v4 app with the look I dialed in at #{url}

    #{Enum.join(steps, "\n\n")}

    Then start the server and confirm headings, body text and code render in the chosen look.\
    """
  end

  # The trigger says what's dialed without opening the panel: the first
  # non-system face by role priority, "+N" when more dials are set, or
  # System when none are.
  defp typeset_trigger_label(a) do
    set = Enum.reject([a.font_heading, a.font_body, a.font_mono], &(&1 == "system"))

    case set do
      [] -> "System"
      [only] -> @font_labels[only]
      [first | rest] -> "#{@font_labels[first]} +#{length(rest)}"
    end
  end

  # Inline custom properties on the page wrapper, exactly like --pc-radius:
  # they re-resolve per subtree, so pinned fixtures can reset them (see the
  # base-layer pin in dev/app.css). System writes nothing - the token stays
  # unset and every pc chain falls through to inherit.
  defp font_style(a) do
    [
      {"--pc-font-heading", a.font_heading},
      {"--pc-font-body", a.font_body},
      {"--pc-font-mono", a.font_mono}
    ]
    |> Enum.reject(fn {_token, slug} -> slug == "system" end)
    |> Enum.map_join(fn {token, slug} -> "; #{token}: #{@font_stacks[slug]}" end)
  end

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

  # Flat mode lists the h2s only, which is what most docs rails do. Nested
  # mode folds the two h3s under the section they belong to.
  defp scrollspy_items(%{nested: nested}) do
    wiring =
      if nested do
        %{
          label: "Wiring it up",
          target: "ss-wiring",
          children: [
            %{label: "The items list", target: "ss-items"},
            %{label: "The targets", target: "ss-targets"}
          ]
        }
      else
        %{label: "Wiring it up", target: "ss-wiring"}
      end

    [
      %{label: "Why a rail", target: "ss-why"},
      wiring,
      %{label: "Clearing a header", target: "ss-offset"},
      %{label: "Motion", target: "ss-motion"},
      %{label: "Accessibility", target: "ss-a11y"},
      %{label: "Wrapping up", target: "ss-end"}
    ]
  end

  defp scrollspy_snippet(ss) do
    """
    <.scrollspy
      id="docs-toc"
      heading="On this page"
      offset="#{ss.offset}"#{if ss.indicator == "none", do: ~s|\n  indicator="none"|, else: ""}
      items={[
        %{label: "Why a rail", target: "ss-why"},#{if ss.nested, do: nested_snippet(), else: ~s|\n    %{label: "Wiring it up", target: "ss-wiring"},|}
        %{label: "Wrapping up", target: "ss-end"}
      ]}
    />
    """
  end

  defp nested_snippet do
    """

        %{
          label: "Wiring it up",
          target: "ss-wiring",
          children: [
            %{label: "The items list", target: "ss-items"},
            %{label: "The targets", target: "ss-targets"}
          ]
        },\
    """
  end

  # A page's slice of a showcase module, in the page's order. Field is one
  # component (so one registry module), but the playground splits its examples
  # across the input / select / checkbox / radio / switch pages. Raises on a
  # typo'd id so a page can't silently drop an example.
  # The separator dial's "none" option is a real none: nil renders no
  # separator span at all (a " " separator still rendered an aria-hidden
  # whitespace span plus the group gap - double spacing, not none).
  defp kbd_sep(" "), do: nil
  defp kbd_sep(g), do: g

  defp examples_for(module, ids) do
    by_id = Map.new(module.examples(), &{&1.id, &1})
    Enum.map(ids, &Map.fetch!(by_id, &1))
  end

  # --- Tree page data -------------------------------------------------------

  defp toggle_member(set, id) do
    if MapSet.member?(set, id), do: MapSet.delete(set, id), else: MapSet.put(set, id)
  end

  defp sample_tree do
    [
      %{
        id: "lib",
        label: "lib",
        children: [
          %{
            id: "petal_components",
            label: "petal_components",
            children: [
              %{id: "button.ex", label: "button.ex"},
              %{id: "modal.ex", label: "modal.ex"},
              %{id: "tree.ex", label: "tree.ex"}
            ]
          },
          %{id: "petal_components.ex", label: "petal_components.ex"}
        ]
      },
      %{
        id: "assets",
        label: "assets",
        children: [
          %{id: "default.css", label: "default.css"},
          %{
            id: "js",
            label: "js",
            children: [%{id: "petal_components.js", label: "petal_components.js"}]
          }
        ]
      },
      %{id: "mix.exs", label: "mix.exs"},
      %{id: "README.md", label: "README.md"}
    ]
  end

  defp hero_expanded("all"), do: :all
  defp hero_expanded("first"), do: ["lib", "assets"]
  defp hero_expanded(_none), do: []

  defp tree_lazy_ids, do: ["deps"]

  defp tree_lazy_children("deps") do
    [
      %{id: "phoenix", label: "phoenix", icon: "hero-cube"},
      %{id: "phoenix_live_view", label: "phoenix_live_view", icon: "hero-cube"},
      %{id: "heroicons", label: "heroicons", icon: "hero-cube"}
    ]
  end

  # The lazy branch keeps :lazy set so it stays a branch before its children
  # exist; once they land they are just children like any others.
  defp explorer_items(tree) do
    sample_tree() ++
      [
        %{
          id: "deps",
          label: "deps",
          lazy: true,
          children: Map.get(tree.loaded, "deps", [])
        },
        %{id: "_build", label: "_build", disabled: true}
      ]
  end

  defp org_tree do
    [
      %{
        id: "dana",
        label: "Dana Okafor",
        initials: "DO",
        role: "VP Engineering",
        city: "Melbourne",
        children: [
          %{
            id: "sam",
            label: "Sam Reyes",
            initials: "SR",
            role: "Platform lead",
            city: "Sydney",
            children: [
              %{
                id: "kit",
                label: "Kit Alvarez",
                initials: "KA",
                role: "Senior engineer",
                city: "Perth"
              },
              %{
                id: "noor",
                label: "Noor Haddad",
                initials: "NH",
                role: "Engineer",
                city: "Sydney"
              }
            ]
          },
          %{
            id: "wren",
            label: "Wren Costa",
            initials: "WC",
            role: "Design lead",
            city: "Melbourne",
            children: [
              %{
                id: "ida",
                label: "Ida Bergstrom",
                initials: "IB",
                role: "Designer",
                city: "Hobart"
              }
            ]
          }
        ]
      }
    ]
  end

  defp settings_tree do
    [
      %{
        id: "workspace",
        label: "Workspace",
        icon: "hero-building-office-2",
        children: [
          %{id: "general", label: "General", icon: "hero-cog-6-tooth"},
          %{id: "members", label: "Members", icon: "hero-users"},
          %{id: "billing", label: "Billing", icon: "hero-credit-card"}
        ]
      },
      %{
        id: "security",
        label: "Security",
        icon: "hero-shield-check",
        children: [
          %{id: "sso", label: "Single sign-on", icon: "hero-key"},
          %{id: "audit-log", label: "Audit log", icon: "hero-document-text"}
        ]
      },
      %{id: "api-keys", label: "API keys", icon: "hero-command-line"},
      %{id: "legal-hold", label: "Legal hold", icon: "hero-lock-closed", disabled: true}
    ]
  end

  # Calendar plumbing. The component hands back ISO strings and takes Dates, so
  # the page owns the tiny bit of state in between - which is the whole point of
  # the event wiring.
  defp parse_date!(iso), do: Date.from_iso8601!(iso)

  defp toggle_date(dates, date) do
    if Enum.any?(dates, &(Date.compare(&1, date) == :eq)),
      do: Enum.reject(dates, &(Date.compare(&1, date) == :eq)),
      else: Enum.sort([date | dates], Date)
  end

  # One click anchors, the next closes, the third starts over. Clicking before
  # the anchor swaps the ends rather than rejecting the click.
  defp extend_range({nil, _to}, date), do: {date, nil}
  defp extend_range({_from, %Date{}}, date), do: {date, nil}

  defp extend_range({from, nil}, date) do
    if Date.before?(date, from), do: {date, from}, else: {from, date}
  end

  defp cal_value(%{mode: "single"}, assigns), do: assigns.cal_single
  defp cal_value(%{mode: "range"}, assigns), do: assigns.cal_range
  defp cal_value(%{mode: "multiple"}, assigns), do: assigns.cal_multi

  defp cal_summary(%{mode: "single"}, assigns), do: date_text(assigns.cal_single)

  defp cal_summary(%{mode: "range"}, assigns) do
    {from, to} = assigns.cal_range
    date_text(from) <> " to " <> date_text(to)
  end

  defp cal_summary(%{mode: "multiple"}, assigns) do
    case assigns.cal_multi do
      [] -> "nothing picked"
      dates -> Enum.map_join(dates, ", ", &date_text/1)
    end
  end

  defp date_text(%Date{} = date), do: Calendar.strftime(date, "%d %b %Y")
  defp date_text(_), do: "-"

  # The deadline scenario is the FormField path the tests cover, so the page
  # drives it through to_form/1 rather than hand-building a name and an errors
  # list - errors, the required marker and the posted name all come off the
  # field the way they would in a real changeset-backed form.
  defp deadline_form(%Date{} = date), do: to_form(%{"due_on" => date}, as: :task)

  defp deadline_form(_),
    do: to_form(%{"due_on" => nil}, as: :task, errors: [due_on: {"can't be blank", []}])

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

  defp hover_card_snippet(hc) do
    attrs =
      [
        hc.placement != "bottom" && ~s(placement="#{hc.placement}"),
        hc.open_delay != 350 && "open_delay={#{hc.open_delay}}",
        hc.close_delay != 150 && "close_delay={#{hc.close_delay}}"
      ]
      |> Enum.filter(& &1)

    Enum.join(["<.hover_card" | attrs], " ") <>
      ">\n  <:trigger>\n    <.link navigate={~p\"/users/jane\"}>@jane</.link>\n  </:trigger>\n  <%!-- avatar, bio, stats, a follow button --%>\n</.hover_card>"
  end

  # Where to park the demo trigger inside the preview frame while the frame is
  # too narrow to centre it (below md). The card is statically placed, so it
  # grows in one direction only - put the trigger against the opposite side and
  # the whole card lands inside the frame. `md:justify-center` overrides this
  # once the frame can hold a card on both sides of a centred trigger.
  defp hover_card_demo_justify("left" <> _), do: "justify-end"
  defp hover_card_demo_justify("right" <> _), do: "justify-start"

  defp hover_card_demo_justify(placement) do
    cond do
      String.ends_with?(placement, "-start") -> "justify-start"
      String.ends_with?(placement, "-end") -> "justify-end"
      true -> "justify-center"
    end
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

  defp number_bounds("qty"), do: %{min: 1, max: 99, step: 1, label: "1 to 99, step 1"}
  defp number_bounds("pct"), do: %{min: 0, max: 100, step: 5, label: "0 to 100, step 5"}
  defp number_bounds("free"), do: %{min: nil, max: nil, step: 0.5, label: "unbounded, step 0.5"}

  defp number_snippet(n) do
    b = number_bounds(n.bounds)

    attrs =
      [
        ~s(name="quantity"),
        ~s(value="12"),
        b.min && ~s(min={#{b.min}}),
        b.max && ~s(max={#{b.max}}),
        b.step != 1 && ~s(step={#{b.step}}),
        n.variant != "stacked" && ~s(variant="#{n.variant}"),
        n.size != "md" && ~s(size="#{n.size}"),
        n.disabled && "disabled"
      ]
      |> Enum.filter(& &1)

    "<.number_field #{Enum.join(attrs, " ")} />"
  end

  defp slider_preview_marks,
    do: [
      %{value: 0, label: "0"},
      %{value: 25, label: ""},
      %{value: 50, label: "50"},
      %{value: 75, label: ""},
      %{value: 100, label: "100"}
    ]

  defp slider_year_marks,
    do:
      for(
        y <- 1990..2030//5,
        do: %{value: y, label: if(rem(y, 10) == 0, do: to_string(y), else: "")}
      )

  # A stand-in catalogue so the price filter has something real to count.
  defp slider_catalogue,
    do: [40, 75, 120, 180, 240, 310, 380, 450, 520, 600, 680, 740, 810, 880, 950]

  defp slider_price_count(form) do
    lo = slider_param(form, :min, 0)
    hi = slider_param(form, :max, 1000)
    Enum.count(slider_catalogue(), &(&1 >= lo and &1 <= hi))
  end

  defp slider_param(form, key, default) do
    case Integer.parse(to_string(form[key].value || "")) do
      {n, _} -> n
      :error -> default
    end
  end

  defp slider_volume_icon(0), do: "hero-speaker-x-mark"
  defp slider_volume_icon(_), do: "hero-speaker-wave"

  defp slider_snippet(%{mode: "dual"} = s) do
    attrs =
      [
        ~s(min_field={@form[:min]}),
        ~s(max_field={@form[:max]}),
        ~s(min={0}),
        ~s(max={100}),
        s.step != 1 && ~s(step={#{s.step}}),
        ~s(label="Budget"),
        s.size != "md" && ~s(size="#{s.size}"),
        s.orientation != "horizontal" && ~s(orientation="#{s.orientation}"),
        s.show_value != "none" && ~s(show_value="#{s.show_value}"),
        s.marks && ~s(marks={[%{value: 0, label: "0"}, %{value: 50, label: "50"}]}),
        s.disabled && "disabled"
      ]
      |> Enum.filter(& &1)
      |> Enum.map(&("    " <> &1))

    """
    <.form for={@form} phx-change="filter">
      <.slider
    #{Enum.join(attrs, "\n")}
      />
    </.form>\
    """
  end

  defp slider_snippet(s) do
    attrs =
      [
        ~s(name="budget"),
        ~s(label="Budget"),
        ~s(value={60}),
        ~s(min={0}),
        ~s(max={100}),
        s.step != 1 && ~s(step={#{s.step}}),
        s.size != "md" && ~s(size="#{s.size}"),
        s.orientation != "horizontal" && ~s(orientation="#{s.orientation}"),
        s.show_value != "none" && ~s(show_value="#{s.show_value}"),
        s.marks && ~s(marks={[%{value: 0, label: "0"}, %{value: 50, label: "50"}]}),
        s.disabled && "disabled"
      ]
      |> Enum.filter(& &1)
      |> Enum.map(&("  " <> &1))

    """
    <.slider
    #{Enum.join(attrs, "\n")}
    />\
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
        sw.variant != "default" && ~s(variant="#{sw.variant}"),
        sw.error && ~s(errors={["must be enabled"]}),
        sw.disabled && "disabled"
      ]
      |> Enum.filter(& &1)

    "<.field #{Enum.join(attrs, " ")} />"
  end

  defp modal_snippet(m) do
    attrs =
      [
        ~s(id="invite"),
        ~s(title="Invite your team"),
        "hide",
        m.max_width != "md" && ~s(max_width="#{m.max_width}"),
        !m.header && "hide_header",
        m.header && !m.close && "hide_close_button",
        !m.dismiss && ~s(close_on_click_away={false})
      ]
      |> Enum.filter(& &1)

    body =
      if m.content == "long",
        do: "  <p>Long body copy that outgrows the box and scrolls.</p>",
        else: "  <p>Share this link and they'll join the workspace.</p>"

    footer =
      if m.footer == "actions",
        do:
          "  <:footer>\n" <>
            "    <.button color=\"gray\" variant=\"outline\" phx-click={hide_modal(\"invite\")}>Cancel</.button>\n" <>
            "    <.button phx-click={hide_modal(\"invite\")}>Copy link</.button>\n" <>
            "  </:footer>\n",
        else: ""

    "<.modal #{Enum.join(attrs, " ")}>\n#{body}\n#{footer}</.modal>"
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

  defp empty_snippet(e) do
    attrs =
      [
        e.variant != "default" && ~s(variant="#{e.variant}"),
        e.size != "md" && ~s(size="#{e.size}"),
        ~s(title="No projects yet"),
        ~s(description="Projects hold your environments, deploys and team access.")
      ]
      |> Enum.filter(& &1)

    open = Enum.join(["<.empty" | attrs], " ")

    case e.actions do
      "none" ->
        open <> " />"

      "primary" ->
        open <>
          ">\n  <:actions>\n    <.button size=\"sm\" label=\"Create project\" />\n  </:actions>\n</.empty>"

      "both" ->
        open <>
          ">\n  <:actions>\n    <.button size=\"sm\" label=\"Create project\" />\n    <.button size=\"sm\" variant=\"outline\" color=\"gray\" label=\"Import from Git\" />\n  </:actions>\n</.empty>"
    end
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

  # The dial demo: one release pipeline, re-dressed by whichever marker and
  # state the dials are set to.
  defp pg_timeline_entries(tl) do
    [
      %{
        icon: "hero-code-bracket",
        name: "Alex Chen",
        color: "gray",
        time: "9:41am",
        title: "Commit pushed",
        description: "fix: retry the webhook worker with a backoff"
      },
      %{
        icon: "hero-check-circle",
        name: "Sam Rivera",
        color: "success",
        time: "9:47am",
        title: "CI passed",
        description: "418 tests, 2m 51s"
      },
      %{
        icon: "hero-rocket-launch",
        name: "Jo Park",
        color: "primary",
        time: "9:52am",
        title: "Deploying to production",
        description: "Rolling through Sydney, Dublin and Ohio."
      },
      %{
        icon: "hero-bell-alert",
        name: "Robin Lee",
        color: "primary",
        time: "in a few minutes",
        title: "Release notes published",
        description: "Sent to everyone watching the repo."
      }
    ]
    |> Enum.with_index()
    |> Enum.map(fn {entry, i} ->
      entry
      |> Map.put(:marker, tl.marker)
      |> Map.put(:state, pg_timeline_state(tl.states, i))
    end)
  end

  defp pg_timeline_state(false, _index), do: "complete"
  defp pg_timeline_state(true, index) when index < 2, do: "complete"
  defp pg_timeline_state(true, 2), do: "current"
  defp pg_timeline_state(true, _index), do: "upcoming"

  defp pg_step_defs do
    [
      %{name: "Account", description: "Email and password"},
      %{name: "Workspace", description: "Name your project"},
      %{name: "Invite", description: "Bring the team"},
      %{name: "Review", description: "Confirm and finish"}
    ]
  end

  # labels: "none" drops name and description from the maps rather than passing
  # an attr - a label-less stepper is the same component with less in its steps.
  defp pg_steps(at, done, labels) do
    pg_step_defs()
    |> Enum.with_index()
    |> Enum.map(fn {step, i} ->
      step
      |> then(&if labels == "none", do: Map.drop(&1, [:name, :description]), else: &1)
      |> Map.put(:complete?, done || i < at)
      |> Map.put(:active?, !done && i == at)
      |> Map.put(
        :on_click,
        Phoenix.LiveView.JS.push("ctl_stepper", value: %{k: "goto", v: to_string(i)})
      )
    end)
  end

  defp stepper_snippet(st) do
    # Only the attrs that actually reach the paint: bars is horizontal-only and
    # outranks label_placement, so the snippet never shows an attr the
    # component would ignore.
    bars? = st.orientation == "horizontal" and st.variant == "bars"

    attrs =
      [
        st.orientation != "horizontal" && ~s(orientation="#{st.orientation}"),
        st.size != "md" && ~s(size="#{st.size}"),
        bars? && ~s(variant="bars"),
        not bars? and st.orientation == "horizontal" and st.labels == "bottom" &&
          ~s(label_placement="bottom")
      ]
      |> Enum.filter(& &1)

    # The steps are the interesting half, so the snippet shows them rather than
    # a placeholder - including the label-less form, where the maps just lose
    # their name and description keys.
    steps =
      pg_step_defs()
      |> Enum.with_index()
      |> Enum.map_join(",\n", fn {step, i} ->
        # `done` completes every step and clears the active one, exactly as
        # the live rail renders it - the snippet must tell the same story.
        state =
          "complete?: #{i < st.at or st.done}, active?: #{i == st.at and not st.done}"

        if st.labels == "none" do
          "    %{#{state}}"
        else
          ~s|    %{name: "#{step.name}", description: "#{step.description}", #{state}}|
        end
      end)

    open = Enum.join(["<.stepper" | attrs], " ")

    "#{open}\n  steps={[\n#{steps}\n  ]}\n/>"
  end

  # The labels dial stays live in every mode because "none" always applies -
  # it's the steps, not the placement. The hint says which half is being
  # ignored instead of greying out a control that still does something.
  defp stepper_labels_hint(%{orientation: "vertical"}),
    do: "beside and bottom are horizontal only"

  defp stepper_labels_hint(%{variant: "bars"}), do: "bars always sit titles under"
  defp stepper_labels_hint(_), do: nil

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
      style={"--pc-radius: #{radius_css(@radius)}" <> font_style(assigns)}
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
          <%!-- lining-nums is the caller opt-in: toggle_group items are slot
          content, so the component never imposes figure style - but these
          items ARE digits, and old-style figures would ride low under a
          display body face. --%>
          <.toggle_group
            variant="outline"
            size="sm"
            aria_label="Corner radius"
            value={@radius}
            on_change="set_radius"
            class={@rail_class}
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
        <div class="flex items-center gap-2.5 shrink-0">
          <span class="text-[11px] font-medium text-gray-400 dark:text-gray-500">type</span>
          <%!-- The three role dials live behind one labelled panel: bare
          selects in the strip couldn't say which face they steered. Top-layer
          popover because the strip is overflow-x-auto - an anchored panel
          would clip (the tooltip lesson). The Aa previews the dialed heading
          face live; row labels in the panel do the same per role. --%>
          <.popover
            id="pg-typeset"
            top_layer
            placement="bottom-start"
            class="shrink-0"
            trigger_class="flex items-center gap-1.5 h-7 px-2 text-xs font-medium lining-nums border rounded-md border-gray-300 bg-white text-gray-600 hover:bg-gray-100 dark:border-gray-400/25 dark:bg-gray-900 dark:text-gray-300 dark:hover:bg-gray-800 focus-visible:ring-2 focus-visible:ring-primary-500/50 focus-visible:outline-none"
          >
            <:trigger>
              <span
                class="text-sm leading-none"
                style="font-family: var(--pc-font-heading, var(--pc-font-body, inherit))"
                aria-hidden="true"
              >
                Aa
              </span>
              {typeset_trigger_label(assigns)}
              <.icon name="hero-chevron-down-mini" class="w-3.5 h-3.5 text-gray-400 dark:text-gray-500" />
            </:trigger>

            <div class="w-60">
              <div class="flex items-center justify-between mb-2.5">
                <div class="text-xs font-semibold text-gray-700 dark:text-gray-200">Typeset</div>
                <div class="flex items-center gap-1">
                  <button
                    phx-click="font_shuffle"
                    aria-label="Shuffle fonts"
                    title="Shuffle fonts"
                    class="flex items-center justify-center rounded-md w-6 h-6 text-gray-400 hover:text-gray-600 hover:bg-gray-100 dark:text-gray-500 dark:hover:text-gray-300 dark:hover:bg-gray-800 focus-visible:ring-2 focus-visible:ring-primary-500/50 focus-visible:outline-none"
                  >
                    <.icon name="hero-arrow-path-mini" class="w-4 h-4" />
                  </button>
                  <%!-- Always rendered: unmounting on click dropped keyboard
                  focus, and disabled-at-system reads as an affordance. --%>
                  <button
                    phx-click="font_reset"
                    aria-label="Reset fonts to system"
                    title="Reset fonts to system"
                    disabled={
                      @font_heading == "system" and @font_body == "system" and @font_mono == "system"
                    }
                    class="flex items-center justify-center rounded-md w-6 h-6 text-gray-400 hover:text-gray-600 hover:bg-gray-100 dark:text-gray-500 dark:hover:text-gray-300 dark:hover:bg-gray-800 focus-visible:ring-2 focus-visible:ring-primary-500/50 focus-visible:outline-none disabled:opacity-30 disabled:pointer-events-none"
                  >
                    <.icon name="hero-x-mark-mini" class="w-4 h-4" />
                  </button>
                </div>
              </div>

              <%!-- Native selects, not toggle groups: fifteen faces, and
              select options render in the system stack, so opening one
              fetches nothing (labels in their own faces would pull all
              ~276 KB). Row labels preview each role's CURRENT face - the
              answer to "which dropdown affects what", live. --%>
              <div class="flex flex-col gap-2">
                <div
                  :for={
                    {event, name, value, label, preview} <- [
                      {"set_font_heading", "heading", @font_heading, "Heading",
                       "var(--pc-font-heading, var(--pc-font-body, inherit))"},
                      {"set_font_body", "body", @font_body, "Body", "var(--pc-font-body, inherit)"},
                      {"set_font_mono", "mono", @font_mono, "Mono",
                       "var(--pc-font-mono, var(--font-mono, ui-monospace, monospace))"}
                    ]
                  }
                  class="flex items-center justify-between gap-3"
                >
                  <label
                    for={"pg-typeset-" <> name}
                    class="text-xs text-gray-500 dark:text-gray-400"
                    style={"font-family: #{preview}"}
                  >
                    {label}
                  </label>
                  <form phx-change={event}>
                    <select
                      id={"pg-typeset-" <> name}
                      name={name}
                      class="h-7 w-36 py-0 pl-2 pr-7 text-xs font-medium border rounded-md border-gray-300 bg-white text-gray-600 dark:border-gray-400/25 dark:bg-gray-900 dark:text-gray-300 focus:ring-0 focus-visible:ring-2 focus-visible:ring-primary-500/50 focus-visible:border-primary-500"
                    >
                      {Phoenix.HTML.Form.options_for_select(@font_select_options, value)}
                    </select>
                  </form>
                </div>
              </div>
            </div>
          </.popover>
        </div>
        <div class="flex items-center gap-3 ml-auto shrink-0">
          <span class="hidden text-[11px] text-gray-400 dark:text-gray-600 sm:block">
            theme is in the URL, share the look
          </span>
          <.button size="xs" color="gray" variant="outline" phx-click={show_modal("pg-get-code")}>
            <.icon name="hero-code-bracket-mini" class="w-3.5 h-3.5" /> Get code
          </.button>
        </div>
      </div>

      <%!-- Get Code: the dialed look as a paste-ready start story. Content is
      recomputed from the live assigns, so it always matches the strip. --%>
      <.modal id="pg-get-code" hide title="Get code" max_width="lg">
        <p class="text-sm text-gray-500 dark:text-gray-400">
          Your dialed-in look, ready to paste: install petal_components, apply
          the theme, self-host the faces - or hand the whole thing to your
          coding agent.
        </p>
        <div :for={{{title, snippet}, i} <- Enum.with_index(get_code_sections(assigns))} class="mt-5">
          <div class="flex items-center justify-between mb-1.5">
            <div class="text-xs font-medium text-gray-400 dark:text-gray-500">{title}</div>
            <button
              id={"pg-get-code-copy-#{i}"}
              phx-hook="PetalCopy"
              data-copy-text={snippet}
              class="text-xs font-medium text-gray-500 hover:text-gray-900 dark:text-gray-400 dark:hover:text-white"
            >
              <span data-pc-copy-default>Copy</span>
              <span data-pc-copy-done class="hidden text-success-600 dark:text-success-400">Copied</span>
            </button>
          </div>
          <pre class="p-3 overflow-x-auto text-xs leading-relaxed text-gray-100 bg-gray-900 rounded-lg dark:border dark:border-gray-800"><code>{snippet}</code></pre>
        </div>
      </.modal>

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

  defp slider_bounds("money"),
    do: %{bound_min: 0, bound_max: 1000, step: 25, prefix: "$", suffix: "", label: "Price range"}

  defp slider_bounds("percent"),
    do: %{bound_min: 0, bound_max: 100, step: 5, prefix: "", suffix: "%", label: "Discount range"}

  defp slider_bounds("plain"),
    do: %{bound_min: 0, bound_max: 100, step: 1, prefix: "", suffix: "", label: "Value range"}

  defp slider_form("money"), do: to_form(%{"min" => "250", "max" => "750"}, as: :pg_range)
  defp slider_form("percent"), do: to_form(%{"min" => "20", "max" => "80"}, as: :pg_range)
  defp slider_form("plain"), do: to_form(%{"min" => "25", "max" => "75"}, as: :pg_range)

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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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

  defp render_page(%{active: "alert-dialog"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Alert dialog</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        One question, two answers, and no way out without picking one. Unlike
        the modal, focus opens on Cancel, Escape cancels, and clicking the
        backdrop does nothing - the friction is deliberate. Built on the native
        &lt;dialog&gt;, so the top layer and the focus trap come from the browser.
        The default treatment is calm; <code>variant="destructive"</code>
        is the explicit opt-in to the danger wash.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center justify-center gap-3 px-6 py-14">
          <.button
            color="gray"
            variant="outline"
            phx-click={PetalComponents.AlertDialog.open_alert_dialog("pg-alert-dialog")}
          >
            Open alert dialog
          </.button>

          <p :if={@alert_dialog_result} class="text-sm text-gray-500 dark:text-gray-400">
            You chose <span class="font-semibold">{@alert_dialog_result}</span>.
          </p>
          <p :if={!@alert_dialog_result} class="text-sm text-gray-400 dark:text-gray-500">
            Open it, then Tab between the actions and hit Escape.
          </p>

          <.alert_dialog
            id="pg-alert-dialog"
            variant={@alert_dialog.variant}
            title={
              if @alert_dialog.variant == "destructive",
                do: "Delete this workspace?",
                else: "Publish these changes?"
            }
            description={
              if @alert_dialog.description == "with",
                do:
                  if(@alert_dialog.variant == "destructive",
                    do:
                      "Everyone on the team loses access straight away, and the deployment history goes with it.",
                    else: "The new version goes live for every visitor as soon as you confirm."
                  ),
                else: nil
            }
            confirm_label={
              if @alert_dialog.variant == "destructive", do: "Delete workspace", else: "Publish"
            }
            on_confirm={JS.push("alert_dialog_answer", value: %{answer: "confirm"})}
            on_cancel={JS.push("alert_dialog_answer", value: %{answer: "cancel"})}
          >
            <:media :if={@alert_dialog.media == "icon"}>
              <.icon
                name={
                  if @alert_dialog.variant == "destructive",
                    do: "hero-trash",
                    else: "hero-rocket-launch"
                }
                class="pc-alert-dialog__media-icon"
              />
            </:media>
            <:media :if={@alert_dialog.media == "image"}>
              <img src="/dev-static/avatars/p32.jpg" alt="" />
            </:media>
            <div :if={@alert_dialog.length == "long"} class="space-y-3">
              <p>
                {if @alert_dialog.variant == "destructive",
                  do: "Deleting this workspace also removes:",
                  else: "Publishing updates:"}
              </p>
              <ul class="pl-4 space-y-1 list-disc marker:text-gray-400">
                <li :for={n <- 1..12}>
                  {if @alert_dialog.variant == "destructive",
                    do: "Project #{n} and its #{n * 3} deployments",
                    else: "Project #{n} and its #{n * 3} pages"}
                </li>
              </ul>
              <p :if={@alert_dialog.variant == "destructive"}>
                Billing stops at the end of the current period. Invoices already
                issued stay in your records and are not refunded automatically.
              </p>
              <p :if={@alert_dialog.variant != "destructive"}>
                Drafts stay unpublished. You can roll back to the previous
                version from the deploy history at any time.
              </p>
            </div>
          </.alert_dialog>
        </div>

        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Variant"
              value={@alert_dialog.variant}
              on_change="ctl_alert_dialog"
            >
              <:item
                :for={v <- ~w(default destructive)}
                value={v}
                phx-value-k="variant"
                phx-value-v={v}
              >
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">media</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Media"
              value={@alert_dialog.media}
              on_change="ctl_alert_dialog"
            >
              <:item :for={m <- ~w(none icon image)} value={m} phx-value-k="media" phx-value-v={m}>
                {m}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">description</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Description"
              value={@alert_dialog.description}
              on_change="ctl_alert_dialog"
            >
              <:item
                :for={d <- ~w(with without)}
                value={d}
                phx-value-k="description"
                phx-value-v={d}
              >
                {d}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">content length</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Content length"
              value={@alert_dialog.length}
              on_change="ctl_alert_dialog"
            >
              <:item :for={l <- ~w(short long)} value={l} phx-value-k="length" phx-value-v={l}>
                {l}
              </:item>
            </.toggle_group>
          </div>
        </div>
        <p class="px-6 pb-3 -mt-1 text-xs text-gray-400 dark:text-gray-500">
          long proves the overflow: the body scrolls, the title and the action row stay put, and the page behind never moves
        </p>
      </div>

      <div class="p-4 mt-6 text-sm border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="font-semibold text-gray-900 dark:text-gray-100">Keyboard</div>
        <ul class="mt-2 space-y-1 text-gray-500 dark:text-gray-400">
          <li>
            Open it and focus lands on <span class="font-medium">Cancel</span>, not the confirm button.
          </li>
          <li>
            <span class="font-medium">Tab</span>
            / <span class="font-medium">Shift+Tab</span>
            cycle the two actions and never leave the dialog.
          </li>
          <li>
            <span class="font-medium">Escape</span>
            cancels, running the same on_cancel as the Cancel button.
          </li>
          <li>Clicking the backdrop does nothing at all.</li>
          <li>
            However you leave - Escape, either button, <code>close_alert_dialog/2</code>
            - the exit runs through one funnel, so the dialog fades and scales out
            instead of snapping. Turn on reduce-motion and it goes instantly.
          </li>
        </ul>
      </div>

      <div :for={ex <- PetalComponents.Showcase.AlertDialog.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <%!-- the brief's live-assign proof: the showcase macro rightly forbids
            interpolation, so THIS example lives only here - the count in the
            body reads a socket assign, changing as you pick rows --%>
      <div class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">A body that reads live state</h2>
        <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          The inner block is ordinary HEEx, so the confirmation can carry whatever the
          socket knows - here, how many rows are ticked right now.
        </p>
        <div class="p-8 border border-gray-200 rounded-xl dark:border-gray-800">
          <div class="flex flex-wrap items-center gap-4">
            <label
              :for={n <- 1..4}
              class="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-300"
            >
              <.field
                type="checkbox"
                name={"bulk-row-#{n}"}
                checked={n in @alert_dialog_rows}
                phx-click="alert_dialog_toggle_row"
                phx-value-row={n}
                wrapper_class="mb-0"
              /> Invoice {n}
            </label>
            <.alert_dialog
              id="pg-alert-bulk"
              variant="destructive"
              title="Delete selected invoices?"
              confirm_label="Delete"
              on_confirm={
                Phoenix.LiveView.JS.push("alert_dialog_answer", value: %{answer: "bulk delete"})
              }
            >
              <:trigger>
                <.button
                  color="danger"
                  variant="outline"
                  size="sm"
                  disabled={@alert_dialog_rows == []}
                >
                  Delete selected
                </.button>
              </:trigger>
              This permanently removes
              <span class="font-semibold">{length(@alert_dialog_rows)} selected invoices</span>
              and their payment history.
            </.alert_dialog>
          </div>
        </div>
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.AlertDialog} function={:alert_dialog} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.AlertDialog</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
          class={@rail_class}
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

  defp render_page(%{active: "qr-code"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">QR code</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Encoded on the server and emitted as inline SVG. No JavaScript, no canvas, crisp at
        any size, and it prints. Every dark module goes into a single path, so even a dense
        code is one DOM node. Colour rides currentColor; size rides classes.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class={[
          "flex items-center justify-center px-6 py-12",
          @qr.surface == "dark" && "bg-gray-900"
        ]}>
          <div class={@qr.surface == "light" && "p-5 bg-white rounded-xl"}>
            <.qr_code
              value={qr_value(@qr.value)}
              error_correction={String.to_existing_atom(@qr.ec)}
              rounded={qr_rounded(@qr.rounded)}
              background={if @qr.surface == "light", do: "white", else: "transparent"}
              label="QR code for the value shown below"
              class={[
                qr_size_class(@qr.size),
                if(@qr.surface == "light", do: "text-gray-900", else: "text-white")
              ]}
            >
              <:logo :if={@qr.logo}>
                <div class="flex items-center justify-center w-full h-full text-5xl font-bold">
                  <span class="text-primary-600">PC</span>
                </div>
              </:logo>
            </.qr_code>
          </div>
        </div>

        <div class="px-4 pb-4 sm:px-6">
          <form phx-change="ctl_qr_value">
            <label class="block mb-2 text-[11px] font-medium tracking-wide text-gray-400">
              value being encoded
            </label>
            <input
              type="text"
              name="pg_qr_value"
              value={@qr.value}
              autocomplete="off"
              class="w-full px-3 py-2 font-mono text-xs text-gray-900 bg-white border border-gray-300 rounded-lg dark:border-gray-700 dark:bg-gray-900 dark:text-gray-100"
            />
          </form>
          <p class="mt-2 text-xs text-gray-400 dark:text-gray-500">
            The same information is right here as text - a QR code must never be the only way in.
          </p>
        </div>

        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">content</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Content preset"
              value={@qr.preset}
              on_change="ctl_qr"
              class={@rail_class}
            >
              <:item :for={p <- ~w(url totp wifi)} value={p} phx-value-k="preset" phx-value-v={p}>
                {p}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Size"
              value={@qr.size}
              on_change="ctl_qr"
              class={@rail_class}
            >
              <:item :for={s <- ~w(sm md lg xl)} value={s} phx-value-k="size" phx-value-v={s}>
                {s}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">
              error correction
            </div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Error correction"
              value={@qr.ec}
              on_change="ctl_qr"
              class={@rail_class}
            >
              <:item :for={e <- ~w(l m q h)} value={e} phx-value-k="ec" phx-value-v={e}>
                {e}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">modules</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Module rounding"
              value={@qr.rounded}
              on_change="ctl_qr"
              class={@rail_class}
            >
              <:item value="0" phx-value-k="rounded" phx-value-v="0">square</:item>
              <:item value="0.5" phx-value-k="rounded" phx-value-v="0.5">soft</:item>
              <:item value="1" phx-value-k="rounded" phx-value-v="1">dots</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">surface</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Surface"
              value={@qr.surface}
              on_change="ctl_qr"
              class={@rail_class}
            >
              <:item value="light" phx-value-k="surface" phx-value-v="light">white card</:item>
              <:item value="dark" phx-value-k="surface" phx-value-v="dark">inverted</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">logo</div>
            <button
              phx-click="flip"
              phx-value-k="qr_logo"
              class="px-3 py-1.5 text-sm border border-gray-300 rounded-lg dark:border-gray-700"
            >
              {if @qr.logo, do: "on", else: "off"}
            </button>
          </div>
        </div>
        <p class="px-6 pb-3 -mt-1 text-xs text-gray-400 dark:text-gray-500">
          turning the logo on forces error correction to :h - watch the code get denser, that is
          the redundancy that lets it survive the hole
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
      ><code>{qr_snippet(@qr)}</code></pre>

      <%!-- the registry is the single source: View Code panels + petal.build
            render these same examples, so the demos can never drift --%>
      <div
        :for={ex <- examples_for(PetalComponents.Showcase.QrCode, ~w(totp share dark_surface logo)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.QrCode} function={:qr_code} />
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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

      <div class="mt-8 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Type tokens</div>
      <div class="px-8 py-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <.p>
          Everything on this page follows the <strong>type</strong>
          dials in the strip above: three opt-in tokens
          (<.inline_code>--pc-font-heading</.inline_code>, <.inline_code>--pc-font-body</.inline_code>,
          <.inline_code>--pc-font-mono</.inline_code>) that the library reads but never defines,
          so an app that sets nothing keeps its own stack. Heading falls back through body,
          so one body token restyles everything.
        </.p>
        <.text_muted>
          Dial in a look, then share the URL - the theme travels in the query string.
        </.text_muted>
      </div>

      <div class="mt-10 mb-3 text-xs font-medium text-gray-400 dark:text-gray-500">Headings</div>
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
        The general dialog (shadcn calls it "Dialog"), on the panel surface
        with a proper scrim. It is light-dismissible on purpose: close button,
        click-away, Escape. The box is a column, so the body scrolls and the
        :footer band stays pinned under it. When the user has to answer, and
        walking away would leave it ambiguous what happened, reach for the
        alert dialog instead - it asks one question with two answers and
        ignores backdrop clicks.
      </p>
      <p class="mt-3 text-sm text-gray-500 dark:text-gray-400">
        The flagship ships the way the component does: click-away closes it.
        That includes clicking a dial while it is open - the dial still
        registers, so reopen to see the change. Flip <code>click away</code>
        off to keep it up while you play.
      </p>

      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center px-6 py-16">
          <.button color="gray" variant="outline" phx-click={show_modal("pg-modal")}>
            Open modal
          </.button>
        </div>

        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">max width</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Max width"
              value={@modal.max_width}
              on_change="ctl_modal"
              class={@rail_class}
            >
              <:item
                :for={w <- ~w(sm md lg xl 2xl full)}
                value={w}
                phx-value-k="max_width"
                phx-value-v={w}
              >
                {w}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">footer</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Footer"
              value={@modal.footer}
              on_change="ctl_modal"
              class={@rail_class}
            >
              <:item :for={f <- ~w(none actions)} value={f} phx-value-k="footer" phx-value-v={f}>
                {f}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">content</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Content"
              value={@modal.content}
              on_change="ctl_modal"
              class={@rail_class}
            >
              <:item :for={c <- ~w(short long)} value={c} phx-value-k="content" phx-value-v={c}>
                {c}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">chrome</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="Chrome"
              value={
                for {k, on} <- [
                      {"header", @modal.header},
                      {"close", @modal.close},
                      {"dismiss", @modal.dismiss}
                    ],
                    on,
                    do: k
              }
              on_change="ctl_modal"
              class={@rail_class}
            >
              <:item value="header" phx-value-k="header">header</:item>
              <:item value="close" phx-value-k="close">close button</:item>
              <:item value="dismiss" phx-value-k="dismiss">click away</:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <.modal
        id="pg-modal"
        hide
        title="Invite your team"
        max_width={@modal.max_width}
        hide_header={!@modal.header}
        hide_close_button={!@modal.close}
        close_on_click_away={@modal.dismiss}
      >
        <p class="text-sm text-gray-500 dark:text-gray-400">
          Share this link with your teammates and they'll join the workspace
          with member access.
        </p>
        <div class="mt-4">
          <.input_group>
            <.input type="text" name="pg_invite_url" value="https://example.com/join/x1y2z3" readonly />
            <:trailing><kbd><span>⌘</span>C</kbd></:trailing>
          </.input_group>
        </div>
        <div :if={@modal.content == "long"} class="flex flex-col gap-4 mt-4">
          <p :for={n <- 1..10} class="text-sm text-gray-500 dark:text-gray-400">
            Note {n}. Anyone with the link can join until you revoke it, and
            revoking it does not remove people who already used it. Keep
            scrolling: the action row below is pinned, so it never leaves.
          </p>
        </div>
        <:footer :if={@modal.footer == "actions"}>
          <.button color="gray" variant="outline" phx-click={hide_modal("pg-modal")}>
            Cancel
          </.button>
          <.button phx-click={hide_modal("pg-modal")}>Copy link</.button>
        </:footer>
      </.modal>

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
      ><code>{modal_snippet(@modal)}</code></pre>

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

  defp render_page(%{active: "file-upload"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">File upload</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A dropzone over Phoenix.LiveView uploads. Every upload on this page is
        real: drag a file in, watch the progress, cancel it mid-flight. The
        component renders the UploadConfig it is handed, so the validation and
        the progress are the server's, not the browser's.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="px-6 py-10">
          <form id="pg-upload-form" phx-change="pg_upload_validate" phx-submit="pg_upload_save">
            <.file_upload
              upload={@uploads.pg_files}
              variant={@file_upload.variant}
              label="Drop images or PDFs here"
              cancel_event="pg_upload_cancel_files"
            />
            <div class="flex flex-wrap items-center gap-3 mt-4">
              <.button type="submit" size="sm" disabled={@uploads.pg_files.entries == []}>
                Save
              </.button>
              <span
                :if={@file_upload.saved != []}
                class="text-sm text-gray-500 dark:text-gray-400"
              >
                consumed: {Enum.join(@file_upload.saved, ", ")}
              </span>
            </div>
          </form>
        </div>
        <div class="flex flex-wrap items-end px-4 py-4 border-t border-gray-200 gap-x-8 gap-y-4 sm:px-6 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Variant"
              value={@file_upload.variant}
              on_change="ctl_file_upload"
            >
              <:item
                :for={v <- ~w(dropzone compact avatar gallery)}
                value={v}
                phx-value-k="variant"
                phx-value-v={v}
              >
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">max_entries</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Max entries"
              value={to_string(@file_upload.max_entries)}
              on_change="ctl_file_upload"
            >
              <:item :for={v <- ~w(1 4 8)} value={v} phx-value-k="max" phx-value-v={v}>
                {v}
              </:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <div class="p-4 mt-4 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        <span class="font-medium text-gray-700 dark:text-gray-200">Keyboard only:</span>
        tab into the zone (the native input is clipped, not hidden, so it stays
        in the tab order and the zone shows its focus ring), press Enter or
        Space to open the picker, then tab on to each file's cancel button -
        every one is named after its file.
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">auto_upload, both ways</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        With auto_upload the bytes start moving the moment you pick a file.
        Without it the entries sit at 0% until the form is submitted, which is
        why the row still has to read sensibly at zero.
      </p>
      <div class="grid gap-4 sm:grid-cols-2">
        <div class="p-4 border border-gray-200 rounded-xl dark:border-gray-800">
          <div class="mb-3 font-mono text-xs text-gray-400">auto_upload: true</div>
          <form id="pg-upload-auto" phx-change="pg_upload_validate">
            <.file_upload
              upload={@uploads.pg_auto}
              label="Uploads on pick"
              cancel_event="pg_upload_cancel_auto"
            />
          </form>
        </div>
        <div class="p-4 border border-gray-200 rounded-xl dark:border-gray-800">
          <div class="mb-3 font-mono text-xs text-gray-400">auto_upload: false</div>
          <form id="pg-upload-manual" phx-change="pg_upload_validate">
            <.file_upload
              upload={@uploads.pg_manual}
              label="Waits for submit"
              cancel_event="pg_upload_cancel_manual"
            />
          </form>
        </div>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Profile photo</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        One circular target, one file. Hover or tab to it for the replace
        overlay; pick an image and the preview takes over the circle.
      </p>
      <div class="p-6 border border-gray-200 rounded-xl dark:border-gray-800">
        <form id="pg-upload-avatar" phx-change="pg_upload_validate">
          <.file_upload
            upload={@uploads.pg_avatar}
            variant="avatar"
            label="Profile photo"
            cancel_event="pg_upload_cancel_avatar"
          />
        </form>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Listing photos</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        The gallery grid, six photos deep. Each tile carries its own progress
        and cancel; the add tile bows out once the config is full. The two
        photos already on this listing come through the :existing slot as
        plain URLs, so an edit form shows what is saved next to what is being
        dragged in. Their X is this page's own remove event, not a cancel.
      </p>
      <div class="p-6 border border-gray-200 rounded-xl dark:border-gray-800">
        <form id="pg-upload-gallery" phx-change="pg_upload_validate">
          <.file_upload
            upload={@uploads.pg_gallery}
            variant="gallery"
            label="Listing photos"
            cancel_event="pg_upload_cancel_gallery"
          >
            <:existing
              :for={photo <- @file_upload.photos}
              src={photo.url}
              name={photo.name}
              remove_event="pg_photo_remove"
              remove_value={photo.id}
            />
          </.file_upload>
        </form>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Documents, with a cap you can trip</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        max_file_size is set to 20 KB here on purpose. Drop anything bigger and
        the row turns and says why, with the message tied to the file so a
        screen reader reads the two together.
      </p>
      <div class="p-6 border border-gray-200 rounded-xl dark:border-gray-800">
        <form id="pg-upload-small" phx-change="pg_upload_validate">
          <.file_upload
            upload={@uploads.pg_small}
            label="Attach supporting documents"
            cancel_event="pg_upload_cancel_small"
          />
        </form>
      </div>

      <div :for={ex <- PetalComponents.Showcase.FileUpload.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.FileUpload} function={:file_upload} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        The examples above render statically from the shared
        <code>PetalComponents.Showcase.FileUpload</code>
        registry, so their thumbnails stay blank - <code>live_img_preview</code>
        needs a running LiveView. The live sections at the top of this page are
        the real thing.
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10" data-pc-drawer-wrapper>
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
              class={@rail_class}
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
              class={@rail_class}
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

      <h2 class="mt-12 text-lg font-semibold">Bottom-sheet drawer</h2>
      <p class="mt-1 mb-3 text-sm text-gray-500 dark:text-gray-400">
        <code>origin="bottom"</code>
        is a mobile drawer: rounded top corners, a grab handle, safe-area padding, and
        drag-to-dismiss. Grab the sheet anywhere its body is scrolled to the top and pull it
        down, or flick it. Escape, click-away and the close button work exactly as they always
        did - dragging routes through the same close event. Judge this one at phone width.
      </p>

      <div class="border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center px-6 py-16">
          <.button
            color="gray"
            variant="outline"
            phx-click={PetalComponents.SlideOver.show_slide_over("bottom", "pg-drawer")}
          >
            <.icon name="hero-adjustments-horizontal" class="w-4 h-4 mr-1" /> Open drawer
          </.button>
        </div>

        <div class="grid gap-5 px-6 py-5 border-t border-gray-100 md:grid-cols-2 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">handle</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Handle"
              value={(@drawer.handle && "on") || "off"}
              on_change="ctl_drawer"
              class={@rail_class}
            >
              <:item value="on" phx-value-k="handle" phx-value-v="on">on</:item>
              <:item value="off" phx-value-k="handle" phx-value-v="off">off</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">
              drag to dismiss
            </div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Drag to dismiss"
              value={(@drawer.drag && "on") || "off"}
              on_change="ctl_drawer"
              class={@rail_class}
            >
              <:item value="on" phx-value-k="drag" phx-value-v="on">on</:item>
              <:item value="off" phx-value-k="drag" phx-value-v="off">off</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">snap points</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Snap points"
              value={@drawer.snaps}
              on_change="ctl_drawer"
              class={@rail_class}
            >
              <:item value="off" phx-value-k="snaps" phx-value-v="off">off</:item>
              <:item value="0.4-0.9" phx-value-k="snaps" phx-value-v="0.4-0.9">
                [0.4, 0.9]
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">
              scale background
            </div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Scale background"
              value={(@drawer.scale && "on") || "off"}
              on_change="ctl_drawer"
              class={@rail_class}
            >
              <:item value="on" phx-value-k="scale" phx-value-v="on">on</:item>
              <:item value="off" phx-value-k="scale" phx-value-v="off">off</:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <.slide_over
        id="pg-drawer"
        hide
        origin="bottom"
        handle={@drawer.handle}
        drag_to_dismiss={@drawer.drag}
        snap_points={(@drawer.snaps == "0.4-0.9" && [0.4, 0.9]) || nil}
        initial_snap={(@drawer.snaps == "0.4-0.9" && 0.4) || nil}
        scale_background={@drawer.scale}
        title="Filters"
        description="Narrow the list down"
      >
        <div class="flex flex-col gap-3">
          <.field
            :for={
              {name, label, checked} <- [
                {"pg_stock", "In stock", true},
                {"pg_preorder", "Available to pre-order", false},
                {"pg_soon", "Back in soon", false},
                {"pg_under_50", "Under $50", true},
                {"pg_50_150", "$50 to $150", false},
                {"pg_over_150", "Over $150", false},
                {"pg_free_ship", "Free shipping", false},
                {"pg_rated", "Rated 4 stars and up", false}
              ]
            }
            type="checkbox"
            name={name}
            value={checked}
            label={label}
          />
        </div>
        <:footer>
          <div class="flex items-center justify-between w-full gap-4">
            <.button
              color="gray"
              variant="ghost"
              phx-click={PetalComponents.SlideOver.hide_slide_over("bottom", "pg-drawer")}
            >
              Clear all
            </.button>
            <.button phx-click={PetalComponents.SlideOver.hide_slide_over("bottom", "pg-drawer")}>
              Show 42 results
            </.button>
          </div>
        </:footer>
      </.slide_over>

      <div
        :for={
          ex <-
            examples_for(
              PetalComponents.Showcase.SlideOver,
              ~w(cart filter_drawer queue_drawer action_drawer)a
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
      <.showcase_props component={PetalComponents.SlideOver} function={:slide_over} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.SlideOver</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "empty"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Empty state</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        What a list, table, inbox or search renders when it has nothing to show.
        Media, title, description, actions, a trailing line - every part optional,
        pure markup and CSS.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center px-6 py-12">
          <div class="w-full max-w-xl">
            <.empty
              variant={@empty.variant}
              size={@empty.size}
              title="No projects yet"
              description="Projects hold your environments, deploys and team access. Create one to get started."
            >
              <:actions :if={@empty.actions != "none"}>
                <.button size="sm" label="Create project" />
                <.button
                  :if={@empty.actions == "both"}
                  size="sm"
                  variant="outline"
                  color="gray"
                  label="Import from Git"
                />
              </:actions>
            </.empty>
          </div>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Variant"
              value={@empty.variant}
              on_change="ctl_empty"
            >
              <:item
                :for={v <- ~w(default compact card dashed)}
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
              value={@empty.size}
              on_change="ctl_empty"
            >
              <:item :for={s <- ~w(sm md lg)} value={s} phx-value-k="size" phx-value-v={s}>
                {s}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">actions</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Actions"
              value={@empty.actions}
              on_change="ctl_empty"
            >
              <:item :for={a <- ~w(none primary both)} value={a} phx-value-k="actions" phx-value-v={a}>
                {a}
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
      ><code>{empty_snippet(@empty)}</code></pre>

      <div :for={ex <- PetalComponents.Showcase.Empty.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Empty} function={:empty} />
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
              class={@rail_class}
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
              class={@rail_class}
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
              steps={pg_steps(@stepper.at, @stepper.done, @stepper.labels)}
              orientation={@stepper.orientation}
              size={@stepper.size}
              variant={@stepper.variant}
              label_placement={if @stepper.labels == "none", do: "beside", else: @stepper.labels}
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
                <%!-- "Step 3 of 4" is composition, not an attr: the stepper
                draws the rail, the page owns the row underneath. It's the
                whole labelling story when the steps have no names. --%>
                <span class="text-sm text-gray-500 tabular-nums dark:text-gray-400">
                  Step {@stepper.at + 1} of {length(pg_step_defs())}
                </span>
                <.button phx-click="ctl_stepper" phx-value-k="next">
                  {if @stepper.at == length(pg_step_defs()) - 1, do: "Complete", else: "Continue"}
                </.button>
              </div>
            <% end %>
          </div>
        </div>
        <div class="grid gap-5 px-6 py-5 border-t border-gray-100 sm:grid-cols-2 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">orientation</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Orientation"
              value={@stepper.orientation}
              on_change="ctl_stepper"
              class={@rail_class}
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
              class={@rail_class}
            >
              <:item :for={sz <- ~w(xs sm md lg)} value={sz} phx-value-k="size" phx-value-v={sz}>
                {sz}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Variant"
              value={@stepper.variant}
              on_change="ctl_stepper"
              disabled={@stepper.orientation == "vertical"}
              class={@rail_class}
            >
              <:item :for={v <- ~w(circles bars)} value={v} phx-value-k="variant" phx-value-v={v}>
                {v}
              </:item>
            </.toggle_group>
            <div :if={@stepper.orientation == "vertical"} class="mt-1.5 text-[10px] text-gray-400">
              horizontal only
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">labels</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Labels"
              value={@stepper.labels}
              on_change="ctl_stepper"
              class={@rail_class}
            >
              <:item
                :for={lp <- ~w(beside bottom none)}
                value={lp}
                phx-value-k="labels"
                phx-value-v={lp}
              >
                {lp}
              </:item>
            </.toggle_group>
            <div :if={stepper_labels_hint(@stepper)} class="mt-1.5 text-[10px] text-gray-400">
              {stepper_labels_hint(@stepper)}
            </div>
          </div>
        </div>

        <div class="px-6 pb-5">
          <button
            phx-click="flip"
            phx-value-k="show_code"
            class="inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
          >
            <.icon name="hero-code-bracket" class="w-4 h-4" />
            {if @show_code, do: "Hide code", else: "View code"}
          </button>
          <pre
            :if={@show_code}
            class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"
          ><code>{stepper_snippet(@stepper)}</code></pre>
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

  defp render_page(%{active: "timeline"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Timeline</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A record of things that happened - activity feeds, deploy logs, order tracking,
        company history. Nothing here is clickable: if the user is meant to move through
        it, you want the stepper instead.
      </p>
      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="px-6 py-8">
          <.timeline
            orientation={@timeline.orientation}
            variant={@timeline.variant}
            connector={@timeline.connector}
            time_placement={@timeline.time_placement}
            label="Release pipeline"
          >
            <:item
              :for={e <- pg_timeline_entries(@timeline)}
              marker={e.marker}
              icon={e.icon}
              name={e.name}
              color={e.color}
              state={e.state}
              time={e.time}
              title={e.title}
              description={e.description}
            />
            <%!-- the local_time composition the docs promise: the time attr is a
                  plain string (Phoenix has no nested slots), so live timestamps
                  ride the entry BODY - this is the pattern to copy --%>
            <:item marker="dot" color="gray" state="complete" title="Nightly build archived">
              <span class="text-sm text-gray-500 dark:text-gray-400">
                Completed
                <.local_time
                  id="timeline-nightly-time"
                  at={DateTime.add(DateTime.utc_now(), -7, :hour)}
                  format="relative"
                /> on runner 4.
              </span>
            </:item>
          </.timeline>
        </div>
        <div class="grid gap-5 px-6 py-5 border-t border-gray-100 md:grid-cols-2 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">orientation</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Orientation"
              value={@timeline.orientation}
              on_change="ctl_timeline"
              class={@rail_class}
            >
              <:item
                :for={o <- ~w(vertical horizontal)}
                value={o}
                phx-value-k="orientation"
                phx-value-v={o}
              >
                {o}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Variant"
              value={@timeline.variant}
              on_change="ctl_timeline"
              disabled={@timeline.orientation == "horizontal"}
              class={@rail_class}
            >
              <:item
                :for={v <- ~w(default alternating compact)}
                value={v}
                phx-value-k="variant"
                phx-value-v={v}
              >
                {v}
              </:item>
            </.toggle_group>
            <div :if={@timeline.orientation == "horizontal"} class="mt-1.5 text-[10px] text-gray-400">
              vertical only
            </div>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">marker</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Marker"
              value={@timeline.marker}
              on_change="ctl_timeline"
              class={@rail_class}
            >
              <:item
                :for={m <- ~w(dot icon avatar number)}
                value={m}
                phx-value-k="marker"
                phx-value-v={m}
              >
                {m}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">connector</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Connector"
              value={@timeline.connector}
              on_change="ctl_timeline"
              class={@rail_class}
            >
              <:item :for={c <- ~w(solid dashed)} value={c} phx-value-k="connector" phx-value-v={c}>
                {c}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">
              time_placement
            </div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Time placement"
              value={@timeline.time_placement}
              on_change="ctl_timeline"
              disabled={@timeline.orientation == "horizontal" or @timeline.variant == "alternating"}
              class={@rail_class}
            >
              <:item
                :for={t <- ~w(top start)}
                value={t}
                phx-value-k="time_placement"
                phx-value-v={t}
              >
                {t}
              </:item>
            </.toggle_group>
            <div
              :if={@timeline.orientation == "horizontal" or @timeline.variant == "alternating"}
              class="mt-1.5 text-[10px] text-gray-400"
            >
              vertical default and compact only
            </div>
            <div
              :if={
                @timeline.time_placement == "start" and @timeline.orientation == "vertical" and
                  @timeline.variant != "alternating"
              }
              class="mt-1.5 text-[10px] text-gray-400"
            >
              the column shows from sm up - narrow the window and it folds back on top
            </div>
          </div>
          <div class="md:col-span-2">
            <.button
              size="sm"
              color="gray"
              variant={if(@timeline.states, do: "solid", else: "outline")}
              phx-click="ctl_timeline"
              phx-value-k="states"
            >
              {if @timeline.states,
                do: "States on: complete, current, upcoming",
                else: "States off: everything complete"}
            </.button>
          </div>
        </div>
      </div>
      <div :for={ex <- PetalComponents.Showcase.Timeline.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Timeline} function={:timeline} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Timeline</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift. (The pipeline above is playground-only - its dials push events.)
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

  defp render_page(%{active: "sidebar"} = assigns) do
    ~H"""
    <div class="max-w-4xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Sidebar</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        The app shell almost every LiveView product hand-rolls: grouped nav with icons and
        badges, a collapse rail, and a sheet takeover on mobile. Collapse is a data attribute
        flipped by LiveView.JS - no hook, no round trip.
      </p>

      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="p-6">
          <.sidebar_shell
            for="pg-sidebar"
            class="h-[30rem] min-h-0 overflow-hidden border border-gray-200 rounded-lg dark:border-gray-800"
          >
            <:sidebar>
              <.sidebar_nav
                id="pg-sidebar"
                label="Product"
                side={@sidebar.side}
                collapsible={@sidebar.collapsible}
                collapsed={@sidebar.collapsed}
              >
                <:header>
                  <.icon name="hero-cube" class="w-5 h-5 shrink-0 text-primary-500" />
                  <span class="pc-sidebar__brand">Acme Inc</span>
                  <.sidebar_trigger for="pg-sidebar" class="ml-auto" />
                </:header>

                <.sidebar_group label="Workspace">
                  <.sidebar_item
                    label="Dashboard"
                    path="#"
                    link_type="a"
                    icon="hero-home"
                    active
                  />
                  <.sidebar_item
                    label="Inbox"
                    path="#"
                    link_type="a"
                    icon="hero-inbox"
                    badge={if @sidebar.badges, do: "12"}
                  />
                  <.sidebar_item
                    label="Invoices"
                    path="#"
                    link_type="a"
                    icon="hero-document-text"
                    badge={if @sidebar.badges, do: "3"}
                  />
                </.sidebar_group>

                <.sidebar_group id="pg-sidebar-acct" label="Account" collapsible>
                  <.sidebar_item
                    id="pg-sidebar-settings"
                    label="Settings"
                    icon="hero-cog-6-tooth"
                    open
                  >
                    <.sidebar_item label="Profile" path="#" link_type="a" />
                    <.sidebar_item label="Billing" path="#" link_type="a" />
                  </.sidebar_item>
                  <.sidebar_item label="Team" path="#" link_type="a" icon="hero-user-group" />
                </.sidebar_group>

                <:footer>
                  <%!-- align follows the sidebar's side: an up-opening panel
                  grows in the align direction, and a start-aligned panel on a
                  right-hand rail grows straight out of the viewport. --%>
                  <.user_dropdown_menu
                    variant="sidebar"
                    current_user_name="Ada Lovelace"
                    current_user_email="ada@example.com"
                    side="top"
                    align={if @sidebar.side == "right", do: "end", else: "start"}
                    menu_items_wrapper_class="w-60"
                  >
                    <.dropdown_menu_label>ada@example.com</.dropdown_menu_label>
                    <.dropdown_menu_item link_type="button">
                      <.icon name="hero-user" class="w-4 h-4" /> Profile
                    </.dropdown_menu_item>
                    <.dropdown_menu_item link_type="button">
                      <.icon name="hero-adjustments-horizontal" class="w-4 h-4" /> Preferences
                    </.dropdown_menu_item>
                    <.dropdown_menu_separator />
                    <.dropdown_menu_item
                      link_type="button"
                      class="text-danger-600 dark:text-danger-400"
                    >
                      <.icon name="hero-arrow-right-start-on-rectangle" class="w-4 h-4" /> Sign out
                    </.dropdown_menu_item>
                  </.user_dropdown_menu>
                </:footer>
              </.sidebar_nav>
            </:sidebar>

            <header class="flex items-center flex-none gap-3 px-4 border-b border-gray-200 h-14 dark:border-gray-800">
              <.sidebar_trigger for="pg-sidebar" target="mobile" />
              <span class="text-sm font-semibold">Dashboard</span>
            </header>
            <div class="p-4 text-sm text-gray-500 dark:text-gray-400">
              Page content. Narrow the window below 768px and the sidebar becomes a sheet -
              this region goes inert, Escape closes it, and focus returns to the burger.
            </div>
          </.sidebar_shell>
        </div>

        <div class="grid gap-5 px-6 py-5 border-t border-gray-100 md:grid-cols-2 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">collapsible</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Collapse mode"
              value={@sidebar.collapsible}
              on_change="ctl_sidebar"
              class={@rail_class}
            >
              <:item
                :for={v <- ~w(icon offcanvas none)}
                value={v}
                phx-value-k="collapsible"
                phx-value-v={v}
              >
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">side</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Side"
              value={@sidebar.side}
              on_change="ctl_sidebar"
              class={@rail_class}
            >
              <:item :for={v <- ~w(left right)} value={v} phx-value-k="side" phx-value-v={v}>
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div class="md:col-span-2">
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">state</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="State"
              value={
                for {k, on} <- [{"collapsed", @sidebar.collapsed}, {"badges", @sidebar.badges}],
                    on,
                    do: k
              }
              on_change="ctl_sidebar"
              class={@rail_class}
            >
              <:item value="collapsed" phx-value-k="collapsed">collapsed on first paint</:item>
              <:item value="badges" phx-value-k="badges">badges</:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        The "collapsed on first paint" dial is the <code>collapsed</code>
        attr - it is what the server renders, so a live_redirect can never flash the wrong
        state. The toggle in the sidebar header is the client-side flip: it changes the DOM
        without telling the server, which is why re-running a dial resets it. Persist the
        choice by keeping it in your own assign and passing it back in. <br /><br />
        Collapse the rail and watch the header: the logo and the toggle stop sharing one
        4rem line and take a row each. The footer is <code>user_dropdown_menu</code>
        with <code>variant="sidebar"</code>, not a hand-rolled avatar row, and it drops to
        the avatar on the rail the same way items drop to their icons - the name and email
        go screen-reader-only, so the button keeps its accessible name.
      </div>

      <div :for={ex <- PetalComponents.Showcase.Sidebar.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props
        component={PetalComponents.Sidebar}
        functions={[:sidebar_shell, :sidebar, :sidebar_group, :sidebar_item, :sidebar_trigger]}
      />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Sidebar</code>
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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

  defp render_page(%{active: "hover-card"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Hover card</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A rich preview that opens when the pointer rests on its trigger, or when
        keyboard focus lands inside it. Interactive content, unlike a tooltip.
        No click needed, unlike a popover. Pure CSS - the delays are custom
        properties, not JavaScript.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <%!-- The frame clips (overflow-hidden), so the preview itself has to
              hold the open card at every placement or the dial reads as a
              component bug. Vertically: the card runs ~220px, so a centred
              trigger needs two of those plus the two 8px gaps and its own
              line - min-h-[34rem] clears that with room to spare.
              Horizontally: below md the frame is narrower than trigger + gap +
              two card widths, so a centred trigger would push the -start/-end
              and side placements out through the edge. Park the trigger on the
              side the card grows AWAY from until md, where centring fits. --%>
        <div class={[
          "flex items-center px-4 sm:px-6 py-16 min-h-[34rem] md:justify-center",
          hover_card_demo_justify(@hover_card.placement)
        ]}>
          <%!-- stable id: dial changes patch this subtree, and without it
                LiveView re-mints the generated id attribute every render --%>
          <.hover_card
            id="hover-card-hero"
            placement={@hover_card.placement}
            open_delay={@hover_card.open_delay}
            close_delay={@hover_card.close_delay}
          >
            <:trigger>
              <a href="#" class="font-medium text-primary-600 dark:text-primary-400 hover:underline">
                @jane
              </a>
            </:trigger>
            <%!-- narrower on phones: a full-width card plus the trigger and
                  the gap is wider than the frame at 375px --%>
            <div class="w-56 sm:w-64">
              <div class="flex items-start gap-3">
                <.avatar name="Jane Doe" size="md" />
                <div class="min-w-0">
                  <div class="text-sm font-semibold">Jane Doe</div>
                  <div class="text-xs text-gray-500 dark:text-gray-400">@jane</div>
                </div>
              </div>
              <p class="mt-3 text-sm text-gray-600 dark:text-gray-300">
                Ships Phoenix apps for a living. Maintains three things she meant to archive.
              </p>
              <div class="flex items-center gap-4 mt-3 text-xs text-gray-500 dark:text-gray-400">
                <span>
                  <span class="font-semibold text-gray-900 dark:text-white">1,204</span> followers
                </span>
                <span>
                  <span class="font-semibold text-gray-900 dark:text-white">183</span> following
                </span>
              </div>
              <.button size="sm" color="primary" class="w-full mt-3" label="Follow" />
            </div>
          </.hover_card>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">placement</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Placement"
              value={@hover_card.placement}
              on_change="ctl_hover_card"
              class={@rail_class}
            >
              <:item
                :for={
                  pl <-
                    ~w(top top-start top-end bottom bottom-start bottom-end left left-start left-end right right-start right-end)
                }
                value={pl}
                phx-value-k="placement"
                phx-value-v={pl}
              >
                {pl}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">open delay</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Open delay"
              value={to_string(@hover_card.open_delay)}
              on_change="ctl_hover_card"
              class={@rail_class}
            >
              <:item
                :for={ms <- ~w(0 350 700)}
                value={ms}
                phx-value-k="open_delay"
                phx-value-v={ms}
              >
                {ms}ms
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">close delay</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Close delay"
              value={to_string(@hover_card.close_delay)}
              on_change="ctl_hover_card"
              class={@rail_class}
            >
              <:item
                :for={ms <- ~w(0 150 500)}
                value={ms}
                phx-value-k="close_delay"
                phx-value-v={ms}
              >
                {ms}ms
              </:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <p class="mt-3 text-sm text-gray-500 dark:text-gray-400">
        Keyboard: tab to the handle and the card opens on focus, then tab again to
        reach Follow inside it. Tab past the card to close it - there is no focus
        trap and no Escape, which is the honest cost of shipping this without a hook.
        On touch there is no hover at all, so the trigger has to stand on its own:
        tapping the handle follows the link, exactly as it would without the card.
      </p>

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
      ><code>{hover_card_snippet(@hover_card)}</code></pre>

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.HoverCard, ~w(link_preview placement)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.HoverCard} function={:hover_card} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.HoverCard</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "context-menu"} = assigns) do
    assigns =
      assign(assigns, :files, [
        %{
          id: "forecast",
          name: "Q3-forecast.xlsx",
          icon: "hero-document-chart-bar",
          meta: "Edited 2 days ago"
        },
        %{
          id: "brief",
          name: "Launch brief.md",
          icon: "hero-document-text",
          meta: "Edited 6 hours ago"
        },
        %{
          id: "hero",
          name: "hero-shot.png",
          icon: "hero-photo",
          meta: "Edited last week"
        }
      ])

    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Context menu</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A right-click menu attached to a region of the page. Same panel as the
        dropdown, different invocation: the menu opens at the cursor and clamps
        itself inside the viewport.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="px-4 py-8 sm:px-6">
          <p class="mb-5 text-sm text-gray-500 dark:text-gray-400">
            Right-click a card. On a phone, hold it for half a second. Keyboard only:
            tab to a card and press <kbd class="pc-kbd">⇧</kbd>
            <kbd class="pc-kbd">F10</kbd>
            (or the Menu key), then arrow through the items and press Escape to get out.
          </p>
          <div class="grid gap-3 sm:grid-cols-3">
            <%!-- disabled is baked into the id ON PURPOSE: flipping the dial
                  changes the id, forcing a remount so the hook attaches or
                  detaches. Simplify it to a stable id and the toggle stops
                  working (LiveView patches never re-run phx-hook wiring). --%>
            <.context_menu
              :for={f <- @files}
              id={"pg-cm-#{f.id}-#{@context_menu.disabled}"}
              disabled={@context_menu.disabled}
            >
              <:trigger>
                <div class="flex flex-col gap-3 p-4 bg-white border border-gray-200 rounded-xl dark:bg-gray-900 dark:border-gray-800">
                  <.icon name={f.icon} class="w-8 h-8 text-gray-400" />
                  <div class="min-w-0">
                    <div class="text-sm font-medium truncate">{f.name}</div>
                    <div class="text-xs text-gray-500 dark:text-gray-400">{f.meta}</div>
                  </div>
                </div>
              </:trigger>

              <.context_menu_label>{f.name}</.context_menu_label>
              <.context_menu_item link_type="button" kbd="↵">
                <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4" /> Open
              </.context_menu_item>
              <.context_menu_item link_type="button" kbd="F2">
                <.icon name="hero-pencil-square" class="w-4 h-4" /> Rename
              </.context_menu_item>
              <.context_menu_item link_type="button" kbd="⌘D">
                <.icon name="hero-square-2-stack" class="w-4 h-4" /> Duplicate
              </.context_menu_item>
              <.context_menu_item link_type="button" disabled>
                <.icon name="hero-lock-closed" class="w-4 h-4" /> Move to team folder
              </.context_menu_item>
              <.context_menu_separator />
              <.context_menu_item link_type="button" variant="danger" kbd="⌘⌫">
                <.icon name="hero-trash" class="w-4 h-4" /> Delete
              </.context_menu_item>
            </.context_menu>
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
              value={for {k, on} <- [{"disabled", @context_menu.disabled}], on, do: k}
              on_change="ctl_context_menu"
              class={@rail_class}
            >
              <:item value="disabled" phx-value-k="disabled">disabled</:item>
            </.toggle_group>
          </div>
          <p class="text-xs text-gray-400">
            disabled hands the region back to the browser's own menu.
          </p>
        </div>
      </div>

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.ContextMenu, ~w(text_selection)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.ContextMenu} function={:context_menu} />
      <.showcase_props component={PetalComponents.ContextMenu} function={:context_menu_item} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.ContextMenu</code>
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
            class={@rail_class}
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
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Slider</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        One thumb or two, on a native range input. The browser gives the keyboard
        map, the ARIA and the form posting; the library paints the track, the fill,
        the marks and the value bubble on top.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center px-6 py-16">
          <div class={if @slider.orientation == "vertical", do: "", else: "w-full max-w-sm"}>
            <.slider
              id="pg-slider-preview"
              name="pg_slider"
              label="Budget"
              value={60}
              values={if @slider.mode == "dual", do: [25, 75]}
              min={0}
              max={100}
              step={@slider.step}
              size={@slider.size}
              orientation={@slider.orientation}
              show_value={@slider.show_value}
              disabled={@slider.disabled}
              marks={if @slider.marks, do: slider_preview_marks(), else: []}
            />
          </div>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">mode</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Mode"
              value={@slider.mode}
              on_change="ctl_slider"
              class={@rail_class}
            >
              <:item :for={m <- ~w(single dual)} value={m} phx-value-k="mode" phx-value-v={m}>
                {m}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">show_value</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Show value"
              value={@slider.show_value}
              on_change="ctl_slider"
              class={@rail_class}
            >
              <:item
                :for={v <- ~w(none tooltip inline)}
                value={v}
                phx-value-k="show_value"
                phx-value-v={v}
              >
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">orientation</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Orientation"
              value={@slider.orientation}
              on_change="ctl_slider"
              class={@rail_class}
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
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">step</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Step"
              value={to_string(@slider.step)}
              on_change="ctl_slider"
              class={@rail_class}
            >
              <:item :for={s <- ~w(1 5 25)} value={s} phx-value-k="step" phx-value-v={s}>
                {s}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Size"
              value={@slider.size}
              on_change="ctl_slider"
              class={@rail_class}
            >
              <:item :for={z <- ~w(sm md lg)} value={z} phx-value-k="size" phx-value-v={z}>
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
                for {k, on} <- [{"marks", @slider.marks}, {"disabled", @slider.disabled}],
                    on,
                    do: k
              }
              on_change="ctl_slider"
              class={@rail_class}
            >
              <:item value="marks" phx-value-k="marks">marks</:item>
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

      <div class="flex items-start gap-2 p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        <.icon name="hero-command-line" class="w-4 h-4 mt-0.5 shrink-0" />
        <div>
          <span class="font-medium text-gray-700 dark:text-gray-200">Keyboard:</span>
          tab to a thumb, then arrows to nudge one step, PageUp / PageDown for a
          bigger jump, Home / End for the bounds. All of it is the native input -
          none of it is re-implemented here.
        </div>
      </div>

      <h2 class="mt-12 mb-1 text-lg font-semibold">Price range filter</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        Two thumbs posting two form fields, so filtering is a plain <code>phx-change</code>
        on the form. The result count below updates as you drag - no JavaScript in
        the app, and the values survive a reconnect because the server holds them.
      </p>
      <div class="p-6 border border-gray-200 rounded-xl dark:border-gray-800">
        <.form for={@slider_price} phx-change="slider_price">
          <.slider
            id="pg-slider-price"
            min_field={@slider_price[:min]}
            max_field={@slider_price[:max]}
            min={0}
            max={1000}
            step={50}
            label="Price"
            value_prefix="$"
            show_value="inline"
            marks={[
              %{value: 0, label: "$0"},
              %{value: 500, label: "$500"},
              %{value: 1000, label: "$1,000"}
            ]}
          />
        </.form>
        <div class="pt-4 mt-6 text-sm border-t border-gray-200 dark:border-gray-800">
          <span class="font-semibold text-gray-900 dark:text-white">
            {slider_price_count(@slider_price)}
          </span>
          <span class="text-gray-500 dark:text-gray-400">
            of {length(slider_catalogue())} products in range
          </span>
        </div>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Volume</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        The everyday single-thumb case: an icon that reacts to the level, the
        value inline in the label row, and a suffix so the number carries a unit.
      </p>
      <div class="p-6 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center gap-4">
          <.icon name={slider_volume_icon(@slider_volume)} class="w-5 h-5 text-gray-400 shrink-0" />
          <form phx-change="slider_volume" class="flex-1">
            <.slider
              id="pg-slider-volume"
              name="volume"
              label="Output volume"
              value={@slider_volume}
              min={0}
              max={100}
              value_suffix="%"
              show_value="inline"
            />
          </form>
        </div>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Model year</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        A coarse scale where every stop matters: <code>step</code>
        of 5 snaps the thumb, a mark sits on each stop, and the tooltip carries the
        number so no row is spent on a readout.
      </p>
      <div class="p-6 border border-gray-200 rounded-xl dark:border-gray-800">
        <form phx-change="slider_year">
          <.slider
            id="pg-slider-year"
            name="year"
            label="Model year"
            value={@slider_year}
            min={1990}
            max={2030}
            step={5}
            show_value="tooltip"
            marks={slider_year_marks()}
          />
        </form>
      </div>

      <div :for={ex <- PetalComponents.Showcase.Slider.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Slider} function={:slider} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        <code>&lt;.field type="range"&gt;</code>
        and <code>type="range-dual"</code>
        still work and are not going anywhere in this release, but <code>&lt;.slider&gt;</code>
        supersedes them - same native machinery, with marks, a value readout,
        vertical orientation and sizes on top. Reach for the slider in new code.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "number-field"} = assigns) do
    assigns = assign(assigns, :bounds, number_bounds(assigns.number.bounds))

    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Number field</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A real spinbutton for quantities, prices and percentages. One text
        input carrying <code>role="spinbutton"</code>, not <code>&lt;input type="number"&gt;</code>, so the steppers look the same
        in every browser and a half-typed value survives. It's live - type in
        it, hold a button, spin the wheel.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center px-6 py-12">
          <div class="w-full max-w-xs">
            <.number_field
              name="pg_quantity"
              value="12"
              min={@bounds.min}
              max={@bounds.max}
              step={@bounds.step}
              variant={@number.variant}
              size={@number.size}
              disabled={@number.disabled}
            />
          </div>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Variant"
              value={@number.variant}
              on_change="ctl_number"
              class={@rail_class}
            >
              <:item
                :for={v <- ~w(stacked split plain)}
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
              value={@number.size}
              on_change="ctl_number"
              class={@rail_class}
            >
              <:item :for={z <- ~w(sm md lg)} value={z} phx-value-k="size" phx-value-v={z}>{z}</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">bounds</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Bounds"
              value={@number.bounds}
              on_change="ctl_number"
              class={@rail_class}
            >
              <:item :for={b <- ~w(qty pct free)} value={b} phx-value-k="bounds" phx-value-v={b}>
                {number_bounds(b).label}
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
              value={if @number.disabled, do: ["disabled"], else: []}
              on_change="ctl_number"
              class={@rail_class}
            >
              <:item value="disabled" phx-value-k="disabled">disabled</:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <p class="mt-3 text-sm text-gray-500 dark:text-gray-400">
        Keyboard only: <kbd class="pc-kbd">↑</kbd>
        and <kbd class="pc-kbd">↓</kbd>
        step, <kbd class="pc-kbd">shift</kbd>
        + arrow steps by <code>big_step</code>, <kbd class="pc-kbd">page up</kbd>
        and <kbd class="pc-kbd">page down</kbd>
        do the same without the modifier, and <kbd class="pc-kbd">home</kbd>
        / <kbd class="pc-kbd">end</kbd>
        jump to the bounds. The buttons are never tab stops - the input is the
        one stop, the way the ARIA spinbutton pattern asks.
      </p>

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
      ><code>{number_snippet(@number)}</code></pre>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Cart quantity</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        The split variant in its natural home: a line-item row where the value
        wants to sit between the two controls. At the minimum the decrement
        greys out with <code>aria-disabled</code>, so it keeps its label for a
        screen reader instead of disappearing.
      </p>
      <div class="p-4 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center gap-4">
          <div class="w-12 h-12 rounded-lg bg-gray-100 dark:bg-gray-800"></div>
          <div class="flex-1 min-w-0">
            <div class="font-medium truncate">Ceramic pour-over</div>
            <div class="text-sm text-gray-500 dark:text-gray-400">$48.00</div>
          </div>
          <div class="w-32">
            <.number_field name="pg_cart_qty" value="1" min={1} max={10} variant="split" size="sm" />
          </div>
        </div>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Price, formatted on blur</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        <code>precision={2}</code>
        rounds and pads when you leave the field, and leaves the raw text alone
        while you type - so <code>7.5</code>
        becomes <code>7.50</code>, but only once you're done. Tab out to watch
        it. Currency and percent display go through <code>Intl.NumberFormat</code>
        on the same blur; the moduledoc has that pattern.
      </p>
      <div class="max-w-xs">
        <.number_field name="pg_price" value="24.5" min={0} step={0.5} precision={2}>
          <:leading>$</:leading>
        </.number_field>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Percentage allocation</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        Bounded 0 to 100 with a step of 5 and a <code>big_step</code>
        of 25, so shift+arrow moves a quarter at a time. Clamping is the hook's
        job on the client, but bounds are advice a browser cannot enforce for
        you - validate them on the server too.
      </p>
      <div class="max-w-xs">
        <.number_field name="pg_allocation" value="25" min={0} max={100} step={5} big_step={25}>
          <:trailing>%</:trailing>
        </.number_field>
      </div>

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.NumberField, ~w(sizes in_a_field)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.NumberField} function={:number_field} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.NumberField</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "sortable"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Sortable</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Drag a row to reorder it. Or don't touch the mouse at all: Tab to a row (or its grip),
        press Space to lift it, arrow keys to move it, Space to drop, Escape to change your
        mind. Every step is announced to a screen reader.
      </p>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        This demo is live. The drop pushes one event, this LiveView reorders its own list, and
        the running log underneath is the SERVER's order, not the browser's. Reload the page
        and the order you left it in is still there.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="px-4 py-8 sm:px-6">
          <.sortable
            :if={@sortable.orientation == "vertical"}
            id="pg-sortable-todos"
            on_reorder="pg_sortable"
            handle={@sortable.handle}
            disabled={@sortable.disabled}
          >
            <:item
              :for={todo <- @sortable.todos}
              id={todo.id}
              label={todo.title}
              disabled={todo.locked}
            >
              <span class="grow">{todo.title}</span>
              <.badge :if={todo.locked} size="sm" color="gray" label="locked" />
            </:item>
          </.sortable>

          <.sortable
            :if={@sortable.orientation == "grid"}
            id="pg-sortable-photos"
            on_reorder="pg_sortable"
            orientation="grid"
            handle={@sortable.handle}
            disabled={@sortable.disabled}
          >
            <:item
              :for={photo <- @sortable.photos}
              id={photo.id}
              label={photo.title}
              class="flex-col items-stretch gap-2 p-2"
            >
              <div class={["h-20 rounded-md bg-gradient-to-br", photo.tone]}></div>
              <span class="text-xs text-gray-600 dark:text-gray-300">{photo.title}</span>
            </:item>
          </.sortable>
        </div>

        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 py-4 border-t border-gray-200 sm:px-6 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">orientation</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Orientation"
              value={@sortable.orientation}
              on_change="ctl_sortable"
            >
              <:item :for={o <- ~w(vertical grid)} value={o} phx-value-k="orientation" phx-value-v={o}>
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
                for {k, on} <- [{"handle", @sortable.handle}, {"disabled", @sortable.disabled}],
                    on,
                    do: k
              }
              on_change="ctl_sortable"
            >
              <:item value="handle" phx-value-k="handle">grip handle</:item>
              <:item value="disabled" phx-value-k="disabled">disabled</:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <div class="p-4 mt-4 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="text-[11px] font-medium tracking-wide text-gray-400">
          server order (persisted in the LiveView, newest move first)
        </div>
        <ol class="mt-2 text-sm text-gray-600 dark:text-gray-300">
          <li :for={entry <- @sortable.log} class="font-mono text-xs">{entry}</li>
          <li :if={@sortable.log == []} class="text-gray-400 dark:text-gray-500">
            nothing moved yet
          </li>
        </ol>
        <div class="mt-3 font-mono text-xs text-gray-500 break-all dark:text-gray-400">
          {Enum.map_join(
            if(@sortable.orientation == "grid", do: @sortable.photos, else: @sortable.todos),
            ", ",
            & &1.id
          )}
        </div>
      </div>

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.Sortable, ~w(handle grid disabled)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Sortable} function={:sortable} />
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
              variant={@switch.variant}
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
              class={@rail_class}
            >
              <:item :for={z <- ~w(xs sm md lg xl)} value={z} phx-value-k="size" phx-value-v={z}>
                {z}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">thumb</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Thumb"
              value={@switch.variant}
              on_change="ctl_switch"
              class={@rail_class}
            >
              <:item :for={t <- ~w(default pill)} value={t} phx-value-k="variant" phx-value-v={t}>
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
                for {k, on} <- [{"error", @switch.error}, {"disabled", @switch.disabled}], on, do: k
              }
              on_change="ctl_switch"
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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

  defp render_page(%{active: "resizable"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Resizable</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Split panes with dividers you can drag - and key. Sizes are percentages of the
        group, so the split stays proportional when the window changes. Nested groups
        each mount their own hook and only touch their own direct children.
      </p>
      <p class="mt-3 text-sm text-gray-500 dark:text-gray-400">
        <span class="font-medium text-gray-700 dark:text-gray-200">Try the keyboard:</span>
        tab to a divider, then arrows to resize (hold shift for a bigger step),
        <kbd class="px-1 font-mono text-xs">Home</kbd>
        to shrink or collapse, <kbd class="px-1 font-mono text-xs">End</kbd>
        to grow, <kbd class="px-1 font-mono text-xs">Enter</kbd>
        to toggle a collapsible pane. Double-click a divider to reset it.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="p-6">
          <.resizable_group
            id={"pg-rsz-#{@rsz.orientation}-#{@rsz.with_handle}-#{@rsz.collapsible}"}
            orientation={@rsz.orientation}
            class="h-64 border border-gray-200 rounded-xl dark:border-gray-400/20"
          >
            <.resizable_panel
              id="pg-rsz-nav"
              default_size={28}
              min_size={18}
              collapsible={@rsz.collapsible}
            >
              <nav class="h-full p-3 overflow-auto text-sm bg-gray-50 dark:bg-gray-800/40">
                <div class="px-2 mb-1.5 text-[11px] font-semibold tracking-wide text-gray-400 uppercase">
                  Layout
                </div>
                <ul class="mb-4 space-y-0.5 text-gray-600 dark:text-gray-300">
                  <li class="px-2 py-1 rounded-md">Container</li>
                  <li class="px-2 py-1 font-medium text-gray-900 rounded-md bg-gray-200/70 dark:bg-gray-400/17 dark:text-white">
                    Resizable
                  </li>
                  <li class="px-2 py-1 rounded-md">Accordion</li>
                </ul>
                <div class="px-2 mb-1.5 text-[11px] font-semibold tracking-wide text-gray-400 uppercase">
                  Data
                </div>
                <ul class="space-y-0.5 text-gray-600 dark:text-gray-300">
                  <li class="px-2 py-1 rounded-md">Table</li>
                  <li class="flex items-center justify-between gap-2 px-2 py-1 rounded-md">
                    Data table
                    <span class="text-[10px] font-semibold uppercase text-success-600 dark:text-success-400">
                      new
                    </span>
                  </li>
                </ul>
              </nav>
            </.resizable_panel>
            <%!-- value_* mirror the panel's default/min so SSR ARIA matches
                  reality before the hook mounts and takes over --%>
            <.resizable_handle
              orientation={@rsz.orientation}
              with_handle={@rsz.with_handle}
              controls="pg-rsz-nav"
              value_now={28}
              value_min={18}
              label="Resize navigation"
            />
            <.resizable_panel default_size={72} min_size={30}>
              <div class="h-full p-5 overflow-auto">
                <div class="text-[11px] font-semibold tracking-wide uppercase text-primary-600 dark:text-primary-400">
                  Layout
                </div>
                <h3 class="mt-1 text-base font-semibold text-gray-900 dark:text-white">Resizable</h3>
                <p class="mt-2 text-sm leading-6 text-gray-600 dark:text-gray-300">
                  Drag the divider. With collapsible on, pull the nav past half its
                  min_size and it snaps shut - pull back out and it reopens.
                </p>
                <dl class="grid grid-cols-2 gap-3 mt-4 text-sm">
                  <div class="p-3 border border-gray-200 rounded-lg dark:border-gray-400/17">
                    <dt class="text-xs text-gray-500 dark:text-gray-400">default_size</dt>
                    <dd class="font-mono font-medium text-gray-900 tabular-nums dark:text-white">
                      28 / 72
                    </dd>
                  </div>
                  <div class="p-3 border border-gray-200 rounded-lg dark:border-gray-400/17">
                    <dt class="text-xs text-gray-500 dark:text-gray-400">min_size</dt>
                    <dd class="font-mono font-medium text-gray-900 tabular-nums dark:text-white">
                      18 / 30
                    </dd>
                  </div>
                </dl>
              </div>
            </.resizable_panel>
          </.resizable_group>
        </div>

        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">orientation</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Orientation"
              value={@rsz.orientation}
              on_change="ctl_rsz"
              class={@rail_class}
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
                      {"with_handle", @rsz.with_handle},
                      {"collapsible", @rsz.collapsible}
                    ],
                    on,
                    do: k
              }
              on_change="ctl_rsz"
              class={@rail_class}
            >
              <:item value="with_handle" phx-value-k="with_handle">with handle</:item>
              <:item value="collapsible" phx-value-k="collapsible">collapsible sidebar</:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">on_resize: the persistence hook point</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        Drag or key the divider below. On release the group pushes the released
        percentages to this LiveView, which is where an app would persist them. The
        library stores nothing itself - the same payload also rides a bubbling
        <code class="text-xs">petal:resizable-resize</code>
        DOM event for non-LiveView listeners.
      </p>
      <.resizable_group
        id="pg-rsz-persist"
        orientation="vertical"
        on_resize="pg_resize"
        class="h-64 border border-gray-200 rounded-xl dark:border-gray-400/20"
      >
        <.resizable_panel id="pg-rsz-editor" default_size={65} min_size={25}>
          <div class="flex flex-col h-full">
            <div class="flex items-center gap-1 px-2 pt-2 text-xs shrink-0">
              <span class="px-2 py-1 font-medium text-gray-900 bg-gray-100 rounded-t-md dark:bg-gray-400/17 dark:text-white">
                playground_live.ex
              </span>
            </div>
            <%!-- Hand-rolled tokens rather than the mdex/lumis path the "View
            code" panels use: this is demo content inside a pane, and it has to
            read on the page's own surface in both schemes. --%>
            <div class="flex-1 p-4 overflow-auto font-mono text-xs leading-5 text-gray-700 dark:text-gray-200">
              <div>
                <span class="text-gray-400 dark:text-gray-500">&lt;</span><span class="text-danger-500 dark:text-danger-400">.resizable_group</span>
                <span class="text-warning-600 dark:text-warning-400">orientation</span><span class="text-gray-400 dark:text-gray-500">=</span><span class="text-success-600 dark:text-success-400">"vertical"</span>
                <span class="text-warning-600 dark:text-warning-400">on_resize</span><span class="text-gray-400 dark:text-gray-500">=</span><span class="text-success-600 dark:text-success-400">"pg_resize"</span><span class="text-gray-400 dark:text-gray-500">&gt;</span>
              </div>
              <div>&nbsp;</div>
              <div>
                <span class="text-danger-500 dark:text-danger-400">def</span>
                <span class="text-info-600 dark:text-info-400">handle_event</span><span class="text-gray-500 dark:text-gray-400">(</span><span class="text-success-600 dark:text-success-400">"pg_resize"</span><span class="text-gray-500 dark:text-gray-400">, params, socket)</span><span class="text-gray-400 dark:text-gray-500">,</span>
                <span class="text-danger-500 dark:text-danger-400">do:</span>
              </div>
              <div class="pl-3">
                <span class="text-info-600 dark:text-info-400">assign</span><span class="text-gray-500 dark:text-gray-400">(socket,</span>
                <span class="text-warning-600 dark:text-warning-400">:rsz_sizes</span><span class="text-gray-500 dark:text-gray-400">, params[</span><span class="text-success-600 dark:text-success-400">"sizes"</span><span class="text-gray-500 dark:text-gray-400">])</span>
              </div>
            </div>
          </div>
        </.resizable_panel>
        <.resizable_handle
          orientation="vertical"
          controls="pg-rsz-editor"
          with_handle
          value_now={65}
          value_min={25}
          label="Resize console"
        />
        <.resizable_panel default_size={35} min_size={15}>
          <div class="h-full p-4 overflow-auto font-mono text-xs leading-5 bg-gray-50 dark:bg-gray-800/40">
            <div class="mb-1 font-sans text-[10px] tracking-wide text-gray-400 uppercase">
              console
            </div>
            <div>
              <span class="text-info-600 dark:text-info-400">[info]</span>
              <span class="text-gray-700 dark:text-gray-200">pg_resize &rarr;</span>
              <span class="font-medium text-success-600 tabular-nums dark:text-success-400">
                {Enum.map_join(@rsz_sizes, " / ", &"#{&1}%")}
              </span>
            </div>
            <div class="text-gray-400 dark:text-gray-500">
              # also on the wire as petal:resizable-resize
            </div>
          </div>
        </.resizable_panel>
      </.resizable_group>

      <div :for={ex <- PetalComponents.Showcase.Resizable.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <.showcase_props component={PetalComponents.Resizable} function={:resizable_group} />
      <.showcase_props component={PetalComponents.Resizable} function={:resizable_panel} />
      <.showcase_props component={PetalComponents.Resizable} function={:resizable_handle} />
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

  defp render_page(%{active: "filters"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Filters</h1>
      <p class="mt-2 mb-6 text-gray-600 dark:text-gray-300">
        A filter bar driven by the same State struct the data table uses. Chips carry field,
        operator and value; the Add filter popover walks field &rarr; operator &rarr; value in
        one panel, no round trip. Keyboard only: Tab to the trigger, Enter to open, Tab through
        the field list, Enter to pick, Tab to the inputs, Enter to apply, Escape to back out.
      </p>

      <div class="border border-gray-200 dark:border-gray-400/20 rounded-xl overflow-hidden">
        <div class="p-6">
          <% {state, rows} = @filters_state %>
          <.filters id="pg-filters" state={state} on_change="pg_filters">
            <:field :if={"text" in @filters_types} field={:name} label="Name" type="text" />
            <:field
              :if={"select" in @filters_types}
              field={:category}
              label="Category"
              type="select"
              options={[{"Hand tools", "hand"}, {"Power tools", "power"}, {"Finishing", "finishing"}]}
            />
            <:field
              :if={"number_range" in @filters_types}
              field={:price}
              label="Price"
              type="number_range"
            />
            <:field
              :if={"boolean" in @filters_types}
              field={:in_stock}
              label="In stock"
              type="boolean"
            />
            <:field
              :if={"date_range" in @filters_types}
              field={:added_on}
              label="Added"
              type="date_range"
            />
          </.filters>

          <ul class="grid gap-2 mt-5 sm:grid-cols-2">
            <li
              :for={p <- rows}
              class="flex items-center justify-between gap-3 px-3 py-2 text-sm border border-gray-200 rounded-lg dark:border-gray-400/20"
            >
              <span class="font-medium">{p.name}</span>
              <span class="flex items-center gap-2 text-gray-500 dark:text-gray-400">
                <.badge size="sm" variant="soft" color="gray" label={p.category} />
                <span>${p.price}</span>
              </span>
            </li>
            <li
              :if={rows == []}
              class="py-6 text-sm text-center text-gray-500 sm:col-span-2 dark:text-gray-400"
            >
              Nothing matches these filters.
            </li>
          </ul>
        </div>

        <div class="flex flex-wrap items-end px-4 py-4 border-t border-gray-200 gap-x-8 gap-y-4 sm:px-6 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">
              registered field types
            </div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="Field types"
              value={@filters_types}
              on_change="pg_filters_types"
              class={@rail_class}
            >
              <:item
                :for={t <- ~w(text select number_range boolean date_range)}
                value={t}
                phx-value-k={t}
              >
                {t}
              </:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">One State, bar and table</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        The composition proof. Both components read and write the same struct on the same event,
        so a chip added here filters the table below, and a column header filter adds a chip up
        here. Sorting and paging ride the same grammar.
      </p>
      <div class="p-6 border border-gray-200 dark:border-gray-400/20 rounded-xl">
        <% {shared_state, shared_rows} = @filters_state %>
        <.filters id="pg-filters-shared" state={shared_state} on_change="pg_filters">
          <:field field={:name} label="Name" type="text" />
          <:field
            field={:category}
            label="Category"
            type="select"
            options={[{"Hand tools", "hand"}, {"Power tools", "power"}, {"Finishing", "finishing"}]}
          />
          <:field field={:price} label="Price" type="number_range" />
          <:field field={:in_stock} label="In stock" type="boolean" />
        </.filters>
        <div class="mt-4">
          <.data_table
            id="pg-filters-table"
            rows={shared_rows}
            state={shared_state}
            on_change="pg_filters"
            striped
          >
            <:col :let={p} field={:name} sortable>{p.name}</:col>
            <:col
              :let={p}
              field={:category}
              filterable="select"
              options={[{"Hand tools", "hand"}, {"Power tools", "power"}, {"Finishing", "finishing"}]}
            >
              {p.category}
            </:col>
            <:col :let={p} field={:price} sortable align="right" filterable="number">${p.price}</:col>
            <:col :let={p} field={:in_stock} align="center">
              {if p.in_stock, do: "yes", else: "no"}
            </:col>
          </.data_table>
        </div>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Link mode: the URL is the state</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        No events. Every chip removal, apply and clear-all is a patch URL built from
        <code class="text-sm">State.to_params/1</code>
        , and <code class="text-sm">handle_params</code>
        decodes it back through the field whitelist. Apply a filter, then reload or hit back.
      </p>
      <div class="p-6 border border-gray-200 dark:border-gray-400/20 rounded-xl">
        <% {link_state, link_rows} = @filters_link %>
        <.filters
          id="pg-filters-link"
          state={link_state}
          path={
            theme_path(%{
              active: "filters",
              primary: @primary,
              secondary: @secondary,
              gray: @gray,
              radius: @radius
            })
          }
        >
          <:field field={:name} label="Name" type="text" />
          <:field
            field={:category}
            label="Category"
            type="select"
            options={[{"Hand tools", "hand"}, {"Power tools", "power"}, {"Finishing", "finishing"}]}
          />
          <:field field={:price} label="Price" type="number_range" />
          <:field field={:added_on} label="Added" type="date_range" />
        </.filters>
        <p class="mt-4 mb-1 text-sm text-gray-500 dark:text-gray-400">
          The query string this page decoded ({length(link_rows)} matching):
        </p>
        <pre class="p-3 overflow-x-auto text-xs rounded-lg bg-gray-100 dark:bg-gray-800"><code>{if @filters_query == "", do: "(none)", else: @filters_query}</code></pre>
      </div>

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.Filters, ~w(empty chips shared_state)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <.showcase_props component={PetalComponents.Filters} function={:filters} />
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
              class={@rail_class}
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
              class={@rail_class}
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
        The menu is the list. The sidebar is the shell it hangs in. Both examples
        below come from the shared showcase registry, so this page, petal.build and
        the MCP all serve the same demos.
      </p>

      <div :for={ex <- PetalComponents.Showcase.VerticalMenu.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} content_left />
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
            class={@rail_class}
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

  defp render_page(%{active: "kbd"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Kbd</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        The keyboard chip you end up hand-rolling in every app. Semantic
        <code class="pc-inline-code">&lt;kbd&gt;</code>
        elements with a key cap treatment - known key names fold to their glyph, anything
        else renders as you typed it. Pure HEEx and CSS, nothing to wire up.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center justify-center gap-5 px-6 py-10">
          <div class="flex items-center gap-3 text-sm text-gray-500 dark:text-gray-400">
            Open the command palette
            <.kbd keys={["cmd", "K"]} size={@kbd.size} separator={kbd_sep(@kbd.separator)} />
          </div>
          <div class="flex items-center gap-3 text-sm text-gray-500 dark:text-gray-400">
            Toggle the sidebar
            <.kbd
              keys={["ctrl", "shift", "B"]}
              size={@kbd.size}
              separator={kbd_sep(@kbd.separator)}
            />
          </div>
          <div class="flex items-center gap-3 text-sm text-gray-500 dark:text-gray-400">
            Assign to yourself
            <.kbd keys={["A", "I"]} size={@kbd.size} separator={kbd_sep(@kbd.separator)} />
          </div>
        </div>
        <div class="flex flex-wrap items-end px-4 py-4 border-t border-gray-200 gap-x-8 gap-y-4 sm:px-6 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Kbd size"
              value={@kbd.size}
              on_change="ctl_kbd"
            >
              <:item :for={z <- ~w(sm md)} value={z} phx-value-k="size" phx-value-v={z}>
                {z}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">separator</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Kbd separator"
              value={@kbd.separator}
              on_change="ctl_kbd"
            >
              <:item
                :for={g <- ["+", "·", "then", " "]}
                value={g}
                phx-value-k="separator"
                phx-value-v={g}
              >
                {if g == " ", do: "none", else: g}
              </:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <div class="mt-6">
        <div class="mb-2 text-sm font-medium text-gray-900 dark:text-white">
          The command palette trigger uses the same chip
        </div>
        <.command_trigger dialog_id="pg-kbd-command" label="Search" kbd="⌘K" />
      </div>

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.Kbd, ~w(cheat_sheet menu_item)a)}
        class="mt-8"
      >
        <h3 class="mb-1 font-semibold text-md">{ex.title}</h3>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Kbd} function={:kbd} />
    </div>
    """
  end

  defp render_page(%{active: "separator"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Separator</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A hairline with no margin of its own, optionally labelled - app layouts already
        control their own rhythm. Decorative by default; flip that off when the rule
        really does divide content screen readers should hear as separate.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex items-center justify-center px-6 py-12">
          <div :if={@separator.orientation == "horizontal"} class="w-full max-w-sm">
            <.button label="Sign in with email" class="w-full" />
            <.separator
              label="OR"
              label_position={@separator.label_position}
              decorative={@separator.decorative}
              class="my-5"
            />
            <.button variant="outline" label="Continue with GitHub" class="w-full" />
          </div>
          <div
            :if={@separator.orientation == "vertical"}
            class="inline-flex items-center gap-2 p-1.5 border border-gray-200 rounded-xl dark:border-gray-800"
          >
            <.button variant="ghost" size="sm" label="Bold" />
            <.button variant="ghost" size="sm" label="Italic" />
            <.separator orientation="vertical" decorative={@separator.decorative} class="h-6" />
            <.button variant="ghost" size="sm" label="Link" />
            <.button variant="ghost" size="sm" label="Code" />
          </div>
        </div>
        <div class="flex flex-wrap items-end px-4 py-4 border-t border-gray-200 gap-x-8 gap-y-4 sm:px-6 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">orientation</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Separator orientation"
              value={@separator.orientation}
              on_change="ctl_separator"
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
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">
              label position
            </div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Label position"
              value={@separator.label_position}
              on_change="ctl_separator"
            >
              <:item
                :for={o <- ~w(start center end)}
                value={o}
                phx-value-k="label_position"
                phx-value-v={o}
              >
                {o}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">aria</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="Separator aria"
              value={if @separator.decorative, do: ["decorative"], else: []}
              on_change="ctl_separator"
            >
              <:item value="decorative" phx-value-k="decorative">decorative</:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <div
        :for={
          ex <-
            examples_for(
              PetalComponents.Showcase.Separator,
              ~w(label_positions activity_feed vertical)a
            )
        }
        class="mt-8"
      >
        <h3 class="mb-1 font-semibold text-md">{ex.title}</h3>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Separator} function={:separator} />
    </div>
    """
  end

  defp render_page(%{active: "collapsible"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Collapsible</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        One disclosure region - the accordion without the group. Tab to the trigger and
        press Enter or Space; it is a real button, so the keyboard works without any wiring.
        The open dial below is the server driving it; clicking the trigger is the client
        doing the same job without a round trip. Turn on Reduce Motion in your OS and the
        height animation drops out while both rest states stay fully legible.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="px-6 py-10">
          <div class="max-w-md mx-auto">
            <.field
              type="text"
              name="pg_webhook"
              label="Webhook URL"
              value="https://example.com/hooks/deploy"
            />
            <.collapsible
              id="pg-collapsible"
              open={@collapsible.open}
              disabled={@collapsible.disabled}
            >
              <:trigger>Advanced options</:trigger>
              <div class="space-y-3">
                <.field
                  type="number"
                  name="pg_timeout"
                  label="Timeout (seconds)"
                  value="30"
                  no_margin
                />
                <.field type="number" name="pg_retries" label="Max retries" value="3" no_margin />
                <.field
                  type="checkbox"
                  name="pg_verify"
                  label="Verify TLS certificate"
                  checked
                  no_margin
                />
              </div>
            </.collapsible>
          </div>
        </div>
        <div class="flex flex-wrap items-end px-4 py-4 border-t border-gray-200 gap-x-8 gap-y-4 sm:px-6 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">state</div>
            <.toggle_group
              multiple
              variant="outline"
              size="sm"
              aria_label="Collapsible state"
              value={
                for {k, on} <- [{"open", @collapsible.open}, {"disabled", @collapsible.disabled}],
                    on,
                    do: k
              }
              on_change="ctl_collapsible"
            >
              <:item value="open" phx-value-k="open">open</:item>
              <:item value="disabled" phx-value-k="disabled">disabled</:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.Collapsible, ~w(changelog open)a)}
        class="mt-8"
      >
        <h3 class="mb-1 font-semibold text-md">{ex.title}</h3>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Collapsible} function={:collapsible} />
    </div>
    """
  end

  defp render_page(%{active: "scroll-area"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Scroll area</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        One themed treatment for every overflow region, so a scrolling panel
        looks like it belongs to the design system instead of inheriting
        whatever the OS decided. One div, zero JavaScript: modern
        scrollbar-width and scrollbar-color where the engine honours them, a
        ::-webkit-scrollbar fallback where it does not. Size the viewport with
        classes; the component never grows sizing attrs of its own.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <%!-- The border lives on the wrapper, not the scroll area: fade_edges
        masks the whole element, border included. --%>
        <div class="px-6 py-10">
          <div class="p-4 border border-gray-200 rounded-lg dark:border-gray-800">
            <.scroll_area
              orientation={@scroll.orientation}
              fade_edges={@scroll.fade == "on"}
              gutter_stable={@scroll.gutter == "stable"}
              visibility={@scroll.visibility}
              aria-label="Playground content"
              class="w-full max-h-64"
            >
              <div class={[
                "space-y-3 text-sm text-gray-700 dark:text-gray-300",
                @scroll.orientation != "vertical" && "w-max"
              ]}>
                <p :for={n <- 1..12}>
                  Line {n} - long enough to run past the right edge, so the horizontal scrollbar has somewhere to go and you can see both axes at once.
                </p>
              </div>
            </.scroll_area>
          </div>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">orientation</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Orientation"
              value={@scroll.orientation}
              on_change="ctl_scroll"
            >
              <:item
                :for={o <- ~w(vertical horizontal both)}
                value={o}
                phx-value-k="orientation"
                phx-value-v={o}
              >
                {o}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">fade edges</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Fade edges"
              value={@scroll.fade}
              on_change="ctl_scroll"
            >
              <:item :for={f <- ~w(off on)} value={f} phx-value-k="fade" phx-value-v={f}>
                {f}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">gutter</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Gutter"
              value={@scroll.gutter}
              on_change="ctl_scroll"
            >
              <:item :for={g <- ~w(auto stable)} value={g} phx-value-k="gutter" phx-value-v={g}>
                {g}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">visibility</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Visibility"
              value={@scroll.visibility}
              on_change="ctl_scroll"
            >
              <:item
                :for={v <- ~w(auto always)}
                value={v}
                phx-value-k="visibility"
                phx-value-v={v}
              >
                {v}
              </:item>
            </.toggle_group>
          </div>
        </div>
        <p class="px-6 pb-4 -mt-1 text-xs text-gray-400 dark:text-gray-500">
          tab into the panel and the arrow keys, Page Up/Down, Home and End all scroll it - that is native browser behaviour, not a hook
        </p>
      </div>

      <div class="p-4 mt-6 text-sm border rounded-xl border-gray-200 bg-gray-50 text-gray-600 dark:border-gray-800 dark:bg-gray-900/40 dark:text-gray-400">
        <div class="mb-1 font-medium text-gray-900 dark:text-gray-100">
          Scrollbars belong to the OS
        </div>
        <p>
          On macOS with "Show scroll bars: Automatically" - the default - the
          scrollbar is an overlay: it appears while you scroll, sits over the
          content, ignores most theming and has no gutter to reserve. Most
          mobile browsers do the same. On Windows, Linux, and macOS set to
          "Always", you get a classic scrollbar that takes real layout space and
          picks up the theming in full.
        </p>
        <p class="mt-2">
          So <code class="font-mono text-xs">visibility="always"</code>
          is a request, not a guarantee - WebKit honours it, Firefox has no
          mechanism for it. <code class="font-mono text-xs">gutter_stable</code>
          is a no-op wherever scrollbars are overlays, because there is no
          gutter to reserve. This component themes what the platform exposes.
          It does not fight the OS.
        </p>
      </div>

      <%!-- the registry is the single source: View Code panels + petal.build
            render these same examples, so the demos can never drift --%>
      <div :for={ex <- PetalComponents.Showcase.ScrollArea.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.ScrollArea} function={:scroll_area} />
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
              <Chat.message_attachments
                :if={Map.get(turn, :attachments, []) != []}
                attachments={Map.get(turn, :attachments)}
                class="mb-2"
              />
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
                <Chat.markdown
                  content={turn.text}
                  id={"pg-chat-md-#{turn.id}"}
                  sources={Map.get(turn, :sources)}
                />
                <Chat.chat_sources
                  :if={Map.get(turn, :sources)}
                  sources={Map.get(turn, :sources)}
                  expanded={@chat.sources_expanded}
                  max_visible={@chat.sources_max}
                />
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
              phx-change="chat_validate"
              upload={@uploads.chat_attachments}
              on_cancel_upload="chat_cancel_upload"
              accept_hint={@chat.attach_hint && "Images and PDFs up to 5 MB"}
              editing={@chat.editing != nil}
              on_cancel_edit="chat_cancel_edit"
              loading={@chat.streaming}
              on_stop="chat_stop"
              placeholder="Ask the (canned) assistant, or paste a screenshot..."
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
              class={@rail_class}
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
              class={@rail_class}
            >
              <:item :for={v <- ~w(always hover)} value={v} phx-value-k="actions" phx-value-v={v}>
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">
              sources expanded
            </div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Sources expanded"
              value={if @chat.sources_expanded, do: "open", else: "closed"}
              on_change="ctl_chat"
              class={@rail_class}
            >
              <:item
                :for={v <- ~w(closed open)}
                value={v}
                phx-value-k="sources_expanded"
                phx-value-v={v}
              >
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">max_visible</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Max visible sources"
              value={
                if @chat.sources_max >= length(@chat_rag_sources),
                  do: "all",
                  else: to_string(@chat.sources_max)
              }
              on_change="ctl_chat"
              class={@rail_class}
            >
              <:item :for={v <- ~w(2 5 all)} value={v} phx-value-k="sources_max" phx-value-v={v}>
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">accept_hint</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Accept hint"
              value={if @chat.attach_hint, do: "on", else: "off"}
              on_change="ctl_chat"
              class={@rail_class}
            >
              <:item :for={v <- ~w(off on)} value={v} phx-value-k="attach_hint" phx-value-v={v}>
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">size limit</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Upload size limit"
              value={@chat.attach_limit}
              on_change="ctl_chat"
              class={@rail_class}
            >
              <:item
                :for={v <- ~w(5mb tiny)}
                value={v}
                phx-value-k="attach_limit"
                phx-value-v={v}
              >
                {v}
              </:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        The composer above takes real uploads. Click the paperclip, drag a file
        onto the composer, or paste a screenshot straight into the textarea -
        each one lands as a chip with a remove button - the progress fills while
        the bytes actually move, which without <code>auto_upload</code>
        is on send - and sending renders them back into the message with <code>message_attachments</code>. It's ordinary <code>allow_upload/3</code>: the component only renders <code>@uploads.name</code>. Flip the size limit dial to
        <code>tiny</code>
        (20 KB) and drop a normal screenshot to see the inline error, and <code>accept_hint</code>
        off/on to toggle the paperclip's description. Keyboard: the chip strip
        renders above the composer row, so Tab reaches each chip's remove button
        first, then the paperclip, then the textarea, then send.
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">A tool call, start to finish</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        Press a button and watch one card walk the lifecycle: pending, then the
        arguments streaming in, then running, then the result. The whole thing is
        four <code>Process.send_after</code>
        hops in this page's handle_info, each one patching a single assign. The
        component holds no client state and ships no hook - the card moves because
        the server said so.
      </p>
      <div class="overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="p-6">
          <Chat.tool_call
            :if={@tool.run_state}
            id={"pg-tool-run-#{@tool.run_seq}"}
            name="web_search"
            state={@tool.run_state}
            icon="web_search"
            label={if @tool.run_state == :running, do: "Searching the web"}
            duration={@tool.run_duration}
            input={if @tool.run_state in [:complete, :error], do: @tool_run_input}
            output={if @tool.run_state == :complete, do: @tool_run_output}
            error={
              if @tool.run_state == :error,
                do: "The search backend returned 503 after three retries."
            }
          >
            <:error_actions :if={@tool.run_state == :error}>
              <button
                type="button"
                class="pc-chat__action"
                phx-click="tool_run"
                phx-value-outcome="success"
              >
                Retry
              </button>
            </:error_actions>
          </Chat.tool_call>
          <p :if={is_nil(@tool.run_state)} class="text-sm text-gray-500 dark:text-gray-400">
            Nothing running yet. Start a call below.
          </p>
        </div>
        <div class="flex flex-wrap items-center gap-2 px-6 py-4 border-t border-gray-100 dark:border-gray-800/80">
          <.button
            size="sm"
            phx-click="tool_run"
            phx-value-outcome="success"
            disabled={@tool.run_state in [:pending, :input_streaming, :running]}
          >
            Run a search
          </.button>
          <.button
            size="sm"
            variant="outline"
            phx-click="tool_run"
            phx-value-outcome="error"
            disabled={@tool.run_state in [:pending, :input_streaming, :running]}
          >
            Run one that fails
          </.button>
          <.button size="sm" variant="ghost" phx-click="tool_reset">Clear</.button>
        </div>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">A compact burst</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        Five calls from one agent turn. <code>compact</code>
        drops the card chrome so consecutive rows read as a list; the two finished
        ones and the failure are disclosures - click a row, or Tab to it and press
        Enter, to open its input and output. The running and pending rows have
        nothing to show yet, so they stay plain announced status lines.
      </p>
      <div class="p-3 border border-gray-200 rounded-xl dark:border-gray-800">
        <Chat.tool_call
          :for={call <- @tool_burst}
          name={call.name}
          compact
          state={call.state}
          icon={call.icon}
          duration={call.duration}
          input={call.input}
          output={call.output}
          error={call.error}
        >
          <:error_actions :if={call.error}>
            <button type="button" class="pc-chat__action" phx-click="noop">Retry</button>
          </:error_actions>
        </Chat.tool_call>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">States and icons</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        One card, every dial.
      </p>
      <div class="overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="p-6">
          <Chat.tool_call
            name="web_search"
            state={@tool.state}
            compact={@tool.compact}
            icon={@tool.icon}
            label={if @tool.state == :running, do: "Searching the web"}
            duration="1.2s"
            input={if @tool.state in [:complete, :error], do: @tool_run_input}
            output={if @tool.state == :complete, do: @tool_run_output}
            error={if @tool.state == :error, do: "The search backend returned 503."}
          >
            <:error_actions :if={@tool.state == :error}>
              <button type="button" class="pc-chat__action" phx-click="noop">Retry</button>
            </:error_actions>
          </Chat.tool_call>
        </div>
        <div class="flex flex-wrap gap-6 px-6 py-4 border-t border-gray-100 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">state</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Tool call state"
              value={to_string(@tool.state)}
              on_change="ctl_tool"
              class={@rail_class}
            >
              <:item
                :for={v <- ~w(pending input_streaming running complete error)}
                value={v}
                phx-value-k="state"
                phx-value-v={v}
              >
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">compact</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Compact"
              value={if @tool.compact, do: "on", else: "off"}
              on_change="ctl_tool"
              class={@rail_class}
            >
              <:item :for={v <- ~w(off on)} value={v} phx-value-k="compact" phx-value-v={v}>
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">icon</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Tool icon"
              value={@tool.icon || "none"}
              on_change="ctl_tool"
              class={@rail_class}
            >
              <:item
                :for={v <- ~w(web_search code database none)}
                value={v}
                phx-value-k="icon"
                phx-value-v={v}
              >
                {v}
              </:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        <code>state</code>
        is the source of truth and it is all assigns - the older <code>status</code>
        attr still works and maps onto running, complete and error. Pending and
        input_streaming rest on a shimmer skeleton (it stands still under reduced
        motion), running gets a spinner and an indeterminate hairline under the
        header, complete settles into a summary row, and error rides the danger
        ramp with the message inline and your retry button in the <code>error_actions</code>
        slot. Input and output take the JSON string you already have; it is
        pretty-printed server-side, and anything that isn't valid JSON is shown
        verbatim rather than swallowed. The panels are native
        &lt;details&gt; - the browser owns the disclosure semantics, so Tab reaches
        a panel and Enter or Space opens it, with no JS and no aria-expanded to go
        stale. The default slot is your rendered widget and stays visible; the
        panels are for inspecting the payload, not for hiding your component.
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Human in the loop</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        A live two-step flow. The assistant asks which framework, you answer, the
        card flips to resolved chips and it asks the follow-up. Submit is a plain
        phx-submit into this page's handle_event - the component holds no client
        state at all. Keyboard-only works end to end: arrows move within a group,
        Space toggles a checkbox, Enter submits.
      </p>
      <Chat.conversation id="pg-chat-quiz">
        <Chat.chat_message role="user">Scaffold me a starter app.</Chat.chat_message>
        <Chat.chat_message role="assistant">
          <Chat.questionnaire
            spec={@q_framework}
            resolved={@quiz.framework}
            allow_skip
            submitting={@quiz.submitting}
          />
        </Chat.chat_message>
        <Chat.chat_message :if={@quiz.asked_scope || @quiz.framework == :skipped} role="assistant">
          <Chat.questionnaire
            spec={@q_scope}
            resolved={@quiz.scope}
            allow_skip
            submit_label="Send answers"
          />
        </Chat.chat_message>
        <:footer>
          <.button size="sm" variant="outline" phx-click="quiz_reset">Reset the flow</.button>
        </:footer>
      </Chat.conversation>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Field types and states</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        One field at a time, through every state.
      </p>
      <div class="overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="p-6">
          <Chat.questionnaire
            spec={quiz_demo_spec(@quiz.field)}
            resolved={quiz_demo_resolved(@quiz)}
            submitting={@quiz.state == "submitting"}
            allow_skip={@quiz.allow_skip}
          />
        </div>
        <div class="flex flex-wrap gap-6 px-6 py-4 border-t border-gray-100 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">field type</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Field type"
              value={@quiz.field}
              on_change="ctl_quiz"
              class={@rail_class}
            >
              <:item
                :for={v <- ~w(single_cards single_buttons multi text scale)}
                value={v}
                phx-value-k="field"
                phx-value-v={v}
              >
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">allow_skip</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Allow skip"
              value={if @quiz.allow_skip, do: "on", else: "off"}
              on_change="ctl_quiz"
              class={@rail_class}
            >
              <:item :for={v <- ~w(off on)} value={v} phx-value-k="allow_skip" phx-value-v={v}>
                {v}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">state</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Questionnaire state"
              value={@quiz.state}
              on_change="ctl_quiz"
              class={@rail_class}
            >
              <:item
                :for={v <- ~w(pending submitting resolved skipped)}
                value={v}
                phx-value-k="state"
                phx-value-v={v}
              >
                {v}
              </:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        The spec is a plain map the app (or the model) emits; the component is a
        thin renderer over it. Single-select composes <code>field type="radio-card"</code>
        when the options carry descriptions and <code>type="radio-group"</code>
        when they don't; multi-select is a checkbox group, text is a text field.
        Only the 1-to-5 scale is new markup - five real radios in a segmented
        row, so arrows move between steps natively. Inputs are named <code>answers[field_id]</code>
        so submit lands as a map with a "spec_id" key and an "answers" map.
        Resolved replaces the form with chips - no disabled form left in the DOM
        pretending to be interactive.
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">A support thread with attachments</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        The received side. Images tile into a grid, files are download rows with
        the size on the end, and a mixed list puts the images first.
      </p>
      <Chat.conversation id="pg-chat-attachments">
        <Chat.chat_message role="user">
          <Chat.message_attachments
            attachments={[
              %{kind: :image, url: @chat_shot_image, name: "checkout-error.png", size: 184_320},
              %{kind: :file, url: "#", name: "invoice-4471.pdf", size: 96_400}
            ]}
            class="mb-2"
          /> Checkout throws on submit. Screenshot and the invoice attached.
        </Chat.chat_message>
        <Chat.chat_message role="assistant">
          That trace is a card token expiring before submit. I pulled the
          gateway log for invoice 4471 - same window.
          <Chat.message_attachments
            attachments={[%{kind: :file, url: "#", name: "gateway-4471.log", size: 4_820}]}
            class="mt-2"
          />
        </Chat.chat_message>
      </Chat.conversation>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Citations while streaming</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        The same grounded answer, streamed. Each tick re-renders the growing buffer
        through <code>to_html(buffer, sources: sources)</code>
        and pushes the HTML at a format="markdown" streaming_text, so chips light up
        as their markers complete. A half-arrived "[^" is left alone until the closing
        bracket lands, so nothing flashes broken.
      </p>
      <div class="p-4 border border-gray-200 rounded-xl dark:border-gray-800">
        <Chat.streaming_text id="pg-chat-rag-stream" event="pc-chat-rag-token" format="markdown" />
        <div class="mt-3">
          <Chat.chat_sources
            sources={@chat_rag_sources}
            expanded={@chat.sources_expanded}
            max_visible={@chat.sources_max}
          />
        </div>
        <.button
          size="sm"
          variant="outline"
          class="mt-3"
          phx-click="chat_rag_stream"
          disabled={@chat.rag_streaming}
        >
          {if @chat.rag_streaming, do: "Streaming...", else: "Stream the grounded answer"}
        </.button>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Answer grounding is two pieces. Prompt the model to cite as <code>[^N]</code>
        and pass the same source maps to <code>markdown/1</code>: complete markers
        become chips, unmatched ones stay as plain text. Chips are real links - Tab
        reaches one, the preview card opens on focus (and on hover, where it stays
        hoverable so you can read a long snippet), Enter opens the source in a new
        tab. The card is pure CSS with no hook, so it dismisses by moving focus or
        the pointer off the chip rather than with Escape. Only http(s) urls become
        links: a source url with any other scheme renders its chip without an href.
        <code>chat_sources</code>
        is the deduped list underneath, a native
        &lt;details&gt; with no JS: the dials above flip <code>expanded</code>
        and cap the list with <code>max_visible</code>, which tucks the rest behind a
        "Show all" reveal.
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
          :chat_error,
          :chat_sources,
          :citation,
          :message_attachments,
          :questionnaire
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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
              class={@rail_class}
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

  defp render_page(%{active: "scrollspy"} = assigns) do
    assigns = assign(assigns, :ss_items, scrollspy_items(assigns.scrollspy))

    ~H"""
    <div class="max-w-5xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Scrollspy</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        The "on this page" rail. A hook watches the sections with an
        IntersectionObserver and moves the highlight to whichever one you're reading.
        Scroll this page and watch it track.
      </p>

      <div class="flex flex-wrap items-end px-4 py-4 mt-8 border border-gray-200 gap-x-8 gap-y-4 rounded-xl dark:border-gray-800">
        <div>
          <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">offset</div>
          <.toggle_group
            variant="outline"
            size="sm"
            aria_label="Offset"
            value={@scrollspy.offset}
            on_change="ctl_scrollspy"
          >
            <:item
              :for={v <- ~w(2rem 6rem 12rem)}
              value={v}
              phx-value-k="offset"
              phx-value-v={v}
            >
              {v}
            </:item>
          </.toggle_group>
        </div>
        <div>
          <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">indicator</div>
          <.toggle_group
            variant="outline"
            size="sm"
            aria_label="Indicator"
            value={@scrollspy.indicator}
            on_change="ctl_scrollspy"
          >
            <:item :for={v <- ~w(bar none)} value={v} phx-value-k="indicator" phx-value-v={v}>
              {v}
            </:item>
          </.toggle_group>
        </div>
        <div>
          <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">nesting</div>
          <.toggle_group
            multiple
            variant="outline"
            size="sm"
            aria_label="Nesting"
            value={for {k, on} <- [{"nested", @scrollspy.nested}], on, do: k}
            on_change="ctl_scrollspy"
          >
            <:item value="nested" phx-value-k="nested">nested</:item>
          </.toggle_group>
        </div>
      </div>

      <div class="sticky top-0 z-10 px-4 py-3 mt-8 -mx-4 text-xs font-medium text-gray-500 border-b border-gray-200 sm:-mx-8 sm:px-8 bg-white/85 dark:bg-gray-950/85 backdrop-blur dark:border-gray-800 dark:text-gray-400">
        Sticky page header - the offset dial is what keeps this bar off a heading you jump to.
      </div>

      <div class="flex gap-10 mt-8">
        <article class="flex-1 min-w-0">
          <section id="ss-why" class="pb-16">
            <h2 class="text-xl font-semibold tracking-tight">Why a rail</h2>
            <p class="mt-3 text-gray-600 dark:text-gray-400">
              Long pages lose people. A reader who scrolls past three headings has no
              idea how much is left or where they are, and the browser's own scrollbar
              is too coarse to answer either question. A rail down the side answers both
              at a glance: here is the shape of the page, and here is you.
            </p>
            <p class="mt-3 text-gray-600 dark:text-gray-400">
              Every docs site rebuilds this by hand and most of them get the edge cases
              wrong. Two sections visible at once, a closing section too short to ever
              reach the activation line, a deep link that lands mid-page. Those are the
              parts worth absorbing into a component.
            </p>
          </section>

          <section id="ss-wiring" class="pb-16">
            <h2 class="text-xl font-semibold tracking-tight">Wiring it up</h2>
            <p class="mt-3 text-gray-600 dark:text-gray-400">
              There are two moving parts and they meet at an id. The rail names the
              sections it wants to track; the page gives those sections ids. Nothing
              else connects them, which is why the hook works just as well on markup you
              wrote yourself.
            </p>
          </section>

          <section id="ss-items" class="pb-16">
            <h3 class="text-base font-semibold">The items list</h3>
            <p class="mt-3 text-gray-600 dark:text-gray-400">
              Each entry is a map with a label and a target. The target is the section
              id without the hash. Add a children key and you get one level of nesting
              for h3s underneath an h2, which is where the rail stops: past two levels
              it is no longer something you can scan.
            </p>
          </section>

          <section id="ss-targets" class="pb-16">
            <h3 class="text-base font-semibold">The targets</h3>
            <p class="mt-3 text-gray-600 dark:text-gray-400">
              Give the section elements those ids and you are done. Missing targets are
              skipped rather than treated as an error, so a rail built from a CMS table
              of contents degrades quietly when a section gets deleted.
            </p>
          </section>

          <section id="ss-offset" class="pb-16">
            <h2 class="text-xl font-semibold tracking-tight">Clearing a fixed header</h2>
            <p class="mt-3 text-gray-600 dark:text-gray-400">
              Click a link and the browser scrolls the heading to the very top of the
              viewport, which is exactly where a sticky site header already is. The
              offset sets scroll-margin-top on every target so the heading parks below
              the bar instead of behind it.
            </p>
            <p class="mt-3 text-gray-600 dark:text-gray-400">
              Try the dial above, then click a link in the rail. At 2rem the heading
              tucks under the sticky bar on this page. At 12rem it lands well clear of it.
            </p>
          </section>

          <section id="ss-motion" class="pb-16">
            <h2 class="text-xl font-semibold tracking-tight">Motion</h2>
            <p class="mt-3 text-gray-600 dark:text-gray-400">
              Smooth scrolling is a property of the scroll container, not of the click,
              so the hook sets it there and puts it back the way it found it when the
              component unmounts. The indicator bar is positioned by the hook and
              animated by CSS, which keeps the timing in one place.
            </p>
            <p class="mt-3 text-gray-600 dark:text-gray-400">
              Turn on reduce motion in your OS and both go away. Jumps land instantly,
              the bar moves without a transition, and nothing about the resting state
              changes.
            </p>
          </section>

          <section id="ss-a11y" class="pb-16">
            <h2 class="text-xl font-semibold tracking-tight">Accessibility</h2>
            <p class="mt-3 text-gray-600 dark:text-gray-400">
              The rail is a nav landmark with a label, so it can be found and skipped.
              The active link carries aria-current="location", which is the right token
              for "you are here within this page" and means the highlight is not colour
              alone.
            </p>
            <p class="mt-3 text-gray-600 dark:text-gray-400">
              Entries are plain anchors, so Tab and Enter already work and there is no
              custom key handling to learn. Scrolling never moves focus: the hook only
              touches classes and one attribute, so a keyboard user's place in the page
              is theirs to lose.
            </p>
          </section>

          <section id="ss-end" class="pb-4">
            <h2 class="text-xl font-semibold tracking-tight">Wrapping up</h2>
            <p class="mt-3 text-gray-600 dark:text-gray-400">
              This last section is deliberately short. Scroll to the very bottom and it
              still highlights, because the last entry snaps active there.
            </p>
          </section>
        </article>

        <.scrollspy
          id="pg-scrollspy"
          heading="On this page"
          items={@ss_items}
          offset={@scrollspy.offset}
          indicator={@scrollspy.indicator}
          class="self-start flex-none hidden w-56 lg:block sticky top-16"
        />
      </div>

      <button
        phx-click="flip"
        phx-value-k="show_code"
        class="mt-10 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-gray-900 rounded-xl dark:border dark:border-gray-800"
      ><code>{scrollspy_snippet(@scrollspy)}</code></pre>

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.Scrollspy, ~w(nested bare)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Scrollspy} function={:scrollspy} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Scrollspy</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "tree"} = assigns) do
    assigns =
      assigns
      |> assign(:explorer_items, explorer_items(assigns.tree))
      |> assign(:hero_expanded, hero_expanded(assigns.tree.expand))

    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Tree</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        Nested data, arbitrary depth, the full WAI-ARIA TreeView keyboard map. Click into
        the tree and drive it with the keyboard: up and down walk the visible nodes,
        right expands or descends, left collapses or goes up a level, Home and End jump
        to the ends, Enter or Space selects, and * opens every branch at the current
        level. The whole tree is one Tab stop.
      </p>

      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="px-6 py-8">
          <div class="max-w-md mx-auto">
            <.tree
              id={"pg-tree-#{@tree.expand}-#{@tree.guides}-#{@tree.row_expand}"}
              label="Project files"
              show_guides={@tree.guides}
              expand_on_click={@tree.row_expand}
              default_expanded={@hero_expanded}
              selected={@tree.picked}
              select_event="tree_pick"
              items={sample_tree()}
            />
          </div>
        </div>

        <div class="grid gap-5 px-6 py-5 border-t border-gray-100 md:grid-cols-3 dark:border-gray-800/80">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">
              default_expanded
            </div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Expanded at render"
              value={@tree.expand}
              on_change="ctl_tree"
              class={@rail_class}
            >
              <:item :for={v <- ~w(none first all)} value={v} phx-value-k="expand" phx-value-v={v}>
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
                for {k, on} <- [{"guides", @tree.guides}, {"row_expand", @tree.row_expand}],
                    on,
                    do: k
              }
              on_change="ctl_tree"
              class={@rail_class}
            >
              <:item value="guides" phx-value-k="guides">show_guides</:item>
              <:item value="row_expand" phx-value-k="row_expand">expand_on_click</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">
              last on_select payload
            </div>
            <code class="inline-block px-2 py-1 font-mono text-xs bg-gray-100 rounded dark:bg-gray-800">
              {if @tree.picked, do: ~s|%{"id" => "#{@tree.picked}"}|, else: "nothing picked yet"}
            </code>
          </div>
        </div>
      </div>

      <div class="p-4 mt-3 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        This tree runs the client-side expansion model: the chevron toggles two attributes
        with LiveView.JS and CSS animates the height, so opening a folder costs no round
        trip. With <code>expand_on_click</code>
        on - the default, and the dial above - the whole folder row runs that same toggle
        and selects the node in the one click; turn it off and expansion is the chevron's
        job alone. The trade is that the open branches live only in the DOM - flip a dial above
        and the tree re-renders back to default_expanded. Trees that must survive a patch,
        or that load children on demand, want the server-controlled model instead (the
        file explorer below).
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Scenario: a file explorer</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        The server-controlled model end to end. A MapSet of expanded ids in assigns, one
        handle_event for the chevron, one for selection. <code>deps/</code>
        is marked :lazy - open it and the loading row shows until its children arrive
        900ms later, the way a real query or API call would land.
      </p>
      <div class="grid gap-4 sm:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
        <div class="p-3 border border-gray-200 rounded-xl dark:border-gray-800">
          <.tree
            id="pg-tree-explorer"
            label="Explorer"
            show_guides
            expanded={@tree.expanded}
            on_expand="tree_toggle"
            selected={@tree.opened}
            select_event="tree_open"
            items={@explorer_items}
          />
        </div>
        <div class="p-4 text-sm border border-gray-200 rounded-xl dark:border-gray-800">
          <div class="font-mono text-xs text-gray-400">selected</div>
          <div class="mt-1 font-medium">{@tree.opened || "nothing open"}</div>
          <div class="mt-4 font-mono text-xs text-gray-400">expanded</div>
          <div class="mt-1 font-mono text-xs break-all text-gray-500 dark:text-gray-400">
            {@tree.expanded |> Enum.sort() |> inspect()}
          </div>
        </div>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Scenario: reporting lines</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        The :item slot takes over the row content and receives the whole node map, so the
        extra keys on this data (a role, a location) render however you like. Everything
        structural - the chevron, the indent, the guides, aria-level, the roving tabindex -
        stays with the component.
      </p>
      <div class="p-3 border border-gray-200 rounded-xl dark:border-gray-800">
        <.tree
          id="pg-tree-org"
          label="Reporting lines"
          show_guides
          default_expanded={:all}
          items={org_tree()}
        >
          <:item :let={person}>
            <span class="flex items-center justify-center w-6 h-6 text-[10px] font-semibold rounded-full shrink-0 bg-primary-100 text-primary-700 dark:bg-primary-500/15 dark:text-primary-300">
              {person.initials}
            </span>
            <span class="font-medium">{person.label}</span>
            <span class="text-xs text-gray-500 dark:text-gray-400">{person.role}</span>
            <span class="ml-auto text-[11px] text-gray-400">{person.city}</span>
          </:item>
        </.tree>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Scenario: settings navigation</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        A two-level settings outline where selection drives the page next to it. Same
        server-controlled model as the explorer, custom icons per node, and one disabled
        node the user can still focus but not choose.
      </p>
      <div class="grid gap-4 sm:grid-cols-[minmax(0,14rem)_minmax(0,1fr)]">
        <div class="p-3 border border-gray-200 rounded-xl dark:border-gray-800">
          <.tree
            id="pg-tree-settings"
            label="Settings"
            expanded={@tree.settings_expanded}
            on_expand="settings_toggle"
            selected={@tree.settings_page}
            select_event="settings_pick"
            items={settings_tree()}
          />
        </div>
        <div class="p-6 border border-gray-200 rounded-xl dark:border-gray-800">
          <div class="text-xs tracking-wide text-gray-400 uppercase">Now showing</div>
          <div class="mt-1 text-xl font-semibold capitalize">
            {@tree.settings_page |> to_string() |> String.replace("-", " ")}
          </div>
          <p class="mt-3 text-sm text-gray-500 dark:text-gray-400">
            Selection is single-select and the server owns it: the component sets
            aria-selected and the soft primary fill on click so the highlight is instant,
            then pushes the id so your LiveView can swap the panel.
          </p>
        </div>
      </div>

      <div :for={ex <- PetalComponents.Showcase.Tree.examples()} class="mt-10">
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} content_left />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.Tree} function={:tree} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Tree</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "calendar"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Calendar</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A month grid on plain Elixir <code>Date</code>. No date dependency, no timezone
        guessing. Tab into the grid and drive it with the arrow keys: PageUp and PageDown
        page the month, Home and End jump to the ends of the week.
      </p>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        The cell size dial below is not an attr. It writes <code>--pc-calendar-cell-size</code>, the one CSS token that sizes days, weekday
        headers and nav arrows together - set it in a class or a style, anywhere above the
        calendar.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="flex flex-col items-center gap-4 px-6 py-10">
          <.calendar
            id="pg-calendar"
            mode={@cal.mode}
            value={cal_value(@cal, assigns)}
            month={@cal_month}
            starts_on={@cal.starts_on}
            show_outside_days={@cal.outside}
            min={@cal.window && Date.utc_today()}
            max={@cal.window && Date.add(Date.utc_today(), 30)}
            on_select="cal_pick"
            on_month_change="cal_month"
            style={"--pc-calendar-cell-size: #{@cal.size}"}
          />
          <p class="text-sm text-gray-500 dark:text-gray-400">
            Selected:
            <span class="font-medium text-gray-900 dark:text-gray-100">
              {cal_summary(@cal, assigns)}
            </span>
          </p>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">mode</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Mode"
              value={@cal.mode}
              on_change="ctl_cal"
              class={@rail_class}
            >
              <:item
                :for={m <- ~w(single range multiple)}
                value={m}
                phx-value-k="mode"
                phx-value-v={m}
              >
                {m}
              </:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">week starts</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Week starts"
              value={to_string(@cal.starts_on)}
              on_change="ctl_cal"
              class={@rail_class}
            >
              <:item value="1" phx-value-k="starts_on" phx-value-v="1">Monday</:item>
              <:item value="7" phx-value-k="starts_on" phx-value-v="7">Sunday</:item>
            </.toggle_group>
          </div>
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">cell size</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Cell size"
              value={@cal.size}
              on_change="ctl_cal"
              class={@rail_class}
            >
              <:item
                :for={s <- ~w(2rem 2.25rem 3rem 4rem)}
                value={s}
                phx-value-k="size"
                phx-value-v={s}
              >
                {s}
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
              value={for {k, on} <- [{"outside", @cal.outside}, {"window", @cal.window}], on, do: k}
              on_change="ctl_cal"
              class={@rail_class}
            >
              <:item value="outside" phx-value-k="outside">outside days</:item>
              <:item value="window" phx-value-k="window">next 30 days only</:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        <span class="font-medium text-gray-900 dark:text-gray-100">Keyboard demo.</span>
        Tab until a day takes focus, then: arrows move a day or a week, Home and End go to the
        ends of the week, PageUp and PageDown page the month (hold Shift for a year), Enter
        picks. Only one day is ever in the tab order, so Tab leaves the grid rather than
        walking all 42 cells.
      </div>

      <div
        :for={
          ex <-
            examples_for(
              PetalComponents.Showcase.Calendar,
              ~w(range multiple limits availability booking in_card appointments week_start)a
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
      <.showcase_props component={PetalComponents.Calendar} function={:calendar} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.Calendar</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  defp render_page(%{active: "date-picker"} = assigns) do
    ~H"""
    <div class="max-w-3xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">Date picker</h1>
      <p class="mt-2 text-gray-500 dark:text-gray-400">
        A text input with the calendar in a panel under it. Type a date or pick one; the
        form posts ISO 8601 either way. Escape closes the panel and puts you back on the
        input.
      </p>

      <div class="mt-8 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="px-6 py-10">
          <div class="max-w-sm">
            <.date_picker
              id="pg-date-picker"
              name="pg_date"
              mode={@picker.mode}
              label="Check in and out"
              format="%d %b %Y"
              two_months={@picker.two_months}
              clearable={@picker.clearable}
              value={if @picker.mode == "range", do: @pick_stay, else: @pick_single}
              month={@pick_month}
              on_month_change="picker_month"
              min={Date.utc_today()}
              help_text="Try typing 14 Mar 2027 - the calendar follows as the year lands."
            />
          </div>
        </div>
        <div class="flex flex-wrap items-end gap-x-8 gap-y-4 px-4 sm:px-6 py-4 [&>div]:min-w-0 [&>div]:max-w-full border-t border-gray-200 dark:border-gray-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">mode</div>
            <.toggle_group
              variant="outline"
              size="sm"
              aria_label="Mode"
              value={@picker.mode}
              on_change="ctl_picker"
              class={@rail_class}
            >
              <:item :for={m <- ~w(single range)} value={m} phx-value-k="mode" phx-value-v={m}>
                {m}
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
                      {"two_months", @picker.two_months},
                      {"clearable", @picker.clearable}
                    ],
                    on,
                    do: k
              }
              on_change="ctl_picker"
              class={@rail_class}
            >
              <:item value="two_months" phx-value-k="two_months">two months</:item>
              <:item value="clearable" phx-value-k="clearable">clearable</:item>
            </.toggle_group>
          </div>
        </div>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Booking range</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        Check in and check out in one control, two months on screen, nothing before today
        selectable. Clicking a day pushes an event, so the server owns the range.
      </p>
      <div class="p-6 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="max-w-sm">
          <.date_picker
            id="pg-booking"
            name="booking[stay]"
            mode="range"
            two_months
            label="Stay"
            format="%a %d %b"
            min={Date.utc_today()}
            value={@pick_stay}
            on_select="stay_pick"
          />
        </div>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Birthday</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        A date decades back is faster to type than to page to, which is what the parse-on-blur
        contract is for. Type <code>12 Jun 1987</code> and the grid follows you there.
      </p>
      <div class="p-6 border border-gray-200 rounded-xl dark:border-gray-800">
        <div class="max-w-sm">
          <.date_picker
            id="pg-birthday"
            name="profile[born_on]"
            label="Date of birth"
            format="%d %b %Y"
            max={Date.utc_today()}
            value={@pick_birthday}
            on_select="birthday_pick"
          />
        </div>
      </div>

      <h2 class="mt-10 mb-1 text-lg font-semibold">Deadline, in a form</h2>
      <p class="mb-3 text-sm text-gray-500 dark:text-gray-400">
        The field surface, errors and all. Weekends are blacked out with a function, and the
        hidden input posts ISO 8601 whatever the display format says.
      </p>
      <div class="p-6 border border-gray-200 rounded-xl dark:border-gray-800">
        <.form :let={f} for={deadline_form(@pick_deadline)} class="max-w-sm">
          <.date_picker
            id="pg-deadline"
            field={f[:due_on]}
            label="Due date"
            required
            clearable
            placeholder="Pick a weekday"
            format="%d/%m/%Y"
            min={Date.utc_today()}
            disabled_dates={&(Date.day_of_week(&1) in [6, 7])}
            on_select="deadline_pick"
            on_clear="deadline_clear"
          />
          <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            Posts as <code>task[due_on]={date_text(@pick_deadline)}</code>
          </p>
        </.form>
      </div>

      <div
        :for={ex <- examples_for(PetalComponents.Showcase.DatePicker, ~w(basic errors)a)}
        class="mt-10"
      >
        <h2 class="mb-1 text-lg font-semibold">{ex.title}</h2>
        <p :if={ex.description} class="mb-3 text-sm text-gray-500 dark:text-gray-400">
          {ex.description}
        </p>
        <.showcase_example example={ex} />
      </div>

      <h2 class="mt-10 mb-2 text-lg font-semibold">Properties</h2>
      <.showcase_props component={PetalComponents.DatePicker} function={:date_picker} />

      <div class="p-4 mt-6 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        These examples render from the shared <code>PetalComponents.Showcase.DatePicker</code>
        registry - the same source petal.build renders, so the playground and the marketing
        docs can't drift.
      </div>
    </div>
    """
  end

  # -- Design Lab: before/after proof for the petal-design skill ------------
  # Public proof surface for bet 003. Pairs 1 and 2 are VERBATIM outputs from
  # the three-arm skill eval (skills/eval/demo-script.md): before = the
  # MCP-only arm / the task fixture, after = the skill arm (wrappers for
  # centering are presentation, the class strings are untouched). Pair 3 is an
  # authored doctrine illustration - original copy, generic AI-slop tells.
  #
  # The compare frame is dial-independent on purpose: it pins data-primary/
  # data-gray on the container so fixtures render identically under any
  # playground theme (chrome that dies under the neutral dial would violate
  # the very doctrine this page demonstrates).
  # Reachable by URL only (slug whitelisted, no nav entry): the skill arm's settings-page output,
  # VERBATIM (rev-2 prompt, 2026-08-28 - see skills/eval/demo-script.md),
  # rendered as a plain app page. Screenshot source for the
  # cold-start pair's after side.
  defp render_page(%{active: "eval-t1"} = assigns) do
    ~H"""
    <div id="eval-t1-page">
    <%
      user = %{name: "Sarah Chen", email: "sarah.chen@example.com"}

      notifications = [
        %{
          id: "notif-product-updates",
          name: "notifications[product_updates]",
          label: "Product updates",
          description: "New features and improvements, as they ship.",
          enabled: true
        },
        %{
          id: "notif-security-alerts",
          name: "notifications[security_alerts]",
          label: "Security alerts",
          description: "Sign-ins from new devices and other important account activity.",
          enabled: true
        },
        %{
          id: "notif-billing-emails",
          name: "notifications[billing_emails]",
          label: "Billing emails",
          description: "Receipts, upcoming renewals and payment reminders.",
          enabled: true
        },
        %{
          id: "notif-weekly-digest",
          name: "notifications[weekly_digest]",
          label: "Weekly digest",
          description: "A Monday morning summary of activity in your workspace.",
          enabled: false
        },
        %{
          id: "notif-tips-offers",
          name: "notifications[tips_offers]",
          label: "Tips and offers",
          description: "Occasional product tips and partner offers.",
          enabled: false
        }
      ]

      plan = %{name: "Pro", price: "$29", renews_on: "Sep 1, 2026", seats_used: 4, seats_total: 5}
      seats_left = plan.seats_total - plan.seats_used

      invoices = [
        %{date: "Aug 1, 2026", amount: "$29.00", status: "Pending", pdf: "/invoices/nimbus-2026-08.pdf"},
        %{date: "Jul 1, 2026", amount: "$29.00", status: "Paid", pdf: "/invoices/nimbus-2026-07.pdf"},
        %{date: "Jun 1, 2026", amount: "$29.00", status: "Paid", pdf: "/invoices/nimbus-2026-06.pdf"},
        %{date: "May 1, 2026", amount: "$29.00", status: "Paid", pdf: "/invoices/nimbus-2026-05.pdf"},
        %{date: "Apr 1, 2026", amount: "$29.00", status: "Paid", pdf: "/invoices/nimbus-2026-04.pdf"},
        %{date: "Mar 1, 2026", amount: "$29.00", status: "Paid", pdf: "/invoices/nimbus-2026-03.pdf"},
        %{date: "Feb 1, 2026", amount: "$29.00", status: "Paid", pdf: "/invoices/nimbus-2026-02.pdf"},
        %{date: "Jan 1, 2026", amount: "$29.00", status: "Paid", pdf: "/invoices/nimbus-2026-01.pdf"},
        %{date: "Dec 1, 2025", amount: "$29.00", status: "Paid", pdf: "/invoices/nimbus-2025-12.pdf"},
        %{date: "Nov 1, 2025", amount: "$29.00", status: "Paid", pdf: "/invoices/nimbus-2025-11.pdf"}
      ]
    %>
    <div class="min-h-screen bg-gray-50 dark:bg-gray-900">
      <header class="sticky top-0 z-30 border-b border-gray-200 bg-white dark:border-gray-400/17 dark:bg-gray-900">
        <.container max_width="md" class="flex h-16 items-center justify-between gap-4">
          <a
            href="/"
            class="flex items-center gap-2.5 focus:outline-hidden focus-visible:ring-2 focus-visible:ring-primary-500/50"
            style="border-radius: var(--pc-radius, 0.625rem);"
          >
            <span
              class="flex h-8 w-8 items-center justify-center bg-primary-600"
              style="border-radius: max(calc(var(--pc-radius, 0.625rem) - 0.25rem), 0.25rem);"
            >
              <.icon name="hero-cloud-solid" class="h-5 w-5" style="color: var(--pc-button-solid-fg, #fff);" />
            </span>
            <span class="text-base font-semibold tracking-tight text-gray-900 dark:text-white">
              Nimbus
            </span>
          </a>

          <.color_scheme_switch id="nimbus-color-scheme" variant="segmented" />
        </.container>
      </header>

      <main>
        <.container max_width="sm" class="py-10">
          <div class="mb-8">
            <.h2 no_margin>Settings</.h2>
            <.text_muted class="mt-1.5">
              Manage your profile, notifications and billing.
            </.text_muted>
          </div>

          <div class="space-y-8">
            <.card variant="basic">
              <.card_header title="Profile" description="How you appear across Nimbus." />
              <.card_content>
                <div class="flex items-center gap-4">
                  <.avatar name={user.name} size="xl" />
                  <div class="min-w-0">
                    <div class="truncate text-sm font-semibold text-gray-900 dark:text-white">
                      {user.name}
                    </div>
                    <div class="truncate text-sm text-gray-500 dark:text-gray-400">
                      {user.email}
                    </div>
                  </div>
                </div>

                <div class="mt-6 grid gap-6 sm:grid-cols-2">
                  <.field
                    type="text"
                    id="profile-name"
                    name="profile[name]"
                    label="Full name"
                    value={user.name}
                    no_margin
                  />
                  <.field
                    type="email"
                    id="profile-email"
                    name="profile[email]"
                    label="Email address"
                    value={user.email}
                    no_margin
                  />
                </div>
              </.card_content>
              <.card_footer class="flex justify-end">
                <.button label="Save changes" color="primary" phx-click="save_profile" />
              </.card_footer>
            </.card>

            <.card variant="basic">
              <.card_header title="Notifications" description="Choose what lands in your inbox." />
              <.card_content>
                <div class="divide-y divide-gray-200 dark:divide-gray-400/17">
                  <div
                    :for={notification <- notifications}
                    class="flex items-center justify-between gap-6 py-4 first:pt-0 last:pb-0"
                  >
                    <div class="min-w-0">
                      <div class="text-sm font-medium text-gray-900 dark:text-gray-200">
                        {notification.label}
                      </div>
                      <div class="mt-0.5 text-sm text-gray-500 dark:text-gray-400">
                        {notification.description}
                      </div>
                    </div>
                    <.field
                      type="switch"
                      id={notification.id}
                      name={notification.name}
                      label={notification.label}
                      label_class="sr-only"
                      checked={notification.enabled}
                      no_margin
                    />
                  </div>
                </div>
              </.card_content>
            </.card>

            <.card variant="basic">
              <.card_header title="Plan" description="Billing for your Nimbus workspace.">
                <:action>
                  <.badge color="primary" variant="soft" size="sm" label={plan.name} />
                </:action>
              </.card_header>
              <.card_content>
                <div class="flex flex-wrap items-baseline gap-x-2 gap-y-1">
                  <span class="text-3xl font-semibold tracking-tight text-gray-900 dark:text-white">
                    {plan.price}
                  </span>
                  <span class="text-sm text-gray-500 dark:text-gray-400">
                    per month &middot; renews {plan.renews_on}
                  </span>
                </div>

                <div class="mt-6">
                  <div class="flex items-center justify-between text-sm">
                    <span class="font-medium text-gray-900 dark:text-gray-200">Seats</span>
                    <span class="text-gray-500 dark:text-gray-400">
                      {plan.seats_used} of {plan.seats_total} used
                    </span>
                  </div>
                  <.progress
                    value={plan.seats_used}
                    max={plan.seats_total}
                    color="primary"
                    size="sm"
                    class="mt-2"
                  />
                  <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
                    {seats_left} seat remaining on the {plan.name} plan.
                  </p>
                </div>
              </.card_content>
              <.card_footer class="flex items-center justify-end gap-2">
                <.button label="Manage billing" color="gray" variant="outline" phx-click="manage_billing" />
                <.button label="Upgrade plan" color="primary" phx-click="upgrade_plan" />
              </.card_footer>
            </.card>

            <.card variant="basic">
              <.card_header title="Invoices" description="Your last 10 invoices." />
              <.card_content>
                <div class="max-w-full overflow-x-auto">
                  <.table rows={invoices} variant="ghost">
                    <:col :let={invoice} label="Date">
                      <span class="font-medium text-gray-900 dark:text-gray-100">{invoice.date}</span>
                    </:col>
                    <:col :let={invoice} label="Amount" class="text-right" row_class="text-right tabular-nums">
                      {invoice.amount}
                    </:col>
                    <:col :let={invoice} label="Status">
                      <.badge
                        color={if invoice.status == "Paid", do: "success", else: "warning"}
                        variant="soft"
                        size="sm"
                        label={invoice.status}
                      />
                    </:col>
                    <:col :let={invoice} label="Invoice" class="text-right" row_class="text-right">
                      <.a
                        to={invoice.pdf}
                        class="inline-flex items-center gap-1.5 text-sm font-medium text-primary-600 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300 focus:outline-hidden focus-visible:ring-2 focus-visible:ring-primary-500/50 transition-colors duration-200 ease-out"
                        style="border-radius: max(calc(var(--pc-radius, 0.625rem) - 0.25rem), 0.25rem);"
                      >
                        <.icon name="hero-arrow-down-tray-micro" class="h-4 w-4" />
                        <span>PDF</span>
                      </.a>
                    </:col>
                  </.table>
                </div>
              </.card_content>
            </.card>
          </div>
        </.container>
      </main>
    </div>
    </div>
    """
  end

  defp render_page(%{active: "design-skill"} = assigns) do
    ~H"""
    <div class="max-w-4xl px-4 py-8 mx-auto sm:px-8 sm:py-10">
      <h1 class="text-3xl font-bold tracking-tight">The petal-design skill</h1>
      <p class="mt-2 text-gray-600 dark:text-gray-300">
        An agent skill that carries this design system's doctrine - so AI coding agents
        build, review, and theme Petal UI the way the library intends. Drag each divider.
        Pairs badged "verbatim eval output" are real eval material, untouched; the rest are
        labelled doctrine illustrations. Panels are display fixtures - the interactive
        components live on their own playground pages.
      </p>

      <.lab_compare
        id="lab-cold"
        title="Cold start: fresh Phoenix vs the Petal stack"
        badge="verbatim eval output"
        construction="fresh phx.new → Petal + MCP + skill"
        live_href="/c/eval-t1"
        prompt="Build a settings LiveView at /settings: app navbar with the product logo on the left and a theme switcher on the right (System / Light / Dark segmented control); profile section (name, email, avatar); notification toggles; and a billing section with a table of the last 10 invoices (date, amount, status, PDF link) plus a plan card showing seat usage (4 of 5 seats) with a usage progress bar and an upgrade button. Support light and dark mode."
        note="Same settings-page prompt, one attempt each, screenshots untouched. Before: an agent in a just-generated Phoenix 1.8 app - it gets the stock daisyUI look, a different system with different opinions. After: the skill arm in a Petal app. This pair is two screenshots, not one DOM: the two sides are different apps by construction."
      >
        <:before_panel>
          <%!-- each side ships light and dark captures (both apps rendered in
          their own native theme machinery) and class-swaps with the page - so
          this image pair follows the theme toggle like the live-DOM pairs. --%>
          <img src="/dev-static/lab-coldstart-before.png" alt="Settings page built by an agent in a fresh Phoenix app" class="block w-full dark:hidden" />
          <img src="/dev-static/lab-coldstart-before-dark.png" alt="Settings page built by an agent in a fresh Phoenix app, dark mode" class="hidden w-full dark:block" />
        </:before_panel>
        <:after_panel>
          <img src="/dev-static/lab-coldstart-after.png" alt="Settings page built by the skill agent in a Petal app" class="block w-full dark:hidden" />
          <img src="/dev-static/lab-coldstart-after-dark.png" alt="Settings page built by the skill agent in a Petal app, dark mode" class="hidden w-full dark:block" />
        </:after_panel>
      </.lab_compare>

      <%!-- Section break: the pair above is the outcome, everything below is the
      mechanism. Without a heading the two visuals run together. --%>
      <div class="mt-12">
        <h2 class="text-lg font-semibold">How it works</h2>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          The library, the MCP and the skill each cover a different part of what an agent writes.
        </p>
      </div>

      <%!-- The layer diagram: what each of the three pieces guards, and why the
      output coheres. Portrait layout on purpose - the wide version reads at
      ~10px type in this column. Colours come off the dials (see .dstack in
      app.css), so the figure demonstrates the token layer it describes. --%>
      <figure class="dstack p-5 mt-4 mb-0 border border-gray-200 rounded-xl dark:border-gray-800">
        <svg
          viewBox="0 0 900 674"
          role="img"
          aria-label="A prompt goes to an AI agent, which writes two kinds of code: component calls, guarded by the MCP server that resolves schemas, and custom markup, guarded by the petal-design skill that applies doctrine. Both pass through one shared token layer and converge into a single cohesive UI."
        >
          <defs>
            <marker id="dstack-ar" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
              <path class="dstack-arrow" d="M 0 0 L 10 5 L 0 10 z" />
            </marker>
            <marker id="dstack-ar-a" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
              <path class="dstack-arrow-a" d="M 0 0 L 10 5 L 0 10 z" />
            </marker>
          </defs>

          <rect class="dstack-box" x="340" y="16" width="220" height="60" rx="10" />
          <text class="dstack-eyebrow" x="450" y="40" text-anchor="middle">YOUR PROMPT</text>
          <text class="dstack-sub" x="450" y="60" text-anchor="middle">“Build a settings page”</text>
          <line class="dstack-flow" x1="450" y1="76" x2="450" y2="92" marker-end="url(#dstack-ar)" />

          <rect class="dstack-box" x="355" y="96" width="190" height="76" rx="10" />
          <text class="dstack-title" x="450" y="130" text-anchor="middle">AI agent</text>
          <text class="dstack-sub" x="450" y="152" text-anchor="middle">writes HEEx</text>

          <path class="dstack-flow" d="M 438 172 C 415 236, 415 367, 384 367" marker-end="url(#dstack-ar)" />
          <path class="dstack-flow" d="M 462 172 C 485 236, 485 367, 516 367" marker-end="url(#dstack-ar)" />
          <text class="dstack-edge" x="424" y="188" text-anchor="end">calls</text>
          <text class="dstack-edge" x="476" y="188">writes</text>

          <rect class="dstack-guard" x="40" y="196" width="340" height="88" rx="10" />
          <text class="dstack-eyebrow" x="210" y="222" text-anchor="middle">SCHEMA TRUTH</text>
          <text class="dstack-title" x="210" y="246" text-anchor="middle">MCP server</text>
          <text class="dstack-sub" x="210" y="268" text-anchor="middle">mcp.petal.build</text>
          <line class="dstack-flow-a" x1="210" y1="284" x2="210" y2="304" marker-end="url(#dstack-ar-a)" />
          <text class="dstack-edge" x="222" y="300">resolves attrs, slots, enums</text>

          <rect class="dstack-guard" x="520" y="196" width="340" height="88" rx="10" />
          <text class="dstack-eyebrow" x="690" y="222" text-anchor="middle">DESIGN DOCTRINE</text>
          <text class="dstack-title" x="690" y="246" text-anchor="middle">petal-design skill</text>
          <text class="dstack-sub" x="690" y="268" text-anchor="middle">ghost ladder · dark pairs · focus ring</text>
          <line class="dstack-flow-a" x1="690" y1="284" x2="690" y2="304" marker-end="url(#dstack-ar-a)" />
          <text class="dstack-edge" x="702" y="300">applies the doctrine</text>

          <rect class="dstack-box" x="40" y="308" width="340" height="118" rx="10" />
          <text class="dstack-title" x="210" y="342" text-anchor="middle">Component calls</text>
          <text class="dstack-mono" x="210" y="368" text-anchor="middle">&lt;.card&gt; &lt;.field&gt; &lt;.table&gt;</text>
          <text class="dstack-sub" x="210" y="394" text-anchor="middle">213 surfaces, already styled</text>

          <rect class="dstack-box" x="520" y="308" width="340" height="118" rx="10" />
          <text class="dstack-title" x="690" y="342" text-anchor="middle">Custom markup</text>
          <text class="dstack-sub" x="690" y="368" text-anchor="middle">layout, wrappers, one-offs</text>
          <text class="dstack-sub" x="690" y="392" text-anchor="middle">no library ships this part</text>

          <line class="dstack-flow" x1="210" y1="426" x2="210" y2="462" marker-end="url(#dstack-ar)" />
          <line class="dstack-flow" x1="690" y1="426" x2="690" y2="462" marker-end="url(#dstack-ar)" />

          <rect class="dstack-band" x="40" y="466" width="820" height="68" rx="12" />
          <text class="dstack-band-label" x="450" y="496" text-anchor="middle">TOKEN LAYER</text>
          <text class="dstack-sub" x="450" y="518" text-anchor="middle">@theme ramps · the gray dial · --pc-radius · the dark ghost material</text>

          <line class="dstack-flow" x1="450" y1="534" x2="450" y2="562" marker-end="url(#dstack-ar)" />

          <rect class="dstack-box" x="310" y="566" width="280" height="92" rx="10" />
          <text class="dstack-title" x="450" y="602" text-anchor="middle">One cohesive UI</text>
          <text class="dstack-sub" x="450" y="626" text-anchor="middle">light and dark, on brand</text>
        </svg>
        <figcaption class="pt-4 mt-5 text-sm text-gray-600 border-t border-gray-200 dark:border-gray-800 dark:text-gray-300">
          An agent writes two kinds of code, and each gets a different guard: the MCP resolves every
          attr against the installed version, the skill governs the markup no library ships. Both then
          read the same tokens, which is why the result coheres instead of being two styles glued
          together - change the primary ramp, the gray dial or <code>--pc-radius</code> once and the
          shipped components and the hand-written markup move together. Including, right now, this
          diagram: it is drawn in the dials above.
        </figcaption>
      </figure>

      <div class="p-5 mt-10 border border-gray-200 rounded-xl dark:border-gray-800">
        <h2 class="text-sm font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">How you use it</h2>
        <ol class="mt-3 space-y-2 text-sm text-gray-600 list-decimal list-inside dark:text-gray-300">
          <li>
            <strong>Install once</strong> - <code>claude plugin install petal-design</code>, or copy
            <code>deps/petal_components/skills/petal-design</code> into your project's <code>.claude/skills/</code>.
          </li>
          <li>
            <strong>Then just work</strong> - the skill triggers itself. Ask your agent to build a page,
            review a diff, or rebrand, and it loads the right doctrine before writing HEEx. There is no
            command to remember and no setup interview: Petal ships the design system, so the skill
            already knows it.
          </li>
        </ol>
      </div>

      <div class="p-5 mt-6 border border-gray-200 rounded-xl dark:border-gray-800">
        <h2 class="text-sm font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">Under the hood</h2>
        <p class="mt-3 text-sm text-gray-600 dark:text-gray-300">
          One skill, no command palette: nine markdown files, zero executable code. A request routes
          by its shape into one of three modes, and each mode loads only the doctrine it needs.
        </p>
        <div class="grid gap-5 mt-4 sm:grid-cols-3">
          <div>
            <div class="text-sm font-semibold text-gray-900 dark:text-white">Build</div>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-300">
              Writes HEEx to the craft floor - components over raw tags, the gray dial,
              a dark pair on every colour, radius from the one knob.
            </p>
            <p class="mt-1.5 text-xs text-gray-400 dark:text-gray-500">"Add a billing settings page"</p>
          </div>
          <div>
            <div class="text-sm font-semibold text-gray-900 dark:text-white">Review</div>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-300">
              Audits a diff - a written design judgment first, then a 13-row grep table and
              schema spot-checks, reported as P0-P3 findings.
            </p>
            <p class="mt-1.5 text-xs text-gray-400 dark:text-gray-500">"Review this diff for design drift"</p>
          </div>
          <div>
            <div class="text-sm font-semibold text-gray-900 dark:text-white">Theme</div>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-300">
              Rebrands through the token layer - primary ramp, gray remap, the radius knob,
              the dark ghost material. Never per-element edits.
            </p>
            <p class="mt-1.5 text-xs text-gray-400 dark:text-gray-500">"Make it warm amber, sharp corners"</p>
          </div>
        </div>
      </div>

      <.lab_compare
        id="lab-soup"
        title="Tailwind soup to the system"
        badge="verbatim eval output"
        construction="task fixture → MCP + skill"
        note="Task: convert a hand-rolled invoices view. Before: the fixture - literal zinc palette, raw table, hand-rolled fixed inset-0 modal, hover:opacity on a solid. After: the skill arm's conversion - table, soft badge, and the confirm becomes a real alert_dialog."
      >
        <:before_panel>
          <div class="flex justify-center p-8 bg-white dark:bg-gray-950">
            <div class="w-full max-w-lg pb-4">
              <h2 class="text-xl font-bold text-zinc-800 mb-4 dark:text-zinc-100">Invoices</h2>
              <table class="w-full border border-zinc-200 rounded-lg dark:border-zinc-700">
                <thead>
                  <tr class="bg-zinc-100 text-left dark:bg-zinc-800">
                    <th class="px-4 py-2 text-sm text-zinc-500">Date</th>
                    <th class="px-4 py-2 text-sm text-zinc-500">Amount</th>
                    <th class="px-4 py-2 text-sm text-zinc-500">Status</th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={inv <- lab_invoices()} class="border-t border-zinc-200 dark:border-zinc-700">
                    <td class="px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300">{inv.date}</td>
                    <td class="px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300">{inv.amount}</td>
                    <td class="px-4 py-2"><span class="px-2 py-1 rounded-full text-xs bg-green-100 text-green-800">{inv.status}</span></td>
                  </tr>
                </tbody>
              </table>
              <button class="mt-4 px-4 py-2 bg-blue-600 text-white rounded-lg hover:opacity-90 focus:outline-none">Delete all</button>
            </div>
          </div>
        </:before_panel>
        <:before_chips>
          <span class="lab-chip" style="top: 3.31rem; right: calc(100% + 1.25rem);">zinc palette</span>
          <span class="lab-chip" style="top: 14.44rem; right: calc(100% + 1.25rem);">hover:opacity</span>
        </:before_chips>
        <:after_panel>
          <div class="flex justify-center p-8 bg-white dark:bg-gray-950">
            <div class="w-full max-w-lg pb-4">
              <.h2>Invoices</.h2>
              <div class="max-w-full overflow-x-auto">
                <.table rows={lab_invoices()}>
                  <:col :let={inv} label="Date">{inv.date}</:col>
                  <:col :let={inv} label="Amount">{inv.amount}</:col>
                  <:col :let={inv} label="Status">
                    <.badge color="success" variant="soft" size="sm" label={inv.status} />
                  </:col>
                </.table>
              </div>
              <div class="mt-4">
                <.alert_dialog
                  id="lab-confirm"
                  variant="destructive"
                  title="Are you sure?"
                  description="This cannot be undone."
                  confirm_label="Delete all"
                >
                  <:trigger>
                    <.button color="danger">Delete all</.button>
                  </:trigger>
                </.alert_dialog>
              </div>
            </div>
          </div>
        </:after_panel>
        <:after_chips>
          <span class="lab-chip lab-chip--improved lab-chip--point-left" style="top: 6.85rem; left: 27.85rem;">soft badge</span>
          <%!-- lab-chip--reveal-30: this chip sits beside the danger button, in the
          region the BEFORE layer covers at rest - so it only fades in once the
          divider sweeps left far enough to actually reveal that button. --%>
          <span class="lab-chip lab-chip--improved lab-chip--point-left lab-chip--reveal-30" style="top: 17.22rem; left: 7.1rem;">alert_dialog</span>
        </:after_chips>
      </.lab_compare>

      <.lab_compare
        id="lab-theme"
        title="Theme mode: the same markup, made yours"
        badge="doctrine illustration"
        construction="identical HEEx, dials only"
        note="Both sides are identical HEEx. The after side sits inside one wrapper carrying the amber primary, the stone gray dial, and --pc-radius: 0 - in an app that is a single @theme block, and the skill's theme mode writes it for you. Retro, corporate, brutalist: the dials do not care."
      >
        <:before_panel>
          <div class="flex justify-center p-8 bg-white dark:bg-gray-950">
            <.card class="w-full max-w-lg">
              <.card_header title="Nightly build" description="Deploys automatically when the suite is green." />
              <.card_content>
                <.progress size="sm" color="primary" value={7} max={10} />
                <div class="mt-3 flex items-center justify-between text-sm">
                  <span class="text-gray-500 dark:text-gray-400">7 of 10 checks passed</span>
                  <.button size="sm" color="primary" label="View pipeline" />
                </div>
              </.card_content>
            </.card>
          </div>
        </:before_panel>
        <:after_panel>
          <div class="flex justify-center p-8 bg-white dark:bg-gray-950">
            <div class="w-full max-w-lg font-mono" data-primary="amber" data-gray="stone" style="--pc-radius: 0">
              <.card class="w-full">
                <.card_header title="Nightly build" description="Deploys automatically when the suite is green." />
                <.card_content>
                  <.progress size="sm" color="primary" value={7} max={10} />
                  <div class="mt-3 flex items-center justify-between text-sm">
                    <span class="text-gray-500 dark:text-gray-400">7 of 10 checks passed</span>
                    <.button size="sm" color="primary" label="View pipeline" />
                  </div>
                </.card_content>
              </.card>
            </div>
          </div>
        </:after_panel>
        <:after_chips>
          <span class="lab-chip lab-chip--improved lab-chip--point-left" style="top: 1.5rem; left: calc(100% + 1.25rem);">amber + stone dials</span>
          <span class="lab-chip lab-chip--improved lab-chip--point-left" style="top: 5.31rem; left: calc(100% + 1.25rem);">--pc-radius: 0</span>
        </:after_chips>
      </.lab_compare>

      <.lab_compare
        id="lab-polish"
        title="The polish pass"
        badge="doctrine illustration"
        construction="authored slop → on the system"
        note="The AI-slop tells the review playbook hunts: kicker caps, italic display serif, side-tab border, off-system cream, hardcoded radius. After: the same content on the system - token surface, house type, one accent."
      >
        <:before_panel>
          <div class="flex justify-center p-8 bg-white dark:bg-gray-950">
            <div class="w-full max-w-lg border-l-4 border-violet-400 bg-[#f4efe4] rounded-2xl p-6">
              <div class="text-[10px] uppercase tracking-[0.22em] text-stone-400 font-semibold">Usage &amp; limits</div>
              <p class="mt-2 text-2xl text-stone-800" style="font-family: Georgia, serif;">Your team is <em>almost</em> out of seats.</p>
              <p class="mt-2 text-sm text-stone-500">9 of 10 member seats are in use across two workspaces.</p>
              <div class="mt-4 h-1.5 rounded-full bg-stone-200"><div class="h-1.5 w-[90%] rounded-full bg-emerald-400"></div></div>
              <div class="mt-3 flex items-center justify-between text-sm">
                <span class="text-stone-500">Renews 1 Oct</span>
                <a href="#" class="font-semibold text-stone-800">Add seats &rarr;</a>
              </div>
            </div>
          </div>
        </:before_panel>
        <:before_chips>
          <span class="lab-chip" style="top: 1.34rem; right: calc(100% + 1.25rem);">kicker caps</span>
          <span class="lab-chip" style="top: 3.31rem; right: calc(100% + 1.25rem);">display serif</span>
          <span class="lab-chip" style="top: 5.16rem; right: calc(100% + 1.25rem);">side-tab + cream</span>
        </:before_chips>
        <:after_panel>
          <div class="flex justify-center p-8 bg-white dark:bg-gray-950">
            <.card class="w-full max-w-lg">
              <.card_header title="Your team is almost out of seats" description="9 of 10 member seats are in use across two workspaces." />
              <.card_content>
                <.progress size="sm" color="primary" value={9} max={10} />
                <div class="mt-3 flex items-center justify-between text-sm">
                  <span class="text-gray-500 dark:text-gray-400">Renews 1 Oct</span>
                  <.button variant="ghost" size="sm" color="primary" label="Add seats" />
                </div>
              </.card_content>
            </.card>
          </div>
        </:after_panel>
        <:after_chips>
          <span class="lab-chip lab-chip--improved lab-chip--point-left" style="top: 1.5rem; left: calc(100% + 1.25rem);">token surface</span>
          <span class="lab-chip lab-chip--improved lab-chip--point-left" style="top: 7.38rem; left: calc(100% + 1.25rem);">one accent</span>
        </:after_chips>
      </.lab_compare>

      <.lab_compare
        id="lab-dark"
        title="Dark mode: the ghost ladder vs mechanical inversion"
        badge="verbatim eval output"
        construction="MCP-only → MCP + skill"
        note="Task: add dark mode to a light-only card. Before: the MCP-only arm - schema access carries no styling doctrine, so it inverts to opaque gray-800/gray-600. After: the skill arm lands the ghost ladder exactly - dark chrome as alpha-of-gray-400 (/8 surface, /17 hairline, /25 input border), so the ghost carries the gray dial's hue. Both sides render forced-dark on purpose: the task under eval is dark mode, so the playground's theme toggle deliberately does not affect this pair."
      >
        <:before_panel>
          <div class="dark"><div class="flex justify-center p-8 bg-gray-950">
            <div class="w-full max-w-lg rounded-lg border border-gray-200 bg-white p-6 shadow-xs dark:border-gray-700 dark:bg-gray-800">
              <h3 class="font-semibold text-gray-900 dark:text-gray-100">API keys</h3>
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">Rotate keys regularly.</p>
              <input type="text" class="mt-4 block w-full rounded-lg border border-gray-300 p-2 text-gray-900 placeholder:text-gray-400 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-100 dark:placeholder:text-gray-500" placeholder="sk-..." />
              <button class="mt-4 rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700">Rotate</button>
            </div>
          </div></div>
        </:before_panel>
        <:before_chips>
          <span class="lab-chip" style="top: 0.4rem; right: calc(100% + 1.25rem);">opaque gray-800</span>
          <span class="lab-chip" style="top: 6.25rem; right: calc(100% + 1.25rem);">gray-600 border</span>
        </:before_chips>
        <:after_panel>
          <div class="dark"><div class="flex justify-center p-8 bg-gray-950">
            <div class="w-full max-w-lg rounded-lg border border-gray-200 dark:border-gray-400/17 bg-white dark:bg-gray-900 p-6 shadow-xs">
              <h3 class="font-semibold text-gray-900 dark:text-white">API keys</h3>
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">Rotate keys regularly.</p>
              <input type="text" class="mt-4 block w-full rounded-lg border border-gray-300 dark:border-gray-400/25 dark:bg-gray-400/8 p-2 text-gray-900 dark:text-white placeholder:text-gray-400 dark:placeholder:text-gray-500" placeholder="sk-..." />
              <button class="mt-4 rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700">Rotate</button>
            </div>
          </div></div>
        </:after_panel>
        <:after_chips>
          <span class="lab-chip lab-chip--improved lab-chip--point-left" style="top: 0.4rem; left: calc(100% + 1.25rem);">gray-900 panel</span>
          <span class="lab-chip lab-chip--improved lab-chip--point-left" style="top: 6.25rem; left: calc(100% + 1.25rem);">ghost /8 + /25</span>
        </:after_chips>
      </.lab_compare>

      <div class="p-4 mt-8 text-sm text-gray-500 border border-gray-200 rounded-xl dark:border-gray-800 dark:text-gray-400">
        Methodology: <code>skills/eval/demo-script.md</code> in the repo. The skill is
        <code>skills/petal-design/</code> - nine files, no executable code; it routes build,
        review, and theme requests and resolves every schema through the MCP ladder.
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:title, :string, required: true)
  attr(:badge, :string, required: true)
  attr(:construction, :string, required: true)
  attr(:note, :string, required: true)
  attr(:prompt, :string, default: nil)
  attr(:live_href, :string, default: nil)
  attr(:live_label, :string, default: "View the after side live")
  slot(:before_panel, required: true)
  slot(:after_panel, required: true)
  slot(:before_chips, required: false)
  slot(:after_chips, required: false)

  # The compare frame. Two stacked layers; the after layer (and its chips) clip
  # to the right of --pos, the before chips clip to the LEFT of --pos so they
  # dismiss as the divider crosses them. The range input is invisible and spans
  # the whole panel (ew-resize cursor); a round grab handle rides the seam.
  # data-primary/data-gray are pinned so fixtures render the same under any dial.
  defp lab_compare(assigns) do
    ~H"""
    <section id={@id} class="mt-10">
      <div class="flex flex-wrap items-center gap-3">
        <h2 class="text-lg font-semibold">{@title}</h2>
        <span class="px-2 py-0.5 text-[11px] font-bold uppercase tracking-wide rounded-md bg-teal-600 text-white">{@construction}</span>
        <span class="px-2 py-0.5 text-[11px] font-medium uppercase tracking-wide rounded-md border border-gray-200 text-gray-500 dark:border-gray-400/17 dark:text-gray-400">{@badge}</span>
      </div>
      <p class="mt-1 mb-3 text-sm text-gray-500 dark:text-gray-400">{@note}</p>
      <div :if={@prompt || @live_href} class="flex items-start justify-between gap-4 -mt-2 mb-2">
        <details :if={@prompt} class="group min-w-0 flex-1">
          <summary class="inline-flex cursor-pointer select-none items-center gap-1.5 text-xs font-medium text-gray-400 transition-colors duration-200 ease-out hover:text-gray-700 dark:text-gray-500 dark:hover:text-gray-200">
            <span class="lab-prompt-caret transition-transform duration-200">▸</span> The exact prompt both agents received
          </summary>
          <p class="mt-2 max-w-3xl rounded-lg border border-gray-200 bg-gray-50 p-3 font-mono text-xs leading-relaxed text-gray-700 dark:border-gray-400/17 dark:bg-gray-400/8 dark:text-gray-300">{@prompt}</p>
        </details>
        <.button
          :if={@live_href}
          link_type="a"
          to={@live_href}
          target="_blank"
          rel="noopener"
          size="xs"
          color="primary"
          class="ml-auto shrink-0"
        >
          {@live_label}
          <.icon name="hero-arrow-top-right-on-square-micro" class="w-3.5 h-3.5" />
        </.button>
      </div>
      <div
        class="relative grid overflow-hidden border border-gray-200 rounded-xl dark:border-gray-800"
        style="--pos: 55%; --pos-n: 55"
        data-lab-compare
        data-primary="blue"
        data-gray="zinc"
      >
        <%!-- isolate: pc components carry internal z-indexes (progress fill is
        z-[1]); without a stacking context per layer, the BEFORE side's fill
        escapes and paints over the AFTER layer - blue bar over amber, found
        the hard way on the theme pair. --%>
        <div class="relative isolate col-start-1 row-start-1 lab-layer">
          {render_slot(@before_panel)}
          <span class="lab-side-label lab-side-label--before" style="left: 1rem;">Before</span>
        </div>
        <div :if={@before_chips != []} class="absolute inset-0 z-10 pointer-events-none lab-chips lab-chips--before">
          <div class="flex justify-center h-full p-8">
            <div class="relative w-full max-w-lg">{render_slot(@before_chips)}</div>
          </div>
        </div>
        <div class="relative isolate col-start-1 row-start-1 lab-layer" style="clip-path: inset(0 0 0 var(--pos))">
          {render_slot(@after_panel)}
          <span class="lab-side-label lab-side-label--after" style="right: 1rem;">After</span>
        </div>
        <div :if={@after_chips != []} class="absolute inset-0 z-10 pointer-events-none lab-chips lab-chips--after">
          <div class="flex justify-center h-full p-8">
            <div class="relative w-full max-w-lg">{render_slot(@after_chips)}</div>
          </div>
        </div>
        <div class="lab-seam" style="left: var(--pos)"></div>
        <div class="lab-handle" style="left: var(--pos)">&harr;</div>
        <input
          type="range"
          min="0"
          max="100"
          value="55"
          aria-label="Reveal the after state"
          class="lab-range"
          oninput="const f = this.closest('[data-lab-compare]'); f.style.setProperty('--pos', this.value + '%'); f.style.setProperty('--pos-n', this.value)"
        />
      </div>
    </section>
    """
  end

  defp lab_invoices do
    [
      %{date: "2026-08-01", amount: "$29.00", status: "paid"},
      %{date: "2026-07-01", amount: "$29.00", status: "paid"},
      %{date: "2026-06-01", amount: "$29.00", status: "paid"}
    ]
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
  # request, unconditionally - no mtime check (see its CodeReloader.reload/2).
  # That cost ~12s when first measured and ~24s after the 4.15 wave doubled
  # the file, which made dev mode feel broken next to the deployed playground
  # (deploy mode compiles once, hence prod's 1s loads).
  #
  # Two fixes layered here:
  #   1. mtime gate - skip the re-eval entirely while dev.exs is unchanged,
  #      so only the first request after an edit pays the compile. The gate
  #      state lives in :persistent_term because this very module is replaced
  #      by each reload.
  #   2. global lock (pre-existing) - two concurrent requests race the
  #      compiler and crash with "module is currently being defined";
  #      re-check the gate inside the lock so the loser of the race skips.
  def reload(endpoint, opts) do
    path = Application.get_env(:phoenix_playground, :file)

    if is_nil(path) or stale?(path) do
      :global.trans({__MODULE__, self()}, fn ->
        if is_nil(path) or stale?(path) do
          result = PhoenixPlayground.CodeReloader.reload(endpoint, opts)
          path && :persistent_term.put({Dev.Reloader, :mtime}, mtime(path))
          result
        else
          :ok
        end
      end)
    else
      :ok
    end
  end

  defp stale?(path), do: :persistent_term.get({Dev.Reloader, :mtime}, nil) != mtime(path)

  defp mtime(path) do
    case File.stat(path) do
      {:ok, %{mtime: t}} -> t
      # fs blip (vim save dance): treat as changed, the reload path re-reads
      {:error, _} -> :unknown
    end
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
  if System.get_env("PLAYGROUND_DEPLOY") != "true" and
       System.get_env("PLAYGROUND_RELOAD", "true") != "false" do
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
  # PLAYGROUND_RELOAD=false compiles out the reload machinery entirely (this
  # option AND the hardcoded endpoint plugs below - both must be gated).
  # Rarely needed now: Dev.Reloader's mtime gate makes default dev mode fast
  # on unchanged requests; only the first request after an edit pays ~24s.
  live_reload: not deploy? and System.get_env("PLAYGROUND_RELOAD", "true") != "false",
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
