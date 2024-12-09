defmodule PetalComponentsWeb.A11yLive do
  @moduledoc """
  A LiveView to test the accessibility of Petal Components using `:a11y_audit`.

  It's worth noting that this view is ugly because classes defined with @apply
  are not able to be processed for Phoenix Playground at this time (as far as I can tell).

  To run locally:
  $ iex -S mix
  iex> Run.playground()
  """
  use Phoenix.LiveView, global_prefixes: ~w(x-)
  use PetalComponents
  alias Phoenix.LiveView.JS

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       count: 0,
       form: to_form(%{}, as: :user),
       main_menu_items: [
         %{
           name: :sign_in,
           label: "Path",
           path: "/path",
           icon: "hero-key"
         }
       ],
       group_size: "lg",
       current_page: :current_page,
       sidebar_title: "blah",
       posts: [
         %{
           id: 1,
           name: "Some post"
         },
         %{
           id: 2,
           name: "Another post"
         }
       ],
       user_menu_items: [%{path: "/path", icon: "hero-home", label: "blah"}],
       avatar_src: "https://avatars.githubusercontent.com/u/82628117?v=4",
       current_user_name: "petal_components"
     )}
  end

  def render(assigns) do
    ~H"""
    <script defer src="https://cdn.jsdelivr.net/npm/@alpinejs/collapse@3.x.x/dist/cdn.min.js">
    </script>
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js">
    </script>
    <script defer src="https://cdn.tailwindcss.com">
    </script>
    <style type="text/css">
      /* css transitions can cause flaky a11y tests */
      .env-test {
        *, *::before, *::after {
          transition: unset !important;
        }
      }
      svg {
        height: 1em; width: 1em;
      }
    </style>
    <main role="main" class="env-test">
      <.h1>Petal Components A11y Audit</.h1>
      <.h2>Heading 2</.h2>
      <.h3>Heading 3</.h3>
      <.h4>Heading 4</.h4>
      <.h5>Heading 5</.h5>

      <.ul class="mb-5" x-random-attribute="lol">
        <li>Item 1</li>
        <li>Item 2</li>
      </.ul>

      <.ol class="mb-5" x-random-attribute="lol">
        <li>Item 1</li>
        <li>Item 2</li>
      </.ol>

      <.prose class="md:prose-lg" x-random-attribute="lol">
        <p>A paragraph</p>
      </.prose>

      <.p x-text="input">Paragraph</.p>

      <.accordion>
        <:item heading="Accordion">
          Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam quis. Ut enim ad minim veniam quis. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
        </:item>
        <:item heading="Accordion Two">
          Lorem ipsum dolor sit amet, consectetur adipiscing elit...
        </:item>
      </.accordion>

      <.alert with_icon color="info" label="Info alert" />
      <.alert with_icon color="info" label="Info alert with heading" heading="Info" />
      <.alert with_icon color="danger" label="Error alert" />

      <.avatar src={@avatar_src} />

      <.badge color="primary" label="Primary" />

      <.breadcrumbs
        class="text-md"
        links={[
          %{label: "Link 1", to: "/", icon: "hero-home"},
          %{label: "Link 2", to: "/", icon: "hero-home"},
          %{label: "Link 3", to: "/", icon: "hero-home"}
        ]}
      />

      <.button label="Press me" phx-click="click_event" />

      <.button_group aria_label="My options" size={@group_size}>
        <:button label="XS" phx-click="change_size" phx-value-size="xs" />
        <:button label="SM" kind="link" patch="/app/orgs" />
        <:button label="MD" phx-click="change_size" phx-value-size="md" />
        <:button phx-click="change_size" phx-value-size="lg">LG</:button>
        <:button phx-click="change_size" phx-value-size="xl">XL</:button>
      </.button_group>

      <.button_group aria_label="My links" size="md">
        <:button kind="link" patch="/path-one">Link 1</:button>
        <:button kind="link" patch="/path-two">Link 2</:button>
        <:button label="Link 3" kind="link" navigate="/other" />
      </.button_group>

      <.card>
        <.card_content category="Article" heading="Enhance your Phoenix development">
          <div class="mt-4 font-light text-gray-500 text-md">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eget leo interdum, feugiat ligula eu, facilisis massa. Nunc sollicitudin massa a elit laoreet.
          </div>
        </.card_content>
      </.card>

      <.container max_width="full"></.container>

      <.dropdown
        class="dropdown_class"
        menu_items_wrapper_class="menu_items_wrapper_class"
        label="Dropdown"
      >
        <.dropdown_menu_item class="dropdown_menu_item_class" type="button">
          <.icon name="hero-home-mini" class="w-5 h-5 text-gray-500" /> Button item with icon
        </.dropdown_menu_item>
      </.dropdown>

      <.form for={@form}>
        <.field
          field={@form[:name]}
          type="text"
          placeholder="eg. Sally"
          class="!w-max"
          label_class="label-class"
        />
        <.field field={@form[:color]} type="color" class="!w-max" label_class="label-class" />
        <.field field={@form[:date]} type="date" class="!w-max" label_class="label-class" />
        <.field
          field={@form[:datetime_local]}
          type="datetime-local"
          class="!w-max"
          label_class="label-class"
        />
        <.field field={@form[:email]} type="email" class="!w-max" label_class="label-class" />
        <.field field={@form[:file]} type="file" class="!w-max" label_class="label-class" />
        <.field field={@form[:hidden]} type="hidden" class="!w-max" label_class="label-class" />
        <.field field={@form[:month]} type="month" class="!w-max" label_class="label-class" />
        <.field field={@form[:number]} type="number" class="!w-max" label_class="label-class" />
        <.field field={@form[:password]} type="password" class="!w-max" label_class="label-class" />
        <.field field={@form[:range]} type="range" class="!w-max" label_class="label-class" />
        <.field field={@form[:search]} type="search" class="!w-max" label_class="label-class" />
        <.field field={@form[:tel]} type="tel" class="!w-max" label_class="label-class" />
        <.field field={@form[:time]} type="time" class="!w-max" label_class="label-class" />
        <.field field={@form[:url]} type="url" class="!w-max" label_class="label-class" />
        <.field field={@form[:week]} type="week" class="!w-max" label_class="label-class" />
      </.form>

      <.icon name="hero-arrow-right" class="text-gray-300" />

      <PetalComponents.Link.a link_type="a" to="/" label="Press me" phx-click="click_event" />

      <.spinner show={true} />

      <.stepper
        steps={[
          %{
            name: "Account Details",
            description: "Basic information",
            complete?: true,
            active?: true,
            on_click: JS.push("navigate", value: %{target_index: 0})
          },
          %{
            name: "Preferences",
            description: "Set preferences",
            complete?: true,
            active?: false,
            on_click: JS.push("navigate", value: %{target_index: 1})
          },
          %{
            name: "Confirmation",
            description: "Review and confirm",
            complete?: false,
            active?: false,
            on_click: JS.push("navigate", value: %{target_index: 2})
          }
        ]}
        orientation="horizontal"
        size="sm"
      />

      <.vertical_menu
        menu_items={@main_menu_items}
        current_page={@current_page}
        title={@sidebar_title}
      />

      <.marquee pause_on_hover repeat={3}>
        <%= for review <- [
    %{
      name: "Anne",
      username: "@anne",
      body: "I've never seen anything like this before. It's amazing.",
      img: "https://res.cloudinary.com/wickedsites/image/upload/v1604268092/unnamed_sagz0l.jpg"
    },
    %{
      name: "Jill",
      username: "@jill",
      body: "I don't know what to say. I'm speechless. This is amazing.",
      img: "https://res.cloudinary.com/wickedsites/image/upload/v1636595188/dummy_data/avatar_1_lc8plf.png"
    },
    %{
      name: "John",
      username: "@john",
      body: "I'm at a loss for words. This is amazing. I love it.",
      img: "https://res.cloudinary.com/wickedsites/image/upload/v1636595188/dummy_data/avatar_2_jhs6ww.png"
    }
    ] do %>
          <.review_card
            name={review.name}
            username={review.username}
            body={review.body}
            img={review.img}
          />
        <% end %>
      </.marquee>

      <.modal max_width="sm" title="Modal">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.Modal.hide_modal()} />
          </div>
        </div>
      </.modal>

      <.progress size="xl" value={10} max={100} label="15%" />

      <.rating include_label rating={3.3} total={5} />

      <.skeleton />

      <.slide_over title="SlideOver" origin="left">
        <div class="gap-5 text-sm">
          <.form_label label="Add some text here." />
          <div class="flex justify-end">
            <.button label="close" phx-click={PetalComponents.SlideOver.hide_slide_over("left")} />
          </div>
        </div>
      </.slide_over>

      <.table class="my-class" id="posts" row_id={fn post -> "row_#{post.id}" end} rows={@posts}>
        <:col :let={post} label="Name" class="col-class" row_class="row-class">{post.name}</:col>
      </.table>

      <.tabs class="flex-col sm:flex-row space-x">
        <.tab is_active to="/">Home</.tab>
        <.tab link_type="a" to="/" label="Press me" phx-click="click_event" />
      </.tabs>

      <.user_dropdown_menu
        user_menu_items={@user_menu_items}
        avatar_src={@avatar_src}
        current_user_name={@current_user_name}
      />
    </main>
    """
  end
end
