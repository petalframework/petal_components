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
  alias PetalComponents.Chat
  alias Phoenix.LiveView.JS

  @avatar_src "https://avatars.githubusercontent.com/u/82628117?v=4"

  @impl true
  def mount(_params, _session, socket) do
    changeset = build_changeset()

    {:ok,
     assign(socket,
       page_title: "Petal Components Playground",
       count: 0,
       stars: 5200,
       form: to_form(changeset, as: :user),
       active_tab: "buttons",
       group_size: "md",
       avatar_src: @avatar_src,
       user_menu_items: [
         %{path: "/", icon: "hero-user", label: "My Profile"},
         %{path: "/", icon: "hero-cog-6-tooth", label: "Settings"},
         %{path: "/", icon: "hero-arrow-right-on-rectangle", label: "Sign out", method: :delete}
       ]
     )}
  end

  @known_tabs ~w(buttons typography forms feedback data navigation layout effects chat)

  @impl true
  def handle_params(%{"tab" => tab}, _uri, socket) when tab in @known_tabs,
    do: {:noreply, assign(socket, :active_tab, tab)}

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_event("inc", _, socket), do: {:noreply, update(socket, :count, &(&1 + 1))}
  def handle_event("dec", _, socket), do: {:noreply, update(socket, :count, &(&1 - 1))}

  def handle_event("change_size", %{"size" => size}, socket),
    do: {:noreply, assign(socket, :group_size, size)}

  def handle_event("switch_tab", %{"tab" => tab}, socket),
    do: {:noreply, assign(socket, :active_tab, tab)}

  def handle_event("randomize_stars", _, socket),
    do: {:noreply, assign(socket, :stars, Enum.random(3_000..9_999))}

  def handle_event("celebrate", _, socket),
    do: {:noreply, push_event(socket, "pc-confetti", %{})}

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      user_params
      |> build_changeset()
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: :user))}
  end

  def handle_event("submit", %{"user" => user_params}, socket) do
    changeset = build_changeset(user_params)

    case Ecto.Changeset.apply_action(changeset, :validate) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:success, "Form submitted successfully!")
          |> assign(form: to_form(changeset, as: :user))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :user))}
    end
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  defp build_changeset(params \\ %{}) do
    data = %{}

    types = %{
      name: :string,
      email: :string,
      number: :integer,
      password: :string,
      search: :string,
      tel: :string,
      url: :string,
      time: :time,
      date: :date,
      week: :string,
      month: :string,
      datetime: :naive_datetime,
      color: :string,
      file: :string,
      range: :integer,
      price_min: :integer,
      price_max: :integer,
      textarea: :string,
      select: :string,
      switch: :boolean,
      checkbox: :boolean,
      checkbox_group: {:array, :string},
      radio_group: :string,
      radio_card: :string
    }

    {data, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required([:name, :email])
    |> Ecto.Changeset.validate_length(:name, min: 2, max: 50)
    |> Ecto.Changeset.validate_format(:email, ~r/@/)
  end

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
          Edit components in
          <code class="text-sm bg-gray-100 px-1.5 py-0.5 rounded">lib/petal_components/</code>
          and see changes live.
        </.p>
      </div>

      <%!-- Navigation tabs --%>
      <div class="flex gap-1 mb-8 border-b border-gray-200">
        <button
          :for={
            {label, key} <- [
              {"Buttons", "buttons"},
              {"Typography", "typography"},
              {"Forms", "forms"},
              {"Feedback", "feedback"},
              {"Data Display", "data"},
              {"Navigation", "navigation"},
              {"Layout", "layout"},
              {"Effects", "effects"},
              {"Chat", "chat"}
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

      <%!-- ============================================================ --%>
      <%!-- BUTTONS TAB                                                  --%>
      <%!-- ============================================================ --%>
      <div :if={@active_tab == "buttons"} class="space-y-10">
        <%!-- All Colors --%>
        <section>
          <.h2 class="mb-4">All Colors</.h2>
          <div class="flex flex-wrap gap-3">
            <.button color="primary" label="Primary" />
            <.button color="secondary" label="Secondary" />
            <.button color="white" label="White" />
            <.button color="pure_white" label="Pure White" />
            <.button color="info" label="Info" />
            <.button color="success" label="Success" />
            <.button color="warning" label="Warning" />
            <.button color="danger" label="Danger" />
            <.button color="gray" label="Gray" />
            <.button color="light" label="Light" />
            <.button color="dark" label="Dark" />
          </div>
        </section>

        <%!-- Sizes --%>
        <section>
          <.h3 class="mb-4">Sizes</.h3>
          <div class="flex flex-wrap items-center gap-3">
            <.button size="xs" label="Extra Small" />
            <.button size="sm" label="Small" />
            <.button size="md" label="Medium" />
            <.button size="lg" label="Large" />
            <.button size="xl" label="Extra Large" />
          </div>
        </section>

        <%!-- Variant: Light --%>
        <section>
          <.h3 class="mb-4">Variant: Light</.h3>
          <div class="flex flex-wrap gap-3">
            <.button variant="light" color="primary" label="Primary" />
            <.button variant="light" color="secondary" label="Secondary" />
            <.button variant="light" color="info" label="Info" />
            <.button variant="light" color="success" label="Success" />
            <.button variant="light" color="warning" label="Warning" />
            <.button variant="light" color="danger" label="Danger" />
          </div>
        </section>

        <%!-- Variant: Outline --%>
        <section>
          <.h3 class="mb-4">Variant: Outline</.h3>
          <div class="flex flex-wrap gap-3">
            <.button variant="outline" color="primary" label="Primary" />
            <.button variant="outline" color="secondary" label="Secondary" />
            <.button variant="outline" color="info" label="Info" />
            <.button variant="outline" color="success" label="Success" />
            <.button variant="outline" color="warning" label="Warning" />
            <.button variant="outline" color="danger" label="Danger" />
          </div>
        </section>

        <%!-- Variant: Inverted --%>
        <section>
          <.h3 class="mb-4">Variant: Inverted</.h3>
          <div class="flex flex-wrap gap-3">
            <.button variant="inverted" color="primary" label="Primary" />
            <.button variant="inverted" color="secondary" label="Secondary" />
            <.button variant="inverted" color="info" label="Info" />
            <.button variant="inverted" color="success" label="Success" />
            <.button variant="inverted" color="warning" label="Warning" />
            <.button variant="inverted" color="danger" label="Danger" />
          </div>
        </section>

        <%!-- Variant: Ghost --%>
        <section>
          <.h3 class="mb-4">Variant: Ghost</.h3>
          <div class="flex flex-wrap gap-3">
            <.button variant="ghost" color="primary" label="Primary" />
            <.button variant="ghost" color="secondary" label="Secondary" />
            <.button variant="ghost" color="info" label="Info" />
            <.button variant="ghost" color="success" label="Success" />
            <.button variant="ghost" color="danger" label="Danger" />
          </div>
        </section>

        <%!-- Variant: Shadow --%>
        <section>
          <.h3 class="mb-4">Variant: Shadow</.h3>
          <div class="flex flex-wrap gap-3">
            <.button variant="shadow" color="primary" label="Primary" />
            <.button variant="shadow" color="secondary" label="Secondary" />
            <.button variant="shadow" color="info" label="Info" />
            <.button variant="shadow" color="success" label="Success" />
            <.button variant="shadow" color="danger" label="Danger" />
          </div>
        </section>

        <%!-- Radius Options --%>
        <section>
          <.h3 class="mb-4">Radius Options</.h3>
          <div class="flex flex-wrap items-center gap-3">
            <.button radius="none" label="none" />
            <.button radius="sm" label="sm" />
            <.button radius="md" label="md" />
            <.button radius="lg" label="lg" />
            <.button radius="xl" label="xl" />
            <.button radius="full" label="full" />
          </div>
        </section>

        <%!-- Disabled & Loading --%>
        <section>
          <.h3 class="mb-4">Disabled & Loading States</.h3>
          <div class="flex flex-wrap items-center gap-3">
            <.button disabled label="Disabled" />
            <.button disabled color="danger" label="Disabled Danger" />
            <.button loading label="Loading" />
            <.button loading color="success" label="Loading Success" />
          </div>
        </section>

        <%!-- Button with Icon --%>
        <section>
          <.h3 class="mb-4">Button with Icon</.h3>
          <div class="flex flex-wrap gap-3">
            <.button icon="hero-plus" label="Add Item" />
            <.button color="danger" icon="hero-trash" label="Delete" />
            <.button color="info" icon="hero-arrow-down-tray" label="Download" />
          </div>
        </section>

        <%!-- Icon Buttons --%>
        <section>
          <.h3 class="mb-4">Icon Buttons</.h3>
          <div class="flex flex-wrap items-center gap-3">
            <.icon_button size="xs" tooltip="Extra small">
              <.icon name="hero-heart" class="w-3 h-3" />
            </.icon_button>
            <.icon_button size="sm" tooltip="Small">
              <.icon name="hero-heart" class="w-4 h-4" />
            </.icon_button>
            <.icon_button size="md" color="primary" tooltip="Medium primary">
              <.icon name="hero-heart" class="w-5 h-5" />
            </.icon_button>
            <.icon_button size="lg" color="danger" tooltip="Large danger">
              <.icon name="hero-trash" class="w-5 h-5" />
            </.icon_button>
            <.icon_button size="xl" color="success" tooltip="Extra large success">
              <.icon name="hero-check" class="w-6 h-6" />
            </.icon_button>
          </div>
        </section>

        <%!-- Button as Link --%>
        <section>
          <.h3 class="mb-4">Button as Link</.h3>
          <div class="flex flex-wrap gap-3">
            <.button link_type="a" to="/" label="link_type=a" />
            <.button link_type="a" to="/" color="secondary" label="Secondary Link" />
          </div>
        </section>

        <%!-- Button Group --%>
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

        <%!-- Counter --%>
        <section>
          <.h3 class="mb-4">Counter (LiveView Interaction)</.h3>
          <div class="flex items-center gap-4">
            <.button phx-click="dec" color="danger" size="sm" label="-" />
            <span class="text-2xl font-bold tabular-nums">{@count}</span>
            <.button phx-click="inc" color="success" size="sm" label="+" />
          </div>
        </section>
      </div>

      <%!-- ============================================================ --%>
      <%!-- FORMS TAB                                                    --%>
      <%!-- ============================================================ --%>
      <div :if={@active_tab == "forms"} class="space-y-10">
        <%!-- Form with Changeset Validation --%>
        <section>
          <.h2 class="mb-4">Form with Validation</.h2>
          <.form for={@form} phx-submit="submit" phx-change="validate" class="space-y-4 max-w-lg">
            <.field
              field={@form[:name]}
              type="text"
              label="Name"
              placeholder="eg. Sally"
              help_text="Must be between 2 and 50 characters"
              phx-debounce="blur"
              required
            />
            <.field
              field={@form[:email]}
              type="email"
              label="Email"
              placeholder="sally@example.com"
              help_text="Must contain an @ symbol"
              phx-debounce="blur"
              required
            />
            <.field
              field={@form[:number]}
              type="number"
              label="Number"
              placeholder="42"
            />
            <.field
              field={@form[:password]}
              type="password"
              label="Password"
              placeholder="Enter password"
            />
            <.field
              field={@form[:search]}
              type="search"
              label="Search"
              placeholder="Search..."
              clearable
            />
            <.field
              field={@form[:tel]}
              type="tel"
              label="Phone"
              placeholder="+1 555 000 0000"
              clearable
            />
            <.field
              field={@form[:url]}
              type="url"
              label="URL"
              placeholder="https://example.com"
            />
            <.field
              field={@form[:time]}
              type="time"
              label="Time"
            />
            <.field
              field={@form[:date]}
              type="date"
              label="Date"
            />
            <.field
              field={@form[:week]}
              type="week"
              label="Week"
            />
            <.field
              field={@form[:month]}
              type="month"
              label="Month"
            />
            <.field
              field={@form[:datetime]}
              type="datetime-local"
              label="Date & Time"
            />
            <.field
              field={@form[:color]}
              type="color"
              label="Favorite Color"
            />
            <.field
              field={@form[:file]}
              type="file"
              label="File Upload"
            />
            <.field
              field={@form[:range]}
              type="range"
              label="Volume"
            />
            <.field
              field={@form[:textarea]}
              type="textarea"
              label="Bio"
              placeholder="Tell us about yourself..."
              rows="3"
              help_text="Optional but appreciated"
            />

            <%!-- Select --%>
            <.field
              field={@form[:select]}
              type="select"
              label="Role"
              options={["Admin", "Editor", "Viewer"]}
            />

            <%!-- Switch --%>
            <.field field={@form[:switch]} type="switch" label="Enable notifications" />

            <%!-- Checkbox --%>
            <.field field={@form[:checkbox]} type="checkbox" label="I agree to the terms" />

            <%!-- Checkbox Group (Column) --%>
            <.field
              field={@form[:checkbox_group]}
              type="checkbox-group"
              label="Interests (column layout)"
              group_layout="col"
              options={[{"Elixir", "elixir"}, {"Phoenix", "phoenix"}, {"LiveView", "liveview"}]}
            />

            <%!-- Checkbox Group (Row) --%>
            <.field
              field={@form[:checkbox_group]}
              type="checkbox-group"
              label="Interests (row layout)"
              group_layout="row"
              options={[{"Elixir", "elixir"}, {"Phoenix", "phoenix"}, {"LiveView", "liveview"}]}
            />

            <%!-- Radio Group (Column) --%>
            <.field
              field={@form[:radio_group]}
              type="radio-group"
              label="Plan (column layout)"
              group_layout="col"
              options={[{"Free", "free"}, {"Pro", "pro"}, {"Enterprise", "enterprise"}]}
            />

            <%!-- Radio Group (Row) --%>
            <.field
              field={@form[:radio_group]}
              type="radio-group"
              label="Plan (row layout)"
              group_layout="row"
              options={[{"Free", "free"}, {"Pro", "pro"}, {"Enterprise", "enterprise"}]}
            />

            <%!-- Radio Card --%>
            <.field
              field={@form[:radio_card]}
              type="radio-card"
              label="Server Size"
              options={[
                %{label: "8-core CPU", value: "high", description: "32 GB RAM"},
                %{label: "6-core CPU", value: "mid", description: "24 GB RAM"},
                %{label: "4-core CPU", value: "low", description: "16 GB RAM", disabled: true}
              ]}
              size="md"
              variant="outline"
              group_layout="row"
              help_text="Choose your server configuration"
              required
            />

            <%!-- Dual Range Slider --%>
            <div>
              <p class="mb-1 text-sm font-medium text-gray-700 dark:text-gray-300">Price Range</p>
              <.input
                type="range-dual"
                id="price-range"
                min_field={@form[:price_min]}
                max_field={@form[:price_max]}
                range_min={0}
                range_max={1000}
                value_prefix="$"
                step={10}
              />
            </div>

            <%!-- Dual Range Slider — percentage --%>
            <div>
              <p class="mb-1 text-sm font-medium text-gray-700 dark:text-gray-300">Match Score</p>
              <.input
                type="range-dual"
                id="score-range"
                min_field={@form[:price_min]}
                max_field={@form[:price_max]}
                range_min={0}
                range_max={100}
                value_suffix="%"
              />
            </div>

            <%!-- Dual Range Slider — disabled --%>
            <div>
              <p class="mb-1 text-sm font-medium text-gray-700 dark:text-gray-300">Disabled slider</p>
              <.input
                type="range-dual"
                id="disabled-range"
                min_field={@form[:price_min]}
                max_field={@form[:price_max]}
                range_min={0}
                range_max={500}
                value_prefix="$"
                disabled
              />
            </div>

            <div class="flex justify-end">
              <.button type="submit" label="Submit" />
            </div>
          </.form>
        </section>
      </div>

      <%!-- ============================================================ --%>
      <%!-- FEEDBACK TAB                                                 --%>
      <%!-- ============================================================ --%>
      <div :if={@active_tab == "feedback"} class="space-y-8">
        <section>
          <.h2 class="mb-4">Alerts</.h2>
          <div class="space-y-3">
            <.alert with_icon color="info" label="This is an info alert." heading="Info" />
            <.alert
              with_icon
              color="success"
              label="Operation completed successfully."
              heading="Success"
            />
            <.alert
              with_icon
              color="warning"
              label="Please review before continuing."
              heading="Warning"
            />
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
          <.button
            phx-click={PetalComponents.SlideOver.show_slide_over("right", "slide-over")}
            label="Open Slide Over"
          />
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

      <%!-- ============================================================ --%>
      <%!-- DATA DISPLAY TAB                                             --%>
      <%!-- ============================================================ --%>
      <div :if={@active_tab == "data"} class="space-y-8">
        <%!-- Table --%>
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

        <%!-- Card with Media and Footer --%>
        <section>
          <.h2 class="mb-4">Card</.h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 max-w-2xl">
            <.card>
              <.card_media src="https://images.unsplash.com/photo-1497032628192-86f99bcd76bc?w=600&h=400&fit=crop" />
              <.card_content category="Guide" heading="Getting Started">
                <.p class="mt-2 text-sm text-gray-500">
                  Learn how to install and configure Petal Components in your Phoenix project.
                </.p>
              </.card_content>
              <.card_footer>
                <div class="flex justify-between items-center w-full">
                  <span class="text-sm text-gray-500">5 min read</span>
                  <.button size="xs" variant="ghost" label="Read more" />
                </div>
              </.card_footer>
            </.card>
            <.card>
              <.card_media src="https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=600&h=400&fit=crop" />
              <.card_content category="Reference" heading="Component API">
                <.p class="mt-2 text-sm text-gray-500">
                  Browse the full list of available components and their props.
                </.p>
              </.card_content>
              <.card_footer>
                <div class="flex justify-between items-center w-full">
                  <span class="text-sm text-gray-500">10 min read</span>
                  <.button size="xs" variant="ghost" label="Read more" />
                </div>
              </.card_footer>
            </.card>
          </div>
        </section>

        <%!-- Avatar with Image --%>
        <section>
          <.h2 class="mb-4">Avatar (with image)</.h2>
          <div class="flex gap-3 items-center">
            <.avatar size="xs" src={@avatar_src} />
            <.avatar size="sm" src={@avatar_src} />
            <.avatar size="md" src={@avatar_src} />
            <.avatar size="lg" src={@avatar_src} />
            <.avatar size="xl" src={@avatar_src} />
          </div>
        </section>

        <%!-- Avatar with Initials --%>
        <section>
          <.h2 class="mb-4">Avatar (with initials)</.h2>
          <div class="flex gap-3 items-center">
            <.avatar size="sm" name="John Doe" random_color />
            <.avatar size="md" name="Jane Smith" random_color />
            <.avatar size="lg" name="Bob Wilson" random_color />
            <.avatar size="xl" name="Alice Brown" random_color />
          </div>
        </section>

        <%!-- Avatar Group --%>
        <section>
          <.h2 class="mb-4">Avatar Group</.h2>
          <.avatar_group
            size="md"
            avatars={[
              @avatar_src,
              "https://i.pravatar.cc/150?img=32",
              "https://i.pravatar.cc/150?img=12",
              "https://i.pravatar.cc/150?img=5",
              "https://i.pravatar.cc/150?img=8"
            ]}
          />
        </section>

        <%!-- Skeleton Variants --%>
        <section>
          <.h2 class="mb-4">Skeleton Variants</.h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <.h4 class="mb-2">Image</.h4>
              <.skeleton kind={:image} />
            </div>
            <div>
              <.h4 class="mb-2">Video</.h4>
              <.skeleton kind={:video} />
            </div>
            <div>
              <.h4 class="mb-2">Text</.h4>
              <.skeleton kind={:text} />
            </div>
            <div>
              <.h4 class="mb-2">Card</.h4>
              <.skeleton kind={:card} />
            </div>
            <div>
              <.h4 class="mb-2">Widget</.h4>
              <.skeleton kind={:widget} />
            </div>
            <div>
              <.h4 class="mb-2">List</.h4>
              <.skeleton kind={:list} />
            </div>
            <div>
              <.h4 class="mb-2">Testimonial</.h4>
              <.skeleton kind={:testimonial} />
            </div>
          </div>
        </section>

        <%!-- Accordion --%>
        <section>
          <.h2 class="mb-4">Accordion</.h2>
          <.accordion>
            <:item heading="What is Petal Components?">
              A set of HEEX components for Phoenix developers -- like Shadcn, but for LiveView.
            </:item>
            <:item heading="How do I install it?">
              Add <code>petal_components</code>
              to your mix.exs dependencies and follow the setup guide.
            </:item>
            <:item heading="Is it free?">
              Yes! Petal Components is open source and MIT licensed.
            </:item>
          </.accordion>
        </section>
      </div>

      <%!-- ============================================================ --%>
      <%!-- NAVIGATION TAB                                               --%>
      <%!-- ============================================================ --%>
      <div :if={@active_tab == "navigation"} class="space-y-8">
        <%!-- Navigation Menu (flyout) --%>
        <section>
          <.h2 class="mb-4">Navigation Menu (flyout)</.h2>
          <.p class="mb-4 text-sm text-gray-500">
            Click a trigger to open its panel. Escape or clicking away closes it.
          </.p>
          <%!-- Triggers pushed to the right edge to stress-test screen-boundary handling. --%>
          <div class="rounded-xl border border-gray-200 bg-white px-4 py-2 dark:border-gray-700 dark:bg-gray-900">
            <div class="flex items-center justify-between gap-4">
              <span class="text-lg font-bold text-gray-900 dark:text-white">Acme</span>
              <.navigation_menu id="demo-nav">
                <:item label="Pricing" to="#" />
                <:item label="Products" width="md">
                  <.navigation_menu_link
                    to="#"
                    icon="hero-chart-bar"
                    title="Analytics"
                    description="Get a better understanding of your traffic"
                  />
                  <.navigation_menu_link
                    to="#"
                    icon="hero-cursor-arrow-rays"
                    title="Engagement"
                    description="Speak directly to your customers"
                  />
                  <.navigation_menu_link
                    to="#"
                    icon="hero-shield-check"
                    title="Security"
                    description="Your customers' data is safe and secure"
                  />
                  <.navigation_menu_footer>
                    <.navigation_menu_footer_link to="#" icon="hero-play-circle" label="Watch demo" />
                    <.navigation_menu_footer_link to="#" icon="hero-phone" label="Contact sales" />
                  </.navigation_menu_footer>
                </:item>
                <:item label="Solutions" width="lg" align="end">
                  <div class="grid grid-cols-2 gap-1">
                    <.navigation_menu_link
                      to="#"
                      icon="hero-building-storefront"
                      title="E-commerce"
                      description="Sell products online"
                    />
                    <.navigation_menu_link
                      to="#"
                      icon="hero-users"
                      title="SaaS"
                      description="Multi-tenant apps"
                    />
                    <.navigation_menu_link
                      to="#"
                      icon="hero-newspaper"
                      title="Content"
                      description="Blogs and publications"
                    />
                    <.navigation_menu_link
                      to="#"
                      icon="hero-chart-pie"
                      title="Dashboards"
                      description="Internal tools and admin"
                    />
                  </div>
                </:item>
                <:item label="Resources" width="lg" align="end">
                  <.navigation_menu_link
                    to="#"
                    icon="hero-book-open"
                    title="Docs"
                    description="Guides and API reference"
                  />
                  <.navigation_menu_link
                    to="#"
                    icon="hero-academic-cap"
                    title="Tutorials"
                    description="Learn by building"
                  />
                </:item>
                <:item label="Docs" to="#" current />
              </.navigation_menu>
            </div>
          </div>
          <.p class="mt-3 text-xs text-gray-400">
            Panels anchor to the trigger's left edge by default (opening rightward). Triggers near
            the right edge set <code>align="end"</code> (as on "Solutions" and "Resources") so the
            panel opens leftward and stays on screen. Every panel is width-clamped to the viewport,
            and on mobile becomes a full-width sheet.
          </.p>
        </section>

        <%!-- Tabs Component --%>
        <section>
          <.h2 class="mb-4">Tabs (pill style)</.h2>
          <.tabs>
            <.tab is_active link_type="a" to="/" label="Dashboard" />
            <.tab link_type="a" to="/" label="Settings" />
            <.tab link_type="a" to="/" label="Users" />
            <.tab link_type="a" to="/" label="Billing" disabled />
          </.tabs>
        </section>

        <section>
          <.h2 class="mb-4">Tabs (underline style)</.h2>
          <.tabs underline>
            <.tab underline is_active link_type="a" to="/" label="Overview" number={12} />
            <.tab underline link_type="a" to="/" label="Activity" number={5} />
            <.tab underline link_type="a" to="/" label="Settings" />
          </.tabs>
        </section>

        <%!-- Breadcrumbs --%>
        <section>
          <.h2 class="mb-4">Breadcrumbs (slash separator)</.h2>
          <.breadcrumbs links={[
            %{label: "Home", to: "/", icon: "hero-home"},
            %{label: "Components", to: "/"},
            %{label: "Breadcrumbs", to: "/"}
          ]} />
        </section>

        <section>
          <.h2 class="mb-4">Breadcrumbs (chevron separator)</.h2>
          <.breadcrumbs
            separator="chevron"
            links={[
              %{label: "Home", to: "/", icon: "hero-home"},
              %{label: "Projects", to: "/"},
              %{label: "Petal Components", to: "/"},
              %{label: "Settings", to: "/"}
            ]}
          />
        </section>

        <%!-- User Dropdown Menu --%>
        <section>
          <.h2 class="mb-4">User Dropdown Menu</.h2>
          <.user_dropdown_menu
            current_user_name="Matt Platts"
            avatar_src={@avatar_src}
            user_menu_items={@user_menu_items}
          />
        </section>

        <%!-- Pagination --%>
        <section>
          <.h2 class="mb-4">Pagination</.h2>
          <.pagination link_type="live_patch" path="/" current_page={3} total_pages={10} />
        </section>

        <%!-- Links --%>
        <section>
          <.h2 class="mb-4">Links</.h2>
          <div class="flex flex-wrap gap-4">
            <.a to="/" link_type="a" label="Standard link (a)" />
            <.a to="/" link_type="live_patch" label="Live Patch link" />
            <.a to="/" link_type="live_redirect" label="Live Redirect link" />
          </div>
        </section>

        <%!-- Stepper --%>
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

        <%!-- Dropdown --%>
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

        <%!-- Tooltip --%>
        <section>
          <.h2 class="mb-4">Tooltip</.h2>

          <%!-- A realistic editor toolbar: every control gets a tooltip --%>
          <div class="inline-flex items-center gap-1 rounded-lg border border-gray-200 bg-white p-1 shadow-xs dark:border-gray-700 dark:bg-gray-800">
            <.tooltip label="Bold (⌘B)">
              <.icon_button size="sm">
                <.icon name="hero-bold" class="w-4 h-4" />
              </.icon_button>
            </.tooltip>
            <.tooltip label="Italic (⌘I)">
              <.icon_button size="sm">
                <.icon name="hero-italic" class="w-4 h-4" />
              </.icon_button>
            </.tooltip>
            <.tooltip label="Insert link (⌘K)">
              <.icon_button size="sm">
                <.icon name="hero-link" class="w-4 h-4" />
              </.icon_button>
            </.tooltip>
            <div class="mx-1 h-5 w-px bg-gray-200 dark:bg-gray-700"></div>
            <.tooltip placement="bottom">
              <:content>
                Last saved <span class="font-semibold">2 minutes ago</span>
              </:content>
              <.icon_button size="sm">
                <.icon name="hero-check-circle" class="w-4 h-4 text-green-500" />
              </.icon_button>
            </.tooltip>
          </div>

          <%!-- Placements --%>
          <div class="mt-6 flex items-center gap-4">
            <.tooltip
              :for={placement <- ["top", "bottom", "left", "right"]}
              placement={placement}
              label={placement}
            >
              <.button size="sm" color="white" label={placement} />
            </.tooltip>
          </div>
        </section>

        <%!-- Popover --%>
        <section>
          <.h2 class="mb-4">Popover</.h2>

          <div class="flex flex-wrap items-start gap-8">
            <%!-- The classic dimensions form --%>
            <.popover
              placement="bottom-start"
              panel_class="w-80"
              trigger_class="pc-button pc-button--md pc-button--white pc-button--radius-md"
            >
              <:trigger>
                <.icon name="hero-adjustments-horizontal" class="w-4 h-4 mr-2" /> Dimensions
              </:trigger>
              <div class="space-y-3">
                <div>
                  <.h5 class="mb-1" no_margin>Dimensions</.h5>
                  <.p class="text-sm text-gray-500 dark:text-gray-400" no_margin>
                    Set the dimensions for the layer.
                  </.p>
                </div>
                <div class="grid grid-cols-2 items-center gap-2">
                  <label class="text-sm">Width</label>
                  <input type="text" value="100%" class="pc-text-input" />
                  <label class="text-sm">Max. width</label>
                  <input type="text" value="300px" class="pc-text-input" />
                  <label class="text-sm">Height</label>
                  <input type="text" value="25px" class="pc-text-input" />
                </div>
              </div>
            </.popover>

            <%!-- Top layer: an account switcher escaping an overflow-clipped rail --%>
            <div class="flex h-56 w-16 flex-col items-center justify-end overflow-hidden rounded-lg border border-gray-200 bg-gray-50 py-3 dark:border-gray-700 dark:bg-gray-900">
              <.popover top_layer placement="right-start" panel_class="w-64">
                <:trigger>
                  <.avatar size="sm" name="Jane Doe" random_color />
                </:trigger>
                <div class="space-y-1">
                  <.p class="px-2 text-xs font-semibold uppercase text-gray-400" no_margin>
                    Switch workspace
                  </.p>
                  <button class="flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-sm hover:bg-gray-100 dark:hover:bg-gray-700">
                    <.avatar size="xs" name="Acme Inc" random_color /> Acme Inc
                  </button>
                  <button class="flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-sm hover:bg-gray-100 dark:hover:bg-gray-700">
                    <.avatar size="xs" name="Petal Labs" random_color /> Petal Labs
                  </button>
                  <div class="my-1 border-t border-gray-200 dark:border-gray-700"></div>
                  <button class="flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-sm text-red-600 hover:bg-gray-100 dark:hover:bg-gray-700">
                    <.icon name="hero-arrow-right-start-on-rectangle" class="w-4 h-4" /> Sign out
                  </button>
                </div>
              </.popover>
              <.p class="mt-2 text-center text-[10px] leading-tight text-gray-400" no_margin>
                overflow<br />hidden
              </.p>
            </div>
          </div>
        </section>

        <%!-- Vertical Menu --%>
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

      <%!-- ============================================================ --%>
      <%!-- LAYOUT TAB                                                   --%>
      <%!-- ============================================================ --%>
      <div :if={@active_tab == "typography"} class="space-y-16">
        <%!-- Realistic article showing every element in context (the example bar). --%>
        <section class="max-w-2xl">
          <.h2 class="mb-6">Typography</.h2>
          <article>
            <.h1>The quiet power of Phoenix</.h1>
            <.lead>
              A considered type scale does more for "looks finished" than any single component.
              Here is every element, in the kind of context you would actually ship.
            </.lead>
            <.p>
              Petal Components gives you a refined set of headings, body copy and inline elements
              out of the box. Drop in a
              <.inline_code>&lt;.button&gt;</.inline_code>
              or a
              <.inline_code>&lt;.modal&gt;</.inline_code>
              and it already matches.
            </.p>

            <.h2>Built for reading</.h2>
            <.p>
              Body text uses a comfortable line height and a sensible measure, so paragraphs are
              actually pleasant to read rather than cramped. Headings carry tight tracking and
              balanced weight.
            </.p>

            <.blockquote class="my-6">
              "We shipped our marketing site in a weekend. The defaults just look right."
            </.blockquote>

            <.h3>What you get</.h3>
            <.ul>
              <li>
                Headings from
                <.inline_code>h1</.inline_code>
                to
                <.inline_code>h5</.inline_code>
              </li>
              <li>Lead, body, blockquote and inline code</li>
              <li>Muted, large and small text helpers</li>
            </.ul>

            <.h4>Three steps</.h4>
            <.ol>
              <li>Add the dependency</li>
              <li>Import the styles</li>
              <li>Start composing</li>
            </.ol>

            <.h4>A table, too</.h4>
            <.table
              id="typography-table"
              rows={[
                %{tier: "Puns", price: "5 gold coins"},
                %{tier: "Jokes", price: "10 gold coins"},
                %{tier: "One-liners", price: "20 gold coins"}
              ]}
            >
              <:col :let={row} label="Joke tier">{row.tier}</:col>
              <:col :let={row} label="Tax">{row.price}</:col>
            </.table>

            <.hr />

            <div class="space-y-2">
              <.text_large>Large — emphasised body text.</.text_large>
              <.p>Default — the standard paragraph.</.p>
              <.text_muted>Muted — captions, hints and metadata.</.text_muted>
              <.text_small>Small — tight label text.</.text_small>
            </div>
          </article>
        </section>

        <%!-- The scale, as a specimen --%>
        <section>
          <div class="mb-6 font-mono text-xs uppercase tracking-widest text-gray-400">Type scale</div>
          <div class="space-y-6 border-l-2 border-gray-100 pl-6 dark:border-gray-800">
            <div>
              <div class="font-mono text-xs text-gray-400">h1 · display</div>
              <.h1 no_margin>The joke tax</.h1>
            </div>
            <div>
              <div class="font-mono text-xs text-gray-400">h2 · section</div>
              <.h2 no_margin>The people of the kingdom</.h2>
            </div>
            <div>
              <div class="font-mono text-xs text-gray-400">h3 · subsection</div>
              <.h3 no_margin>The king's decree</.h3>
            </div>
            <div>
              <div class="font-mono text-xs text-gray-400">h4 · minor heading</div>
              <.h4 no_margin>A note on rates</.h4>
            </div>
            <div>
              <div class="font-mono text-xs text-gray-400">h5 · label</div>
              <.h5 no_margin>Fine print</.h5>
            </div>
          </div>
        </section>

        <%!-- Every style, labelled with the component that renders it --%>
        <section>
          <div class="mb-6 font-mono text-xs uppercase tracking-widest text-gray-400">
            Every style
          </div>
          <div class="space-y-10">
            <div>
              <div class="mb-2 font-mono text-xs text-gray-400">&lt;.lead&gt;</div>
              <.lead>
                A lead paragraph opens a page with a little more size and a softer colour, setting
                the tone before the body begins.
              </.lead>
            </div>
            <div>
              <div class="mb-2 font-mono text-xs text-gray-400">&lt;.p&gt;</div>
              <.p>
                The standard paragraph, set at a comfortable measure and line height so longer
                passages stay easy on the eye.
              </.p>
            </div>
            <div>
              <div class="mb-2 font-mono text-xs text-gray-400">&lt;.blockquote&gt;</div>
              <.blockquote>
                "The defaults just look right, so we shipped the marketing site in a weekend."
              </.blockquote>
            </div>
            <div>
              <div class="mb-2 font-mono text-xs text-gray-400">&lt;.inline_code&gt;</div>
              <.p>Install with <.inline_code>mix deps.get</.inline_code>, then import the styles.</.p>
            </div>
            <div>
              <div class="mb-2 font-mono text-xs text-gray-400">
                &lt;.text_large&gt; · &lt;.text_muted&gt; · &lt;.text_small&gt;
              </div>
              <div class="space-y-1">
                <.text_large>Large — an emphasised line of body text.</.text_large>
                <.text_muted>Muted — captions, hints and metadata.</.text_muted>
                <.text_small>Small — tight label text.</.text_small>
              </div>
            </div>
            <div>
              <div class="mb-2 font-mono text-xs text-gray-400">&lt;.hr&gt;</div>
              <.hr />
            </div>
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
      </div>

      <%!-- ============================================================ --%>
      <%!-- LAYOUT TAB                                                  --%>
      <%!-- ============================================================ --%>
      <div :if={@active_tab == "layout"} class="space-y-8">
        <%!-- Container with all max_width variants --%>
        <section>
          <.h2 class="mb-4">Container (max_width variants)</.h2>
          <div class="space-y-3">
            <.container max_width="full" class="bg-gray-100 p-4 rounded">
              <.p class="text-sm text-gray-600">max_width="full"</.p>
            </.container>
            <.container max_width="xl" class="bg-gray-100 p-4 rounded">
              <.p class="text-sm text-gray-600">max_width="xl"</.p>
            </.container>
            <.container max_width="lg" class="bg-gray-100 p-4 rounded">
              <.p class="text-sm text-gray-600">max_width="lg"</.p>
            </.container>
            <.container max_width="md" class="bg-gray-100 p-4 rounded">
              <.p class="text-sm text-gray-600">max_width="md"</.p>
            </.container>
            <.container max_width="sm" class="bg-gray-100 p-4 rounded">
              <.p class="text-sm text-gray-600">max_width="sm"</.p>
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

      <%!-- ============================================================ --%>
      <%!-- EFFECTS TAB                                                  --%>
      <%!-- ============================================================ --%>
      <div :if={@active_tab == "effects"} class="space-y-10">
        <section>
          <.h2 class="mb-4">Text Animations</.h2>
          <div class="space-y-8">
            <div>
              <.h4 class="mb-2">Gradient Text</.h4>
              <.gradient_text class="text-4xl font-bold">Build beautiful Phoenix apps</.gradient_text>
            </div>
            <div>
              <.h4 class="mb-2">Shimmer Text</.h4>
              <.shimmer_text class="text-lg font-medium">
                ✨ Introducing Petal Components
              </.shimmer_text>
            </div>
            <div>
              <.h4 class="mb-2">Word Rotate</.h4>
              <span class="text-3xl font-bold">
                Petal makes your app
                <.word_rotate
                  id="effects-word-rotate"
                  words={["beautiful.", "fast.", "accessible.", "consistent."]}
                  class="text-primary-600"
                />
              </span>
            </div>
            <div>
              <.h4 class="mb-2">Typing Effect</.h4>
              <.typing_effect
                id="effects-typing"
                text="shadcn for Phoenix"
                loop
                class="font-mono text-lg"
              />
            </div>
          </div>
        </section>

        <section>
          <.h2 class="mb-4">Number Ticker</.h2>
          <div class="flex flex-wrap items-end gap-8">
            <div>
              <.number_ticker id="effects-ticker-stars" value={@stars} class="text-4xl font-bold" />
              <.p class="text-sm text-gray-500">GitHub stars</.p>
            </div>
            <div>
              <.number_ticker
                id="effects-ticker-mrr"
                value={12480}
                prefix="$"
                class="text-4xl font-bold"
              />
              <.p class="text-sm text-gray-500">MRR</.p>
            </div>
            <div>
              <.number_ticker
                id="effects-ticker-uptime"
                value={99.98}
                decimal_places={2}
                suffix="%"
                class="text-4xl font-bold"
              />
              <.p class="text-sm text-gray-500">Uptime</.p>
            </div>
            <.button size="sm" variant="outline" label="Update value" phx-click="randomize_stars" />
          </div>
          <.p class="mt-2 text-sm text-gray-500">
            Counts up when scrolled into view. Updating the assign animates from the old value to the new one.
          </.p>
        </section>

        <section>
          <.h2 class="mb-4">Border Beam</.h2>
          <div class="grid max-w-3xl gap-6 md:grid-cols-2">
            <.border_beam>
              <div class="p-8">
                <.h4>Default beam</.h4>
                <.p class="text-sm text-gray-500">An animated beam travels along the border.</.p>
              </div>
            </.border_beam>
            <.border_beam color_from="#38bdf8" color_to="#818cf8" duration="5s">
              <div class="p-8">
                <.h4>Custom colors</.h4>
                <.p class="text-sm text-gray-500">color_from, color_to, duration, size.</.p>
              </div>
            </.border_beam>
          </div>
        </section>

        <section>
          <.h2 class="mb-4">Meteors</.h2>
          <div class="relative max-w-3xl overflow-hidden rounded-xl bg-gray-950 px-8 py-16">
            <.meteors count={25} />
            <div class="relative text-center">
              <.h3 class="text-white">Ship faster with Petal</.h3>
              <.p class="text-gray-400">Pure CSS — meteor positions are generated server-side.</.p>
            </div>
          </div>
        </section>

        <section>
          <.h2 class="mb-4">Spotlight Cards</.h2>
          <div class="grid max-w-4xl gap-4 md:grid-cols-3">
            <.spotlight_card id="spotlight-1">
              <div class="p-6">
                <.icon name="hero-bolt" class="mb-3 h-6 w-6 text-primary-600" />
                <.h5>Fast by default</.h5>
                <.p class="text-sm text-gray-500">Server-rendered, minimal JS.</.p>
              </div>
            </.spotlight_card>
            <.spotlight_card id="spotlight-2">
              <div class="p-6">
                <.icon name="hero-swatch" class="mb-3 h-6 w-6 text-primary-600" />
                <.h5>Themeable</.h5>
                <.p class="text-sm text-gray-500">Tailwind v4 with pc-* overrides.</.p>
              </div>
            </.spotlight_card>
            <.spotlight_card id="spotlight-3" spotlight_color="rgb(56 189 248 / 0.25)">
              <div class="p-6">
                <.icon name="hero-cursor-arrow-ripple" class="mb-3 h-6 w-6 text-primary-600" />
                <.h5>Custom glow</.h5>
                <.p class="text-sm text-gray-500">Move your cursor over this card.</.p>
              </div>
            </.spotlight_card>
          </div>
        </section>

        <section>
          <.h2 class="mb-4">Confetti</.h2>
          <.confetti id="effects-confetti" />
          <div class="flex flex-wrap gap-3">
            <.button label="Server burst 🎉" phx-click="celebrate" />
            <.button
              variant="outline"
              label="Client burst (no round trip)"
              phx-click={JS.dispatch("pc:confetti", to: "#effects-confetti")}
            />
          </div>
          <.p class="mt-2 text-sm text-gray-500">
            Fire from the server with <code>push_event(socket, "pc-confetti", %{})</code>
            or from the client with <code>JS.dispatch("pc:confetti")</code>.
          </.p>
        </section>
      </div>

      <%!-- ============================================================ --%>
      <%!-- CHAT TAB                                                     --%>
      <%!-- ============================================================ --%>
      <div :if={@active_tab == "chat"} class="space-y-10">
        <section>
          <.h2 class="mb-4">Conversation</.h2>
          <.p class="mb-4">
            AI chat / conversation components. Streaming is driven by the bundled
            <code>PetalChatStream</code>
            hook (not interactive in this static playground).
          </.p>
          <Chat.conversation id="dev-chat" class="max-w-xl">
            <Chat.chat_message role="assistant">
              <:avatar>
                <div class="flex h-full w-full items-center justify-center bg-gradient-to-br from-fuchsia-500 to-indigo-600 text-white">
                  ✦
                </div>
              </:avatar>
              <Chat.markdown content="Hi! I support **bold**, `inline code`, and [links](https://petal.build)." />
            </Chat.chat_message>
            <Chat.chat_message role="user">
              <span class="pc-chat__text">What's the weather in Tokyo?</span>
            </Chat.chat_message>
            <Chat.tool_call name="get_weather" status={:complete}>
              <div class="flex items-center justify-between rounded-lg bg-gradient-to-br from-sky-500 to-indigo-600 px-4 py-3 text-white">
                <div>
                  <div class="text-sm font-medium opacity-90">Tokyo</div>
                  <div class="text-2xl font-bold">21°C</div>
                </div>
                <div class="text-4xl">☀️</div>
              </div>
            </Chat.tool_call>
            <Chat.chat_message role="assistant">
              <:avatar>
                <div class="flex h-full w-full items-center justify-center bg-gradient-to-br from-fuchsia-500 to-indigo-600 text-white">
                  ✦
                </div>
              </:avatar>
              <Chat.streaming_text id="dev-stream" />
            </Chat.chat_message>
            <:footer>
              <Chat.prompt_input phx-submit="noop" placeholder="Send a message..." />
            </:footer>
          </Chat.conversation>
        </section>

        <section>
          <.h3 class="mb-4">Reasoning</.h3>
          <Chat.reasoning label="Thought for 2s">
            First I considered the user's location, then looked up the current conditions.
          </Chat.reasoning>
        </section>

        <section>
          <.h3 class="mb-4">Message actions</.h3>
          <Chat.message_actions>
            <Chat.copy_button id="dev-copy" text="Copied text" />
            <button type="button" class="pc-chat__action" phx-click="noop">Regenerate</button>
          </Chat.message_actions>
        </section>

        <section>
          <.h3 class="mb-4">Suggestions</.h3>
          <Chat.suggestions
            items={["What is Phoenix LiveView?", "Show me a markdown demo", "Write a haiku"]}
            on_select="noop"
          />
        </section>

        <section>
          <.h3 class="mb-4">Error</.h3>
          <Chat.chat_error on_retry="noop">
            Something went wrong generating a response.
          </Chat.chat_error>
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
  port:
    case Integer.parse(System.get_env("PORT") || "") do
      {port, ""} -> port
      _ -> 4000
    end,
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
