<p align="center">
  <img src="https://res.cloudinary.com/wickedsites/image/upload/v1635752721/petal/logo_rh2ras.png" height="128">
  <h1 align="center">Petal Components</h1>
</p>

## About 🌺

Petal stands for:

* [Phoenix](https://www.phoenixframework.org/)
* [Elixir](https://elixir-lang.org/)
* [Tailwind CSS](https://tailwindcss.com/)
* [Alpine JS](https://alpinejs.dev/)
* [Live View (HEEX)](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html)

Petal is a set of HEEX components that makes it easy for Phoenix developers to start building beautiful web apps.

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
    - [Text area](#text-area)
    - [Select](#select)
    - [Radios](#radios)
  - [Dropdowns](#dropdowns)
  - [Loading indicators](#loading-indicators)

## Install

For Petal to work you simply need Tailwind CSS and Alpine JS installed along with with some Tailwind configuration.

### Existing projects

1 - Follow [this guide](https://sergiotapia.com/phoenix-160-liveview-esbuild-tailwind-jit-alpinejs-a-brief-tutorial) to install Tailwind and Alpine.

2 - Add Petal to your deps:

`mix.exs`

```elixir
defp deps do
  [
    {:petal_components, "~> 0.3.1"},
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
        Heroicons,
        Alert,
        Badge,
        Button,
        Container,
        Dropdown,
        Form,
        Loading,
        Typography
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
- [ ] multiple select
- [x] radios
- [ ] file upload
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
- [ ] avatar
- [x] alerts
- [ ] tables
- [ ] cards
- [ ] breadcrumbs
- [ ] modal
- [ ] slide over
- [ ] spinners
- [ ] accordian
- [ ] pagination
- [x] badges

## Examples

### Containers
```elixir
<Container.container max_width="full | lg | md | sm">
```
### Buttons

#### Button types
```elixir
<.button label="Button">
<.a href="/" label="a">
<.patch href="/" label="Live Patch">
<.redirect href="/" label="Live Redirect">
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
<.button disabled type="a" href="/" label="a Disabled" />
<.button disabled color="primary" label="Button Disabled" />
<.patch disabled href="/" label="Live Patch Disabled" />
<.redirect disabled href="/" label="Live Redirect" />
```

##### Loading
```elixir
<.button loading type="a" href="/" label="a Loading" />
<.button loading label="Button Loading" />
<.patch loading href="/" label="Live Patch Loading" />
<.redirect loading href="/" label="Live Redirect Loading" />
```

#### Button with icon
```elixir
<.button icon type="a" href="/">
  <Heroicons.Solid.home class="w-5 h-5" />
  a with label
</.button>
```

### Typography
```elixir
<.h1>Heading 1</.h1>
<.h2>Heading 2</.h2>
<.h3>Heading 3</.h3>
<.h4>Heading 4</.h4>
<.h5>Heading 5</.h5>
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

#### Text input
```html
<.text_input form={:user} field={:name} placeholder="eg. John" />

<!-- With a label and bottom margin -->
<div class="mb-6">
  <.form_label form={:user} field={:last_name} />
  <.text_input form={:user} field={:last_name} placeholder="eg. Smith" />
</div>

<!-- Includes label and bottom margin -->
<.form_field
  type="text_input"
  form={:user}
  field={:first_name}
/>
```

#### Text area
```html
<.textarea form={:user} field={:description} />

<!-- With a label and bottom margin -->
<div class="mb-6">
  <.form_label form={:user} field={:description} />
  <.textarea form={:user} field={:description} />
</div>

<!-- Includes label and bottom margin -->
<.form_field
  type="textarea"
  form={:user}
  field={:description}
/>
```

#### Select
```html
<.select
  options={["Admin": "admin", "User": "user"]}
  form={:user}
  field={:role}
/>

<!-- With a label and bottom margin -->
<div class="mb-6">
  <.form_label form={:user} field={:role} />
  <.select
    options={["Admin": "admin", "User": "user"]}
    form={:user}
    field={:role}
  />
</div>

<!-- Includes label and bottom margin -->
<.form_field
  type="select"
  form={:user}
  field={:first_name}
  options={["Admin": "admin", "User": "user"]}
/>
```

#### Checkbox
```html
<!-- Includes the label and margin automatically -->
<.checkbox
  form={:user}
  field={:read_terms}
  label="I accept"
/>
```

#### Radios
```html
<!-- A collection of radios - provide options like a select dropdown -->
<.radios
  form={:user}
  field={:eye_color}
  options={["Green": "green", "Blue": "blue", "Gray": "gray"]}
/>
```

### Dropdowns
```elixir
<.dropdown label="Dropdown">
  <.dropdown_menu_item type="button">
    <Heroicons.Outline.home class="w-5 h-5 text-gray-500" />
    Button item with icon
  </.dropdown_menu_item>
  <.dropdown_menu_item type="a" href="/" label="a item" />
  <.dropdown_menu_item type="live_patch" href="/" label="Live Patch item" />
  <.dropdown_menu_item type="live_redirect" href="/" label="Live Redirect item" />
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
