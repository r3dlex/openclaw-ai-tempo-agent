defmodule TempoWeb.Router do
  @moduledoc """
  Phoenix Router for the Tempo backend API.

  All routes are scoped under `/api/v1` and use the JSON pipeline.
  Analytics routes are further scoped under `/analytics/:source` where
  `source` is the analytics provider (e.g., `"augment"`).
  """

  use TempoWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", TempoWeb do
    pipe_through :api

    get "/health", HealthController, :index

    scope "/analytics" do
      get "/sources", AnalyticsController, :sources
      get "/:source/users", AnalyticsController, :user_stats
      get "/:source/daily", AnalyticsController, :daily_aggregates
      get "/:source/raw", AnalyticsController, :raw_data
      get "/:source/summary", AnalyticsController, :summary
    end
  end
end
