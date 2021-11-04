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

## Install

For Petal to work you simply need Tailwind CSS and Alpine JS installed along with with some Tailwind configuration.

### Existing projects

1 - Follow [this guide](https://sergiotapia.com/phoenix-160-liveview-esbuild-tailwind-jit-alpinejs-a-brief-tutorial) to install Tailwind and Alpine.

2 - Add Petal to your deps:

`mix.exs`

```elixir
defp deps do
  [
    {:petal_components, "~> 0.2.1"},
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
      
      alias PetalComponents.{
        Container,
        Typography,
        Heroicons,
        Button,
        Badge,
        Alert,
        Form,
        Dropdown,
        Loading
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
<Button.button label="Button">
<Button.a href="/" label="a">
<Button.patch href="/" label="Live Patch">
<Button.redirect href="/" label="Live Redirect">
```

#### Button colors
```elixir
<Button.button color="primary | secondary | white | success | danger" label="Primary" />
```

#### Button colors (outline)
```elixir
<Button.button color="primary | secondary | white | success | danger" label="Primary" variant="outline" />
```

#### Button sizes
```elixir
<Button.button size="sm | md | lg | xl">
```

#### Button states

##### Disabled
```elixir
<Button.button disabled type="a" href="/" label="a Disabled" />
<Button.button disabled color="primary" label="Button Disabled" />
<Button.patch disabled href="/" label="Live Patch Disabled" />
<Button.redirect disabled href="/" label="Live Redirect" />
```

##### Loading
```elixir
<Button.button loading type="a" href="/" label="a Loading" />
<Button.button loading label="Button Loading" />
<Button.patch loading href="/" label="Live Patch Loading" />
<Button.redirect loading href="/" label="Live Redirect Loading" />
```

#### Button with icon
```elixir
<Button.button icon type="a" href="/">
  <Heroicons.Solid.home class="w-5 h-5" />
  a with label
</Button.button>
```

### Typography
```elixir
<Typography.h1>Heading 1</Typography.h1>
<Typography.h2>Heading 2</Typography.h2>
<Typography.h3>Heading 3</Typography.h3>
<Typography.h4>Heading 4</Typography.h4>
<Typography.h5>Heading 5</Typography.h5>
```

### Heroicons

#### Heroicons solid
```elixir
<Heroicons.Solid.home class="w-6 h-6 text-blue-500" />
```

#### Heroicons outline
```elixir
<Heroicons.Outline.home class="w-6 h-6 text-blue-500" />
```

### Badges
```elixir
<Badge.badge color="primary | secondary | White | Black | Green | Red | Blue | Gray | Light Gray | Pink | Purple | Orange | Yellow" label="Primary" />
```
### Alerts

#### Info alert
```elixir
<Alert.alert state="info">
  This is an info state
</Alert.alert>
```

#### Success alert
```elixir
<Alert.alert state="success" label="This is a success state" />
```

#### Warning alert
```elixir
<Alert.alert state="warning" label="This is a warning state" />
```

#### Danger alert
```elixir
<Alert.alert state="danger" label="This is a danger state" />
```

### Forms

#### Text input
```elixir
<Form.text_input form={:user} field={:name} placeholder="eg. John" />
```

#### Text area
```elixir
<Form.textarea form={:user} field={:description} />
```

#### Select
```elixir
<Form.select
  options={["Admin": "admin", "User": "user"]}
  form={:user}
  field={:role}
/>
```

#### Radios
```elixir
<Form.radios
  form={:user}
  field={:eye_color}
  options={["Green": "green", "Blue": "blue", "Gray": "gray"]}
/>
```

### Dropdowns
```elixir
<Dropdown.dropdown label="Dropdown">
  <Dropdown.dropdown_menu_item type="button">
    <Heroicons.Outline.home class="w-5 h-5 text-gray-500" />
    Button item with icon
  </Dropdown.dropdown_menu_item>
  <Dropdown.dropdown_menu_item type="a" href="/" label="a item" />
  <Dropdown.dropdown_menu_item type="live_patch" href="/" label="Live Patch item" />
  <Dropdown.dropdown_menu_item type="live_redirect" href="/" label="Live Redirect item" />
</Dropdown.dropdown>
```
