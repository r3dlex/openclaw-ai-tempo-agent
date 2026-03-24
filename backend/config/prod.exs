import Config

config :tempo, TempoWeb.Endpoint,
  url: [host: System.get_env("PHX_HOST", "localhost"), port: 443, scheme: "https"],
  http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT", "4000"))],
  secret_key_base: System.get_env("SECRET_KEY_BASE")

config :tempo, :data_dir, System.get_env("DATA_DIR", "/app/data")

config :tempo, :augment,
  api_url: System.get_env("AUGMENT_API_URL", "https://api.augmentcode.com"),
  api_token: System.get_env("AUGMENT_API_TOKEN")

config :logger, level: :info
