# Upgrade Guide

## v2.8.4 to v2.9.0

Petal Components has been upgraded to Tailwind 4. Some utilities have been removed or renamed. See the [Tailwind upgrade guide](https://tailwindcss.com/docs/upgrade-guide) for more information.

To upgrade to Tailwind 4 in your project, make sure you update `mix.exs`:

```diff
-  {:tailwind, "~> 0.2", runtime: Mix.env() == :dev}
+  {:tailwind, "~> 0.3", runtime: Mix.env() == :dev}
```

And `config.exs` (note that the paths have changed and that you need 4.0.9 or above):

```diff
config :tailwind,
-  version: "3.3.3",
+  version: "4.0.9",
   default: [
     args: ~w(
-      --config=tailwind.config.js
-      --input=css/app.css
-      --output=../priv/static/assets/app.css
+      --input=assets/css/app.css
+      --output=priv/static/assets/app.css
     ),
-    cd: Path.expand("../assets", __DIR__)
+    cd: Path.expand("..", __DIR__)
  ]
```

Don't forget to run:

```bash
mix tailwind.install
```

`tailwind.config.js` is now considered legacy and is no longer automatically loaded. However, it is still supported and you can manually load it by adding the following to your `app.css`:

```CSS
@config "../tailwind.config.js";
```

Now you should be able to follow the [Tailwind upgrade guide](https://tailwindcss.com/docs/upgrade-guide) to update your project.

### Petal Components CSS configuration

Here are some tips on how to integrate Petal Components if you are no longer using the `tailwind.config.js` file.

To reference Petal Components CSS and include it as a source for Tailwind utility classes, use the `@source` and `@import` directives:

```CSS
@import "tailwindcss";

@source "../../deps/petal_components/**/*.*ex";
@import "../../deps/petal_components/assets/default.css";
```

The CSS file equivalent of `darkMode: 'class'` is:

```CSS
@custom-variant dark (&:where(.dark, .dark *));
```

In Tailwind 4 buttons now use `cursor: default` instead of `cursor: pointer`. If you would like the old behaviour:

```CSS
@layer base {
  /* Use the pointer for buttons */
  button:not(:disabled),
  [role="button"]:not(:disabled) {
    cursor: pointer;
  }
}
```

To configure Petal Component colours add an `@import`:

```CSS
@import "./colors.css";
```

Then create the `colors.css` file:

```CSS
@theme inline {
  --color-primary-50: var(--color-blue-50);
  --color-primary-100: var(--color-blue-100);
  --color-primary-200: var(--color-blue-200);
  --color-primary-300: var(--color-blue-300);
  --color-primary-400: var(--color-blue-400);
  --color-primary-500: var(--color-blue-500);
  --color-primary-600: var(--color-blue-600);
  --color-primary-700: var(--color-blue-700);
  --color-primary-800: var(--color-blue-800);
  --color-primary-900: var(--color-blue-900);
  --color-primary-950: var(--color-blue-950);

  --color-secondary-50: var(--color-pink-50);
  --color-secondary-100: var(--color-pink-100);
  --color-secondary-200: var(--color-pink-200);
  --color-secondary-300: var(--color-pink-300);
  --color-secondary-400: var(--color-pink-400);
  --color-secondary-500: var(--color-pink-500);
  --color-secondary-600: var(--color-pink-600);
  --color-secondary-700: var(--color-pink-700);
  --color-secondary-800: var(--color-pink-800);
  --color-secondary-900: var(--color-pink-900);
  --color-secondary-950: var(--color-pink-950);

  --color-success-50: var(--color-green-50);
  --color-success-100: var(--color-green-100);
  --color-success-200: var(--color-green-200);
  --color-success-300: var(--color-green-300);
  --color-success-400: var(--color-green-400);
  --color-success-500: var(--color-green-500);
  --color-success-600: var(--color-green-600);
  --color-success-700: var(--color-green-700);
  --color-success-800: var(--color-green-800);
  --color-success-900: var(--color-green-900);
  --color-success-950: var(--color-green-950);

  --color-danger-50: var(--color-red-50);
  --color-danger-100: var(--color-red-100);
  --color-danger-200: var(--color-red-200);
  --color-danger-300: var(--color-red-300);
  --color-danger-400: var(--color-red-400);
  --color-danger-500: var(--color-red-500);
  --color-danger-600: var(--color-red-600);
  --color-danger-700: var(--color-red-700);
  --color-danger-800: var(--color-red-800);
  --color-danger-900: var(--color-red-900);
  --color-danger-950: var(--color-red-950);

  --color-warning-50: var(--color-yellow-50);
  --color-warning-100: var(--color-yellow-100);
  --color-warning-200: var(--color-yellow-200);
  --color-warning-300: var(--color-yellow-300);
  --color-warning-400: var(--color-yellow-400);
  --color-warning-500: var(--color-yellow-500);
  --color-warning-600: var(--color-yellow-600);
  --color-warning-700: var(--color-yellow-700);
  --color-warning-800: var(--color-yellow-800);
  --color-warning-900: var(--color-yellow-900);
  --color-warning-950: var(--color-yellow-950);

  --color-info-50: var(--color-sky-50);
  --color-info-100: var(--color-sky-100);
  --color-info-200: var(--color-sky-200);
  --color-info-300: var(--color-sky-300);
  --color-info-400: var(--color-sky-400);
  --color-info-500: var(--color-sky-500);
  --color-info-600: var(--color-sky-600);
  --color-info-700: var(--color-sky-700);
  --color-info-800: var(--color-sky-800);
  --color-info-900: var(--color-sky-900);
  --color-info-950: var(--color-sky-950);

  --color-gray-50: var(--color-slate-50);
  --color-gray-100: var(--color-slate-100);
  --color-gray-200: var(--color-slate-200);
  --color-gray-300: var(--color-slate-300);
  --color-gray-400: var(--color-slate-400);
  --color-gray-500: var(--color-slate-500);
  --color-gray-600: var(--color-slate-600);
  --color-gray-700: var(--color-slate-700);
  --color-gray-800: var(--color-slate-800);
  --color-gray-900: var(--color-slate-900);
  --color-gray-950: var(--color-slate-950);
}
```

To add the "typography" and "form" plug-ins:

```CSS
@plugin "@tailwindcss/typography";
@plugin "@tailwindcss/forms";
```

To re-create the heroicons JavaScript:

```CSS
@plugin "./tailwind_heroicons.js";
```

Then create the `tailwind_heroicons.js` file:

```JavaScript
const plugin = require("tailwindcss/plugin");
const fs = require("fs");
const path = require("path");

// Embeds Heroicons (https://heroicons.com) into your app.css bundle
// See your `CoreComponents.icon/1` for more information.
module.exports = plugin(function ({ matchComponents, theme }) {
  let iconsDir = path.join(__dirname, "../../deps/heroicons/optimized");
  let values = {};
  let icons = [
    ["", "/24/outline"],
    ["-solid", "/24/solid"],
    ["-mini", "/20/solid"],
    ["-micro", "/16/solid"],
  ];
  icons.forEach(([suffix, dir]) => {
    fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
      let name = path.basename(file, ".svg") + suffix;
      values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
    });
  });
  matchComponents(
    {
      hero: ({ name, fullPath }) => {
        let content = fs
          .readFileSync(fullPath)
          .toString()
          .replace(/\r?\n|\r/g, "");
        let size = theme("spacing.6");
        if (name.endsWith("-mini")) {
          size = theme("spacing.5");
        } else if (name.endsWith("-micro")) {
          size = theme("spacing.4");
        }
        return {
          [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
          "-webkit-mask": `var(--hero-${name})`,
          mask: `var(--hero-${name})`,
          "mask-repeat": "no-repeat",
          "background-color": "currentColor",
          "vertical-align": "middle",
          display: "inline-block",
          width: size,
          height: "1lh",
        };
      },
    },
    { values },
  );
});
```

## v1.4 to v1.5

v1.5 requires Tailwind v3.3.3. Update the version in `config.exs`:

```elixir
config :tailwind,
  version: "3.3.3",
```

Then run `mix tailwind.install`.

## v0.19 to v1.0.0

In `tailwind.config.js` you need to add more colors:

```js

  theme: {
    extend: {

      colors: {
        primary: colors.blue,
        secondary: colors.pink,

        // ADD THESE COLORS (can pick different ones from here: https://tailwindcss.com/docs/customizing-colors)
        success: colors.green,
        danger: colors.red,
        warning: colors.yellow,
        info: colors.sky,

        // Options: slate, gray, zinc, neutral, stone
        gray: colors.gray,
      },
    },
  },
```

NOTE: If you are supplying your own colours, they will require keys for different shades.

In your `app.css` you need to import the default Petal Components CSS:

```css
@import "tailwindcss/base";
@import "../../deps/petal_components/assets/default.css";
@import "tailwindcss/components";
@import "tailwindcss/utilities";
```

Update tailwind and esbuild dependencies:

```
mix deps.update esbuild
mix deps.update tailwind
```

In your `config.exs`, update tailwind and esbuild to more recent versions:

```elixir
config :esbuild,
  version: "0.15.5",
  default: [
  ...


config :tailwind,
  version: "3.3.3",
  default: [
  ...
```

Update tailwind and esbuild binaries:

```
mix esbuild.install
mix tailwind.install
```

## v0.18 to v0.19

There should be no breaking changes. This provides declarative assigns for all components so you should get warnings if you don't pass the right attributes.

### Using with Phoenix 1.7

Petal Components work fine with Phoenix 1.7 - there just will be some naming conflicts as the Phoenix generator now creates a file called `core_components.ex`, which has some function components defined in there.

To fix, go to the generated `core_components.ex` file and rename or remove the following functions: `modal`, `button` and `table`.

Unfortunately, this means the generators like `mix phx.gen.live` won't work properly. If you want generators for Petal Components, look into buying [Petal Pro](https://petal.build).

For a full upgrade commit of Phoenix 1.6 to 1.7 you can see [here](https://github.com/petalframework/petal_boilerplate/commit/dfd122902b2f1730f122efafc3d6962c2a6ce91d) how we did it with Petal Boilerplate.

If you want to pick and choose which components to use, you could namespace Petal Components.

```
defmodule PC do
  use PetalComponents
end
```

Then there would be no naming conflicts. But you would have to use the module for every component: `<PC.button></PC.button>` etc.

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

PetalComponents now internally uses https://github.com/mveytsman/heroicons_elixir, which uses Heroicons V2.

Unfortunately Heroicons V2 renames a lot of icons and is kind of like another library. So we have renamed `PetalComponents.Heroicons` --> `PetalComponents.HeroiconsV1` for anyone who would like to continue using V1.

#### To keep using V1:

Do the global replaces:

```
Replace `PetalComponents.Heroicons` --> `PetalComponents.HeroiconsV1`
Replace `Heroicons.Solid` --> `HeroiconsV1.Solid`
Replace `Heroicons.Outline` --> `HeroiconsV1.Outline`
```

#### To use V2:

Delete all references to `PetalComponents.Heroicons`.

For every case you have used a Heroicon in a HEEX template you will have to update to the new syntax defined here: https://github.com/mveytsman/heroicons_elixir

Eg.

```html
<!-- Old way -->
<Heroicons.Solid.home class="" />

<!-- New way -->
<Heroicons.home solid class="" />
```

Note the `solid` attribute. For `outline`, you don't need any attributes.

The most annoying part is that a lot of the icon names have changed. You can see a list of the all the name changes here: https://github.com/tailwindlabs/heroicons/releases/tag/v2.0.0

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
