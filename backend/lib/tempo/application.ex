defmodule Tempo.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TempoWeb.Telemetry,
      {Phoenix.PubSub, name: Tempo.PubSub},
      Tempo.MqClient,
      Tempo.MqWsClient,
      Tempo.DataStore,
      TempoWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Tempo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TempoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
