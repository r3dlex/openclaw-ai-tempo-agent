defmodule Tempo.Sources.Augment do
  @moduledoc """
  Client for the Augment Code Analytics API.

  Endpoints:
  - GET /analytics/v0/dau-count - Daily active user counts
  - GET /analytics/v0/dau - Active users for a date
  - GET /analytics/v0/daily-usage - Org usage metrics by day
  - GET /analytics/v0/user-activity - Per-user metrics
  - GET /analytics/v0/daily-user-activity-by-editor-language - Activity by editor/language
  """

  @rate_limit_ms 6_000

  defp config do
    Application.get_env(:tempo, :augment, [])
  end

  defp base_url, do: Keyword.get(config(), :api_url, "https://api.augmentcode.com")
  defp api_token, do: Keyword.get(config(), :api_token, "")

  defp headers do
    [
      {"authorization", "Bearer #{api_token()}"},
      {"content-type", "application/json"},
      {"accept", "application/json"}
    ]
  end

  @doc "Fetch daily active user counts for a date range."
  def dau_count(start_date \\ nil, end_date \\ nil) do
    params =
      %{}
      |> maybe_put(:start_date, start_date)
      |> maybe_put(:end_date, end_date)

    get("/analytics/v0/dau-count", params)
  end

  @doc "Fetch active users for a specific date."
  def dau(date \\ nil, opts \\ []) do
    params =
      %{}
      |> maybe_put(:date, date)
      |> maybe_put(:cursor, Keyword.get(opts, :cursor))
      |> maybe_put(:page_size, Keyword.get(opts, :page_size))

    get("/analytics/v0/dau", params)
  end

  @doc "Fetch daily organization usage metrics."
  def daily_usage(start_date \\ nil, end_date \\ nil) do
    params =
      %{}
      |> maybe_put(:start_date, start_date)
      |> maybe_put(:end_date, end_date)

    get("/analytics/v0/daily-usage", params)
  end

  @doc "Fetch per-user activity metrics."
  def user_activity(start_date \\ nil, end_date \\ nil, opts \\ []) do
    params =
      %{}
      |> maybe_put(:start_date, start_date)
      |> maybe_put(:end_date, end_date)
      |> maybe_put(:cursor, Keyword.get(opts, :cursor))
      |> maybe_put(:page_size, Keyword.get(opts, :page_size))

    get("/analytics/v0/user-activity", params)
  end

  @doc "Fetch user activity broken down by editor and language."
  def activity_by_editor_language(date \\ nil, opts \\ []) do
    params =
      %{}
      |> maybe_put(:date, date)
      |> maybe_put(:cursor, Keyword.get(opts, :cursor))
      |> maybe_put(:page_size, Keyword.get(opts, :page_size))

    get("/analytics/v0/daily-user-activity-by-editor-language", params)
  end

  defp get(path, params) do
    url = base_url() <> path

    case Req.get(url, headers: headers(), params: params) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: 429}} ->
        Process.sleep(@rate_limit_ms)
        get(path, params)

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, %{status: status, body: body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
