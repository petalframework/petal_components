# Upgrade Guide

## v0.17 to v0.18

This guide assumes you are also updating `phoenix_live_view` to `0.18.0`.

### Update mix.exs

```elixir
{:phoenix_live_view, "~> 0.18"},
{:petal_components, "~> 0.18"},
```

### Live View 0.18 updates

#### Phoenix.Component

Global replace: `Phoenix.LiveView.Helpers` --> `import Phoenix.Component`.

In some places you'll need to `import Phoenix.Component`. For example with `assign_new/3` calls.

#### Live title tag

`live_title_tag` is to be replaced with a component:

```html
<.live_title>
  <%= assigns[:page_title] || "Welcome" %>
</.live_title>
```

#### Renaming <.link>

Live View 0.18 deprecations:
  - `live_redirect` - deprecate in favor of new `<.link navigate={..}>` component of `Phoenix.Component`
  - `live_patch` - deprecate in favor of new `<.link patch={..}>` component of `Phoenix.Component`
  - `push_redirect` - deprecate in favor of new `push_navigate` function on `Phoenix.LiveView`

Petal Components has a `<.link>` component, but now Live View 0.18 has its own `<.link>`:

```
    <.link href="https://myapp.com">my app</.link>
    <.link navigate={@path}>remount</.link>
    <.link patch={@path}>patch</.link>
```

The attributes are a bit different to our link. So we renamed `<.link>` to `<.a>` to make it an easier upgrade.

Perform these global replaces:

```
`<.link` --> `<.a`
`</.link` --> `</.a`
```

This way, your app will still work with our `<a>` tags. However, we will eventually deprecate this in favour of the new Live View `<.link>`.

### Renaming Heroicons

PetalComponents now internally uses https://github.com/mveytsman/heroicons_elixir, which uses Heroicons V2. If you'd like to use Heroicons V2, then use this library.

Unfortunately Heroicons V2 renames a lot of icons and is kind of like another library. So we have renamed `PetalComponents.Heroicons` --> `PetalComponents.HeroiconsV1` for anyone who would like to continue using V1.

To keep using V1:

Do the global replaces:

```
Replace `PetalComponents.Heroicons` --> `PetalComponents.HeroiconsV1`
Replace `Heroicons.Solid` --> `HeroiconsV1.Solid`
Replace `Heroicons.Outline` --> `HeroiconsV1.Outline`
```

#### Icon Button

We can't use a dynamic `Heroicons.Solid.render/1` anymore so instead we need to pass in the icon as the default slot.

Old way:

```html
<.icon_button to="/" icon={:trash} />
```

New way:

```html
<.icon_button to="/">
  <Heroicons.trash solid />
<./icon_button>
```

### Alpine JS updates

You can't use the bind shortcuts in the latest Live View.

Old:
```html
<div :class="..."></div>
```

New
```html
<div x-bind:class="..."></div>
```

You can do this global replace: ` :class=` --> ` x-bind:class=`.
You'll have to do it for each attribute using this bind syntax, eg: ` :aria-expanded=` --> ` x-bind:aria-expanded=`

There could be many more if you use Alpine a lot.

