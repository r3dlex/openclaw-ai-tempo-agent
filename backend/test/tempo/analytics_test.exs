defmodule Tempo.AnalyticsTest do
  use ExUnit.Case, async: true

  alias Tempo.Analytics

  @sample_data [
    %{
      "dateRange" => %{"startDate" => "2025-11-24T00:00:00Z", "endDate" => "2025-11-25T00:00:00Z"},
      "creditsConsumed" => "54389",
      "groupKey" => "alice@example.com"
    },
    %{
      "dateRange" => %{"startDate" => "2025-11-24T00:00:00Z", "endDate" => "2025-11-25T00:00:00Z"},
      "creditsConsumed" => "12000",
      "groupKey" => "bob@example.com"
    },
    %{
      "dateRange" => %{"startDate" => "2025-11-25T00:00:00Z", "endDate" => "2025-11-26T00:00:00Z"},
      "creditsConsumed" => "30000",
      "groupKey" => "alice@example.com"
    }
  ]

  describe "compute_user_stats/1" do
    test "aggregates credits per user" do
      stats = Analytics.compute_user_stats(@sample_data)

      alice = Enum.find(stats, &(&1.email == "alice@example.com"))
      assert alice.total_credits == 84389
      assert alice.days_active == 2
    end

    test "sorts by total credits descending" do
      [first | _] = Analytics.compute_user_stats(@sample_data)
      assert first.email == "alice@example.com"
    end

    test "returns empty list for empty input" do
      assert Analytics.compute_user_stats([]) == []
    end
  end

  describe "compute_daily_aggregates/1" do
    test "groups by date and sums credits" do
      aggregates = Analytics.compute_daily_aggregates(@sample_data)

      day1 = Enum.find(aggregates, &(&1.date == "2025-11-24"))
      assert day1.total_credits == 66389
      assert day1.user_count == 2
    end

    test "sorts chronologically" do
      [first, second] = Analytics.compute_daily_aggregates(@sample_data)
      assert first.date < second.date
    end
  end
end
