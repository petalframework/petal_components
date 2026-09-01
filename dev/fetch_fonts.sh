#!/bin/sh
# Vendored playground fonts - the Typeset dials' curated set. All OFL 1.1,
# single variable woff2 each (latin, wght axis only - opsz builds are ~3x
# larger for no playground benefit). Pinned at Fontsource 5.3.0; to bump,
# change the version below and re-run, then RENAME the files (dev-static has
# no cache busting - Safari caches stale bytes otherwise). Weight ranges and
# ids verified against api.fontsource.org - the id IS the slug for every
# pick (the one classic gotcha: Geist Sans is `geist`, not `geist-sans`).
set -eu
cd "$(dirname "$0")/static/fonts"
V=5.3.0
for id in inter geist manrope space-grotesk dm-sans figtree outfit public-sans nunito-sans montserrat ibm-plex-sans source-sans-3 fraunces source-serif-4 lora merriweather newsreader playfair-display roboto-slab jetbrains-mono geist-mono fira-code source-code-pro roboto-mono; do
  curl -fsSLO "https://cdn.jsdelivr.net/npm/@fontsource-variable/${id}@${V}/files/${id}-latin-wght-normal.woff2"
done
ls | wc -l
