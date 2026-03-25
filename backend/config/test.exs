import Config

config :tempo, TempoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base:
    "test_only_secret_key_base_that_is_long_enough_for_phoenix_requirements_64chars",
  server: false

config :tempo, :data_dir, Path.expand("../../data", __DIR__)

config :tempo, :augment,
  api_url: "http://localhost:8081",
  api_token: "test_token"

config :logger, level: :warning
