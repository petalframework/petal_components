import Config

config :wallaby, :chromedriver,
  binary: System.get_env("CHROMEDRIVER", "/usr/bin/chromedriver")
