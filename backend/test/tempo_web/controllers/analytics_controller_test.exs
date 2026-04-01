defmodule TempoWeb.AnalyticsControllerTest do
  use ExUnit.Case
  import Plug.Test
  import Plug.Conn

  alias TempoWeb.Router

  @opts Router.init([])

  # ---- Health ----

  test "GET /api/v1/health returns ok" do
    conn =
      conn(:get, "/api/v1/health")
      |> put_req_header("accept", "application/json")
      |> Router.call(@opts)

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert body["status"] == "ok"
    assert body["service"] == "tempo"
    assert body["version"] == "0.1.0"
  end

  # ---- Sources ----

  test "GET /api/v1/analytics/sources returns supported sources" do
    conn =
      conn(:get, "/api/v1/analytics/sources")
      |> put_req_header("accept", "application/json")
      |> Router.call(@opts)

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert "augment" in body["sources"]
  end

  # ---- User stats ----

  test "GET /api/v1/analytics/augment/users returns 200" do
    conn =
      conn(:get, "/api/v1/analytics/augment/users")
      |> put_req_header("accept", "application/json")
      |> Router.call(@opts)

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert body["source"] == "augment"
    assert is_list(body["users"])
  end

  test "GET /api/v1/analytics/invalid/users returns 400" do
    conn =
      conn(:get, "/api/v1/analytics/invalid/users")
      |> put_req_header("accept", "application/json")
      |> Router.call(@opts)

    assert conn.status == 400
    body = Jason.decode!(conn.resp_body)
    assert body["error"] == "unsupported source"
  end

  # ---- Daily aggregates ----

  test "GET /api/v1/analytics/augment/daily returns 200" do
    conn =
      conn(:get, "/api/v1/analytics/augment/daily")
      |> put_req_header("accept", "application/json")
      |> Router.call(@opts)

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert body["source"] == "augment"
    assert is_list(body["daily"])
  end

  test "GET /api/v1/analytics/invalid/daily returns 400" do
    conn =
      conn(:get, "/api/v1/analytics/invalid/daily")
      |> put_req_header("accept", "application/json")
      |> Router.call(@opts)

    assert conn.status == 400
    body = Jason.decode!(conn.resp_body)
    assert body["error"] == "unsupported source"
  end

  # ---- Raw data ----

  test "GET /api/v1/analytics/augment/raw returns 200" do
    conn =
      conn(:get, "/api/v1/analytics/augment/raw")
      |> put_req_header("accept", "application/json")
      |> Router.call(@opts)

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert body["source"] == "augment"
    assert is_integer(body["count"])
    assert is_list(body["data"])
  end

  test "GET /api/v1/analytics/invalid/raw returns 400" do
    conn =
      conn(:get, "/api/v1/analytics/invalid/raw")
      |> put_req_header("accept", "application/json")
      |> Router.call(@opts)

    assert conn.status == 400
  end

  # ---- Summary ----

  test "GET /api/v1/analytics/augment/summary returns 200" do
    conn =
      conn(:get, "/api/v1/analytics/augment/summary")
      |> put_req_header("accept", "application/json")
      |> Router.call(@opts)

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert body["source"] == "augment"
    assert Map.has_key?(body, "total_credits")
    assert Map.has_key?(body, "total_users")
    assert Map.has_key?(body, "active_users")
    assert Map.has_key?(body, "days_tracked")
    assert Map.has_key?(body, "average_credits_per_user")
  end

  test "GET /api/v1/analytics/invalid/summary returns 400" do
    conn =
      conn(:get, "/api/v1/analytics/invalid/summary")
      |> put_req_header("accept", "application/json")
      |> Router.call(@opts)

    assert conn.status == 400
  end
end
