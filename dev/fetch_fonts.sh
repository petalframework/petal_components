#!/bin/sh
# Vendored playground fonts - the Typeset dial's curated set. All OFL 1.1,
# single variable woff2 each (latin, wght axis only - the opsz builds of the
# serifs are ~3x larger for no playground benefit). Pinned at Fontsource
# 5.3.0; to bump, change the version below and re-run, then RENAME the files
# (dev-static has no cache busting - Safari caches stale bytes otherwise).
# Fontsource id gotcha: Geist Sans is `geist`, not `geist-sans`.
set -eu
cd "$(dirname "$0")/static/fonts"
V=5.3.0
for id in inter geist manrope space-grotesk fraunces source-serif-4 jetbrains-mono geist-mono; do
  curl -fsSLO "https://cdn.jsdelivr.net/npm/@fontsource-variable/${id}@${V}/files/${id}-latin-wght-normal.woff2"
done
ls -la
