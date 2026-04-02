defmodule TempoWeb.HealthController do
  @moduledoc """
  Phoenix controller for the health-check endpoint.

  Returns a simple JSON response confirming the service is running and its
  current version. Used by load balancers and orchestration tools.
  """

  use TempoWeb, :controller

  @doc """
  Returns `{"status": "ok", "service": "tempo", "version": "0.1.0"}`.
  """
  def index(conn, _params) do
    json(conn, %{status: "ok", service: "tempo", version: "0.1.0"})
  end
end
