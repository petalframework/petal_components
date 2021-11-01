<p align="center">
  <img src="logo.png" height="128">
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
  <img src="screenshot.png" height="1200">
</p>

## Install

For Petal to work you simply need Tailwind CSS and Alpine JS installed along with with some Tailwind configuration.

### Existing projects

Follow [this guide](https://sergiotapia.com/phoenix-160-liveview-esbuild-tailwind-jit-alpinejs-a-brief-tutorial) to install Tailwind and Alpine.

Then add Petal to your deps:

`mix.exs`

```elixir
defp deps do
  [
    {:petal_components, "~> 0.1.0"},
  ]
end
```

### New projects

We recommend using [Petal boilerplate](https://github.com/petalframework/petal_boilerplate), which is a fresh Phoenix install with Tailwind + Alpine installed. It comes with a project renaming script so you can still rename your project to whatever you like.

### Configuration

Modify your `tailwind.config.js` file to include these settings:

```js
const colors = require("tailwindcss/colors");

module.exports = {
  mode: "jit",
  // We need to include the Petal dependency so the classes get picked up by JIT.
  purge: ["../lib/*_web/**/*.*ex", "./js/**/*.js", "../deps/petal/**/*.*ex"],
  darkMode: false,
  theme: {
    extend: {
      colors: {
        // Set these to your brand colors
        primary: colors.blue,
        secondary: colors.pink,
      },
    },
  },
  variants: {
    extend: {
      cursor: ["disabled"],
    },
  },
  plugins: [require("@tailwindcss/forms")],
};

```

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
- [ ] menu dropdown
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
