defmodule Tempo.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    base_children = [
      TempoWeb.Telemetry,
      {Phoenix.PubSub, name: Tempo.PubSub},
      Tempo.DataStore,
      TempoWeb.Endpoint
    ]

    mq_children =
      if Application.get_env(:tempo, :start_mq_clients, true) do
        [Tempo.MqClient, Tempo.MqWsClient]
      else
        []
      end

    children = base_children ++ mq_children

    opts = [strategy: :one_for_one, name: Tempo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TempoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
