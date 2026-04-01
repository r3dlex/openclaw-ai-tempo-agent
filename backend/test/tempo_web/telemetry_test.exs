defmodule TempoWeb.TelemetryTest do
  use ExUnit.Case, async: true

  test "metrics/0 returns a list of telemetry metrics" do
    metrics = TempoWeb.Telemetry.metrics()
    assert is_list(metrics)
    assert length(metrics) > 0
  end

  test "metrics/0 includes phoenix endpoint metrics" do
    metrics = TempoWeb.Telemetry.metrics()
    names = Enum.map(metrics, fn m -> m.name end)
    # At least one endpoint metric should be present
    assert Enum.any?(names, fn name -> List.first(name) == :phoenix end)
  end
end
