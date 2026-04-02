defmodule TempoWeb.Endpoint do
  @moduledoc """
  Phoenix Endpoint for the Tempo backend.

  Configures static file serving, request parsing, session management,
  CORS (allowing the Angular dashboard on ports 4200 and 4000), and
  routes all requests through `TempoWeb.Router`.
  """

  use Phoenix.Endpoint, otp_app: :tempo

  @session_options [
    store: :cookie,
    key: "_tempo_key",
    signing_salt: "tempo_sign",
    same_site: "Lax"
  ]

  plug Plug.Static,
    at: "/",
    from: :tempo,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)

  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug CORSPlug, origin: ["http://localhost:4200", "http://localhost:4000"]
  plug TempoWeb.Router

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)
end
