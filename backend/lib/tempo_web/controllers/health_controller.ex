defmodule TempoWeb.HealthController do
  use TempoWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok", service: "tempo", version: "0.1.0"})
  end
end
