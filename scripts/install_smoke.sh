#!/usr/bin/env bash
# Install smoke test: follow the install steps in usage-rules.md in a fresh
# Phoenix 1.8 app and prove the result works.
#
#   scripts/install_smoke.sh [petal_components checkout] [work dir]
#
# What it does, in order:
#   1. installs the phx_new archive into a private MIX_HOME (nothing global)
#   2. generates a fresh app with --no-ecto (no database needed) and runs
#      `mix deps.get`, so mix.lock holds what a new app really locks
#   3. copies the files the Hex package ships into deps/petal_components and
#      adds it as a path dependency, the layout a Hex install produces
#   4. runs `mix deps.get` again WITHOUT unlocking anything: a library
#      constraint that conflicts with a fresh app's lock fails here
#   5. applies exactly the edits usage-rules.md describes (app.css, the web
#      module's html_helpers, app.js, the two AGENTS.md lines)
#   6. adds a LiveView using <.button>, <.icon>, <.field>, <.table>, <.modal>
#   7. `mix compile --warnings-as-errors`, then a LiveViewTest that asserts
#      the library's markup rendered (with --warnings-as-errors)
#   8. builds the assets and greps the CSS and JS for the library's output
#
# If you change the install steps in usage-rules.md, change the matching
# edit here in the same commit. CI runs this on every pull request.
set -euo pipefail

PC_DIR=$(cd "${1:-$(dirname "$0")/..}" && pwd)
WORK=${2:-$(mktemp -d "${TMPDIR:-/tmp}/petal-install-smoke.XXXXXX")}
mkdir -p "$WORK"
WORK=$(cd "$WORK" && pwd)

# The generator is pinned; the app's own deps resolve as phx.new writes them.
PHX_NEW_VERSION=${PHX_NEW_VERSION:-1.8.16}
APP=smoke_app
MOD=SmokeApp
APP_DIR="$WORK/$APP"

# Run the app on the checkout's Elixir/OTP. asdf and mise read .tool-versions
# from the nearest parent dir, and the work dir is usually outside the repo.
if [ -f "$PC_DIR/.tool-versions" ] && [ ! -f "$WORK/.tool-versions" ]; then
  cp "$PC_DIR/.tool-versions" "$WORK/.tool-versions"
fi

export MIX_HOME="$WORK/mix_home"
export MIX_ARCHIVES="$MIX_HOME/archives"
unset MIX_ENV

step() { printf '\n==> %s\n' "$*"; }
fail() {
  printf '\nINSTALL SMOKE FAILED: %s\n' "$*" >&2
  exit 1
}

# replace_once FILE OLD NEW - fails unless OLD occurs exactly once in FILE,
# so a change in what phx.new generates stops the test instead of passing it.
replace_once() {
  elixir -e '
    [file, old, new] = System.argv()
    body = File.read!(file)

    case :binary.matches(body, old) do
      [_] ->
        File.write!(file, String.replace(body, old, new))

      found ->
        IO.puts(:stderr, "expected one #{inspect(old)} in #{file}, found #{length(found)}")
        System.halt(1)
    end
  ' "$1" "$2" "$3" || fail "could not edit $1 (see above)"
}

if [ -e "$APP_DIR" ]; then
  fail "$APP_DIR already exists; pass an empty work dir"
fi

step "petal_components under test: $PC_DIR"
step "work dir: $WORK"

step "Installing Hex, rebar and phx_new $PHX_NEW_VERSION into $MIX_HOME"
mix local.hex --force >/dev/null
mix local.rebar --force >/dev/null
mix archive.install hex phx_new "$PHX_NEW_VERSION" --force >/dev/null

step "Generating a fresh Phoenix app"
cd "$WORK"
mix phx.new "$APP" --no-ecto --no-install >/dev/null
cd "$APP_DIR"
mix deps.get >/dev/null
echo "fresh app locks: $(grep -o '"websock_adapter": {:hex, :websock_adapter, "[^"]*"' mix.lock || echo 'no websock_adapter')"

step "Copying the files the Hex package ships into deps/petal_components"
PACKAGE_FILES=$(elixir -e '
  [mix_exs] = System.argv()

  case Regex.run(~r/files:\s*~w\(([^)]*)\)/, File.read!(mix_exs)) do
    [_, files] -> IO.puts(files)
    nil -> System.halt(1)
  end
' "$PC_DIR/mix.exs") || fail "could not read the package files list from $PC_DIR/mix.exs"
mkdir -p deps/petal_components
for f in $PACKAGE_FILES; do
  [ -e "$PC_DIR/$f" ] || fail "mix.exs ships $f but $PC_DIR/$f does not exist"
  cp -R "$PC_DIR/$f" deps/petal_components/
done

step "Step 1: add the dependency"
replace_once mix.exs '  defp deps do
    [
' '  defp deps do
    [
      {:petal_components, path: "deps/petal_components"},
'

step "Step 2: mix deps.get, with the fresh lock and nothing unlocked"
if ! mix deps.get; then
  fail "mix deps.get failed in a fresh Phoenix app. A dependency petal_components declares conflicts with what phx.new locks."
fi

step "Step 3: Tailwind lines below the existing import"
replace_once assets/css/app.css '@import "tailwindcss" source(none);
' '@import "tailwindcss" source(none);
@source "../../deps/petal_components/**/*.*ex";
@source not "../../deps/petal_components/lib/petal_components/showcase";
@import "../../deps/petal_components/assets/default.css";
@plugin "@tailwindcss/forms";
'
imports=$(grep -c '^@import "tailwindcss"' assets/css/app.css || true)
[ "$imports" = 1 ] || fail "app.css has $imports @import \"tailwindcss\" lines, expected 1"

step "Step 4: use PetalComponents in html_helpers, CoreComponents without the four shared names"
replace_once "lib/${APP}_web.ex" "      import ${MOD}Web.CoreComponents
" "      use PetalComponents
      import ${MOD}Web.CoreComponents, except: [button: 1, icon: 1, input: 1, table: 1]
"

step "Step 5: register the JS hooks"
replace_once assets/js/app.js 'import {LiveSocket} from "phoenix_live_view"
' 'import {LiveSocket} from "phoenix_live_view"
import PetalComponents from "../../deps/petal_components/assets/js/petal_components"
'
replace_once assets/js/app.js 'hooks: {...colocatedHooks},' 'hooks: {...colocatedHooks, ...PetalComponents},'

step "Step 6: correct the two AGENTS.md lines phx.new wrote about <.icon> and <.input>"
replace_once AGENTS.md '- Out of the box, `core_components.ex` imports an `<.icon name="hero-x-mark" class="w-5 h-5"/>` component for hero icons. **Always** use the `<.icon>` component for icons, **never** use `Heroicons` modules or similar' \
  '- `<.icon>` comes from petal_components (`use PetalComponents` in `html_helpers`). Use `<.icon name="hero-x-mark" class="w-5 h-5" />` for hero icons, **never** `Heroicons` modules or similar'
replace_once AGENTS.md '- **Always** use the imported `<.input>` component for form inputs from `core_components.ex` when available. `<.input>` is imported and using it will save steps and prevent errors' \
  '- Form fields use petal_components `<.field field={@form[:name]} label="..." />` (label, input, errors and help text). `<.input>` is the petal_components bare input and renders no label'

step "Adding a LiveView that uses the components"
mkdir -p "lib/${APP}_web/live" "test/${APP}_web/live"
cat >"lib/${APP}_web/live/smoke_live.ex" <<EOF
defmodule ${MOD}Web.SmokeLive do
  use ${MOD}Web, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       form: to_form(%{"email" => ""}, as: :signup),
       users: [%{id: 1, name: "Ada", email: "ada@example.com"}]
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.button id="save" phx-click="noop">
        <.icon name="hero-check-micro" /> Save
      </.button>
      <.form for={@form} id="signup-form" phx-submit="noop">
        <.field field={@form[:email]} type="email" label="Email address" />
      </.form>
      <.table id="users" rows={@users}>
        <:col :let={user} label="Name">{user.name}</:col>
        <:col :let={user} label="Email">{user.email}</:col>
      </.table>
      <.modal id="smoke-modal" title="Hello">Modal body</.modal>
    </Layouts.app>
    """
  end

  def handle_event("noop", _params, socket), do: {:noreply, socket}
end
EOF
replace_once "lib/${APP}_web/router.ex" '    get "/", PageController, :home
' '    get "/", PageController, :home
    live "/smoke", SmokeLive
'

cat >"test/${APP}_web/live/smoke_live_test.exs" <<EOF
defmodule ${MOD}Web.SmokeLiveTest do
  use ${MOD}Web.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "petal_components render inside a LiveView", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/smoke")

    for class <- ~w(pc-button pc-form-field pc-text-input pc-table--basic pc-modal) do
      assert html =~ class, "rendered page has no #{class}"
    end

    assert has_element?(view, "button#save.pc-button")
    assert has_element?(view, "button#save span.hero-check-micro")
    assert has_element?(view, "label", "Email address")
    assert has_element?(view, "input.pc-text-input[name='signup[email]']")
    assert has_element?(view, "table.pc-table--basic td", "ada@example.com")
    assert has_element?(view, "#smoke-modal")

    # The generated CoreComponents versions must not be the ones that ran.
    refute has_element?(view, "button#save.btn")
    refute has_element?(view, "#signup-form .fieldset")
    refute has_element?(view, "table.table")
  end
end
EOF

step "Compiling with --warnings-as-errors"
mix compile --warnings-as-errors

step "LiveViewTest"
mix test --warnings-as-errors

step "Building assets"
mix assets.setup >/dev/null
mix assets.build

CSS=priv/static/assets/css/app.css
JS=priv/static/assets/js/app.js
for selector in .pc-button .pc-card__header .pc-text-input; do
  grep -qF -- "$selector" "$CSS" || fail "built $CSS has no $selector"
done
grep -qF PetalComboBox "$JS" || fail "built $JS has no petal_components hooks"
echo "built CSS: $(grep -oF .pc-button "$CSS" | wc -l | tr -d ' ') .pc-button, $(grep -oF .pc-card__header "$CSS" | wc -l | tr -d ' ') .pc-card__header"

printf '\nINSTALL SMOKE PASSED (%s)\n' "$APP_DIR"
