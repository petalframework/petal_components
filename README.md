<p align="center">
  <img src="https://res.cloudinary.com/wickedsites/image/upload/v1635752721/petal/logo_rh2ras.png" height="128">
  <h1 align="center">Petal Components</h1>
</p>

<p align="center">
  <a href="https://opensource.org/licenses/MIT" alt="MIT">
    <img src="https://img.shields.io/badge/license-MIT-green" />
  </a>
</p>

<p align="center">
  <a href="https://petal-components-demo.fly.dev">
    DEMO
  </a>
</p>

<p align="center">
  Petal is a set of HEEX components that makes it easy for Phoenix developers to start building beautiful web apps.
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

For full documentation, visit [petal.build](https://petal.build/docs).

## Try it out

We have a fresh [Phoenix boilerplate template](https://github.com/petalframework/petal_boilerplate) with Petal Components ready to go if you would like to get your hands dirty. 

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
- [x] cards
- [x] breadcrumbs
- [x] modal
- [ ] slide over
- [x] spinners
- [ ] accordian
- [x] pagination
- [x] badges
- [x] progress
- [x] links

## Contributing

Feel free to open a Github issue in this project.

If you'd like to help out we've got a [Phoenix umbrella app](https://github.com/petalframework/petal_development) that allows you to easily contribute to Petal Components (which is installed as a git submodule).
