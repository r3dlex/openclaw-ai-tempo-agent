defmodule Tempo.ApplicationTest do
  use ExUnit.Case

  test "config_change/3 returns :ok" do
    # This exercises the config_change/3 callback used by the Phoenix endpoint
    result = Tempo.Application.config_change([], [], [])
    assert result == :ok
  end
end
