# Deployed component playground (playground.petal.build).
#
# This intentionally runs MIX_ENV=dev: the playground IS the dev server
# (dev.exs + phoenix_playground), just with the dev conveniences switched
# off via PLAYGROUND_DEPLOY=true (no code reloader, no live reload, no
# tailwind watcher, real secret_key_base). Every runtime dep it needs is
# scoped `only: :dev` in mix.exs, so a prod build would have nothing to run.
FROM hexpm/elixir:1.17.2-erlang-26.2.1-debian-bookworm-20260610-slim

# git: heroicons is a github dep. build-essential: NIF fallback compiles
# (lazy_html) when a precompiled binary isn't available for this target.
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends git ca-certificates build-essential && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# MIX_HOME/HEX_HOME live under /app so the runtime user can read them -
# the default is /root/.mix, which becomes unreadable after the USER drop
# and `mix run` still consults it at boot.
ENV MIX_ENV=dev \
    LANG=C.UTF-8 \
    OPEN_BROWSER=false \
    MIX_HOME=/app/.mix \
    HEX_HOME=/app/.hex

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only dev

COPY config config
RUN mix deps.compile

# Fetch the linux tailwind binary at build time so first boot doesn't
# download it (dev.exs runs the tailwind task on every start).
RUN mix tailwind.install --if-missing

COPY lib lib
COPY assets assets
COPY priv priv
COPY dev dev
COPY dev.exs ./

RUN mix compile

# Public app: don't run as root, and own only what boot actually writes -
# priv/static (tailwind CSS output), dev (generated heroicons.css) and
# _build. Source, deps and mix files stay root-owned read-only.
# _build stays writable ON PURPOSE: the entrypoint is `mix run`, and Mix
# (1.17) takes file locks under the build path on every invocation, so a
# read-only _build can crash boot. The marginal risk (overwriting compiled
# beams) buys nothing here - an attacker positioned to do that is already
# executing inside the BEAM. --create-home because the BEAM writes
# ~/.erlang.cookie on first start.
# mkdir first: priv/static only holds generated output, which .dockerignore
# keeps out of the context, so the directory may not exist yet.
RUN useradd --system --create-home --shell /usr/sbin/nologin playground && \
    mkdir -p /app/priv/static/assets && \
    chown -R playground:playground /app/priv/static /app/dev /app/_build
USER playground

EXPOSE 8080

CMD ["mix", "run", "--no-halt", "dev.exs"]
