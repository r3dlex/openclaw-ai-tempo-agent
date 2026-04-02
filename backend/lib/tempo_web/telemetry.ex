defmodule TempoWeb.Telemetry do
  @moduledoc """
  Telemetry supervisor for the Tempo backend.

  Starts a `:telemetry_poller` that periodically emits VM metrics and
  defines the set of Phoenix/endpoint metrics exported to
  `Phoenix.LiveDashboard` and any attached reporters.
  """

  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc "Returns the list of Telemetry metrics to be reported."
  def metrics do
    [
      summary("phoenix.endpoint.start.system_time", unit: {:native, :millisecond}),
      summary("phoenix.endpoint.stop.duration", unit: {:native, :millisecond}),
      summary("phoenix.router_dispatch.stop.duration", unit: {:native, :millisecond})
    ]
  end

  defp periodic_measurements do
    []
  end
end
