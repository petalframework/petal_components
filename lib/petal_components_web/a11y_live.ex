defmodule PetalComponentsWeb.A11yLive do
  @moduledoc """
  A LiveView to test the accessibility of Petal Components using `:a11y_audit`.
  """
  use Phoenix.LiveView
  use PetalComponents

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
           icon: :key
         }
       ],
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
       user_menu_items: [%{path: "/path", icon: :home, label: "blah"}],
       avatar_src: "blah.img",
       current_user_name: nil
     )}
  end

  def render(assigns) do
    ~H"""
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js">
    </script>
    <main role="main">
      <.h1>Petal Components A11y Audit</.h1>
      <.h2>Heading 2</.h2>
      <.h3>Heading 3</.h3>
      <.h4>Heading 4</.h4>
      <.h5>Heading 5</.h5>

      <.ul class="mb-5" random-attribute="lol">
        <li>Item 1</li>
        <li>Item 2</li>
      </.ul>

      <.ol class="mb-5" random-attribute="lol">
        <li>Item 1</li>
        <li>Item 2</li>
      </.ol>

      <.prose class="md:prose-lg" random-attribute="lol">
        <p>A paragraph</p>
      </.prose>

      <.p x-text="input">Paragraph</.p>

      <.accordion>
        <:item heading="Accordion">
          Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam quis. Ut enim ad minim veniam quis. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
        </:item>
      </.accordion>

      <.alert with_icon color="info" label="Info alert" />

      <.avatar src="image.png" />

      <.badge color="primary" label="Primary" />

      <.breadcrumbs
        class="text-md"
        links={[
          %{label: "Link 1", to: "/", icon: :home}
        ]}
      />

      <.button label="Press me" phx-click="click_event" />

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
          <Heroicons.home class="w-5 h-5 text-gray-500" /> Button item with icon
        </.dropdown_menu_item>
      </.dropdown>

      <.form for={@form}>
        <.field
          field={@form[:name]}
          placeholder="eg. Sally"
          class="!w-max"
          itemid="something"
          value="John"
          help_text="Help text"
          label_class="label-class"
        />
      </.form>

      <.icon name={:arrow_right} class="text-gray-300" />

      <.form for={@form}>
        <.input field={@form[:name]} type="text" />
        <.input field={@form[:name]} type="color" />
        <.input field={@form[:name]} type="date" />
        <.input field={@form[:name]} type="datetime-local" />
        <.input field={@form[:name]} type="email" />
        <.input field={@form[:name]} type="file" />
        <.input field={@form[:name]} type="hidden" />
        <.input field={@form[:name]} type="month" />
        <.input field={@form[:name]} type="number" />
        <.input field={@form[:name]} type="password" />
        <.input field={@form[:name]} type="range" />
        <.input field={@form[:name]} type="search" />
        <.input field={@form[:name]} type="tel" />
        <.input field={@form[:name]} type="text" />
        <.input field={@form[:name]} type="time" />
        <.input field={@form[:name]} type="url" />
        <.input field={@form[:name]} type="week" />
      </.form>

      <PetalComponents.Link.a link_type="a" to="/" label="Press me" phx-click="click_event" />

      <.spinner show={true} />

      <.vertical_menu
        menu_items={@main_menu_items}
        current_page={@current_page}
        title={@sidebar_title}
      />

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
        <:col :let={post} label="Name" class="col-class" row_class="row-class"><%= post.name %></:col>
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
