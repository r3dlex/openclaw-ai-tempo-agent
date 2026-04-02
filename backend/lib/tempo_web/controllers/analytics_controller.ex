defmodule TempoWeb.AnalyticsController do
  @moduledoc """
  Phoenix controller for analytics endpoints.

  Exposes per-source analytics data: user statistics, daily aggregates,
  raw records, and a summary rollup. All endpoints require a `source`
  path parameter; currently only `"augment"` is supported.
  """

  use TempoWeb, :controller

  alias Tempo.DataStore

  @supported_sources ~w(augment)

  def sources(conn, _params) do
    json(conn, %{sources: @supported_sources})
  end

  def user_stats(conn, %{"source" => source}) do
    with :ok <- validate_source(source) do
      stats = DataStore.get_user_stats(String.to_existing_atom(source))
      json(conn, %{source: source, users: stats})
    else
      {:error, msg} -> conn |> put_status(400) |> json(%{error: msg})
    end
  end

  def daily_aggregates(conn, %{"source" => source}) do
    with :ok <- validate_source(source) do
      aggregates = DataStore.get_daily_aggregates(String.to_existing_atom(source))
      json(conn, %{source: source, daily: aggregates})
    else
      {:error, msg} -> conn |> put_status(400) |> json(%{error: msg})
    end
  end

  def raw_data(conn, %{"source" => source}) do
    with :ok <- validate_source(source) do
      data = DataStore.get_data(String.to_existing_atom(source))
      json(conn, %{source: source, count: length(data), data: Enum.take(data, 100)})
    else
      {:error, msg} -> conn |> put_status(400) |> json(%{error: msg})
    end
  end

  def summary(conn, %{"source" => source}) do
    with :ok <- validate_source(source) do
      stats = DataStore.get_user_stats(String.to_existing_atom(source))
      daily = DataStore.get_daily_aggregates(String.to_existing_atom(source))

      total_credits = stats |> Enum.map(& &1.total_credits) |> Enum.sum()
      total_users = length(stats)
      active_users = Enum.count(stats, &(&1.days_active > 0))
      days_tracked = length(daily)

      avg_credits =
        if total_users > 0, do: total_credits / total_users, else: 0

      json(conn, %{
        source: source,
        total_credits: total_credits,
        total_users: total_users,
        active_users: active_users,
        days_tracked: days_tracked,
        average_credits_per_user: Float.round(avg_credits * 1.0, 2)
      })
    else
      {:error, msg} -> conn |> put_status(400) |> json(%{error: msg})
    end
  end

  defp validate_source(source) when source in @supported_sources, do: :ok
  defp validate_source(_), do: {:error, "unsupported source"}
end
