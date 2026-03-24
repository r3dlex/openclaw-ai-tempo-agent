import Config

config :tempo,
  generators: [timestamp_type: :utc_datetime]

config :tempo, TempoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: TempoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Tempo.PubSub,
  live_view: [signing_salt: "tempo_salt"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
