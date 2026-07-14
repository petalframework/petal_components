import Config

config :phoenix, :json_library, Jason

# Compile mdex's native NIF with the Lumis syntax highlighter so the dev
# playground highlights chat code blocks. This config lives here (not shipped
# in the Hex package); consumers who want highlighting add {:lumis, ...} and
# this same config in their own app - the chat falls back to plain otherwise.
config :mdex_native, syntax_highlighter: :lumis

env_config = "#{config_env()}.exs"

if File.exists?(Path.expand(env_config, __DIR__)) do
  import_config env_config
end
