import Config

config :phoenix, :json_library, Jason

env_config = "#{config_env()}.exs"

if File.exists?(Path.expand(env_config, __DIR__)) do
  import_config env_config
end
