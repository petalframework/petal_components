import Config

config :phoenix, :json_library, Jason

if File.exists?("config/#{config_env()}.exs"), do: import_config "#{config_env()}.exs"
