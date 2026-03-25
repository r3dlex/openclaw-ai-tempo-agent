import Config

config :tempo, TempoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base:
    "dev_only_secret_key_base_that_is_long_enough_for_phoenix_requirements_64chars",
  watchers: []

config :tempo, :data_dir, Path.expand("../../data", __DIR__)

config :tempo, :augment,
  api_url: System.get_env("AUGMENT_API_URL", "https://api.augmentcode.com"),
  api_token: System.get_env("AUGMENT_API_TOKEN", "")

config :logger, :console, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
