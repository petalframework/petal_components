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
        <link rel="stylesheet" href="/assets/app.css" />
      </head>
      <body class="bg-white antialiased">
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

  @nav [
    %{group: "Foundations",
      items: [
        %{slug: "typography", name: "Typography", icon: "hero-language", ready: false},
        %{slug: "colors", name: "Colours", icon: "hero-swatch", ready: false}
      ]},
    %{group: "Inputs",
      items: [
        %{slug: "button", name: "Button", icon: "hero-cursor-arrow-rays", ready: true},
        %{slug: "input", name: "Input", icon: "hero-pencil-square", ready: false},
        %{slug: "checkbox", name: "Checkbox", icon: "hero-check-circle", ready: false},
        %{slug: "select", name: "Select", icon: "hero-chevron-up-down", ready: false}
      ]},
    %{group: "Feedback",
      items: [
        %{slug: "alert", name: "Alert", icon: "hero-exclamation-triangle", ready: false},
        %{slug: "badge", name: "Badge", icon: "hero-tag", ready: false},
        %{slug: "progress", name: "Progress", icon: "hero-bars-3-bottom-left", ready: false}
      ]},
    %{group: "Overlay",
      items: [
        %{slug: "modal", name: "Modal", icon: "hero-window", ready: false},
        %{slug: "dropdown", name: "Dropdown", icon: "hero-chevron-down", ready: false}
      ]},
    %{group: "Effects",
      items: [
        %{slug: "border-beam", name: "Border beam", icon: "hero-sparkles", ready: false},
        %{slug: "meteors", name: "Meteors", icon: "hero-star", ready: false}
      ]}
  ]

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       nav: @nav,
       active: "button",
       dark: false,
       variant: "solid",
       size: "md",
       show_code: false
     )}
  end

  def handle_event("select", %{"slug" => slug}, socket),
    do: {:noreply, assign(socket, active: slug, show_code: false)}

  def handle_event("toggle_dark", _, socket),
    do: {:noreply, update(socket, :dark, &(!&1))}

  def handle_event("set", %{"k" => k, "v" => v}, socket),
    do: {:noreply, assign(socket, String.to_existing_atom(k), v)}

  def handle_event("toggle_code", _, socket),
    do: {:noreply, update(socket, :show_code, &(!&1))}

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <div class={[
      "flex flex-col h-screen bg-white text-gray-900 dark:bg-zinc-950 dark:text-zinc-50",
      @dark && "dark"
    ]}>
      <header class="flex items-center justify-between flex-none px-4 border-b h-14 border-gray-200 dark:border-zinc-800">
        <div class="flex items-center gap-2 text-[15px] font-semibold">
          <.icon name="hero-sparkles" class="w-5 h-5 text-primary-600" /> petal
          <span class="font-normal text-gray-400 dark:text-zinc-500">playground</span>
        </div>
        <div class="flex items-center gap-1.5">
          <button class="hidden md:flex items-center gap-2 h-8 pl-3 pr-2 mr-1 text-sm text-gray-400 border rounded-lg w-56 border-gray-200 dark:border-zinc-800 hover:bg-gray-50 dark:hover:bg-zinc-900">
            <.icon name="hero-magnifying-glass" class="w-4 h-4" />
            <span>Search components</span>
            <kbd class="ml-auto text-[11px] px-1.5 py-0.5 rounded border border-gray-200 dark:border-zinc-700">⌘K</kbd>
          </button>
          <a href="https://github.com/petalframework/petal_components" target="_blank" class="flex items-center h-8 gap-1.5 px-2.5 text-sm rounded-lg text-gray-600 dark:text-zinc-300 hover:bg-gray-100 dark:hover:bg-zinc-900">
            <svg viewBox="0 0 438.549 438.549" class="w-4 h-4" fill="currentColor"><path d="M409.132 114.573c-19.608-33.596-46.205-60.194-79.798-79.8-33.598-19.607-70.277-29.408-110.063-29.408-39.781 0-76.472 9.804-110.063 29.408-33.596 19.605-60.192 46.204-79.8 79.8C9.803 148.168 0 184.854 0 224.63c0 47.78 13.94 90.745 41.827 128.906 27.884 38.164 63.906 64.572 108.063 79.227 5.14.954 8.945.283 11.419-1.996 2.475-2.282 3.711-5.14 3.711-8.562 0-.571-.049-5.708-.144-15.417a2549.81 2549.81 0 01-.144-25.406l-6.567 1.136c-4.187.767-9.469 1.092-15.846 1-6.374-.089-12.991-.757-19.842-1.999-6.854-1.231-13.229-4.086-19.13-8.559-5.898-4.473-10.085-10.328-12.56-17.556l-2.855-6.57c-1.903-4.374-4.899-9.233-8.992-14.559-4.093-5.331-8.232-8.945-12.419-10.848l-1.999-1.431c-1.332-.951-2.568-2.098-3.711-3.429-1.142-1.331-1.997-2.663-2.568-3.997-.572-1.335-.098-2.43 1.427-3.289 1.525-.859 4.281-1.276 8.28-1.276l5.708.853c3.807.763 8.516 3.042 14.133 6.851 5.614 3.806 10.229 8.754 13.846 14.842 4.38 7.806 9.657 13.754 15.846 17.847 6.184 4.093 12.419 6.136 18.699 6.136 6.28 0 11.704-.476 16.274-1.423 4.565-.952 8.848-2.383 12.847-4.285 1.713-12.758 6.377-22.559 13.988-29.41-10.848-1.14-20.601-2.857-29.264-5.14-8.658-2.286-17.605-5.996-26.835-11.14-9.235-5.137-16.896-11.516-22.985-19.126-6.09-7.614-11.088-17.61-14.987-29.979-3.901-12.374-5.852-26.648-5.852-42.826 0-23.035 7.52-42.637 22.557-58.817-7.044-17.318-6.379-36.732 1.997-58.24 5.52-1.715 13.706-.428 24.554 3.853 10.85 4.283 18.794 7.952 23.84 10.994 5.046 3.041 9.089 5.618 12.135 7.708 17.705-4.947 35.976-7.421 54.818-7.421s37.117 2.474 54.823 7.421l10.849-6.849c7.419-4.57 16.18-8.758 26.262-12.565 10.088-3.805 17.802-4.853 23.134-3.138 8.562 21.509 9.325 40.922 2.279 58.24 15.036 16.18 22.559 35.787 22.559 58.817 0 16.178-1.958 30.497-5.853 42.966-3.9 12.471-8.941 22.457-15.125 29.979-6.191 7.521-13.901 13.85-23.131 18.986-9.232 5.14-18.182 8.85-26.84 11.136-8.662 2.286-18.415 4.004-29.263 5.146 9.894 8.562 14.842 22.077 14.842 40.539v60.237c0 3.422 1.19 6.279 3.572 8.562 2.379 2.279 6.136 2.95 11.276 1.995 44.163-14.653 80.185-41.062 108.068-79.226 27.88-38.161 41.825-81.126 41.825-128.906-.01-39.771-9.818-76.454-29.414-110.049z" /></svg>
            <span class="text-xs tabular-nums">1,037</span>
          </a>
          <a href="https://discord.com/invite/exbwVbjAct" target="_blank" aria-label="Discord" class="flex items-center justify-center w-8 h-8 rounded-lg text-gray-600 dark:text-zinc-300 hover:bg-gray-100 dark:hover:bg-zinc-900">
            <svg viewBox="0 0 24 24" class="w-4 h-4" fill="currentColor"><path d="M20.317 4.37a19.79 19.79 0 0 0-4.885-1.515a.074.074 0 0 0-.079.037c-.21.375-.444.865-.608 1.25a18.27 18.27 0 0 0-5.487 0a12.64 12.64 0 0 0-.617-1.25a.077.077 0 0 0-.079-.037A19.74 19.74 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057a19.9 19.9 0 0 0 5.993 3.03a.078.078 0 0 0 .084-.028a14.09 14.09 0 0 0 1.226-1.994a.076.076 0 0 0-.041-.106a13.107 13.107 0 0 1-1.872-.892a.077.077 0 0 1-.008-.128a10.2 10.2 0 0 0 .372-.292a.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127a12.299 12.299 0 0 1-1.873.892a.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028a19.839 19.839 0 0 0 6.002-3.03a.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419c0-1.333.956-2.419 2.157-2.419c1.21 0 2.176 1.096 2.157 2.42c0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419c0-1.333.955-2.419 2.157-2.419c1.21 0 2.176 1.096 2.157 2.42c0 1.333-.946 2.418-2.157 2.418z" /></svg>
          </a>
          <a href="https://x.com/PetalFramework" target="_blank" aria-label="X" class="flex items-center justify-center w-8 h-8 rounded-lg text-gray-600 dark:text-zinc-300 hover:bg-gray-100 dark:hover:bg-zinc-900">
            <svg viewBox="0 0 24 24" class="w-3.5 h-3.5" fill="currentColor"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" /></svg>
          </a>
          <button phx-click="toggle_dark" aria-label="Toggle dark mode" class="flex items-center justify-center w-8 h-8 rounded-lg text-gray-600 dark:text-zinc-300 hover:bg-gray-100 dark:hover:bg-zinc-900">
            <.icon name={if @dark, do: "hero-sun", else: "hero-moon"} class="w-4 h-4" />
          </button>
        </div>
      </header>

      <div class="flex flex-1 min-h-0">
        <nav class="flex-none w-56 p-3 overflow-y-auto border-r border-gray-200 dark:border-zinc-800">
          <div :for={grp <- @nav}>
            <div class="px-2 pt-4 pb-1 text-[11px] font-medium tracking-wide text-gray-400 dark:text-zinc-500">
              {grp.group}
            </div>
            <button
              :for={it <- grp.items}
              phx-click="select"
              phx-value-slug={it.slug}
              class={[
                "w-full flex items-center gap-2.5 px-2 py-1.5 rounded-lg text-sm text-left",
                (@active == it.slug && "bg-primary-600 text-white") ||
                  "text-gray-600 dark:text-zinc-400 hover:bg-gray-100 dark:hover:bg-zinc-900"
              ]}
            >
              <.icon name={it.icon} class="w-4 h-4 shrink-0" />
              {it.name}
              <span
                :if={not it.ready}
                class={[
                  "ml-auto text-[10px] px-1.5 py-0.5 rounded",
                  (@active == it.slug && "bg-white/20") || "bg-gray-100 dark:bg-zinc-800 text-gray-400"
                ]}
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
        Triggers an action. Reach for the core four; the full colour range is there when you need it.
      </p>

      <div class="mt-8 overflow-hidden border border-gray-200 rounded-xl dark:border-zinc-800">
        <div class="flex items-center justify-center px-6 py-16 bg-gray-50 dark:bg-zinc-900/40">
          <.button variant={@variant} color="primary" size={@size} label="Get started" />
        </div>
        <div class="flex flex-wrap gap-8 px-6 py-4 border-t border-gray-200 dark:border-zinc-800">
          <div>
            <div class="mb-2 text-[11px] font-medium tracking-wide text-gray-400">variant</div>
            <div class="inline-flex overflow-hidden border rounded-lg border-gray-200 dark:border-zinc-700">
              <button
                :for={v <- ~w(solid outline ghost)}
                phx-click="set"
                phx-value-k="variant"
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
                :for={s <- ~w(sm md lg)}
                phx-click="set"
                phx-value-k="size"
                phx-value-v={s}
                class={seg(@size == s)}
              >
                {s}
              </button>
            </div>
          </div>
        </div>
      </div>

      <button
        phx-click="toggle_code"
        class="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white"
      >
        <.icon name="hero-code-bracket" class="w-4 h-4" />
        {if @show_code, do: "Hide code", else: "View code"}
      </button>
      <pre
        :if={@show_code}
        class="p-4 mt-2 overflow-x-auto text-sm text-gray-100 bg-zinc-900 rounded-xl"
      ><code>{"<.button variant=\"#{@variant}\" size=\"#{@size}\">Get started</.button>"}</code></pre>

      <div class="mt-12 text-[11px] font-medium tracking-wide text-gray-400">the four you'll reach for</div>
      <div class="flex flex-wrap items-center justify-center gap-3 px-6 py-10 mt-2 border border-gray-200 rounded-xl bg-gray-50 dark:bg-zinc-900/40 dark:border-zinc-800">
        <.button label="Get started" />
        <.button variant="outline" label="Outline" />
        <.button variant="ghost" label="Ghost" />
        <.button color="danger" label="Delete" />
      </div>

      <div class="mt-8 text-[11px] font-medium tracking-wide text-gray-400">the full colour range, kept but demoted</div>
      <div class="flex flex-wrap gap-2 mt-3">
        <.button :for={c <- ~w(primary secondary info success warning danger gray dark)} variant="outline" size="xs" color={c} label={c} />
      </div>
    </div>
    """
  end

  defp render_page(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center h-full px-8 text-center">
      <.icon name="hero-cube-transparent" class="w-10 h-10 text-gray-300 dark:text-zinc-700" />
      <p class="mt-4 text-lg font-medium capitalize">{@active}</p>
      <p class="mt-1 text-sm text-gray-500 dark:text-zinc-400 max-w-sm">
        This page gets the same treatment next. We're locking the shell and the pattern on Button first.
      </p>
    </div>
    """
  end

  defp seg(true), do: "px-3 py-1.5 text-xs bg-primary-600 text-white"
  defp seg(false), do: "px-3 py-1.5 text-xs text-gray-500 dark:text-zinc-400 hover:bg-gray-100 dark:hover:bg-zinc-800"
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
  # OPEN_BROWSER=false for headless runs (CI, agents)
  open_browser: System.get_env("OPEN_BROWSER", "true") != "false",
  live_reload: true,
  endpoint_options: [
    debug_errors: true,
    render_errors: [formats: [html: Dev.ErrorHTML], layout: false],
    watchers: [
      tailwind: {Tailwind, :install_and_run, [:petal_dev, ~w(--watch)]}
    ]
  ]
)
