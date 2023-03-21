<p align="center">
  <img src="https://res.cloudinary.com/wickedsites/image/upload/v1635752721/petal/logo_rh2ras.png" height="128">

  <h1 align="center">Petal Components</h1>

<p align="center">
  <a href="https://petal.build">petal.build</a>
</p>

  <p align="center">
    Petal is a set of HEEX components that makes it easy for Phoenix developers to build beautiful web apps. Think Bootstrap or MUI, but written in HEEX using Tailwind CSS classes.
  </p>
</p>

<p align="center">
  <a href="https://hex.pm/packages/petal_components">
    <img alt="Hex Version" src="https://img.shields.io/hexpm/v/petal_components.svg">
  </a>
  <a href="https://hexdocs.pm/petal_components">
    <img alt="Hex Docs" src="https://img.shields.io/hexpm/dt/petal_components.svg?style=flat">
  </a>
  <a href="https://opensource.org/licenses/MIT" alt="MIT">
    <img src="https://img.shields.io/badge/license-MIT-green" />
  </a>
  <a href="https://codecov.io/gh/petalframework/petal_components" >
    <img src="https://codecov.io/gh/petalframework/petal_components/branch/main/graph/badge.svg?token=47KQGJOT1G"/>
  </a>
</p>

<p align="center">
  <a href="https://petal-components-demo.fly.dev">
    <img src="https://res.cloudinary.com/nhobes/image/upload/v1664493810/Petal_Components/Xnapper-2022-09-30-09.22.58_qufkq8.png" height="300" />
  </a>
  <a href="https://petal-components-demo.fly.dev">
    <img src="https://res.cloudinary.com/nhobes/image/upload/v1664493101/Petal_Components/Xnapper-2022-09-30-09.02.10_q5hkri.png" height="300" />
  </a>
</p>

<p align="center">
  <a href="https://petal.build/components">View the docs</a>
</p>

## About

Petal stands for:

* [Phoenix](https://www.phoenixframework.org/)
* [Elixir](https://elixir-lang.org/)
* [Tailwind CSS](https://tailwindcss.com/)
* [Alpine JS](https://alpinejs.dev/) (optional)
* [Live View (HEEX)](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html)

Some components like Dropdowns require Javascript to work. We default to Alpine JS (17kb) but you can choose to use `Phoenix.LiveView.JS` as an alternative (though this will only work in live environments like live views or live components).

## Documentation

For full documentation, visit [petal.build](https://petal.build/components).

## Try it out

We have a fresh [Phoenix boilerplate template](https://github.com/petalframework/petal_boilerplate) with Petal Components ready to go if you would like to get your hands dirty.

## VSCode Snippets Extension

Install our [VSCode extension](https://marketplace.visualstudio.com/items?itemName=petalframework.vscode-petal-components-snippets&ssr=false#overview) to gain access to 65+ snippets for all of the components.

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
- [x] time, datetime, & date input
- [x] multiple select (see checkbox group)
- [x] switch
- [x] input help text
- [ ] input prefix and postfix

### Buttons
- [x] basic button
- [x] change size
- [x] change color
- [x] loading state (with spinner)
- [x] filled vs outline
- [ ] button group

### Misc
- [x] menu dropdown
- [x] avatar
- [x] alerts
- [x] tables
- [x] cards
- [x] breadcrumbs
- [x] modal
- [x] slide over
- [x] spinners
- [x] accordion
- [x] pagination
- [x] badges
- [x] progress
- [x] links
- [ ] tooltips

## FAQ

**Q: Do I need Alpine JS?**
A: No we have designed the components to use either Alpine JS or LiveView.JS.

**Q: What if I want to use my own components too?**
A: You can install this library and import only the components you need.

```elixir
# The recommended option is to import every single component
use PetalComponents

# But you can get more granular. eg.

# Import Button so you can now create `<.button>` components
import PetalComponents.Button

# Or just alias if you already have a `def button` HEEX component. With alias you now write the Petal component like this: `<Button.button>`
alias PetalComponents.Button
```

**Q: Does this increase my CSS filesize?**
A: Tailwind will scan any folders you specify and hoover up CSS classes from files to include in your final CSS file. You specify the folders in `tailwind.config.js`. By default, we instruct you to just scan the whole Petal Components library:

```js
const colors = require("tailwindcss/colors");

module.exports = {
  purge: [
    "../lib/*_web/**/*.*ex",
    "./js/**/*.js",

    // We need to include the Petal dependency so the classes get picked up by JIT.
    "../deps/petal_components/**/*.*ex"
  ],

  ... rest of file omitted
```

You might be worried that if you don't use every component you'll have unused CSS classes. But we believe it's so small it won't matter. Our petal.build site's CSS file totals just 25kb.

If you really want to you can instruct Tailwind to just scan the components you use:

```
"../deps/petal_components/lib/button.ex",
"../deps/petal_components/lib/alert.ex",
```

**Q: Can I customize the components?**
A: Yes! You can customize the components by overriding the CSS classes. For example, if you want to change the color of the button you can do this:

```css
.pc-button {
  @apply inline-flex items-center justify-center font-semibold tracking-wider uppercase transition duration-150 ease-in-out border-2 rounded-none focus:outline-none;
}
.pc-button--primary {
  @apply text-black border-black bg-primary-400 hover:bg-primary-700 focus:bg-primary-700 active:bg-primary-800 focus:shadow-primary-500/50;
}
```

## Contributing

If you'd like to help out we've got a [Phoenix umbrella app](https://github.com/petalframework/petal_development) that allows you to easily contribute to Petal Components (which is installed as a git submodule). If you create a new component then feel free to submit a PR. Ideally one from the roadmap but we're open to any new components that would benefit others!

