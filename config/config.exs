import Config

config :phoenix, :json_library, Jason

File.exists?("config/#{config_env()}.exs") && import_config "#{config_env()}.exs"
