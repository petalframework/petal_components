<p align="center">
  <img src="https://res.cloudinary.com/wickedsites/image/upload/v1635752721/petal/logo_rh2ras.png" height="128">
  <h1 align="center">Petal Components</h1>
</p>

## About 🌺

Petal stands for:

* [Phoenix](https://www.phoenixframework.org/)
* [Elixir](https://elixir-lang.org/)
* [Tailwind CSS](https://tailwindcss.com/)
* [Alpine JS](https://alpinejs.dev/) (optional)
* [Live View (HEEX)](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html)

Petal is a set of HEEX components that makes it easy for Phoenix developers to start building beautiful web apps.

Some components like [Dropdowns](#dropdowns) require Javascript to work. We default to Alpine JS (17kb) but you can choose to use `Phoenix.LiveView.JS` as an alternative (though this will only work in live environments like live views or live components).

<p align="center">
  <img src="https://res.cloudinary.com/wickedsites/image/upload/v1635752726/petal/screenshot_tti5my.png" height="1200">
</p>

## Docs 📄

- [Install](#install)
  - [Existing projects](#existing-projects)
  - [New projects](#new-projects)
- [Roadmap](#roadmap)
  - [Layout](#layout)
  - [Form components](#form-components)
  - [Buttons](#buttons)
  - [Misc](#misc)
- [Examples](#examples)
  - [Containers](#containers)
  - [Links](#links)
    - [Link types](#link-types)
  - [Buttons](#buttons)
    - [Button types](#button-types)
    - [Button colors](#button-colors)
    - [Button colors (outline)](#button-colors-(outline))
    - [Button sizes](#button-sizes)
    - [Button states](#button-states)
      - [Disabled](#disabled)
      - [Loading](#loading)
    - [Button with icon](#button-with-icon)
  - [Typography](#typography)
    - [Headings](#headings)
    - [Paragraphs](#paragraphs)
  - [Heroicons](#heroicons)
    - [Heroicons solid](#heroicons-solid)
    - [Heroicons outline](#heroicons-outline)
  - [Badges](#badges)
  - [Alerts](#alerts)
    - [Info alert](#info-alert)
    - [Success alert](#success-alert)
    - [Warning alert](#warning-alert)
    - [Danger alert](#danger-alert)
  - [Forms](#forms)
    - [Text input](#text-input)
    - [Number input](#number-input)
    - [Email input](#email-input)
    - [Password input](#password-input)
    - [Search input](#search-input)
    - [Telephone input](#telephone-input)
    - [URL input](#url-input)
    - [Time input](#time-input)
    - [Time select](#time-input)
    - [Datetime local input](#datetime-input)
    - [Datetime select](#datetime-select)
    - [Color input](#color-input)
    - [File input](#file-input)
    - [Range input](#range-input)
    - [Text area](#text-area)
    - [Select](#select)
    - [Radios](#radios)
  - [Dropdowns](#dropdowns)
  - [Loading indicators](#loading-indicators)
  - [Breadcrumbs](#breadcrumbs)
    - [Slash](#slash)
    - [Chevron](#chevron)
  - [Avatar](#avatar)
    - [Basic Avatars](#basic-avatars)
    - [Avatars with placeholder icon](#avatars-with-placeholder-icon)
    - [Avatar groups stacked](#avatar-groups-stacked)
    - [Avatars with placeholder initials](#avatars-with-placeholder-initials)
    - [Random color generated avatars with placeholder initials](#random-color-generated-avatars-with-placeholder-initials)
  - [Progress](#progress)
    - [Progress bar](#progress-bar)
    - [Sizes](#sizes)
  - [Pagination](#pagination)
    - [Progress bar](#progress-bar)
    - [Sizes](#sizes)
  - [Modal](#modal)
    - [Sizes](#sizes)


## Install

For Petal to work you simply need Tailwind CSS and Alpine JS installed along with with some Tailwind configuration.

### Existing projects

1 - Follow [this guide](https://sergiotapia.com/phoenix-160-liveview-esbuild-tailwind-jit-alpinejs-a-brief-tutorial) to install Tailwind and Alpine.

2 - Add Petal to your deps:

`mix.exs`

```elixir
defp deps do
  [
    {:petal_components, "~> 0.5.1"},
  ]
end
```

3 - Modify your `tailwind.config.js` file to include these settings:

```js
const colors = require("tailwindcss/colors");

module.exports = {
  mode: "jit",
  purge: [
    "../lib/*_web/**/*.*ex",
    "./js/**/*.js",

    // We need to include the Petal dependency so the classes get picked up by JIT.
    "../deps/petal_components/**/*.*ex"
  ],
  darkMode: false,
  theme: {
    extend: {

      // Set these to your brand colors
      colors: {
        primary: colors.blue,
        secondary: colors.pink,
      },
    },
  },
  plugins: [require("@tailwindcss/forms")],
};
```

4 - Alias the components in your `<your_project>_web.ex` file

```elixir
defmodule YourProjectWeb
  ...

  defp view_helpers do
    quote do
      ...

      use PetalComponents
    end
  end
```

This will import the functions so you can go `<.button />` in your templates / live views.

If the function names clash with yours (eg. you already have a `.button` function) you can opt to alias the modules instead:

```elixir
defmodule YourProjectWeb
  ...

  defp view_helpers do
    quote do
      ...

      alias PetalComponents.{
        Alert,
        Badge,
        Button,
        Container,
        Dropdown,
        Form,
        Loading,
        Typography,
        Avatar,
        Progress,
        Breadcrumbs,
        Pagination,
        Link,
        Modal
      }
    end
  end
```

### New projects

We recommend using [Petal boilerplate](https://github.com/petalframework/petal_boilerplate), which is a fresh Phoenix install with Tailwind + Alpine installed. It comes with a project renaming script so you can still rename your project to whatever you like.

## Roadmap

### Layout
- [x] container

### Form components
- [x] text input
- [x] select dropdown
- [x] textarea
- [x] checkbox
- [x] radios
- [x] errors
- [x] labels
- [x] file upload
- [x] text variants (email, password, tel)
- [x] color input
- [x] range input
- [x] time & datetime input
- [ ] multiple select
- [ ] switch

### Buttons
- [x] basic button
- [x] change size
- [x] change color
- [x] loading state (with spinner)
- [x] filled vs outline
- [ ] button group

### Misc
- [x] menu dropdown
- [ ] tooltips
- [x] avatar
- [x] alerts
- [ ] tables
- [ ] cards
- [x] breadcrumbs
- [x] modal
- [ ] slide over
- [x] spinners
- [ ] accordian
- [x] pagination
- [x] badges
- [x] progress
- [x] links

## Configuring components

Most components will allow you to provide a `class` attribute. If you wish to override an existing class you can prepend an exclamation mark to the class:

```elixir
<.h2 class="leading-1">Won't work</.h2>
<.h2 class="!leading-1">Works!</.h2>
```

## Examples
### Containers
```elixir
<Container.container max_width="full | lg | md | sm">
```
### Links

#### Link types
```elixir
<.link link_type="a | live_patch | live_redirect" to="/" class="" label="" />
```

### Buttons

#### Button types
```elixir
<.button label="Button" />
<.button link_type="a | live_patch | live_redirect" to="#" label="a" />
```

#### Button colors
```elixir
<.button color="primary | secondary | white | success | danger" label="Primary" />
```

#### Button colors (outline)
```elixir
<.button color="primary | secondary | white | success | danger" label="Primary" variant="outline" />
```

#### Button sizes
```elixir
<.button size="sm | md | lg | xl">
```

#### Button states

##### Disabled
```elixir
<.button disabled link_type="a | live_patch | live_redirect"  to="/" label="Disabled" />
```

##### Loading
```elixir
<.button loading link_type="a | live_patch | live_redirect"  to="/" label="Loading" />
```

#### Button with icon
```elixir
<.button icon>
  <Heroicons.Solid.home class="w-5 h-5" />
  With label
</.button>
<.button icon link_type="a | live_patch | live_redirect" icon to="/">
  <Heroicons.Solid.home  class="w-5 h-5" />
  With label
</.button>
```

### Typography

#### Headings

```elixir
<.h1>Heading 1</.h1>
<.h2>Heading 2</.h2>
<.h3>Heading 3</.h3>
<.h4>Heading 4</.h4>
<.h5>Heading 5</.h5>

<.h1 no_margin>Has no bottom margin</.h1>
<.h1 underline>Has an underline</.h1>
<.h1 class="!mb-10">Modify bottom margin</.h1>
<.h1 class="hover:text-gray-600">Change color on hover</.h1>
<.h1 color_class="text-blue-700 dark:text-blue-200">Change color</.h1>
```

#### Paragraphs

```elixir
<.p>Paragraph</.p>
<.p class="!text-blue-500">Blue paragraph</.p>
```

### Heroicons

#### Heroicons solid
```elixir
<Heroicons.Solid.home class="w-6 h-6 text-blue-500" />
<Heroicons.Solid.render icon={:home} />
```

#### Heroicons outline
```elixir
<Heroicons.Outline.home class="w-6 h-6 text-blue-500" />
<Heroicons.Outline.render icon={:home} />
```

### Badges
```elixir
<.badge color="primary | secondary | Info | Success | Warning | Danger | Gray" label="Primary" />
```
### Alerts

#### Info alert
```elixir
<.alert state="info">
  This is an info state
</.alert>
```

#### Success alert
```elixir
<.alert state="success" label="This is a success state" />
```

#### Warning alert
```elixir
<.alert state="warning" label="This is a warning state" />
```

#### Danger alert
```elixir
<.alert state="danger" label="This is a danger state" />
```

#### Optional heading alert
```elixir
<.alert heading="Optional heading">
  This is quite a long paragraph that takes up more than one line.
</.alert>
```

### Forms

Inputs can take the same arguments as the equivalents in [Phoenix.HTML.Form](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#content). Eg. `<.time_input precision={:second} />`.

#### Text input
```elixir
<.text_input form={:user} field={:name} placeholder="eg. John" />

<!-- With a label, errors and bottom margin -->
<div class="mb-6">
  <.form_label form={f} field={:name} />
  <.text_input form={f} field={:name} placeholder="eg. John" />
  <.form_field_error form={f} field={:name} class="mt-1" />
</div>

<!-- Includes label, errors and bottom margin -->
<.form_field
  type="text_input"
  form={f}
  field={:first_name}
  placeholder="eg. John"
/>
```

#### Number input

Same as [Text input](#text-input) but use `<.number_input>`.

#### Email input

Same as [Text input](#text-input) but use `<.email_input>`.

#### Password input

Same as [Text input](#text-input) but use `<.password_input>`.

#### Telephone input

Same as [Text input](#text-input) but use `<.telephone_input>`.

#### URL input

Same as [Text input](#text-input) but use `<.url_input>`.

#### Time input

Same as [Text input](#text-input) but use `<.time_input>`.

#### Time select

Same as [Text input](#text-input) but use `<.time_select>`.

#### Datetime input

Same as [Text input](#text-input) but use `<.datetime_local_input>`.

#### Datetime select

Same as [Text input](#text-input) but use `<.datetime_select>`.

#### Color input

Same as [Text input](#text-input) but use `<.color_input>`.

#### File input

Same as [Text input](#text-input) but use `<.file_input>`.

#### Range input

Same as [Text input](#text-input) but use `<.range_input>`.

#### Text area

Same as [Text input](#text-input) but use `<.textarea>`.

#### Select
```elixir
<.select
  options={["Admin": "admin", "User": "user"]}
  form={f}
  field={:role}
/>

<!-- With a label, errors and bottom margin -->
<div class="mb-6">
  <.form_label form={f} field={:role} />
  <.select
    options={["Admin": "admin", "User": "user"]}
    form={f}
    field={:role}
  />
  <.form_field_error form={f} field={:name} class="mt-1" />
</div>

<!-- Includes label, errors and bottom margin -->
<.form_field
  type="select"
  options={["Admin": "admin", "User": "user"]}
  form={f}
  field={:role}
/>
```

#### Checkbox
```elixir
<.checkbox form={f} field={:read_terms} />

<!-- With a label, errors and bottom margin -->
<label class="inline-flex items-center block gap-3 mb-6 text-sm text-gray-900 dark:text-gray-200">
  <.checkbox form={f} field={:read_terms} />
  <div>I accept</div>
</label>

<.form_field_error form={f} field={:read_terms} class="mt-1" />

<!-- Includes label, errors and bottom margin -->
<.form_field
  type="checkbox"
  form={f}
  field={:read_terms}
  label="I accept"
/>
```

#### Radios
```elixir
<.checkbox form={f} field={:read_terms} />

<!-- With a label, errors and bottom margin -->
<.form_label form={f} field={:eye_color} />

<div class="flex flex-col gap-1">
  <label class="inline-flex items-center block gap-3 text-sm text-gray-900 dark:text-gray-200">
    <.radio form={f} field={:eye_color} value="green" />
    <div>Green</div>
  </label>

  <label class="inline-flex items-center block gap-3 text-sm text-gray-900 dark:text-gray-200">
    <.radio form={f} field={:eye_color} value="blue" />
    <div>Blue</div>
  </label>

  <label class="inline-flex items-center block gap-3 text-sm text-gray-900 dark:text-gray-200">
    <.radio form={f} field={:eye_color} value="gray" />
    <div>Gray</div>
  </label>
</div>

<.form_field_error form={f} field={:read_terms} class="mt-1" />

<!-- Includes label, errors and bottom margin -->
<.form_field
  type="radio_group"
  form={f}
  field={:eye_color}
  options={["Green": "green", "Blue": "blue", "Gray": "gray"]}
  label="Eye color"
/>
```

### Dropdowns

Dropdowns require Javascript. You can choose whether to use Alpine JS or the `Phoenix.LiveView.JS` module.

Note that the `Phoenix.LiveView.JS` option only works in live components. For dead components you must use Alpine JS.

```elixir
<.dropdown label="Dropdown" js_lib="alpine_js|live_view_js" placement="left|right">
  <.dropdown_menu_item>
    <Heroicons.Outline.home class="w-5 h-5 text-gray-500" />
    Button item with icon
  </.dropdown_menu_item>
  <.dropdown_menu_item link_type="button" label="a item" />
  <.dropdown_menu_item link_type="a" to="/" label="a item" />
  <.dropdown_menu_item link_type="live_patch" to="/" label="Live Patch item" />
  <.dropdown_menu_item link_type="live_redirect" to="/" label="Live Redirect item" />
</.dropdown>
```

### Loading indicators
```elixir
<.spinner show={false} />
<.spinner show={true} size="sm" />
<.spinner show={true} size="md" class="text-green-500" />
<.spinner show={true} size="lg" class="text-red-500" />
```

### Breadcrumbs

#### Slash
```elixir
<.breadcrumbs links={[
  %{ label: "Link 1", to: "#" },
  %{ label: "Link 2", to: "#" },
  %{ label: "Link 3", to: "#" }
]}/>
```

#### Chevron
```elixir
<.breadcrumbs separator="chevron" links={[
  %{ label: "Link 1", to: "#" },
  %{ label: "Link 2", to: "#", link_type: "live_patch" },
  %{ label: "Link 3", to: "#", link_type: "live_redirect" },
]}/>
```

#### Basic Avatars
```elixir
<.avatar size="xs | sm | md | lg | xl " src="https://res.cloudinary.com/wickedsites/image/upload/v1604268092/unnamed_sagz0l.jpg" />
```

#### Avatars with placeholder icon
```elixir
<.avatar size="xs | sm | md | lg | xl"/>
```

#### Avatar groups stacked
```elixir
<.avatar_group avatars={[
  "https://res.cloudinary.com/wickedsites/image/upload/v1604268092/unnamed_sagz0l.jpg",
  "https://res.cloudinary.com/wickedsites/image/upload/v1636595188/dummy_data/avatar_1_lc8plf.png",
  "https://res.cloudinary.com/wickedsites/image/upload/v1636595188/dummy_data/avatar_2_jhs6ww.png",
  "https://res.cloudinary.com/wickedsites/image/upload/v1636595189/dummy_data/avatar_14_rkiyfa.png",
]} size="xs | sm | md | lg | xl" class="inline-block"/>
```

#### Avatars with placeholder initials
```elixir
 <.avatar name="Petal Components" size="xs | sm | md | lg | xl" />
```

#### Random color generated avatars with placeholder initials
```elixir
<.avatar name="Matt Platts" size="xs | sm | md | lg | xl" random_color />
```

### Progress

#### Progress bar
```elixir
<.progress color="primary | secondary | info | success | warning | danger" value={30} max={100} class="max-w-xl" />
```

##### Sizes
```elixir
<.progress size="xs | sm | md | lg | xl" value={15} max={100} class="max-w-xl" label="15%" />
```
### Pagination

#### Basic pagination
```elixir
<.pagination link_type="a | live_patch | live_redirect" class="mb-5" path="/:page" current_page={1} total_pages={10} />
```

### Modal

The live view will handle the modal's state.

```elixir

# Live view

@impl true
def mount(_params, _session, socket) do
  {:ok, assign(socket, :show_modal, false)}
end

@impl true
def handle_params(_params, _uri, socket) do
  case socket.assigns.live_action do
    :index ->
      {:noreply, assign(socket, show_modal: false)}
    :show ->
      {:noreply, assign(socket, show_modal: true)}
  end
end

# This event is emitted by the component and must be catched
@impl true
def handle_event("close_modal", _, socket) do
  {:noreply, push_patch(socket, to: "/index")}
end

@impl true
def render(assigns) do
  ~H"""
  <.button label="Show modal" link_type="live_patch" to="/show" />

  <%= if @modal do %>
    <.modal max_width="sm | md | lg | xl | 2xl | full" title="Modal">

      Modal contents goes here

      <div class="gap-5 text-sm">
        <div class="flex justify-end">
          <.button label="close" phx-click={PetalComponents.Modal.hide_modal()} />
        </div>
      </div>
    </.modal>
  <% end %>
  """
end
```


