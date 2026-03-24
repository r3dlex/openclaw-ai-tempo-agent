defmodule TempoWeb.AnalyticsControllerTest do
  use ExUnit.Case
  use Plug.Test

  alias TempoWeb.Router

  @opts Router.init([])

  test "GET /api/v1/health returns ok" do
    conn =
      conn(:get, "/api/v1/health")
      |> put_req_header("accept", "application/json")
      |> Router.call(@opts)

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert body["status"] == "ok"
  end

  test "GET /api/v1/analytics/sources returns supported sources" do
    conn =
      conn(:get, "/api/v1/analytics/sources")
      |> put_req_header("accept", "application/json")
      |> Router.call(@opts)

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert "augment" in body["sources"]
  end
end
