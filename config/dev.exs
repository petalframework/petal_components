import Config

# Tailwind config for the standalone dev server (dev.exs)
config :tailwind,
  version: "4.1.12",
  petal_dev: [
    args: ~w(--input=dev/app.css --output=priv/static/assets/app.css),
    cd: Path.expand("..", __DIR__)
  ]
