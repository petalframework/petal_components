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
      </head>
      <body class="bg-white antialiased">
        <script src="/assets/phoenix/phoenix.js">
        </script>
        <script src="/assets/phoenix_live_view/phoenix_live_view.js">
        </script>
        <script>
          window.hooks = {}
          window.uploaders = {}
          let liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket, {hooks, uploaders})
          liveSocket.connect()
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
  # JS alias available for component demos that need it
  # alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Petal Components Playground",
       count: 0,
       form: to_form(%{}, as: :user),
       active_tab: "buttons",
       group_size: "md"
     )}
  end

  @impl true
  def handle_event("inc", _, socket), do: {:noreply, update(socket, :count, &(&1 + 1))}
  def handle_event("dec", _, socket), do: {:noreply, update(socket, :count, &(&1 - 1))}

  def handle_event("change_size", %{"size" => size}, socket),
    do: {:noreply, assign(socket, :group_size, size)}

  def handle_event("switch_tab", %{"tab" => tab}, socket),
    do: {:noreply, assign(socket, :active_tab, tab)}

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <link rel="stylesheet" href="/assets/app.css" />
    <script defer src="https://cdn.jsdelivr.net/npm/@alpinejs/collapse@3.x.x/dist/cdn.min.js">
    </script>
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js">
    </script>

    <.container max_width="xl" class="py-10">
      <div class="mb-8">
        <.h1>Petal Components Playground</.h1>
        <.p class="text-gray-500">
          Edit components in <code class="text-sm bg-gray-100 px-1.5 py-0.5 rounded">lib/petal_components/</code>
          and see changes live.
        </.p>
      </div>

      <%!-- Navigation tabs --%>
      <div class="flex gap-1 mb-8 border-b border-gray-200">
        <button
          :for={
            {label, key} <- [
              {"Buttons", "buttons"},
              {"Forms", "forms"},
              {"Feedback", "feedback"},
              {"Data Display", "data"},
              {"Navigation", "navigation"},
              {"Layout", "layout"}
            ]
          }
          phx-click="switch_tab"
          phx-value-tab={key}
          class={[
            "px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors",
            if(@active_tab == key,
              do: "border-primary-500 text-primary-600",
              else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
            )
          ]}
        >
          {label}
        </button>
      </div>

      <%!-- Buttons --%>
      <div :if={@active_tab == "buttons"} class="space-y-8">
        <section>
          <.h2 class="mb-4">Buttons</.h2>
          <div class="flex flex-wrap gap-3">
            <.button color="primary" label="Primary" />
            <.button color="secondary" label="Secondary" />
            <.button color="info" label="Info" />
            <.button color="success" label="Success" />
            <.button color="warning" label="Warning" />
            <.button color="danger" label="Danger" />
          </div>
        </section>

        <section>
          <.h3 class="mb-4">Button Variants</.h3>
          <div class="flex flex-wrap gap-3">
            <.button variant="outline" label="Outline" />
            <.button variant="shadow" label="Shadow" />
            <.button variant="inverted" label="Inverted" />
          </div>
        </section>

        <section>
          <.h3 class="mb-4">Button Sizes</.h3>
          <div class="flex flex-wrap items-center gap-3">
            <.button size="xs" label="Extra Small" />
            <.button size="sm" label="Small" />
            <.button size="md" label="Medium" />
            <.button size="lg" label="Large" />
            <.button size="xl" label="Extra Large" />
          </div>
        </section>

        <section>
          <.h3 class="mb-4">Button with Icon</.h3>
          <div class="flex flex-wrap gap-3">
            <.button icon="hero-plus" label="Add Item" />
            <.button color="danger" icon="hero-trash" label="Delete" />
            <.button color="info" icon="hero-arrow-down-tray" label="Download" />
          </div>
        </section>

        <section>
          <.h3 class="mb-4">Button Group</.h3>
          <.button_group aria_label="Size options" size={@group_size}>
            <:button label="XS" phx-click="change_size" phx-value-size="xs" />
            <:button label="SM" phx-click="change_size" phx-value-size="sm" />
            <:button label="MD" phx-click="change_size" phx-value-size="md" />
            <:button label="LG" phx-click="change_size" phx-value-size="lg" />
            <:button label="XL" phx-click="change_size" phx-value-size="xl" />
          </.button_group>
          <.p class="mt-2 text-sm text-gray-500">Current size: {@group_size}</.p>
        </section>

        <section>
          <.h3 class="mb-4">Counter (LiveView Interaction)</.h3>
          <div class="flex items-center gap-4">
            <.button phx-click="dec" color="danger" size="sm" label="-" />
            <span class="text-2xl font-bold tabular-nums">{@count}</span>
            <.button phx-click="inc" color="success" size="sm" label="+" />
          </div>
        </section>
      </div>

      <%!-- Forms --%>
      <div :if={@active_tab == "forms"} class="space-y-8">
        <section>
          <.h2 class="mb-4">Form Fields</.h2>
          <.form for={@form} class="space-y-4 max-w-md">
            <.field field={@form[:name]} type="text" label="Name" placeholder="eg. Sally" />
            <.field field={@form[:email]} type="email" label="Email" placeholder="sally@example.com" />
            <.field field={@form[:password]} type="password" label="Password" />
            <.field field={@form[:bio]} type="textarea" label="Bio" placeholder="Tell us about yourself..." />
            <.field
              field={@form[:role]}
              type="select"
              label="Role"
              options={["Admin", "Editor", "Viewer"]}
            />
            <.field field={@form[:remember]} type="checkbox" label="Remember me" />
            <.field
              field={@form[:plan]}
              type="radio-group"
              label="Plan"
              options={[{"Free", "free"}, {"Pro", "pro"}, {"Enterprise", "enterprise"}]}
            />
            <.field field={@form[:start_date]} type="date" label="Start Date" />
            <.field field={@form[:color]} type="color" label="Favorite Color" />
            <.field field={@form[:volume]} type="range" label="Volume" />
            <.button type="submit" label="Submit" />
          </.form>
        </section>
      </div>

      <%!-- Feedback --%>
      <div :if={@active_tab == "feedback"} class="space-y-8">
        <section>
          <.h2 class="mb-4">Alerts</.h2>
          <div class="space-y-3">
            <.alert with_icon color="info" label="This is an info alert." heading="Info" />
            <.alert with_icon color="success" label="Operation completed successfully." heading="Success" />
            <.alert with_icon color="warning" label="Please review before continuing." heading="Warning" />
            <.alert with_icon color="danger" label="Something went wrong." heading="Error" />
          </div>
        </section>

        <section>
          <.h2 class="mb-4">Badges</.h2>
          <div class="flex flex-wrap gap-2">
            <.badge color="primary" label="Primary" />
            <.badge color="secondary" label="Secondary" />
            <.badge color="info" label="Info" />
            <.badge color="success" label="Success" />
            <.badge color="warning" label="Warning" />
            <.badge color="danger" label="Danger" />
            <.badge color="gray" label="Gray" />
          </div>
        </section>

        <section>
          <.h2 class="mb-4">Progress</.h2>
          <div class="space-y-4 max-w-md">
            <.progress size="sm" value={25} max={100} label="25%" />
            <.progress size="md" value={50} max={100} label="50%" />
            <.progress size="lg" value={75} max={100} label="75%" color="success" />
            <.progress size="xl" value={100} max={100} label="100%" color="info" />
          </div>
        </section>

        <section>
          <.h2 class="mb-4">Rating</.h2>
          <.rating include_label rating={3.5} total={5} />
        </section>

        <section>
          <.h2 class="mb-4">Loading</.h2>
          <div class="flex gap-4">
            <.spinner show={true} />
            <.spinner show={true} size="md" />
            <.spinner show={true} size="lg" />
          </div>
        </section>

        <section>
          <.h2 class="mb-4">Skeleton</.h2>
          <.skeleton />
        </section>

        <section>
          <.h2 class="mb-4">Modal</.h2>
          <.button phx-click={PetalComponents.Modal.show_modal("modal")} label="Open Modal" />
          <.modal max_width="sm" title="Example Modal" hide>
            <.p>This is a modal dialog. Click outside or press Escape to close.</.p>
            <div class="flex justify-end mt-4">
              <.button label="Close" phx-click={PetalComponents.Modal.hide_modal()} />
            </div>
          </.modal>
        </section>

        <section>
          <.h2 class="mb-4">Slide Over</.h2>
          <.button phx-click={PetalComponents.SlideOver.show_slide_over("right", "slide-over")} label="Open Slide Over" />
          <.slide_over title="Example Slide Over" origin="right" hide>
            <.p>Content goes here.</.p>
            <div class="flex justify-end mt-4">
              <.button
                label="Close"
                phx-click={PetalComponents.SlideOver.hide_slide_over("right")}
              />
            </div>
          </.slide_over>
        </section>
      </div>

      <%!-- Data Display --%>
      <div :if={@active_tab == "data"} class="space-y-8">
        <section>
          <.h2 class="mb-4">Table</.h2>
          <.table
            id="example-table"
            rows={[
              %{id: 1, name: "Phoenix", language: "Elixir", stars: "21k"},
              %{id: 2, name: "Rails", language: "Ruby", stars: "56k"},
              %{id: 3, name: "Next.js", language: "JavaScript", stars: "128k"}
            ]}
          >
            <:col :let={row} label="Name">{row.name}</:col>
            <:col :let={row} label="Language">{row.language}</:col>
            <:col :let={row} label="Stars">{row.stars}</:col>
          </.table>
        </section>

        <section>
          <.h2 class="mb-4">Card</.h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 max-w-2xl">
            <.card>
              <.card_content category="Guide" heading="Getting Started">
                <.p class="mt-2 text-sm text-gray-500">
                  Learn how to install and configure Petal Components in your Phoenix project.
                </.p>
              </.card_content>
            </.card>
            <.card>
              <.card_content category="Reference" heading="Component API">
                <.p class="mt-2 text-sm text-gray-500">
                  Browse the full list of available components and their props.
                </.p>
              </.card_content>
            </.card>
          </div>
        </section>

        <section>
          <.h2 class="mb-4">Avatar</.h2>
          <div class="flex gap-3 items-center">
            <.avatar size="sm" src="https://avatars.githubusercontent.com/u/82628117?v=4" />
            <.avatar size="md" src="https://avatars.githubusercontent.com/u/82628117?v=4" />
            <.avatar size="lg" src="https://avatars.githubusercontent.com/u/82628117?v=4" />
          </div>
        </section>

        <section>
          <.h2 class="mb-4">Accordion</.h2>
          <.accordion>
            <:item heading="What is Petal Components?">
              A set of HEEX components for Phoenix developers — like Shadcn, but for LiveView.
            </:item>
            <:item heading="How do I install it?">
              Add <code>petal_components</code> to your mix.exs dependencies and follow the setup guide.
            </:item>
            <:item heading="Is it free?">
              Yes! Petal Components is open source and MIT licensed.
            </:item>
          </.accordion>
        </section>
      </div>

      <%!-- Navigation --%>
      <div :if={@active_tab == "navigation"} class="space-y-8">
        <section>
          <.h2 class="mb-4">Breadcrumbs</.h2>
          <.breadcrumbs links={[
            %{label: "Home", to: "/", icon: "hero-home"},
            %{label: "Components", to: "/"},
            %{label: "Breadcrumbs", to: "/"}
          ]} />
        </section>

        <section>
          <.h2 class="mb-4">Pagination</.h2>
          <.pagination link_type="live_patch" path="/" current_page={3} total_pages={10} />
        </section>

        <section>
          <.h2 class="mb-4">Stepper</.h2>
          <.stepper
            steps={[
              %{name: "Account", description: "Create account", complete?: true, active?: false},
              %{name: "Profile", description: "Set up profile", complete?: true, active?: true},
              %{name: "Review", description: "Review & confirm", complete?: false, active?: false}
            ]}
            orientation="horizontal"
            size="md"
          />
        </section>

        <section>
          <.h2 class="mb-4">Dropdown</.h2>
          <.dropdown label="Options">
            <.dropdown_menu_item type="button">
              <.icon name="hero-pencil-mini" class="w-4 h-4" /> Edit
            </.dropdown_menu_item>
            <.dropdown_menu_item type="button">
              <.icon name="hero-document-duplicate-mini" class="w-4 h-4" /> Duplicate
            </.dropdown_menu_item>
            <.dropdown_menu_item type="button">
              <.icon name="hero-trash-mini" class="w-4 h-4" /> Delete
            </.dropdown_menu_item>
          </.dropdown>
        </section>

        <section>
          <.h2 class="mb-4">Vertical Menu</.h2>
          <div class="max-w-xs">
            <.vertical_menu
              title="Settings"
              current_page={:general}
              menu_items={[
                %{name: :general, label: "General", path: "/", icon: "hero-cog-6-tooth"},
                %{name: :profile, label: "Profile", path: "/", icon: "hero-user"},
                %{name: :billing, label: "Billing", path: "/", icon: "hero-credit-card"}
              ]}
            />
          </div>
        </section>
      </div>

      <%!-- Layout --%>
      <div :if={@active_tab == "layout"} class="space-y-8">
        <section>
          <.h2 class="mb-4">Typography</.h2>
          <div class="space-y-2">
            <.h1>Heading 1</.h1>
            <.h2>Heading 2</.h2>
            <.h3>Heading 3</.h3>
            <.h4>Heading 4</.h4>
            <.h5>Heading 5</.h5>
            <.p>A paragraph of text. Lorem ipsum dolor sit amet, consectetur adipiscing elit.</.p>
          </div>
        </section>

        <section>
          <.h2 class="mb-4">Lists</.h2>
          <div class="flex gap-8">
            <div>
              <.h4 class="mb-2">Unordered</.h4>
              <.ul>
                <li>First item</li>
                <li>Second item</li>
                <li>Third item</li>
              </.ul>
            </div>
            <div>
              <.h4 class="mb-2">Ordered</.h4>
              <.ol>
                <li>First step</li>
                <li>Second step</li>
                <li>Third step</li>
              </.ol>
            </div>
          </div>
        </section>

        <section>
          <.h2 class="mb-4">Prose</.h2>
          <.prose>
            <h3>Rich Content Block</h3>
            <p>
              The <code>.prose</code> component applies beautiful typographic defaults.
              It handles paragraphs, lists, code blocks, and more.
            </p>
            <ul>
              <li>Automatic spacing</li>
              <li>Readable line lengths</li>
              <li>Styled inline elements</li>
            </ul>
          </.prose>
        </section>

        <section>
          <.h2 class="mb-4">Container</.h2>
          <div class="space-y-3">
            <.container max_width="sm" class="bg-gray-100 p-4 rounded">
              <.p class="text-sm text-gray-600">max_width="sm"</.p>
            </.container>
            <.container max_width="md" class="bg-gray-100 p-4 rounded">
              <.p class="text-sm text-gray-600">max_width="md"</.p>
            </.container>
            <.container max_width="lg" class="bg-gray-100 p-4 rounded">
              <.p class="text-sm text-gray-600">max_width="lg"</.p>
            </.container>
          </div>
        </section>

        <section>
          <.h2 class="mb-4">Marquee</.h2>
          <.marquee pause_on_hover>
            <div class="flex items-center gap-2 px-4 py-2 rounded-lg border border-gray-200 bg-white">
              <.icon name="hero-star-solid" class="w-4 h-4 text-yellow-400" />
              <span>Petal Components</span>
            </div>
            <div class="flex items-center gap-2 px-4 py-2 rounded-lg border border-gray-200 bg-white">
              <.icon name="hero-bolt-solid" class="w-4 h-4 text-blue-400" />
              <span>Phoenix LiveView</span>
            </div>
            <div class="flex items-center gap-2 px-4 py-2 rounded-lg border border-gray-200 bg-white">
              <.icon name="hero-fire-solid" class="w-4 h-4 text-orange-400" />
              <span>Tailwind CSS</span>
            </div>
            <div class="flex items-center gap-2 px-4 py-2 rounded-lg border border-gray-200 bg-white">
              <.icon name="hero-heart-solid" class="w-4 h-4 text-red-400" />
              <span>Open Source</span>
            </div>
          </.marquee>
        </section>
      </div>
    </.container>
    """
  end
end

# -- Router -------------------------------------------------------------------

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

# -- Custom endpoint with Plug.Static for compiled CSS ------------------------

defmodule Dev.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix_playground

  plug Plug.Logger

  socket "/live", Phoenix.LiveView.Socket

  # Phoenix and LiveView JS assets
  plug Plug.Static, from: {:phoenix, "priv/static"}, at: "/assets/phoenix"
  plug Plug.Static, from: {:phoenix_live_view, "priv/static"}, at: "/assets/phoenix_live_view"

  # Compiled Tailwind CSS
  plug Plug.Static,
    from: Path.expand("priv/static", __DIR__),
    at: "/"

  socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
  plug Phoenix.LiveReloader
  plug Phoenix.CodeReloader, reloader: &PhoenixPlayground.CodeReloader.reload/2

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
Application.put_env(:phoenix_playground, Dev.Endpoint,
  secret_key_base: String.duplicate("a", 64)
)

# Run initial Tailwind build before starting the server
Mix.Task.run("tailwind", ["petal_dev"])

PhoenixPlayground.start(
  endpoint: Dev.Endpoint,
  open_browser: true,
  live_reload: true,
  endpoint_options: [
    debug_errors: true,
    render_errors: [formats: [html: Dev.ErrorHTML], layout: false],
    watchers: [
      tailwind: {Tailwind, :install_and_run, [:petal_dev, ~w(--watch)]}
    ]
  ]
)
